//
//  RNUMAPMConfig.m
//  umeng-react-native
//

#import "RNUMAPMConfig.h"

@implementation RNUMAPMConfig

- (instancetype)init
{
  self = [super init];
  if (self) {
    // 默认配置
    _crashAndBlockMonitorEnable = YES;
    _launchMonitorEnable = YES;
    _pageMonitorEnable = YES;
    _logCollectEnable = YES;
    // memMonitorEnable / networkEnable / javaScriptBridgeEnable 默认 NO
  }
  return self;
}

@end
