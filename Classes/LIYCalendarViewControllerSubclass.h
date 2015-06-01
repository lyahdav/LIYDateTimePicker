#import "LIYCalendarViewController.h"

// protected members as per http://bootstragram.com/blog/simulating-protected-modifier-with-objective-c/

@interface LIYCalendarViewController ()

@property (nonatomic, strong) NSArray *allDayEvents;

- (void)commonInit;
- (CGFloat)hourAtYCoordinate:(CGFloat)y;
- (void)setSelectedDateWithoutDayPicker:(NSDate *)selectedDateTime;
- (void)scrollToTimeByFactor:(CGFloat)timeFactor;
- (void)setupCalendarBottomConstraint;
- (void)setupViews;

@end
