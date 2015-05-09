#import "Kiwi.h"
#import "LIYCalendarService.h"
#import "LIYSpecHelper.h"
#import "LIYMockEventStore.h"

SPEC_BEGIN(LIYCalendarServiceSpec)
    describe(@"LIYCalendarService", ^{

        it(@"separates all day events from non all day events", ^{
            LIYMockEventStore *mockEventStore = [LIYMockEventStore mockEventStore];
            id mockAllDayEvent = [mockEventStore addAllDayEventAtDate:[NSDate date]];
            id mockNonAllDayEvent = [mockEventStore addNonAllDayEventAtDate:[NSDate date]];
            [EKEventStore stub:@selector(new) andReturn:mockEventStore];

            __block NSArray *capturedNonAllDayEvents = nil;
            __block NSArray *capturedAllDayEvents = nil;

            [[LIYCalendarService sharedInstance] eventsForDate:[NSDate date] calendars:nil completion:^(NSArray *nonAllDayEvents, NSArray *allDayEvents) {
                capturedNonAllDayEvents = nonAllDayEvents;
                capturedAllDayEvents = allDayEvents;
            }];
            
            [[capturedNonAllDayEvents should] equal:@[mockNonAllDayEvent]];
            [[capturedAllDayEvents should] equal:@[mockAllDayEvent]];
        });

    });
SPEC_END