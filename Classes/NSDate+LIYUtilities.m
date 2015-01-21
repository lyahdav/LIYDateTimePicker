#import "NSDate+LIYUtilities.h"

@implementation NSDate (LIYUtilities)

- (NSDate *)dateAtHour:(NSUInteger)hour minute:(NSUInteger)minute {
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self];
    dateComponents.hour = hour;
    dateComponents.minute = minute;
    return [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
}

- (BOOL)dateIsToday {
    return [self isSameDayAsDate:[NSDate date]];
}

- (BOOL)isSameDayAsDate:(NSDate *)date {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date];
    NSDate *otherDateWithoutTime = [cal dateFromComponents:components];
    components = [cal components:(NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:self];
    NSDate *thisDateWithoutTime = [cal dateFromComponents:components];
    
    return [otherDateWithoutTime isEqualToDate:thisDateWithoutTime];
}

@end
