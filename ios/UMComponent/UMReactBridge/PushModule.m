//
//  PushModule.m
//  UMComponent
//
//  Created by wyq.Cloudayc on 11/09/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "PushModule.h"
#import <UMPush/UMessage.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>

@implementation PushModule

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(sendClickReportForRemoteNotification:(NSDictionary *)userInfo)
{
  [UMessage sendClickReportForRemoteNotification:userInfo];
}

/** 获取当前绑定设备上的所有tag(每台设备最多绑定64个tag)
 @warning 获取列表的先决条件是已经成功获取到device_token，否则失败(kUMessageErrorDependsErr)
 @param handle responseTags为绑定的tag
 集合,remain剩余可用的tag数,为-1时表示异常,error为获取失败时的信息(ErrCode:kUMessageError)
 */
//+ (void)getTags:(nullable void (^)(NSSet *__nonnull responseTags,NSInteger remain,NSError *__nonnull error))handle;
RCT_EXPORT_METHOD(getTags:(RCTResponseSenderBlock)completion)
{
  [UMessage getTags:^(NSSet * _Nonnull responseTags, NSInteger remain, NSError * _Nonnull error) {
    
  }];
}


/** 绑定一个或多个tag至设备，每台设备最多绑定64个tag，超过64个，绑定tag不再成功，可`removeTag`或者`removeAllTags`来精简空间
 @warning 添加tag的先决条件是已经成功获取到device_token，否则直接添加失败(kUMessageErrorDependsErr)
 @param tag tag标记,可以为单个tag（NSString）也可以为tag集合（NSArray、NSSet），单个tag最大允许长度50字节，编码UTF-8，超过长度自动截取
 @param handle responseTags为绑定的tag集合,remain剩余可用的tag数,为-1时表示异常,error为获取失败时的信息(ErrCode:kUMessageError)
 */
//+ (void)addTags:(nullable id)tag response:(nullable void (^)(id __nonnull responseObject ,NSInteger remain,NSError *__nonnull error))handle;
RCT_EXPORT_METHOD(addTags:(NSString *)tag response:(RCTResponseSenderBlock)completion)
{
  [UMessage addTags:tag response:^(id  _Nonnull responseObject, NSInteger remain, NSError * _Nonnull error) {
    
  }];
}

/** 删除设备中绑定的一个或多个tag
 @warning 添加tag的先决条件是已经成功获取到device_token，否则失败(kUMessageErrorDependsErr)
 @param tag tag标记,可以为单个tag（NSString）也可以为tag集合（NSArray、NSSet），单个tag最大允许长度50字节，编码UTF-8，超过长度自动截取
 @param handle responseTags为绑定的tag集合,remain剩余可用的tag数,为-1时表示异常,error为获取失败时的信息(ErrCode:kUMessageError)
 */
//+ (void)deleteTags:(id __nonnull)tag response:(nullable void (^)(id __nonnull responseObject,NSInteger remain,NSError *__nonnull error))handle;
RCT_EXPORT_METHOD(deleteTags:(NSString *)tag response:(RCTResponseSenderBlock)completion)
{
  [UMessage deleteTags:tag response:^(id  _Nonnull responseObject, NSInteger remain, NSError * _Nonnull error) {
    
  }];
}

/** 绑定一个别名至设备（含账户，和平台类型）
 @warning 添加Alias的先决条件是已经成功获取到device_token，否则失败(kUMessageErrorDependsErr)
 @param name 账户，例如email
 @param type 平台类型，参见本文件头部的`kUMessageAliasType...`，例如：kUMessageAliasTypeSina
 @param handle block返回数据，error为获取失败时的信息，responseObject为成功返回的数据
 */
//+ (void)addAlias:(NSString * __nonnull)name type:(NSString * __nonnull)type response:(nullable void (^)(id __nonnull responseObject,NSError *__nonnull error))handle;
RCT_EXPORT_METHOD(addAlias:(NSString *)name type:(NSString *)type response:(RCTResponseSenderBlock)completion)
{
  [UMessage addAlias:name type:type response:^(id  _Nonnull responseObject, NSError * _Nonnull error) {
    
  }];
}

/** 绑定一个别名至设备（含账户，和平台类型）,并解绑这个别名曾今绑定过的设备。
 @warning 添加Alias的先决条件是已经成功获取到device_token，否则失败(kUMessageErrorDependsErr)
 @param name 账户，例如email
 @param type 平台类型，参见本文件头部的`kUMessageAliasType...`，例如：kUMessageAliasTypeSina
 @param handle block返回数据，error为获取失败时的信息，responseObject为成功返回的数据
 */
//+ (void)setAlias:(NSString *__nonnull )name type:(NSString * __nonnull)type response:(nullable void (^)(id __nonnull responseObject,NSError *__nonnull error))handle;
RCT_EXPORT_METHOD(setAlias:(NSString *)name type:(NSString *)type response:(RCTResponseSenderBlock)completion)
{
  [UMessage setAlias:name type:type response:^(id  _Nonnull responseObject, NSError * _Nonnull error) {
    
  }];
}

/** 删除一个设备的别名绑定
 @warning 删除Alias的先决条件是已经成功获取到device_token，否则失败(kUMessageErrorDependsErr)
 @param name 账户，例如email
 @param type 平台类型，参见本文件头部的`kUMessageAliasType...`，例如：kUMessageAliasTypeSina
 @param handle block返回数据，error为获取失败时的信息，responseObject为成功返回的数据
 */
//+ (void)removeAlias:(NSString * __nonnull)name type:(NSString * __nonnull)type response:(nullable void (^)(id __nonnull responseObject, NSError *__nonnull error))handle;
RCT_EXPORT_METHOD(removeAlias:(NSString *)name type:(NSString *)type response:(RCTResponseSenderBlock)completion)
{
  [UMessage removeAlias:name type:type response:^(id  _Nonnull responseObject, NSError * _Nonnull error) {
    
  }];
}



@end
