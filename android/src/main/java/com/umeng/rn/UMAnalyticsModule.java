package com.umeng.rn;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;

import com.umeng.analytics.MobclickAgent;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * UMAnalyticsModule - 友盟统计 React Native 桥接模块
 *
 * 从旧 AnalyticsModule 迁移，关键变更：
 * - 修正 onEventWithLable 拼写 → onEventWithLabel
 * - getPreProperties 由 Callback 改为 Promise
 * - ReadableMap 转换逻辑抽取为工具方法
 * - 使用 Legacy Module 方式（ReactContextBaseJavaModule + @ReactMethod），
 *   首要保证编译运行，后续可切换为 TurboModule（继承 NativeUMAnalyticsSpec）
 */
public class UMAnalyticsModule extends ReactContextBaseJavaModule {

    private final ReactApplicationContext reactContext;

    public UMAnalyticsModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @NonNull
    @Override
    public String getName() {
        return "UMAnalyticsModule";
    }

    // ======================== 自定义事件 ========================

    @ReactMethod
    public void onEvent(String eventId) {
        MobclickAgent.onEvent(reactContext, eventId);
    }

    /**
     * 修正旧版拼写错误 onEventWithLable → onEventWithLabel
     */
    @ReactMethod
    public void onEventWithLabel(String eventId, String eventLabel) {
        MobclickAgent.onEvent(reactContext, eventId, eventLabel);
    }

    @ReactMethod
    public void onEventWithMap(String eventId, ReadableMap map) {
        Map<String, String> params = readableMapToStringMap(map);
        MobclickAgent.onEvent(reactContext, eventId, params);
    }

    @ReactMethod
    public void onEventWithMapAndCount(String eventId, ReadableMap map, int value) {
        Map<String, String> params = readableMapToStringMap(map);
        MobclickAgent.onEventValue(reactContext, eventId, params, value);
    }

    @ReactMethod
    public void onEventObject(String eventId, ReadableMap map) {
        Map<String, Object> params = readableMapToObjectMap(map);
        MobclickAgent.onEventObject(reactContext, eventId, params);
    }

    // ======================== 页面统计 ========================

    @ReactMethod
    public void onPageStart(String pageName) {
        MobclickAgent.onPageStart(pageName);
    }

    @ReactMethod
    public void onPageEnd(String pageName) {
        MobclickAgent.onPageEnd(pageName);
    }

    /**
     * 设置页面采集模式为自动
     */
    @ReactMethod
    public void setPageCollectionModeAuto() {
        MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.AUTO);
    }

    /**
     * 设置页面采集模式为手动
     */
    @ReactMethod
    public void setPageCollectionModeManual() {
        MobclickAgent.setPageCollectionMode(MobclickAgent.PageMode.MANUAL);
    }

    // ======================== 错误上报 ========================

    /**
     * 上报错误信息
     */
    @ReactMethod
    public void reportError(String error) {
        MobclickAgent.reportError(reactContext, error);
    }

    // ======================== 账号统计 ========================

    @ReactMethod
    public void profileSignInWithPUID(String puid) {
        MobclickAgent.onProfileSignIn(puid);
    }

    @ReactMethod
    public void profileSignInWithPUIDWithProvider(String provider, String puid) {
        MobclickAgent.onProfileSignIn(provider, puid);
    }

    @ReactMethod
    public void profileSignOff() {
        MobclickAgent.onProfileSignOff();
    }

    // ======================== 超级属性 ========================

    @ReactMethod
    public void registerPreProperties(ReadableMap map) {
        Map<String, Object> hashMap = readableMapToObjectMap(map);
        JSONObject json = new JSONObject();
        for (Map.Entry<String, Object> entry : hashMap.entrySet()) {
            try {
                json.put(entry.getKey(), entry.getValue());
            } catch (JSONException ignored) {
                // skip malformed entries
            }
        }
        MobclickAgent.registerPreProperties(reactContext, json);
    }

    @ReactMethod
    public void unregisterPreProperty(String propertyName) {
        MobclickAgent.unregisterPreProperty(reactContext, propertyName);
    }

    /**
     * Breaking change: 旧版使用 Callback，新版使用 Promise。
     */
    @ReactMethod
    public void getPreProperties(Promise promise) {
        try {
            JSONObject props = MobclickAgent.getPreProperties(reactContext);
            promise.resolve(props != null ? props.toString() : "{}");
        } catch (Exception e) {
            promise.reject("E_GET_PRE_PROPERTIES", e.getMessage(), e);
        }
    }

    @ReactMethod
    public void clearPreProperties() {
        MobclickAgent.clearPreProperties(reactContext);
    }

    // ======================== 首次启动事件 ========================

    @ReactMethod
    public void setFirstLaunchEvent(ReadableArray array) {
        List<String> list = new ArrayList<>();
        if (array != null) {
            for (int i = 0; i < array.size(); i++) {
                if (ReadableType.String == array.getType(i)) {
                    list.add(array.getString(i));
                } else {
                    // 非 String 类型统一转为字符串
                    list.add(String.valueOf(array.getDynamic(i)));
                }
            }
        }
        MobclickAgent.setFirstLaunchEvent(reactContext, list);
    }

    // ======================== 工具方法 ========================

    /**
     * ReadableMap → HashMap&lt;String, String&gt;
     */
    private static Map<String, String> readableMapToStringMap(ReadableMap map) {
        Map<String, String> result = new HashMap<>();
        if (map == null) {
            return result;
        }
        ReadableMapKeySetIterator iterator = map.keySetIterator();
        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            ReadableType type = map.getType(key);
            switch (type) {
                case String:
                    result.put(key, map.getString(key));
                    break;
                case Number:
                    result.put(key, String.valueOf(map.getDouble(key)));
                    break;
                case Boolean:
                    result.put(key, String.valueOf(map.getBoolean(key)));
                    break;
                default:
                    result.put(key, map.getDynamic(key).toString());
                    break;
            }
        }
        return result;
    }

    /**
     * ReadableMap → HashMap&lt;String, Object&gt;
     */
    private static Map<String, Object> readableMapToObjectMap(ReadableMap map) {
        Map<String, Object> result = new HashMap<>();
        if (map == null) {
            return result;
        }
        ReadableMapKeySetIterator iterator = map.keySetIterator();
        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            ReadableType type = map.getType(key);
            switch (type) {
                case String:
                    result.put(key, map.getString(key));
                    break;
                case Number:
                    result.put(key, map.getDouble(key));
                    break;
                case Boolean:
                    result.put(key, map.getBoolean(key));
                    break;
                case Map:
                    result.put(key, readableMapToObjectMap(map.getMap(key)));
                    break;
                case Array:
                    result.put(key, map.getArray(key).toString());
                    break;
                default:
                    result.put(key, null);
                    break;
            }
        }
        return result;
    }
}
