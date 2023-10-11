package com.umeng.soexample.invokenative;

import android.app.Activity;

import java.util.List;

import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.umeng.message.MsgConstant;
import com.umeng.message.PushAgent;
import com.umeng.message.api.UPushAliasCallback;
import com.umeng.message.api.UPushRegisterCallback;
import com.umeng.message.api.UPushTagCallback;
import com.umeng.message.common.inter.ITagManager;

public class PushModule extends ReactContextBaseJavaModule {
    private final int SUCCESS = 200;
    private final int ERROR = 0;
    private final int CANCEL = -1;
    private static final String TAG = "PushModule";
    private static final Handler mSDKHandler = new Handler(Looper.getMainLooper());
    private final ReactApplicationContext context;
    private final PushAgent mPushAgent;

    public PushModule(ReactApplicationContext reactContext) {
        super(reactContext);
        context = reactContext;
        mPushAgent = PushAgent.getInstance(context);
    }

    public static void initPushSDK(Activity activity) {
    }

    @Override
    public String getName() {
        return "UMPushModule";
    }

    private static void runOnMainThread(Runnable runnable) {
        mSDKHandler.post(runnable);
    }

    @ReactMethod
    public void register(final Callback callback) {
        mPushAgent.setDisplayNotificationNumber(0);
        mPushAgent.register(new UPushRegisterCallback() {
            @Override
            public void onSuccess(String deviceToken) {
                callback.invoke(SUCCESS, deviceToken);
            }

            @Override
            public void onFailure(String code, String msg) {
                callback.invoke(ERROR, code, msg);
            }
        });
    }

    @ReactMethod
    public void getDeviceToken(Callback callback) {
        String deviceToken = mPushAgent.getRegistrationId();
        callback.invoke(deviceToken);
    }


    @ReactMethod
    public void addTag(String tag, final Callback successCallback) {
        mPushAgent.getTagManager().addTags(new UPushTagCallback<ITagManager.Result>() {
            @Override
            public void onMessage(final boolean isSuccess, final ITagManager.Result result) {
                if (isSuccess) {
                    successCallback.invoke(SUCCESS, result.remain);
                } else {
                    successCallback.invoke(ERROR, 0);
                }
            }
        }, tag);
    }

    @ReactMethod
    public void deleteTag(String tag, final Callback successCallback) {
        mPushAgent.getTagManager().deleteTags(new UPushTagCallback<ITagManager.Result>() {
            @Override
            public void onMessage(boolean isSuccess, final ITagManager.Result result) {
                if (isSuccess) {
                    successCallback.invoke(SUCCESS, result.remain);
                } else {
                    successCallback.invoke(ERROR, 0);
                }
            }
        }, tag);
    }

    @ReactMethod
    public void listTag(final Callback successCallback) {
        mPushAgent.getTagManager().getTags(new UPushTagCallback<List<String>>() {
            @Override
            public void onMessage(final boolean isSuccess, final List<String> result) {
                mSDKHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        if (isSuccess) {
                            if (result != null) {
                                successCallback.invoke(SUCCESS, resultToList(result));
                            } else {
                                successCallback.invoke(ERROR, resultToList(null));
                            }
                        } else {
                            successCallback.invoke(ERROR, resultToList(result));
                        }

                    }
                });

            }
        });
    }

    @ReactMethod
    public void addAlias(String alias, String aliasType, final Callback successCallback) {
        mPushAgent.addAlias(alias, aliasType, new UPushAliasCallback() {
            @Override
            public void onMessage(final boolean isSuccess, final String message) {
                Log.d(TAG, "isSuccess:" + isSuccess + "," + message);
                if (isSuccess) {
                    successCallback.invoke(SUCCESS);
                } else {
                    successCallback.invoke(ERROR);
                }


            }
        });
    }

    @ReactMethod
    public void addExclusiveAlias(String exclusiveAlias, String aliasType, final Callback successCallback) {
        mPushAgent.setAlias(exclusiveAlias, aliasType, new UPushAliasCallback() {
            @Override
            public void onMessage(final boolean isSuccess, final String message) {
                Log.i(TAG, "isSuccess:" + isSuccess + "," + message);
                if (Boolean.TRUE.equals(isSuccess)) {
                    successCallback.invoke(SUCCESS);
                } else {
                    successCallback.invoke(ERROR);
                }
            }
        });
    }

    @ReactMethod
    public void deleteAlias(String alias, String aliasType, final Callback successCallback) {
        mPushAgent.deleteAlias(alias, aliasType, new UPushAliasCallback() {
            @Override
            public void onMessage(boolean isSuccess, String s) {
                if (Boolean.TRUE.equals(isSuccess)) {
                    successCallback.invoke(SUCCESS);
                } else {
                    successCallback.invoke(ERROR);
                }
            }
        });
    }

    @ReactMethod
    public void appInfo(final Callback successCallback) {
        try {
            final String pkgName = context.getPackageName();
            final PackageInfo packageInfo = context.getPackageManager().getPackageInfo(pkgName, 0);
            mPushAgent.register(new UPushRegisterCallback() {
                @Override
                public void onSuccess(String deviceToken) {
                    String info = String.format("DeviceToken:%s\n" + "SdkVersion:%s\nAppVersionCode:%s\nAppVersionName:%s",
                            deviceToken, MsgConstant.SDK_VERSION,
                            packageInfo.versionCode, packageInfo.versionName);
                    successCallback.invoke("应用包名:" + pkgName + "\n" + info);
                }

                @Override
                public void onFailure(String code, String msg) {
                    String info = String.format("DeviceToken:%s\n" + "SdkVersion:%s\nAppVersionCode:%s\nAppVersionName:%s",
                            mPushAgent.getRegistrationId(), MsgConstant.SDK_VERSION,
                            packageInfo.versionCode, packageInfo.versionName);
                    successCallback.invoke("应用包名:" + pkgName + "\n" + info + "\n" + "code:" + code + "msg:" + msg);
                }
            });
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
        }
    }

    private WritableMap resultToMap(ITagManager.Result result) {
        WritableMap map = Arguments.createMap();
        if (result != null) {
            map.putString("status", result.status);
            map.putInt("remain", result.remain);
            map.putString("interval", result.interval + "");
            map.putString("errors", result.errors);
            map.putString("jsonString", result.jsonString);
        }
        return map;
    }

    private WritableArray resultToList(List<String> result) {
        WritableArray list = Arguments.createArray();
        if (result != null) {
            for (String key : result) {
                list.pushString(key);
            }
        }
        Log.d(TAG, "list=" + list);
        return list;
    }
}