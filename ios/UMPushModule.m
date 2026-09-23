//
//  UMPushModule.m
//  umeng-react-native
//
//  友盟推送 React Native 桥接模块
//
//  关键能力：
//  - 基于 RCTEventEmitter 支持事件系统
//  - 新增批量 Tag、setBadge、setPushEnable
//  - getDeviceToken 从 NSUserDefaults 读取 hex token
//  - 静态入口供 AppDelegate 回调
//
//  注意：不在 register() 中调用 UMConfigure.init，由 RNUMConfigure 统一初始化
//

#import "UMPushModule.h"
#import <UMPush/UMessage.h>
#import <React/RCTConvert.h>
#import <UIKit/UIKit.h>

// 缓存模块实例，供静态方法使用
static UMPushModule *sharedInstance = nil;
// 模块初始化前缓存的通知（register 后回放）
static NSDictionary *userInfoTemp = nil;
// 模块初始化前缓存的 deviceToken（register 后回放）
static NSString *deviceTokenTemp = nil;

/**
 * NSData deviceToken → hex 字符串（与 getDeviceToken 读取 NSUserDefaults 的编码保持一致）
 */
static NSString *UMPushHexFromTokenData(NSData *tokenData)
{
  if (tokenData == nil || ![tokenData isKindOfClass:[NSData class]] || tokenData.length == 0) {
    return @"";
  }
  const unsigned char *bytes = (const unsigned char *)[tokenData bytes];
  NSMutableString *hex = [NSMutableString stringWithCapacity:tokenData.length * 2];
  for (NSUInteger i = 0; i < tokenData.length; i++) {
    [hex appendFormat:@"%02x", bytes[i]];
  }
  return [hex copy];
}

/**
 * APNs userInfo 可能含非 plist 值，直接作为 event body 会在 JSON 序列化时抛异常，
 * 故 emit 前做一次降级拷贝：不可序列化的 value 退化为 description 字符串。
 */
static NSDictionary *UMPushSanitizeUserInfo(NSDictionary *userInfo)
{
  if (userInfo == nil || ![userInfo isKindOfClass:[NSDictionary class]]) {
    return @{};
  }
  if ([NSJSONSerialization isValidJSONObject:userInfo]) {
    return userInfo;
  }
  NSMutableDictionary *safe = [NSMutableDictionary dictionaryWithCapacity:userInfo.count];
  [userInfo enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
    NSString *k = [key isKindOfClass:[NSString class]] ? key : [key description];
    if ([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNumber class]] ||
        [value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]] ||
        [value isKindOfClass:[NSNull class]]) {
      safe[k] = value;
    } else {
      safe[k] = [value description];
    }
  }];
  return [safe copy];
}

@implementation UMPushModule

RCT_EXPORT_MODULE(UMPushModule);

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    sharedInstance = self;
  }
  return self;
}

- (void)dealloc
{
  if (sharedInstance == self) {
    sharedInstance = nil;
  }
}

// ======================== 事件系统 ========================

- (NSArray<NSString *> *)supportedEvents
{
  return @[
    @"UMPushOnToken",
    @"UMPushOnMessage",
    @"UMPushOnNotificationReceive",
    @"UMPushOnNotificationOpen"
  ];
}

// ======================== 静态入口 ========================
//
// 宿主 AppDelegate 只需将系统回调转发到下面四个静态方法：
// 桥接层统一负责「向友盟 SDK 回传数据」+「emit 事件到 JS」，
// 避免集成方漏调 UMessage 导致后台送达/点击统计为 0。

+ (void)didReceiveUMessage:(NSDictionary *)userInfo
{
  if (!userInfo || userInfo.count == 0) return;
  // 前台/后台运行时收到消息：回传送达与点击数据
  [UMessage didReceiveRemoteNotification:userInfo];
  NSDictionary *body = UMPushSanitizeUserInfo(userInfo);
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"UMPushOnNotificationReceive" body:body];
  } else {
    userInfoTemp = body;
  }
}

+ (void)didOpenUMessage:(NSDictionary *)userInfo
{
  if (!userInfo || userInfo.count == 0) return;
  // 用户点击通知：回传点击数据（否则友盟后台点击量为 0）
  [UMessage didReceiveRemoteNotification:userInfo];
  NSDictionary *body = UMPushSanitizeUserInfo(userInfo);
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"UMPushOnNotificationOpen" body:body];
  } else {
    // RN 模块尚未实例化（典型：冷启动点通知拉起），缓存等 register 后回放
    userInfoTemp = body;
  }
}

+ (void)didRegisterDeviceToken:(NSData *)deviceToken
{
  NSString *hex = UMPushHexFromTokenData(deviceToken);
  if (hex.length == 0) {
    NSLog(@"[UMPushModule] didRegisterDeviceToken 收到空 token，已忽略");
    return;
  }
  // 向友盟上报 deviceToken（宿主也可自行调用，重复调用无副作用）
  [UMessage registerDeviceToken:deviceToken];
  NSLog(@"[UMPushModule] APNs deviceToken=%@", hex);
  if (sharedInstance) {
    [sharedInstance sendEventWithName:@"UMPushOnToken" body:hex];
  } else {
    deviceTokenTemp = hex;
  }
}

+ (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  NSLog(@"[UMPushModule] APNs 注册失败: %@", error.localizedDescription);
}

+ (void)registerFromNative
{
  NSLog(@"[UMPushModule] registerFromNative: 隐私同意后自动注册推送");
  [UMessage setAutoAlert:NO];

  UMessageRegisterEntity *entity = [[UMessageRegisterEntity alloc] init];
  entity.types = UMessageAuthorizationOptionBadge | UMessageAuthorizationOptionAlert | UMessageAuthorizationOptionSound;

  [UMessage registerForRemoteNotificationsWithLaunchOptions:nil
                                                     Entity:entity
                                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
    if (error) {
      NSLog(@"[UMPushModule] registerFromNative 失败: %@", error.localizedDescription);
    } else {
      NSLog(@"[UMPushModule] registerFromNative 成功, granted=%d", granted);

      // 回放冷启动缓存的 deviceToken
      if (sharedInstance && deviceTokenTemp.length > 0) {
        NSString *cachedToken = deviceTokenTemp;
        deviceTokenTemp = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
          [sharedInstance sendEventWithName:@"UMPushOnToken" body:cachedToken];
        });
      }

      // 回放冷启动缓存的通知点击（典型：点通知拉起 App，事件早于 RN 模块创建）
      if (sharedInstance && userInfoTemp) {
        NSDictionary *cached = userInfoTemp;
        userInfoTemp = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
          [sharedInstance sendEventWithName:@"UMPushOnNotificationOpen" body:cached];
        });
      }
    }
  }];
}

// ======================== 内部辅助 ========================

- (NSString *)checkErrorMessage:(NSInteger)code
{
  switch (code) {
    case 1:
      return @"响应出错";
    case 2:
      return @"操作失败";
    case 3:
      return @"参数非法";
    case 4:
      return @"条件不足(如:还未获取device_token，添加tag是不成功的)";
    case 5:
      return @"服务器限定操作";
    default:
      return nil;
  }
}

// ======================== Tag 管理 ========================

RCT_EXPORT_METHOD(addTag:(NSString *)tag
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (tag == nil || [tag isKindOfClass:[NSNull class]]) {
    reject(@"E_ADD_TAG", @"tag is required", nil);
    return;
  }
  [UMessage addTags:tag response:^(id  _Nonnull responseObject, NSInteger remain, NSError * _Nonnull error) {
    if (error) {
      NSString *msg = [self checkErrorMessage:error.code];
      if (msg.length == 0) {
        msg = error.localizedDescription;
      }
      reject(@"E_ADD_TAG", msg, error);
    } else {
      if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *retDict = responseObject;
        if ([retDict[@"success"] isEqualToString:@"ok"]) {
          resolve(@{@"code": @200, @"remain": @(remain)});
        } else {
          reject(@"E_ADD_TAG", @"addTag failed", nil);
        }
      } else {
        reject(@"E_ADD_TAG", @"addTag failed: unexpected response", nil);
      }
    }
  }];
}

RCT_EXPORT_METHOD(deleteTag:(NSString *)tag
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (tag == nil || [tag isKindOfClass:[NSNull class]]) {
    reject(@"E_DELETE_TAG", @"tag is required", nil);
    return;
  }
  [UMessage deleteTags:tag response:^(id  _Nonnull responseObject, NSInteger remain, NSError * _Nonnull error) {
    if (error) {
      NSString *msg = [self checkErrorMessage:error.code];
      if (msg.length == 0) {
        msg = error.localizedDescription;
      }
      reject(@"E_DELETE_TAG", msg, error);
    } else {
      if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *retDict = responseObject;
        if ([retDict[@"success"] isEqualToString:@"ok"]) {
          resolve(@{@"code": @200, @"remain": @(remain)});
        } else {
          reject(@"E_DELETE_TAG", @"deleteTag failed", nil);
        }
      } else {
        reject(@"E_DELETE_TAG", @"deleteTag failed: unexpected response", nil);
      }
    }
  }];
}

RCT_EXPORT_METHOD(listTag:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [UMessage getTags:^(NSSet * _Nonnull responseTags, NSInteger remain, NSError * _Nonnull error) {
    if (error) {
      NSString *msg = [self checkErrorMessage:error.code];
      if (msg.length == 0) {
        msg = error.localizedDescription;
      }
      reject(@"E_LIST_TAG", msg, error);
    } else {
      NSArray *tagList = @[];
      if ([responseTags isKindOfClass:[NSSet class]]) {
        tagList = responseTags.allObjects;
      }
      resolve(@{@"code": @200, @"remain": @(remain), @"tags": tagList});
    }
  }];
}

RCT_EXPORT_METHOD(addTags:(NSArray *)tags
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (tags == nil || ![tags isKindOfClass:[NSArray class]] || tags.count == 0) {
    reject(@"E_ADD_TAGS", @"tags is required and cannot be empty", nil);
    return;
  }
  [UMessage addTags:tags response:^(id  _Nonnull responseObject, NSInteger remain, NSError * _Nonnull error) {
    if (error) {
      NSString *msg = [self checkErrorMessage:error.code];
      if (msg.length == 0) {
        msg = error.localizedDescription;
      }
      reject(@"E_ADD_TAGS", msg, error);
    } else {
      resolve(@{@"code": @200, @"remain": @(remain)});
    }
  }];
}

RCT_EXPORT_METHOD(removeTags:(NSArray *)tags
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (tags == nil || ![tags isKindOfClass:[NSArray class]] || tags.count == 0) {
    reject(@"E_REMOVE_TAGS", @"tags is required and cannot be empty", nil);
    return;
  }
  [UMessage deleteTags:tags response:^(id  _Nonnull responseObject, NSInteger remain, NSError * _Nonnull error) {
    if (error) {
      NSString *msg = [self checkErrorMessage:error.code];
      if (msg.length == 0) {
        msg = error.localizedDescription;
      }
      reject(@"E_REMOVE_TAGS", msg, error);
    } else {
      resolve(@{@"code": @200, @"remain": @(remain)});
    }
  }];
}

// ======================== Alias 管理 ========================

RCT_EXPORT_METHOD(addAlias:(NSString *)alias
                  aliasType:(NSString *)aliasType
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (alias == nil || [alias isKindOfClass:[NSNull class]]) {
    reject(@"E_ADD_ALIAS", @"alias is required", nil);
    return;
  }
  if (aliasType == nil || [aliasType isKindOfClass:[NSNull class]]) {
    reject(@"E_ADD_ALIAS", @"aliasType is required", nil);
    return;
  }
  [UMessage addAlias:alias type:aliasType response:^(id  _Nonnull responseObject, NSError * _Nonnull error) {
    if (error) {
      NSString *msg = [self checkErrorMessage:error.code];
      if (msg.length == 0) {
        msg = error.localizedDescription;
      }
      reject(@"E_ADD_ALIAS", msg, error);
    } else {
      if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *retDict = responseObject;
        if ([retDict[@"success"] isEqualToString:@"ok"]) {
          resolve(@{@"code": @200});
        } else {
          reject(@"E_ADD_ALIAS", @"addAlias failed", nil);
        }
      } else {
        reject(@"E_ADD_ALIAS", @"addAlias failed: unexpected response", nil);
      }
    }
  }];
}

RCT_EXPORT_METHOD(addExclusiveAlias:(NSString *)alias
                  aliasType:(NSString *)aliasType
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (alias == nil || [alias isKindOfClass:[NSNull class]]) {
    reject(@"E_ADD_EXCLUSIVE_ALIAS", @"alias is required", nil);
    return;
  }
  if (aliasType == nil || [aliasType isKindOfClass:[NSNull class]]) {
    reject(@"E_ADD_EXCLUSIVE_ALIAS", @"aliasType is required", nil);
    return;
  }
  [UMessage setAlias:alias type:aliasType response:^(id  _Nonnull responseObject, NSError * _Nonnull error) {
    if (error) {
      NSString *msg = [self checkErrorMessage:error.code];
      if (msg.length == 0) {
        msg = error.localizedDescription;
      }
      reject(@"E_ADD_EXCLUSIVE_ALIAS", msg, error);
    } else {
      if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *retDict = responseObject;
        if ([retDict[@"success"] isEqualToString:@"ok"]) {
          resolve(@{@"code": @200});
        } else {
          reject(@"E_ADD_EXCLUSIVE_ALIAS", @"addExclusiveAlias failed", nil);
        }
      } else {
        reject(@"E_ADD_EXCLUSIVE_ALIAS", @"addExclusiveAlias failed: unexpected response", nil);
      }
    }
  }];
}

RCT_EXPORT_METHOD(deleteAlias:(NSString *)alias
                  aliasType:(NSString *)aliasType
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (alias == nil || [alias isKindOfClass:[NSNull class]]) {
    reject(@"E_DELETE_ALIAS", @"alias is required", nil);
    return;
  }
  if (aliasType == nil || [aliasType isKindOfClass:[NSNull class]]) {
    reject(@"E_DELETE_ALIAS", @"aliasType is required", nil);
    return;
  }
  [UMessage removeAlias:alias type:aliasType response:^(id  _Nonnull responseObject, NSError * _Nonnull error) {
    if (error) {
      NSString *msg = [self checkErrorMessage:error.code];
      if (msg.length == 0) {
        msg = error.localizedDescription;
      }
      reject(@"E_DELETE_ALIAS", msg, error);
    } else {
      if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *retDict = responseObject;
        if ([retDict[@"success"] isEqualToString:@"ok"]) {
          resolve(@{@"code": @200});
        } else {
          reject(@"E_DELETE_ALIAS", @"deleteAlias failed", nil);
        }
      } else {
        reject(@"E_DELETE_ALIAS", @"deleteAlias failed: unexpected response", nil);
      }
    }
  }];
}

// ======================== 注册与配置 ========================

RCT_EXPORT_METHOD(register:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  // 前台展示交给 UNUserNotificationCenterDelegate 的 willPresentNotification 控制，
  // 关掉 SDK 自带 alert，避免同一条通知前台弹两次
  [UMessage setAutoAlert:NO];

  // 构造注册参数实体
  UMessageRegisterEntity *entity = [[UMessageRegisterEntity alloc] init];
  entity.types = UMessageAuthorizationOptionBadge | UMessageAuthorizationOptionAlert | UMessageAuthorizationOptionSound;

  [UMessage registerForRemoteNotificationsWithLaunchOptions:nil
                                                     Entity:entity
                                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
    if (error) {
      reject(@"E_REGISTER", error.localizedDescription, error);
    } else {
      resolve(@{@"code": @200, @"granted": @(granted)});

      // 回放模块实例化前缓存的 deviceToken
      if (deviceTokenTemp.length > 0) {
        NSString *cachedToken = deviceTokenTemp;
        deviceTokenTemp = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
          [self sendEventWithName:@"UMPushOnToken" body:cachedToken];
        });
      }

      // 回放缓存的通知（典型：冷启动点通知拉起，事件早于 RN 模块创建）
      if (userInfoTemp) {
        NSDictionary *cached = userInfoTemp;
        userInfoTemp = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
          [self sendEventWithName:@"UMPushOnNotificationOpen" body:cached];
        });
      }
    }
  }];
}

RCT_EXPORT_METHOD(getDeviceToken:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  @try {
    NSData *tokenData = [[NSUserDefaults standardUserDefaults] objectForKey:@"kUMessageUserDefaultKeyForDeviceToken"];
    resolve(UMPushHexFromTokenData(tokenData));
  } @catch (NSException *exception) {
    reject(@"E_GET_DEVICE_TOKEN", exception.reason, nil);
  }
}

// ======================== 推送控制 ========================

RCT_EXPORT_METHOD(setPushEnable:(BOOL)enable)
{
  // iOS no-op，保留 Spec 一致性
  // iOS 推送权限由系统管理，不支持应用层开关
}

RCT_EXPORT_METHOD(setBadge:(NSInteger)num)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [UIApplication sharedApplication].applicationIconBadgeNumber = num;
  });
}

RCT_EXPORT_METHOD(openNotificationSettings)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
      [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
  });
}

RCT_EXPORT_METHOD(isNotificationEnabled:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
    BOOL enabled = (settings.authorizationStatus == UNAuthorizationStatusAuthorized);
    resolve(@(enabled));
  }];
}

@end
