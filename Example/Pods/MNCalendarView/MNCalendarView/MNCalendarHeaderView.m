//
//  MNCalendarHeaderView.m
//  MNCalendarView
//
//  Created by Min Kim on 7/26/13.
//  Copyright (c) 2013 min. All rights reserved.
//

#import "MNCalendarHeaderView.h"

NSString *const MNCalendarHeaderViewIdentifier = @"MNCalendarHeaderViewIdentifier";

@interface MNCalendarHeaderView()

@property(nonatomic,strong,readwrite) UILabel *titleLabel;
@property(nonatomic,strong,readwrite) UILabel *titleYearLabel;

@end

@implementation MNCalendarHeaderView

- (id)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
      CGRect labelBounds = self.bounds;
      labelBounds.origin.x = 16.0f;
      
        self.titleLabel = [[UILabel alloc] initWithFrame:labelBounds];
        self.titleLabel.backgroundColor = [UIColor whiteColor];
        self.titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];

        self.titleLabel.textAlignment = NSTextAlignmentLeft;
          
        [self addSubview:self.titleLabel];

        labelBounds.origin.y = labelBounds.origin.y + 20.0f;
        self.titleYearLabel = [[UILabel alloc] initWithFrame:labelBounds];
        self.titleYearLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.titleYearLabel.font = [UIFont systemFontOfSize:12.0f];

        self.titleYearLabel.textAlignment = NSTextAlignmentLeft;

        [self addSubview:self.titleYearLabel];
      
  }
  return self;
}

-(void) layoutSubviews{
    [super layoutSubviews];
    
    if (self.defaultFontFamilyName){
        self.titleYearLabel.font = [UIFont fontWithName:self.defaultFontFamilyName size:12.0f];
    }
    
    if (self.defaultFontFamilyName){
        self.titleLabel.font = [UIFont fontWithName:self.defaultFontFamilyName size:18.0f];
    }
}

- (void)setDate:(NSDate *)date {
  _date = date;

  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

  [dateFormatter setDateFormat:@"MMMM yyyy"];

  self.titleLabel.text = [dateFormatter stringFromDate:self.date];
}

@end
