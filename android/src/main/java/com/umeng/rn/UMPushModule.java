package com.umeng.rn;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.umeng.message.PushAgent;
import com.umeng.message.UmengMessageHandler;
import com.umeng.message.UmengNotificationClickHandler;
import com.umeng.message.api.UPushAliasCallback;
import com.umeng.message.api.UPushRegisterCallback;
import com.umeng.message.api.UPushSettingCallback;
import com.umeng.message.api.UPushTagCallback;
import com.umeng.message.common.inter.ITagManager;
import com.umeng.message.entity.UMessage;

import java.lang.ref.WeakReference;
import java.lang.reflect.Method;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;

/**
 * UMPushModule - 友盟推送 React Native 桥接模块
 *
 * 关键能力：
 * - 事件系统：通过 RCTDeviceEventEmitter 发送推送事件到 JS
 * - 批量 Tag：addTags / removeTags
 * - 推送控制：setPushEnable / setBadge
 * - 厂商通道：反射注册（小米/华为/荣耀/OPPO/VIVO/魅族），不强依赖厂商 SDK
 * - 离线消息：UMOfflineMessageActivity 经 deliverNotificationOpenEvent 统一交付
 *
 * 注意：不在 register() 中调用 UMConfigure.init，由 RNUMConfigure 统一初始化
 */
@ReactModule(name = "UMPushModule")
public class UMPushModule extends ReactContextBaseJavaModule {

    private static final String TAG = "UMPushModule";
    private static final Handler sMainHandler = new Handler(Looper.getMainLooper());

    // 事件名常量
    private static final String EVENT_ON_TOKEN = "UMPushOnToken";
    private static final String EVENT_ON_MESSAGE = "UMPushOnMessage";
    private static final String EVENT_ON_NOTIFICATION_RECEIVE = "UMPushOnNotificationReceive";
    private static final String EVENT_ON_NOTIFICATION_OPEN = "UMPushOnNotificationOpen";

    // 冷启动事件缓存：handlers 在构造器中即设置，但 ReactContext 可能尚未就绪，
    // 此时将事件暂存到静态字段，待 register 成功后回放（对齐 iOS userInfoTemp/deviceTokenTemp 机制）
    private static String sCachedToken = null;
    private static String sCachedNotificationReceive = null;
    private static String sCachedMessage = null;

    // 点击事件统一交付状态（静态，供 UMOfflineMessageActivity 等非 JS 调用方使用）：
    // - sActiveModuleRef：当前存活的模块实例，弱引用避免 ReactContext 重建后泄漏
    // - sPendingOpenQueue：JS 监听未就绪期间的点击事件待回放队列（FIFO）
    // - sOpenListenerReady：JS 是否已订阅 UMPushOnNotificationOpen
    //   （RN 的 NativeEventEmitter 订阅事件时会回调本模块 addListener）
    private static final Object sDeliveryLock = new Object();
    private static final int MAX_PENDING_OPEN_EVENTS = 20;
    private static WeakReference<UMPushModule> sActiveModuleRef = new WeakReference<>(null);
    private static final Deque<String> sPendingOpenQueue = new ArrayDeque<>();
    private static boolean sOpenListenerReady = false;

    private final ReactApplicationContext reactContext;
    private final PushAgent mPushAgent;

    public UMPushModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        this.mPushAgent = PushAgent.getInstance(reactContext);
        synchronized (sDeliveryLock) {
            sActiveModuleRef = new WeakReference<>(this);
            // 新桥接实例意味着 JS 侧监听需重新建立（如 reload），旧标记归零；
            // 待回放队列保留，JS 重新订阅后立即补发
            sOpenListenerReady = false;
        }
        // 尽早设置消息/通知处理器，避免冷启动期间事件丢失
        setupHandlers();
    }

    @NonNull
    @Override
    public String getName() {
        return "UMPushModule";
    }

    /**
     * ReactContext 销毁时注销静态引用，避免旧实例阻塞事件交付。
     */
    @Override
    public void invalidate() {
        synchronized (sDeliveryLock) {
            UMPushModule active = sActiveModuleRef.get();
            if (active == this) {
                sActiveModuleRef = new WeakReference<>(null);
                sOpenListenerReady = false;
            }
        }
        super.invalidate();
    }

    // ======================== 事件发射 ========================

    private void emitEvent(String eventName, Object params) {
        try {
            if (reactContext.hasActiveCatalystInstance()) {
                reactContext
                    .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                    .emit(eventName, params);
            }
        } catch (Exception e) {
            Log.w(TAG, "emitEvent failed: " + eventName, e);
        }
    }

    private void emitEventOnMain(String eventName, Object params) {
        sMainHandler.post(() -> emitEvent(eventName, params));
    }

    /**
     * 尝试发送事件到 JS；若 ReactContext 尚未就绪则缓存到静态字段待回放。
     */
    private void emitOrCache(String eventName, String data) {
        if (reactContext.hasActiveCatalystInstance()) {
            emitEventOnMain(eventName, data);
        } else {
            Log.i(TAG, "ReactContext 未就绪，缓存事件: " + eventName);
            switch (eventName) {
                case EVENT_ON_TOKEN: sCachedToken = data; break;
                case EVENT_ON_NOTIFICATION_OPEN:
                    enqueuePendingOpenEvent(data);
                    break;
                case EVENT_ON_NOTIFICATION_RECEIVE: sCachedNotificationReceive = data; break;
                case EVENT_ON_MESSAGE: sCachedMessage = data; break;
            }
        }
    }

    /**
     * 回放冷启动期间缓存的事件（注册成功后调用，对齐 iOS registerFromNative 回放逻辑）
     */
    private void replayCachedEvents() {
        if (sCachedToken != null) {
            String data = sCachedToken;
            sCachedToken = null;
            emitEventOnMain(EVENT_ON_TOKEN, data);
        }
        // 点击事件统一走待回放队列：仅在 JS 已订阅 notificationOpen 时补发，
        // 否则保留在队列中，待 addListener 订阅时再补发，避免事件悬空丢失
        if (isNotificationOpenListenerReady()) {
            drainPendingOpenEvents();
        }
        if (sCachedNotificationReceive != null) {
            String data = sCachedNotificationReceive;
            sCachedNotificationReceive = null;
            emitEventOnMain(EVENT_ON_NOTIFICATION_RECEIVE, data);
        }
        if (sCachedMessage != null) {
            String data = sCachedMessage;
            sCachedMessage = null;
            emitEventOnMain(EVENT_ON_MESSAGE, data);
        }
    }

    // ======================== 消息/通知处理器 ========================

    /**
     * 设置消息/通知处理器（构造时即调用，确保冷启动期间事件不丢失）。
     * 若 ReactContext 尚未就绪，事件会被缓存到静态字段，待 register 后回放。
     */
    private void setupHandlers() {
        UmengMessageHandler messageHandler = new UmengMessageHandler() {
            @Override
            public void dealWithCustomMessage(Context context, UMessage uMessage) {
                super.dealWithCustomMessage(context, uMessage);
                try {
                    String raw = uMessage.getRaw().toString();
                    emitOrCache(EVENT_ON_MESSAGE, raw);
                } catch (Throwable e) {
                    Log.w(TAG, "dealWithCustomMessage emit failed", e);
                }
            }

            @Override
            public void dealWithNotificationMessage(Context context, UMessage uMessage) {
                super.dealWithNotificationMessage(context, uMessage);
                try {
                    String raw = uMessage.getRaw().toString();
                    emitOrCache(EVENT_ON_NOTIFICATION_RECEIVE, raw);
                } catch (Throwable e) {
                    Log.w(TAG, "dealWithNotificationMessage emit failed", e);
                }
            }
        };
        mPushAgent.setMessageHandler(messageHandler);

        UmengNotificationClickHandler clickHandler = new UmengNotificationClickHandler() {
            @Override
            public void handleMessage(Context context, UMessage uMessage) {
                super.handleMessage(context, uMessage);
                if (uMessage.dismiss) {
                    return;
                }
                try {
                    String raw = uMessage.getRaw().toString();
                    emitOrCache(EVENT_ON_NOTIFICATION_OPEN, raw);
                } catch (Throwable e) {
                    Log.w(TAG, "handleMessage emit failed", e);
                }
            }
        };
        mPushAgent.setNotificationClickHandler(clickHandler);
    }

    // ======================== Tag 管理 ========================

    @ReactMethod
    public void addTag(String tag, Promise promise) {
        mPushAgent.getTagManager().addTags(new UPushTagCallback<ITagManager.Result>() {
            @Override
            public void onMessage(boolean isSuccess, ITagManager.Result result) {
                if (isSuccess) {
                    WritableMap map = resultToMap(result);
                    map.putInt("code", 200);
                    promise.resolve(map);
                } else {
                    promise.reject("E_ADD_TAG", "addTag failed");
                }
            }
        }, tag);
    }

    @ReactMethod
    public void deleteTag(String tag, Promise promise) {
        mPushAgent.getTagManager().deleteTags(new UPushTagCallback<ITagManager.Result>() {
            @Override
            public void onMessage(boolean isSuccess, ITagManager.Result result) {
                if (isSuccess) {
                    WritableMap map = resultToMap(result);
                    map.putInt("code", 200);
                    promise.resolve(map);
                } else {
                    promise.reject("E_DELETE_TAG", "deleteTag failed");
                }
            }
        }, tag);
    }

    @ReactMethod
    public void listTag(Promise promise) {
        mPushAgent.getTagManager().getTags(new UPushTagCallback<List<String>>() {
            @Override
            public void onMessage(boolean isSuccess, List<String> result) {
                sMainHandler.post(() -> {
                    if (isSuccess) {
                        WritableMap map = Arguments.createMap();
                        map.putInt("code", 200);
                        map.putArray("tags", listToArray(result));
                        promise.resolve(map);
                    } else {
                        promise.reject("E_LIST_TAG", "listTag failed");
                    }
                });
            }
        });
    }

    @ReactMethod
    public void addTags(ReadableArray tags, Promise promise) {
        String[] tagArray = readableArrayToStringArray(tags);
        mPushAgent.getTagManager().addTags(new UPushTagCallback<ITagManager.Result>() {
            @Override
            public void onMessage(boolean isSuccess, ITagManager.Result result) {
                if (isSuccess) {
                    WritableMap map = resultToMap(result);
                    map.putInt("code", 200);
                    promise.resolve(map);
                } else {
                    promise.reject("E_ADD_TAGS", "addTags failed");
                }
            }
        }, tagArray);
    }

    @ReactMethod
    public void removeTags(ReadableArray tags, Promise promise) {
        String[] tagArray = readableArrayToStringArray(tags);
        mPushAgent.getTagManager().deleteTags(new UPushTagCallback<ITagManager.Result>() {
            @Override
            public void onMessage(boolean isSuccess, ITagManager.Result result) {
                if (isSuccess) {
                    WritableMap map = resultToMap(result);
                    map.putInt("code", 200);
                    promise.resolve(map);
                } else {
                    promise.reject("E_REMOVE_TAGS", "removeTags failed");
                }
            }
        }, tagArray);
    }

    // ======================== Alias 管理 ========================

    @ReactMethod
    public void addAlias(String alias, String aliasType, Promise promise) {
        mPushAgent.addAlias(alias, aliasType, new UPushAliasCallback() {
            @Override
            public void onMessage(boolean isSuccess, String message) {
                Log.d(TAG, "addAlias isSuccess:" + isSuccess + ", " + message);
                if (isSuccess) {
                    WritableMap map = Arguments.createMap();
                    map.putInt("code", 200);
                    promise.resolve(map);
                } else {
                    promise.reject("E_ADD_ALIAS", "addAlias failed: " + message);
                }
            }
        });
    }

    @ReactMethod
    public void addExclusiveAlias(String alias, String aliasType, Promise promise) {
        mPushAgent.setAlias(alias, aliasType, new UPushAliasCallback() {
            @Override
            public void onMessage(boolean isSuccess, String message) {
                Log.d(TAG, "addExclusiveAlias isSuccess:" + isSuccess + ", " + message);
                if (isSuccess) {
                    WritableMap map = Arguments.createMap();
                    map.putInt("code", 200);
                    promise.resolve(map);
                } else {
                    promise.reject("E_ADD_EXCLUSIVE_ALIAS",
                            "addExclusiveAlias failed: " + message);
                }
            }
        });
    }

    @ReactMethod
    public void deleteAlias(String alias, String aliasType, Promise promise) {
        mPushAgent.deleteAlias(alias, aliasType, new UPushAliasCallback() {
            @Override
            public void onMessage(boolean isSuccess, String message) {
                Log.d(TAG, "deleteAlias isSuccess:" + isSuccess + ", " + message);
                if (isSuccess) {
                    WritableMap map = Arguments.createMap();
                    map.putInt("code", 200);
                    promise.resolve(map);
                } else {
                    promise.reject("E_DELETE_ALIAS",
                            "deleteAlias failed: " + message);
                }
            }
        });
    }

    // ======================== 注册与配置 ========================

    /**
     * JS 侧注册接口（ReactMethod，TS 接口保留）。
     * 完整注册逻辑见 {@link #doRegister}，成功后 resolve Promise。
     */
    @ReactMethod
    public void register(Promise promise) {
        doRegister(promise);
    }

    /**
     * 原生初始化时调用：执行与 {@link #register(Promise)} 完全相同的注册逻辑，
     * 仅不涉及 JS Promise。由宿主在 initUmeng 中经 ReactContext 取得本模块实例后调用。
     */
    public void registerFromNative() {
        doRegister(null);
    }

    /**
     * 推送注册核心逻辑：注册设备；成功回调中发送 token 事件、
     * 注册厂商通道、回放冷启动缓存事件、回放离线消息。
     * 消息/通知 handler 已在构造器中通过 setupHandlers() 设置。
     * JS 与原生两条入口共用此方法，避免逻辑重复。
     *
     * @param promise JS 调用时用于 resolve/reject；原生调用传 null（跳过 Promise）
     */
    private void doRegister(@Nullable final Promise promise) {
        final Context ctx = reactContext.getApplicationContext();
        mPushAgent.setDisplayNotificationNumber(0);

        // 注册推送（handlers 已在构造器中通过 setupHandlers() 设置）
        mPushAgent.register(new UPushRegisterCallback() {
            @Override
            public void onSuccess(String deviceToken) {
                Log.i(TAG, "register success deviceToken:" + deviceToken);
                if (promise != null) {
                    WritableMap map = Arguments.createMap();
                    map.putInt("code", 200);
                    map.putString("deviceToken", deviceToken);
                    promise.resolve(map);
                }

                // 发送 token 事件
                emitEventOnMain(EVENT_ON_TOKEN, deviceToken);

                // 注册厂商通道
                registerVendorChannels(ctx);

                // 回放冷启动缓存事件（对齐 iOS registerFromNative 回放 userInfoTemp/deviceTokenTemp）
                replayCachedEvents();

                // 检查离线消息缓存
                checkOfflineMessage();
            }

            @Override
            public void onFailure(String code, String msg) {
                Log.w(TAG, "register failure code:" + code + " msg:" + msg);
                if (promise != null) {
                    promise.reject("E_REGISTER", "register failed: code=" + code + " msg=" + msg);
                }
            }
        });
    }

    @ReactMethod
    public void getDeviceToken(Promise promise) {
        try {
            String deviceToken = mPushAgent.getRegistrationId();
            promise.resolve(deviceToken != null ? deviceToken : "");
        } catch (Exception e) {
            promise.reject("E_GET_DEVICE_TOKEN", e.getMessage(), e);
        }
    }

    // ======================== 推送控制 ========================

    @ReactMethod
    public void setPushEnable(boolean enable) {
        UPushSettingCallback callback = new UPushSettingCallback() {
            @Override
            public void onSuccess() {
                Log.i(TAG, "setPushEnable success: " + enable);
            }

            @Override
            public void onFailure(String code, String msg) {
                Log.w(TAG, "setPushEnable failure: " + enable + ", " + code + ", " + msg);
            }
        };
        if (enable) {
            mPushAgent.enable(callback);
        } else {
            mPushAgent.disable(callback);
        }
    }

    @ReactMethod
    public void setBadge(int num) {
        try {
            mPushAgent.setBadgeNum(num);
        } catch (Exception e) {
            Log.w(TAG, "setBadge failed", e);
        }
    }

    /**
     * 打开手机通知设置页面，引导用户开启通知权限
     */
    @ReactMethod
    public void openNotificationSettings() {
        try {
            mPushAgent.openNotificationSettings();
        } catch (Exception e) {
            Log.w(TAG, "openNotificationSettings failed", e);
        }
    }

    /**
     * 检查通知权限是否已开启
     */
    @ReactMethod
    public void isNotificationEnabled(Promise promise) {
        try {
            boolean enabled = mPushAgent.isNotificationEnabled();
            promise.resolve(enabled);
        } catch (Exception e) {
            promise.reject("E_CHECK_NOTIFICATION", e.getMessage(), e);
        }
    }

    // ======================== 事件系统（Legacy Module 必需）========================

    @ReactMethod
    public void addListener(String eventName) {
        // NativeEventEmitter 订阅事件时会回调此方法：收到 notificationOpen 订阅
        // 说明 JS 监听已就绪，立即补发此前缓存的点击事件
        if (EVENT_ON_NOTIFICATION_OPEN.equals(eventName)) {
            synchronized (sDeliveryLock) {
                sOpenListenerReady = true;
            }
            Log.i(TAG, "JS 已订阅 notificationOpen，检查待回放队列");
            drainPendingOpenEvents();
        }
    }

    @ReactMethod
    public void removeListeners(int count) {
        // Required for RN NativeEventEmitter
        // 注：count 不携带事件名（可能来自任意事件监听的移除），无法据此精确
        // 还原 notificationOpen 的订阅状态，故保持 sOpenListenerReady 不变，
        // 避免误判为“未监听”而让后续点击事件滞留在队列中。
    }

    // ======================== 厂商通道注册 ========================

    /**
     * 通过反射注册厂商通道，避免强依赖厂商 SDK。
     * 从 ApplicationInfo.metaData 读取配置，如果 metaData 不存在则跳过。
     */
    private void registerVendorChannels(Context ctx) {
        try {
            ApplicationInfo appInfo = ctx.getPackageManager()
                .getApplicationInfo(ctx.getPackageName(), PackageManager.GET_META_DATA);
            if (appInfo.metaData == null) {
                Log.d(TAG, "No metaData found, skip vendor channels");
                return;
            }

            // 小米
            try {
                String xmAppId = appInfo.metaData.getString("org.android.agoo.xiaomi.app_id");
                String xmAppKey = appInfo.metaData.getString("org.android.agoo.xiaomi.app_key");
                if (xmAppId != null && xmAppKey != null) {
                    xmAppId = xmAppId.replace("appid=", "");
                    xmAppKey = xmAppKey.replace("appkey=", "");
                    Class<?> clazz = Class.forName("org.android.agoo.xiaomi.MiPushRegistar");
                    Method method = clazz.getMethod("register", Context.class, String.class, String.class);
                    method.invoke(null, ctx, xmAppId, xmAppKey);
                    Log.i(TAG, "Xiaomi push registered");
                }
            } catch (Throwable e) {
                Log.d(TAG, "xiaomi register skip: " + e.getMessage());
            }

            // 华为
            try {
                Class<?> clazz = Class.forName("org.android.agoo.huawei.HuaWeiRegister");
                Method method = clazz.getMethod("register", Context.class);
                method.invoke(null, ctx);
                Log.i(TAG, "Huawei push registered");
            } catch (Throwable e) {
                Log.d(TAG, "huawei register skip: " + e.getMessage());
            }

            // 荣耀
            try {
                Class<?> clazz = Class.forName("org.android.agoo.honor.HonorRegister");
                Method method = clazz.getMethod("register", Context.class);
                method.invoke(null, ctx);
                Log.i(TAG, "Honor push registered");
            } catch (Throwable e) {
                Log.d(TAG, "honor register skip: " + e.getMessage());
            }

            // OPPO
            try {
                String oppoAppKey = appInfo.metaData.getString("org.android.agoo.oppo.app_key");
                String oppoAppSecret = appInfo.metaData.getString("org.android.agoo.oppo.app_secret");
                if (oppoAppKey != null && oppoAppSecret != null) {
                    Class<?> clazz = Class.forName("org.android.agoo.oppo.OppoRegister");
                    Method method = clazz.getMethod("register", Context.class, String.class, String.class);
                    method.invoke(null, ctx, oppoAppKey, oppoAppSecret);
                    Log.i(TAG, "OPPO push registered");
                }
            } catch (Throwable e) {
                Log.d(TAG, "oppo register skip: " + e.getMessage());
            }

            // VIVO
            try {
                Class<?> clazz = Class.forName("org.android.agoo.vivo.VivoRegister");
                Method method = clazz.getMethod("register", Context.class);
                method.invoke(null, ctx);
                Log.i(TAG, "VIVO push registered");
            } catch (Throwable e) {
                Log.d(TAG, "vivo register skip: " + e.getMessage());
            }

            // 魅族
            try {
                String mzAppId = appInfo.metaData.getString("org.android.agoo.meizu.app_id");
                String mzAppKey = appInfo.metaData.getString("org.android.agoo.meizu.app_key");
                if (mzAppId != null && mzAppKey != null) {
                    mzAppId = mzAppId.replace("appid=", "");
                    mzAppKey = mzAppKey.replace("appkey=", "");
                    Class<?> clazz = Class.forName("org.android.agoo.mezu.MeizuRegister");
                    Method method = clazz.getMethod("register", Context.class, String.class, String.class);
                    method.invoke(null, ctx, mzAppId, mzAppKey);
                    Log.i(TAG, "Meizu push registered");
                }
            } catch (Throwable e) {
                Log.d(TAG, "meizu register skip: " + e.getMessage());
            }

        } catch (Throwable e) {
            Log.w(TAG, "registerVendorChannels error", e);
        }
    }

    // ======================== 点击事件统一交付 ========================

    /**
     * 静态入口：交付推送点击事件（供 UMOfflineMessageActivity 等非 JS 调用方使用）。
     *
     * 交付策略：
     * - 模块已创建且 JS 已订阅 notificationOpen（热启动常规路径）→ 立即发送事件；
     * - 模块尚未创建 / ReactContext 未就绪 / JS 尚未订阅（冷启动）→ 进入待回放队列，
     *   待 JS 订阅（addListener）或 register 成功后统一补发。
     *
     * @param raw UMessage 原始 JSON 字符串
     */
    public static void deliverNotificationOpenEvent(@Nullable String raw) {
        if (raw == null || raw.isEmpty()) {
            return;
        }
        UMPushModule target = null;
        synchronized (sDeliveryLock) {
            UMPushModule active = sActiveModuleRef.get();
            if (active != null && sOpenListenerReady && active.hasActiveJsContext()) {
                target = active;
            } else {
                enqueuePendingOpenEventLocked(raw);
            }
        }
        if (target != null) {
            Log.i(TAG, "JS 监听已就绪，立即交付 notificationOpen 事件");
            target.emitEventOnMain(EVENT_ON_NOTIFICATION_OPEN, raw);
        } else {
            Log.i(TAG, "JS 监听未就绪，notificationOpen 事件入队待回放");
        }
    }

    /**
     * JS 监听是否已就绪：模块实例存活 + ReactContext 可用 + 已订阅 notificationOpen。
     */
    private boolean isNotificationOpenListenerReady() {
        boolean listenerReady;
        synchronized (sDeliveryLock) {
            listenerReady = sOpenListenerReady;
        }
        return listenerReady && hasActiveJsContext();
    }

    private boolean hasActiveJsContext() {
        try {
            return reactContext.hasActiveCatalystInstance();
        } catch (Throwable e) {
            return false;
        }
    }

    /**
     * 按 FIFO 补发待回放队列中的点击事件。
     */
    private void drainPendingOpenEvents() {
        List<String> pending;
        synchronized (sDeliveryLock) {
            if (sPendingOpenQueue.isEmpty()) {
                return;
            }
            pending = new ArrayList<>(sPendingOpenQueue);
            sPendingOpenQueue.clear();
        }
        Log.i(TAG, "回放待交付 notificationOpen 事件: " + pending.size());
        for (String data : pending) {
            emitEventOnMain(EVENT_ON_NOTIFICATION_OPEN, data);
        }
    }

    private static void enqueuePendingOpenEvent(String data) {
        synchronized (sDeliveryLock) {
            enqueuePendingOpenEventLocked(data);
        }
    }

    /**
     * 入队（调用方须持有 {@link #sDeliveryLock}）；超过上限时丢弃最早事件，避免无限增长。
     */
    private static void enqueuePendingOpenEventLocked(String data) {
        if (sPendingOpenQueue.size() >= MAX_PENDING_OPEN_EVENTS) {
            String dropped = sPendingOpenQueue.pollFirst();
            Log.w(TAG, "待回放队列已满，丢弃最早事件: " + dropped);
        }
        sPendingOpenQueue.addLast(data);
    }

    // ======================== 离线消息处理 ========================

    /**
     * 兼容旧实现：早期 Activity 只写静态字段 sOfflineMsgCache，
     * 这里将其转入统一交付入口，确保同一事件仍只交付一次。
     */
    private void checkOfflineMessage() {
        try {
            String offlineMsg = UMOfflineMessageActivity.sOfflineMsgCache;
            if (offlineMsg != null && !offlineMsg.isEmpty()) {
                UMOfflineMessageActivity.sOfflineMsgCache = null;
                deliverNotificationOpenEvent(offlineMsg);
            }
        } catch (Throwable e) {
            Log.w(TAG, "checkOfflineMessage error", e);
        }
    }

    // ======================== 工具方法 ========================

    private static WritableMap resultToMap(ITagManager.Result result) {
        WritableMap map = Arguments.createMap();
        if (result != null) {
            map.putString("status", result.status);
            map.putInt("remain", result.remain);
            map.putString("errors", result.errors);
            map.putString("jsonString", result.jsonString);
        }
        return map;
    }

    private static WritableArray listToArray(List<String> list) {
        WritableArray array = Arguments.createArray();
        if (list != null) {
            for (String item : list) {
                array.pushString(item);
            }
        }
        return array;
    }

    private static String[] readableArrayToStringArray(ReadableArray readableArray) {
        if (readableArray == null) {
            return new String[0];
        }
        String[] result = new String[readableArray.size()];
        for (int i = 0; i < readableArray.size(); i++) {
            result[i] = readableArray.getString(i);
        }
        return result;
    }
}
