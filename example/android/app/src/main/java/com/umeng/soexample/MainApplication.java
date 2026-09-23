package com.umeng.soexample;

import android.app.Application;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;

import com.facebook.react.PackageList;
import com.facebook.react.ReactApplication;
import com.facebook.react.ReactHost;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.defaults.DefaultNewArchitectureEntryPoint;
import com.facebook.react.defaults.DefaultReactHost;
import com.facebook.react.defaults.DefaultReactNativeHost;
import com.facebook.soloader.SoLoader;

import com.tencent.tauth.Tencent;
import com.umeng.commonsdk.UMConfigure;
import com.umeng.rn.RNUMConfigure;
import com.umeng.rn.UMAPMConfig;
import com.umeng.rn.UMAPMModule;
import com.umeng.rn.UMPushModule;
import com.umeng.rn.UMShareConfig;
import com.umeng.rn.UMShareModule;

import java.util.List;

public class MainApplication extends Application implements ReactApplication {

    // 友盟凭证（须与 build.gradle 的 manifestPlaceholders 保持一致）
    private static final String UMENG_APP_KEY = "59892f08310c9307b60023d0";
    private static final String UMENG_CHANNEL = "Umeng";
    private static final String UMENG_PUSH_SECRET = "669c30a9584623e70e8cd01b0381dcb4";

    // 防止重复初始化（冷启动已同意 + JS 再次调用时跳过）
    private static volatile boolean sUmengInitialized = false;

    private final ReactNativeHost mReactNativeHost =
        new DefaultReactNativeHost(this) {
            @Override
            protected List<ReactPackage> getPackages() {
                List<ReactPackage> packages = new PackageList(this).getPackages();
                // 隐私合规桥接模块：JS 同意隐私政策后触发原生正式初始化
                packages.add(new UMConfigurePackage());
                return packages;
            }

            @Override
            protected String getJSMainModuleName() {
                return "index";
            }

            @Override
            public boolean getUseDeveloperSupport() {
                return BuildConfig.DEBUG;
            }

            @Override
            protected boolean isNewArchEnabled() {
                return BuildConfig.IS_NEW_ARCHITECTURE_ENABLED;
            }

            @Override
            protected Boolean isHermesEnabled() {
                return BuildConfig.IS_HERMES_ENABLED;
            }
        };

    @Override
    public ReactNativeHost getReactNativeHost() {
        return mReactNativeHost;
    }

    public ReactHost getReactHost() {
        return DefaultReactHost.getDefaultReactHost(this.getApplicationContext(), getReactNativeHost());
    }

    @Override
    public void onCreate() {
        super.onCreate();
        SoLoader.init(this, false);
        if (BuildConfig.IS_NEW_ARCHITECTURE_ENABLED) {
            DefaultNewArchitectureEntryPoint.load();
        }
        // 隐私合规：用户同意前仅做 preInit（不采集设备信息），
        // 正式 init 延迟到用户同意后由 UMConfigureModule.initAfterConsent() 触发。
        RNUMConfigure.preInit(this, UMENG_APP_KEY, UMENG_CHANNEL);
    }

    /**
     * 用户同意隐私政策后调用，执行正式初始化。
     * 由 {@link UMConfigureModule#initAfterConsent} 桥接触发，带防重入守卫。
     */
    public void initUmengAfterConsent(ReactApplicationContext reactContext) {
        if (sUmengInitialized) {
            return;
        }
        sUmengInitialized = true;
        initUmeng(reactContext);
        // QQ 隐私授权门：依赖 example 引入的 open_sdk jar，库层不含此依赖，故留在宿主
        try {
            Tencent.setIsPermissionGranted(true);
        } catch (Throwable ignored) {
        }
    }

    private void initUmeng(ReactApplicationContext reactContext) {
        UMConfigure.setLogEnabled(true);

        // APM 配置：库层原生方法，必须在 init 之前执行才生效（友盟 SDK 时序约束）
        UMAPMConfig apmConfig = new UMAPMConfig();
        try {
            PackageInfo packageInfo = getPackageManager().getPackageInfo(getPackageName(), 0);
            apmConfig.appVersion = packageInfo.versionName;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                apmConfig.buildVersion = String.valueOf(packageInfo.getLongVersionCode());
            } else {
                //noinspection deprecation
                apmConfig.buildVersion = String.valueOf(packageInfo.versionCode);
            }
        } catch (PackageManager.NameNotFoundException ignored) {
        }
        // 经 ReactContext 取得 UMAPMModule 实例调用（与 push 一致的模式）；须在 UMConfigure.init 之前
        UMAPMModule apmModule = reactContext.getNativeModule(UMAPMModule.class);
        if (apmModule != null) {
            apmModule.initFromNative(apmConfig);
        }
        RNUMConfigure.init(this, UMENG_APP_KEY, UMENG_CHANNEL, UMConfigure.DEVICE_TYPE_PHONE, UMENG_PUSH_SECRET);

        // 分享平台配置：库层原生方法，凭证在原生层配置不经 JS
        UMShareConfig shareConfig = new UMShareConfig();
        shareConfig.fileProvider = getPackageName() + ".fileprovider";
        shareConfig.weixinAppId = "wxdc1e388c3822c80b";
        shareConfig.weixinAppSecret = "3baf1193c85774b3fd9d18447d76cab0";
        shareConfig.qqAppId = "101830139";
        shareConfig.qqAppKey = "5d63ae8858f1caab67715ccd6c18d7a5";
        shareConfig.sinaAppKey = "3921700954";
        shareConfig.sinaAppSecret = "04b48b094faeb16683c32669824ebdad";
        shareConfig.sinaRedirectUrl = "http://sns.whalecloud.com";
        shareConfig.dingAppId = "dingoalmlnohc0wggfedpk";
        // 经 ReactContext 取得 UMShareModule 实例调用（与 push 一致的模式）
        UMShareModule shareModule = reactContext.getNativeModule(UMShareModule.class);
        if (shareModule != null) {
            shareModule.initFromNative(shareConfig);
        }

        // 推送注册：经 ReactContext 取得 UMPushModule 实例，调用其完整注册逻辑
        // （handler/事件/厂商通道/离线消息），与 JS 侧 register(Promise) 共用 doRegister。
        UMPushModule pushModule = reactContext.getNativeModule(UMPushModule.class);
        if (pushModule != null) {
            pushModule.registerFromNative();
        }
    }
}
