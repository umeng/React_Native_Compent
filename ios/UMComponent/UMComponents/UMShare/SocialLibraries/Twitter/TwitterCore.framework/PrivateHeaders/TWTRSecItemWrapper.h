//
//  TWTRSecItemWrapper.h
//  TwitterCore
//
//  Created by Rajul Arora on 10/4/17.
//  Copyright © 2017 Twitter Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * SecItem methods are wrapped so they can be mocked in unit tests using OCMock because the behaviour of
 * these methods is inconsistent in a testing environment.
 */
@interface TWTRSecItemWrapper : NSObject

/**
 * Calls SecItemAdd()
 */
+ (OSStatus)secItemAdd:(CFDictionaryRef)attributes withResult:(CFTypeRef * __nullable CF_RETURNS_RETAINED)result;

/**
 * Calls SecItemDelegate()
 */
+ (OSStatus)secItemDelete:(CFDictionaryRef)query;

/**
 * Calls SecItemCopyMatching()
 */
+ (OSStatus)secItemCopyMatching:(CFDictionaryRef)query withResult:(CFTypeRef * __nullable CF_RETURNS_RETAINED)result;

@end

NS_ASSUME_NONNULL_END
