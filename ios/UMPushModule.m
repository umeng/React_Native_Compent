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
// JS 侧是否已注册事件监听（由 startObserving / stopObserving 维护）。
// 事件能否直接发送以「是否有人在听」为准：模块已实例化但 JS 尚未 addListener 时，
// RCTEventEmitter 会静默丢弃事件且无法回放，因此该状态下必须降级到缓存队列。
static BOOL hasJSListeners = NO;
// JS 尚未监听期间缓存的事件队列，元素形如 @{@"eventName": ..., @"payload": ...}。
// 保留原始事件类型与先后顺序，避免「到达」被回放成「点击」、多条通知相互覆盖。
static NSMutableArray<NSDictionary *> *pendingEvents = nil;
// 缓存队列上限，避免长时间无监听（或桥接重载）时无限增长
static const NSUInteger kUMPushMaxPendingEvents = 20;

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

/**
 * 事件出口：JS 有监听则立即发送，否则按原始事件名入队，待 startObserving 后按序回放。
 * 静态入口（AppDelegate 回调）可能来自任意线程，且早于 JS 监听注册，故加锁保护共享状态。
 */
static void UMPushEmitEvent(NSString *eventName, id payload)
{
  if (eventName.length == 0 || payload == nil) return;
  UMPushModule *target = nil;
  @synchronized (UMPushModule.class) {
    target = sharedInstance;
    if (target == nil || !hasJSListeners) {
      if (pendingEvents == nil) {
        pendingEvents = [NSMutableArray array];
      }
      if (pendingEvents.count >= kUMPushMaxPendingEvents) {
        [pendingEvents removeObjectAtIndex:0];
      }
      [pendingEvents addObject:@{@"eventName": eventName, @"payload": payload}];
      return;
    }
  }
  [target sendEventWithName:eventName body:payload];
}

@interface UMPushModule ()

- (void)flushPendingEvents;
- (BOOL)isSuccessResponseObject:(id)responseObject;
- (NSString *)failureMessageForResponseObject:(id)responseObject action:(NSString *)action;
- (void)handleTagResponse:(id)responseObject
                   remain:(NSInteger)remain
                    error:(NSError *)error
                errorCode:(NSString *)errorCode
                   action:(NSString *)action
                  resolve:(RCTPromiseResolveBlock)resolve
                   reject:(RCTPromiseRejectBlock)reject;

@end

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
    @synchronized (UMPushModule.class) {
      sharedInstance = self;
      // 新实例尚未绑定 JS 监听（桥接重载场景）：先回到缓存模式，等 startObserving 再回放
      hasJSListeners = NO;
    }
  }
  return self;
}

- (void)dealloc
{
  @synchronized (UMPushModule.class) {
    if (sharedInstance == self) {
      sharedInstance = nil;
      hasJSListeners = NO;
    }
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

/**
 * JS 侧注册首个监听时回调（RCTEventEmitter 内部 addListener → startObserving）：
 * 冷启动点通知拉起、deviceToken 早到等缓存事件在这里按原始类型与顺序回放
 */
- (void)startObserving
{
  [super startObserving];
  [self flushPendingEvents];
}

/**
 * JS 侧移除全部监听时回调：之后的事件重新进入缓存队列
 */
- (void)stopObserving
{
  [super stopObserving];
  @synchronized (UMPushModule.class) {
    if (sharedInstance == self) {
      hasJSListeners = NO;
    }
  }
}

- (void)flushPendingEvents
{
  @synchronized (UMPushModule.class) {
    sharedInstance = self;
    hasJSListeners = YES;
    if (pendingEvents.count == 0) {
      return;
    }
    NSArray<NSDictionary *> *events = [pendingEvents copy];
    [pendingEvents removeAllObjects];
    // 在锁内完成回放，保证与随后到达的实时事件严格有序
    for (NSDictionary *event in events) {
      NSString *eventName = event[@"eventName"];
      id payload = event[@"payload"];
      if (eventName.length == 0 || payload == nil) {
        continue;
      }
      [self sendEventWithName:eventName body:payload];
    }
  }
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
  // 保留「到达」语义：JS 未监听时入队，回放时仍是 UMPushOnNotificationReceive
  UMPushEmitEvent(@"UMPushOnNotificationReceive", UMPushSanitizeUserInfo(userInfo));
}

+ (void)didOpenUMessage:(NSDictionary *)userInfo
{
  if (!userInfo || userInfo.count == 0) return;
  // 用户点击通知：回传点击数据（否则友盟后台点击量为 0）
  [UMessage didReceiveRemoteNotification:userInfo];
  UMPushEmitEvent(@"UMPushOnNotificationOpen", UMPushSanitizeUserInfo(userInfo));
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
  UMPushEmitEvent(@"UMPushOnToken", hex);
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
      // 缓存事件的回放不在注册成功时触发：以 JS 是否注册监听为准，由 startObserving 统一回放
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

/**
 * 友盟 Tag 接口的业务响应校验：
 * HTTP 成功但业务失败时 NSError 为 nil，真实状态在 responseObject 中（成功固定为 @{@"success": @"ok"}）。
 */
- (BOOL)isSuccessResponseObject:(id)responseObject
{
  if (![responseObject isKindOfClass:[NSDictionary class]]) {
    return NO;
  }
  id success = ((NSDictionary *)responseObject)[@"success"];
  return [success isKindOfClass:[NSString class]] && [(NSString *)success isEqualToString:@"ok"];
}

- (NSString *)failureMessageForResponseObject:(id)responseObject action:(NSString *)action
{
  if (![responseObject isKindOfClass:[NSDictionary class]]) {
    return [NSString stringWithFormat:@"%@ failed: unexpected response", action];
  }
  NSDictionary *retDict = (NSDictionary *)responseObject;
  for (NSString *key in @[@"msg", @"message", @"error"]) {
    id value = retDict[key];
    if ([value isKindOfClass:[NSString class]] && [(NSString *)value length] > 0) {
      return [NSString stringWithFormat:@"%@ failed: %@", action, value];
    }
  }
  return [NSString stringWithFormat:@"%@ failed", action];
}

/**
 * 单个 / 批量 Tag 操作共用的回调处理：只有明确成功才 resolve，
 * 业务失败或异常响应一律 reject，避免把服务端业务失败误报为成功
 */
- (void)handleTagResponse:(id)responseObject
                   remain:(NSInteger)remain
                    error:(NSError *)error
                errorCode:(NSString *)errorCode
                   action:(NSString *)action
                  resolve:(RCTPromiseResolveBlock)resolve
                   reject:(RCTPromiseRejectBlock)reject
{
  if (error) {
    NSString *msg = [self checkErrorMessage:error.code];
    if (msg.length == 0) {
      msg = error.localizedDescription.length > 0 ? error.localizedDescription
                                                  : [NSString stringWithFormat:@"%@ failed", action];
    }
    reject(errorCode, msg, error);
    return;
  }
  if ([self isSuccessResponseObject:responseObject]) {
    resolve(@{@"code": @200, @"remain": @(remain)});
    return;
  }
  reject(errorCode, [self failureMessageForResponseObject:responseObject action:action], nil);
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
    [self handleTagResponse:responseObject
                     remain:remain
                      error:error
                  errorCode:@"E_ADD_TAG"
                     action:@"addTag"
                    resolve:resolve
                     reject:reject];
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
    [self handleTagResponse:responseObject
                     remain:remain
                      error:error
                  errorCode:@"E_DELETE_TAG"
                     action:@"deleteTag"
                    resolve:resolve
                     reject:reject];
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
    [self handleTagResponse:responseObject
                     remain:remain
                      error:error
                  errorCode:@"E_ADD_TAGS"
                     action:@"addTags"
                    resolve:resolve
                     reject:reject];
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
    [self handleTagResponse:responseObject
                     remain:remain
                      error:error
                  errorCode:@"E_REMOVE_TAGS"
                     action:@"removeTags"
                    resolve:resolve
                     reject:reject];
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
      // 缓存事件（deviceToken / 通知到达 / 通知点击）的回放由 startObserving 统一完成：
      // 以 JS 是否注册监听为准，而非注册时机
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
    UNAuthorizationStatus status = settings.authorizationStatus;
    // Provisional（临时授权）仍可投递安静通知，不能判为未开启
    BOOL enabled = (status == UNAuthorizationStatusAuthorized ||
                    status == UNAuthorizationStatusProvisional);
    resolve(@(enabled));
  }];
}

@end
