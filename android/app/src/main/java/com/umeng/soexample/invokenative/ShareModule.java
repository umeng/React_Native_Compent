package com.umeng.soexample.invokenative;

import java.net.URLEncoder;
import java.util.Map;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableMap;
import com.umeng.commonsdk.framework.UMWorkDispatch;
import com.umeng.socialize.ShareAction;
import com.umeng.socialize.UMAuthListener;
import com.umeng.socialize.UMShareAPI;
import com.umeng.socialize.UMShareListener;
import com.umeng.socialize.bean.SHARE_MEDIA;
import com.umeng.socialize.common.ResContainer;
import com.umeng.socialize.media.UMImage;
import com.umeng.socialize.media.UMWeb;

/**
 * Created by wangfei on 17/8/28.
 */

public class ShareModule extends ReactContextBaseJavaModule {
    private static Activity ma;
    private static Handler mSDKHandler = new Handler(Looper.getMainLooper());
    private ReactApplicationContext contect;
    public ShareModule(ReactApplicationContext reactContext) {
        super(reactContext);
        contect = reactContext;

    }
    public static void initSocialSDK(Activity activity){
        ma = activity;
    }
    @Override
    public String getName() {
        return "share";
    }
    private static void runOnMainThread(Runnable runnable) {
        mSDKHandler.postDelayed(runnable, 0);
    }
    @ReactMethod
    public void share(final String text, final String img, final String weburl, final String title, final int sharemedia, final Callback successCallback){
        runOnMainThread(new Runnable() {
            @Override
            public void run() {

                if (!TextUtils.isEmpty(weburl)){
                    UMWeb web = new UMWeb(weburl);
                    web.setTitle(title);
                    web.setDescription(text);
                    if (getImage(img)!=null){
                        web.setThumb(getImage(img));
                    }
                    new ShareAction(ma).withText(text)
                        .withMedia(web)
                        .setPlatform(getShareMedia(sharemedia))
                        .setCallback(getUMShareListener(successCallback))
                        .share();
                }else if (getImage(img)!=null){
                    new ShareAction(ma).withText(text)
                        .withMedia(getImage(img))
                        .setPlatform(getShareMedia(sharemedia))
                        .setCallback(getUMShareListener(successCallback))
                        .share();
                }else {
                    new ShareAction(ma).withText(text)
                        .setPlatform(getShareMedia(sharemedia))
                        .setCallback(getUMShareListener(successCallback))
                        .share();
                }

            }
        });

    }
    private UMShareListener getUMShareListener(final Callback successCallback){
        return new UMShareListener() {
            @Override
            public void onStart(SHARE_MEDIA share_media) {

            }

            @Override
            public void onResult(SHARE_MEDIA share_media) {
                successCallback.invoke(0, "success");
            }

            @Override
            public void onError(SHARE_MEDIA share_media, Throwable throwable) {
                successCallback.invoke(1, throwable.getMessage());
            }

            @Override
            public void onCancel(SHARE_MEDIA share_media) {
                successCallback.invoke(2, "cancel");
            }
        };
    }
    private UMImage getImage(String url){
        if (TextUtils.isEmpty(url)){
            return null;
        }else if(url.startsWith("http")){
            return new UMImage(ma,url);
        }else if(url.startsWith("/")){
            return new UMImage(ma,url);
        }else if(url.startsWith("res")){
            return new UMImage(ma, ResContainer.getResourceId(ma,"drawable",url.replace("res/","")));
        }else {
            return new UMImage(ma,url);
        }
    }
    @ReactMethod
    public void auth(final int  sharemedia, final Callback successCallback){
        runOnMainThread(new Runnable() {
            @Override
            public void run() {
                UMShareAPI.get(ma).getPlatformInfo(ma, getShareMedia(sharemedia), new UMAuthListener() {
                    @Override
                    public void onStart(SHARE_MEDIA share_media) {

                    }

                    @Override
                    public void onComplete(SHARE_MEDIA share_media, int i, Map<String, String> map) {
                        WritableMap result = Arguments.createMap();
                        for (String key:map.keySet()){
                            result.putString(key,map.get(key));
                        }
                        successCallback.invoke(0,result,"success");
                    }

                    @Override
                    public void onError(SHARE_MEDIA share_media, int i, Throwable throwable) {
                        WritableMap result = Arguments.createMap();
                        successCallback.invoke(1,result,throwable.getMessage());
                    }

                    @Override
                    public void onCancel(SHARE_MEDIA share_media, int i) {
                        WritableMap result = Arguments.createMap();
                        successCallback.invoke(2,result,"cancel");
                    }
                });
            }
        });

    }

    @ReactMethod
    public void shareboard(final String text, final String img, final String weburl, final String title, final ReadableArray sharemedias, final Callback successCallback){
        runOnMainThread(new Runnable() {
            @Override
            public void run() {

                if (!TextUtils.isEmpty(weburl)){
                    UMWeb web = new UMWeb(weburl);
                    web.setTitle(title);
                    web.setDescription(text);
                    if (getImage(img)!=null){
                        web.setThumb(getImage(img));
                    }
                    new ShareAction(ma).withText(text)
                        .withMedia(web)
                        .setDisplayList(getShareMedias(sharemedias))
                        .setCallback(getUMShareListener(successCallback))
                        .open();
                }else if (getImage(img)!=null){
                    new ShareAction(ma).withText(text)
                        .withMedia(getImage(img))
                        .setDisplayList(getShareMedias(sharemedias))
                        .setCallback(getUMShareListener(successCallback))
                        .open();
                }else {
                    new ShareAction(ma).withText(text)
                        .setDisplayList(getShareMedias(sharemedias))
                        .setCallback(getUMShareListener(successCallback))
                        .open();
                }

            }
        });

    }
    private SHARE_MEDIA getShareMedia(int num){
        switch (num){
            case 0:
                return SHARE_MEDIA.QQ;

            case 1:
                return SHARE_MEDIA.SINA;

            case 2:
                return SHARE_MEDIA.WEIXIN;

            case 3:
                return SHARE_MEDIA.WEIXIN_CIRCLE;

            default:
                return SHARE_MEDIA.QQ;
        }
    }
    private SHARE_MEDIA[] getShareMedias(ReadableArray num){
        SHARE_MEDIA[] medias = new SHARE_MEDIA[num.size()];
        for (int i = 0 ; i <num.size();i++){
            medias[i] = getShareMedia(num.getInt(i));
        }
        return medias;
    }
}
