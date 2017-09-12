/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <UMCommon/UMConfigure.h>
#import <UMAnalytics/MobClick.h>
#import <UMShare/UMShare.h>


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  [UMConfigure setLogEnabled:YES];
  
  /* Umeng init */
  [MobClick setScenarioType:E_UM_GAME|E_UM_DPLUS];
  [UMConfigure initWithAppkey:@"599d6d81c62dca07c5001db6" channel:@"App Store"];

  /* Share init */
  [self setupUSharePlatforms];   // required: setting platforms on demand
  [self setupUShareSettings];
  
  NSURL *jsCodeLocation;

  jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.ios" fallbackResource:nil];

  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                      moduleName:@"UMComponent"
                                               initialProperties:nil
                                                   launchOptions:launchOptions];
  rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UIViewController *rootViewController = [UIViewController new];
  rootViewController.view = rootView;
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];
  return YES;
}

- (void)setupUShareSettings
{
  /*
   * 打开图片水印
   */
  //[UMSocialGlobal shareInstance].isUsingWaterMark = YES;
  
  /*
   * 关闭强制验证https，可允许http图片分享，但需要在info.plist设置安全域名
   <key>NSAppTransportSecurity</key>
   <dict>
   <key>NSAllowsArbitraryLoads</key>
   <true/>
   </dict>
   */
  [UMSocialGlobal shareInstance].isUsingHttpsWhenShareContent = NO;
  
}

- (void)setupUSharePlatforms
{
  /*
   设置微信的appKey和appSecret
   [微信平台从U-Share 4/5升级说明]http://dev.umeng.com/social/ios/%E8%BF%9B%E9%98%B6%E6%96%87%E6%A1%A3#1_1
   */
  [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_WechatSession appKey:@"wxdc1e388c3822c80b" appSecret:@"3baf1193c85774b3fd9d18447d76cab0" redirectURL:nil];
  /*
   * 移除相应平台的分享，如微信收藏
   */
  //[[UMSocialManager defaultManager] removePlatformProviderWithPlatformTypes:@[@(UMSocialPlatformType_WechatFavorite)]];
  
  /* 设置分享到QQ互联的appID
   * U-Share SDK为了兼容大部分平台命名，统一用appKey和appSecret进行参数设置，而QQ平台仅需将appID作为U-Share的appKey参数传进即可。
   100424468.no permission of union id
   [QQ/QZone平台集成说明]http://dev.umeng.com/social/ios/%E8%BF%9B%E9%98%B6%E6%96%87%E6%A1%A3#1_3
   */
  [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_QQ appKey:@"1105821097"/*设置QQ平台的appID*/  appSecret:nil redirectURL:nil];
  
  /*
   设置新浪的appKey和appSecret
   [新浪微博集成说明]http://dev.umeng.com/social/ios/%E8%BF%9B%E9%98%B6%E6%96%87%E6%A1%A3#1_2
   */
  [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Sina appKey:@"3921700954"  appSecret:@"04b48b094faeb16683c32669824ebdad" redirectURL:@"https://sns.whalecloud.com/sina2/callback"];
  
  /* 设置Twitter的appKey和appSecret */
  [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Twitter appKey:@"fB5tvRpna1CKK97xZUslbxiet"  appSecret:@"YcbSvseLIwZ4hZg9YmgJPP5uWzd4zr6BpBKGZhf07zzh3oj62K" redirectURL:nil];
  
  /* 设置Facebook的appKey和UrlString */
  [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Facebook appKey:@"506027402887373"  appSecret:nil redirectURL:@"http://www.umeng.com/social"];
}


//#define __IPHONE_10_0    100000
#if __IPHONE_OS_VERSION_MAX_ALLOWED > 100000
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
  //6.3的新的API调用，是为了兼容国外平台(例如:新版facebookSDK,VK等)的调用[如果用6.2的api调用会没有回调],对国内平台没有影响。
  BOOL result = [[UMSocialManager defaultManager]  handleOpenURL:url options:options];
  if (!result) {
    // 其他如支付等SDK的回调
  }
  return result;
}
#endif

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
  //6.3的新的API调用，是为了兼容国外平台(例如:新版facebookSDK,VK等)的调用[如果用6.2的api调用会没有回调],对国内平台没有影响
  BOOL result = [[UMSocialManager defaultManager] handleOpenURL:url sourceApplication:sourceApplication annotation:annotation];
  if (!result) {
    // 其他如支付等SDK的回调
  }
  return result;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
  BOOL result = [[UMSocialManager defaultManager] handleOpenURL:url];
  if (!result) {
    // 其他如支付等SDK的回调
  }
  return result;
}


@end
