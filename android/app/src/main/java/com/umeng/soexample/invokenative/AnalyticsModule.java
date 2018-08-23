package com.umeng.soexample.invokenative;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.json.JSONObject;
import org.json.JSONException;
import java.util.Iterator;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableNativeMap;
import com.facebook.react.bridge.ReadableType;
import com.umeng.analytics.MobclickAgent;

/**
 * Created by wangfei on 17/8/28.
 */

public class AnalyticsModule extends ReactContextBaseJavaModule {
    private ReactApplicationContext context;
    private boolean isGameInited = false;
    public AnalyticsModule(ReactApplicationContext reactContext) {
        super(reactContext);
        context = reactContext;
    }

    @Override
    public String getName() {
        return "UMAnalyticsModule";
    }
    @ReactMethod
    private void initGame() {
        //UMGameAgent.init(context);
        //UMGameAgent.setPlayerLevel(1);

        isGameInited = true;
    }
    /********************************U-App统计*********************************/
    @ReactMethod
    public void onPageStart(String mPageName) {
        android.util.Log.e("xxxxxx","onPageStart="+mPageName);

        MobclickAgent.onPageStart(mPageName);
    }

    @ReactMethod
    public void onPageEnd(String mPageName) {
        android.util.Log.e("xxxxxx","onPageEnd="+mPageName);

        MobclickAgent.onPageEnd(mPageName);

    }
    @ReactMethod
    public void onEvent(String eventId) {
        MobclickAgent.onEvent(context, eventId);
    }
    @ReactMethod
    public void onEventWithLable(String eventId,String eventLabel) {
        MobclickAgent.onEvent(context, eventId, eventLabel);
    }
    @ReactMethod
    public void onEventWithMap(String eventId,ReadableMap map) {
        Map<String, String> rMap = new HashMap<String, String>();
        ReadableMapKeySetIterator iterator = map.keySetIterator();
        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            if (ReadableType.Array == map.getType(key)) {
                rMap.put(key, map.getArray(key).toString());
            } else if (ReadableType.Boolean == map.getType(key)) {
                rMap.put(key, String.valueOf(map.getBoolean(key)));
            } else if (ReadableType.Number == map.getType(key)) {
                rMap.put(key, String.valueOf(map.getInt(key)));
            } else if (ReadableType.String == map.getType(key)) {
                rMap.put(key, map.getString(key));
            } else if (ReadableType.Map == map.getType(key)) {
                rMap.put(key, map.getMap(key).toString());
            }
        }
        MobclickAgent.onEvent(context, eventId, rMap);
    }
    @ReactMethod
    public void onEventWithMapAndCount(String eventId,ReadableMap map,int value) {
        Map<String, String> rMap = new HashMap();
        ReadableMapKeySetIterator iterator = map.keySetIterator();
        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            if (ReadableType.Array == map.getType(key)) {
                rMap.put(key, map.getArray(key).toString());
            } else if (ReadableType.Boolean == map.getType(key)) {
                rMap.put(key, String.valueOf(map.getBoolean(key)));
            } else if (ReadableType.Number == map.getType(key)) {
                rMap.put(key, String.valueOf(map.getInt(key)));
            } else if (ReadableType.String == map.getType(key)) {
                rMap.put(key, map.getString(key));
            } else if (ReadableType.Map == map.getType(key)) {
                rMap.put(key, map.getMap(key).toString());
            }
        }
        MobclickAgent.onEventValue(context, eventId, rMap, value);
    }
    /********************************U-App(Game)统计*********************************/
    //@ReactMethod
    //public void track(String eventName) {
    //    Log.e("xxxxxx dddddd="+context);
    //    UMADplus.track(context,eventName);
    //}
    @ReactMethod
    public void onEventObject(String eventID,ReadableMap property) {
        Map<String, Object> map = new HashMap();
        ReadableMapKeySetIterator iterator = property.keySetIterator();
        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            if (ReadableType.Array == property.getType(key)) {
                map.put(key, property.getArray(key).toString());
            } else if (ReadableType.Boolean == property.getType(key)) {
                map.put(key, String.valueOf(property.getBoolean(key)));
            } else if (ReadableType.Number == property.getType(key)) {
                map.put(key, String.valueOf(property.getInt(key)));
            } else if (ReadableType.String == property.getType(key)) {
                map.put(key, property.getString(key));
            } else if (ReadableType.Map == property.getType(key)) {
                map.put(key, property.getMap(key).toString());
            }
        }

        MobclickAgent.onEventObject(context, eventID, map);

    }
    @ReactMethod
    public void registerSuperProperty(ReadableMap map) {
        ReadableNativeMap map2 = (ReadableNativeMap) map;
        Map<String, Object> map3  = map2.toHashMap();
        Iterator entries = map3.entrySet().iterator();
        JSONObject json = new JSONObject();
        while (entries.hasNext()) {
            Map.Entry entry = (Map.Entry) entries.next();
            String key = (String)entry.getKey();
            String value = (String)entry.getValue();
            try {
                json.put(key,value);
            }catch (JSONException e){

            }
        }
        MobclickAgent.registerPreProperties(context,json);
    }
    @ReactMethod
    public void unregisterSuperProperty(String propertyName) {
        MobclickAgent.unregisterPreProperty(context, propertyName);

    }

    @ReactMethod
    public void getSuperProperties(Callback callback) {
        String result = MobclickAgent.getPreProperties(context).toString();
        callback.invoke(result);
    }
    @ReactMethod
    public void clearSuperProperties() {
        MobclickAgent.clearPreProperties(context);

    }
    @ReactMethod
    public void setFirstLaunchEvent(ReadableArray array) {
        List<String> list = new ArrayList();
        for (int i = 0; i < array.size(); i++) {
            if (ReadableType.Array == array.getType(i)) {
                list.add(array.getArray(i).toString());
            } else if (ReadableType.Boolean == array.getType(i)) {
                list.add(String.valueOf(array.getBoolean(i)));
            } else if (ReadableType.Number == array.getType(i)) {
                list.add(String.valueOf(array.getInt(i)));
            } else if (ReadableType.String == array.getType(i)) {
                list.add(array.getString(i));
            } else if (ReadableType.Map == array.getType(i)) {
                list.add(array.getMap(i).toString());
            }
        }
        MobclickAgent.setFirstLaunchEvent(context, list);
    }
    /********************************U-Dplus*********************************/
    @ReactMethod
    public void profileSignInWithPUID(String puid) {
        MobclickAgent.onProfileSignIn(puid);
    }

    @ReactMethod
    @SuppressWarnings("unused")
    public void profileSignInWithPUIDWithProvider(String puid, String provider) {
        MobclickAgent.onProfileSignIn(puid, provider);
    }

    @ReactMethod
    @SuppressWarnings("unused")
    public void profileSignOff() {
        MobclickAgent.onProfileSignOff();
    }

    //@ReactMethod
    //@SuppressWarnings("unused")
    //public void setUserLevelId(int level) {
    //    if (!isGameInited) {
    //        initGame();
    //    }
    //    UMGameAgent.setPlayerLevel(level);
    //}
    //
    //@ReactMethod
    //@SuppressWarnings("unused")
    //public void startLevel(String level) {
    //    if (!isGameInited) {
    //        initGame();
    //    }
    //    UMGameAgent.startLevel(level);
    //}
    //
    //@ReactMethod
    //@SuppressWarnings("unused")
    //public void failLevel(String level) {
    //    if (!isGameInited) {
    //        initGame();
    //    }
    //    UMGameAgent.failLevel(level);
    //}
    //
    //@ReactMethod
    //@SuppressWarnings("unused")
    //public void finishLevel(String level) {
    //    if (!isGameInited) {
    //        initGame();
    //    }
    //    UMGameAgent.finishLevel(level);
    //}
    //
    //@ReactMethod
    //@SuppressWarnings("unused")
    //public void exchange(double currencyAmount, String currencyType, double virtualAmount, int channel,
    //                     String orderId) {
    //    if (!isGameInited) {
    //        initGame();
    //    }
    //    UMGameAgent.exchange(currencyAmount, currencyType, virtualAmount, channel, orderId);
    //}
    //
    //@ReactMethod
    //@SuppressWarnings("unused")
    //public void pay(double money, double coin, int source) {
    //    if (!isGameInited) {
    //        initGame();
    //    }
    //    UMGameAgent.pay(money, coin, source);
    //}
    //
    //@ReactMethod
    //@SuppressWarnings("unused")
    //public void payWithItem(double money, String item, int number, double price, int source) {
    //    if (!isGameInited) {
    //        initGame();
    //    }
    //    UMGameAgent.pay(money, item, number, price, source);
    //}
    //
    //@ReactMethod
    //@SuppressWarnings("unused")
    //public void buy(String item, int number, double price) {
    //    if (!isGameInited) {
    //        initGame();
    //    }
    //    UMGameAgent.buy(item, number, price);
    //}
    //
    //@ReactMethod
    //@SuppressWarnings("unused")
    //public void use(String item, int number, double price) {
    //    if (!isGameInited) {
    //        initGame();
    //    }
    //    UMGameAgent.use(item, number, price);
    //}
    //
    //@ReactMethod
    //@SuppressWarnings("unused")
    //public void bonus(double coin, int source) {
    //    if (!isGameInited) {
    //        initGame();
    //    }
    //    UMGameAgent.bonus(coin, source);
    //}
    //
    //@ReactMethod
    //@SuppressWarnings("unused")
    //public void bonusWithItem(String item, int number, double price, int source) {
    //    if (!isGameInited) {
    //        initGame();
    //    }
    //    UMGameAgent.bonus(item, number, price, source);
    //}
}
