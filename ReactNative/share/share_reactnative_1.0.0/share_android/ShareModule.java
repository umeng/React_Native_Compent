package com.umeng.soexample.invokenative;

import java.net.URLEncoder;
import java.util.Map;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;
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
    private final int SUCCESS = 200;
    private final int ERROR = 0;
    private final int CANCEL = -1;
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
        return "UMShareModule";
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
                successCallback.invoke(SUCCESS, "success");
            }

            @Override
            public void onError(SHARE_MEDIA share_media, Throwable throwable) {
                successCallback.invoke(ERROR, throwable.getMessage());
            }

            @Override
            public void onCancel(SHARE_MEDIA share_media) {
                successCallback.invoke(CANCEL, "cancel");
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
                            Log.e("todoremove","key="+key+"   value"+map.get(key).toString());
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
            case 4:
                return SHARE_MEDIA.QZONE;
            case 5:
                return SHARE_MEDIA.EMAIL;
            case 6:
                return SHARE_MEDIA.SMS;
            case 7:
                return SHARE_MEDIA.FACEBOOK;
            case 8:
                return SHARE_MEDIA.TWITTER;
            case 9:
                return SHARE_MEDIA.WEIXIN_FAVORITE;
            case 10:
                return SHARE_MEDIA.GOOGLEPLUS;
            case 11:
                return SHARE_MEDIA.RENREN;
            case 12:
                return SHARE_MEDIA.TENCENT;
            case 13:
                return SHARE_MEDIA.DOUBAN;
            case 14:
                return SHARE_MEDIA.FACEBOOK_MESSAGER;
            case 15:
                return SHARE_MEDIA.YIXIN;
            case 16:
                return SHARE_MEDIA.YIXIN_CIRCLE;
            case 17:
                return SHARE_MEDIA.INSTAGRAM;
            case 18:
                return SHARE_MEDIA.PINTEREST;
            case 19:
                return SHARE_MEDIA.EVERNOTE;
            case 20:
                return SHARE_MEDIA.POCKET;
            case 21:
                return SHARE_MEDIA.LINKEDIN;
            case 22:
                return SHARE_MEDIA.FOURSQUARE;
            case 23:
                return SHARE_MEDIA.YNOTE;
            case 24:
                return SHARE_MEDIA.WHATSAPP;
            case 25:
                return SHARE_MEDIA.LINE;
            case 26:
                return SHARE_MEDIA.FLICKR;
            case 27:
                return SHARE_MEDIA.TUMBLR;
            case 28:
                return SHARE_MEDIA.ALIPAY;
            case 29:
                return SHARE_MEDIA.KAKAO;
            case 30:
                return SHARE_MEDIA.DROPBOX;
            case 31:
                return SHARE_MEDIA.VKONTAKTE;
            case 32:
                return SHARE_MEDIA.DINGTALK;
            case 33:
                return SHARE_MEDIA.MORE;
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
