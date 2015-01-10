//
//  MSEventCell.m
//  Example
//
//  Created by Eric Horacek on 2/26/13.
//  Copyright (c) 2013 Monospace Ltd. All rights reserved.
//

#import "MSEventCell.h"
#import <EventKit/EventKit.h>
#import "Masonry.h"
#import "UIColor+HexString.h"

@interface MSEventCell ()

@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) UIView *bottomBorderView;
@property (nonatomic, strong) UILabel *eventTimeLabel;

@end

@implementation MSEventCell

#pragma mark - UIView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.layer.shouldRasterize = YES;
        
        self.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.layer.shadowOffset = CGSizeMake(0.0, 4.0);
        self.layer.shadowRadius = 5.0;
        self.layer.shadowOpacity = 0.0;
        
        self.borderView = [UIView new];
        [self.contentView addSubview:self.borderView];
        self.bottomBorderView = [UIView new];
        [self.contentView addSubview:self.bottomBorderView];
        
        self.title = [UILabel new];
        self.title.numberOfLines = 0;
        self.title.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.title];
        
        self.location = [UILabel new];
        self.location.numberOfLines = 0;
        self.location.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.location];
        
        self.eventTimeLabel = [UILabel new];
        self.eventTimeLabel.numberOfLines = 0;
        self.eventTimeLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.eventTimeLabel];
        
        [self updateColors];
        
        CGFloat borderWidth = 6.0;
        CGFloat contentMargin = 2.0;
        UIEdgeInsets contentPadding = UIEdgeInsetsMake(5.0, (borderWidth + 4.0), 1.0, 4.0);
        
        [self.borderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(self.mas_height);
            make.width.equalTo(@(borderWidth));
            make.left.equalTo(self.mas_left);
            make.top.equalTo(self.mas_top);
        }];
        
        [self.bottomBorderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(borderWidth));
            make.left.equalTo(self.mas_left);
            make.right.equalTo(self.mas_right);
        }];
        
        [self.title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_top).offset(contentPadding.top);
            make.left.equalTo(self.mas_left).offset(contentPadding.left);
            make.right.equalTo(self.mas_right).offset(-contentPadding.right);
        }];

        [self.eventTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.title.mas_bottom).offset(contentMargin);
            make.left.equalTo(self.mas_left).offset(contentPadding.left);
            make.right.equalTo(self.mas_right).offset(-contentPadding.right);
            make.bottom.lessThanOrEqualTo(self.mas_bottom).offset(-contentPadding.bottom);
        }];

        // TODO
//        [self.location mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.top.equalTo(self.title.mas_bottom).offset(contentMargin);
//            make.left.equalTo(self.mas_left).offset(contentPadding.left);
//            make.right.equalTo(self.mas_right).offset(-contentPadding.right);
//            make.bottom.lessThanOrEqualTo(self.mas_bottom).offset(-contentPadding.bottom);
//        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self updateColors];
}

#pragma mark - UICollectionViewCell

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected]; // Must be here for animation to fire
}

#pragma mark - MSEventCell

- (void)setEvent:(EKEvent *)event {
    _event = event;
    self.title.attributedText = [[NSAttributedString alloc] initWithString:self.event.title attributes:[self titleAttributesHighlighted:self.selected]];
    self.location.attributedText = [[NSAttributedString alloc] initWithString:event.location ?: @"" attributes:[self subtitleAttributesHighlighted:self.selected]];
    [self updateEventTimesLabel];
}

- (void)setShowEventTimes:(BOOL)showEventTimes {
    _showEventTimes = showEventTimes;
    [self updateEventTimesLabel];
}

- (void)updateEventTimesLabel {
    if (self.showEventTimes) {
        self.eventTimeLabel.attributedText = [[NSAttributedString alloc] initWithString:[self eventTimesString] attributes:[self eventTimesLabelAttributesHighlighted:self.selected]];
    } else {
        self.eventTimeLabel.attributedText = [[NSAttributedString alloc] initWithString:@"" attributes:[self eventTimesLabelAttributesHighlighted:self.selected]];
    }
}

- (NSString *)eventTimesString {
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"h:mm aa"];
    }
    NSString *startDateString = [dateFormatter stringFromDate:self.event.startDate];
    NSString *endDateString = [dateFormatter stringFromDate:self.event.endDate];
    return [NSString stringWithFormat:@"%@ - %@ (%@)", startDateString, endDateString, [self durationString]];
}

- (NSString *)durationString {
    NSTimeInterval interval = [self.event.endDate timeIntervalSinceDate:self.event.startDate];
    NSInteger minutes = (NSInteger)(interval / 60) % 60;
    NSInteger hours = interval / 3600;
    return [NSString stringWithFormat:@"%ld:%02ld hours", hours, minutes];
}

- (void)updateColors {
    self.contentView.backgroundColor = [self backgroundColorHighlighted:self.selected];
    self.borderView.backgroundColor = [self borderColor];
    self.bottomBorderView.backgroundColor = [UIColor colorWithHexString:@"eaeaea"];
    self.title.textColor = [self textColorHighlighted:self.selected];
    self.location.textColor = [self textColorHighlighted:self.selected];
}

- (NSDictionary *)titleAttributesHighlighted:(BOOL)highlighted {
    return [self highlightAttributes:highlighted fontSize:12.0 bold:YES];
}

- (NSDictionary *)eventTimesLabelAttributesHighlighted:(BOOL)highlighted {
    return [self highlightAttributes:highlighted fontSize:10.0 bold:NO];
}

- (NSDictionary *)subtitleAttributesHighlighted:(BOOL)highlighted {
    return [self highlightAttributes:highlighted fontSize:12.0 bold:NO];
}

- (NSDictionary *)highlightAttributes:(BOOL)isHighlighted fontSize:(CGFloat)fontSize bold:(BOOL)bold {
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.hyphenationFactor = 1.0;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    UIFont *font = bold ? [UIFont boldSystemFontOfSize:fontSize] : [UIFont systemFontOfSize:fontSize];
    return @{
             NSFontAttributeName : font,
             NSForegroundColorAttributeName : [self textColorHighlighted:isHighlighted],
             NSParagraphStyleAttributeName : paragraphStyle
             };
}

- (UIColor *)backgroundColorHighlighted:(BOOL)selected {
    return selected ? [UIColor colorWithHexString:@"ffffff"] : [[UIColor colorWithHexString:@"ffffff"] colorWithAlphaComponent:1.0];
}

- (UIColor *)textColorHighlighted:(BOOL)selected {
    return selected ? [UIColor whiteColor] : [UIColor colorWithHexString:@"353535"];
}

- (UIColor *)borderColor {
    return [UIColor colorWithCGColor: self.event.calendar.CGColor];
}


@end
