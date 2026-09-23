//
//  UMAnalyticsModule.m
//  umeng-react-native
//
//  友盟统计 React Native 桥接模块
//
//  从旧版 UMAnalyticsModule.m 迁移，关键变更：
//  - 修正 nil 检查 bug：`&&` 改为 `||`
//  - getPreProperties 改用 Promise 替代 Callback
//  - onPageBegin 统一为 onPageStart
//  - 使用 Legacy Module 方式保证编译兼容
//

#import "UMAnalyticsModule.h"
#import <UMCommon/MobClick.h>
#import <React/RCTConvert.h>

@implementation UMAnalyticsModule

RCT_EXPORT_MODULE(UMAnalyticsModule);

// ======================== 自定义事件 ========================

RCT_EXPORT_METHOD(onEvent:(NSString *)eventId)
{
  if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClick event:eventId];
}

RCT_EXPORT_METHOD(onEventWithLabel:(NSString *)eventId label:(NSString *)eventLabel)
{
  if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
    return;
  }
  if ([eventLabel isKindOfClass:[NSNull class]]) {
    eventLabel = nil;
  }
  [MobClick event:eventId label:eventLabel];
}

RCT_EXPORT_METHOD(onEventWithMap:(NSString *)eventId map:(NSDictionary *)parameters)
{
  if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
    return;
  }
  // 修正旧版 bug：`&&` → `||`
  if (parameters == nil || [parameters isKindOfClass:[NSNull class]]) {
    parameters = nil;
  }
  [MobClick event:eventId attributes:parameters];
}

RCT_EXPORT_METHOD(onEventWithMapAndCount:(NSString *)eventId map:(NSDictionary *)parameters count:(int)eventNum)
{
  if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
    return;
  }
  // 修正旧版 bug：`&&` → `||`
  if (parameters == nil || [parameters isKindOfClass:[NSNull class]]) {
    parameters = nil;
  }
  [MobClick event:eventId attributes:parameters counter:eventNum];
}

RCT_EXPORT_METHOD(onEventObject:(NSString *)eventId map:(NSDictionary *)parameters)
{
  if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
    return;
  }
  // 修正旧版 bug：`&&` → `||`
  if (parameters == nil || [parameters isKindOfClass:[NSNull class]]) {
    parameters = nil;
  }
  [MobClick event:eventId attributes:parameters];
}

// ======================== 页面统计 ========================
// 统一为 onPageStart / onPageEnd（旧 iOS 版使用 onPageBegin）

RCT_EXPORT_METHOD(onPageStart:(NSString *)pageName)
{
  if (pageName == nil || [pageName isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClick beginLogPageView:pageName];
}

RCT_EXPORT_METHOD(onPageEnd:(NSString *)pageName)
{
  if (pageName == nil || [pageName isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClick endLogPageView:pageName];
}

/**
 * 设置页面采集模式为自动
 */
RCT_EXPORT_METHOD(setPageCollectionModeAuto)
{
  [MobClick setAutoPageEnabled:YES];
}

/**
 * 设置页面采集模式为手动
 */
RCT_EXPORT_METHOD(setPageCollectionModeManual)
{
  [MobClick setAutoPageEnabled:NO];
}

// ======================== 错误上报 ========================

/**
 * 上报错误信息
 *
 * iOS 原生 SDK 不支持此 API，为空实现。
 */
RCT_EXPORT_METHOD(reportError:(NSString *)error)
{
  NSLog(@"[UMAnalyticsModule] reportError is not supported on iOS, error: %@", error);
}

// ======================== 账号统计 ========================

RCT_EXPORT_METHOD(profileSignInWithPUID:(NSString *)puid)
{
  if (puid == nil || [puid isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClick profileSignInWithPUID:puid];
}

RCT_EXPORT_METHOD(profileSignInWithPUIDWithProvider:(NSString *)provider puid:(NSString *)puid)
{
  // 修正旧版 bug：provider 的 nil 检查 `&&` → `||`
  if (provider == nil || [provider isKindOfClass:[NSNull class]]) {
    provider = nil;
  }
  if (puid == nil || [puid isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClick profileSignInWithPUID:puid provider:provider];
}

RCT_EXPORT_METHOD(profileSignOff)
{
  [MobClick profileSignOff];
}

// ======================== 超级属性 ========================

RCT_EXPORT_METHOD(registerPreProperties:(NSDictionary *)property)
{
  // 修正旧版 bug：`&&` → `||`
  if (property == nil || [property isKindOfClass:[NSNull class]]) {
    property = nil;
  }
  [MobClick registerPreProperties:property];
}

RCT_EXPORT_METHOD(unregisterPreProperty:(NSString *)propertyName)
{
  // 修正旧版 bug：`&&` → `||`
  if (propertyName == nil || [propertyName isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClick unregisterPreProperty:propertyName];
}

/**
 * Breaking change: 旧版使用 RCTResponseSenderBlock，新版使用 Promise。
 */
RCT_EXPORT_METHOD(getPreProperties:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  @try {
    NSDictionary *props = [MobClick getPreProperties];
    if (props == nil) {
      resolve(@"{}");
      return;
    }
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:props
                                                       options:kNilOptions
                                                         error:&error];
    if (jsonData && error == nil) {
      NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
      resolve(jsonString ?: @"{}");
    } else {
      resolve(@"{}");
    }
  } @catch (NSException *exception) {
    reject(@"E_GET_PRE_PROPERTIES", exception.reason, nil);
  }
}

RCT_EXPORT_METHOD(clearPreProperties)
{
  [MobClick clearPreProperties];
}

// ======================== 首次启动事件 ========================

RCT_EXPORT_METHOD(setFirstLaunchEvent:(NSArray *)eventList)
{
  // 修正旧版 bug：`&&` → `||`
  if (eventList == nil || [eventList isKindOfClass:[NSNull class]]) {
    eventList = nil;
  }
  [MobClick setFirstLaunchEvent:eventList];
}

@end
