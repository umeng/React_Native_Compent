package com.umeng.soexample.invokenative;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;

/**
 * Created by wangfei on 17/8/30.
 */

public class PushModule extends ReactContextBaseJavaModule {
    private ReactApplicationContext context;
    private boolean isGameInited = false;

    public PushModule(ReactApplicationContext reactContext) {
        super(reactContext);
        context = reactContext;
    }

    @Override
    public String getName() {
        return "push";
    }
}