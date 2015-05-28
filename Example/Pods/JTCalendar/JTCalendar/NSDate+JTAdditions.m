//
//  NSDate+JTAdditions.m
//  Pods
//
//  Created by kriser gellci on 5/27/15.
//
//

#import "NSDate+JTAdditions.h"

@implementation NSDate (JTAdditions)

- (NSDate *)jt_firstDayOfTheMonth {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:self];
    [comp setDay:1];
    return [gregorian dateFromComponents:comp];
}

- (NSDate *)jt_nextMonthWithCalendar:(NSCalendar *)calendar {
    NSDateComponents *monthComponent = [NSDateComponents new];
    monthComponent.month = 1;
    return [calendar dateByAddingComponents:monthComponent toDate:self options:0];
}

- (NSDate *)jt_previousMonthWithCalendar:(NSCalendar *)calendar {
    NSDateComponents *monthComponent = [NSDateComponents new];
    monthComponent.month = -1;
    return [calendar dateByAddingComponents:monthComponent toDate:self options:0];
}

@end
