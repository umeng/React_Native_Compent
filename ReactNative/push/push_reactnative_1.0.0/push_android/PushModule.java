package com.umeng.soexample.invokenative;

import android.app.Activity;
import java.util.List;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.widget.Toast;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
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
    private final int SUCCESS = 200;
    private final int ERROR = 0;
    private final int CANCEL = -1;
    private static final String TAG = PushModule.class.getSimpleName();
    private static Handler mSDKHandler = new Handler(Looper.getMainLooper());
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
    private static void runOnMainThread(Runnable runnable) {
        mSDKHandler.postDelayed(runnable, 0);
    }
    @ReactMethod
    public void addTag(String tag, final Callback successCallback) {
        mPushAgent.getTagManager().addTags(new TagManager.TCallBack() {
            @Override
            public void onMessage(final boolean isSuccess, final ITagManager.Result result) {


                        if (isSuccess) {
                            successCallback.invoke(SUCCESS,result.remain);
                        } else {
                            successCallback.invoke(ERROR,0);
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
                if (isSuccess) {
                    successCallback.invoke(SUCCESS,result.remain);
                } else {
                    successCallback.invoke(ERROR,0);
                }
            }
        }, tag);
    }

    @ReactMethod
    public void listTag(final Callback successCallback) {
        mPushAgent.getTagManager().getTags(new TagManager.TagListCallBack() {
            @Override
            public void onMessage(final boolean isSuccess, final List<String> result) {
                mSDKHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        if (isSuccess) {
                            if (result != null) {

                                successCallback.invoke(SUCCESS,resultToList(result));
                            } else {
                                successCallback.invoke(ERROR,resultToList(result));
                            }
                        } else {
                            successCallback.invoke(ERROR,resultToList(result));
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
            public void onMessage(final boolean isSuccess, final String message) {
                Log.i(TAG, "isSuccess:" + isSuccess + "," + message);

                        Log.e("xxxxxx","isuccess"+isSuccess);
                        if (isSuccess) {
                            successCallback.invoke(SUCCESS);
                        } else {
                            successCallback.invoke(ERROR);
                        }


            }
        });
    }

    @ReactMethod
    public void addAliasType() {
        Toast.makeText(ma,"function will come soon",Toast.LENGTH_LONG);
    }

    @ReactMethod
    public void addExclusiveAlias(String exclusiveAlias, String aliasType, final Callback successCallback) {
        mPushAgent.setAlias(exclusiveAlias, aliasType, new UTrack.ICallBack() {
            @Override
            public void onMessage(final boolean isSuccess, final String message) {

                        Log.i(TAG, "isSuccess:" + isSuccess + "," + message);
                        if (Boolean.TRUE.equals(isSuccess)) {
                            successCallback.invoke(SUCCESS);
                        }else {
                            successCallback.invoke(ERROR);
                        }



            }
        });
    }

    @ReactMethod
    public void deleteAlias(String alias, String aliasType, final Callback successCallback) {
        mPushAgent.deleteAlias(alias, aliasType, new UTrack.ICallBack() {
            @Override
            public void onMessage(boolean isSuccess, String s) {
                if (Boolean.TRUE.equals(isSuccess)) {
                    successCallback.invoke(SUCCESS);
                }else {
                    successCallback.invoke(ERROR);
                }
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
    private WritableMap resultToMap(ITagManager.Result result){
        WritableMap map = Arguments.createMap();
        if (result!=null){
            map.putString("status",result.status);
            map.putInt("remain",result.remain);
            map.putString("interval",result.interval+"");
            map.putString("errors",result.errors);
            map.putString("last_requestTime",result.last_requestTime+"");
            map.putString("jsonString",result.jsonString);
        }
        return map;
    }
    private WritableArray resultToList(List<String> result){
        WritableArray list = Arguments.createArray();
        if (result!=null){
            for (String key:result){
                list.pushString(key);
            }
        }
        Log.e("xxxxxx","list="+list);
        return list;
    }
}