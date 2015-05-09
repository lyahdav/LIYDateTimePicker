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
    EKEvent *event = [EKEvent nullMock];
    [event stub:@selector(isAllDay) andReturn:theValue(YES)];
    [event stub:@selector(startDate) andReturn:[date beginningOfDay]];
    [event stub:@selector(endDate) andReturn:[date endOfDay]];
    [self.events addObject:event];
    return event;
}

- (EKEvent *)addNonAllDayEventAtDate:(NSDate *)date {
    EKEvent *event = [EKEvent nullMock];
    [event stub:@selector(isAllDay) andReturn:theValue(NO)];
    [event stub:@selector(startDate) andReturn:date];
    [event stub:@selector(endDate) andReturn:[date dateByAddingTimeInterval:60*60]];
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
