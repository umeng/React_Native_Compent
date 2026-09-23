package com.umeng.rn;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.umeng.message.UmengNotifyClick;
import com.umeng.message.entity.UMessage;

import java.util.Map;
import java.util.Set;

/**
 * 离线消息点击入口 Activity
 *
 * 当应用未启动时，用户点击推送通知会启动此 Activity。
 * 消息缓存到 sOfflineMsgCache，在 UMPushModule.register() 成功后回放。
 */
public class UMOfflineMessageActivity extends Activity {

    private static final String TAG = "UMOfflineMsg";

    /**
     * 离线消息缓存，register() 成功后读取并置空
     */
    public static String sOfflineMsgCache;

    private final UmengNotifyClick mNotificationClick = new UmengNotifyClick() {
        @Override
        public void onMessage(UMessage msg) {
            try {
                String body = msg.getRaw().toString();
                Log.d(TAG, "offline msg: " + body);
                sOfflineMsgCache = body;
            } catch (Throwable e) {
                Log.w(TAG, "parse offline msg failed", e);
            }
            launchApp(msg);
            finish();
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mNotificationClick.onCreate(this, getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        mNotificationClick.onNewIntent(intent);
    }

    private void launchApp(UMessage msg) {
        try {
            String pkg = getPackageName();
            Intent intent = getPackageManager().getLaunchIntentForPackage(pkg);
            if (intent == null) {
                Log.e(TAG, "can't find launch activity: " + pkg);
                return;
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            addMessageToIntent(intent, msg);
            startActivity(intent);
            Log.i(TAG, "start app: " + pkg);
        } catch (Throwable e) {
            Log.e(TAG, "start app fail: " + e.getMessage());
        }
    }

    private void addMessageToIntent(Intent intent, UMessage msg) {
        if (intent == null || msg == null || msg.getExtra() == null) {
            return;
        }
        Set<Map.Entry<String, String>> entrySet = msg.getExtra().entrySet();
        for (Map.Entry<String, String> entry : entrySet) {
            String key = entry.getKey();
            String value = entry.getValue();
            if (key != null) {
                intent.putExtra(key, value);
            }
        }
    }
}
