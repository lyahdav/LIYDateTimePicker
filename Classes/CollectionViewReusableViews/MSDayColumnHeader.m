//
//  MSDayColumnHeader.m
//  Example
//
//  Created by Eric Horacek on 2/26/13.
//  Copyright (c) 2013 Monospace Ltd. All rights reserved.
//

#import "MSDayColumnHeader.h"
#import "Masonry.h"
#import "UIColor+HexString.h"
#import <EventKit/EventKit.h>
#import "ObjectiveSugar.h"
#import "PureLayout.h"

CGFloat const kLIYDefaultHeaderHeight = 56.0f;

@interface MSDayColumnHeader ()

@property (nonatomic, strong) NSString *defaultBoldFontFamilyName;
@property (nonatomic, strong) NSString *dayTitlePrefix;
@property (nonatomic, strong) UIColor *timeHighlightColor;
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UIView *allDayView;
@property (nonatomic, strong) UILabel *allDayLabel;
@property (nonatomic, strong) UILabel *allDayEventsLabel;
@property (nonatomic, strong) UIView *backgroundOutline;
@property (nonatomic) BOOL showDateTime;
@property (nonatomic, assign) BOOL showTimeInHeader;
@property (nonatomic, strong) NSArray *allDayEvents;
@property (nonatomic, strong) NSLayoutConstraint *dayColumnHeaderHeightConstraint;

@end

@implementation MSDayColumnHeader

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.title = [UILabel new];
        self.title.textAlignment = NSTextAlignmentLeft;
        self.title.backgroundColor = [UIColor clearColor];
        self.title.font = [UIFont boldSystemFontOfSize:14.0];

        [self addSubview:self.title];

        [self.title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(kLIYAllDayHeight));
            make.left.equalTo(@26.0f);
        }];

        self.allDayView = [UIView new];
        [self addSubview:self.allDayView];
        self.allDayView.backgroundColor = [[UIColor colorWithHexString:@"35b1f1"] colorWithAlphaComponent:0.2];
        self.allDayView.clipsToBounds = YES;
        [self.allDayView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self);
            make.height.equalTo(@(kLIYAllDayHeight));
            make.leading.equalTo(@0);
            make.trailing.equalTo(@0);
        }];

        self.allDayLabel = [UILabel new];
        [self.allDayView addSubview:self.allDayLabel];
        self.allDayLabel.text = @"all-day";
        [self.allDayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.allDayView);
            make.left.equalTo(@10);
        }];
        self.allDayLabel.font = [UIFont systemFontOfSize:10.0];

        self.allDayEventsLabel = [UILabel new];
        self.allDayEventsLabel.textColor = [UIColor colorWithHexString:@"21729c"];
        [self.allDayView addSubview:self.allDayEventsLabel];
        [self.allDayEventsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(self.allDayView);
            make.leading.equalTo(self.allDayLabel.mas_trailing).with.offset(15);
        }];
        self.allDayEventsLabel.font = [UIFont boldSystemFontOfSize:10.0];
    }
    return self;
}

- (void)setDefaultFontFamilyName:(NSString *)defaultFontFamilyName {
    self.title.font = [UIFont fontWithName:defaultFontFamilyName size:14.0f];
    self.allDayLabel.font = [UIFont fontWithName:defaultFontFamilyName size:10.0f];
    self.allDayEventsLabel.font = [UIFont fontWithName:defaultFontFamilyName size:10.0f];
}

- (void)setDate:(NSDate *)date {
    _date = date;
    [self formatTitle];
    [self setNeedsLayout];
}

- (void)setAllDayVisible:(BOOL)visible {
    if (visible) {
        [self.allDayView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(kLIYAllDayHeight));
        }];
    } else {
        [self.allDayView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@0);
        }];
    }

    if (self.showTimeInHeader) {
        [self.backgroundOutline removeFromSuperview];
        self.backgroundOutline = nil;
        [self addBackgroundOutline];
    }
}

- (void)setShowTimeInHeader:(BOOL)showTimeInHeader {
    _showTimeInHeader = showTimeInHeader;

    [self addBackgroundOutline];
}

#pragma mark - Convenience

- (void)formatTitle {
    if (self.date) {
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        NSDateFormatter *timeFormatter = [NSDateFormatter new];
        timeFormatter.dateFormat = @"h:mm a";
        dateFormatter.dateFormat = @"EEEE, MMM d";

        NSString *dateBase;
        if (!self.dayTitlePrefix) {
            dateBase = [dateFormatter stringFromDate:self.date];
        } else {
            dateBase = [NSString stringWithFormat:@"%@ %@", self.dayTitlePrefix, [dateFormatter stringFromDate:self.date]];
        }

        NSMutableAttributedString *dateString = [[NSMutableAttributedString alloc] initWithString:dateBase];

        if (self.showTimeInHeader) {
            NSMutableAttributedString *time = [[NSMutableAttributedString alloc] initWithString:[timeFormatter stringFromDate:self.date]];
            [time addAttribute:NSFontAttributeName value:[UIFont fontWithName:self.defaultBoldFontFamilyName size:14.0f] range:NSMakeRange(0, time.length)];

            [dateString appendAttributedString:[[NSAttributedString alloc] initWithString:@", "]];

            NSInteger dateLength = dateString.length;

            [dateString appendAttributedString:time];

            [dateString addAttribute:NSForegroundColorAttributeName value:self.timeHighlightColor range:NSMakeRange(dateLength, time.length)];
        }

        self.title.attributedText = dateString;
    }
}

- (void)addBackgroundOutline {
    if (!self.backgroundOutline) {
        self.backgroundOutline = [[UIView alloc] init];
        self.backgroundOutline.layer.borderColor = [UIColor colorWithHexString:@"#d0d0d0"].CGColor;
        self.backgroundOutline.layer.borderWidth = 1.0f;
        self.backgroundOutline.layer.cornerRadius = 5.0f;

        [self addSubview:self.backgroundOutline];

        [self.backgroundOutline mas_makeConstraints:^(MASConstraintMaker *maker) {

            CGFloat top = 10.0f;
            CGFloat height = 36.0f;

            maker.top.equalTo(@(top));
            maker.height.equalTo(@(height));
            maker.leading.equalTo(@16);
            maker.trailing.equalTo(@-16);
        }];
    }
}

- (void)configureForDateHeaderWithDayTitlePrefix:(NSString *)dayTitlePrefix defaultFontFamilyName:(NSString *)defaultFontFamilyName 
                       defaultBoldFontFamilyName:(NSString *)defaultBoldFontFamilyName timeHighlightColor:(UIColor *)timeHighlightColor date:(NSDate *)date
                                showTimeInHeader:(BOOL)showTimeInHeader {
    self.showDateTime = YES;
    self.dayTitlePrefix = dayTitlePrefix;
    [self setDefaultFontFamilyName:defaultFontFamilyName];
    self.defaultBoldFontFamilyName = defaultBoldFontFamilyName;
    self.timeHighlightColor = timeHighlightColor;
    self.showTimeInHeader = showTimeInHeader;
    self.date = date;
}

- (void)updateAllDaySectionWithEvents:(NSArray *)allDayEvents {
    self.allDayEvents = allDayEvents;
    if (allDayEvents.count == 0) {
        [self setAllDayVisible:NO];
    } else {
        [self setAllDayVisible:YES];
        NSArray *allDayEventTitles = [allDayEvents map:^id(EKEvent *event) { // TODO: compute once
            return event.title;
        }];
        self.allDayEventsLabel.text = [allDayEventTitles componentsJoinedByString:@", "];
    }

    if (self.dayColumnHeaderHeightConstraint) {
        [self updateDayColumnHeaderHeight];
    }
}

- (CGFloat)height {
    CGFloat height;
    if (self.showDateTime) {
        height = self.allDayEvents.count == 0 ? kLIYDefaultHeaderHeight : kLIYDefaultHeaderHeight + kLIYAllDayHeight;
    } else {
        height = self.allDayEvents.count == 0 ? 0.0f : kLIYAllDayHeight;
    }
    return height;
}

- (void)updateDayColumnHeaderHeight {
    self.dayColumnHeaderHeightConstraint.constant = [self height];
}

- (void)positionInView:(UIView *)view {
    [view addSubview:self];
    self.dayColumnHeaderHeightConstraint = [self autoSetDimension:ALDimensionHeight toSize:[self height]];
    [self autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
}

@end
