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
 * 当用户点击厂商通道的离线通知（无论应用是否已运行）时会启动此 Activity。
 * 点击事件统一交给 {@link UMPushModule#deliverNotificationOpenEvent(String)} 交付：
 * - 热启动（模块已创建、JS 已监听）→ 立即发送到 JS；
 * - 冷启动（模块尚未创建 / JS 尚未监听）→ 进入待回放队列，
 *   待 JS 订阅或 UMPushModule.register() 成功后补发。
 */
public class UMOfflineMessageActivity extends Activity {

    private static final String TAG = "UMOfflineMsg";

    /**
     * @deprecated 点击事件已改由 {@link UMPushModule#deliverNotificationOpenEvent(String)} 统一交付，
     * 本字段仅保留以兼容旧宿主代码，不再由本 Activity 写入。
     */
    @Deprecated
    public static String sOfflineMsgCache;

    private final UmengNotifyClick mNotificationClick = new UmengNotifyClick() {
        @Override
        public void onMessage(UMessage msg) {
            try {
                String body = msg.getRaw().toString();
                Log.d(TAG, "offline msg: " + body);
                // 统一交付入口：JS 监听就绪则立即发送，否则入队待回放
                UMPushModule.deliverNotificationOpenEvent(body);
            } catch (Throwable e) {
                Log.w(TAG, "deliver offline msg failed", e);
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
