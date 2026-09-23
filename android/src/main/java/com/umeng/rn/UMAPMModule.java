package com.umeng.rn;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.view.Choreographer;
import android.view.WindowManager;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.module.annotations.ReactModule;

import com.umeng.umcrash.UMCrash;
import com.umeng.umcrash.customlog.UAPMCustomLog;
import com.efs.sdk.launch.LaunchManager;
import com.umeng.pagesdk.PageManger;

import org.json.JSONArray;
import org.json.JSONObject;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * UMAPMModule - 友盟 APM 性能监控 React Native 桥接模块
 *
 * 全新模块，方法名直接对齐友盟官方 APM SDK 语义命名。
 * 使用 Legacy Module 方式（ReactContextBaseJavaModule + @ReactMethod），
 * 与 UMAnalyticsModule 保持一致。
 */
@ReactModule(name = "UMAPMModule")
public class UMAPMModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;

    // 页面性能/帧率/API 监控开关（默认开启，仅当配置显式关闭时生效）
    private boolean trackingPagePerf = true;
    private boolean trackingPageFps = true;
    private boolean trackingApi = true;
    // 运行环境与工程类型，用于丰富上报日志
    private String env = null;
    private int projectType = 0;

    // 页面性能打点：[0]=begin [1]=FP [2]=FCP [3]=TTI
    private final Map<String, long[]> pagePerfMarks = new ConcurrentHashMap<>();
    // 页面帧率采集记录
    private final Map<String, FpsRecord> fpsRecords = new ConcurrentHashMap<>();
    // HTTP API 请求记录
    private final Map<String, ApiRecord> apiRecords = new ConcurrentHashMap<>();
    // 主线程 Handler（Choreographer 需要在带 Looper 的线程上调度）
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    public UMAPMModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @NonNull
    @Override
    public String getName() {
        return "UMAPMModule";
    }

    // ======================== APM 初始化 ========================

    /**
     * JS 侧 APM 初始化接口（ReactMethod）：接收 TS 传入的配置对象，
     * 转换为 {@link UMAPMConfig} 后委托 {@link #doInit}。
     *
     * 注意：UMCrash.initConfig 只有在 UMConfigure.init 之前调用才生效。若宿主已在原生
     * init 流程配置过 APM，JS 再调用通常不再生效——本接口用于纯 JS 驱动初始化的场景，
     * 需在触发原生 UMConfigure.init 之前调用。
     */
    @ReactMethod
    public void init(ReadableMap config) {
        UMAPMConfig apmConfig = new UMAPMConfig();
        if (config != null) {
            if (config.hasKey("crashAndBlockMonitorEnable")) apmConfig.crashAndBlockMonitorEnable = config.getBoolean("crashAndBlockMonitorEnable");
            if (config.hasKey("launchMonitorEnable")) apmConfig.launchMonitorEnable = config.getBoolean("launchMonitorEnable");
            if (config.hasKey("memMonitorEnable")) apmConfig.memMonitorEnable = config.getBoolean("memMonitorEnable");
            if (config.hasKey("networkEnable")) apmConfig.networkEnable = config.getBoolean("networkEnable");
            if (config.hasKey("pageMonitorEnable")) apmConfig.pageMonitorEnable = config.getBoolean("pageMonitorEnable");
            if (config.hasKey("logCollectEnable")) apmConfig.logCollectEnable = config.getBoolean("logCollectEnable");
            if (config.hasKey("javaScriptBridgeEnable")) apmConfig.javaScriptBridgeEnable = config.getBoolean("javaScriptBridgeEnable");
            if (config.hasKey("appVersion")) apmConfig.appVersion = config.getString("appVersion");
            if (config.hasKey("buildVersion")) apmConfig.buildVersion = config.getString("buildVersion");
        }
        doInit(apmConfig);
    }

    /**
     * 原生初始化时调用：执行与 {@link #init(ReadableMap)} 完全相同的 APM 配置逻辑。
     * 由宿主在 initUmeng 中经 ReactContext.getNativeModule(UMAPMModule.class) 取得实例后调用
     * （须在 UMConfigure.init 之前）。
     *
     * @param config APM 配置对象；为 null 时跳过
     */
    public void initFromNative(UMAPMConfig config) {
        doInit(config);
    }

    /**
     * APM 配置核心逻辑：写 UMCrash Bundle 开关并 initConfig、setAppVersion。
     * JS 与原生两条入口共用此方法，避免逻辑重复。
     * 友盟时序约束：UMCrash.initConfig 与 setAppVersion 必须在 UMConfigure.init 之前执行才生效。
     */
    private void doInit(UMAPMConfig config) {
        if (config == null) {
            return;
        }
        Bundle bundle = new Bundle();
        // 崩溃与卡顿监控：统一开关同时写入 4 个 key（对齐 iOS 单一 crashAndBlockMonitorEnable）
        bundle.putBoolean(UMCrash.KEY_ENABLE_CRASH_JAVA, config.crashAndBlockMonitorEnable);
        bundle.putBoolean(UMCrash.KEY_ENABLE_CRASH_NATIVE, config.crashAndBlockMonitorEnable);
        bundle.putBoolean(UMCrash.KEY_ENABLE_ANR, config.crashAndBlockMonitorEnable);
        bundle.putBoolean(UMCrash.KEY_ENABLE_PA, config.crashAndBlockMonitorEnable);
        bundle.putBoolean(UMCrash.KEY_ENABLE_LAUNCH, config.launchMonitorEnable);
        bundle.putBoolean(UMCrash.KEY_ENABLE_MEM, config.memMonitorEnable);
        bundle.putBoolean(UMCrash.KEY_ENABLE_NET, config.networkEnable);
        bundle.putBoolean(UMCrash.KEY_ENABLE_PAGE, config.pageMonitorEnable);
        bundle.putBoolean(UMCrash.KEY_ENABLE_CODE_LOG, config.logCollectEnable);
        bundle.putBoolean(UMCrash.KEY_ENABLE_H5PAGE, config.javaScriptBridgeEnable);
        UMCrash.initConfig(bundle);
        if (!TextUtils.isEmpty(config.appVersion)) {
            UMCrash.setAppVersion(config.appVersion, "", config.buildVersion != null ? config.buildVersion : "");
        }
    }

    // ======================== 异常上报 ========================

    /**
     * 上报自定义异常
     *
     * @param name       异常类型名称
     * @param reason     异常原因描述
     * @param stackTrace 调用栈信息数组
     * @param extra      附加信息（键值对），会以 JSON 形式附加到错误信息中
     */
    @ReactMethod
    public void reportException(String name, String reason, ReadableArray stackTrace, ReadableMap extra) {
        if (TextUtils.isEmpty(name)) {
            return;
        }
        try {
            String stackTraceStr = readableArrayToStackString(stackTrace);
            String content = buildExceptionString(name, reason, stackTraceStr);
            String extraJson = readableMapToJson(extra);
            // 仅当 extra 非空对象时才附加
            if (!TextUtils.isEmpty(extraJson) && !"{}".equals(extraJson)) {
                content = content + "\nextra:" + extraJson;
            }
            UMCrash.generateCustomLog(content, name);
        } catch (Throwable e) {
            // SDK 未初始化或内部异常时静默降级，避免应用崩溃
            android.util.Log.w("UMAPMModule", "reportException failed: " + e.getMessage());
        }
    }

    // ======================== 自定义日志 ========================

    /**
     * 自定义日志（用于崩溃附加信息、日志回捞等）
     *
     * @param tag     日志标签
     * @param message 日志内容
     * @param level   日志级别（verbose/debug/info/warn/error）
     */
    @ReactMethod
    public void log(String tag, String message, String level) {
        if (TextUtils.isEmpty(message)) {
            return;
        }
        if (level == null) level = "info";
        switch (level.toLowerCase()) {
            case "verbose":
            case "v":
                UAPMCustomLog.v(tag, message);
                break;
            case "debug":
            case "d":
                UAPMCustomLog.d(tag, message);
                break;
            case "warn":
            case "warning":
            case "w":
                UAPMCustomLog.w(tag, message);
                break;
            case "error":
            case "e":
                UAPMCustomLog.e(tag, message);
                break;
            default: // info
                UAPMCustomLog.i(tag, message);
                break;
        }
    }

    // ======================== 自定义维度 ========================

    /**
     * 设置自定义字符串参数
     */
    @ReactMethod
    public void setCustomStringParam(String key, String value) {
        if (TextUtils.isEmpty(key)) {
            return;
        }
        UMCrash.addCustomInfo(key, value != null ? value : "");
    }

    // ======================== 启动耗时 ========================

    /**
     * 标记启动开始
     */
    @ReactMethod
    public void beginLaunch(String methodName) {
        if (TextUtils.isEmpty(methodName)) {
            return;
        }
        Context context = getReactApplicationContext();
        if (context != null) {
            LaunchManager.onTraceBegin(context, methodName, System.currentTimeMillis());
        }
    }

    /**
     * 标记启动结束
     */
    @ReactMethod
    public void endLaunch(String methodName) {
        if (TextUtils.isEmpty(methodName)) {
            return;
        }
        Context context = getReactApplicationContext();
        if (context != null) {
            LaunchManager.onTraceEnd(context, methodName, System.currentTimeMillis());
        }
    }

    // ======================== 页面耗时 ========================

    /**
     * 标记页面加载开始
     */
    @ReactMethod
    public void beginPageTrace(String methodName) {
        if (TextUtils.isEmpty(methodName)) {
            return;
        }
        Activity activity = getCurrentActivity();
        if (activity != null) {
            PageManger.onTracePageBegin(activity, methodName);
        }
    }

    /**
     * 标记页面加载结束
     */
    @ReactMethod
    public void endPageTrace(String methodName) {
        if (TextUtils.isEmpty(methodName)) {
            return;
        }
        Activity activity = getCurrentActivity();
        if (activity != null) {
            PageManger.onTracePageEnd(activity, methodName);
        }
    }

    // ======================== 页面性能追踪（FP/FCP/TTI）========================
    //
    // 说明：友盟原生 APM SDK（PageManger）仅提供页面加载耗时打点，
    // 未暴露 FP/FCP/TTI 细粒度指标 API。此处采用"时间戳记录"方式在原生侧计算各阶段耗时，并通过
    // UMCrash.generateCustomLog 以自定义日志形式上报。

    @ReactMethod
    public void beginPagePerf(String pageName) {
        if (TextUtils.isEmpty(pageName) || !trackingPagePerf) {
            return;
        }
        long[] marks = new long[4];
        marks[0] = System.currentTimeMillis();
        pagePerfMarks.put(pageName, marks);
    }

    @ReactMethod
    public void markPageFP(String pageName) {
        setPerfMark(pageName, 1);
    }

    @ReactMethod
    public void markPageFCP(String pageName) {
        setPerfMark(pageName, 2);
    }

    @ReactMethod
    public void markPageTTI(String pageName) {
        setPerfMark(pageName, 3);
    }

    @ReactMethod
    public void endPagePerf(String pageName) {
        if (TextUtils.isEmpty(pageName) || !trackingPagePerf) {
            return;
        }
        long[] marks = pagePerfMarks.remove(pageName);
        if (marks == null || marks[0] <= 0) {
            return;
        }
        JSONObject json = new JSONObject();
        try {
            json.put("page", pageName);
            json.put("fp", marks[1] > 0 ? marks[1] - marks[0] : -1);
            json.put("fcp", marks[2] > 0 ? marks[2] - marks[0] : -1);
            json.put("tti", marks[3] > 0 ? marks[3] - marks[0] : -1);
            appendCommonFields(json);
        } catch (Throwable ignored) {
        }
        reportPerfLog("rn_page_perf", json.toString());
    }

    private void setPerfMark(String pageName, int index) {
        if (TextUtils.isEmpty(pageName) || !trackingPagePerf) {
            return;
        }
        long[] marks = pagePerfMarks.get(pageName);
        if (marks != null) {
            marks[index] = System.currentTimeMillis();
        }
    }

    // ======================== 页面帧率追踪 ========================
    //
    // 通过 Choreographer 帧回调统计 begin/end 之间的刷新帧数，
    // 计算平均 FPS，再以自定义日志形式上报。

    @ReactMethod
    public void beginPageFps(String pageName) {
        if (TextUtils.isEmpty(pageName) || !trackingPageFps) {
            return;
        }
        // 若已有同名采集，先停止
        stopFpsRecord(pageName);
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                final FpsRecord record = new FpsRecord();
                record.startTime = System.nanoTime();
                record.callback = new Choreographer.FrameCallback() {
                    @Override
                    public void doFrame(long frameTimeNanos) {
                        if (record.running) {
                            record.frameCount++;
                            Choreographer.getInstance().postFrameCallback(this);
                        }
                    }
                };
                fpsRecords.put(pageName, record);
                Choreographer.getInstance().postFrameCallback(record.callback);
            }
        });
    }

    @ReactMethod
    public void endPageFps(String pageName) {
        if (TextUtils.isEmpty(pageName) || !trackingPageFps) {
            return;
        }
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                FpsRecord record = fpsRecords.remove(pageName);
                if (record == null) {
                    return;
                }
                record.running = false;
                if (record.callback != null) {
                    Choreographer.getInstance().removeFrameCallback(record.callback);
                }
                long elapsedNs = System.nanoTime() - record.startTime;
                double fps = elapsedNs > 0
                        ? record.frameCount * 1_000_000_000.0 / elapsedNs
                        : 0;
                JSONObject json = new JSONObject();
                try {
                    json.put("page", pageName);
                    json.put("fps", Math.round(fps * 100.0) / 100.0);
                    json.put("frames", record.frameCount);
                    json.put("duration", Math.round(elapsedNs / 1_000_000.0));
                    appendCommonFields(json);
                } catch (Throwable ignored) {
                }
                reportPerfLog("rn_page_fps", json.toString());
            }
        });
    }

    private void stopFpsRecord(String pageName) {
        FpsRecord record = fpsRecords.remove(pageName);
        if (record != null) {
            record.running = false;
            if (record.callback != null) {
                Choreographer.getInstance().removeFrameCallback(record.callback);
            }
        }
    }

    // ======================== HTTP API 监控 ========================
    //
    // 原生 APM SDK 的 NetManager 为内部 HTTP 客户端，未提供针对业务请求的
    // begin/end 打点 API。此处以时间戳记录方式统计请求耗时，并以自定义日志上报。

    @ReactMethod
    public void trackApiBegin(String requestId, String uri, String method) {
        if (TextUtils.isEmpty(requestId) || !trackingApi) {
            return;
        }
        apiRecords.put(requestId, new ApiRecord(uri, method, System.currentTimeMillis()));
    }

    @ReactMethod
    public void trackApiEnd(String requestId, int statusCode, int spend, int reqSize,
                            int resSize, int type, String message) {
        if (TextUtils.isEmpty(requestId) || !trackingApi) {
            return;
        }
        ApiRecord record = apiRecords.remove(requestId);
        long beginTime = record != null ? record.beginTime : System.currentTimeMillis();
        String uri = record != null ? record.uri : "";
        String method = record != null ? record.method : "";
        long realSpend = spend > 0 ? spend : (System.currentTimeMillis() - beginTime);
        JSONObject json = new JSONObject();
        try {
            json.put("requestId", requestId);
            json.put("uri", uri);
            json.put("method", method);
            json.put("statusCode", statusCode);
            json.put("spend", realSpend);
            json.put("reqSize", reqSize);
            json.put("resSize", resSize);
            json.put("type", type);
            json.put("message", message != null ? message : "");
            appendCommonFields(json);
        } catch (Throwable ignored) {
        }
        reportPerfLog("rn_api", json.toString());
    }

    // ======================== 版本设置 ========================

    /**
     * 设置自定义 App 版本
     *
     * @param appVersion   应用版本号
     * @param buildVersion 构建版本号
     */
    @ReactMethod
    public void setAppVersion(String appVersion, String buildVersion) {
        if (TextUtils.isEmpty(appVersion)) {
            return;
        }
        UMCrash.setAppVersion(appVersion, "", buildVersion != null ? buildVersion : "");
    }

    // ======================== SDK 信息查询 ========================

    /**
     * 获取原生 APM SDK 版本号
     * （通过反射读取 UMCrash.crashSdkVersion）
     */
    @ReactMethod
    public void getSdkVersion(Promise promise) {
        String version = "";
        try {
            Class<?> umCrashClass = Class.forName("com.umeng.umcrash.UMCrash");
            Field ver = umCrashClass.getDeclaredField("crashSdkVersion");
            ver.setAccessible(true);
            Object value = ver.get(null);
            if (value != null) {
                version = value.toString();
            }
        } catch (Throwable ignored) {
        }
        if (promise != null) {
            promise.resolve(version);
        }
    }

    /**
     * 获取设备最大刷新率（FPS）
     * 优先使用 PageManger.getRefreshRate()，失败时回退到 WindowManager。
     */
    @ReactMethod
    public void getDeviceMaxFps(Promise promise) {
        float fps = -1f;
        try {
            fps = PageManger.getRefreshRate();
        } catch (Throwable ignored) {
        }
        if (fps <= 0) {
            try {
                Context context = getReactApplicationContext();
                if (context != null) {
                    WindowManager wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
                    if (wm != null && wm.getDefaultDisplay() != null) {
                        fps = wm.getDefaultDisplay().getRefreshRate();
                    }
                }
            } catch (Throwable ignored) {
            }
        }
        if (promise != null) {
            promise.resolve((double) fps);
        }
    }

    // ======================== 工具方法 ========================

    /**
     * ReadableArray → 换行分隔的堆栈字符串
     */
    private static String readableArrayToStackString(ReadableArray array) {
        if (array == null || array.size() == 0) {
            return "";
        }
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < array.size(); i++) {
            if (i > 0) {
                sb.append("\n");
            }
            if (ReadableType.String == array.getType(i)) {
                sb.append(array.getString(i));
            } else {
                sb.append(String.valueOf(array.getDynamic(i)));
            }
        }
        return sb.toString();
    }

    /**
     * 构建异常描述字符串
     */
    private static String buildExceptionString(String name, String reason, String stackTrace) {
        StringBuilder sb = new StringBuilder();
        sb.append(name);
        if (!TextUtils.isEmpty(reason)) {
            sb.append(": ").append(reason);
        }
        if (!TextUtils.isEmpty(stackTrace)) {
            sb.append("\n").append(stackTrace);
        }
        return sb.toString();
    }

    /**
     * ReadableMap → JSON 字符串（用于 reportException 的 extra 参数）
     * 内部走递归转换，嵌套的 Map / Array 会保留原有结构。
     */
    private static String readableMapToJson(ReadableMap map) {
        if (map == null) {
            return "";
        }
        try {
            return readableMapToJsonObject(map).toString();
        } catch (Throwable e) {
            return "";
        }
    }

    /**
     * ReadableMap → JSONObject（递归）：String / Number / Boolean / Null 直接映射，
     * 嵌套 Map 转为 JSONObject、嵌套 Array 转为 JSONArray，避免数组被降级成字符串。
     */
    private static JSONObject readableMapToJsonObject(ReadableMap map) {
        JSONObject json = new JSONObject();
        if (map == null) {
            return json;
        }
        ReadableMapKeySetIterator iterator = map.keySetIterator();
        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            try {
                switch (map.getType(key)) {
                    case String:
                        json.put(key, map.getString(key));
                        break;
                    case Number:
                        json.put(key, numberToJsonValue(map.getDouble(key)));
                        break;
                    case Boolean:
                        json.put(key, map.getBoolean(key));
                        break;
                    case Map: {
                        ReadableMap nested = map.getMap(key);
                        json.put(key, nested != null ? readableMapToJsonObject(nested) : JSONObject.NULL);
                        break;
                    }
                    case Array: {
                        ReadableArray nested = map.getArray(key);
                        json.put(key, nested != null ? readableArrayToJsonArray(nested) : JSONObject.NULL);
                        break;
                    }
                    case Null:
                    default:
                        json.put(key, JSONObject.NULL);
                        break;
                }
            } catch (Throwable ignored) {
                // 单个字段转换失败不影响其余字段
            }
        }
        return json;
    }

    /**
     * ReadableArray → JSONArray（递归）：元素类型处理规则与 {@link #readableMapToJsonObject} 一致，
     * 支持任意层级的 Map / Array 嵌套。
     */
    private static JSONArray readableArrayToJsonArray(ReadableArray array) {
        JSONArray json = new JSONArray();
        if (array == null) {
            return json;
        }
        for (int i = 0; i < array.size(); i++) {
            try {
                switch (array.getType(i)) {
                    case String:
                        json.put(array.getString(i));
                        break;
                    case Number:
                        json.put(numberToJsonValue(array.getDouble(i)));
                        break;
                    case Boolean:
                        json.put(array.getBoolean(i));
                        break;
                    case Map: {
                        ReadableMap nested = array.getMap(i);
                        json.put(nested != null ? readableMapToJsonObject(nested) : JSONObject.NULL);
                        break;
                    }
                    case Array: {
                        ReadableArray nested = array.getArray(i);
                        json.put(nested != null ? readableArrayToJsonArray(nested) : JSONObject.NULL);
                        break;
                    }
                    case Null:
                    default:
                        json.put(JSONObject.NULL);
                        break;
                }
            } catch (Throwable ignored) {
                // 单个元素转换失败不影响其余元素
            }
        }
        return json;
    }

    /**
     * JS Number → JSON 值：整数值保持整数形态（避免 1 被写成 1.0），
     * NaN / Infinity 无法用 JSON 数字表示，退化为字符串。
     */
    private static Object numberToJsonValue(double value) {
        if (Double.isNaN(value) || Double.isInfinite(value)) {
            return String.valueOf(value);
        }
        long asLong = (long) value;
        // 2^53 以内可保证 double → long → double 无损
        if ((double) asLong == value && Math.abs(value) <= 9007199254740992.0) {
            return asLong;
        }
        return value;
    }

    /**
     * 为性能日志附加公共字段（env / projectType / 时间戳）
     */
    private void appendCommonFields(JSONObject json) {
        try {
            if (!TextUtils.isEmpty(env)) {
                json.put("env", env);
            }
            json.put("projectType", projectType);
            json.put("ts", System.currentTimeMillis());
        } catch (Throwable ignored) {
        }
    }

    /**
     * 以自定义日志形式上报性能数据
     */
    private static void reportPerfLog(String type, String content) {
        try {
            UMCrash.generateCustomLog(content, type);
        } catch (Throwable ignored) {
        }
    }

    /**
     * 页面帧率采集记录
     */
    private static class FpsRecord {
        long startTime;
        int frameCount;
        volatile boolean running = true;
        Choreographer.FrameCallback callback;
    }

    /**
     * HTTP API 请求记录
     */
    private static class ApiRecord {
        final String uri;
        final String method;
        final long beginTime;

        ApiRecord(String uri, String method, long beginTime) {
            this.uri = uri;
            this.method = method;
            this.beginTime = beginTime;
        }
    }
}
