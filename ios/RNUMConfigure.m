//
//  RNUMConfigure.m
//  umeng-react-native
//
//  友盟 SDK 初始化配置
//
//  从旧版 RNUMConfigure 迁移，关键变更：
//  - wrapper 版本标识更新为 "3.0"
//  - 补充 preInit / submitPolicyGrantResult 的 no-op 导出，与 Android 端保持 JS 调用面对称
//    （iOS UMCommon 7.6.7 无对应原生 API，隐私合规由 iOS 系统机制约束）
//

#import "RNUMConfigure.h"

#import <React/RCTBridgeModule.h>

@implementation RNUMConfigure

RCT_EXPORT_MODULE(RNUMConfigure);

+ (void)initWithAppkey:(NSString *)appkey channel:(NSString *)channel
{
  SEL sel = NSSelectorFromString(@"setWraperType:wrapperVersion:");
  if ([UMConfigure respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [UMConfigure performSelector:sel withObject:@"react-native" withObject:@"3.0"];
#pragma clang diagnostic pop
  }
  [UMConfigure initWithAppkey:appkey channel:channel];
}

// ======================== 隐私合规（no-op）========================
//
// iOS UMCommon 7.6.7 未提供 preInit / submitPolicyGrantResult 原生 API，
// 此处仅作与 Android 端 RNUMConfigure 对称的空实现，保证 JS 层跨平台调用
// 不会报 method not found。方法签名与 Android 端一致（无 Context 参数）。

RCT_EXPORT_METHOD(preInit:(NSString *)appKey channel:(NSString *)channel)
{
  NSLog(@"[RNUMConfigure] preInit is a no-op on iOS: iOS SDK does not require pre-init (appKey=%@, channel=%@)", appKey, channel);
}

RCT_EXPORT_METHOD(submitPolicyGrantResult:(BOOL)granted)
{
  NSLog(@"[RNUMConfigure] submitPolicyGrantResult is a no-op on iOS: iOS SDK has no such privacy API (granted=%@)", granted ? @"YES" : @"NO");
}

@end
