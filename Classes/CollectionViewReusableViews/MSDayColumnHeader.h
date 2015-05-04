//
//  MSDayColumnHeader.h
//  Example
//
//  Created by Eric Horacek on 2/26/13.
//  Copyright (c) 2013 Monospace Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

static const NSInteger kLIYAllDayHeight = 20;

@interface MSDayColumnHeader : UIView

@property (nonatomic, strong) NSDate *date;

- (void)configureForDateHeaderWithDayTitlePrefix:(NSString *)dayTitlePrefix defaultFontFamilyName:(NSString *)defaultFontFamilyName defaultBoldFontFamilyName:(NSString *)defaultBoldFontFamilyName timeHighlightColor:(UIColor *)timeHighlightColor date:(NSDate *)date showTimeInHeader:(BOOL)showTimeInHeader;
- (void)updateAllDaySectionWithEvents:(NSArray *)allDayEvents;
- (CGFloat)height;
- (void)positionInView:(UIView *)view;

@end
