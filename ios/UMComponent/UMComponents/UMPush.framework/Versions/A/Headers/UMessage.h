//
//  UMessage.h
//  UMessage
//
//  Created by shile on 2017/4/1.
//  Copyright © 2017年 umeng.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
/** String type for alias
 */
//新浪微博
UIKIT_EXTERN NSString * __nonnull const kUMessageAliasTypeSina;
//腾讯微博
UIKIT_EXTERN NSString * __nonnull const kUMessageAliasTypeTencent;
//QQ
UIKIT_EXTERN NSString * __nonnull const kUMessageAliasTypeQQ;
//微信
UIKIT_EXTERN NSString * __nonnull const kUMessageAliasTypeWeiXin;
//百度
UIKIT_EXTERN NSString * __nonnull const kUMessageAliasTypeBaidu;
//人人网
UIKIT_EXTERN NSString * __nonnull const kUMessageAliasTypeRenRen;
//开心网
UIKIT_EXTERN NSString * __nonnull const kUMessageAliasTypeKaixin;
//豆瓣
UIKIT_EXTERN NSString * __nonnull const kUMessageAliasTypeDouban;
//facebook
UIKIT_EXTERN NSString * __nonnull const kUMessageAliasTypeFacebook;
//twitter
UIKIT_EXTERN NSString * __nonnull const kUMessageAliasTypeTwitter;


//error for handle
extern NSString * __nonnull const kUMessageErrorDomain;

typedef NS_ENUM(NSInteger, kUMessageError) {
    /**未知错误*/
    kUMessageErrorUnknown = 0,
    /**响应出错*/
    kUMessageErrorResponseErr = 1,
    /**操作失败*/
    kUMessageErrorOperateErr = 2,
    /**参数非法*/
    kUMessageErrorParamErr = 3,
    /**条件不足(如:还未获取device_token，添加tag是不成功的)*/
    kUMessageErrorDependsErr = 4,
    /**服务器限定操作*/
    kUMessageErrorServerSetErr = 5,
};

typedef NS_OPTIONS(NSUInteger, UMessageAuthorizationOptions) {
    UMessageAuthorizationOptionNone    = 0,
    UMessageAuthorizationOptionBadge   = (1 << 0),
    UMessageAuthorizationOptionSound   = (1 << 1),
    UMessageAuthorizationOptionAlert   = (1 << 2),
};

typedef void (^UMPlaunchFinishBlock)();

@interface UMessageRegisterEntity : NSObject
//需要注册的类型
@property (nonatomic, assign) NSInteger types;

@property (nonatomic, strong) NSSet * __nullable categories;
@end

/** UMessage：开发者使用主类（API）
 */
@interface UMessage : NSObject


///---------------------------------------------------------------------------------------
/// @name settings（most required）
///---------------------------------------------------------------------------------------

//--required

/**
 友盟推送的注册接口

 @param launchOptions 系统的launchOptions启动消息参数用于处理用户通过消息打开应用相关信息。
 @param entity 友盟推送的注册类如果使用默认的注册，Entity设置为nil即可。如需其他的可选择其他参数，具体的参考demo或者文档。
 @param completionHandler iOS10授权后的回调。
 */
+ (void)registerForRemoteNotificationsWithLaunchOptions:(NSDictionary * __nullable)launchOptions Entity:(UMessageRegisterEntity * __nullable)entity completionHandler:(void (^ __nullable)(BOOL granted, NSError *_Nullable error))completionHandler;


/** 解除RemoteNotification的注册（关闭消息推送，实际调用：[[UIApplication sharedApplication] unregisterForRemoteNotifications]）
 
 iOS10.0，iOS10.1两个版本存在系统bug,调用此方法后可能会导致无法再次打开推送
 */
+ (void)unregisterForRemoteNotifications;

/** 向友盟注册该设备的deviceToken，便于发送Push消息
 @param deviceToken APNs返回的deviceToken
 */
+ (void)registerDeviceToken:( NSData * __nullable)deviceToken;

/** 应用处于运行时（前台、后台）的消息处理，回传点击数据
 @param userInfo 消息参数
 */
+ (void)didReceiveRemoteNotification:( NSDictionary * __nullable)userInfo;

/** 设置是否允许SDK自动清空角标（默认开启）
 @param value 是否开启角标清空
 */
+ (void)setBadgeClear:(BOOL)value;

/** 设置是否允许SDK当应用在前台运行收到Push时弹出Alert框（默认开启）
 @param value 是否开启弹出框
 */
+ (void)setAutoAlert:(BOOL)value;

/** 为某个消息发送点击事件
 */
+ (void)sendClickReportForRemoteNotification:(NSDictionary * __nullable)userInfo;


///---------------------------------------------------------------------------------------
/// @name tag (optional)
///---------------------------------------------------------------------------------------


/** 获取当前绑定设备上的所有tag(每台设备最多绑定1024个tag)
 @warning 获取列表的先决条件是已经成功获取到device_token，否则失败(kUMessageErrorDependsErr)
 @param handle responseTags为绑定的tag
 集合,remain剩余可用的tag数,为-1时表示异常,error为获取失败时的信息(ErrCode:kUMessageError)
 */
+ (void)getTags:(void (^__nonnull)(NSSet * __nonnull responseTags,NSInteger remain,NSError * __nullable error))handle;

/** 绑定一个或多个tag至设备，每台设备最多绑定1024个tag，超过1024个，绑定tag不再成功，可`removeTag`来精简空间
 @warning 添加tag的先决条件是已经成功获取到device_token，否则直接添加失败(kUMessageErrorDependsErr)
 @param tag tag标记,可以为单个tag（NSString）也可以为tag集合（NSArray、NSSet），单个tag最大允许长度128字节，编码UTF-8，超过长度绑定失败
 @param handle responseTags为绑定的tag集合,remain剩余可用的tag数,为-1时表示异常,error为获取失败时的信息(ErrCode:kUMessageError)
 */
+ (void)addTags:(__nonnull id)tag response:( void (^ __nonnull)(id __nullable responseObject ,NSInteger remain,NSError * __nullable error))handle;

/** 删除设备中绑定的一个或多个tag
 @warning 添加tag的先决条件是已经成功获取到device_token，否则失败(kUMessageErrorDependsErr)
 @param tag tag标记,可以为单个tag（NSString）也可以为tag集合（NSArray、NSSet），单个tag最大允许长度128字节，编码UTF-8，超过长度删除失败
 @param handle responseTags为绑定的tag集合,remain剩余可用的tag数,为-1时表示异常,error为获取失败时的信息(ErrCode:kUMessageError)
 */
+ (void)deleteTags:(__nonnull id)tag response:(void (^__nonnull)(id __nullable responseObject,NSInteger remain,NSError * __nullable error))handle;


///---------------------------------------------------------------------------------------
/// @name WeightedTag (optional)
///---------------------------------------------------------------------------------------

/**
 绑定一个或多个weightedtag以及权值至设备

 @warning 添加tag的先决条件是已经成功获取到device_token，否则直接添加失败(kUMessageErrorDependsErr)
 @param weightedTag tag标记,为NSDictionary类型，key为weightedtag名称，value为权值。
 @param handle responseTags为绑定的tag集合,remain剩余可用的tag数,为-1时表示异常,error为获取失败时的信息(ErrCode:kUMessageError)
 */
+ (void)addWeightedTags:(NSDictionary * __nonnull)weightedTag response:(void (^__nonnull)(id __nullable responseObject ,NSInteger remain,NSError * __nullable error))handle;

/** 获取当前绑定设备上的所有Weightedtag
 @warning 获取列表的先决条件是已经成功获取到device_token，否则失败(kUMessageErrorDependsErr)
 @param handle responseWeightedTags为绑定的WeightedTags字典，key为weightedtag名称，value为权值,remain剩余可用的weightedtag数,为-1时表示异常,error为获取失败时的信息(ErrCode:kUMessageError)
 */
+ (void)getWeightedTags:(void (^__nonnull)(NSDictionary * __nullable responseWeightedTags,NSInteger remain,NSError * __nullable error))handle;

/**
 删除一个设备中绑定的一个或多个weightedtag
 
 @warning 添加tag的先决条件是已经成功获取到device_token，否则直接添加失败(kUMessageErrorDependsErr)
 @param weightedTags tag标记,为NSDictionary类型，key为tag名称，value为权值。
 @param handle responseTags为绑定的tag集合,remain剩余可用的tag数,为-1时表示异常,error为获取失败时的信息(ErrCode:kUMessageError)
 */
+ (void)deleteWeightedTags:(id __nonnull)weightedTags response:(void (^__nonnull)(id __nullable responseObject,NSInteger remain,NSError * __nullable error))handle;

/// @name alias (optional)
///---------------------------------------------------------------------------------------


/** 绑定一个别名至设备（含账户，和平台类型）
 @warning 添加Alias的先决条件是已经成功获取到device_token，否则失败(kUMessageErrorDependsErr)
 @param name 账户，例如email
 @param type 平台类型，参见本文件头部的`kUMessageAliasType...`，例如：kUMessageAliasTypeSina
 @param handle block返回数据，error为获取失败时的信息，responseObject为成功返回的数据
 */
+ (void)addAlias:(NSString * __nonnull)name type:(NSString * __nonnull)type response:(void (^__nonnull)(id __nullable responseObject,NSError * __nullable error))handle;

/** 绑定一个别名至设备（含账户，和平台类型）,并解绑这个别名曾今绑定过的设备。
 @warning 添加Alias的先决条件是已经成功获取到device_token，否则失败(kUMessageErrorDependsErr)
 @param name 账户，例如email
 @param type 平台类型，参见本文件头部的`kUMessageAliasType...`，例如：kUMessageAliasTypeSina
 @param handle block返回数据，error为获取失败时的信息，responseObject为成功返回的数据
 */
+ (void)setAlias:(NSString * __nonnull )name type:(NSString * __nonnull)type response:(void (^__nonnull)(id __nullable responseObject,NSError * __nullable error))handle;

/** 删除一个设备的别名绑定
 @warning 删除Alias的先决条件是已经成功获取到device_token，否则失败(kUMessageErrorDependsErr)
 @param name 账户，例如email
 @param type 平台类型，参见本文件头部的`kUMessageAliasType...`，例如：kUMessageAliasTypeSina
 @param handle block返回数据，error为获取失败时的信息，responseObject为成功返回的数据
 */
+ (void)removeAlias:(NSString * __nonnull)name type:(NSString * __nonnull)type response:(void (^__nonnull)(id __nullable responseObject, NSError * __nullable error))handle;


/** 添加一个启动页的开屏消息
 */
+(void)addLaunchMessage;

/** 添加一个插屏消息
 @warning 需先在触发一次才可以在后台配置中找到该标识
 @param label 当前位置的标识
 */
+(void)addCardMessageWithLabel:(NSString* __nonnull)label;

/**
 @warning 需先在触发一次才可以在后台配置中找到该标识
 添加一个自定义插屏消息

 @param portraitsize portrait时显示的size
 @param landscapesize landscape时显示的大小
 @param button button 可以自定义的button
 @param label 标识
 */
+(void)addCustomCardMessageWithPortraitSize:(CGSize )portraitsize LandscapeSize:(CGSize )landscapesize CloseBtn:(UIButton * __nullable )button  Label:(NSString * __nonnull)label umCustomCloseButtonDisplayMode:(BOOL )displaymode;


/**
 @warning 需先在触发一次才可以在后台配置中找到该标识
 增加一个文本插屏消息

 @param label 当前位置的标识
 */
+(void)addPlainTextCardMessageWithTitleFont:(UIFont * __nullable)titlefont ContentFont:(UIFont * __nullable)contentfont buttonFont:(UIFont * __nullable)buttonfont Label:(NSString * __nonnull)label;;

/**
 设置应用内通知的模式

 @param debugmode 是否是debug模式
 */
+(void)openDebugMode:(BOOL)debugmode;

/**
 @warning 注意此方法使用场景必须有Navigation 
 设置webViewController在.h文件中声明一个叫url的参数，SDK内部会去调用
 @param webViewClassString webViewController的Class String
 */
+(void)setWebViewClassString:(NSString * __nonnull)webViewClassString;
@end
