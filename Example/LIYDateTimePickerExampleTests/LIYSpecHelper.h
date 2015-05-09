#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

@class LIYDateTimePickerViewController;

@interface LIYSpecHelper : NSObject

+ (void)rotateDeviceToOrientation:(UIInterfaceOrientation)orientation;
+ (void)tickRunLoop;
+ (void)tickRunLoopForSeconds:(NSTimeInterval)seconds;
+ (LIYDateTimePickerViewController *)visiblePickerViewController;
+ (LIYDateTimePickerViewController *)pickerViewControllerWithAllDayEventAtDate:(NSDate *)date;

//! @param dateString in format @"5/3/15, 12:00 AM"
+ (void)stubCurrentDateAs:(NSString *)dateString;

@end