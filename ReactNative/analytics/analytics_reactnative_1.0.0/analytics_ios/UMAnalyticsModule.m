//
//  analytics.m
//  analytics
//
//
//  Copyright (c) 2016年 tendcloud. All rights reserved.
//

#import <UMAnalytics/MobClick.h>
#import <UMAnalytics/MobClickGameAnalytics.h>
#import <UMAnalytics/DplusMobClick.h>
#import "UMAnalyticsModule.h"
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>

@implementation UMAnalyticsModule

RCT_EXPORT_MODULE();


RCT_EXPORT_METHOD(onEvent:(NSString *)eventId)
{
  if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClick event:eventId];
}

RCT_EXPORT_METHOD(onEventWithLabel:(NSString *)eventId eventLabel:(NSString *)eventLabel)
{
  if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
    return;
  }
  if ([eventLabel isKindOfClass:[NSNull class]]) {
    eventLabel = nil;
  }
  [MobClick event:eventId label:eventLabel];

}

RCT_EXPORT_METHOD(onEventWithMap:(NSString *)eventId parameters:(NSDictionary *)parameters)
{
  if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
    return;
  }
  if (parameters == nil && [parameters isKindOfClass:[NSNull class]]) {
    parameters = nil;
  }
  [MobClick event:eventId attributes:parameters];
}

RCT_EXPORT_METHOD(onEventWithMapAndCount:(NSString *)eventId parameters:(NSDictionary *)parameters eventNum:(int)eventNum)
{
  if (eventId == nil || [eventId isKindOfClass:[NSNull class]]) {
    return;
  }
  if (parameters == nil && [parameters isKindOfClass:[NSNull class]]) {
    parameters = nil;
  }
  
  [MobClick event:eventId attributes:parameters counter:eventNum];
}

RCT_EXPORT_METHOD(onPageBegin:(NSString *)pageName)
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

RCT_EXPORT_METHOD(profileSignInWithPUID:(NSString *)puid)
{
  if (puid == nil || [puid isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClick profileSignInWithPUID:puid];
}

RCT_EXPORT_METHOD(profileSignInWithPUIDWithProvider:(NSString *)provider puid:(NSString *)puid)
{
  if (provider == nil && [provider isKindOfClass:[NSNull class]]) {
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
//游戏统计

RCT_EXPORT_METHOD(setUserLevelId:(int)level)
{
  [MobClickGameAnalytics setUserLevelId:level];
}

RCT_EXPORT_METHOD(startLevel:(NSString *)level)
{
  if (level == nil || [level isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClickGameAnalytics startLevel:level];
}

RCT_EXPORT_METHOD(finishLevel:(NSString *)level)
{
  if (level == nil || [level isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClickGameAnalytics finishLevel:level];
}

RCT_EXPORT_METHOD(failLevel:(NSString *)level)
{
  if (level == nil || [level isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClickGameAnalytics failLevel:level];
}

RCT_EXPORT_METHOD(exchange:(double)currencyAmount currencyType:(NSString *)currencyType virtualAmount:(double)virtualAmount channel:(int)channel orderId:(NSString *)orderId)
{
  if (currencyType == nil && [currencyType isKindOfClass:[NSNull class]]) {
    currencyType = nil;
  }
  if (orderId == nil || [orderId isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClickGameAnalytics exchange:orderId currencyAmount:currencyAmount currencyType:currencyType virtualCurrencyAmount:virtualAmount paychannel:channel];
}

RCT_EXPORT_METHOD(pay:(double)cash coin:(int)coin source:(double)source)
{
  [MobClickGameAnalytics pay:cash source:source coin:coin];
}

RCT_EXPORT_METHOD(payWithItem:(double)cash item:(NSString *)item amount:(int)amount price:(double)price source:(int)source)
{
  if (item == nil && [item isKindOfClass:[NSNull class]]) {
    item = nil;
  }
  [MobClickGameAnalytics pay:cash source:source item:item amount:amount price:price];
}

RCT_EXPORT_METHOD(buy:(NSString *)item amount:(int)amount price:(double)price)
{
  if (item == nil || [item isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClickGameAnalytics buy:item amount:amount price:price];
}

RCT_EXPORT_METHOD(use:(NSString *)item amount:(int)amount price:(double)price)
{
  if (item == nil || [item isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClickGameAnalytics use:item amount:amount price:price];
}

RCT_EXPORT_METHOD(bonus:(double)coin source:(int)source)
{
  [MobClickGameAnalytics bonus:coin source:source];
}

RCT_EXPORT_METHOD(bonusWithItem:(NSString *)item amount:(int)amount price:(double)price source:(int)source)
{
  if (item == nil || [item isKindOfClass:[NSNull class]]) {
    return;
  }
  [MobClickGameAnalytics bonus:item amount:amount price:price source:source];
}

//Dplus

RCT_EXPORT_METHOD(track:(NSString *)eventName)
{
  
  if (eventName == nil && [eventName isKindOfClass:[NSNull class]]) {
    eventName = nil;
  }
  [DplusMobClick track:eventName];
}

RCT_EXPORT_METHOD(trackWithMap:(NSString *)eventName property:(NSDictionary *) property)
{
  
  if (eventName == nil && [eventName isKindOfClass:[NSNull class]]) {
    eventName = nil;
  }
  
  if (property == nil && [property isKindOfClass:[NSNull class]]) {
    property = nil;
  }
  [DplusMobClick track:eventName property:property];
}

RCT_EXPORT_METHOD(registerSuperProperty:(NSDictionary *)property)
{
  
  if (property == nil && [property isKindOfClass:[NSNull class]]) {
    property = nil;
  }
  [DplusMobClick registerSuperProperty:property];
}

RCT_EXPORT_METHOD(unregisterSuperProperty:(NSString *)propertyName)
{
  
  if (propertyName == nil && [propertyName isKindOfClass:[NSNull class]]) {
    propertyName = nil;
  }
  [DplusMobClick unregisterSuperProperty:propertyName];
  
}



RCT_EXPORT_METHOD(getSuperProperty:(NSString *)propertyName  callback:(RCTResponseSenderBlock)callback)
{
  
  if (propertyName == nil && [propertyName isKindOfClass:[NSNull class]]) {
    propertyName = nil;
  }
  callback(@[[DplusMobClick getSuperProperty:propertyName]]);
  
}

RCT_EXPORT_METHOD(getSuperProperties:(RCTResponseSenderBlock)callback)
{
  NSString *jsonString = nil;
  NSError *error = nil;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[DplusMobClick getSuperProperties]
                                                     options:kNilOptions //TODO: NSJSONWritingPrettyPrinted  // kNilOptions
                                                       error:&error];
  if ([jsonData length] && (error == nil))
  {
    jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] ;
  }else{
    jsonString=@"";
  }
  
  callback(@[jsonString]);
  
}

RCT_EXPORT_METHOD(clearSuperProperties)
{
  [DplusMobClick clearSuperProperties];
  
}

RCT_EXPORT_METHOD(setFirstLaunchEvent:(NSArray *)eventList)
{
  if (eventList == nil && [eventList isKindOfClass:[NSNull class]]) {
    eventList = nil;
  }
  [DplusMobClick setFirstLaunchEvent:eventList];
}

@end
