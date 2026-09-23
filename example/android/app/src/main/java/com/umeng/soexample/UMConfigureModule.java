package com.umeng.soexample;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.umeng.rn.RNUMConfigure;

/**
 * UMConfigureModule - 隐私合规初始化桥接模块
 *
 * 配合 App.tsx 的隐私政策弹窗使用：
 * - 用户点击「同意」→ JS 调用 initAfterConsent()，原生执行 submitPolicyGrantResult(true) + 正式 init
 * - 用户点击「不同意」→ JS 调用 submitReject()，原生执行 submitPolicyGrantResult(false)，不 init
 *
 * 时序说明：MainApplication.onCreate 阶段仅做 preInit（不采集设备信息），
 * 正式 init 由本模块在用户同意后触发，确保 SDK 不会在同意前采集数据。
 */
public class UMConfigureModule extends ReactContextBaseJavaModule {

    private static final String TAG = "UMConfigureModule";

    public UMConfigureModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @NonNull
    @Override
    public String getName() {
        return "UMConfigureModule";
    }

    /**
     * 用户同意隐私政策后调用：提交授权结果并执行正式初始化。
     * 带防重入守卫，冷启动已同意时再次调用为幂等空操作。
     */
    @ReactMethod
    public void initAfterConsent(Promise promise) {
        try {
            Context ctx = getReactApplicationContext().getApplicationContext();
            RNUMConfigure.submitPolicyGrantResult(ctx, true);
            if (ctx instanceof MainApplication) {
                ((MainApplication) ctx).initUmengAfterConsent(getReactApplicationContext());
                promise.resolve(true);
            } else {
                Log.w(TAG, "ApplicationContext is not MainApplication, skip init");
                promise.reject("E_INIT_AFTER_CONSENT", "ApplicationContext is not MainApplication");
            }
        } catch (Exception e) {
            Log.e(TAG, "initAfterConsent failed", e);
            promise.reject("E_INIT_AFTER_CONSENT", e.getMessage(), e);
        }
    }

    /**
     * 用户拒绝隐私政策后调用：仅提交授权结果，不执行初始化。
     */
    @ReactMethod
    public void submitReject(Promise promise) {
        try {
            Context ctx = getReactApplicationContext().getApplicationContext();
            RNUMConfigure.submitPolicyGrantResult(ctx, false);
            promise.resolve(true);
        } catch (Exception e) {
            Log.e(TAG, "submitReject failed", e);
            promise.reject("E_SUBMIT_REJECT", e.getMessage(), e);
        }
    }
}
