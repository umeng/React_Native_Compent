package com.umeng.rn;

/**
 * UMShareConfig - 友盟分享平台原生配置对象
 *
 * 用于 {@link UMShareModule#init}，在原生层完成各平台 AppId/AppSecret 配置。
 *
 * 设计动机：分享凭证不再经 JS 桥接下发（旧 UMShareModule.setSharePlatform 已移除），
 * 避免 AppId/AppSecret 进入可被解包提取的 JS bundle。
 *
 * 字段为 null 或空时，init 会跳过对应平台的配置（PlatformConfig.setXxx 不调用）。
 * 注意：QQ 隐私授权门 Tencent.setIsPermissionGranted 依赖宿主引入的 open_sdk jar，
 * 不在本库依赖范围内，需由宿主在 init 之后自行调用。
 */
public class UMShareConfig {

    /** FileProvider authority，需与宿主 AndroidManifest.xml 中声明保持一致 */
    public String fileProvider;

    /** 微信 AppId */
    public String weixinAppId;
    /** 微信 AppSecret */
    public String weixinAppSecret;

    /** QQ / QQ空间 AppId */
    public String qqAppId;
    /** QQ / QQ空间 AppKey */
    public String qqAppKey;

    /** 新浪微博 AppKey */
    public String sinaAppKey;
    /** 新浪微博 AppSecret */
    public String sinaAppSecret;
    /** 新浪微博 RedirectUrl */
    public String sinaRedirectUrl;

    /** 钉钉 AppId */
    public String dingAppId;
}
