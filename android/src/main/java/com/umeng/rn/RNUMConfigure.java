package com.umeng.rn;

import android.content.Context;

import com.umeng.commonsdk.UMConfigure;

import java.lang.reflect.Method;

/**
 * RNUMConfigure - 友盟 SDK 初始化配置
 *
 * 从旧版 RNUMConfigure 迁移，关键变更：
 * - wrapper 版本标识更新为 "3.0"
 * - 简化 init 方法签名（device type 固定为 DEVICE_TYPE_PHONE）
 * - 保留旧版 5 参数重载用于需要自定义 device type 的场景
 */
public class RNUMConfigure {

    private static final String WRAPPER_TYPE = "react-native";
    private static final String WRAPPER_VERSION = "3.0";

    /**
     * 标准初始化（推荐）
     *
     * @param context  Application Context
     * @param appKey   友盟 AppKey
     * @param channel  渠道名
     * @param logEnabled 是否开启日志（1=开启，0=关闭）
     */
    public static void init(Context context, String appKey, String channel, int logEnabled) {
        setWraperType();
        UMConfigure.setLogEnabled(logEnabled == 1);
        UMConfigure.init(context, appKey, channel, UMConfigure.DEVICE_TYPE_PHONE, "");
    }

    /**
     * 完整初始化（兼容旧版调用方式）
     *
     * @param context  Application Context
     * @param appKey   友盟 AppKey
     * @param channel  渠道名
     * @param type     设备类型（UMConfigure.DEVICE_TYPE_PHONE / DEVICE_TYPE_BOX）
     * @param secret   Push Secret（无推送可传空串）
     */
    public static void init(Context context, String appKey, String channel, int type, String secret) {
        setWraperType();
        UMConfigure.init(context, appKey, channel, type, secret);
    }

    /**
     * 预初始化（隐私合规：用户同意隐私政策前调用）
     *
     * preInit 不会采集任何设备信息，仅完成 SDK 内部准备工作。
     * 用户同意后须再调用 {@link #submitPolicyGrantResult} 与 {@link #init} 完成正式初始化。
     *
     * @param context  Application Context
     * @param appKey   友盟 AppKey
     * @param channel  渠道名
     */
    public static void preInit(Context context, String appKey, String channel) {
        setWraperType();
        UMConfigure.preInit(context, appKey, channel);
    }

    /**
     * 提交隐私政策授权结果（隐私合规：用户做出选择后调用）
     *
     * @param context  Application Context
     * @param granted  true=用户同意，false=用户拒绝
     */
    public static void submitPolicyGrantResult(Context context, boolean granted) {
        UMConfigure.submitPolicyGrantResult(context, granted);
    }

    /**
     * 通过反射设置 wrapper 类型，避免编译期直接依赖
     */
    private static void setWraperType() {
        try {
            Class<?> config = Class.forName("com.umeng.commonsdk.UMConfigure");
            Method method = config.getDeclaredMethod("setWraperType", String.class, String.class);
            method.setAccessible(true);
            method.invoke(null, WRAPPER_TYPE, WRAPPER_VERSION);
        } catch (Exception e) {
            // 忽略：可能 SDK 版本不包含此方法
        }
    }
}
