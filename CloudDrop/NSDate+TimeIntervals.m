//
//  NSDate+TimeIntervals.m
//  CloudDrops
//
//  Created by James Rutherford on 2012-08-22.
//  Copyright (c) 2012 Malaspina University-College. All rights reserved.
//

#import "NSDate+TimeIntervals.h"

@implementation NSDate (TimeIntervals)

+(NSNumber*) LongTimeIntervalSince1970 {
    long long integerSeconds = round([[NSDate date] timeIntervalSince1970]);
    return [NSNumber numberWithLongLong:integerSeconds];
}

@end
