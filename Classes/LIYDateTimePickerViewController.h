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

@required
- (void)dateTimePicker:(LIYDateTimePickerViewController *)dateTimePickerViewController didSelectDate:(NSDate *)selectedDate;

@end

@interface LIYDateTimePickerViewController : UIViewController

+ (instancetype)timePickerForDate:(NSDate *)date delegate:(id<LIYDateTimePickerDelegate>)delegate;
- (void)reloadEvents;
- (CGFloat)middleYForTimeLine;

@property (nonatomic) BOOL allowTimeSelection;
@property (nonatomic) BOOL showCancelButton;
@property (nonatomic) BOOL showDayPicker;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, weak) id<LIYDateTimePickerDelegate> delegate;
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
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) NSString *saveButtonText;



@end
