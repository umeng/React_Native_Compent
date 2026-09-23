//
//  RNUMAPMConfig.h
//  umeng-react-native
//
//  友盟 APM 原生初始化配置对象。
//  命名加 RN 前缀以区别于友盟 APM SDK 自带的 UMAPMConfig 类
//  （ObjC 无命名空间，同名会与 SDK 类冲突）。
//

#import <Foundation/Foundation.h>

@interface RNUMAPMConfig : NSObject

/// 崩溃与卡顿监控（默认 YES）；对应 iOS SDK 单一开关 crashAndBlockMonitorEnable
@property (nonatomic, assign) BOOL crashAndBlockMonitorEnable;
/// 启动监控（默认 YES）
@property (nonatomic, assign) BOOL launchMonitorEnable;
/// 内存监控（默认 NO）
@property (nonatomic, assign) BOOL memMonitorEnable;
/// 网络监控（默认 NO）
@property (nonatomic, assign) BOOL networkEnable;
/// 页面监控（默认 YES）
@property (nonatomic, assign) BOOL pageMonitorEnable;
/// 日志回捞（默认 YES）
@property (nonatomic, assign) BOOL logCollectEnable;
/// H5 / JSBridge 监控（默认 NO）
@property (nonatomic, assign) BOOL javaScriptBridgeEnable;
/// 自定义 App 版本号（nil/空时不调用 setAppVersion）
@property (nonatomic, copy) NSString *appVersion;
/// 构建版本号
@property (nonatomic, copy) NSString *buildVersion;

@end
