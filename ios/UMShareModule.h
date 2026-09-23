//
//  UMShareModule.h
//  umeng-react-native
//
//  友盟分享 React Native 桥接模块
//

#import <React/RCTBridgeModule.h>
#import "RNUMShareConfig.h"

@interface UMShareModule : NSObject <RCTBridgeModule>

/// 原生初始化入口（供宿主 AppDelegate 直接调用，无需模块实例）。
/// 内部切后台队列先设 universalLinkDic 再 setPlaform:，
/// 规避主线程 watchdog（0x8BADF00D）与微博 universalLink 空值断言崩溃。
+ (void)initFromNative:(RNUMShareConfig *)config;

@end
