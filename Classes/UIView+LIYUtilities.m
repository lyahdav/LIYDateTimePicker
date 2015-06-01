#import "UIView+LIYUtilities.h"
#import "PureLayout.h"

@implementation UIView (LIYUtilities)

- (void)liy_pinBelowView:(UIView *)otherView {
    [self autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [self autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:otherView];
}

@end