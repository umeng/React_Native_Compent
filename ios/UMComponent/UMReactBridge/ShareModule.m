//
//  ShareModule.h
//  UMComponent
//
//  Created by wyq.Cloudayc on 11/09/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "ShareModule.h"
#import <UMShare/UMShare.h>
#import <UShareUI/UShareUI.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>

@implementation ShareModule

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(share:(NSString *)text icon:(NSString *)icon link:(NSString *)link title:(NSString *)title platform:(NSInteger)platform completion:(RCTResponseSenderBlock)completion)
{
  UMSocialPlatformType plf = UMSocialPlatformType_UnKnown;
  switch (platform) {
    case 0: // QQ
      plf = UMSocialPlatformType_QQ;
      break;
    case 1: // Sina
      plf = UMSocialPlatformType_Sina;
      break;
    case 2: // wechat
      plf = UMSocialPlatformType_WechatSession;
      break;
    default:
      break;
  }
  
  if (plf == UMSocialPlatformType_UnKnown) {
    if (completion) {
      completion(@[@(UMSocialPlatformType_UnKnown), @"invalid platform"]);
      return;
    }
  }
  
  UMSocialMessageObject *messageObject = [UMSocialMessageObject messageObject];
  
  if (link.length > 0) {
    UMShareWebpageObject *shareObject = [UMShareWebpageObject shareObjectWithTitle:title descr:text thumImage:icon];
    shareObject.webpageUrl = link;
    
    messageObject.shareObject = shareObject;
  } else if (icon.length > 0) {
    UMShareImageObject *shareObject = [[UMShareImageObject alloc] init];
    shareObject.thumbImage = icon;
    shareObject.shareImage = icon;
    messageObject.shareObject = shareObject;
    
    messageObject.text = text;
  } else if (text.length > 0) {
    messageObject.text = text;
  } else {
    if (completion) {
      completion(@[@(-3), @"invalid parameter"]);
      return;
    }
  }
  
  [[UMSocialManager defaultManager] shareToPlatform:plf messageObject:messageObject currentViewController:nil completion:^(id result, NSError *error) {
    if (completion) {
      if (error) {
        completion(@[@(error.code), error.localizedDescription]);
      } else {
        completion(@[@0, @"share success"]);
      }
    }
  }];

}


RCT_EXPORT_METHOD(shareboard:(NSString *)text icon:(NSString *)icon link:(NSString *)link title:(NSString *)title platform:(NSArray *)platforms completion:(RCTResponseSenderBlock)completion)
{
  [UMSocialUIManager showShareMenuViewInWindowWithPlatformSelectionBlock:^(UMSocialPlatformType platformType, NSDictionary *userInfo) {
    [self share:text icon:icon link:link title:title platform:platformType completion:completion];
  }];
}


RCT_EXPORT_METHOD(auth:(NSInteger)platform completion:(RCTResponseSenderBlock)completion)
{
  UMSocialPlatformType plf = UMSocialPlatformType_UnKnown;
  switch (platform) {
    case 0: // QQ
      plf = UMSocialPlatformType_QQ;
      break;
    case 1: // Sina
      plf = UMSocialPlatformType_Sina;
      break;
    case 2: // wechat
      plf = UMSocialPlatformType_WechatSession;
      break;
    default:
      break;
  }
  
  if (plf == UMSocialPlatformType_UnKnown) {
    if (completion) {
      completion(@[@(UMSocialPlatformType_UnKnown), @"invalid platform"]);
      return;
    }
  }
  
  [[UMSocialManager defaultManager] getUserInfoWithPlatform:plf currentViewController:nil completion:^(id result, NSError *error) {
    if (completion) {
      if (error) {
        completion(@[@(error.code), error.localizedDescription]);
      } else {
        UMSocialUserInfoResponse *authInfo = result;
        completion(@[@0, authInfo.uid]);
      }
    }
  }];
  
}
@end
