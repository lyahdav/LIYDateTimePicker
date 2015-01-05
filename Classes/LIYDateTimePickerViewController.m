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
#import "MSGenericTimeLabel.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "NSDate+CupertinoYankee.h"
#import "UIColor+HexString.h"

NSString * const MSEventCellReuseIdentifier = @"MSEventCellReuseIdentifier";
NSString * const MSDayColumnHeaderReuseIdentifier = @"MSDayColumnHeaderReuseIdentifier";
NSString * const MSTimeRowHeaderReuseIdentifier = @"MSTimeRowHeaderReuseIdentifier";
NSString * const MSNewEventTimeLabelReuseIdentifier = @"MSNewEventTimeLabelReuseIdentifier";
CGFloat const kFixedTimeBuddleWidth = 120.0f;
const NSInteger kLIYDayPickerHeight = 84;
CGFloat const kLIYGapToMidnight = 20.0f; // TODO should compute, this is from the start of the grid to the 12am line
CGFloat const kLIYDefaultHeaderHeight = 56.0f;
NSInteger const kLIYScrollIntervalSeconds = 5 * 60;

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
@property (nonatomic, strong) MZDayPicker *dayPicker;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *fixedDateFormatter;
@property (nonatomic, strong) NSDateFormatter *dragEventDateFormatter;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) UIView *fixedSelectedTimeLine;
@property (nonatomic, strong) UIView *fixedSelectedTimeBubble;
@property (nonatomic, strong) UILabel *fixedSelectedTimeBubbleTime;
@property (nonatomic, assign) BOOL isDoneLoading;
@property (nonatomic, assign) BOOL isChangingTime;
@property (nonatomic, assign) BOOL isDraggingToSetEventStartDate;
@property (nonatomic, assign) BOOL isDraggingToSetEventEndDate;
@property (nonatomic, assign) BOOL needToSetEventEndDate;
@property (nonatomic, strong) EKEvent *eventToCreate;

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

- (void)cancelTapped:(id)sender {
    [self.delegate dateTimePicker:self didSelectDate:nil];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setDefaults];
    }
    return self;
}

- (void)setDefaults {
    _date = [NSDate date];
    _showDayPicker = YES;
    _allowTimeSelection = YES;
    _defaultColor1 = [UIColor colorWithHexString:@"59c7f1"];
    _defaultColor2 = [UIColor orangeColor];
    _saveButtonText = @"Save";
    _fixedDateFormatter = [[NSDateFormatter alloc] init];
    [_fixedDateFormatter setDateFormat:@"h:mm a"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setDefaults];
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
    [self.collectionView registerClass:MSGenericTimeLabel.class forSupplementaryViewOfKind:MSCollectionElementKindNewEventTimeIndicator withReuseIdentifier:MSNewEventTimeLabelReuseIdentifier];
    
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
    
    if (self.allowTimeSelection) {
        [self setupSaveButton];
    }
    
    [self setupConstraints];
    
    if (self.allowTimeSelection) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarFrame) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    }
    
    if (self.allowEventCreation) {
        [self setUpEventCreation];
    }
}

- (void)dealloc {
    if (self.allowTimeSelection) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)didChangeStatusBarFrame {
    [self updateCollectionViewContentInset];
    [self positionTimeLine];
    if (self.selectedDate) {
        [self scrollToTime:self.selectedDate];
    }
}

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self reloadEvents];
    self.isDoneLoading = NO;
}

-(void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.allowTimeSelection){
        
        [self setupFixedTimeSelector];
        
        if (!self.selectedDate){
            self.selectedDate = [self.date dateByAddingTimeInterval:60*90];
        }
        
        [self updateCollectionViewContentInset];
        
        [self scrollToTime:self.selectedDate];
    }else{
        [self scrollToTime:[NSDate date]];
    }
    
    
    self.isDoneLoading = YES;
    
}

// allows user to scroll to midnight at start and end of day
- (void)updateCollectionViewContentInset {
    if (!self.allowTimeSelection) {
        return;
    }
    if (self.collectionView == nil) {
        return;
    }
    
    UIEdgeInsets edgeInsets = self.collectionView.contentInset;
    
    CGFloat viewControllerTopToMidnightBeginningOfDay = [self statusBarHeight] + [self navBarHeight] + kLIYDayPickerHeight + self.collectionViewCalendarLayout.dayColumnHeaderHeight + kLIYGapToMidnight;
    
    edgeInsets.top = [self middleYForTimeLine] - viewControllerTopToMidnightBeginningOfDay;
    
    CGFloat viewControllerTopToEndOfDayMidnightTop = [self statusBarHeight] + [self navBarHeight] + kLIYDayPickerHeight + self.collectionView.frame.size.height - kLIYGapToMidnight;
    edgeInsets.bottom = viewControllerTopToEndOfDayMidnightTop - [self middleYForTimeLine];
    self.collectionView.contentInset = edgeInsets;
}

#pragma mark - Actions
-(void) saveButtonTapped{
    [self.delegate dateTimePicker:self didSelectDate:self.selectedDate];
}

#pragma mark - Convenience

- (void)setUpEventCreation {
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
    [self.collectionView addGestureRecognizer:longPressRecognizer];
}

- (IBAction)onLongPress:(UILongPressGestureRecognizer *)recognizer {
    CGFloat y = [recognizer locationInView:self.collectionView].y;
    // adjust y per interface of dateFromYCoord:
    y = y - self.collectionView.contentOffset.y - self.collectionViewCalendarLayout.dayColumnHeaderHeight;
    NSDate *dateAtDrag = [self dateFromYCoord:y];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (self.needToSetEventEndDate) {
            self.isDraggingToSetEventEndDate = YES;
        } else {
            self.isDraggingToSetEventStartDate = YES;
            self.eventToCreate = [EKEvent eventWithEventStore:self.eventStore];
            self.eventToCreate.calendar = self.eventStore.defaultCalendarForNewEvents;
            self.eventToCreate.startDate = dateAtDrag;
            self.eventToCreate.endDate = [dateAtDrag dateByAddingTimeInterval:60*60];
            self.eventToCreate.title = [self titleForDragEvent];
            [self.collectionViewCalendarLayout invalidateLayoutCache];
            [self.collectionView reloadData];
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.needToSetEventEndDate) {
            self.isDraggingToSetEventEndDate = NO;
            self.needToSetEventEndDate = NO;
            NSError *error = nil;
            [self.eventStore saveEvent:self.eventToCreate span:EKSpanThisEvent error:&error];
            NSAssert(error == nil, @"Error saving event: %@", error);
            [self reloadEvents];
        } else {
            self.isDraggingToSetEventStartDate = NO;
            self.needToSetEventEndDate = YES;
            [self.collectionViewCalendarLayout invalidateLayoutCache];
            [self.collectionView reloadData];
        }
    } else {
        if (self.isDraggingToSetEventStartDate) {
            self.eventToCreate.startDate = dateAtDrag;
            self.eventToCreate.endDate = [dateAtDrag dateByAddingTimeInterval:60*60];
            self.eventToCreate.title = [self titleForDragEvent];
            [self.collectionViewCalendarLayout invalidateLayoutCache];
            [self.collectionView reloadData];
        } else {
            NSAssert(self.isDraggingToSetEventEndDate, @"expected to be dragging to set end date");
            self.eventToCreate.endDate = dateAtDrag;
            self.eventToCreate.title = [self titleForDragEvent];
            [self.collectionViewCalendarLayout invalidateLayoutCache];
            [self.collectionView reloadData];
        }
    }
}

- (NSString *)titleForDragEvent {
    NSTimeInterval interval = [self.eventToCreate.endDate timeIntervalSinceDate:self.eventToCreate.startDate];
    NSInteger minutes = interval / 60;
    NSInteger remainingMinutes = minutes % 60;
    NSInteger hours = interval / 3600;
    return [NSString stringWithFormat:@"New Event: %@ - %@ (%02ld:%02ld)", [self.dragEventDateFormatter stringFromDate:self.eventToCreate.startDate], [self.dragEventDateFormatter stringFromDate:self.eventToCreate.endDate], hours, remainingMinutes];
}

- (void)setSelectedDateFromLocation {
    CGFloat topOfViewControllerToStartOfGrid = [self statusBarHeight] + [self navBarHeight] + kLIYDayPickerHeight + self.collectionViewCalendarLayout.dayColumnHeaderHeight;
    self.selectedDate = [self dateFromYCoord:[self middleYForTimeLine] - topOfViewControllerToStartOfGrid];
}

- (void)setSelectedDate:(NSDate *)selectedDate {
    _selectedDate = selectedDate;
    [self setSelectedTimeText];
}

-(void) setSelectedTimeText{
    NSString *dateString = [self.fixedDateFormatter stringFromDate:self.selectedDate];
    self.fixedSelectedTimeBubbleTime.text = dateString;
    
    if (self.allowTimeSelection){
        
        [self.dayColumnHeader setDay:self.selectedDate];
    }
}

- (void)setupSaveButton {
    self.saveButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.saveButton addTarget:self action:@selector(saveButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.saveButton.backgroundColor = self.defaultColor2;
    [self.saveButton setTitle:self.saveButtonText forState:UIControlStateNormal];
    self.saveButton.titleLabel.textColor = [UIColor whiteColor];
    self.saveButton.titleLabel.font = [UIFont fontWithName:self.defaultFontFamilyName size:18.0f];
    self.saveButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:self.saveButton];
    
}

// From the top of the view controller (top of screen because it goes under status bar) to the line for the selected time
- (CGFloat)middleYForTimeLine {
    CGFloat collectionViewHeight = self.collectionView.frame.size.height;
    return [self statusBarHeight] + [self navBarHeight] + kLIYDayPickerHeight + (collectionViewHeight / 2);
}

- (CGFloat)statusBarHeight {
    return self.navigationController.navigationBar.translucent ? 20.0f : 0.0f; // we have to use 20 always here regardless of if status bar height changes in call. Probably could fix if we use autolayout instead of frames.
}

- (CGFloat)navBarHeight {
    return self.navigationController.navigationBar.translucent ? 44.0f : 0.0f; // TODO can we get this programmatically?
}

-(void) setupFixedTimeSelector{
    
    if (self.allowTimeSelection){
        if (!self.fixedSelectedTimeLine)
        {
            // floating bubble and line
            self.fixedSelectedTimeLine = [[UIView alloc] init];
            self.fixedSelectedTimeLine.backgroundColor = [UIColor colorWithRed:0.0f green:0.5f blue:1.0f alpha:.2f];
            self.fixedSelectedTimeLine.backgroundColor = self.defaultColor1;
            
            [self.view addSubview:self.fixedSelectedTimeLine];
            
            self.fixedSelectedTimeBubble = [[UIView alloc] init];
            self.fixedSelectedTimeBubble.backgroundColor = [UIColor redColor];
            self.fixedSelectedTimeBubble.layer.cornerRadius = 15.0f;
            [self.fixedSelectedTimeBubble.layer masksToBounds];
            self.fixedSelectedTimeBubble.layer.borderColor = [UIColor colorWithHexString:@"353535"].CGColor;
            self.fixedSelectedTimeBubble.layer.borderWidth = 1.0f;
            self.fixedSelectedTimeBubble.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
            [self.view addSubview:self.fixedSelectedTimeBubble];
            
            self.fixedSelectedTimeBubbleTime = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 120.0f, 30.0f)];
            self.fixedSelectedTimeBubbleTime.textAlignment = NSTextAlignmentCenter;
            self.fixedSelectedTimeBubbleTime.textColor = self.defaultColor1;
            [self setSelectedTimeText];
            
            self.fixedSelectedTimeBubbleTime.font = [UIFont boldSystemFontOfSize:18.0f];
            if (self.defaultFontFamilyName){
                self.fixedSelectedTimeBubbleTime.font = [UIFont fontWithName:self.defaultFontFamilyName size:18.0f];
            }
            
            [self.fixedSelectedTimeBubble addSubview:self.fixedSelectedTimeBubbleTime];
            
            [self positionTimeLine];
        }
    }
    
}

- (void)positionTimeLine {
    CGFloat middleY = [self middleYForTimeLine];
    self.fixedSelectedTimeLine.frame = CGRectMake(0.0f, middleY, self.collectionView.frame.size.width, 1.0f);
    self.fixedSelectedTimeBubble.frame = CGRectMake(0.0f, middleY, 120.0f, 30.0f);
    self.fixedSelectedTimeBubble.center = CGPointMake(self.view.frame.size.width / 2, middleY);
}

- (void)scrollToTime:(NSDate *)dateTime {
    self.isChangingTime = YES;
    
    NSTimeInterval seconds = ceil([dateTime timeIntervalSinceReferenceDate]/kLIYScrollIntervalSeconds)*kLIYScrollIntervalSeconds;
    NSDate *roundDateTime = [NSDate dateWithTimeIntervalSinceReferenceDate:seconds];
    
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:roundDateTime];
    
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
    
    NSObject *collectionView = self.collectionView, *dayPicker = self.dayPicker ?: [UIView new], *topLayoutGuide = self.topLayoutGuide, *bottomLayoutGuide = self.bottomLayoutGuide, *saveButton = self.saveButton ?: [UIView new];
    CGFloat saveButtonHeight = 44.0f;
    // [showDayPicker, showSaveButton]
    NSDictionary *constraints =
    @{
      @[@YES, @YES] : [NSString stringWithFormat:@"V:[topLayoutGuide][dayPicker(%ld)][collectionView][saveButton(%f)][bottomLayoutGuide]", (long)kLIYDayPickerHeight, saveButtonHeight],
      @[@YES, @NO] : [NSString stringWithFormat:@"V:[topLayoutGuide][dayPicker(%ld)][collectionView][bottomLayoutGuide]", (long)kLIYDayPickerHeight],
      @[@NO, @YES] : [NSString stringWithFormat:@"V:[topLayoutGuide][collectionView][saveButton(%f)][bottomLayoutGuide]", saveButtonHeight],
      @[@NO, @NO] : @"V:[topLayoutGuide][collectionView][bottomLayoutGuide]"
      };
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:constraints[@[@(self.showDayPicker), @(self.saveButton != nil)]]
                               options:0
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(topLayoutGuide, dayPicker, collectionView, saveButton, bottomLayoutGuide)]];
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
    
    if (self.saveButton) {
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|[saveButton]|"
                                   options:0
                                   metrics:nil
                                   views:NSDictionaryOfVariableBindings(saveButton)]];
    }
}

/// y is measured where 0 is the top of the collection view (after day column header and optionally all day event view)
- (NSDate *)dateFromYCoord:(CGFloat)y {
    NSInteger secondsInHour = 60*60;
    NSInteger intervalsPerHour = secondsInHour / kLIYScrollIntervalSeconds;
    CGFloat hour = round([self hourAtYCoord:y] * intervalsPerHour) / intervalsPerHour;
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [cal components:NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.date];
    dateComponents.hour = trunc(hour);
    dateComponents.minute = round((hour - trunc(hour)) * 60);
    NSDate *selectedDate = [cal dateFromComponents:dateComponents];
    return selectedDate;
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

/// y is measured where 0 is the top of the collection view (after day column header and optionally all day event view)
- (CGFloat)hourAtYCoord:(CGFloat)y {
    CGFloat hour = (y + self.collectionView.contentOffset.y - kLIYGapToMidnight) / self.collectionViewCalendarLayout.hourHeight;
    hour = fmax(hour, 0);
    hour = fmin(hour, 24);
    return hour;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.allowTimeSelection && self.isDoneLoading && !self.isChangingTime) {
        [self setSelectedDateFromLocation];
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
    self.collectionViewCalendarLayout.dayColumnHeaderHeight = _allDayEvents.count == 0 ? kLIYDefaultHeaderHeight : kLIYDefaultHeaderHeight + kLIYAllDayHeight;
    
    self.dayColumnHeader.heightForHeader = self.collectionViewCalendarLayout.dayColumnHeaderHeight;
    
    [self updateCollectionViewContentInset];
    if (self.selectedDate && self.allowTimeSelection) {
        [self scrollToTime:self.selectedDate]; // it's possible the scroll changed when all day now shows
    }
}

- (NSDateFormatter *)dragEventDateFormatter {
    if (_dragEventDateFormatter == nil) {
        _dragEventDateFormatter = [NSDateFormatter new];
        _dragEventDateFormatter.dateFormat = @"h:mm aaa";
    }
    
    return _dragEventDateFormatter;
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
    NSInteger countForCreateEventDrag = (NSInteger)self.isDraggingToSetEventStartDate + (NSInteger)self.needToSetEventEndDate;
    return self.nonAllDayEvents.count + countForCreateEventDrag;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MSEventCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MSEventCellReuseIdentifier forIndexPath:indexPath];
    
    if (indexPath.row < self.nonAllDayEvents.count) {
        cell.event = self.nonAllDayEvents[indexPath.row];
    } else {
        NSAssert(self.isDraggingToSetEventStartDate || self.needToSetEventEndDate, @"Must be dragging to create an event");
        cell.event = self.eventToCreate;
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view;
    
    if (kind == MSCollectionElementKindDayColumnHeader) {
        self.dayColumnHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:MSDayColumnHeaderReuseIdentifier forIndexPath:indexPath];
        self.dayColumnHeader.defaultFontFamilyName = self.defaultFontFamilyName;
        
        NSDate *day = [self.collectionViewCalendarLayout dateForDayColumnHeaderAtIndexPath:indexPath];
        NSDate *currentDay = [self currentTimeComponentsForCollectionView:self.collectionView layout:self.collectionViewCalendarLayout];
        
        self.dayColumnHeader.showTimeInHeader = self.allowTimeSelection;
        self.dayColumnHeader.day = [self combineDateAndTime:day timeDate:self.date];
        self.dayColumnHeader.currentDay = [[day beginningOfDay] isEqualToDate:[currentDay beginningOfDay]];
        self.dayColumnHeader.dayTitlePrefix = self.dayTitlePrefix;
        
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
    } else if (kind == MSCollectionElementKindNewEventTimeIndicator) {
        MSGenericTimeLabel *timeLabel = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:MSNewEventTimeLabelReuseIdentifier forIndexPath:indexPath];
        timeLabel.time = [NSDate dateWithTimeIntervalSinceNow:60*60];
        timeLabel.title.textColor = [UIColor redColor];
        [self setFrame];
        view = timeLabel;
    }
    
    return view;
}

// TODO rename
- (void)setFrame {
    if (self.eventToCreate == nil) {
        return;
    }
    NSIndexPath *newEventTimeIndicatorIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    UICollectionViewLayoutAttributes *draggingEventTimeIndicatorAttributes = [self.collectionViewCalendarLayout layoutAttributesForSupplementaryViewAtIndexPath:newEventTimeIndicatorIndexPath ofKind:MSCollectionElementKindNewEventTimeIndicator withItemCache:self.collectionViewCalendarLayout.draggingEventTimeIndicatorAttributes];
    
    NSDate *newEventStartDate = self.eventToCreate.startDate;
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:newEventStartDate];
    
    CGFloat calendarGridMinY = (self.collectionViewCalendarLayout.dayColumnHeaderHeight + self.collectionViewCalendarLayout.contentMargin.top);
    // The y value of the event we're dragging
    CGFloat timeY = (calendarGridMinY + nearbyintf(((dateComponents.hour - [self.collectionViewCalendarLayout earliestHour]) * self.collectionViewCalendarLayout.hourHeight) + (dateComponents.minute * self.collectionViewCalendarLayout.minuteHeight)));
    
    CGFloat currentTimeIndicatorMinY = (timeY - nearbyintf(self.collectionViewCalendarLayout.currentTimeIndicatorSize.height / 2.0));
    CGFloat currentTimeIndicatorMinX = (self.collectionViewCalendarLayout.timeRowHeaderWidth - self.collectionViewCalendarLayout.currentTimeIndicatorSize.width);
    draggingEventTimeIndicatorAttributes.frame = (CGRect){{currentTimeIndicatorMinX, currentTimeIndicatorMinY}, self.collectionViewCalendarLayout.currentTimeIndicatorSize};
}

#pragma mark - MSCollectionViewCalendarLayout

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout dayForSection:(NSInteger)section {
    return self.date;
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout startTimeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((self.isDraggingToSetEventStartDate || self.needToSetEventEndDate) && indexPath.item >= self.nonAllDayEvents.count) {
        return self.eventToCreate.startDate;
    }

    EKEvent *event = self.nonAllDayEvents[indexPath.item];
    NSTimeInterval startDate = [event.startDate timeIntervalSince1970];
    startDate = fmax(startDate, [[self.date beginningOfDay] timeIntervalSince1970]); // show events that start before midnight as starting at midnight
    return [NSDate dateWithTimeIntervalSince1970:startDate];
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout endTimeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ((self.isDraggingToSetEventStartDate || self.needToSetEventEndDate) && indexPath.item >= self.nonAllDayEvents.count) {
        return self.eventToCreate.endDate;
    }

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