//
//  TWTRDateFormatter.h
//  TwitterKit
//
//  Created by Joey Carmello on 3/28/15.
//  Copyright (c) 2015 Twitter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TWTRDateFormatter : NSObject

/**
 *  Returns the formatted elapsed time string base on the given date.
 *
 *  Logic:
 *      - Relative timestamp for anything less than 24 hours
 *      - Abbreviated month and day format (Aug 5), and no year for anything within the current year
 *      - MM/DD/YY (10/5/14) for anything beyond the current year
 *
 *  @param date The date object to calculate elapsed time against.
 *
 *  @return Formatted string of the elapsed time from the given date.
 */
+ (NSString *)elapsedTimeStringSinceDate:(NSDate *)date;

@end
