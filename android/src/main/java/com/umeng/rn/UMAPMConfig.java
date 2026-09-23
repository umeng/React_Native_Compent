package com.umeng.rn;

/**
 * UMAPMConfig - 友盟 APM 性能监控原生配置对象
 *
 * 用于 {@link UMAPMModule#init}，必须在 {@link RNUMConfigure#init} 之前调用，
 * 因为 UMCrash.initConfig / setAppVersion 只有在 UMConfigure.init 之前执行才生效。
 *
 * 设计动机：APM 配置不再经 JS 桥接下发（旧 setAPMConfig 桥接方法已移除），
 * 改由宿主在原生层构造本对象传入，避免 initConfig 时序失效问题。
 *
 * 崩溃与卡顿监控统一为单一开关 crashAndBlockMonitorEnable（对齐 iOS SDK），
 * 在 doInit 中同时写入 UMCrash 的 4 个 KEY_ENABLE_*：
 * KEY_ENABLE_CRASH_JAVA、KEY_ENABLE_CRASH_NATIVE、KEY_ENABLE_ANR、KEY_ENABLE_PA（卡顿）。
 */
public class UMAPMConfig {

    /**
     * 崩溃与卡顿监控（统一开关，对齐 iOS SDK crashAndBlockMonitorEnable）。
     * 同时作用于 KEY_ENABLE_CRASH_JAVA / KEY_ENABLE_CRASH_NATIVE / KEY_ENABLE_ANR / KEY_ENABLE_PA。
     */
    public boolean crashAndBlockMonitorEnable = true;

    /** 启动监控（KEY_ENABLE_LAUNCH） */
    public boolean launchMonitorEnable = true;

    /** 内存监控（KEY_ENABLE_MEM） */
    public boolean memMonitorEnable = false;

    /** 网络监控（KEY_ENABLE_NET） */
    public boolean networkEnable = false;

    /** 页面监控（KEY_ENABLE_PAGE） */
    public boolean pageMonitorEnable = true;

    /** 日志回捞（KEY_ENABLE_CODE_LOG） */
    public boolean logCollectEnable = true;

    /** H5 / JSBridge 监控（KEY_ENABLE_H5PAGE） */
    public boolean javaScriptBridgeEnable = false;

    /** 自定义 App 版本号；为 null 时不调用 UMCrash.setAppVersion */
    public String appVersion;

    /** 构建版本号；与 appVersion 配合使用 */
    public String buildVersion;
}
