#import <Foundation/Foundation.h>
#import "LIYDateTimePickerViewController.h"

@protocol LIYDateTimePickerDelegate;

@interface LIYFakeTimePickerDelegate : NSObject<LIYDateTimePickerDelegate>

@property (nonatomic, readonly) NSDate *lastSelectedDate;

@end

@interface LIYFakeUserDefaults : NSUserDefaults

@property (nonatomic, strong) NSMutableDictionary *data;

@end

