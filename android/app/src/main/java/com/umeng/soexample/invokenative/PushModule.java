package com.umeng.soexample.invokenative;

import android.app.Activity;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;

/**
 * Created by wangfei on 17/8/30.
 */

public class PushModule extends ReactContextBaseJavaModule {
    private ReactApplicationContext context;
    private boolean isGameInited = false;
    private static Activity ma;
    public PushModule(ReactApplicationContext reactContext) {
        super(reactContext);
        context = reactContext;
    }
    public static void initPushSDK(Activity activity){
        ma = activity;
    }
    @Override
    public String getName() {
        return "UMPushModule";
    }
}