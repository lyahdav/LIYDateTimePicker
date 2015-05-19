#import <CupertinoYankee/NSDate+CupertinoYankee.h>
#import "LIYMockEventStore.h"
#import "Kiwi.h"

@implementation LIYMockEventStore

+ (LIYMockEventStore *)mockEventStore {
    return [LIYMockEventStore new];
}

+ (LIYMockEventStore *)mockEventStoreWithAllDayEventAt:(NSDate *)date {
    LIYMockEventStore *mockEventStore = [self mockEventStore];
    [mockEventStore addAllDayEventAtDate:date];
    return mockEventStore;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.events = [NSMutableArray array];
    }
    return self;
}

- (EKEvent *)addAllDayEventAtDate:(NSDate *)date {
    return [self addEventWithStartDate:[date beginningOfDay] endDate:[date endOfDay] isAllDay:YES];
}

- (EKEvent *)addNonAllDayEventAtDate:(NSDate *)date {
    return [self addNonAllDayEventAtDate:date endDate:[date dateByAddingTimeInterval:60*60]];
}

- (EKEvent *)addNonAllDayEventAtDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    return [self addEventWithStartDate:startDate endDate:endDate isAllDay:NO];
}

- (EKEvent *)addEventWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate isAllDay:(BOOL)isAllDay {
    EKEvent *event = [EKEvent nullMock];
    [event stub:@selector(isAllDay) andReturn:theValue(isAllDay)];
    [event stub:@selector(startDate) andReturn:startDate];
    [event stub:@selector(endDate) andReturn:endDate];
    [event stub:@selector(title) andReturn:@"Some Event"];
    [self.events addObject:event];
    return event;
}

- (NSArray *)eventsMatchingPredicate:(NSPredicate *)predicate {
    return self.events;
}

- (void)requestAccessToEntityType:(EKEntityType)entityType completion:(EKEventStoreRequestAccessCompletionHandler)completion {
    completion(YES, nil);
}

@end
