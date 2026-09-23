package com.umeng.soexample.wxapi;

import com.umeng.socialize.weixin.view.WXCallbackActivity;

/**
 * 微信分享 / 授权回调 Activity。
 *
 * <p>路径必须严格为 {@code ${applicationId}.wxapi.WXEntryActivity}，
 * 由微信 SDK 通过包名约定反射回调。当前 applicationId 为
 * {@code com.umeng.soexample}（官方 MultiFunctionAndroidMavenDemo 的包名），
 * Java 代码的包名（namespace）亦已统一为 {@code com.umeng.soexample}，
 * 因此本类位于 {@code com.umeng.soexample.wxapi} 包下。</p>
 */
public class WXEntryActivity extends WXCallbackActivity {
}
