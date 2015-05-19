#import <Foundation/Foundation.h>

@class EKEventStore;

@interface LIYCalendarService : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, strong, readonly) EKEventStore *eventStore;

- (void)eventsForDate:(NSDate *)date calendars:(NSArray *)calendars completion:(void (^)(NSArray *nonAllDayEvents, NSArray *allDayEvents))completionBlock;
- (void)reset;

@end