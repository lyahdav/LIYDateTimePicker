#import "Kiwi.h"
#import "LIYDateTimePickerViewController.h"
#import "NSDate+LIYUtilities.h"
#import "LIYSpecHelper.h"
#import "UIView+LIYSpecAdditions.h"
#import "LIYCalendarService.h"
#import <CupertinoYankee/NSDate+CupertinoYankee.h>
#import "LIYJTCalendar.h"

SPEC_BEGIN(LIYDateTimePickerViewControllerSpec)
    describe(@"LIYDateTimePickerViewController", ^{

        beforeEach(^{
            [[LIYCalendarService sharedInstance] reset];
            [EKEventStore stub:@selector(new) andReturn:[EKEventStore nullMock]];
        });

        it(@"shows the day picker by default", ^{
            LIYDateTimePickerViewController *pickerViewController = [LIYDateTimePickerViewController new];
            [[theValue(pickerViewController.showDayPicker) should] equal:theValue(YES)];
        });

        it(@"initializes the day picker to the given date", ^{
            NSDate *someDate = [NSDate liy_dateFromString:@"5/21/15, 12:00 PM"];
            LIYDateTimePickerViewController *pickerViewController = [LIYDateTimePickerViewController timePickerForDate:someDate delegate:nil];
            [pickerViewController view];
            [[pickerViewController.dayPicker.currentDateSelected should] equal:someDate];
            [[pickerViewController.dayPicker.currentDate should] equal:someDate];
        });

        it(@"sets the selected date to the nearest valid date", ^{
            [LIYSpecHelper stubCurrentDateAs:@"5/21/15, 12:32 PM"];
            LIYDateTimePickerViewController *pickerViewController = [LIYDateTimePickerViewController new];
            [[pickerViewController.selectedDate should] equal:[NSDate liy_dateFromString:@"5/21/15, 12:45 PM"]];
        });

        it(@"allows hiding the day picker", ^{
            [LIYSpecHelper stubCurrentDateAs:@"5/21/15, 12:00 PM"];
            LIYDateTimePickerViewController *pickerViewController = [LIYSpecHelper visiblePickerViewController];
            pickerViewController.showDayPicker = NO;
            [[[pickerViewController.view liy_specsFindLabelWithText:@"TUE"] should] beNil];
        });

        it(@"allows setting 5 minute scroll interval", ^{
            [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 12:00 PM"];

            LIYDateTimePickerViewController *pickerViewController = [LIYSpecHelper visiblePickerViewController];
            pickerViewController.scrollIntervalMinutes = 5;
            NSDate *nextIncrementDate = [NSDate liy_dateFromString:@"5/3/15, 12:05 PM"];
            [pickerViewController scrollToTime:nextIncrementDate];

            [[pickerViewController.selectedDate should] equal:nextIncrementDate];
        });

        it(@"defaults to 15 minute scroll interval", ^{
            LIYDateTimePickerViewController *pickerViewController = [LIYDateTimePickerViewController new];
            [[theValue(pickerViewController.scrollIntervalMinutes) should] equal:theValue(15)];
        });

        it(@"allows hiding of the relative time picker", ^{
            LIYDateTimePickerViewController *pickerViewController = [LIYSpecHelper visiblePickerViewController];
            pickerViewController.showRelativeTimePicker = NO;
            [[[pickerViewController.view liy_specsFindLabelWithText:@"15m"] should] beNil];
        });

        context(@"at 12:00am", ^{
            __block LIYDateTimePickerViewController *pickerViewController;

            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 12:00 AM"];
                pickerViewController = [LIYSpecHelper visiblePickerViewController];
            });
            
            it(@"updates the insets when switching from week to month", ^{
                [pickerViewController switchToMonthPicker];
                [LIYSpecHelper tickRunLoop];

                UIEdgeInsets insets = pickerViewController.collectionView.contentInset;
                CGFloat topInsetOnIPhone6 = 131.5; // TODO: make this work on other devices
                [[theValue(insets.top) should] equal:topInsetOnIPhone6 withDelta:0.1];
            });
            
            it(@"doesn't update the selected date when switching from week to month view and in calendar mode", ^{
                pickerViewController.allowTimeSelection = NO;
                
                [[pickerViewController shouldNot] receive:@selector(setSelectedDate:)];
                [pickerViewController switchToMonthPicker];
                [LIYSpecHelper tickRunLoop];
            });
        });
        
        context(@"at 3:00am", ^{
            __block LIYDateTimePickerViewController *pickerViewController;
            
            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 3:00 AM"];
                pickerViewController = [LIYSpecHelper visiblePickerViewController];
            });
            
            it(@"updates the selected date when switching from week to month", ^{
                [pickerViewController switchToMonthPicker];
                [LIYSpecHelper tickRunLoop];
                
                [[pickerViewController.selectedDate should] equal:[NSDate liy_dateFromString:@"5/3/15, 3:00 AM"]];
            });
        });
        
        context(@"at 1:00am", ^{
            __block LIYDateTimePickerViewController *pickerViewController;

            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 1:00 AM"];
                pickerViewController = [LIYSpecHelper visiblePickerViewController];
            });

            it(@"scrolls to the correct time initially", ^{
                [[pickerViewController.selectedDate should] equal:[NSDate liy_dateFromString:@"5/3/15, 1:00 AM"]];
            });
        });

        context(@"at noon", ^{
            __block LIYDateTimePickerViewController *pickerViewController;

            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 12:00 PM"];
                pickerViewController = [LIYSpecHelper visiblePickerViewController];
            });

            it(@"allows scrolling to the beginning of the day", ^{
                NSDate *beginningOfDayDate = [NSDate liy_dateFromString:@"5/3/15, 12:00 AM"];

                [pickerViewController scrollToTime:beginningOfDayDate];
                [[expectFutureValue(pickerViewController.selectedDate) shouldEventually] equal:beginningOfDayDate];
            });

            it(@"allows scrolling to the end of the day", ^{
                NSDate *endOfDayDate = [NSDate liy_dateFromString:@"5/3/15, 11:45 PM"];
                [pickerViewController scrollToTime:endOfDayDate];
                [[expectFutureValue(pickerViewController.selectedDate) shouldEventually] equal:endOfDayDate];
            });

            it(@"allows scrolling to the end of the day when the device is landscape", ^{
                [LIYSpecHelper rotateDeviceToOrientation:UIInterfaceOrientationLandscapeLeft];
                NSDate *endOfDayDate = [NSDate liy_dateFromString:@"5/3/15, 11:45 PM"];
                [pickerViewController scrollToTime:endOfDayDate];
                [[expectFutureValue(pickerViewController.selectedDate) shouldEventually] equal:endOfDayDate];
            });

            it(@"keeps the same date when rotating the device", ^{
                NSDate *endOfDayDate = [NSDate liy_dateFromString:@"5/3/15, 11:45 PM"];
                [pickerViewController scrollToTime:endOfDayDate];
                [LIYSpecHelper tickRunLoop];

                [LIYSpecHelper rotateDeviceToOrientation:UIInterfaceOrientationLandscapeLeft];
                [LIYSpecHelper rotateDeviceToOrientation:UIInterfaceOrientationPortrait];

                [[expectFutureValue(pickerViewController.selectedDate) shouldEventually] equal:endOfDayDate];
            });
        });

        context(@"at 1:05pm", ^{
            __block LIYDateTimePickerViewController *pickerViewController;

            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 1:05 PM"];
                pickerViewController = [LIYDateTimePickerViewController timePickerForDate:[NSDate date] delegate:nil];
            });

            it(@"sets 1:15pm as the selected date", ^{
                [[pickerViewController.selectedDate should] equal:[NSDate liy_dateFromString:@"5/3/15, 1:15 PM"]];
            });

            it(@"displays 1:15pm as the selected time", ^{
                [[[pickerViewController.view liy_specsFindLabelWithText:@"1:15 PM"] shouldNot] beNil];
            });
        });
        
        context(@"at 11:45pm when in month view", ^{
            __block LIYDateTimePickerViewController *pickerViewController;
            
            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 11:45 PM"];
                pickerViewController = [LIYSpecHelper visiblePickerViewController];
                [pickerViewController switchToMonthPicker];
                [LIYSpecHelper tickRunLoop];
            });
            
            it(@"keeps the selected date when switching to week view", ^{
                [pickerViewController switchToWeekPicker];
                [LIYSpecHelper tickRunLoop];
                [[pickerViewController.selectedDate should] equal:[NSDate liy_dateFromString:@"5/3/15, 11:45 PM"]];
            });

            it(@"keeps the selected date when panning to week view", ^{
                // simulate gesture beginning
                [pickerViewController.dayPicker stub:@selector(panGestureState) andReturn:theValue(UIGestureRecognizerStateChanged)];
                CGPoint initialContentOffset = pickerViewController.collectionView.contentOffset;
                [pickerViewController.collectionView setContentOffset:CGPointMake(0, initialContentOffset.y - 50) animated:NO];

                // simulate gesture ending
                [pickerViewController.dayPicker stub:@selector(panGestureState) andReturn:theValue(UIGestureRecognizerStatePossible)];
                initialContentOffset = pickerViewController.collectionView.contentOffset;
                [pickerViewController.collectionView setContentOffset:CGPointMake(0, initialContentOffset.y - 50) animated:NO];
                [pickerViewController.dayPicker reloadAppearance];

                [[pickerViewController.selectedDate should] equal:[NSDate liy_dateFromString:@"5/3/15, 11:45 PM"]];
            });
        });

        context(@"when scrolling to the end of the day", ^{
            __block LIYDateTimePickerViewController *pickerViewController;

            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 1:05 PM"];
                pickerViewController = [LIYSpecHelper visiblePickerViewController];
                [pickerViewController.collectionView setContentOffset:CGPointMake(0, 10000) animated:NO];
            });

            it(@"doesn't continue advancing the selected date if you keep scrolling at the end of the day", ^{
                [pickerViewController.collectionView setContentOffset:CGPointMake(0, 10001) animated:NO];
                [[pickerViewController.selectedDate should] equal:[NSDate liy_dateFromString:@"5/4/15, 12:00 AM"]];
            });

            it(@"stays on the same day in the day picker", ^{
                [[[pickerViewController.dayPicker.currentDateSelected beginningOfDay] should] equal:[NSDate liy_dateFromString:@"5/3/15, 12:00 AM"]];
            });
        });

        context(@"when switching from a day without an all day event to a day with an all day event and then going to midnight", ^{
            __block LIYDateTimePickerViewController *pickerViewController;
            __block NSDate *tomorrowDate;

            beforeEach(^{
                // create picker with all day event for tomorrow
                NSTimeInterval oneDay = 60 * 60 * 24;
                tomorrowDate = [NSDate dateWithTimeIntervalSinceNow:oneDay];
                pickerViewController = [LIYSpecHelper pickerViewControllerWithAllDayEventAtDate:tomorrowDate];

                // go to tomorrow
                pickerViewController.selectedDate = tomorrowDate;
                [pickerViewController reloadEvents];

                [LIYSpecHelper tickRunLoop];

                // scroll to 12am
                [pickerViewController scrollToTime:[tomorrowDate beginningOfDay]];

                [LIYSpecHelper tickRunLoop];
            });

            it(@"has the correct insets", ^{
                UIEdgeInsets insets = pickerViewController.collectionView.contentInset;
                CGFloat topInsetOnIPhone6 = 191.5f; // TODO: make this work on other devices
                [[theValue(insets.top) should] equal:topInsetOnIPhone6 withDelta:0.1];
            });

            it(@"is at midnight", ^{
                [[pickerViewController.selectedDate should] equal:[tomorrowDate beginningOfDay]];
            });
        });

        context(@"when showing an event on the calendar", ^{
            __block LIYDateTimePickerViewController *pickerViewController;

            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 1:05 PM"];

                // create picker with event for today
                NSDate *eventStartDate = [NSDate liy_dateFromString:@"5/3/15, 2:00 PM"];
                NSDate *eventEndDate = [NSDate liy_dateFromString:@"5/3/15, 3:00 PM"];
                pickerViewController = [LIYSpecHelper pickerViewControllerWithEventAtDate:eventStartDate endDate:eventEndDate];
                pickerViewController.showEventTimes = YES;

                [LIYSpecHelper tickRunLoop];
            });

            it(@"has the event duration", ^{
                [[[pickerViewController.view liy_specsFindLabelWithText:@"2 PM - 3 PM (1 hour)"] shouldNot] beNil];
            });
        });

        context(@"when in calendar mode", ^{
            afterEach(^{
                // TODO seems to be needed to prevent crash where view controller gets deallocated after test but scrollView still has reference to view controller and
                // calls a method on its delegate (view controller). Find a better solution.
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            });

            __block LIYDateTimePickerViewController *pickerViewController;

            context(@"towards the beginning of the day", ^{
                beforeEach(^{
                    [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 1:00 AM"];
                    pickerViewController = [LIYSpecHelper visibleCalendarViewController];
                });

                it(@"doesn't scroll", ^{
                    [[theValue(pickerViewController.collectionView.contentOffset.y) should] equal:0 withDelta:0.1];
                });
            });

            context(@"at noon", ^{
                beforeEach(^{
                    [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 12:00 PM"];
                    pickerViewController = [LIYSpecHelper visibleCalendarViewController];
                });
                it(@"scrolls to center noon", ^{
                    CGFloat contentOffsetForNoonOnIPhone6 = 349.0f; // TODO would be nice to not hard-code
                    [[theValue(pickerViewController.collectionView.contentOffset.y) should] equal:contentOffsetForNoonOnIPhone6 withDelta:0.1];
                });
            });

            context(@"towards the end of the day", ^{
                beforeEach(^{
                    [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 9:00 PM"];
                    pickerViewController = [LIYSpecHelper visibleCalendarViewController];
                });
                it(@"scrolls to the end of the day", ^{
                    UICollectionView *collectionView = pickerViewController.collectionView;
                    CGFloat maximumContentOffset = collectionView.contentSize.height - collectionView.frame.size.height;
                    [[theValue(collectionView.contentOffset.y) should] equal:maximumContentOffset withDelta:0.1];
                });
            });
        });
    });
SPEC_END