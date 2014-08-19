//
//  ViewController.h
//  CalendarExample
//
//  Created by Liron Yahdav on 5/29/14.
//  Copyright (c) 2014 Handle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LIYDateTimePickerViewController;

@protocol LIYDateTimePickerDelegate <NSObject>

@required
- (void)dateTimePicker:(LIYDateTimePickerViewController *)dateTimePickerViewController didSelectDate:(NSDate *)selectedDate;

@end

@interface LIYDateTimePickerViewController : UIViewController

+ (instancetype)timePickerForDate:(NSDate *)date delegate:(id<LIYDateTimePickerDelegate>)delegate;
- (void)reloadEvents;

@property (nonatomic) BOOL allowTimeSelection;
@property (nonatomic) BOOL showCancelButton;
@property (nonatomic) BOOL showDayPicker;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, weak) id<LIYDateTimePickerDelegate> delegate;
@property (nonatomic, strong) NSArray *visibleCalendarTitles; //<! nil means all calendars
@property (nonatomic, strong) UICollectionView *collectionView;

@end
