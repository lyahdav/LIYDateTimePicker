#import "Kiwi.h"
#import "MSEventCell.h"
#import <EventKit/EventKit.h>
#import "NSDate+LIYUtilities.h"
#import "NSDate+CupertinoYankee.h"

@interface MSEventCell (LIYPrivateMethodsExposedForSpec)
- (NSInteger)eventDurationMinutesInSelectedDay;
@end

SPEC_BEGIN(MSEventCellSpec)

describe(@"MSEventCell", ^{
    
    context(@"given an event that starts at 11:30pm today and goes to 12:15am the next day", ^{
        __block EKEvent *event;

        beforeEach(^{
            event = [EKEvent mock];
            NSDate *startDate = [[NSDate date] dateAtHour:23 minute:30];
            [event stub:@selector(startDate) andReturn:startDate];
            [event stub:@selector(endDate) andReturn:[startDate dateByAddingTimeInterval:45*60]];
            [event stub:@selector(title) andReturn:@"some event"];
        });

        it(@"returns the event duration in the current day when today is selected", ^{
            MSEventCell *eventCell = [MSEventCell new];
            eventCell.selectedDate = [NSDate date];
            eventCell.event = event;
            
            [[theValue([eventCell eventDurationMinutesInSelectedDay]) should] equal:theValue(30)];
        });
        
        it(@"returns the event duration in the current day when tomorrow is selected", ^{
            MSEventCell *eventCell = [MSEventCell new];
            NSDate *tomorrow = [NSDate dateWithTimeIntervalSinceNow:60*60*24]; // TODO: don't use magic number, could fail on DST, etc.
            eventCell.selectedDate = tomorrow;
            eventCell.event = event;

            [[theValue([eventCell eventDurationMinutesInSelectedDay]) should] equal:theValue(15)];
        });
        
    });
    
    context(@"given a 15 minute event tomorrow when I look at tomorrow", ^{
        __block EKEvent *event;
        __block NSDate *tomorrowMidnight;
        
        beforeEach(^{
            event = [EKEvent mock];
            tomorrowMidnight = [[[NSDate date] endOfDay] dateByAddingTimeInterval:1];
            NSDate *startDate = [tomorrowMidnight dateAtHour:1 minute:0];
            [event stub:@selector(startDate) andReturn:startDate];
            [event stub:@selector(endDate) andReturn:[startDate dateByAddingTimeInterval:15*60]];
            [event stub:@selector(title) andReturn:@"some event"];
        });
        
        it(@"returns the correct event duration", ^{
            MSEventCell *eventCell = [MSEventCell new];
            eventCell.selectedDate = tomorrowMidnight;
            eventCell.event = event;
            
            [[theValue([eventCell eventDurationMinutesInSelectedDay]) should] equal:theValue(15)];
        });
    });
});

SPEC_END
