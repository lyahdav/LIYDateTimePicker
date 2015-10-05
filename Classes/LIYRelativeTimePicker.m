#import "LIYRelativeTimePicker.h"
#import "ALView+PureLayout.h"

NSString *const LIYUserDefaultsKey_PreviousDate = @"LIYUserDefaultsKey_PreviousDate";

@implementation LIYRelativeTimePicker

#pragma mark - class methods

+ (instancetype)timePickerInView:(UIView *)superview withBackgroundColor:(UIColor *)backgroundColor userDefaults:(NSUserDefaults *)userDefaults showPreviousDateButton:(BOOL)showPreviousDateButton relativeButtonTappedBlock:(void (^)(NSInteger))relativeButtonTappedBlock previousDateButtonTappedBlock:(void (^)(NSDate *))previousDateButtonTappedBlock {
    LIYRelativeTimePicker *timePicker = [LIYRelativeTimePicker new];
    timePicker.backgroundColor = backgroundColor;
    timePicker.userDefaults = userDefaults;
    timePicker.relativeButtonTappedBlock = relativeButtonTappedBlock;
    timePicker.previousDateButtonTappedBlock = previousDateButtonTappedBlock;
    [timePicker addButtonsWithPreviousDateButton:showPreviousDateButton];
    [superview addSubview:timePicker];
    [timePicker positionButtons];
    return timePicker;
}

#pragma mark - convenience

- (void)addButtonsWithPreviousDateButton:(BOOL)showPreviousDateButton {
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

    if (showPreviousDateButton) {
        [self addPreviousDateButton];
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
    self.relativeButtonTappedBlock(minutes);
}

- (void)addPreviousDateButton {
    NSDate *previousDate = [self.userDefaults objectForKey:LIYUserDefaultsKey_PreviousDate];
    if (previousDate != nil) {
        NSString *title = [self previousDateTitleFromDate:previousDate];
        UIButton *button = [self previousDateButtonWithTitle:title];
        [self addSubview:button];
    }
}

- (NSString *)previousDateTitleFromDate:(NSDate *)date {
    static NSDateFormatter* dateFormatter = nil;
    if (!dateFormatter) {
            dateFormatter = [NSDateFormatter new];
            [dateFormatter setDateStyle:NSDateFormatterShortStyle];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
        }
    NSString *title = [dateFormatter stringFromDate:date];
    return title;
}

- (UIButton *)previousDateButtonWithTitle:(NSString *)title {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:10];
    button.backgroundColor = self.backgroundColor;
    button.accessibilityIdentifier = title;
    [button addTarget:self action:@selector(previousDateButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    button.accessibilityLabel = @"PreviousTime";
    return button;
}

- (void)previousDateButtonTapped:(UIButton *)sender {
    NSDate *previousDate = [self.userDefaults objectForKey:LIYUserDefaultsKey_PreviousDate];
    self.previousDateButtonTappedBlock(previousDate);
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