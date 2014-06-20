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

@interface MSDayColumnHeader ()

@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UIView *titleBackground;
@property (nonatomic, strong) UIView *allDayView;
@property (nonatomic, strong) UILabel *allDayLabel;

@end

@implementation MSDayColumnHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        self.title = [UILabel new];
        self.title.backgroundColor = [UIColor clearColor];
        [self addSubview:self.title];
        
        [self.title mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.top.equalTo(@(kLIYAllDayHeight));
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

- (void)setDay:(NSDate *)day
{
    _day = day;
    
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"EEE MMM d" : @"EEEE MMMM d, YYYY");
    }
    self.title.text = [dateFormatter stringFromDate:day];
    [self setNeedsLayout];
}

- (void)setShowAllDaySection:(BOOL)showAllDaySection {
    _showAllDaySection = showAllDaySection;
    
    if (showAllDaySection) {
        [self.allDayView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@(kLIYAllDayHeight));
        }];
    } else {
        [self.allDayView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(@0);
        }];
    }
}

@end
