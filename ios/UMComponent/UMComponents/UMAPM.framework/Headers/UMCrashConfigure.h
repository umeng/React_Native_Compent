//
//  UMCrashConfigure.h
//  UMCrash
//
//  Created by wangkai on 2020/9/3.
//  Copyright © 2020 wangkai. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NSString *_Nullable(^CallbackBlock)(void);
@class UMAPMConfig;

@interface UMCrashConfigure : NSObject
//获取sdk版本号
+ (NSString *_Nonnull)getVersion;

//return字符串不能大于256字节，大于部分将被截取
+ (void)setCrashCBBlock:(CallbackBlock _Nullable )cbBlock;


/**
 *  设置自定义版本号和build版本号即子版本号 (需要在初始化appkey方法之前调用)
 */
+ (void)setAppVersion:( NSString * __nonnull )appVersion buildVersion:(NSString* __nullable)buildVersion;


/**
 *  设置APM的各个模块的开启/关闭配置(需要在初始化appkey方法之前调用)
 */
+(void)setAPMConfig:(UMAPMConfig*_Nonnull)config;

@end

