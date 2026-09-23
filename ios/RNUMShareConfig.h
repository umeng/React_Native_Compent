//
//  RNUMShareConfig.h
//  umeng-react-native
//
//  友盟分享平台原生初始化配置对象。
//  命名加 RN 前缀以区别于友盟 SDK 类（ObjC 无命名空间）。
//

#import <Foundation/Foundation.h>

@interface RNUMShareConfig : NSObject

/// 微信 AppId
@property (nonatomic, copy) NSString *weixinAppId;
/// 微信 AppSecret
@property (nonatomic, copy) NSString *weixinAppSecret;
/// QQ / QQ空间 AppId
@property (nonatomic, copy) NSString *qqAppId;
/// QQ / QQ空间 AppKey
@property (nonatomic, copy) NSString *qqAppKey;
/// 新浪微博 AppKey
@property (nonatomic, copy) NSString *sinaAppKey;
/// 新浪微博 AppSecret
@property (nonatomic, copy) NSString *sinaAppSecret;
/// 新浪微博 RedirectUrl
@property (nonatomic, copy) NSString *sinaRedirectUrl;
/// 钉钉 AppId
@property (nonatomic, copy) NSString *dingAppId;
/// Universal Link（微博/微信 SDK 要求非空，否则 setPlaform 崩溃）
@property (nonatomic, copy) NSString *universalLink;

@end
