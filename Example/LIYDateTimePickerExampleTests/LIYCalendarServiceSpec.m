#import "Kiwi.h"
#import "LIYCalendarService.h"
#import "LIYSpecHelper.h"
#import "LIYMockEventStore.h"
#import "NSDate+LIYUtilities.h"

SPEC_BEGIN(LIYCalendarServiceSpec)
    describe(@"LIYCalendarService", ^{
        beforeEach(^{
            [[LIYCalendarService sharedInstance] reset];
        });

        it(@"separates all day events from non all day events", ^{
            // mock event store
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

        describe(@"calendars:haveEventsOnDate:", ^{
            it(@"returns yes on a date with an event", ^{
                // mock event store with an event
                LIYMockEventStore *mockEventStore = [LIYMockEventStore mockEventStore];
                NSDate *someDate = [NSDate liy_dateFromString:@"5/3/15, 11:45 PM"];
                [mockEventStore addNonAllDayEventAtDate:someDate endDate:[someDate dateByAddingTimeInterval:3600]];
                [EKEventStore stub:@selector(new) andReturn:mockEventStore];

                EKCalendar *calendar = [EKCalendar nullMock];
                BOOL result = [[LIYCalendarService sharedInstance] calendars:@[calendar] haveEventsOnDate:someDate];
                [[theValue(result) should] equal:theValue(YES)];
            });

            it(@"returns no on a date without any events", ^{
                // mock event store without an event
                LIYMockEventStore *mockEventStore = [LIYMockEventStore mockEventStore];
                [EKEventStore stub:@selector(new) andReturn:mockEventStore];

                EKCalendar *calendar = [EKCalendar nullMock];
                BOOL result = [[LIYCalendarService sharedInstance] calendars:@[calendar] haveEventsOnDate:[NSDate date]];
                [[theValue(result) should] equal:theValue(NO)];
            });
        });
    });
SPEC_END