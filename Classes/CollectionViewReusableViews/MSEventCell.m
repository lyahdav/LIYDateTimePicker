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

@end

@implementation MSEventCell

#pragma mark - UIView

- (id)initWithFrame:(CGRect)frame
{
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
        
        self.title = [UILabel new];
        self.title.numberOfLines = 0;
        self.title.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.title];
        
        self.location = [UILabel new];
        self.location.numberOfLines = 0;
        self.location.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.location];
        
        [self updateColors];
        
        CGFloat borderWidth = 2.0;
        CGFloat contentMargin = 2.0;
        UIEdgeInsets contentPadding = UIEdgeInsetsMake(1.0, (borderWidth + 4.0), 1.0, 4.0);
        
        [self.borderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(self.mas_height);
            make.width.equalTo(@(borderWidth));
            make.left.equalTo(self.mas_left);
            make.top.equalTo(self.mas_top);
        }];
        
        [self.title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_top).offset(contentPadding.top);
            make.left.equalTo(self.mas_left).offset(contentPadding.left);
            make.right.equalTo(self.mas_right).offset(-contentPadding.right);
        }];
        
        [self.location mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.title.mas_bottom).offset(contentMargin);
            make.left.equalTo(self.mas_left).offset(contentPadding.left);
            make.right.equalTo(self.mas_right).offset(-contentPadding.right);
            make.bottom.lessThanOrEqualTo(self.mas_bottom).offset(-contentPadding.bottom);
        }];
    }
    return self;
}

#pragma mark - UICollectionViewCell

- (void)setSelected:(BOOL)selected
{
    if (selected && (self.selected != selected)) {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformMakeScale(1.025, 1.025);
            self.layer.shadowOpacity = 0.2;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.transform = CGAffineTransformIdentity;
            }];
        }];
    } else if (selected) {
        self.layer.shadowOpacity = 0.2;
    } else {
        self.layer.shadowOpacity = 0.0;
    }
    [super setSelected:selected]; // Must be here for animation to fire
    [self updateColors];
}

#pragma mark - MSEventCell

- (void)setEvent:(EKEvent *)event
{
    _event = event;
    self.title.attributedText = [[NSAttributedString alloc] initWithString:event.title attributes:[self titleAttributesHighlighted:self.selected]];
    self.location.attributedText = [[NSAttributedString alloc] initWithString:event.location ?: @"" attributes:[self subtitleAttributesHighlighted:self.selected]];
    self.eventBorderColor = [UIColor colorWithCGColor: self.event.calendar.CGColor];
}

- (void)updateColors
{
    self.contentView.backgroundColor = [self backgroundColorHighlighted:self.selected];
    self.borderView.backgroundColor = [self borderColor];
    self.title.textColor = [self textColorHighlighted:self.selected];
    self.location.textColor = [self textColorHighlighted:self.selected];
}

- (NSDictionary *)titleAttributesHighlighted:(BOOL)highlighted
{
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.hyphenationFactor = 1.0;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    return @{
        NSFontAttributeName : [UIFont boldSystemFontOfSize:12.0],
        NSForegroundColorAttributeName : [self textColorHighlighted:highlighted],
        NSParagraphStyleAttributeName : paragraphStyle
    };
}

- (NSDictionary *)subtitleAttributesHighlighted:(BOOL)highlighted
{
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.hyphenationFactor = 1.0;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    return @{
        NSFontAttributeName : [UIFont systemFontOfSize:12.0],
        NSForegroundColorAttributeName : [self textColorHighlighted:highlighted],
        NSParagraphStyleAttributeName : paragraphStyle
    };
}

- (UIColor *)backgroundColorHighlighted:(BOOL)selected
{
    return selected ? [UIColor colorWithHexString:@"ffffff"] : [[UIColor colorWithHexString:@"ffffff"] colorWithAlphaComponent:1.0];
}

- (UIColor *)textColorHighlighted:(BOOL)selected
{
    return selected ? [UIColor whiteColor] : [UIColor colorWithHexString:@"353535"];
}

- (UIColor *)borderColor
{
    return self.eventBorderColor;
}

@end
