//
//  UMAPMModule.h
//  umeng-react-native
//
//  友盟 APM 性能监控 React Native 桥接模块
//

#import <React/RCTBridgeModule.h>
#import "RNUMAPMConfig.h"

@interface UMAPMModule : NSObject <RCTBridgeModule>

/// 原生初始化入口（供宿主 AppDelegate 直接调用，无需模块实例）。
/// 内部完成 UMCrashConfigure 配置；必须在 UMConfigure initWithAppkey 之前调用才生效。
+ (void)initFromNative:(RNUMAPMConfig *)config;

@end
