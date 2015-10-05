#import <Foundation/Foundation.h>

extern NSString *const LIYUserDefaultsKey_PreviousDate;

@interface LIYRelativeTimePicker : UIView

+ (instancetype)timePickerInView:(UIView *)superview withBackgroundColor:(UIColor *)backgroundColor userDefaults:(NSUserDefaults *)userDefaults showPreviousDateButton:(BOOL)showPreviousDateButton relativeButtonTappedBlock:(void (^)(NSInteger))relativeButtonTappedBlock previousDateButtonTappedBlock:(void (^)(NSDate *))previousDateButtonTappedBlock;

@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, copy) void (^relativeButtonTappedBlock)(NSInteger);
@property (nonatomic, copy) void (^previousDateButtonTappedBlock)(NSDate *);

@end