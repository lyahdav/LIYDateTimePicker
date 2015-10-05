#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

@class LIYDateTimePickerViewController;
@protocol LIYDateTimePickerDelegate;

@interface LIYSpecHelper : NSObject

+ (void)rotateDeviceToOrientation:(UIInterfaceOrientation)orientation;
+ (void)tickRunLoop;
+ (void)tickRunLoopForSeconds:(NSTimeInterval)seconds;
+ (LIYDateTimePickerViewController *)visibleCalendarViewController;
+ (LIYDateTimePickerViewController *)visiblePickerViewController;
+ (LIYDateTimePickerViewController *)pickerViewControllerWithAllDayEventAtDate:(NSDate *)date;
+ (LIYDateTimePickerViewController *)pickerViewControllerWithEventAtDate:(NSDate *)startDate endDate:(NSDate *)endDate;
+ (LIYDateTimePickerViewController *)pickerViewControllerWithPreviousDateForDate:(NSDate *)date delegate:(id <LIYDateTimePickerDelegate>)delegate userDefaults:(NSUserDefaults *)userDefault;

//! @param dateString in format @"5/3/15, 12:00 AM"
+ (void)stubCurrentDateAs:(NSString *)dateString;

@end