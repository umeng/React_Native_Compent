package com.umeng.rn;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.module.annotations.ReactModule;

import com.umeng.socialize.PlatformConfig;
import com.umeng.socialize.ShareAction;
import com.umeng.socialize.UMAuthListener;
import com.umeng.socialize.UMShareAPI;
import com.umeng.socialize.UMShareListener;
import com.umeng.socialize.bean.SHARE_MEDIA;
import com.umeng.socialize.common.ResContainer;
import com.umeng.socialize.media.UMImage;
import com.umeng.socialize.media.UMWeb;

import java.util.HashMap;
import java.util.Map;

/**
 * UMShareModule - 友盟分享 React Native 桥接模块
 *
 * 从旧 ShareModule 迁移，关键变更：
 * - platform 参数由数字 ID 改为字符串枚举
 * - share / auth / shareboard 由 Callback 改为 Promise
 * - 分享内容参数合并为 shareParams 对象
 * - 移除静态 Activity 引用，改用 getCurrentActivity()
 * - 使用 Legacy Module 方式（ReactContextBaseJavaModule + @ReactMethod），
 *   首要保证编译运行，后续可切换为 TurboModule
 */
@ReactModule(name = "UMShareModule")
public class UMShareModule extends ReactContextBaseJavaModule {

    private static final int CODE_SUCCESS = 200;
    private static final int CODE_ERROR = 0;
    private static final int CODE_CANCEL = -1;
    private static final Handler sMainHandler = new Handler(Looper.getMainLooper());

    /** 平台字符串 → SHARE_MEDIA 映射 */
    private static final Map<String, SHARE_MEDIA> PLATFORM_MAP = new HashMap<>();

    static {
        PLATFORM_MAP.put("wechat_session", SHARE_MEDIA.WEIXIN);
        PLATFORM_MAP.put("wechat_timeline", SHARE_MEDIA.WEIXIN_CIRCLE);
        PLATFORM_MAP.put("wechat_favorite", SHARE_MEDIA.WEIXIN_FAVORITE);
        PLATFORM_MAP.put("qq", SHARE_MEDIA.QQ);
        PLATFORM_MAP.put("qzone", SHARE_MEDIA.QZONE);
        PLATFORM_MAP.put("sina", SHARE_MEDIA.SINA);
        PLATFORM_MAP.put("alipay", SHARE_MEDIA.ALIPAY);
        PLATFORM_MAP.put("dingtalk", SHARE_MEDIA.DINGTALK);
        PLATFORM_MAP.put("sms", SHARE_MEDIA.SMS);
        PLATFORM_MAP.put("email", SHARE_MEDIA.EMAIL);
        PLATFORM_MAP.put("facebook", SHARE_MEDIA.FACEBOOK);
        PLATFORM_MAP.put("twitter", SHARE_MEDIA.TWITTER);
        PLATFORM_MAP.put("linkedin", SHARE_MEDIA.LINKEDIN);
        PLATFORM_MAP.put("instagram", SHARE_MEDIA.INSTAGRAM);
        PLATFORM_MAP.put("whatsapp", SHARE_MEDIA.WHATSAPP);
        PLATFORM_MAP.put("line", SHARE_MEDIA.LINE);
        PLATFORM_MAP.put("pinterest", SHARE_MEDIA.PINTEREST);
        PLATFORM_MAP.put("pocket", SHARE_MEDIA.POCKET);
        PLATFORM_MAP.put("dropbox", SHARE_MEDIA.DROPBOX);
        PLATFORM_MAP.put("vkontakte", SHARE_MEDIA.VKONTAKTE);
        PLATFORM_MAP.put("kakao", SHARE_MEDIA.KAKAO);
        PLATFORM_MAP.put("tumblr", SHARE_MEDIA.TUMBLR);
        PLATFORM_MAP.put("flickr", SHARE_MEDIA.FLICKR);
        PLATFORM_MAP.put("youdao_note", SHARE_MEDIA.YNOTE);
        PLATFORM_MAP.put("evernote", SHARE_MEDIA.EVERNOTE);
        PLATFORM_MAP.put("facebook_messenger", SHARE_MEDIA.FACEBOOK_MESSAGER);
    }

    private final ReactApplicationContext reactContext;

    public UMShareModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @NonNull
    @Override
    public String getName() {
        return "UMShareModule";
    }

    // ======================== 分享平台初始化 ========================

    /**
     * JS 侧分享初始化接口（ReactMethod）：接收 TS 传入的配置对象，
     * 转换为 {@link UMShareConfig} 后委托 {@link #doInit}。
     *
     * 注意：QQ 隐私授权门 Tencent.setIsPermissionGranted 依赖宿主的 open_sdk jar，
     * 不在本库依赖内，需宿主自行调用。
     */
    @ReactMethod
    public void init(ReadableMap config) {
        UMShareConfig shareConfig = new UMShareConfig();
        if (config != null) {
            if (config.hasKey("fileProvider")) shareConfig.fileProvider = config.getString("fileProvider");
            if (config.hasKey("weixinAppId")) shareConfig.weixinAppId = config.getString("weixinAppId");
            if (config.hasKey("weixinAppSecret")) shareConfig.weixinAppSecret = config.getString("weixinAppSecret");
            if (config.hasKey("qqAppId")) shareConfig.qqAppId = config.getString("qqAppId");
            if (config.hasKey("qqAppKey")) shareConfig.qqAppKey = config.getString("qqAppKey");
            if (config.hasKey("sinaAppKey")) shareConfig.sinaAppKey = config.getString("sinaAppKey");
            if (config.hasKey("sinaAppSecret")) shareConfig.sinaAppSecret = config.getString("sinaAppSecret");
            if (config.hasKey("sinaRedirectUrl")) shareConfig.sinaRedirectUrl = config.getString("sinaRedirectUrl");
            if (config.hasKey("dingAppId")) shareConfig.dingAppId = config.getString("dingAppId");
        }
        doInit(shareConfig);
    }

    /**
     * 原生初始化时调用：执行与 {@link #init(ReadableMap)} 完全相同的分享配置逻辑。
     * 由宿主在 initUmeng 中经 ReactContext.getNativeModule(UMShareModule.class) 取得实例后调用。
     *
     * @param config 分享配置对象；为 null 时跳过
     */
    public void initFromNative(UMShareConfig config) {
        doInit(config);
    }

    /**
     * 分享平台配置核心逻辑：各平台字段为 null/空时跳过对应 PlatformConfig.setXxx。
     * JS 与原生两条入口共用此方法，避免逻辑重复。
     */
    private void doInit(UMShareConfig config) {
        if (config == null) {
            return;
        }
        if (!TextUtils.isEmpty(config.fileProvider)) {
            PlatformConfig.setFileProvider(config.fileProvider);
        }
        if (!TextUtils.isEmpty(config.weixinAppId)) {
            PlatformConfig.setWeixin(config.weixinAppId, config.weixinAppSecret);
        }
        if (!TextUtils.isEmpty(config.qqAppId)) {
            PlatformConfig.setQQZone(config.qqAppId, config.qqAppKey);
        }
        if (!TextUtils.isEmpty(config.sinaAppKey)) {
            PlatformConfig.setSinaWeibo(config.sinaAppKey, config.sinaAppSecret, config.sinaRedirectUrl);
        }
        if (!TextUtils.isEmpty(config.dingAppId)) {
            PlatformConfig.setDing(config.dingAppId);
        }
    }

    // ======================== 分享 ========================

    /**
     * 分享到指定平台
     *
     * @param platform    平台字符串枚举
     * @param shareParams 分享内容 { text, img, webUrl, title }
     * @param promise     Promise 回调
     */
    @ReactMethod
    public void share(String platform, ReadableMap shareParams, Promise promise) {
        SHARE_MEDIA media = resolveMedia(platform);
        if (media == null) {
            promise.reject("E_PLATFORM_UNSUPPORTED", "Unsupported platform: " + platform);
            return;
        }

        Activity activity = getCurrentActivity();
        if (activity == null) {
            promise.reject("E_NO_ACTIVITY", "Current activity is null");
            return;
        }

        String text = shareParams.hasKey("text") ? shareParams.getString("text") : "";
        String img = shareParams.hasKey("img") ? shareParams.getString("img") : "";
        String webUrl = shareParams.hasKey("webUrl") ? shareParams.getString("webUrl") : "";
        String title = shareParams.hasKey("title") ? shareParams.getString("title") : "";

        sMainHandler.post(() -> {
            ShareAction action = new ShareAction(activity)
                    .setPlatform(media)
                    .setCallback(createShareListener(promise));

            if (!TextUtils.isEmpty(webUrl)) {
                UMWeb web = new UMWeb(webUrl);
                web.setTitle(title);
                web.setDescription(text);
                UMImage thumb = getImage(activity, img);
                if (thumb != null) {
                    web.setThumb(thumb);
                }
                action.withText(text).withMedia(web).share();
            } else if (!TextUtils.isEmpty(img)) {
                UMImage image = getImage(activity, img);
                if (image != null) {
                    action.withText(text).withMedia(image).share();
                } else {
                    action.withText(text).share();
                }
            } else {
                action.withText(text).share();
            }
        });
    }

    /**
     * 弹出分享面板
     *
     * @param shareParams 分享内容
     * @param platforms   平台字符串枚举列表
     * @param promise     Promise 回调
     */
    @ReactMethod
    public void shareboard(ReadableMap shareParams, ReadableArray platforms, Promise promise) {
        Activity activity = getCurrentActivity();
        if (activity == null) {
            promise.reject("E_NO_ACTIVITY", "Current activity is null");
            return;
        }

        SHARE_MEDIA[] mediaArray = resolveMediaArray(platforms);

        String text = shareParams.hasKey("text") ? shareParams.getString("text") : "";
        String img = shareParams.hasKey("img") ? shareParams.getString("img") : "";
        String webUrl = shareParams.hasKey("webUrl") ? shareParams.getString("webUrl") : "";
        String title = shareParams.hasKey("title") ? shareParams.getString("title") : "";

        sMainHandler.post(() -> {
            ShareAction action = new ShareAction(activity)
                    .setDisplayList(mediaArray)
                    .setCallback(createShareListener(promise));

            if (!TextUtils.isEmpty(webUrl)) {
                UMWeb web = new UMWeb(webUrl);
                web.setTitle(title);
                web.setDescription(text);
                UMImage thumb = getImage(activity, img);
                if (thumb != null) {
                    web.setThumb(thumb);
                }
                action.withText(text).withMedia(web).open();
            } else if (!TextUtils.isEmpty(img)) {
                UMImage image = getImage(activity, img);
                if (image != null) {
                    action.withText(text).withMedia(image).open();
                } else {
                    action.withText(text).open();
                }
            } else {
                action.withText(text).open();
            }
        });
    }

    // ======================== 授权 ========================

    /**
     * 第三方平台授权登录
     *
     * @param platform 平台字符串枚举
     * @param promise  Promise 回调
     */
    @ReactMethod
    public void auth(String platform, Promise promise) {
        SHARE_MEDIA media = resolveMedia(platform);
        if (media == null) {
            promise.reject("E_PLATFORM_UNSUPPORTED", "Unsupported platform: " + platform);
            return;
        }

        Activity activity = getCurrentActivity();
        if (activity == null) {
            promise.reject("E_NO_ACTIVITY", "Current activity is null");
            return;
        }

        sMainHandler.post(() ->
            UMShareAPI.get(activity).getPlatformInfo(activity, media, new UMAuthListener() {
                @Override
                public void onStart(SHARE_MEDIA shareMedia) {
                    // no-op
                }

                @Override
                public void onComplete(SHARE_MEDIA shareMedia, int i, Map<String, String> map) {
                    WritableMap result = Arguments.createMap();
                    result.putInt("code", CODE_SUCCESS);
                    result.putString("message", "success");

                    WritableMap data = Arguments.createMap();
                    if (map != null) {
                        for (Map.Entry<String, String> entry : map.entrySet()) {
                            data.putString(entry.getKey(), entry.getValue());
                        }
                    }
                    result.putMap("data", data);
                    promise.resolve(result);
                }

                @Override
                public void onError(SHARE_MEDIA shareMedia, int i, Throwable throwable) {
                    String msg = throwable != null ? throwable.getMessage() : "auth failed";
                    promise.reject("E_AUTH_ERROR", msg, throwable);
                }

                @Override
                public void onCancel(SHARE_MEDIA shareMedia, int i) {
                    WritableMap result = Arguments.createMap();
                    result.putInt("code", CODE_CANCEL);
                    result.putString("message", "cancel");
                    result.putMap("data", Arguments.createMap());
                    promise.resolve(result);
                }
            })
        );
    }

    // ======================== 工具方法 ========================

    /**
     * 平台字符串 → SHARE_MEDIA
     */
    private static SHARE_MEDIA resolveMedia(String platform) {
        if (TextUtils.isEmpty(platform)) {
            return null;
        }
        return PLATFORM_MAP.get(platform);
    }

    /**
     * ReadableArray 中的平台字符串列表 → SHARE_MEDIA[]
     */
    private SHARE_MEDIA[] resolveMediaArray(ReadableArray array) {
        if (array == null || array.size() == 0) {
            return new SHARE_MEDIA[0];
        }
        SHARE_MEDIA[] medias = new SHARE_MEDIA[array.size()];
        int validCount = 0;
        for (int i = 0; i < array.size(); i++) {
            SHARE_MEDIA m = resolveMedia(array.getString(i));
            if (m != null) {
                medias[validCount++] = m;
            }
        }
        if (validCount < medias.length) {
            SHARE_MEDIA[] trimmed = new SHARE_MEDIA[validCount];
            System.arraycopy(medias, 0, trimmed, 0, validCount);
            return trimmed;
        }
        return medias;
    }

    /**
     * 创建分享回调监听器（Promise 版）
     */
    private UMShareListener createShareListener(final Promise promise) {
        return new UMShareListener() {
            @Override
            public void onStart(SHARE_MEDIA shareMedia) {
                // no-op
            }

            @Override
            public void onResult(SHARE_MEDIA shareMedia) {
                WritableMap result = Arguments.createMap();
                result.putInt("code", CODE_SUCCESS);
                result.putString("message", "success");
                promise.resolve(result);
            }

            @Override
            public void onError(SHARE_MEDIA shareMedia, Throwable throwable) {
                String msg = throwable != null ? throwable.getMessage() : "share failed";
                promise.reject("E_SHARE_ERROR", msg, throwable);
            }

            @Override
            public void onCancel(SHARE_MEDIA shareMedia) {
                WritableMap result = Arguments.createMap();
                result.putInt("code", CODE_CANCEL);
                result.putString("message", "cancel");
                promise.resolve(result);
            }
        };
    }

    /**
     * 解析图片资源（URL / 本地路径 / res 资源）
     */
    private static UMImage getImage(Activity activity, String url) {
        if (TextUtils.isEmpty(url)) {
            return null;
        }
        if (url.startsWith("http")) {
            return new UMImage(activity, url);
        } else if (url.startsWith("/")) {
            return new UMImage(activity, url);
        } else if (url.startsWith("res")) {
            return new UMImage(activity,
                    ResContainer.getResourceId(activity, "drawable", url.replace("res/", "")));
        } else {
            return new UMImage(activity, url);
        }
    }
}
