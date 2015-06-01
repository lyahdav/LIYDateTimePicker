#import "Kiwi.h"
#import "LIYCalendarViewController.h"
#import "LIYSpecHelper.h"

SPEC_BEGIN(LIYCalendarViewControllerSpec)
    describe(@"LIYCalendarViewController", ^{

        __block LIYCalendarViewController *calendarViewController;

        afterEach(^{
            // TODO seems to be needed to prevent crash where view controller gets deallocated after test but scrollView still has reference to view controller and
            // calls a method on its delegate (view controller). Find a better solution.
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        });

        context(@"at 12:00am", ^{

            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 12:00 AM"];
                calendarViewController = [LIYSpecHelper visibleCalendarViewController];
            });

            it(@"doesn't update the selected date when switching from week to month view and in calendar mode", ^{
                [[calendarViewController shouldNot] receive:@selector(setSelectedDate:)];
                [calendarViewController switchToMonthPicker];
                [LIYSpecHelper tickRunLoop];
            });
        });

        context(@"towards the beginning of the day", ^{
            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 1:00 AM"];
                calendarViewController = [LIYSpecHelper visibleCalendarViewController];
            });

            it(@"doesn't scroll", ^{
                [[theValue(calendarViewController.collectionView.contentOffset.y) should] equal:0 withDelta:0.1];
            });
        });

        context(@"at noon", ^{
            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 12:00 PM"];
                calendarViewController = [LIYSpecHelper visibleCalendarViewController];
            });
            it(@"scrolls to center noon", ^{
                CGFloat contentOffsetForNoonOnIPhone6 = 349.0f; // TODO would be nice to not hard-code
                [[theValue(calendarViewController.collectionView.contentOffset.y) should] equal:contentOffsetForNoonOnIPhone6 withDelta:0.1];
            });
        });

        context(@"towards the end of the day", ^{
            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 9:00 PM"];
                calendarViewController = [LIYSpecHelper visibleCalendarViewController];
            });
            it(@"scrolls to the end of the day", ^{
                UICollectionView *collectionView = calendarViewController.collectionView;
                CGFloat maximumContentOffset = collectionView.contentSize.height - collectionView.frame.size.height;
                [[theValue(collectionView.contentOffset.y) should] equal:maximumContentOffset withDelta:0.1];
            });
        });
    });
SPEC_END