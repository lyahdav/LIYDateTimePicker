//
//  ViewController.m
//  CalendarExample
//
//  Created by Liron Yahdav on 5/29/14.
//  Copyright (c) 2014 Handle. All rights reserved.
//

#import "LIYDateTimePickerViewController.h"
#import "MSCollectionViewCalendarLayout.h"
#import "MZDayPicker.h"

// Collection View Reusable Views
#import "MSGridline.h"
#import "MSTimeRowHeaderBackground.h"
#import "MSDayColumnHeaderBackground.h"
#import "MSEventCell.h"
#import "MSDayColumnHeader.h"
#import "MSTimeRowHeader.h"
#import "MSCurrentTimeIndicator.h"
#import "MSCurrentTimeGridline.h"
#import <EventKit/EventKit.h>
#import "NSDate+CupertinoYankee.h"

NSString * const MSEventCellReuseIdentifier = @"MSEventCellReuseIdentifier";
NSString * const MSDayColumnHeaderReuseIdentifier = @"MSDayColumnHeaderReuseIdentifier";
NSString * const MSTimeRowHeaderReuseIdentifier = @"MSTimeRowHeaderReuseIdentifier";
NSString * const HLInvisibleEventCellReuseIdentifier = @"HLInvisibleEventCellReuseIdentifier";

@interface LIYDateTimePickerViewController () <MZDayPickerDelegate, MZDayPickerDataSource, MSCollectionViewDelegateCalendarLayout, UICollectionViewDataSource>

@property (nonatomic, strong) MSCollectionViewCalendarLayout *collectionViewCalendarLayout;
@property (atomic, strong) NSArray *events;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) MZDayPicker *dayPicker;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *dragDateFormatter;
@property (nonatomic, strong) UIView *dragView;
@property (nonatomic, strong) UILabel *dragLabel;
@property (nonatomic, strong) NSLayoutConstraint *dragViewY;
@property (nonatomic, strong) NSLayoutConstraint *dragLabelY;

@end

@implementation LIYDateTimePickerViewController

+ (LIYDateTimePickerViewController *)timePickerForDate:(NSDate *)date delegate:(id<LIYDateTimePickerDelegate>)delegate {
    LIYDateTimePickerViewController *vc = [[LIYDateTimePickerViewController alloc] init];
    vc.delegate = delegate;
    vc.date = date;
    return vc;
}

- (void)collectionViewTapped:(UITapGestureRecognizer *)recognizer {
    self.dragViewY.constant = [recognizer locationInView:self.view].y;
    self.dragLabelY.constant = [recognizer locationInView:self.view].y;
    
    NSDate *selectedDate = [self dateFromYCoord:[recognizer locationInView:self.collectionView].y];
    self.dragLabel.text = [self.dragDateFormatter stringFromDate:selectedDate];
    
    self.dragView.hidden = NO;
    self.dragView.alpha = 0;
    self.dragLabel.hidden = NO;
    self.dragLabel.alpha = 0;
    [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionAutoreverse animations:^{
        self.dragView.alpha = 1;
        self.dragLabel.alpha = 1;
    } completion:^(BOOL finished) {
        self.dragView.hidden = YES;
        self.dragLabel.hidden = YES;
        [self.delegate dateTimePicker:self didSelectDate:selectedDate];
    }];
}

- (void)cancelTapped:(id)sender {
    [self.delegate dateTimePicker:self didSelectDate:nil];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _date = [NSDate date];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.showCancelButton) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped:)];
    }
    
    self.collectionViewCalendarLayout = [[MSCollectionViewCalendarLayout alloc] init];
    self.collectionViewCalendarLayout.hourHeight = 50.0; //TODO const
    self.collectionViewCalendarLayout.delegate = self;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.collectionViewCalendarLayout];
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    
    [self.collectionView registerClass:MSEventCell.class forCellWithReuseIdentifier:MSEventCellReuseIdentifier];
    [self.collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:HLInvisibleEventCellReuseIdentifier];
    [self.collectionView registerClass:MSDayColumnHeader.class forSupplementaryViewOfKind:MSCollectionElementKindDayColumnHeader withReuseIdentifier:MSDayColumnHeaderReuseIdentifier];
    [self.collectionView registerClass:MSTimeRowHeader.class forSupplementaryViewOfKind:MSCollectionElementKindTimeRowHeader withReuseIdentifier:MSTimeRowHeaderReuseIdentifier];

    // These are optional. If you don't want any of the decoration views, just don't register a class for them.
    [self.collectionViewCalendarLayout registerClass:MSCurrentTimeIndicator.class forDecorationViewOfKind:MSCollectionElementKindCurrentTimeIndicator];
    [self.collectionViewCalendarLayout registerClass:MSCurrentTimeGridline.class forDecorationViewOfKind:MSCollectionElementKindCurrentTimeHorizontalGridline];
    [self.collectionViewCalendarLayout registerClass:MSGridline.class forDecorationViewOfKind:MSCollectionElementKindVerticalGridline];
    [self.collectionViewCalendarLayout registerClass:MSGridline.class forDecorationViewOfKind:MSCollectionElementKindHorizontalGridline];
    [self.collectionViewCalendarLayout registerClass:MSTimeRowHeaderBackground.class forDecorationViewOfKind:MSCollectionElementKindTimeRowHeaderBackground];
    [self.collectionViewCalendarLayout registerClass:MSDayColumnHeaderBackground.class forDecorationViewOfKind:MSCollectionElementKindDayColumnHeaderBackground];

    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(collectionViewTapped:)];
    [self.collectionView addGestureRecognizer:self.tapGestureRecognizer];
    
    

    self.dayPicker = [[MZDayPicker alloc] initWithFrame:CGRectZero month:9 year:2013];
    [self.view addSubview:self.dayPicker];

    self.dayPicker.delegate = self;
    self.dayPicker.dataSource = self;
    
    self.dayPicker.dayNameLabelFontSize = 12.0f;
    self.dayPicker.dayLabelFontSize = 18.0f;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"EE"];
    
    [self.dayPicker setStartDate:self.date endDate:[self.date dateByAddingTimeInterval:60*60*24*14]]; // TODO create property for this value
    
    [self.dayPicker setCurrentDate:self.date animated:NO];

    [self setupConstraints];
    
    [self setupDragView];
    
    [self loadEventKitEventsForSelectedDay];
}

- (void)setupConstraints {
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.dayPicker.translatesAutoresizingMaskIntoConstraints = NO;

    NSObject *collectionView = self.collectionView, *dayPicker = self.dayPicker, *topLayoutGuide = self.topLayoutGuide;
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:[topLayoutGuide][dayPicker(64)][collectionView]|"
                               options:0
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(topLayoutGuide, dayPicker, collectionView)]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[dayPicker]|"
                               options:0
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(dayPicker)]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[collectionView]|"
                               options:0
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(collectionView)]];
}

- (void)setupDragView {
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
    [self.view addGestureRecognizer:longPressRecognizer];
    
    self.dragView = [[UIView alloc] init];
    [self.view addSubview:self.dragView];
    self.dragView.translatesAutoresizingMaskIntoConstraints = NO;
    self.dragView.hidden = YES;
    self.dragView.backgroundColor = [UIColor blueColor];
    
    NSObject *dragView = self.dragView;
    self.dragViewY = [NSLayoutConstraint constraintWithItem:self.dragView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0f constant:0];
    [self.view addConstraint:self.dragViewY];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[dragView]|"
                               options:0
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(dragView)]];
    [self.dragView addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:[dragView(2)]"
                                   options:0
                                   metrics:nil
                                   views:NSDictionaryOfVariableBindings(dragView)]];
    
    self.dragLabel = [[UILabel alloc] init];
    self.dragLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.dragLabel.hidden = YES;
    self.dragLabel.font = [UIFont boldSystemFontOfSize:10.0];
    self.dragLabel.textColor = [UIColor blueColor];
    self.dragLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:self.dragLabel];
    NSObject *dragLabel = self.dragLabel;
    self.dragLabelY = [NSLayoutConstraint constraintWithItem:self.dragLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0f constant:0];
    [self.view addConstraint:self.dragLabelY];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[dragLabel]|"
                               options:0
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(dragLabel)]];
    
    self.dragDateFormatter = [[NSDateFormatter alloc] init];
    [self.dragDateFormatter setDateFormat:@"h:mm a"];
    
}

- (NSDate *)dateFromYCoord:(CGFloat)y {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.date];
    CGFloat hour = round([self hourAtYCoord:y] * 4) / 4;
    dateComponents.hour = trunc(hour);
    dateComponents.minute = round((hour - trunc(hour)) * 60);
    NSDate *selectedDate = [cal dateFromComponents:dateComponents];
    return selectedDate;
}

- (IBAction)onLongPress:(UILongPressGestureRecognizer *)recognizer {
    self.dragViewY.constant = [recognizer locationInView:self.view].y;
    self.dragLabelY.constant = [recognizer locationInView:self.view].y;

    NSDate *selectedDate = [self dateFromYCoord:[recognizer locationInView:self.collectionView].y];
    self.dragLabel.text = [self.dragDateFormatter stringFromDate:selectedDate];

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.dragView.hidden = NO;
        self.dragLabel.hidden = NO;
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        self.dragView.hidden = YES;
        self.dragLabel.hidden = YES;
        [self.delegate dateTimePicker:self didSelectDate:selectedDate];
    }
}

- (NSDate *)nextDayForDate:(NSDate *)date {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:1];
    
    return [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:date options:0];
}

- (void)loadEventKitEventsForSelectedDay {
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        NSAssert(granted, @"calendar access denied");
        
        NSPredicate *predicate = [eventStore predicateForEventsWithStartDate:[self.date beginningOfDay] // TODO weakify?
                                                                          endDate:[self nextDayForDate:[self.date beginningOfDay]] // TODO weakify?
                                                                        calendars:nil];
        self.events = [eventStore eventsMatchingPredicate:predicate]; // TODO weakify?
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionViewCalendarLayout invalidateLayoutCache];
            [self.collectionView reloadData]; // TODO weakify?
            [self scrollToHour:6];
        });
        
    }];
}

- (void)scrollToHour:(NSInteger)hour {
    NSDate *now = [NSDate date];
    BOOL todaySelected = [[now beginningOfDay] isSameDayAsDate:self.date];
    if (todaySelected) {
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *dateComponents = [cal components:NSCalendarUnitHour fromDate:now];
        hour = dateComponents.hour;
    }
    CGFloat timeY = hour * self.collectionViewCalendarLayout.hourHeight;
    [self.collectionView setContentOffset:CGPointMake(0, timeY) animated:NO];
}

- (CGFloat)hourAtYCoord:(CGFloat)y {
    CGFloat hour = (y + (self.collectionViewCalendarLayout.hourHeight / 2) - self.collectionViewCalendarLayout.dayColumnHeaderHeight) / self.collectionViewCalendarLayout.hourHeight - 1;
    hour = fmax(hour, 0);
    hour = fmin(hour, 24);
    return hour;
}

# pragma mark - properties

- (void)setDate:(NSDate *)date {
    _date = date;
    [self.collectionViewCalendarLayout invalidateLayoutCache];
    [self.collectionView reloadData];
    [self scrollToHour:6];
    [self loadEventKitEventsForSelectedDay];
}

#pragma mark - MZDayPickerDataSource

- (NSString *)dayPicker:(MZDayPicker *)dayPicker titleForCellDayNameLabelInDay:(MZDay *)day {
    return [self.dateFormatter stringFromDate:day.date];
}

#pragma mark - MZDayPickerDelegate

- (void)dayPicker:(MZDayPicker *)dayPicker didSelectDay:(MZDay *)day
{
    self.date = day.date;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger numberOfInvisibleCells = 2; // we have start and end pseudo cells
    return self.events.count + numberOfInvisibleCells;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0 || indexPath.row == self.events.count + 1) {
        // we don't actually have cells to display for the pseudo events
        return [collectionView dequeueReusableCellWithReuseIdentifier:HLInvisibleEventCellReuseIdentifier forIndexPath:indexPath];
    }

    MSEventCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MSEventCellReuseIdentifier forIndexPath:indexPath];
    cell.event = self.events[indexPath.row - 1];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view;
    if (kind == MSCollectionElementKindDayColumnHeader) {
        MSDayColumnHeader *dayColumnHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:MSDayColumnHeaderReuseIdentifier forIndexPath:indexPath];
        NSDate *day = [self.collectionViewCalendarLayout dateForDayColumnHeaderAtIndexPath:indexPath];
        NSDate *currentDay = [self currentTimeComponentsForCollectionView:self.collectionView layout:self.collectionViewCalendarLayout];
        dayColumnHeader.day = day;
        dayColumnHeader.currentDay = [[day beginningOfDay] isEqualToDate:[currentDay beginningOfDay]];
        view = dayColumnHeader;
    } else if (kind == MSCollectionElementKindTimeRowHeader) {
        MSTimeRowHeader *timeRowHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:MSTimeRowHeaderReuseIdentifier forIndexPath:indexPath];
        timeRowHeader.time = [self.collectionViewCalendarLayout dateForTimeRowHeaderAtIndexPath:indexPath];
        view = timeRowHeader;
    }
    return view;
}

#pragma mark - MSCollectionViewCalendarLayout

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout dayForSection:(NSInteger)section {
    return self.date;
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout startTimeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return [self.date beginningOfDay];
    } else if (indexPath.row == self.events.count + 1) {
        return [self.date endOfDay];
    } else {
        EKEvent *event = self.events[indexPath.item - 1];
        return event.startDate;
    }
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout endTimeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return [self.date beginningOfDay];
    } else if (indexPath.row == self.events.count + 1) {
        return [self.date endOfDay];
    } else {
        EKEvent *event = self.events[indexPath.item - 1];
        return event.endDate;
    }
}

- (NSDate *)currentTimeComponentsForCollectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout {
    return [NSDate date];
}

@end
