#import <UIColor-HexString/UIColor+HexString.h>
#import "LIYTimeDisplayLine.h"
#import "PureLayout.h"

const NSInteger LIYTimeSelectorHeight = 30;
const NSInteger LIYTimeSelectorBubbleWidth = 120;

@interface LIYTimeDisplayLine ()

@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation LIYTimeDisplayLine

#pragma mark - class methods

+ (LIYTimeDisplayLine *)timeDisplayLineInView:(UIView *)view withBorderColor:(UIColor *)borderColor fontName:(NSString *)fontName initialDate:(NSDate *)initialDate {
    LIYTimeDisplayLine *timeDisplayLine = [LIYTimeDisplayLine new];
    [view addSubview:timeDisplayLine];
    timeDisplayLine.borderColor = borderColor;
    [timeDisplayLine setFontByName:fontName];
    [timeDisplayLine positionViews];
    [timeDisplayLine updateLabelFromDate:initialDate];

    return timeDisplayLine;
}

#pragma mark - public

- (void)updateLabelFromDate:(NSDate *)date {
    self.timeLabel.text = [self.dateFormatter stringFromDate:date];
}

#pragma mark - UIView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initView];
    }

    return self;
}

#pragma mark - convenience

- (void)initView {
    [self setupDateFormatter];
    [self removeMarginsFromView:self];
    [self addLineView];
    [self addTimeBubble];
    [self addTimeLabel];
}

- (void)setupDateFormatter {
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"h:mm a"];
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = [borderColor copy];
    self.lineView.backgroundColor = _borderColor;
    self.bubbleView.layer.borderColor = _borderColor.CGColor;
}

- (void)addLineView {
    self.lineView = [UIView new];
    [self addSubview:self.lineView];
}

- (void)positionViews {
    [self positionInSuperview];
    [self positionLineView];
    [self positionBubbleView];
    [self pinTimeLabelToBubbleView];
}

- (void)positionInSuperview {
    [self pinViewHorizontallyToSuperview:self];
    [self autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self autoSetDimension:ALDimensionHeight toSize:LIYTimeSelectorHeight];
}

- (void)pinTimeLabelToBubbleView {
    [self.timeLabel autoPinEdgesToSuperviewEdgesWithInsets:ALEdgeInsetsZero];
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
- (void)removeMarginsFromView:(UIView *)view {
    if ([view respondsToSelector:@selector(layoutMargins)]) {
        view.layoutMargins = UIEdgeInsetsZero;
    }
}
#pragma clang diagnostic pop

- (void)positionLineView {
    [self.lineView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.lineView autoSetDimension:ALDimensionHeight toSize:1.0f];
    [self pinViewHorizontallyToSuperview:self.lineView];
}

- (void)pinViewHorizontallyToSuperview:(UIView *)view {
    [view autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [view autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
}

- (void)positionBubbleView {
    [self.bubbleView autoSetDimension:ALDimensionWidth toSize:LIYTimeSelectorBubbleWidth];
    [self pinBubbleViewVertically];
    [self.bubbleView autoAlignAxisToSuperviewAxis:ALAxisVertical];
}

- (void)pinBubbleViewVertically {
    [self.bubbleView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [self.bubbleView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
}

- (void)addTimeBubble {
    self.bubbleView = [UIView new];
    self.bubbleView.layer.cornerRadius = 15.0f;
    self.bubbleView.layer.borderWidth = 1.0f;
    self.bubbleView.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.bubbleView];
}

- (void)addTimeLabel {
    self.timeLabel = [UILabel new];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.textColor = [UIColor colorWithHexString:@"353535"];
    self.timeLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    [self.bubbleView addSubview:self.timeLabel];
}

- (void)setFontByName:(NSString *)fontName {
    if (fontName) {
        self.timeLabel.font = [UIFont fontWithName:fontName size:18.0f];
    }
}

@end