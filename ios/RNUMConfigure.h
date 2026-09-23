//
//  RNUMConfigure.h
//  umeng-react-native
//
//  友盟 SDK 初始化配置
//

#import <Foundation/Foundation.h>
#import <UMCommon/UMCommon.h>

@interface RNUMConfigure : NSObject

+ (void)initWithAppkey:(NSString *)appkey channel:(NSString *)channel;

@end
