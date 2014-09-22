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
#import "ObjectiveSugar.h"

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

# pragma mark - LIYCollectionViewCalendarLayout

// TODO submit pull request to MSCollectionViewCalendarLayout so we don't need this

@interface LIYCollectionViewCalendarLayout : MSCollectionViewCalendarLayout

@end

@implementation LIYCollectionViewCalendarLayout

- (NSInteger)earliestHourForSection:(NSInteger)section {
    return 0;
}

- (NSInteger)latestHourForSection:(NSInteger)section {
    return 24;
}

@end

#pragma mark - NSDate (LIYAdditional)

// TODO: this shouldn't be necessary as it's defined in MZDayPicker.h, but it's required for `pod lib lint` to succeed. Figure out how to fix that.
@implementation NSDate (LIYAdditional)
- (BOOL)isSameDayAsDate:(NSDate*)date
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:self];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date];
    
    return [comp1 day] == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}
@end

#pragma mark - LIYDateTimePickerViewController

@interface LIYDateTimePickerViewController () <MZDayPickerDelegate, MZDayPickerDataSource, MSCollectionViewDelegateCalendarLayout, UICollectionViewDataSource>

@property (nonatomic, strong) MSCollectionViewCalendarLayout *collectionViewCalendarLayout;
@property (nonatomic, strong) NSArray *allDayEvents;
@property (nonatomic, strong) NSArray *nonAllDayEvents;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) MZDayPicker *dayPicker;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *dragDateFormatter;
@property (nonatomic, strong) UIView *dragView;
@property (nonatomic, strong) UILabel *dragLabel;
@property (nonatomic, strong) NSLayoutConstraint *dragViewY;
@property (nonatomic, strong) NSLayoutConstraint *dragLabelY;
@property (nonatomic, strong) EKEventStore *eventStore;


@end

@implementation LIYDateTimePickerViewController

+ (instancetype)timePickerForDate:(NSDate *)date delegate:(id<LIYDateTimePickerDelegate>)delegate {
    LIYDateTimePickerViewController *vc = [self new];
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

- (instancetype)init {
    self = [super init];
    if (self) {
        _date = [NSDate date];
        _showDayPicker = YES;
        _allowTimeSelection = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (self.showCancelButton) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped:)];
    }
    
    self.collectionViewCalendarLayout = [[LIYCollectionViewCalendarLayout alloc] init];
    self.collectionViewCalendarLayout.hourHeight = 50.0; //TODO const
    self.collectionViewCalendarLayout.delegate = self;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.collectionViewCalendarLayout];
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    
    [self.collectionView registerClass:MSEventCell.class forCellWithReuseIdentifier:MSEventCellReuseIdentifier];
    [self.collectionView registerClass:MSDayColumnHeader.class forSupplementaryViewOfKind:MSCollectionElementKindDayColumnHeader withReuseIdentifier:MSDayColumnHeaderReuseIdentifier];
    [self.collectionView registerClass:MSTimeRowHeader.class forSupplementaryViewOfKind:MSCollectionElementKindTimeRowHeader withReuseIdentifier:MSTimeRowHeaderReuseIdentifier];

    // These are optional. If you don't want any of the decoration views, just don't register a class for them.
    [self.collectionViewCalendarLayout registerClass:MSCurrentTimeIndicator.class forDecorationViewOfKind:MSCollectionElementKindCurrentTimeIndicator];
    [self.collectionViewCalendarLayout registerClass:MSCurrentTimeGridline.class forDecorationViewOfKind:MSCollectionElementKindCurrentTimeHorizontalGridline];
    [self.collectionViewCalendarLayout registerClass:MSGridline.class forDecorationViewOfKind:MSCollectionElementKindVerticalGridline];
    [self.collectionViewCalendarLayout registerClass:MSGridline.class forDecorationViewOfKind:MSCollectionElementKindHorizontalGridline];
    [self.collectionViewCalendarLayout registerClass:MSTimeRowHeaderBackground.class forDecorationViewOfKind:MSCollectionElementKindTimeRowHeaderBackground];
    [self.collectionViewCalendarLayout registerClass:MSDayColumnHeaderBackground.class forDecorationViewOfKind:MSCollectionElementKindDayColumnHeaderBackground];

    if (self.showDayPicker) {
        self.automaticallyAdjustsScrollViewInsets = NO;
        [self createDayPicker];
    }

    [self setupConstraints];
    
    if (self.allowTimeSelection) {
        [self setupTimeSelector];
    }
    
    [self reloadEvents];
}

- (void)createDayPicker {
    self.dayPicker = [[MZDayPicker alloc] initWithFrame:CGRectZero month:9 year:2013];
    [self.view addSubview:self.dayPicker];
    
    self.dayPicker.delegate = self;
    self.dayPicker.dataSource = self;
    
    self.dayPicker.dayNameLabelFontSize = 12.0f;
    self.dayPicker.dayLabelFontSize = 18.0f;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"EE"];
    
    [self.dayPicker setStartDate:self.date endDate:[self endDate]]; // TODO create property for this value
    
    [self.dayPicker setCurrentDate:self.date animated:NO];
}

- (void)setupConstraints {
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.dayPicker.translatesAutoresizingMaskIntoConstraints = NO;

    NSObject *collectionView = self.collectionView, *dayPicker = self.dayPicker ?: [UIView new], *topLayoutGuide = self.topLayoutGuide;
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:self.showDayPicker ? @"V:[topLayoutGuide][dayPicker(64)][collectionView]|" : @"V:|[collectionView]|"
                               options:0
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(topLayoutGuide, dayPicker, collectionView)]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[collectionView]|"
                               options:0
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(collectionView)]];
    if (self.showDayPicker) {
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|[dayPicker]|"
                                   options:0
                                   metrics:nil
                                   views:NSDictionaryOfVariableBindings(dayPicker)]];
    }
}

- (void)setupTimeSelector {
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(collectionViewTapped:)];
    [self.collectionView addGestureRecognizer:self.tapGestureRecognizer];
    
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
    NSDateComponents *dateComponents = [cal components:NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.date];
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

-(NSDate *) endDate{
    return [self.date dateByAddingTimeInterval:60*60*24*14];
}


- (void)reloadEvents {
    if (![self isViewLoaded]) {
        return;
    }

    if (!self.eventStore) {
        self.eventStore = [[EKEventStore alloc] init];
    }
    EKEventStore *__weak weakEventStore = self.eventStore;
    typeof(self) __weak weakSelf = self;
    [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        EKEventStore *strongEventStore = weakEventStore;
        typeof(self) strongSelf = weakSelf;
        if (!granted) {
            return;
        }

        NSPredicate *predicate = [strongEventStore predicateForEventsWithStartDate:[strongSelf.date beginningOfDay]
                                                                           endDate:[strongSelf nextDayForDate:[strongSelf.date beginningOfDay]]
                                                                         calendars:self.visibleCalendars];
        NSArray *events = [strongEventStore eventsMatchingPredicate:predicate];
        dispatch_async(dispatch_get_main_queue(), ^{ // TODO invalidate previous block if a new one is enqueued
            NSMutableArray *nonAllDayEvents = [NSMutableArray array];
            NSMutableArray *allDayEvents = [NSMutableArray array];
            for (EKEvent *event in events) {
                if (event.isAllDay) {
                    [allDayEvents addObject:event];
                } else {
                    [nonAllDayEvents addObject:event];
                }
            }
            strongSelf.nonAllDayEvents = nonAllDayEvents;
            strongSelf.allDayEvents = allDayEvents;
            [strongSelf.collectionViewCalendarLayout invalidateLayoutCache];
            [strongSelf.collectionView reloadData];
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
    
    if (![date isEqualToDate:self.dayPicker.currentDate]){
        [self.dayPicker setStartDate:self.date endDate:[self endDate]];
        [self.dayPicker setCurrentDate:date animated:YES];

    }
    
    // clear out events immediately because reloadEvents loads events asynchronously
    self.nonAllDayEvents = [NSMutableArray array];
    self.allDayEvents = [NSMutableArray array];
    [self.collectionViewCalendarLayout invalidateLayoutCache];
    [self.collectionView reloadData];
    [self scrollToHour:6];
    
    [self reloadEvents];
}

-(void) setVisibleCalendars:(NSArray *)visibleCalendars{
    _visibleCalendars = visibleCalendars;
    [self reloadEvents];
}

- (void)setAllDayEvents:(NSMutableArray *)allDayEvents {
    _allDayEvents = allDayEvents;
    self.collectionViewCalendarLayout.dayColumnHeaderHeight = _allDayEvents.count == 0 ? 50.0f : 50.0f + kLIYAllDayHeight; // TODO don't hardcode
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
    return self.nonAllDayEvents.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MSEventCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MSEventCellReuseIdentifier forIndexPath:indexPath];
    cell.event = self.nonAllDayEvents[indexPath.row];
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

        if (self.allDayEvents.count == 0) {
            dayColumnHeader.showAllDaySection = NO;
        } else {
            dayColumnHeader.showAllDaySection = YES;
            NSArray *allDayEventTitles = [self.allDayEvents map:^id(EKEvent *event) { // TODO: compute once
                return event.title;
            }];
            dayColumnHeader.allDayEventsLabel.text = [allDayEventTitles componentsJoinedByString:@", "];
        }

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
    EKEvent *event = self.nonAllDayEvents[indexPath.item];
    NSTimeInterval startDate = [event.startDate timeIntervalSince1970];
    startDate = fmax(startDate, [[self.date beginningOfDay] timeIntervalSince1970]);
    return [NSDate dateWithTimeIntervalSince1970:startDate];
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout endTimeForItemAtIndexPath:(NSIndexPath *)indexPath {
    EKEvent *event = self.nonAllDayEvents[indexPath.item];
    NSTimeInterval endDate = [event.endDate timeIntervalSince1970];
    endDate = fmin(endDate, [[self.date endOfDay] timeIntervalSince1970]);
    NSDate *startDate = [self collectionView:self.collectionView layout:self.collectionViewCalendarLayout startTimeForItemAtIndexPath:indexPath];

    if (endDate - [startDate timeIntervalSince1970] < 15*60) {
        endDate = [startDate timeIntervalSince1970] + 15*60; // set to minimum 15 min gap
    }
    return [NSDate dateWithTimeIntervalSince1970:endDate];
}

- (NSDate *)currentTimeComponentsForCollectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout {
    return [NSDate date];
}

@end
