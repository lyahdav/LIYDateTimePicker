#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

@interface LIYMockEventStore : EKEventStore

+ (LIYMockEventStore *)mockEventStore;
+ (LIYMockEventStore *)mockEventStoreWithAllDayEventAt:(NSDate *)date;

@property (nonatomic, strong) NSMutableArray *events;

- (EKEvent *)addAllDayEventAtDate:(NSDate *)date;
- (EKEvent *)addNonAllDayEventAtDate:(NSDate *)date;
- (EKEvent *)addNonAllDayEventAtDate:(NSDate *)startDate endDate:(NSDate *)endDate;

@end

