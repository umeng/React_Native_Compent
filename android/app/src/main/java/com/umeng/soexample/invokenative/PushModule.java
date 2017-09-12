package com.umeng.soexample.invokenative;

import android.app.Activity;
import java.util.List;
import android.os.Handler;
import android.util.Log;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.umeng.message.MsgConstant;
import com.umeng.message.PushAgent;
import com.umeng.message.UTrack;
import com.umeng.message.common.UmengMessageDeviceConfig;
import com.umeng.message.common.inter.ITagManager;
import com.umeng.message.tag.TagManager;

/**
 * Created by wangfei on 17/8/30
 */

public class PushModule extends ReactContextBaseJavaModule {

    private static final String TAG = PushModule.class.getSimpleName();

    private ReactApplicationContext context;
    private boolean isGameInited = false;
    private static Activity ma;
    private PushAgent mPushAgent;
    private Handler handler;

    public PushModule(ReactApplicationContext reactContext) {
        super(reactContext);
        context = reactContext;
        mPushAgent = PushAgent.getInstance(context);
    }

    public static void initPushSDK(Activity activity) {
        ma = activity;
    }

    @Override
    public String getName() {
        return "UMPushModule";
    }

    @ReactMethod
    public void addTag(String tag, final Callback successCallback) {
        mPushAgent.getTagManager().addTags(new TagManager.TCallBack() {
            @Override
            public void onMessage(final boolean isSuccess, final ITagManager.Result result) {
                successCallback.invoke("");
                if (isSuccess) {
                    successCallback.invoke("Add Tag:" + result);
                } else {
                    successCallback.invoke("Add Tag:" + "加入tag失败");
                }

            }
        }, tag);
    }

    @ReactMethod
    public void deleteTag(String tag, final Callback successCallback) {
        mPushAgent.getTagManager().deleteTags(new TagManager.TCallBack() {
            @Override
            public void onMessage(boolean isSuccess, final ITagManager.Result result) {
                Log.i(TAG, "isSuccess:" + isSuccess);
                if (isSuccess) { Log.i(TAG, "deletTag was set successfully."); }
                successCallback.invoke("delet Tags:" + (isSuccess ? "Success" : "Fail"));
            }
        }, tag);
    }

    @ReactMethod
    public void listTag(final Callback successCallback) {
        mPushAgent.getTagManager().getTags(new TagManager.TagListCallBack() {
            @Override
            public void onMessage(final boolean isSuccess, final List<String> result) {
                handler.post(new Runnable() {
                    @Override
                    public void run() {
                        if (isSuccess) {
                            if (result != null) {
                                StringBuilder info = new StringBuilder();
                                info.append("Tags:");
                                for (int i = 0; i < result.size(); i++) {
                                    String tag = result.get(i);
                                    info.append("\n" + tag);
                                }
                                successCallback.invoke(info.toString());
                            } else {
                                successCallback.invoke("");
                            }
                        } else {
                            successCallback.invoke("Tags获取失败");
                        }

                    }
                });

            }
        });
    }

    @ReactMethod
    public void addAlias(String alias, String aliasType, final Callback successCallback) {
        mPushAgent.addAlias(alias, aliasType, new UTrack.ICallBack() {
            @Override
            public void onMessage(boolean isSuccess, String message) {
                Log.i(TAG, "isSuccess:" + isSuccess + "," + message);
                if (isSuccess) { Log.i(TAG, "alias was set successfully."); }
                successCallback.invoke("", "", "Add Alias:" + (isSuccess ? "Success" : "Fail"));
            }
        });
    }

    @ReactMethod
    public void addAliasType() {

    }

    @ReactMethod
    public void addExclusiveAlias(String exclusiveAlias, String aliasType, final Callback successCallback) {
        mPushAgent.setAlias(exclusiveAlias, aliasType, new UTrack.ICallBack() {
            @Override
            public void onMessage(boolean isSuccess, String message) {
                Log.i(TAG, "isSuccess:" + isSuccess + "," + message);
                if (Boolean.TRUE.equals(isSuccess)) {
                    Log.i(TAG, "Exclusive alias was set successfully.");
                }
                successCallback.invoke("", "Add Exclusive Alias:" + (isSuccess ? "Success" : "Fail"));
            }
        });
    }

    @ReactMethod
    public void deleteAlias(String alias, String aliasType, final Callback successCallback) {
        mPushAgent.deleteAlias(alias, aliasType, new UTrack.ICallBack() {
            @Override
            public void onMessage(boolean isSuccess, String s) {
                if (Boolean.TRUE.equals(isSuccess)) {
                    Log.i(TAG, "Delete alias was set successfully.");
                }

                successCallback.invoke("", "", "Delete Alias:" + (isSuccess ? "Success" : "Fail"));
            }
        });
    }

    @ReactMethod
    public void appInfo(final Callback successCallback) {
        String pkgName = context.getPackageName();
        String info = String.format("DeviceToken:%s\n" + "SdkVersion:%s\nAppVersionCode:%s\nAppVersionName:%s",
            mPushAgent.getRegistrationId(), MsgConstant.SDK_VERSION,
            UmengMessageDeviceConfig.getAppVersionCode(context), UmengMessageDeviceConfig.getAppVersionName(context));
        successCallback.invoke("应用包名:" + pkgName + "\n" + info);
    }
}