//
//  UMAPMModule.m
//  umeng-react-native
//
//  友盟 APM 性能监控 React Native 桥接模块
//
//  全新模块，方法名直接对齐友盟官方 APM SDK 语义命名。
//  使用 Legacy Module 方式保证编译兼容。
//

#import "UMAPMModule.h"
#import <UMAPM/UMCrashConfigure.h>
#import <UMAPM/UMAPMConfig.h>
#import <UMAPM/UMAPMCustomLog.h>
#import <UMAPM/UMLaunch.h>
#import <UMAPM/UMPage.h>
#import <React/RCTConvert.h>
#import <UIKit/UIKit.h>

#pragma mark - 辅助记录类

/// 页面帧率采集记录
@interface UMAPMFpsRecord : NSObject
@property (nonatomic, assign) long long startTime;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, strong) CADisplayLink *displayLink;
- (void)tick:(CADisplayLink *)link;
@end

@implementation UMAPMFpsRecord
- (void)tick:(CADisplayLink *)link {
  self.frameCount += 1;
}
@end

/// HTTP API 请求记录
@interface UMAPMApiRecord : NSObject
@property (nonatomic, copy) NSString *uri;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, assign) long long beginTime;
@end

@implementation UMAPMApiRecord
@end

@interface UMAPMModule () {
  BOOL _trackingPagePerf;
  BOOL _trackingPageFps;
  BOOL _trackingApi;
  NSString *_env;
  NSInteger _projectType;
  NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSNumber *> *> *_pagePerfMarks;
  NSMutableDictionary<NSString *, UMAPMFpsRecord *> *_fpsRecords;
  NSMutableDictionary<NSString *, UMAPMApiRecord *> *_apiRecords;
}
@end

@implementation UMAPMModule

RCT_EXPORT_MODULE(UMAPMModule);

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _trackingPagePerf = YES;
    _trackingPageFps = YES;
    _trackingApi = YES;
    _projectType = 0;
    _pagePerfMarks = [NSMutableDictionary dictionary];
    _fpsRecords = [NSMutableDictionary dictionary];
    _apiRecords = [NSMutableDictionary dictionary];
  }
  return self;
}

// ======================== 初始化（可从 TS 传参） ========================

/**
 * APM 初始化配置（JS 入口，可从 TS 传参）：NSDictionary → RNUMAPMConfig 后委托 initFromNative:。
 */
RCT_EXPORT_METHOD(init:(NSDictionary *)dict)
{
  RNUMAPMConfig *config = [RNUMAPMConfig new];
  if (dict != nil && ![dict isKindOfClass:[NSNull class]]) {
    if (dict[@"crashAndBlockMonitorEnable"])  config.crashAndBlockMonitorEnable = [dict[@"crashAndBlockMonitorEnable"] boolValue];
    if (dict[@"launchMonitorEnable"])     config.launchMonitorEnable = [dict[@"launchMonitorEnable"] boolValue];
    if (dict[@"memMonitorEnable"])        config.memMonitorEnable = [dict[@"memMonitorEnable"] boolValue];
    if (dict[@"networkEnable"])           config.networkEnable = [dict[@"networkEnable"] boolValue];
    if (dict[@"pageMonitorEnable"])       config.pageMonitorEnable = [dict[@"pageMonitorEnable"] boolValue];
    if (dict[@"logCollectEnable"])        config.logCollectEnable = [dict[@"logCollectEnable"] boolValue];
    if (dict[@"javaScriptBridgeEnable"])  config.javaScriptBridgeEnable = [dict[@"javaScriptBridgeEnable"] boolValue];
    if (dict[@"appVersion"])              config.appVersion = [dict[@"appVersion"] description];
    if (dict[@"buildVersion"])            config.buildVersion = [dict[@"buildVersion"] description];
  }
  [UMAPMModule initFromNative:config];
}

/**
 * APM 初始化配置核心（原生入口，供宿主 AppDelegate 直接调用，无需模块实例）。
 * 注意：iOS SDK 的 UMAPMConfig 崩溃与卡顿是单一开关 crashAndBlockMonitorEnable，
 * 与 RNUMAPMConfig.crashAndBlockMonitorEnable 一一对应；其余开关亦一一对应。
 * 必须在 UMConfigure initWithAppkey 之前调用才生效。
 */
+ (void)initFromNative:(RNUMAPMConfig *)config
{
  if (config == nil) {
    return;
  }
  UMAPMConfig *cfg = [UMAPMConfig defaultConfig];
  cfg.crashAndBlockMonitorEnable = config.crashAndBlockMonitorEnable;
  cfg.launchMonitorEnable = config.launchMonitorEnable;
  cfg.memMonitorEnable = config.memMonitorEnable;
  cfg.networkEnable = config.networkEnable;
  cfg.pageMonitorEnable = config.pageMonitorEnable;
  cfg.logCollectEnable = config.logCollectEnable;
  cfg.javaScriptBridgeEnable = config.javaScriptBridgeEnable;
  [UMCrashConfigure setAPMConfig:cfg];
  if (config.appVersion.length > 0) {
    [UMCrashConfigure setAppVersion:config.appVersion buildVersion:config.buildVersion ?: @""];
  }
}

// ======================== 异常上报 ========================

/**
 * 上报自定义异常
 */
RCT_EXPORT_METHOD(reportException:(NSString *)name
                  reason:(NSString *)reason
                  stackTrace:(NSArray *)stackTrace
                  extra:(NSDictionary *)extra)
{
  if (name == nil || [name isKindOfClass:[NSNull class]]) {
    return;
  }
  if ([reason isKindOfClass:[NSNull class]]) {
    reason = nil;
  }
  if ([stackTrace isKindOfClass:[NSNull class]]) {
    stackTrace = nil;
  }

  // 将 extra 以 JSON 字符串形式附加到堆栈末尾
  NSMutableArray *finalStack = [NSMutableArray array];
  if (stackTrace != nil) {
    [finalStack addObjectsFromArray:stackTrace];
  }
  if (extra != nil && ![extra isKindOfClass:[NSNull class]] && [extra count] > 0) {
    NSString *extraJson = [self jsonStringFromObject:extra];
    if (extraJson.length > 0) {
      [finalStack addObject:[NSString stringWithFormat:@"extra:%@", extraJson]];
    }
  }

  @try {
    [UMCrashConfigure reportExceptionWithName:name reason:(reason ?: @"") stackTrace:finalStack];
  } @catch (NSException *exception) {
    NSLog(@"[UMAPMModule] reportException failed: %@", exception.reason);
  }
}

// ======================== 自定义日志 ========================

/**
 * 自定义日志
 */
RCT_EXPORT_METHOD(log:(NSString *)tag
                  message:(NSString *)message
                  level:(NSString *)level)
{
  if (message == nil || [message isKindOfClass:[NSNull class]]) {
    return;
  }
  if ([tag isKindOfClass:[NSNull class]]) {
    tag = nil;
  }
  if (level == nil || [level isKindOfClass:[NSNull class]]) {
    level = @"info";
  }

  NSString *l = [level lowercaseString];
  if ([l isEqualToString:@"verbose"] || [l isEqualToString:@"v"]) {
    [UMAPMCustomLog vTag:tag msg:message];
  } else if ([l isEqualToString:@"debug"] || [l isEqualToString:@"d"]) {
    [UMAPMCustomLog dTag:tag msg:message];
  } else if ([l isEqualToString:@"warn"] || [l isEqualToString:@"warning"] || [l isEqualToString:@"w"]) {
    [UMAPMCustomLog wTag:tag msg:message];
  } else if ([l isEqualToString:@"error"] || [l isEqualToString:@"e"]) {
    [UMAPMCustomLog eTag:tag msg:message];
  } else {
    [UMAPMCustomLog iTag:tag msg:message];
  }
}

// ======================== 自定义维度 ========================

RCT_EXPORT_METHOD(setCustomStringParam:(NSString *)key value:(NSString *)value)
{
  if (key == nil || [key isKindOfClass:[NSNull class]]) {
    return;
  }
  if (value == nil || [value isKindOfClass:[NSNull class]]) {
    value = @"";
  }
  [UMCrashConfigure addCustomInfoKey:key value:value];
}

// ======================== 启动耗时 ========================

RCT_EXPORT_METHOD(beginLaunch:(NSString *)methodName)
{
  if (methodName == nil || [methodName isKindOfClass:[NSNull class]]) {
    return;
  }
  [UMLaunch beginLaunch:methodName];
}

RCT_EXPORT_METHOD(endLaunch:(NSString *)methodName)
{
  if (methodName == nil || [methodName isKindOfClass:[NSNull class]]) {
    return;
  }
  [UMLaunch endLaunch:methodName];
}

// ======================== 页面耗时 ========================

RCT_EXPORT_METHOD(beginPageTrace:(NSString *)methodName)
{
  if (methodName == nil || [methodName isKindOfClass:[NSNull class]]) {
    return;
  }
  UIViewController *vc = [self currentTopViewController];
  if (vc) {
    [UMPage trackBegin:methodName viewController:vc];
  }
}

RCT_EXPORT_METHOD(endPageTrace:(NSString *)methodName)
{
  if (methodName == nil || [methodName isKindOfClass:[NSNull class]]) {
    return;
  }
  UIViewController *vc = [self currentTopViewController];
  if (vc) {
    [UMPage trackEnd:methodName viewController:vc];
  }
}

// ======================== 页面性能追踪（FP/FCP/TTI）========================
//
// 说明：友盟原生 APM SDK（UMPage）仅提供页面加载耗时打点，
// 未暴露 FP/FCP/TTI 细粒度指标 API。此处采用"时间戳记录"方式在原生侧计算各阶段耗时并上报。

RCT_EXPORT_METHOD(beginPagePerf:(NSString *)pageName)
{
  if (pageName == nil || [pageName isKindOfClass:[NSNull class]] || !_trackingPagePerf) {
    return;
  }
  NSMutableDictionary *marks = [NSMutableDictionary dictionary];
  marks[@"begin"] = @([self nowMillis]);
  @synchronized (_pagePerfMarks) {
    _pagePerfMarks[pageName] = marks;
  }
}

RCT_EXPORT_METHOD(markPageFP:(NSString *)pageName)
{
  [self setPerfMark:pageName key:@"fp"];
}

RCT_EXPORT_METHOD(markPageFCP:(NSString *)pageName)
{
  [self setPerfMark:pageName key:@"fcp"];
}

RCT_EXPORT_METHOD(markPageTTI:(NSString *)pageName)
{
  [self setPerfMark:pageName key:@"tti"];
}

RCT_EXPORT_METHOD(endPagePerf:(NSString *)pageName)
{
  if (pageName == nil || [pageName isKindOfClass:[NSNull class]] || !_trackingPagePerf) {
    return;
  }
  NSMutableDictionary *marks;
  @synchronized (_pagePerfMarks) {
    marks = _pagePerfMarks[pageName];
    [_pagePerfMarks removeObjectForKey:pageName];
  }
  long long begin = [marks[@"begin"] longLongValue];
  if (marks == nil || begin <= 0) {
    return;
  }
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  data[@"page"] = pageName;
  data[@"fp"] = marks[@"fp"] ? @([marks[@"fp"] longLongValue] - begin) : @(-1);
  data[@"fcp"] = marks[@"fcp"] ? @([marks[@"fcp"] longLongValue] - begin) : @(-1);
  data[@"tti"] = marks[@"tti"] ? @([marks[@"tti"] longLongValue] - begin) : @(-1);
  [self reportPerfLog:@"rn_page_perf" data:data];
}

- (void)setPerfMark:(NSString *)pageName key:(NSString *)key
{
  if (pageName == nil || [pageName isKindOfClass:[NSNull class]] || !_trackingPagePerf) {
    return;
  }
  @synchronized (_pagePerfMarks) {
    NSMutableDictionary *marks = _pagePerfMarks[pageName];
    if (marks != nil) {
      marks[key] = @([self nowMillis]);
    }
  }
}

// ======================== 页面帧率追踪 ========================
//
// 通过 CADisplayLink 统计 begin/end 之间的刷新帧数，计算平均 FPS 并上报。

RCT_EXPORT_METHOD(beginPageFps:(NSString *)pageName)
{
  if (pageName == nil || [pageName isKindOfClass:[NSNull class]] || !_trackingPageFps) {
    return;
  }
  [self stopFpsRecord:pageName];
  UMAPMFpsRecord *record = [[UMAPMFpsRecord alloc] init];
  record.startTime = [self nowMillis];
  record.frameCount = 0;
  CADisplayLink *link = [CADisplayLink displayLinkWithTarget:record selector:@selector(tick:)];
  [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  record.displayLink = link;
  @synchronized (_fpsRecords) {
    _fpsRecords[pageName] = record;
  }
}

RCT_EXPORT_METHOD(endPageFps:(NSString *)pageName)
{
  if (pageName == nil || [pageName isKindOfClass:[NSNull class]] || !_trackingPageFps) {
    return;
  }
  UMAPMFpsRecord *record;
  @synchronized (_fpsRecords) {
    record = _fpsRecords[pageName];
    [_fpsRecords removeObjectForKey:pageName];
  }
  if (record == nil) {
    return;
  }
  [record.displayLink invalidate];
  record.displayLink = nil;
  long long elapsed = [self nowMillis] - record.startTime;
  double fps = elapsed > 0 ? (record.frameCount * 1000.0 / elapsed) : 0;
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  data[@"page"] = pageName;
  data[@"fps"] = @(round(fps * 100.0) / 100.0);
  data[@"frames"] = @(record.frameCount);
  data[@"duration"] = @(elapsed);
  [self reportPerfLog:@"rn_page_fps" data:data];
}

- (void)stopFpsRecord:(NSString *)pageName
{
  UMAPMFpsRecord *record;
  @synchronized (_fpsRecords) {
    record = _fpsRecords[pageName];
    [_fpsRecords removeObjectForKey:pageName];
  }
  if (record != nil) {
    [record.displayLink invalidate];
    record.displayLink = nil;
  }
}

// ======================== HTTP API 监控 ========================
//
// 原生 APM SDK 未提供针对业务请求的 begin/end 打点 API，
// 此处以时间戳记录方式统计请求耗时并上报。

RCT_EXPORT_METHOD(trackApiBegin:(NSString *)requestId uri:(NSString *)uri method:(NSString *)method)
{
  if (requestId == nil || [requestId isKindOfClass:[NSNull class]] || !_trackingApi) {
    return;
  }
  UMAPMApiRecord *record = [[UMAPMApiRecord alloc] init];
  record.uri = uri ?: @"";
  record.method = method ?: @"";
  record.beginTime = [self nowMillis];
  @synchronized (_apiRecords) {
    _apiRecords[requestId] = record;
  }
}

RCT_EXPORT_METHOD(trackApiEnd:(NSString *)requestId
                  statusCode:(nonnull NSNumber *)statusCode
                  spend:(nonnull NSNumber *)spend
                  reqSize:(nonnull NSNumber *)reqSize
                  resSize:(nonnull NSNumber *)resSize
                  type:(nonnull NSNumber *)type
                  message:(NSString *)message)
{
  if (requestId == nil || [requestId isKindOfClass:[NSNull class]] || !_trackingApi) {
    return;
  }
  UMAPMApiRecord *record;
  @synchronized (_apiRecords) {
    record = _apiRecords[requestId];
    [_apiRecords removeObjectForKey:requestId];
  }
  long long beginTime = record ? record.beginTime : [self nowMillis];
  long spendVal = spend ? [spend longValue] : 0;
  long realSpend = spendVal > 0 ? spendVal : ([self nowMillis] - beginTime);
  NSMutableDictionary *data = [NSMutableDictionary dictionary];
  data[@"requestId"] = requestId;
  data[@"uri"] = record.uri ?: @"";
  data[@"method"] = record.method ?: @"";
  data[@"statusCode"] = statusCode ?: @(0);
  data[@"spend"] = @(realSpend);
  data[@"reqSize"] = reqSize ?: @(0);
  data[@"resSize"] = resSize ?: @(0);
  data[@"type"] = type ?: @(0);
  data[@"message"] = (message && ![message isKindOfClass:[NSNull class]]) ? message : @"";
  [self reportPerfLog:@"rn_api" data:data];
}

// ======================== 版本设置 ========================

RCT_EXPORT_METHOD(setAppVersion:(NSString *)appVersion buildVersion:(NSString *)buildVersion)
{
  if (appVersion == nil || [appVersion isKindOfClass:[NSNull class]]) {
    return;
  }
  if (buildVersion == nil || [buildVersion isKindOfClass:[NSNull class]]) {
    buildVersion = @"";
  }
  [UMCrashConfigure setAppVersion:appVersion buildVersion:buildVersion];
}

// ======================== SDK 信息查询 ========================

RCT_EXPORT_METHOD(getSdkVersion:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  NSString *version = @"";
  @try {
    version = [UMCrashConfigure getVersion] ?: @"";
  } @catch (NSException *exception) {
    version = @"";
  }
  if (resolve) {
    resolve(version);
  }
}

RCT_EXPORT_METHOD(getDeviceMaxFps:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  NSInteger fps = 0;
  @try {
    fps = [UIScreen mainScreen].maximumFramesPerSecond;
  } @catch (NSException *exception) {
    fps = 0;
  }
  if (resolve) {
    resolve(@(fps));
  }
}

// ======================== 工具方法 ========================

/// 当前毫秒时间戳
- (long long)nowMillis
{
  return (long long)([[NSDate date] timeIntervalSince1970] * 1000);
}

/// 将字典/数组序列化为 JSON 字符串
- (NSString *)jsonStringFromObject:(id)object
{
  if (object == nil) {
    return @"";
  }
  @try {
    if (![NSJSONSerialization isValidJSONObject:object]) {
      return [object description] ?: @"";
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    if (data != nil) {
      return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
    }
  } @catch (NSException *exception) {
  }
  return @"";
}

/// 为性能数据附加公共字段并以自定义日志形式上报
- (void)reportPerfLog:(NSString *)type data:(NSMutableDictionary *)data
{
  NSMutableDictionary *payload = [data mutableCopy] ?: [NSMutableDictionary dictionary];
  if (_env.length > 0) {
    payload[@"env"] = _env;
  }
  payload[@"projectType"] = @(_projectType);
  payload[@"ts"] = @([self nowMillis]);
  NSString *content = [self jsonStringFromObject:payload];
  @try {
    // iOS 原生 APM SDK 无 generateCustomLog 等价接口，
    // 使用 reportExceptionWithName 上报。
    [UMCrashConfigure reportExceptionWithName:type reason:content stackTrace:@[]];
  } @catch (NSException *exception) {
  }
}

- (UIViewController *)currentTopViewController
{
  UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
  while (vc.presentedViewController) {
    vc = vc.presentedViewController;
  }
  if ([vc isKindOfClass:[UINavigationController class]]) {
    vc = [(UINavigationController *)vc topViewController];
  }
  return vc;
}

- (NSString *)stackTraceArrayToString:(NSArray *)array
{
  if (array == nil || array.count == 0) {
    return @"";
  }
  return [array componentsJoinedByString:@"\n"];
}

- (NSString *)buildExceptionStringWithName:(NSString *)name
                                    reason:(NSString *)reason
                                stackTrace:(NSString *)stackTrace
{
  NSMutableString *result = [NSMutableString stringWithString:name ?: @""];
  if (reason.length > 0) {
    [result appendFormat:@": %@", reason];
  }
  if (stackTrace.length > 0) {
    [result appendFormat:@"\n%@", stackTrace];
  }
  return result;
}

@end
