
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
#import <EventKitUI/EventKitUI.h>
#import "NSDate+CupertinoYankee.h"
#import "UIColor+HexString.h"

NSString * const MSEventCellReuseIdentifier = @"MSEventCellReuseIdentifier";
NSString * const MSDayColumnHeaderReuseIdentifier = @"MSDayColumnHeaderReuseIdentifier";
NSString * const MSTimeRowHeaderReuseIdentifier = @"MSTimeRowHeaderReuseIdentifier";
CGFloat const kFixedTimeBuddleWidth = 120.0f;
const NSInteger kLIYDayPickerHeight = 84;
CGFloat const kLIYDefaultHeaderHeight = 56.0f;
CGFloat const kLIYDefaultSmallHeaderHeight = 0.0f;


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

@interface LIYDateTimePickerViewController () <MZDayPickerDelegate, MZDayPickerDataSource, MSCollectionViewDelegateCalendarLayout, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate>


@property (nonatomic, strong) NSArray *allDayEvents;
@property (nonatomic, strong) NSArray *nonAllDayEvents;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) MZDayPicker *dayPicker;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *dragDateFormatter;
@property (nonatomic, strong) NSDateFormatter *fixedDateFormatter;
@property (nonatomic, strong) UIView *dragView;
@property (nonatomic, strong) UILabel *dragLabel;
@property (nonatomic, strong) NSLayoutConstraint *dragViewY;
@property (nonatomic, strong) NSLayoutConstraint *dragLabelY;
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) UIView *fixedSelectedTimeLine;
@property (nonatomic, strong) UIView *fixedSelectedTimeBubble;
@property (nonatomic, strong) UILabel *fixedSelectedTimeBubbleTime;
@property (nonatomic, assign) BOOL isDoneLoading;
@property (nonatomic, assign) BOOL isChangingTime;


@end

@implementation LIYDateTimePickerViewController

+ (instancetype)timePickerForDate:(NSDate *)date delegate:(id<LIYDateTimePickerDelegate>)delegate {
    LIYDateTimePickerViewController *vc = [self new];
    vc.delegate = delegate;
    
    if (!date)
    {
        vc.date = [NSDate date];
    }else{
        vc.date = date;
        vc.selectedDate = date;
    }
    
    
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
    self.collectionViewCalendarLayout.sectionWidth = self.view.frame.size.width - 66.0f;
    self.collectionViewCalendarLayout.delegate = self;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.collectionViewCalendarLayout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor colorWithHexString:@"#ededed"];
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
    
    if (!self.defaultColor1){
        self.defaultColor1 = [UIColor colorWithHexString:@"59c7f1"];
    }
    
    if (!self.defaultColor2){
        self.defaultColor2 = [UIColor orangeColor];
    }
    
}


-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self reloadEvents];
    self.isDoneLoading = NO;
    
    if (!self.saveButtonText){
        self.saveButtonText = @"Save";
    }

}

-(void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.allowTimeSelection){
        
        [self setupFixedTimeSelector];
        
        if (!self.selectedDate){
            self.selectedDate = [self.date dateByAddingTimeInterval:60*90];
        }
        [self scrollToTime:self.selectedDate];
        [self setSelectedTimeText];

        [self updateCollectionViewContentInset];
        [self setupSaveButton];
    }else{
        [self scrollToTime:[NSDate date]];
    }
    
    
    self.isDoneLoading = YES;
    
}

// allows user to scroll to midnight at start and end of day
- (void)updateCollectionViewContentInset {
    
    if (!self.allowTimeSelection){
        return;
    }
    
    UIEdgeInsets edgeInsets = self.collectionView.contentInset;
    
    CGFloat gapToMidnight = 20.0f; // TODO should compute, this is from the start of the grid to the 12am line
    
    CGFloat yForMidnight = kLIYDayPickerHeight + self.collectionViewCalendarLayout.dayColumnHeaderHeight + gapToMidnight;
    if (self.allDayEvents.count > 0){
        yForMidnight += kLIYAllDayHeight;
    }
    
    edgeInsets.top = [self middleYForTimeLine] - yForMidnight;
    
    CGFloat endOfDayMidnightTop = kLIYDayPickerHeight + self.collectionView.frame.size.height - gapToMidnight;
    if (self.allDayEvents.count > 0){
        endOfDayMidnightTop += kLIYAllDayHeight;
    }
    edgeInsets.bottom = endOfDayMidnightTop - [self middleYForTimeLine];
    self.collectionView.contentInset = edgeInsets;
}

#pragma mark - Actions
-(void) saveButtonTapped{
    [self.delegate dateTimePicker:self didSelectDate:self.selectedDate];
}

#pragma mark - Convenience

-(void) setSelectedDateFromLocation{
    CGFloat buffer = 12.0f; // TODO what's this buffer for? give a better variable name
    self.selectedDate = [self dateFromYCoord:(buffer + self.collectionView.contentOffset.y + (self.collectionView.frame.size.height / 2))];
}

-(void) setSelectedTimeText{
    
    self.fixedSelectedTimeBubbleTime.text = [self.fixedDateFormatter stringFromDate:self.selectedDate];
    
    if (self.allowTimeSelection){
        
        [self.dayColumnHeader setDay:self.selectedDate];
    }
}

-(void) setupSaveButton{
    UIButton *saveButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height - 44.0f, self.view.frame.size.width, 44.0f)];
    [saveButton addTarget:self action:@selector(saveButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    saveButton.backgroundColor = self.defaultColor2;
    [saveButton setTitle:self.saveButtonText forState:UIControlStateNormal];
    saveButton.titleLabel.textColor = [UIColor whiteColor];
    saveButton.titleLabel.font = [UIFont fontWithName:self.defaultFontFamilyName size:18.0f];
    
    [self.view addSubview:saveButton];
    
}

- (CGFloat)middleYForTimeLine {
    CGFloat buffer = 40.0f; // TODO what is this buffer? give it a better name
    return buffer + self.collectionViewCalendarLayout.dayColumnHeaderHeight + (self.collectionView.frame.size.height / 2);
}

-(void) setupFixedTimeSelector{
    
    if (self.allowTimeSelection){
        
        CGFloat middleY = [self middleYForTimeLine];
        
        
        if (!self.fixedDateFormatter)
        {
            // floating bubble and line
            self.fixedDateFormatter = [[NSDateFormatter alloc] init];
            [self.fixedDateFormatter setDateFormat:@"h:mm a"];
            
            
            self.fixedSelectedTimeLine = [[UIView alloc] init]; //]WithFrame:CGRectMake(0.0f,  middleY, self.collectionView.frame.size.width, 1.0f)];
            self.fixedSelectedTimeLine.backgroundColor = [UIColor colorWithRed:0.0f green:0.5f blue:1.0f alpha:.2f];
            self.fixedSelectedTimeLine.backgroundColor = self.defaultColor1;
            
            [self.view addSubview:self.fixedSelectedTimeLine];
            
            self.fixedSelectedTimeBubble = [[UIView alloc] init];//WithFrame:CGRectMake(0.0f, middleY, 120.0f, 30.0f)];
            self.fixedSelectedTimeBubble.backgroundColor = [UIColor redColor];
            self.fixedSelectedTimeBubble.layer.cornerRadius = 15.0f;
            [self.fixedSelectedTimeBubble.layer masksToBounds];
            self.fixedSelectedTimeBubble.center = CGPointMake(self.view.frame.size.width / 2, middleY);
            self.fixedSelectedTimeBubble.layer.borderColor = [UIColor colorWithHexString:@"353535"].CGColor;
            self.fixedSelectedTimeBubble.layer.borderWidth = 1.0f;
            self.fixedSelectedTimeBubble.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
            [self.view addSubview:self.fixedSelectedTimeBubble];
            
            self.fixedSelectedTimeBubbleTime = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 120.0f, 30.0f)];
            self.fixedSelectedTimeBubbleTime.textAlignment = NSTextAlignmentCenter;
            
            self.fixedSelectedTimeBubbleTime.textColor = self.defaultColor1;
            
            self.fixedSelectedTimeBubbleTime.font = [UIFont boldSystemFontOfSize:18.0f];
            if (self.defaultFontFamilyName){
                self.fixedSelectedTimeBubbleTime.font = [UIFont fontWithName:self.defaultFontFamilyName size:18.0f];
            }
            
            [self.fixedSelectedTimeBubble addSubview:self.fixedSelectedTimeBubbleTime];
            
            self.fixedSelectedTimeLine.frame = CGRectMake(0.0f,  middleY, self.collectionView.frame.size.width, 1.0f);
            self.fixedSelectedTimeBubble.frame = CGRectMake(0.0f, middleY, 120.0f, 30.0f);
            self.fixedSelectedTimeBubble.center = CGPointMake(self.view.frame.size.width / 2, middleY);
        }
        
    }
    
}

-(void) scrollToTime:(NSDate *) dateTime{
    self.isChangingTime = YES;
    
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:dateTime];
    
    float minuteFactor = dateComponents.minute / 60.0f;
    float timeFactor = dateComponents.hour + minuteFactor;
    CGFloat topInset = self.collectionView.contentInset.top;
    CGFloat timeY = (timeFactor * self.collectionViewCalendarLayout.hourHeight) - topInset;
    [self.collectionView setContentOffset:CGPointMake(0, timeY) animated:YES];
    
    self.isChangingTime = NO;
}


- (void)createDayPicker {
    self.dayPicker = [[MZDayPicker alloc] initWithFrame:CGRectZero month:9 year:2013];
    [self.view addSubview:self.dayPicker];
    
    self.dayPicker.delegate = self;
    self.dayPicker.dataSource = self;
    
    self.dayPicker.dayNameLabelFontSize = 10.0f;
    self.dayPicker.dayLabelFontSize = 16.0f;
    self.dayPicker.dayLabelFont = self.defaultFontFamilyName;
    self.dayPicker.dayNameLabelFont = self.defaultFontFamilyName;
    self.dayPicker.dayLabelFont = self.defaultFontFamilyName;
    self.dayPicker.daySelectedFont = self.defaultSelectedFontFamilyName;
    self.dayPicker.selectedDayColor = self.defaultColor1;
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"EE"];
    
    [self.dayPicker setStartDate:self.date endDate:[self endDate]]; // TODO create property for this value
    
    [self.dayPicker setCurrentDate:self.date animated:NO];
    
    self.dayPicker.currentDayHighlightColor = self.defaultColor2;
    self.dayPicker.selectedDayColor = self.defaultColor1;
}

- (void)setupConstraints {
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.dayPicker.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSObject *collectionView = self.collectionView, *dayPicker = self.dayPicker ?: [UIView new], *topLayoutGuide = self.topLayoutGuide;
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:self.showDayPicker ? [NSString stringWithFormat:@"V:[topLayoutGuide][dayPicker(%ld)][collectionView]|", (long)kLIYDayPickerHeight] : @"V:|[collectionView]|"
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
    if (self.defaultFontFamilyName){
        self.dragLabel.font = [UIFont fontWithName:self.defaultFontFamilyName size:10.0f];
    }
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

-(NSDate *) combineDateAndTime:(NSDate *) dateForDay timeDate:(NSDate *) dateForTime{
    
    NSDateComponents *timeComps = [[NSCalendar currentCalendar] components:(NSCalendarUnitMinute | NSCalendarUnitHour) fromDate:dateForTime];
    NSDateComponents *dateComps = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear) fromDate:dateForDay];
    
    dateComps.hour = timeComps.hour;
    dateComps.minute = timeComps.minute;
    
    NSDate *toReturn = [[NSCalendar currentCalendar] dateFromComponents:dateComps];
    return toReturn;
    
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
    if (![self isViewLoaded] || !self.visibleCalendars || self.visibleCalendars.count == 0) {
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
                                                                         calendars:strongSelf.visibleCalendars];
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



#pragma mark - UIScrollViewDelegate
-(void) scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (self.allowTimeSelection && self.isDoneLoading && !self.isChangingTime) {
        [self setSelectedDateFromLocation];
        [self setSelectedTimeText];
    }
}



# pragma mark - properties

- (void)setDate:(NSDate *)date {
    _date = date;
    
    if (self.dayPicker.currentDate && ![date isSameDayAsDate:self.dayPicker.currentDate])
    {
        [self.dayPicker setStartDate:self.date endDate:[self endDate]];
        [self.dayPicker setCurrentDate:date animated:YES];
        
    }
    
    // clear out events immediately because reloadEvents loads events asynchronously
    self.nonAllDayEvents = [NSMutableArray array];
    self.allDayEvents = [NSMutableArray array];
    [self.collectionViewCalendarLayout invalidateLayoutCache];
    [self.collectionView reloadData];
}

-(void) setVisibleCalendars:(NSArray *)visibleCalendars{
    _visibleCalendars = visibleCalendars;
}

- (void)setAllDayEvents:(NSMutableArray *)allDayEvents {
    _allDayEvents = allDayEvents;
    
    if (self.allowTimeSelection){
        self.collectionViewCalendarLayout.dayColumnHeaderHeight = _allDayEvents.count == 0.0f ? kLIYDefaultHeaderHeight : kLIYDefaultHeaderHeight + kLIYAllDayHeight;
    }else{
        self.collectionViewCalendarLayout.dayColumnHeaderHeight = _allDayEvents.count == kLIYDefaultSmallHeaderHeight ? kLIYDefaultSmallHeaderHeight : kLIYAllDayHeight;
    }
    
    self.dayColumnHeader.heightForHeader = self.collectionViewCalendarLayout.dayColumnHeaderHeight;
    
    [self updateCollectionViewContentInset];
}

#pragma mark - MZDayPickerDataSource

- (NSString *)dayPicker:(MZDayPicker *)dayPicker titleForCellDayNameLabelInDay:(MZDay *)day {
    return [self.dateFormatter stringFromDate:day.date];
}

#pragma mark - MZDayPickerDelegate

- (void)dayPicker:(MZDayPicker *)dayPicker didSelectDay:(MZDay *)day
{
    NSDate *timeDate = self.date;
    if (self.selectedDate){
        timeDate = self.selectedDate;
    }
    
    self.date = [self combineDateAndTime:day.date timeDate:timeDate];
    self.selectedDate = self.date;
    
    [self reloadEvents];
}




#pragma mark - UICollectionViewDelegate
-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    EKEventViewController *vc = [[EKEventViewController alloc] init];
    EKEvent *event = self.nonAllDayEvents[indexPath.row];
    vc.event = event;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF =[c] %@", event.calendar.title];
    NSArray *matchingCalendars = [self.calendarNamesToFilterForEdit filteredArrayUsingPredicate:predicate];
    if (matchingCalendars.count == 0){
        [vc setAllowsEditing:YES];
    }
    
    [self.navigationController pushViewController:vc animated:YES];
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
    
    // this is a safety check since we were seeing a crash here. not sure how this would happen.
    if (indexPath.row < self.nonAllDayEvents.count){
        cell.event = self.nonAllDayEvents[indexPath.row];
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view;

        if (kind == MSCollectionElementKindDayColumnHeader) {
            
            self.dayColumnHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:MSDayColumnHeaderReuseIdentifier forIndexPath:indexPath];
        
        
            if (self.allowTimeSelection)
            {
                self.dayColumnHeader.defaultFontFamilyName = self.defaultFontFamilyName;
                
                NSDate *day = [self.collectionViewCalendarLayout dateForDayColumnHeaderAtIndexPath:indexPath];
                NSDate *currentDay = [self currentTimeComponentsForCollectionView:self.collectionView layout:self.collectionViewCalendarLayout];
                
                self.dayColumnHeader.showTimeInHeader = self.allowTimeSelection;
                self.dayColumnHeader.day = [self combineDateAndTime:day timeDate:self.date];
                self.dayColumnHeader.currentDay = [[day beginningOfDay] isEqualToDate:[currentDay beginningOfDay]];
                self.dayColumnHeader.dayTitlePrefix = self.dayTitlePrefix;
            }

            if (self.allDayEvents.count == 0) {
                self.dayColumnHeader.showAllDaySection = NO;
            } else {
                self.dayColumnHeader.showAllDaySection = YES;
                NSArray *allDayEventTitles = [self.allDayEvents map:^id(EKEvent *event) { // TODO: compute once
                    return event.title;
                }];
                self.dayColumnHeader.allDayEventsLabel.text = [allDayEventTitles componentsJoinedByString:@", "];
            }
            
            view = self.dayColumnHeader;

            
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
