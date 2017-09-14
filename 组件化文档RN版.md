# 工程配置
## Android
### 初始化

将下载的jar放入app下的libs中：

![](http://upload-images.jianshu.io/upload_images/1483670-67f20ad5d09b48c7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
首先需要拷贝common_android文件夹中的`DplusReactPackage.java`文件到你的工程中：

![](http://upload-images.jianshu.io/upload_images/1483670-2ac964446ec18042.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

然后再将对应平台的桥接文件拷入你的工程：

![](http://upload-images.jianshu.io/upload_images/1483670-dbc0763494fc54e6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
需要注意如果你拷入的路径不是`com.umeng.soexample.invokenative`请将桥接文件中的路径修改为你工程的路径：

![image.png](http://upload-images.jianshu.io/upload_images/1483670-88bae62879ffced7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
打开Application文件，添加`DplusReactPackage`：

```
 private final ReactNativeHost mReactNativeHost = new ReactNativeHost(this) {
        @Override
        public boolean getUseDeveloperSupport() {
            return BuildConfig.DEBUG;
        }

        @Override
        protected List<ReactPackage> getPackages() {
            return Arrays.<ReactPackage>asList(
                new MainReactPackage(),
                new DplusReactPackage()
            );
        }
    };
```

并在`onCreate()`中进行初始化：

```
 @Override
    public void onCreate() {
        super.onCreate();
        SoLoader.init(this, /* native exopackage */ false);
        RNUMConfigure.init(this, "59892f08310c9307b60023d0", "Umeng", UMConfigure.DEVICE_TYPE_PHONE,
            "669c30a9584623e70e8cd01b0381dcb4");
    }
```
 
 >`RNUMConfture.init`接口一共五个参数，其中第一个参数为Context，第二个参数为友盟Appkey，第三个参数为channel，第四个参数为应用类型（手机或平板），第五个参数为push的secret（如果没有使用push，可以为空）。

至此，所有的工程配置已经完成，接下来请按照各个组件的文档进行初始化。

## iOS
### 初始化
## 接口说明
# 统计
## Android
### 初始化
## iOS
### 初始化
在工程的 AppDelegate.m 文件中引入相关组件头文件 ，且在 application:didFinishLaunchingWithOptions: 方法中添加如下代码：

```
[MobClick setScenarioType:E_UM_NORMAL];

```
如果需要引入多个场景：

```
[MobClick setScenarioType:E_UM_E_UM_GAME|E_UM_DPLUS];

```

js部分首先需要引入`AnalyticsUtil`文件：

```
import AnalyticsUtil from './AnalyticsUtil'
```

## 接口说明
### 自定义事件
AnalyticsUtil.onEvent(eventId);

AnalyticsUtil.onEventWithLable(eventId,eventLabel);

AnalyticsUtil.onEventWithMap(eventId,eventData);

AnalyticsUtil.onEventWithMapAndCount(eventId,eventData,eventNum);

* eventId 为当前统计的事件ID
* eventLabel 为分类标签
* eventData 为当前事件的属性和取值（键值对），不能为空，如：{name:"umeng",sex:"man"}
* eventNum 用户每次触发的数值的分布情况，如事件持续时间、每次付款金额等

### 账号的统计
AnalyticsUtil.profileSignInWithPUID(puid);

* puid 用户账号ID.长度小于64字节

AnalyticsUtil.profileSignOff()；

 * 账号登出时需调用此接口，调用之后不再发送账号相关内容

### Dplus 统计
#### track事件
AnalyticsUtil.track(eventName);

AnalyticsUtil.trackWithMap(eventName, property);

* eventName 事件名称
* property 事件的自定义属性（可以包含多对“属性名-属性值”）,如：{name:"umeng",sex:"man"}

#### 超级属性

AnalyticsUtil.registerSuperProperty(property);

* property 事件的超级属性（可以包含多对“属性名-属性值”）,如：{name:"umeng",sex:"man"}

AnalyticsUtil.clearSuperProperties();

* 清空所有超级属性

#### 设置关注事件是否首次触发

AnalyticsUtil.setFirstLaunchEvent(eventList);

* eventList 只关注eventList前五个合法eventID.只要已经保存五个,此接口无效,如：["list1","list2","list3"]

### 游戏统计

#### 关卡
AnalyticsUtil.startLevel(level); //进入关卡

AnalyticsUtil.failLevel(level); //通过关卡

AnalyticsUtil.finishLevel(level); //完成关卡

* level 关卡ID

#### 充值

AnalyticsUtil.pay(cash, source, price);

AnalyticsUtil.payWithItem(cash, source, item, amount, price);

* cash 真实币数量，>=0的数,最多只保存小数点后2位
* source 支付渠道，1 ~ 99的整数, 其中1..20 是预定义含义,其余21-99需要在网站设置。
* coin 虚拟币数量，大于等于0的整数, 最多只保存小数点后2位
* item 道具ID
* amount 道具数量，大于0的整数
* price 虚拟币数量

#### 购买

AnalyticsUtil.buy(item, amount, price);

* item 道具ID
* amount 道具数量,大于0的整数
* price 道具单价

#### 消耗

AnalyticsUtil.use(item, amount, price);

* item 道具ID
* amount 道具数量,大于0的整数
* price 道具单价

#### 额外奖励

AnalyticsUtil.bonus(coin, source); //赠送金币

AnalyticsUtil.bonusWithItem(item, amount, price, source); //赠送道具

 * coin 虚拟币数量，大于0的整数, 最多只保存小数点后2位
 * source 奖励渠道，取值在 1~10 之间。“1”已经被预先定义为“系统奖励”，2~10 需要在网站设置含义
 * item 道具ID，非空字符串
 * amount 道具数量，大于0的整数
 * price 道具单价

#### 交易兑换货币

AnalyticsUtil.exchange(orderId, currencyAmount, currencyType, virtualAmount, channel);

* currencyAmount 现金或等价物总额
* currencyType 为ISO4217定义的3位字母代码，如CNY,USD等（如使用其它自定义等价物作为现金，可使￼用ISO4217中未定义的3位字母组合传入货币类型）￼
* virtualAmount 虚拟币数量
* channel 支付渠道
* orderId 交易订单ID


# 推送
## Android
### 初始化
首先，Android push需要让Android app依赖我们提供的push module，再根据文档进行相应的初始化。
找到React Native使用的Activity，添加初始化代码：

```
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
       PushModule.initPushSDK(this);
          }

```
UShare SDK 的平台配置与单独 Native 项目集成相同，请参考 [接入U-Share SDK](http://dev.umeng.com/sdk_integate/android_sdk/android_push_doc#1) 以及 [初始化设置部分](http://dev.umeng.com/sdk_integate/android_sdk/android_push_doc#2_1)


## iOS
### 初始化
Push SDK 的平台配置与单独 Native 项目集成相同，请参考 [接入Push SDK](http://dev.umeng.com/sdk_integate/ios-integrate-guide/push#1) 以及 [初始化设置部分](http://dev.umeng.com/sdk_integate/ios-integrate-guide/push#1)
## 接口说明
首先需要引入`PushUtil`文件：

```
import PushUtil from './PushUtil'
```
### 添加tag
```
 PushUtil.addTag(tag,(code,remain) =>{
            
        })
```
* tag 此参数为tag
* callback 第一个参数code为错误码，当为0时标记成功。remain为remain值



### 删除tag
```
  PushUtil.deleteTag(tag,(code,result) =>{
          
        })
```
* tag 此参数为tag
* callback 第一个参数code为错误码，当为0时标记成功。remain为remain值



### 展示tag
```
  PushUtil.listTag((code,result) =>{
            
        })
```

* callback 第一个参数code为错误码，当为0时标记成功。result为一个数组类型，内容为所有tag

### 添加Alias
```
PushUtil.addAlias(alias,type,(code) =>{
          
        })
```
* alias 此参数为alias
* type  此参数为alias type

### 添加额外Alias
```
PushUtil.addExclusiveAlias(alias,type,(code) =>{
          
        })
```
* alias 此参数为alias
* type  此参数为alias type

### 删除Alias
```
PushUtil.deleteAlias(alias,type,(code) =>{
          
        })
```
* alias 此参数为alias
* type  此参数为alias type

### appinfo
```
PushUtil.appInfo((result) =>{

        })
```
* callback result为一个字符串类型，标记结果

# Share
## Android
### 初始化
在Application中设置使用的三方平台的appkey：

```
 {

        PlatformConfig.setWeixin("wxdc1e388c3822c80b", "3baf1193c85774b3fd9d18447d76cab0");
        //豆瓣RENREN平台目前只能在服务器端配置
        PlatformConfig.setSinaWeibo("3921700954", "04b48b094faeb16683c32669824ebdad", "http://sns.whalecloud.com");
        PlatformConfig.setYixin("yxc0614e80c9304c11b0391514d09f13bf");
        PlatformConfig.setQQZone("100424468", "c7394704798a158208a74ab60104f0ba");

    }
```

找到React Native使用的Activity，添加初始化代码：

```
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ShareModule.initSocialSDK(this);
          }

```

并添加回调所需代码：

```
  @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        UMShareAPI.get(this).onActivityResult(requestCode, resultCode, data);
    }
```

分享其它工程配置请参照[分享工程配置](http://dev.umeng.com/sdk_integate/android_sdk/android_share_doc#1_3_2)

## iOS
### 初始化
UShare SDK 的平台配置与单独 Native 项目集成相同，请参考 [接入U-Share SDK](http://dev.umeng.com/social/ios/quick-integration#1_1) 以及 [初始化设置部分](http://dev.umeng.com/social/ios/quick-integration#2)

## 接口说明
首先需要引入`ShareUtil`文件：

```
import ShareUtile from './ShareUtil'
```
### 授权

授权代码可以直接使用`ShareUtile.auth(platform,callback)`，其中platform为平台id，callback为回调内容。
平台与id的对应关系如下：


| 平台 | id|
| -------- | -------- | 
| QQ     | 0     | 
| 新浪微博     | 1     | 
| 微信     | 2     | 
| 微信朋友圈     | 3     | 
| Qzone     | 4     | 
| 电子邮件     | 5     | 
| 短信     | 6     | 
| Facebook     | 7     | 
| Twitter     | 8     | 

回调示例如下：

```
  ShareUtile.auth(0,(code,result,message) =>{
            this.setState({result:message});
            if (code == 0){
                this.setState({result:result.uid});
            }
        });
```
其中code为错误码，当为0时标记为成功。
其中message为错误信息。
其中result属性如下：

| 属性 | 含义|
| -------- | -------- | 
| uid     | uid     | 
| screen_name     | 用户名     | 
| iconurl     | 头像     | 
| accessToken     | accessToken     | 
| refreshToken     | refreshToken| 
| gender     | gender     | 
| unionid     | unionid     | 
| openid     | openid     | 
| expires_in     | 过期时间     | 

### 分享
分享示例如下：

```
 ShareUtile.share(text,img,url,title,platform,(code,message) =>{
            this.setState({result:message});

        });
```

* text 为分享内容
* img 为图片地址，可以为链接，本地地址以及res图片（如果使用res,请使用如下写法：`res/icon.png`）
* url 为分享链接，可以为空
* title 为分享链接的标题
* platform为平台id，id对照表与授权相同
* callback中code为错误码，当为0时，标记成功。message为错误信息
 
### 分享面板
分享面板示例如下：

```
 ShareUtile.shareboard(text,img,url,title,list,(code,message) =>{
            this.setState({result:message});

        });
```

* text 为分享内容
* img 为图片地址，可以为链接，本地地址以及res图片（如果使用res,请使用如下写法：`res/icon.png`）
* url 为分享链接，可以为空
* title 为分享链接的标题
* list 为分享平台数组，如：` var list = [0,1,2]`
* callback中code为错误码，当为0时，标记成功。message为错误信息
