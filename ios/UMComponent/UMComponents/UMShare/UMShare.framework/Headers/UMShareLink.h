//
//  UMShareLink.h
//  UMShare
//
//  Created by zhangjunhua on 2020/12/22.
//  Copyright © 2020 UMeng. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
extern NSString* const UMShareLinkErrorDomain;
typedef void (^UMSocialTrackcodeCompletionHandler)(id __nullable result,NSError* __nullable error);
@interface UMShareLink : NSObject

+(void)trackcode:(NSString*)appKey
             url:(NSString* )url
             umid:(NSString*)umid
             uid:(nullable NSString*)uid
        userInfo:(nullable NSDictionary*)userInfo
completionHandler:(nullable UMSocialTrackcodeCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
