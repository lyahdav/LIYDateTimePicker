#import <UIColor-HexString/UIColor+HexString.h>
#import "LIYTimeDisplayLine.h"

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

- (void)positionInSuperview {
    [self pinHorizontallyToSuperview];
    [self centerVerticallyInSuperview];
    [self setHeight];
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
    self.translatesAutoresizingMaskIntoConstraints = NO;
    [self setupDateFormatter];
    [self removeMarginsFromView:self];
    [self setupLine];
    [self setupTimeBubble];
    [self setupTimeLabel];
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

- (void)setHeight {
    NSString *format = [NSString stringWithFormat:@"V:[timeDisplayLine(%ld)]", (long)LIYTimeSelectorHeight];
    [self.superview addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:format options:(NSLayoutFormatOptions)0 metrics:nil views:@{@"timeDisplayLine" : self}]];
}

- (void)pinHorizontallyToSuperview {
    [self.superview addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"H:|[timeDisplayLine]|" options:(NSLayoutFormatOptions)0 metrics:nil views:@{@"timeDisplayLine" : self}]];
}

- (void)centerVerticallyInSuperview {
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[superview]-(<=1)-[timeDisplayLine]" options:NSLayoutFormatAlignAllCenterY
                                                                   metrics:nil views:@{@"superview" : self.superview, @"timeDisplayLine" : self}];
    [self.superview addConstraints:constraints];
}

- (void)setupLine {
    self.lineView = [UIView new];
    self.lineView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.lineView];
}

- (void)positionViews {
    [self positionInSuperview];
    [self positionLineView];
    [self positionBubbleView];
    [self positionTimeLabel];
}

- (void)positionTimeLabel {
    [self removeMarginsFromView:self.bubbleView];
    [self.bubbleView addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"H:|-[timeLabel]-|" options:(NSLayoutFormatOptions)0 metrics:nil views:@{@"timeLabel" : self.timeLabel}]];
    [self.bubbleView addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"V:|-[timeLabel]-|" options:(NSLayoutFormatOptions)0 metrics:nil views:@{@"timeLabel" : self.timeLabel}]];
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
    [self centerLineViewVertically];
    [self setLineViewHeight];
    [self pinLineViewHorizontally];
}

- (void)setLineViewHeight {
    [self addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"V:[line(1)]" options:(NSLayoutFormatOptions)0 metrics:nil views:@{@"line" : self.lineView}]];
}

- (void)centerLineViewVertically {
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[superview]-(<=1)-[line]" options:NSLayoutFormatAlignAllCenterY
                                                                 metrics:nil views:@{@"superview" : self, @"line" : self.lineView}]];
}

- (void)pinLineViewHorizontally {
    [self addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"H:|-[line]-|" options:(NSLayoutFormatOptions)0 metrics:nil views:@{@"line" : self.lineView}]];
}

- (void)positionBubbleView {
    [self setBubbleViewWidth];
    [self pinBubbleViewVertically];
    [self centerBubbleViewHorizontally];
}

- (void)centerBubbleViewHorizontally {
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[superview]-(<=1)-[bubble]" options:NSLayoutFormatAlignAllCenterX
                                                                 metrics:nil views:@{@"superview" : self, @"bubble" : self.bubbleView}]];
}

- (void)pinBubbleViewVertically {
    [self addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"V:|-[bubble]-|" options:(NSLayoutFormatOptions)0 metrics:nil views:@{@"bubble" : self.bubbleView}]];
}

- (void)setBubbleViewWidth {
    NSString *format = [NSString stringWithFormat:@"H:[bubble(%ld)]", (long)LIYTimeSelectorBubbleWidth];
    [self addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:format options:(NSLayoutFormatOptions)0 metrics:nil views:@{@"bubble" : self.bubbleView}]];
}

- (void)setupTimeBubble {
    self.bubbleView = [UIView new];
    self.bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
    self.bubbleView.backgroundColor = [UIColor redColor];
    self.bubbleView.layer.cornerRadius = 15.0f;
    self.bubbleView.layer.borderWidth = 1.0f;
    self.bubbleView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
    [self addSubview:self.bubbleView];
}

- (void)setupTimeLabel {
    self.timeLabel = [UILabel new];
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
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