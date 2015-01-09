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
@property (nonatomic, strong) UIView *bottomBorder;
@property (nonatomic, strong) UIView *backgroundOutline;

@end

@implementation MSDayColumnHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
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


-(void) setDefaultFontFamilyName:(NSString *)defaultFontFamilyName{
    _defaultFontFamilyName = defaultFontFamilyName;
    
    self.title.font = [UIFont fontWithName:defaultFontFamilyName size:14.0f];
    self.allDayLabel.font = [UIFont fontWithName:defaultFontFamilyName size:10.0f];
    self.allDayEventsLabel.font = [UIFont fontWithName:defaultFontFamilyName size:10.0f];
}

-(void) setHeightForHeader:(CGFloat) heightForHeader{
    
    _heightForHeader = heightForHeader;
    
    if (self.bottomBorder){
        [self.bottomBorder removeFromSuperview];
    }
    
    self.bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f, heightForHeader, self.frame.size.width, .5f)];
    self.bottomBorder.backgroundColor = [UIColor colorWithHexString:@"d0d0d0"];
    [self addSubview:self.bottomBorder];
    
}

- (void)setDay:(NSDate *)day
{
    _day = day;
    
    [self formatTitle];
    
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

-(void) setShowTimeInHeader:(BOOL)showTimeInHeader{
    _showTimeInHeader = showTimeInHeader;
    
    [self addBackgroundOutline];
}

#pragma mark - Convenience
-(void) formatTitle{
    
    if (self.day){
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        NSDateFormatter *timeFormatter = [NSDateFormatter new];
        timeFormatter.dateFormat = @"h:mm a";
        dateFormatter.dateFormat = @"EEEE, MMM d";
        
        
        NSString *dateBase;
        if (!self.dayTitlePrefix){
            dateBase = [dateFormatter stringFromDate:self.day];
        }else{
            dateBase = [NSString stringWithFormat:@"%@ %@", self.dayTitlePrefix, [dateFormatter stringFromDate:self.day]];
        }
        
        NSMutableAttributedString *dateString = [[NSMutableAttributedString alloc] initWithString:dateBase];
        
        if (self.showTimeInHeader){
            NSMutableAttributedString *time = [[NSMutableAttributedString alloc] initWithString:[timeFormatter stringFromDate:self.day]];
            [time addAttribute:NSFontAttributeName value:[UIFont fontWithName:self.defaultBoldFontFamilyName size:14.0f] range:NSMakeRange(0, time.length)];
            
            [dateString appendAttributedString:[[NSAttributedString alloc] initWithString:@", "]];
            
            NSInteger dateLength = dateString.length;
            
            [dateString appendAttributedString:time];
            
            [dateString addAttribute:NSForegroundColorAttributeName value:self.timeHighlightColor range:NSMakeRange(dateLength, time.length)];
            
        }
        
        self.title.attributedText = dateString;
    }

}

-(void) addBackgroundOutline{
    
    if (!self.backgroundOutline){
        self.backgroundOutline = [[UIView alloc] init];
        self.backgroundOutline.layer.borderColor = [UIColor colorWithHexString:@"#d0d0d0"].CGColor;
        self.backgroundOutline.layer.borderWidth = 1.0f;
        self.backgroundOutline.layer.cornerRadius = 5.0f;
        
        [self addSubview:self.backgroundOutline];
        
        [self.backgroundOutline mas_makeConstraints:^(MASConstraintMaker *maker) {
            
            CGFloat bottom = self.bounds.size.height - 62.0f;
            CGFloat height = self.bounds.size.height - 20.0f;
            
            maker.bottom.equalTo(@(bottom));
            maker.height.equalTo(@(height));
            maker.leading.equalTo(@16);
            maker.trailing.equalTo(@-16);
        }];
    }
}

@end
