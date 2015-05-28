#import "JTCalendar.h"

@interface LIYJTCalendar : JTCalendar

@property (nonatomic, copy) void (^reloadAppearanceBlock)(LIYJTCalendar *calendar);
@property (nonatomic, readonly) UIGestureRecognizerState panGestureState;

@end
