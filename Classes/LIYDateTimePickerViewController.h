//
//  ViewController.h
//  CalendarExample
//
//  Created by Liron Yahdav on 5/29/14.
//  Copyright (c) 2014 Handle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MSDayColumnHeader.h"
#import "MSCollectionViewCalendarLayout.h"

@class LIYDateTimePickerViewController;

@protocol LIYDateTimePickerDelegate <NSObject>

@optional

- (void)dateTimePicker:(LIYDateTimePickerViewController *)dateTimePickerViewController didSelectDate:(NSDate *)selectedDate;

@end

@interface LIYDateTimePickerViewController : UIViewController

+ (instancetype)timePickerForDate:(NSDate *)date delegate:(id<LIYDateTimePickerDelegate>)delegate;

@property (nonatomic, assign) BOOL allowTimeSelection;
@property (nonatomic, assign) BOOL showCancelButton;
@property (nonatomic, assign) BOOL showDayPicker;
@property (nonatomic, assign) BOOL showDayColumnHeader;
@property (nonatomic, assign) BOOL showEventTimes;
@property (nonatomic, weak) id<LIYDateTimePickerDelegate> delegate;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDate *selectedDate; // TODO: a bit odd there's a date and selectedDate. Combine the two? Or give them better names.
@property (nonatomic, strong) NSArray *visibleCalendars;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSString *dayTitlePrefix;
@property (nonatomic, strong) MSDayColumnHeader *dayColumnHeader;
@property (nonatomic, strong) MSCollectionViewCalendarLayout *collectionViewCalendarLayout;
@property (nonatomic, strong) NSArray *calendarNamesToFilterForEdit;
@property (nonatomic, strong) UIColor *defaultColor1;
@property (nonatomic, strong) UIColor *defaultColor2;
@property (nonatomic, strong) NSString *defaultFontFamilyName;
@property (nonatomic, strong) NSString *defaultSelectedFontFamilyName;
@property (nonatomic, strong) NSString *saveButtonText;
@property (nonatomic, strong) NSArray *nonAllDayEvents;

- (void)reloadEvents;
- (CGFloat)middleYForTimeLine;
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;

@end
