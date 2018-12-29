//
//  analytics.m
//  analytics
//
//
//  Copyright (c) 2016年 tendcloud. All rights reserved.
//

#import <UMAnalytics/MobClick.h>

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

RCT_EXPORT_METHOD(onEventObject:(NSString *)eventId parameters:(NSDictionary *)parameters)
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


RCT_EXPORT_METHOD(registerPreProperties:(NSDictionary *)property)
{
  
  if (property == nil && [property isKindOfClass:[NSNull class]]) {
    property = nil;
  }

  [MobClick registerPreProperties:property];
}

RCT_EXPORT_METHOD(unregisterPreProperty:(NSString *)propertyName)
{
  
  if (propertyName == nil && [propertyName isKindOfClass:[NSNull class]]) {
    propertyName = nil;
  }
  [MobClick unregisterPreProperty:propertyName];
  
}


RCT_EXPORT_METHOD(getPreProperties:(RCTResponseSenderBlock)callback)
{
  NSString *jsonString = nil;
  NSError *error = nil;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[MobClick getPreProperties]
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

RCT_EXPORT_METHOD(clearPreProperties)
{
  [MobClick clearPreProperties];
  
}

RCT_EXPORT_METHOD(setFirstLaunchEvent:(NSArray *)eventList)
{
  if (eventList == nil && [eventList isKindOfClass:[NSNull class]]) {
    eventList = nil;
  }
  [MobClick setFirstLaunchEvent:eventList];
}

@end
