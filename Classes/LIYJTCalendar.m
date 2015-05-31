#import "LIYJTCalendar.h"

@implementation LIYJTCalendar

- (void)reloadAppearance {
    [super reloadAppearance];
    if (self.reloadAppearanceBlock) {
        self.reloadAppearanceBlock(self);
    }
}

- (UIGestureRecognizerState)panGestureState {
    return (UIGestureRecognizerState)[[self.contentView valueForKeyPath:@"weekMonthPanGesture.state"] integerValue];
}

@end
