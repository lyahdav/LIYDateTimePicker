#import <Foundation/Foundation.h>
#import "LIYCalendarViewController.h"

@protocol LIYDateTimePickerDelegate <NSObject>

@optional

- (void)dateTimePicker:(LIYDateTimePickerViewController *)dateTimePickerViewController didSelectDate:(NSDate *)selectedDate;

@end

@interface LIYDateTimePickerViewController : LIYCalendarViewController

+ (instancetype)timePickerForDate:(NSDate *)date delegate:(id <LIYDateTimePickerDelegate>)delegate;

@property (nonatomic, assign) BOOL showCancelButton;
@property (nonatomic, assign) BOOL showRelativeTimePicker;
@property (nonatomic, assign) BOOL showDateInDayColumnHeader;
@property (nonatomic, weak) id<LIYDateTimePickerDelegate> delegate;

@end