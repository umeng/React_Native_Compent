//
//  RNUMConfigure.m
//  umeng-react-native
//
//  友盟 SDK 初始化配置
//
//  从旧版 RNUMConfigure 迁移，关键变更：
//  - wrapper 版本标识更新为 "3.0"
//

#import "RNUMConfigure.h"

@implementation RNUMConfigure

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

@end
