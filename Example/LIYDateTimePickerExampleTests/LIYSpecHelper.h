#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

@class LIYCalendarViewController;
@class LIYDateTimePickerViewController;

@interface LIYSpecHelper : NSObject

+ (void)rotateDeviceToOrientation:(UIInterfaceOrientation)orientation;
+ (void)tickRunLoop;
+ (void)tickRunLoopForSeconds:(NSTimeInterval)seconds;
+ (LIYCalendarViewController *)visibleCalendarViewController;
+ (LIYDateTimePickerViewController *)visiblePickerViewController;
+ (LIYDateTimePickerViewController *)pickerViewControllerWithAllDayEventAtDate:(NSDate *)date;
+ (LIYDateTimePickerViewController *)pickerViewControllerWithEventAtDate:(NSDate *)startDate endDate:(NSDate *)endDate;

//! @param dateString in format @"5/3/15, 12:00 AM"
+ (void)stubCurrentDateAs:(NSString *)dateString;

@end