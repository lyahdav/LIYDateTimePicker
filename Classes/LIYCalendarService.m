#import "LIYCalendarService.h"
#import <EventKit/EventKit.h>
#import <CupertinoYankee/NSDate+CupertinoYankee.h>

@interface LIYCalendarService ()

@property (nonatomic, strong, readwrite) EKEventStore *eventStore;

@end

@implementation LIYCalendarService

static LIYCalendarService *sharedInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (void)eventsForDate:(NSDate *)date calendars:(NSArray *)calendars completion:(void (^)(NSArray *nonAllDayEvents, NSArray *allDayEvents))completionBlock {
    typeof(self) __weak weakSelf = self;
    [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        typeof(self) strongSelf = weakSelf;
        [strongSelf eventsForDate:date calendars:calendars completionBlock:completionBlock granted:granted];
    }];
}

#pragma mark - properties

- (EKEventStore *)eventStore {
    if (_eventStore == nil) {
        _eventStore = [EKEventStore new];
    }
    return _eventStore;
}

#pragma mark - convenience

- (void)eventsForDate:(NSDate *)date calendars:(NSArray *)calendars completionBlock:(void (^)(NSArray *, NSArray *))completionBlock granted:(BOOL)granted {
    if (!granted) {
        return;
    }

    NSPredicate *predicate = [self.eventStore predicateForEventsWithStartDate:[date beginningOfDay]
                                                                      endDate:[date endOfDay]
                                                                    calendars:calendars];
    NSArray *events = [self.eventStore eventsMatchingPredicate:predicate];

    NSMutableArray *nonAllDayEvents;
    NSMutableArray *allDayEvents;
    [self splitEvents:events nonAllDayEvents:&nonAllDayEvents allDayEvents:&allDayEvents];

    [self callOnMainThreadIfNeeded:^{
        completionBlock(nonAllDayEvents, allDayEvents);
    }];
}

- (void)callOnMainThreadIfNeeded:(void (^)())block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

- (void)splitEvents:(NSArray *)events nonAllDayEvents:(out NSMutableArray **)nonAllDayEvents allDayEvents:(out NSMutableArray **)allDayEvents {
    (*nonAllDayEvents) = [NSMutableArray array];
    (*allDayEvents) = [NSMutableArray array];
    for (EKEvent *event in events) {
        if (event.isAllDay) {
            [*allDayEvents addObject:event];
        } else {
            [*nonAllDayEvents addObject:event];
        }
    }
}

@end