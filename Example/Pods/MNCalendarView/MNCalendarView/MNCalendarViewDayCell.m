//
//  MNCalendarViewDayCell.m
//  MNCalendarView
//
//  Created by Min Kim on 7/28/13.
//  Copyright (c) 2013 min. All rights reserved.
//

#import "MNCalendarViewDayCell.h"
#import "UIColor+HexString.h"

NSString *const MNCalendarViewDayCellIdentifier = @"MNCalendarViewDayCellIdentifier";

@interface MNCalendarViewDayCell()

@property(nonatomic,strong,readwrite) NSDate *date;
@property(nonatomic,strong,readwrite) NSDate *month;
@property(nonatomic,assign,readwrite) NSUInteger weekday;

@end

@implementation MNCalendarViewDayCell

- (void)setDate:(NSDate *)date
          month:(NSDate *)month
       calendar:(NSCalendar *)calendar {
  
  self.date     = date;
  self.month    = month;
  self.calendar = calendar;
  
  NSDateComponents *components =
  [self.calendar components:NSMonthCalendarUnit|NSDayCalendarUnit|NSWeekdayCalendarUnit
                   fromDate:self.date];
  
  NSDateComponents *monthComponents =
  [self.calendar components:NSMonthCalendarUnit
                   fromDate:self.month];
  
  self.weekday = components.weekday;
  self.titleLabel.text = [NSString stringWithFormat:@"%d", components.day];
  self.enabled = monthComponents.month == components.month;
    
   
    if ([self isToday]){
        self.titleLabel.textColor = [UIColor colorWithHexString:@"75d6e0"];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];

    }else{
        self.titleLabel.textColor = self.enabled ? [UIColor colorWithHexString:@"353535"] : [UIColor colorWithHexString:@"ededed"];
    }
    
    if (self.defaultFontFamilyName){
        self.titleLabel.font = [UIFont fontWithName:self.defaultFontFamilyName size:14.0f];
    }

    

  
  [self setNeedsDisplay];
}


-(BOOL) isToday{
    
    NSCalendarUnit unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *cellDateComps =  [self.calendar components:unitFlags fromDate:self.date];
    NSDateComponents *todayDateComps =  [self.calendar components:unitFlags fromDate:[NSDate date]];
    
    return [cellDateComps day] == [todayDateComps day] && [cellDateComps month] == [todayDateComps month] && [cellDateComps year] == [todayDateComps year];

}


- (void)setEnabled:(BOOL)enabled {
  [super setEnabled:enabled];
  
    self.backgroundColor = UIColor.whiteColor;
  //self.enabled ? UIColor.whiteColor : [UIColor colorWithRed:.96f green:.96f blue:.96f alpha:1.f];
}

- (void)drawRect:(CGRect)rect {
  [super drawRect:rect];
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGColorRef separatorColor = self.separatorColor.CGColor;
  
  CGSize size = self.bounds.size;
  
  if (self.weekday != 7) {
    CGFloat pixel = 1.f / [UIScreen mainScreen].scale;
    MNContextDrawLine(context,
                      CGPointMake(size.width - pixel, pixel),
                      CGPointMake(size.width - pixel, size.height),
                      separatorColor,
                      pixel);
  }
}

@end
