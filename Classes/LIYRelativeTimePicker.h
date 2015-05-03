#import <Foundation/Foundation.h>

@interface LIYRelativeTimePicker : UIView

+ (instancetype)timePickerInView:(UIView *)superview withBackgroundColor:(UIColor *)backgroundColor buttonTappedBlock:(void (^)(NSInteger))buttonTappedBlock;

@property (nonatomic, copy) void (^buttonTappedBlock)(NSInteger);

@end