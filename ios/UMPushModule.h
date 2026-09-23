//
//  UMPushModule.h
//  umeng-react-native
//
//  友盟推送 React Native 桥接模块
//  改为 RCTEventEmitter 以支持事件系统
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

@interface UMPushModule : RCTEventEmitter <RCTBridgeModule>

/**
 * 静态入口：通知到达时调用（在 AppDelegate 的 UNUserNotificationCenterDelegate
 * willPresentNotification 中，或 application:didReceiveRemoteNotification: 中）
 * 内部会向友盟回传送达/点击数据，并 emit UMPushOnNotificationReceive 到 JS 层
 */
+ (void)didReceiveUMessage:(NSDictionary *)userInfo;

/**
 * 静态入口：通知被点击时调用（在 AppDelegate 的 UNUserNotificationCenterDelegate
 * didReceiveNotificationResponse 中）
 * 内部会向友盟回传点击数据，并 emit UMPushOnNotificationOpen 到 JS 层
 */
+ (void)didOpenUMessage:(NSDictionary *)userInfo;

/**
 * 静态入口：APNs 注册成功拿到 deviceToken 时调用
 * （在 AppDelegate 的 application:didRegisterForRemoteNotificationsWithDeviceToken: 中）
 * 内部会向友盟上报 deviceToken，并 emit UMPushOnToken（hex 字符串）到 JS 层
 */
+ (void)didRegisterDeviceToken:(NSData *)deviceToken;

/**
 * 静态入口：APNs 注册失败时调用（可选，仅日志）
 */
+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

/**
 * 原生入口：隐私同意后自动注册推送
 * 宿主 AppDelegate 在 initUmengAfterConsent 中调用，无需 JS 侧手动触发 register()
 */
+ (void)registerFromNative;

@end
