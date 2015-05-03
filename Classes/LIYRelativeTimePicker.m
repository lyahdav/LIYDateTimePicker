#import "LIYRelativeTimePicker.h"
#import "ALView+PureLayout.h"

@implementation LIYRelativeTimePicker

#pragma mark - class methods

+ (instancetype)timePickerInView:(UIView *)superview withBackgroundColor:(UIColor *)backgroundColor buttonTappedBlock:(void (^)(NSInteger))buttonTappedBlock {
    LIYRelativeTimePicker *timePicker = [LIYRelativeTimePicker new];
    timePicker.backgroundColor = backgroundColor;
    timePicker.buttonTappedBlock = buttonTappedBlock;
    [timePicker addButtons];
    [superview addSubview:timePicker];
    [timePicker positionButtons];
    return timePicker;
}

#pragma mark - convenience

- (void)addButtons {
    NSArray *relativeTimeButtonData = @[
            @{@"minutes" : @(15), @"title" : @"15m"},
            @{@"minutes" : @(60), @"title" : @"1h"},
            @{@"minutes" : @(1440), @"title" : @"1d"},
    ];
    for (NSDictionary *relativeTimeButtonInfo in relativeTimeButtonData) {
        NSInteger minutes = ((NSNumber *)relativeTimeButtonInfo[@"minutes"]).integerValue;
        NSString *title = relativeTimeButtonInfo[@"title"];
        UIButton *button = [self relativeTimeButtonWithTitle:title minutes:minutes];
        [self addSubview:button];
    }
}

- (UIButton *)relativeTimeButtonWithTitle:(NSString *)title minutes:(NSInteger)minutes {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
    [button setTitle:title forState:UIControlStateNormal];
    button.tag = minutes;
    button.backgroundColor = self.backgroundColor;
    button.accessibilityIdentifier = title;
    [button addTarget:self action:@selector(relativeTimeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)relativeTimeButtonTapped:(UIButton *)sender {
    NSInteger minutes = sender.tag;
    self.buttonTappedBlock(minutes);
}

- (void)positionButtons {
    [self autoPinEdgesToSuperviewEdgesWithInsets:ALEdgeInsetsZero];
    UIButton *previousButton = nil;
    CGFloat widthMultiplier = 1.0f / self.subviews.count;
    for (UIButton *button in self.subviews) {
        [self positionButton:button toRightOfPreviousButton:previousButton widthMultiplier:widthMultiplier];
        previousButton = button;
    }
}

- (void)positionButton:(UIButton *)button toRightOfPreviousButton:(UIButton *)previousButton widthMultiplier:(CGFloat)widthMultiplier {
    [button autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:widthMultiplier];
    [button autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [button autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    if (previousButton) {
        [button autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:previousButton];
        [self addLeftLineToButton:button];
    } else {
        [button autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    }

    [self addBottomLineToButton:button];
}

- (void)addLeftLineToButton:(UIButton *)button {
    UIView *leftLineView = [UIView new];
    leftLineView.backgroundColor = [UIColor blackColor];
    [button addSubview:leftLineView];
    [leftLineView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [leftLineView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
    [leftLineView autoSetDimension:ALDimensionWidth toSize:1.0f];
    [leftLineView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
}

- (void)addBottomLineToButton:(UIButton *)button {
    UIView *bottomLineView = [UIView new];
    bottomLineView.backgroundColor = [UIColor blackColor];
    [button addSubview:bottomLineView];
    [bottomLineView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [bottomLineView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [bottomLineView autoSetDimension:ALDimensionHeight toSize:1.0f];
    [bottomLineView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
}

@end