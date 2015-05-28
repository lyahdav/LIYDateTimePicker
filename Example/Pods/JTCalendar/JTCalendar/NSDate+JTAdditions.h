//
//  NSDate+JTAdditions.h
//  Pods
//
//  Created by kriser gellci on 5/27/15.
//
//

#import <Foundation/Foundation.h>

@interface NSDate (JTAdditions)

- (NSDate *)jt_firstDayOfTheMonth;
- (NSDate *)jt_nextMonthWithCalendar:(NSCalendar *)calendar;
- (NSDate *)jt_previousMonthWithCalendar:(NSCalendar *)calendar;

@end
