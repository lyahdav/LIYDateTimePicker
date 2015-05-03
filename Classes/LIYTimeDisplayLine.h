#import <Foundation/Foundation.h>

@interface LIYTimeDisplayLine : UIView

+ (LIYTimeDisplayLine *)timeDisplayLineInView:(UIView *)view withBorderColor:(UIColor *)borderColor fontName:(NSString *)fontName initialDate:(NSDate *)initialDate;

@property (nonatomic, copy) UIColor *borderColor;

- (void)updateLabelFromDate:(NSDate *)date;

@end