#import "Kiwi.h"
#import "LIYDateTimePickerViewController.h"
#import "NSDate+LIYUtilities.h"
#import "LIYSpecHelper.h"
#import "UIView+LIYSpecAdditions.h"
#import <CupertinoYankee/NSDate+CupertinoYankee.h>

SPEC_BEGIN(LIYDateTimePickerViewControllerSpec)
    describe(@"LIYDateTimePickerViewController", ^{

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

        context(@"when switching from a day without an all day event to a day with an all day event and then going to midnight", ^{
            __block LIYDateTimePickerViewController *pickerViewController;
            __block NSDate *tomorrowDate;

            beforeEach(^{
                pickerViewController = [LIYSpecHelper visiblePickerViewController];

                // create picker with all day event for tomorrow
                NSTimeInterval oneDay = 60 * 60 * 24;
                tomorrowDate = [NSDate dateWithTimeIntervalSinceNow:oneDay];
                pickerViewController = [LIYSpecHelper pickerViewControllerWithAllDayEventAtDate:tomorrowDate];

                // go to tomorrow
                pickerViewController.selectedDate = tomorrowDate;
                pickerViewController.date = tomorrowDate;
                [pickerViewController reloadEvents];

                [LIYSpecHelper tickRunLoop];

                // scroll to 12am
                [pickerViewController scrollToTime:[tomorrowDate beginningOfDay]];
            });

            it(@"has the corret insets", ^{
                UIEdgeInsets insets = pickerViewController.collectionView.contentInset;
                CGFloat topInsetOnIPhone6 = 121.5; // TODO: make this work on other devices
                [[theValue(insets.top) should] equal:topInsetOnIPhone6 withDelta:0.1];
            });

            it(@"is at midnight", ^{
                [[pickerViewController.selectedDate should] equal:[tomorrowDate beginningOfDay]];
            });
        });
    });
SPEC_END