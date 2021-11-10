//
//  UMAPMConfig.h
//  UMAPM
//
//  Created by zhangjunhua on 2021/6/21.
//  Copyright © 2021 wangkai. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UMAPMConfig : NSObject<NSCopying>



+(UMAPMConfig*)defaultConfig;

/**
 *  crash&卡顿监控开关，默认开启
 */
@property (nonatomic,assign) BOOL crashAndBlockMonitorEnable;


/**
 *  启动模块监控开关，默认开启
 */
@property (nonatomic,assign) BOOL launchMonitorEnable;


/**
 *  内存模块监控开关，默认开启
 */
@property (nonatomic,assign) BOOL memMonitorEnable;


/**
 *  OOM模块监控开关，默认开启
 */
@property (nonatomic,assign) BOOL oomMonitorEnable;


/**
 *  网络模块监控开关，默认开启
 */
@property (nonatomic,assign) BOOL networkEnable;

/**
 *集成测试。
 */
+ (BOOL)handleUrl:(NSURL *)url;


@end

NS_ASSUME_NONNULL_END
