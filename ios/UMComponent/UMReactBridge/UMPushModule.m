//
//  PushModule.m
//  UMComponent
//
//  Created by wyq.Cloudayc on 11/09/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "UMPushModule.h"
#import <UMPush/UMessage.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>

@implementation UMPushModule

RCT_EXPORT_MODULE();

//  /**未知错误*/
//  kUMessageErrorUnknown = 0,
//  /**响应出错*/
//  kUMessageErrorResponseErr = 1,
//  /**操作失败*/
//  kUMessageErrorOperateErr = 2,
//  /**参数非法*/
//  kUMessageErrorParamErr = 3,
//  /**条件不足(如:还未获取device_token，添加tag是不成功的)*/
//  kUMessageErrorDependsErr = 4,
//  /**服务器限定操作*/
//  kUMessageErrorServerSetErr = 5,
- (NSString *)checkErrorMessage:(NSInteger)code
{
  switch (code) {
    case 1:
      return @"响应出错";
      break;
    case 2:
      return @"操作失败";
      break;
    case 3:
      return @"参数非法";
      break;
    case 4:
      return @"条件不足(如:还未获取device_token，添加tag是不成功的)";
      break;
    case 5:
      return @"服务器限定操作";
      break;
    default:
      break;
  }
  return nil;
}

- (void)handleResponse:(id  _Nonnull)responseObject remain:(NSInteger)remain error:(NSError * _Nonnull)error completion:(RCTResponseSenderBlock)completion
{
  if (completion) {
    if (error) {
      NSString *msg = [self checkErrorMessage:error.code];
      if (msg.length == 0) {
        msg = error.localizedDescription;
      }
      completion(@[@(error.code), @(remain)]);
    } else {
      if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *retDict = responseObject;
        if ([retDict[@"success"] isEqualToString:@"ok"]) {
          completion(@[@200, @(remain)]);
        } else {
          completion(@[@(-1), @(remain)]);
        }
      } else {
        completion(@[@(-1), @(remain)]);
      }
      
    }
  }
}

- (void)handleGetTagResponse:(NSSet * _Nonnull)responseTags remain:(NSInteger)remain error:(NSError * _Nonnull)error completion:(RCTResponseSenderBlock)completion
{
  if (completion) {
    if (error) {
      NSString *msg = [self checkErrorMessage:error.code];
      if (msg.length == 0) {
        msg = error.localizedDescription;
      }
      completion(@[@(error.code), @(remain), @[]]);
    } else {
      if ([responseTags isKindOfClass:[NSSet class]]) {
        NSArray *retList = responseTags.allObjects;
        completion(@[@200, @(remain), retList]);
      } else {
        completion(@[@(-1), @(remain), @[]]);
      }
    }
  }
}
- (void)handleAliasResponse:(id  _Nonnull)responseObject error:(NSError * _Nonnull)error completion:(RCTResponseSenderBlock)completion
{
  if (completion) {
    if (error) {
      NSString *msg = [self checkErrorMessage:error.code];
      if (msg.length == 0) {
        msg = error.localizedDescription;
      }
      completion(@[@(error.code)]);
    } else {
      if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *retDict = responseObject;
        if ([retDict[@"success"] isEqualToString:@"ok"]) {
          completion(@[@200]);
        } else {
          completion(@[@(-1)]);
        }
      } else {
        completion(@[@(-1)]);
      }
      
    }
  }
}

RCT_EXPORT_METHOD(addTag:(NSString *)tag response:(RCTResponseSenderBlock)completion)
{
  [UMessage addTags:tag response:^(id  _Nonnull responseObject, NSInteger remain, NSError * _Nonnull error) {
    [self handleResponse:responseObject remain:remain error:error completion:completion];
  }];
}

RCT_EXPORT_METHOD(deleteTag:(NSString *)tag response:(RCTResponseSenderBlock)completion)
{
  [UMessage deleteTags:tag response:^(id  _Nonnull responseObject, NSInteger remain, NSError * _Nonnull error) {
    [self handleResponse:responseObject remain:remain error:error completion:completion];
  }];
}

RCT_EXPORT_METHOD(listTag:(RCTResponseSenderBlock)completion)
{
  [UMessage getTags:^(NSSet * _Nonnull responseTags, NSInteger remain, NSError * _Nonnull error) {
    [self handleGetTagResponse:responseTags remain:remain error:error completion:completion];
  }];
}

RCT_EXPORT_METHOD(addAlias:(NSString *)name type:(NSString *)type response:(RCTResponseSenderBlock)completion)
{
  [UMessage addAlias:name type:type response:^(id  _Nonnull responseObject, NSError * _Nonnull error) {
    [self handleAliasResponse:responseObject error:error completion:completion];
  }];
}

RCT_EXPORT_METHOD(addExclusiveAlias:(NSString *)name type:(NSString *)type response:(RCTResponseSenderBlock)completion)
{
  [UMessage setAlias:name type:type response:^(id  _Nonnull responseObject, NSError * _Nonnull error) {
    [self handleAliasResponse:responseObject error:error completion:completion];
  }];
}

RCT_EXPORT_METHOD(deleteAlias:(NSString *)name type:(NSString *)type response:(RCTResponseSenderBlock)completion)
{
  [UMessage removeAlias:name type:type response:^(id  _Nonnull responseObject, NSError * _Nonnull error) {
    [self handleAliasResponse:responseObject error:error completion:completion];
  }];
}



@end
