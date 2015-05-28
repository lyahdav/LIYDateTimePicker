//
//  JTCalendarContentView.h
//  JTCalendar
//
//  Created by Jonathan Tribouharet
//

#import <UIKit/UIKit.h>

@class JTCalendar;

@interface JTCalendarContentView : UIScrollView

@property (weak, nonatomic) JTCalendar *calendarManager;

@property (nonatomic) NSDate *currentDate;

- (void)reloadData;
- (void)reloadAppearance;
- (void)enableWeekMonthPanWithMinimumHeight:(CGFloat)minimumHeight andMaximumHeight:(CGFloat)maximumHeight byUpdatingContainerHeightConstraint:(NSLayoutConstraint *)containerHeightConstraint andContentViewHeightConstraint:(NSLayoutConstraint *)contentViewHeightConstraint;

@end
