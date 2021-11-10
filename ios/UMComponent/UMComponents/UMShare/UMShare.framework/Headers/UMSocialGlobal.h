//
//  UMSocialGlobal.h
//  UMSocialSDK
//
//  Created by 张军华 on 16/8/16.
//  Copyright © 2016年 dongjianxiong. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  UMSocial的全局配置文件
 */


@class UMSocialWarterMarkConfig;

/**
 *  用来设置UMSocial的全局设置变量
 */
@interface  UMSocialGlobal: NSObject

+ (UMSocialGlobal *)shareInstance;

/**
 *  是否用cocos2dx,0-没有使用 1-使用cocos2dx 默认为0
 */
@property(atomic,readwrite, assign)NSInteger use_coco2dx;

/**
 *  统计的主题，默认为：UMSocialDefault
 */
@property(atomic,readwrite,copy)NSString* dc;

/**
 *  是否请求的回流统计请求，默认为不请求
 */
@property(atomic,readwrite,assign)BOOL isUrlRequest;

/**
 *  type字符串
 *  @discuss type是新加入的字段，目前默认值为@"native"
 */
@property(atomic,readwrite, copy)NSString* type;

/**
 *  Universal Links设置
 *  @note  universalLinkDic 的key是由UMSocialPlatformType来确定
 *         universalLinkDic 的value是由对应平台申请的universalLink来设置
 *
 *  @exapmle 比如微信平台的universalLink为:@"https://developer.umeng.com/"
 *  在初始化每个平台之前调用
 *  [UMSocialGlobal shareInstance].universalLinkDic = @{@(UMSocialPlatformType_WechatSession):@"https://developer.umeng.com/"};
 */
@property(atomic,readwrite, copy)NSDictionary* universalLinkDic;

/**
 *  设置额外的初始化平台的参数
 *  @note 目前用于企业微信的配置 corpId为第三方App所属企业的ID agentId 第三方App在企业内部的ID
 *  @exapmle 比如微信企业平台的额外初始化配置如下
    [UMSocialGlobal shareInstance].extraInitDic = @{
        @(UMSocialPlatformType_WechatWork):@{@"corpId":@"ww813cd5c1f46dc9ab",@"agentId":@"1000002"}
            };
 */
@property(atomic,readwrite, copy)NSDictionary* extraInitDic;


/**
 *  UMSocial的版本号
 *
 *  @return 返回当前的版本号
 */
+(NSString*)umSocialSDKVersion;


/**
 *  对平台的分享文本的时候，做规定的截断，默认开启
 *  @discuss 针对特定平台(比如:微信，qq,sina等)对当前的分享信息中的文本截断到合理的位置从而能成功分享
 */
@property(atomic,readwrite,assign)BOOL isTruncateShareText;

/**
 *  当前网络请求是否用https
 *  @discuss 针对ios9系统以后强制使用https的网络请求，针对分享的网络图片都必须是https的网络图片(此为苹果官方要求)
 *  @discuss 该函数默认开启https请求
 *  @discuss 如果开启ios9的请求后，自动会过滤ios的http的请求，并返回错误。
 *
 */
@property(atomic,readwrite,assign)BOOL isUsingHttpsWhenShareContent;


/**
 *  是否清除缓存在获得用户资料的时候
 *  默认设置为YES,代表请求用户的时候需要请求缓存
 *  NO,代表不清楚缓存，用缓存的数据请求用户数据
 */
@property(atomic,readwrite,assign)BOOL isClearCacheWhenGetUserInfo;


/**
 *  添加水印功能
 *  @note 此功能为6.2版本以后的功能
 *  @discuss 此函数默认关闭 NO - 关闭水印 YES - 打开水印
 *  @discuss 设置此函数为YES后，必须要设置warterMarkConfig,来配置图片水印和字符串水印，如果不配置，就会用默认的[UMSocialWarterMarkConfig defaultWarterMarkConfig]来显示水印
 */
@property(atomic,readwrite,assign)BOOL isUsingWaterMark;

/**
 *  添加水印的配置类
 *  @note 此功能为6.2版本以后的功能
 *  @discuss 设置isUsingWaterMark此函数为YES后，必须要设置warterMarkConfig,来配置图片水印和字符串水印
 */
@property(nonatomic,readwrite,strong)UMSocialWarterMarkConfig* warterMarkConfig;


/**
 *  废弃 API
 */
@property(atomic,readwrite,copy)NSString* thumblr_Tag;

@end

