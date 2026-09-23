#import <RCTAppDelegate.h>
#import <UIKit/UIKit.h>

@interface AppDelegate : RCTAppDelegate

/// 用户同意隐私政策后调用，执行友盟 SDK 正式初始化
/// （APM 配置 → initWithAppkey → 分享平台配置）。
/// 由 UMConfigureModule.initAfterConsent 桥接触发。iOS UMCommon 7.6.7 无 preInit，故同意前不 init。
- (void)initUmengAfterConsent;

@end
