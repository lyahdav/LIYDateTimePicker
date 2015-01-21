#import <Foundation/Foundation.h>

@interface NSDate (LIYUtilities)

- (NSDate *)dateAtHour:(NSUInteger)hour minute:(NSUInteger)minute;
- (BOOL)dateIsToday;
- (BOOL)isSameDayAsDate:(NSDate *)date;

@end

