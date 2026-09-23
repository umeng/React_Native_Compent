#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <React/RCTBridgeModule.h>
#import <UserNotifications/UserNotifications.h>

// 友盟 SDK 初始化
#import "RNUMConfigure.h"
#import "UMAPMModule.h"
#import "UMShareModule.h"
// 推送回调转发：桥接层静态入口内部已负责向 UMessage 回传数据 + emit 事件到 JS
#import "UMPushModule.h"

@interface AppDelegate () <UNUserNotificationCenterDelegate>
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = @"UmengReactNativeExample";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};

  // 尽早接管通知中心代理：系统只在 didFinishLaunching 返回后投递一次「点击通知拉起」的
  // didReceiveNotificationResponse，若等到用户同意隐私（JS 触发 initUmengAfterConsent）
  // 再设置，冷启动的点击回调会丢失。设置代理本身不采集任何设备信息，不违反隐私合规要求。
  [UNUserNotificationCenter currentNotificationCenter].delegate = self;

  // 隐私合规：iOS UMCommon 7.6.7 无 preInit/submitPolicyGrantResult，
  // 故启动阶段不做任何友盟初始化（未 init 即不采集设备信息）；
  // 正式 init 延迟到用户同意隐私政策后，由 UMConfigureModule.initAfterConsent
  // 触发 initUmengAfterConsent 执行（APM 配置 → initWithAppkey → 分享配置）。

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)initUmengAfterConsent
{
  // 防重入：冷启动已同意 + JS 再次调用时只初始化一次
  static BOOL sUmengInitialized = NO;
  if (sUmengInitialized) {
    return;
  }
  sUmengInitialized = YES;

  // 通知代理兜底再设一次（didFinishLaunching 已设，此处幂等，防宿主改走 JS 初始化路径时漏设）
  [UNUserNotificationCenter currentNotificationCenter].delegate = self;

  // APM 配置：构造 RNUMAPMConfig 交给 UMAPMModule（默认已开 crash/launch/page/logCollect），须在 initWithAppkey 之前
  RNUMAPMConfig *apmConfig = [RNUMAPMConfig new];
  [UMAPMModule initFromNative:apmConfig];

  // 友盟 SDK 正式初始化
  [RNUMConfigure initWithAppkey:@"59892ebcaed179694b000104" channel:@"Umeng"];

  // 分享平台配置：构造 RNUMShareConfig 交给 UMShareModule（内部切后台队列 + universalLink + setPlaform + @try 兜底）
  RNUMShareConfig *shareConfig = [RNUMShareConfig new];
  shareConfig.weixinAppId = @"wxdc1e388c3822c80b";
  shareConfig.weixinAppSecret = @"3baf1193c85774b3fd9d18447d76cab0";
  shareConfig.sinaAppKey = @"3921700954";
  shareConfig.sinaAppSecret = @"04b48b094faeb16683c32669824ebdad";
  shareConfig.sinaRedirectUrl = @"http://sns.whalecloud.com";
  shareConfig.qqAppId = @"101830139";
  shareConfig.qqAppKey = @"5d63ae8858f1caab67715ccd6c18d7a5";
  shareConfig.dingAppId = @"dingoalmlnohc0wggfedpk";
  shareConfig.universalLink = @"https://developer.umeng.com/";
  [UMShareModule initFromNative:shareConfig];

  // Push 自动注册
  [UMPushModule registerFromNative];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self getBundleURL];
}

- (NSURL *)getBundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

#pragma mark - APNs 注册回调

/// APNs 注册成功：交给桥接层上报友盟并 emit UMPushOnToken（JS 侧 UPush.addEventListener('token')）
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  [UMPushModule didRegisterDeviceToken:deviceToken];
}

/// APNs 注册失败（模拟器 / 无推送权限描述文件时常见）
- (void)application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  [UMPushModule didFailToRegisterForRemoteNotificationsWithError:error];
}

/// 后台静默推送（透传自定义消息，content-available=1）：iOS 10+ 不走通知中心代理，走这条旧回调
- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
  [UMPushModule didReceiveUMessage:userInfo];
  completionHandler(UIBackgroundFetchResultNewData);
}

#pragma mark - UNUserNotificationCenterDelegate

/// 前台收到通知：转发给桥接层 emit UMPushOnNotificationReceive，
/// 并通过 completionHandler 决定前台展示形式（不实现则前台不弹通知）
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
  NSDictionary *userInfo = notification.request.content.userInfo;
  [UMPushModule didReceiveUMessage:userInfo];

  // 工程 IPHONEOS_DEPLOYMENT_TARGET = 15.0，直接用 iOS 14+ 的 Banner（Alert 已废弃）；
  // 若宿主工程要兼容 iOS 13 及以下，需改用 @available 分支回退到 UNNotificationPresentationOptionAlert
  completionHandler(UNNotificationPresentationOptionBanner |
                    UNNotificationPresentationOptionSound |
                    UNNotificationPresentationOptionBadge);
}

/// 用户点击通知（含冷启动由通知拉起）：转发给桥接层 emit UMPushOnNotificationOpen，
/// JS 侧通过 UPush.addEventListener('notificationOpen', cb) 收到消息内容
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler
{
  NSDictionary *userInfo = response.notification.request.content.userInfo;
  [UMPushModule didOpenUMessage:userInfo];
  completionHandler();
}

@end

#pragma mark - UMConfigureModule（隐私合规初始化桥接模块）

/**
 * UMConfigureModule - 隐私合规初始化桥接模块
 *
 * 暴露 JS 接口：
 * - initAfterConsent：用户同意后调用，触发 AppDelegate.initUmengAfterConsent 正式初始化
 * - submitReject：用户拒绝时调用；iOS UMCommon 7.6.7 无 submitPolicyGrantResult，故为空操作
 *
 * 定义在 AppDelegate.mm 内（ObjC 允许一个 .m 含多个类），避免新增文件需改 project.pbxproj。
 * 经 RCT_EXPORT_MODULE 自动注册，JS 侧 NativeModules.UMConfigureModule 即可访问。
 */
@interface UMConfigureModule : NSObject <RCTBridgeModule>
@end

@implementation UMConfigureModule

RCT_EXPORT_MODULE(UMConfigureModule);

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(initAfterConsent:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
  if ([appDelegate respondsToSelector:@selector(initUmengAfterConsent)]) {
    [appDelegate initUmengAfterConsent];
    resolve(@(YES));
  } else {
    reject(@"E_INIT_AFTER_CONSENT", @"AppDelegate 未实现 initUmengAfterConsent", nil);
  }
}

RCT_EXPORT_METHOD(submitReject:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  // iOS UMCommon 7.6.7 无 submitPolicyGrantResult；用户拒绝即保持不 init
  resolve(@(YES));
}

@end
