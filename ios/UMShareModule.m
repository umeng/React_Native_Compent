//
//  UMShareModule.m
//  umeng-react-native
//
//  友盟分享 React Native 桥接模块
//
//  从旧版 UMShareModule.m 迁移，关键变更：
//  - platform 参数由数字 ID 改为字符串枚举
//  - share / auth / shareboard 由 Callback 改为 Promise
//  - 分享内容参数合并为 shareParams 字典
//  - 修正旧版 nil 检查 bug
//  - 使用 Legacy Module 方式保证编译兼容
//

#import "UMShareModule.h"
#import <UMShare/UMShare.h>
#import <UShareUI/UShareUI.h>
#import <React/RCTConvert.h>

/**
 * 平台类型 → 中文名，仅用于日志可读性（C 静态函数，需先于调用点定义）
 */
static NSString *UMSharePlatformName(UMSocialPlatformType type)
{
  switch (type) {
    case UMSocialPlatformType_WechatSession:  return @"微信会话";
    case UMSocialPlatformType_WechatTimeLine: return @"微信朋友圈";
    case UMSocialPlatformType_WechatFavorite: return @"微信收藏";
    case UMSocialPlatformType_QQ:             return @"QQ";
    case UMSocialPlatformType_Qzone:          return @"QQ空间";
    case UMSocialPlatformType_Sina:           return @"新浪微博";
    case UMSocialPlatformType_DingDing:       return @"钉钉";
    case UMSocialPlatformType_APSession:      return @"支付宝";
    default:                                  return @"未知平台";
  }
}

@implementation UMShareModule

RCT_EXPORT_MODULE(UMShareModule);

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

#pragma mark - Init (TS-callable)

/**
 * 分享平台初始化配置（JS 入口，可从 TS 传参）：NSDictionary → RNUMShareConfig 后委托 initFromNative:。
 */
RCT_EXPORT_METHOD(init:(NSDictionary *)dict)
{
  RNUMShareConfig *config = [RNUMShareConfig new];
  if (dict != nil && ![dict isKindOfClass:[NSNull class]]) {
    if (dict[@"weixinAppId"])      config.weixinAppId = [dict[@"weixinAppId"] description];
    if (dict[@"weixinAppSecret"])  config.weixinAppSecret = [dict[@"weixinAppSecret"] description];
    if (dict[@"qqAppId"])          config.qqAppId = [dict[@"qqAppId"] description];
    if (dict[@"qqAppKey"])         config.qqAppKey = [dict[@"qqAppKey"] description];
    if (dict[@"sinaAppKey"])       config.sinaAppKey = [dict[@"sinaAppKey"] description];
    if (dict[@"sinaAppSecret"])    config.sinaAppSecret = [dict[@"sinaAppSecret"] description];
    if (dict[@"sinaRedirectUrl"])  config.sinaRedirectUrl = [dict[@"sinaRedirectUrl"] description];
    if (dict[@"dingAppId"])        config.dingAppId = [dict[@"dingAppId"] description];
    if (dict[@"universalLink"])    config.universalLink = [dict[@"universalLink"] description];
  }
  [UMShareModule initFromNative:config];
}

/**
 * 分享平台初始化配置核心（原生入口，供宿主 AppDelegate 直接调用，无需模块实例）。
 * setPlaform: 内部会同步等待（疑似网络请求），放主线程会触发 watchdog，故切后台队列；
 * 微博/微信 SDK 要求 universalLink 非空，否则 setPlaform 崩溃，故先设 universalLinkDic，
 * 并整段套 @try/@catch 兜底（后台队列未捕获异常会直接 signal 9 杀进程）。
 *
 * 注册完成后回主线程调用 setPreDefinePlatforms: 预设分享面板平台列表，
 * 并逐平台打印 isInstall 安装态——面板只显示「已注册且设备已安装对应 App」的平台，
 * 未安装的会被 SDK 过滤（上架审核要求），日志用于定位面板缺项原因。
 */
+ (void)initFromNative:(RNUMShareConfig *)config
{
  if (config == nil) {
    return;
  }
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
    // 本次实际配置到的平台（注册后用于 setPreDefinePlatforms 与安装态诊断）
    NSMutableArray<NSNumber *> *configuredPlatforms = [NSMutableArray array];
    @try {
      NSString *universalLink = config.universalLink.length > 0 ? config.universalLink : @"https://developer.umeng.com/";
      NSLog(@"[UMShareModule] 开始配置分享平台: universalLink=%@ weixinAppId=%@ qqAppId=%@ sinaAppKey=%@ dingAppId=%@",
            universalLink, config.weixinAppId, config.qqAppId, config.sinaAppKey, config.dingAppId);
      [UMSocialGlobal shareInstance].universalLinkDic = @{
        @(UMSocialPlatformType_Sina) : universalLink,
        @(UMSocialPlatformType_WechatSession) : universalLink,
        @(UMSocialPlatformType_WechatTimeLine) : universalLink,
        @(UMSocialPlatformType_WechatFavorite) : universalLink,
      };
      if (config.weixinAppId.length > 0) {
        NSLog(@"[UMShareModule] 配置微信: appId=%@", config.weixinAppId);
        [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_WechatSession
                                              appKey:config.weixinAppId
                                           appSecret:config.weixinAppSecret ?: @""
                                         redirectURL:@"http://mobile.umeng.com/social"];
        // 微信 handler 同时承载 会话/朋友圈/收藏 三种平台类型
        [configuredPlatforms addObjectsFromArray:@[
          @(UMSocialPlatformType_WechatSession),
          @(UMSocialPlatformType_WechatTimeLine),
        ]];
        NSLog(@"[UMShareModule] 微信注册完成（会话 + 朋友圈）");
      }
      if (config.sinaAppKey.length > 0) {
        NSLog(@"[UMShareModule] 配置新浪微博: appKey=%@", config.sinaAppKey);
        [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Sina
                                              appKey:config.sinaAppKey
                                           appSecret:config.sinaAppSecret ?: @""
                                         redirectURL:config.sinaRedirectUrl.length > 0 ? config.sinaRedirectUrl : @"http://sns.whalecloud.com"];
        [configuredPlatforms addObject:@(UMSocialPlatformType_Sina)];
        NSLog(@"[UMShareModule] 新浪微博注册完成");
      }
      if (config.qqAppId.length > 0) {
        NSLog(@"[UMShareModule] 配置 QQ: appId=%@", config.qqAppId);
        [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_QQ
                                              appKey:config.qqAppId
                                           appSecret:config.qqAppKey ?: @""
                                         redirectURL:@"http://mobile.umeng.com/social"];
        // QQ handler 同时承载 QQ / QQ空间
        [configuredPlatforms addObjectsFromArray:@[
          @(UMSocialPlatformType_QQ),
          @(UMSocialPlatformType_Qzone),
        ]];
        NSLog(@"[UMShareModule] QQ 注册完成（QQ + QQ空间）");
      }
      if (config.dingAppId.length > 0) {
        NSLog(@"[UMShareModule] 配置钉钉: appId=%@", config.dingAppId);
        [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_DingDing
                                              appKey:config.dingAppId
                                           appSecret:@""
                                         redirectURL:@"http://mobile.umeng.com/social"];
        [configuredPlatforms addObject:@(UMSocialPlatformType_DingDing)];
        NSLog(@"[UMShareModule] 钉钉注册完成");
      }
    } @catch (NSException *exception) {
      NSLog(@"[UMShareModule] 分享平台配置异常: %@", exception.reason);
    }
    [UMShareModule applyPreDefinePlatforms:configuredPlatforms];
  });
}

/**
 * 设置分享面板默认显示的平台列表，并打印各平台安装态。
 *
 * UMSocialUIManager 约束：
 *  - setPreDefinePlatforms: 必须在 showShareMenuViewInWindowWithPlatformSelectionBlock: 之前调用；
 *  - 传入平台必须是 core 模块已检测到的（已注册 + 设备已安装对应 App），否则被过滤。
 * 故这里只把 initFromNative: 实际注册过的平台传进去，避免面板顺序随 SDK 默认列表漂移。
 * isInstall: 内部走 UIApplication canOpenURL，必须回主线程调用。
 */
+ (void)applyPreDefinePlatforms:(NSArray<NSNumber *> *)platforms
{
  if (platforms == nil || platforms.count == 0) {
    NSLog(@"[UMShareModule] 未配置任何分享平台，跳过 setPreDefinePlatforms");
    return;
  }
  NSArray<NSNumber *> *list = [platforms copy];
  dispatch_async(dispatch_get_main_queue(), ^{
    @try {
      for (NSNumber *item in list) {
        UMSocialPlatformType type = (UMSocialPlatformType)item.integerValue;
        BOOL installed = [[UMSocialManager defaultManager] isInstall:type];
        NSLog(@"[UMShareModule] 面板平台 %@(%ld) 设备已安装=%@%@",
              UMSharePlatformName(type), (long)item.integerValue, installed ? @"YES" : @"NO",
              installed ? @"" : @" —— 未安装将被分享面板过滤");
      }
      [UMSocialUIManager setPreDefinePlatforms:list];
      NSLog(@"[UMShareModule] setPreDefinePlatforms 完成，共 %lu 个平台: %@",
            (unsigned long)list.count, list);
    } @catch (NSException *exception) {
      NSLog(@"[UMShareModule] setPreDefinePlatforms 异常: %@", exception.reason);
    }
  });
}

#pragma mark - Platform Mapping

/**
 * 平台字符串枚举 → UMSocialPlatformType
 * 返回 -1 表示不支持的平台
 */
- (UMSocialPlatformType)platformTypeFromString:(NSString *)platform
{
  if (platform == nil || [platform isKindOfClass:[NSNull class]]) {
    return -1;
  }

  static NSDictionary<NSString *, NSNumber *> *platformMap = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    platformMap = @{
      @"wechat_session":    @(UMSocialPlatformType_WechatSession),
      @"wechat_timeline":   @(UMSocialPlatformType_WechatTimeLine),
      @"wechat_favorite":   @(UMSocialPlatformType_WechatFavorite),
      @"qq":                @(UMSocialPlatformType_QQ),
      @"qzone":             @(UMSocialPlatformType_Qzone),
      @"sina":              @(UMSocialPlatformType_Sina),
      @"alipay":            @(UMSocialPlatformType_APSession),
      @"dingtalk":          @(UMSocialPlatformType_DingDing),
      @"sms":               @(UMSocialPlatformType_Sms),
      @"email":             @(UMSocialPlatformType_Email),
      @"facebook":          @(UMSocialPlatformType_Facebook),
      @"twitter":           @(UMSocialPlatformType_Twitter),
      @"linkedin":          @(UMSocialPlatformType_Linkedin),
      @"instagram":         @(UMSocialPlatformType_Instagram),
      @"whatsapp":          @(UMSocialPlatformType_Whatsapp),
      @"line":              @(UMSocialPlatformType_Line),
      @"pinterest":         @(UMSocialPlatformType_Pinterest),
      @"pocket":            @(UMSocialPlatformType_Pocket),
      @"dropbox":           @(UMSocialPlatformType_DropBox),
      @"vkontakte":         @(UMSocialPlatformType_VKontakte),
      @"kakao":             @(UMSocialPlatformType_KakaoTalk),
      @"tumblr":            @(UMSocialPlatformType_Tumblr),
      @"flickr":            @(UMSocialPlatformType_Flickr),
      @"youdao_note":       @(UMSocialPlatformType_YouDaoNote),
      @"evernote":          @(UMSocialPlatformType_EverNote),
      @"facebook_messenger":@(UMSocialPlatformType_FaceBookMessenger),
    };
  });

  NSNumber *value = platformMap[platform];
  return value ? value.integerValue : -1;
}

#pragma mark - Share Helper

- (void)shareWithParams:(NSDictionary *)params
               platform:(UMSocialPlatformType)platformType
                resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject
{
  NSString *text = params[@"text"];
  NSString *img = params[@"img"];
  NSString *webUrl = params[@"webUrl"];
  NSString *title = params[@"title"];

  // 修正旧版 nil 检查 bug：`&&` → `||`
  if ([text isKindOfClass:[NSNull class]]) text = nil;
  if ([img isKindOfClass:[NSNull class]]) img = nil;
  if ([webUrl isKindOfClass:[NSNull class]]) webUrl = nil;
  if ([title isKindOfClass:[NSNull class]]) title = nil;

  UMSocialMessageObject *messageObject = [UMSocialMessageObject messageObject];

  if (webUrl.length > 0) {
    UMShareWebpageObject *shareObject = [UMShareWebpageObject shareObjectWithTitle:title
                                                                             descr:text
                                                                         thumImage:[self resolveImage:img]];
    shareObject.webpageUrl = webUrl;
    messageObject.shareObject = shareObject;
  } else if (img.length > 0) {
    id image = [self resolveImage:img];
    UMShareImageObject *shareObject = [[UMShareImageObject alloc] init];
    shareObject.thumbImage = image;
    shareObject.shareImage = image;
    messageObject.shareObject = shareObject;
    messageObject.text = text;
  } else if (text.length > 0) {
    messageObject.text = text;
  } else {
    reject(@"E_INVALID_PARAMS", @"Share params must contain at least text, img, or webUrl", nil);
    return;
  }

  [[UMSocialManager defaultManager] shareToPlatform:platformType
                                      messageObject:messageObject
                              currentViewController:nil
                                         completion:^(id result, NSError *error) {
    if (error) {
      NSString *msg = error.userInfo[@"NSLocalizedFailureReason"];
      if (!msg) msg = error.userInfo[@"message"];
      if (!msg) msg = @"share failed";

      NSInteger code = error.code;
      if (code == 2009) {
        // 用户取消
        NSDictionary *res = @{@"code": @(-1), @"message": @"cancel"};
        resolve(res);
      } else {
        reject(@"E_SHARE_ERROR", msg, error);
      }
    } else {
      NSDictionary *res = @{@"code": @(200), @"message": @"success"};
      resolve(res);
    }
  }];
}

/**
 * 解析图片资源：URL / 本地绝对路径 / bundle 相对路径
 */
- (id)resolveImage:(NSString *)img
{
  if (img == nil || img.length == 0) {
    return nil;
  }
  if ([img hasPrefix:@"http"]) {
    return img;
  } else if ([img hasPrefix:@"/"]) {
    return [UIImage imageWithContentsOfFile:img];
  } else {
    return [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:img ofType:nil]];
  }
}

#pragma mark - Share

RCT_EXPORT_METHOD(share:(NSString *)platform
           shareParams:(NSDictionary *)shareParams
               resolve:(RCTPromiseResolveBlock)resolve
                reject:(RCTPromiseRejectBlock)reject)
{
  UMSocialPlatformType plf = [self platformTypeFromString:platform];
  if ((NSInteger)plf == -1) {
    reject(@"E_PLATFORM_UNSUPPORTED", [NSString stringWithFormat:@"Unsupported platform: %@", platform], nil);
    return;
  }

  if (shareParams == nil || [shareParams isKindOfClass:[NSNull class]]) {
    shareParams = @{};
  }

  [self shareWithParams:shareParams platform:plf resolve:resolve reject:reject];
}

#pragma mark - Shareboard

RCT_EXPORT_METHOD(shareboard:(NSDictionary *)shareParams
              platforms:(NSArray *)platforms
                resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject)
{
  if (shareParams == nil || [shareParams isKindOfClass:[NSNull class]]) {
    shareParams = @{};
  }

  NSMutableArray *plfs = [NSMutableArray array];
  if (platforms != nil && ![platforms isKindOfClass:[NSNull class]]) {
    for (NSString *p in platforms) {
      UMSocialPlatformType t = [self platformTypeFromString:p];
      if ((NSInteger)t != -1) {
        [plfs addObject:@(t)];
      } else {
        NSLog(@"[UMShareModule] shareboard 忽略不支持的平台参数: %@", p);
      }
    }
  }

  if (plfs.count > 0) {
    [UMSocialUIManager setPreDefinePlatforms:plfs];
  }

  // 面板只显示「已 setPlaform 注册 且 设备已安装对应 App」的平台，
  // 传入多个却只弹出一个时，先靠这段日志确认是未注册还是未安装被 SDK 过滤。
  for (NSNumber *item in plfs) {
    UMSocialPlatformType t = (UMSocialPlatformType)item.integerValue;
    BOOL installed = [[UMSocialManager defaultManager] isInstall:t];
    NSLog(@"[UMShareModule] shareboard 请求平台 %@(%ld) 设备已安装=%@%@",
          UMSharePlatformName(t), (long)item.integerValue, installed ? @"YES" : @"NO",
          installed ? @"" : @" —— 不会出现在面板上");
  }
  NSLog(@"[UMShareModule] shareboard 共请求 %lu 个平台，弹出面板", (unsigned long)plfs.count);

  // 保存 shareParams 供 block 内使用
  NSDictionary *params = [shareParams copy];

  [UMSocialUIManager showShareMenuViewInWindowWithPlatformSelectionBlock:^(UMSocialPlatformType platformType, NSDictionary *userInfo) {
    [self shareWithParams:params platform:platformType resolve:resolve reject:reject];
  }];
}

#pragma mark - Auth

RCT_EXPORT_METHOD(auth:(NSString *)platform
            resolve:(RCTPromiseResolveBlock)resolve
             reject:(RCTPromiseRejectBlock)reject)
{
  UMSocialPlatformType plf = [self platformTypeFromString:platform];
  if ((NSInteger)plf == -1) {
    reject(@"E_PLATFORM_UNSUPPORTED", [NSString stringWithFormat:@"Unsupported platform: %@", platform], nil);
    return;
  }

  [[UMSocialManager defaultManager] getUserInfoWithPlatform:plf
                                      currentViewController:nil
                                                 completion:^(id result, NSError *error) {
    if (error) {
      NSString *msg = error.userInfo[@"NSLocalizedFailureReason"];
      if (!msg) msg = error.userInfo[@"message"];
      if (!msg) msg = @"auth failed";

      NSInteger code = error.code;
      if (code == 2009) {
        // 用户取消
        NSDictionary *res = @{@"code": @(-1), @"message": @"cancel", @"data": @{}};
        resolve(res);
      } else {
        reject(@"E_AUTH_ERROR", msg, error);
      }
    } else {
      UMSocialUserInfoResponse *authInfo = result;

      NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:12];
      if (authInfo.uid)          data[@"uid"] = authInfo.uid;
      if (authInfo.openid)       data[@"openid"] = authInfo.openid;
      if (authInfo.unionId)      data[@"unionid"] = authInfo.unionId;
      if (authInfo.accessToken)  data[@"accessToken"] = authInfo.accessToken;
      if (authInfo.refreshToken) data[@"refreshToken"] = authInfo.refreshToken;
      if (authInfo.expiration)   data[@"expiration"] = authInfo.expiration;
      if (authInfo.name)         data[@"name"] = authInfo.name;
      if (authInfo.iconurl)      data[@"iconurl"] = authInfo.iconurl;
      if (authInfo.unionGender)  data[@"gender"] = authInfo.unionGender;

      NSDictionary *originInfo = authInfo.originalResponse;
      if (originInfo[@"city"])     data[@"city"] = originInfo[@"city"];
      if (originInfo[@"province"]) data[@"province"] = originInfo[@"province"];
      if (originInfo[@"country"])  data[@"country"] = originInfo[@"country"];

      NSDictionary *res = @{@"code": @(200), @"message": @"success", @"data": data};
      resolve(res);
    }
  }];
}

@end
