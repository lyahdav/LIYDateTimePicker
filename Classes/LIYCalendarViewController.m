#import "LIYCalendarViewController.h"
#import "LIYCalendarViewControllerSubclass.h"
#import "ObjectiveSugar.h"
#import "LIYCalendarPickerViewController.h"
#import "MSGridline.h"
#import "MSTimeRowHeaderBackground.h"
#import "MSEventCell.h"
#import "MSTimeRowHeader.h"
#import "MSCurrentTimeIndicator.h"
#import "MSCurrentTimeGridline.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "LIYJTCalendar.h"
#import "NSDate+CupertinoYankee.h"
#import "UIColor+HexString.h"
#import "UIView+LIYUtilities.h"
#import "PureLayout.h"
#import "LIYCalendarService.h"
#import "NSDate+LIYUtilities.h"

NSString *const MSEventCellReuseIdentifier = @"MSEventCellReuseIdentifier";
NSString *const MSDayColumnHeaderReuseIdentifier = @"MSDayColumnHeaderReuseIdentifier";
NSString *const MSTimeRowHeaderReuseIdentifier = @"MSTimeRowHeaderReuseIdentifier";

const NSUInteger LIYDefaultScrollIntervalMinutes = 15;
const CGFloat LIYDayPickerContentViewWeekHeight = 60.0f;
const CGFloat LIYDayPickerContentViewMonthHeight = 200.0f;

# pragma mark - LIYCollectionViewCalendarLayout

// TODO submit pull request to MSCollectionViewCalendarLayout so we don't need to subclass

@interface MSCollectionViewCalendarLayout (LIYExposedPrivateMethods)

- (CGFloat)zIndexForElementKind:(NSString *)elementKind floating:(BOOL)floating;

@end

@interface LIYCollectionViewCalendarLayout : MSCollectionViewCalendarLayout

@end

@implementation LIYCollectionViewCalendarLayout

#pragma mark - MSCollectionViewCalendarLayout

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"

- (NSInteger)earliestHourForSection:(NSInteger)section {
    return 0;
}

- (NSInteger)latestHourForSection:(NSInteger)section {
    return 24;
}

#pragma clang diagnostic pop

- (CGFloat)zIndexForElementKind:(NSString *)elementKind floating:(BOOL)floating {
    if (elementKind == MSCollectionElementKindCurrentTimeHorizontalGridline) {
        CGFloat MSCollectionMinCellZ = 100.0f; // from MSCollectionViewCalendarLayout.m
        return (MSCollectionMinCellZ + 10.0f);
    } else {
        return [super zIndexForElementKind:elementKind floating:floating];
    }
}

@end

#pragma mark - LIYCalendarViewController

@interface LIYCalendarViewController () <MSCollectionViewDelegateCalendarLayout, UICollectionViewDataSource, UICollectionViewDelegate, JTCalendarDataSource>

@property (nonatomic) BOOL hasScrolledToSelectedDate;
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) NSDate *dateBeforeRotation;
@property (nonatomic, strong) JTCalendarContentView *dayPickerContentView;
@property (nonatomic, strong) UIView *dayPickerContentViewContainer;
@property (nonatomic, strong) NSLayoutConstraint *dayPickerContentViewHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *dayPickerContentViewContainerHeightConstraint;

@end

@implementation LIYCalendarViewController

#pragma mark - class methods

+ (instancetype)calendarForDate:(NSDate *)date {
    LIYCalendarViewController *calendarViewController = [self new];
    if (date) {
        calendarViewController.selectedDate = date;
    }
    return calendarViewController;
}

#pragma mark - UIViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    [self setupViews];

    [self setupConstraints];

    [self setupCalendarBottomConstraint];
}

- (void)viewDidLayoutSubviews {
    [self.dayPicker repositionViews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadEvents];

    if (self.showCalendarPickerButton) {
        [self addCalendarPickerButton];
    }
    
    if (!self.hasScrolledToSelectedDate) {
        [self.view layoutIfNeeded];
        [self scrollToTime:self.selectedDate];
        self.hasScrolledToSelectedDate = YES;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.dateBeforeRotation = self.selectedDate;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self setCollectionViewSectionWidth];
    [self.collectionViewCalendarLayout invalidateLayoutCache];
    [self scrollToTime:self.dateBeforeRotation]; // required because rotation causes a scroll away from selectedDate
}

#pragma mark - public

- (void)switchToMonthPicker {
    self.dayPicker.calendarAppearance.isWeekMode = NO;
    self.dayPickerContentViewHeightConstraint.constant = self.dayPickerMonthHeight;
    [self updateDayPickerHeight];
    [self.dayPicker reloadAppearance];
}

- (void)switchToWeekPicker {
    self.dayPicker.calendarAppearance.isWeekMode = YES;
    self.dayPickerContentViewHeightConstraint.constant = self.dayPickerWeekHeight;
    [self updateDayPickerHeight];
    [self.dayPicker reloadAppearance];
}

- (void)scrollToTime:(NSDate *)dateTime {
    NSParameterAssert(dateTime != nil);

    NSDate *roundDateTime = [self nearestValidDateFromDate:dateTime];
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:roundDateTime];
    
    CGFloat minuteFactor = dateComponents.minute / 60.0f;
    CGFloat timeFactor = dateComponents.hour + minuteFactor;

    [self scrollToTimeByFactor:timeFactor];
}

- (void)calendarPickerButtonTapped {
    typeof(self) __weak weakSelf = self;
    LIYCalendarPickerViewController *calendarPickerViewController =
            [LIYCalendarPickerViewController calendarPickerWithCalendarsFromUserDefaultsWithEventStore:self.eventStore completion:^(NSArray *newSelectedCalendarIdentifiers) {
                weakSelf.visibleCalendars = [newSelectedCalendarIdentifiers map:^id(NSString *calendarIdentifier) {
                    return [weakSelf.eventStore calendarWithIdentifier:calendarIdentifier];
                }];
            }];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:calendarPickerViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - protected

- (void)commonInit {
    _scrollIntervalMinutes = LIYDefaultScrollIntervalMinutes;
    _showDayPicker = YES;
    self.selectedDate = [NSDate date]; // we use the property here to ensure we get a valid date
    _allowEventEditing = YES;
    _defaultColor1 = [UIColor colorWithHexString:@"59c7f1"];
    _defaultColor2 = [UIColor orangeColor];
    _saveButtonText = @"Save";
    _dayPickerWeekHeight = LIYDayPickerContentViewWeekHeight;
    _dayPickerMonthHeight = LIYDayPickerContentViewMonthHeight;
}

- (void)setupViews {
    [self setupCollectionView];

    [self setupDayColumnHeader];

    [self setupDayPicker];
}

- (void)setSelectedDateWithoutDayPicker:(NSDate *)selectedDateTime {
    _selectedDate = [self nearestValidDateFromDate:selectedDateTime];
}

/// y is measured where 0 is the top of the collection view (after day column header and optionally all day event view)
- (CGFloat)hourAtYCoordinate:(CGFloat)y {
    CGFloat hour = (y + self.collectionView.contentOffset.y - kLIYGapToMidnight) / self.collectionViewCalendarLayout.hourHeight;
    hour = (CGFloat)fmax(hour, 0);
    hour = (CGFloat)fmin(hour, 24);
    return hour;
}

- (void)scrollToTimeByFactor:(CGFloat)timeFactor {
    CGFloat hourAtMiddleOfCollectionView = [self hourAtYCoordinate:self.collectionView.frame.size.height / 2];
    CGFloat timeY = (timeFactor - hourAtMiddleOfCollectionView) * self.collectionViewCalendarLayout.hourHeight;
    timeY = (CGFloat)fmax(0.0f, timeY);
    CGFloat maxYOffset = self.collectionView.contentSize.height - self.collectionView.frame.size.height;
    timeY = (CGFloat)fmin(maxYOffset, timeY);
    [self.collectionView setContentOffset:CGPointMake(0, timeY) animated:NO];
}

- (void)setupCalendarBottomConstraint {
    [self.collectionView autoPinToBottomLayoutGuideOfViewController:self withInset:0];
}

#pragma mark - convenience

- (void)setupDayPicker {
    self.dayPicker = [LIYJTCalendar new];
    self.dayPicker.calendarAppearance.focusSelectedDayChangeMode = YES;
    self.dayPicker.calendarAppearance.isWeekMode = YES;
    self.dayPicker.updateSelectedDateOnSwipe = YES;

    [self.dayPicker setDataSource:self];
    [self setDayPickerDate:self.selectedDate];

    self.dayPickerContentViewContainer = [UIView new];
    [self.view addSubview:self.dayPickerContentViewContainer];

    self.dayPickerContentView = [JTCalendarContentView new];
    [self.dayPicker setContentView:self.dayPickerContentView];
    [self.dayPickerContentViewContainer addSubview:self.dayPickerContentView];

    [self.dayPicker reloadData];
}

- (void)setupCollectionView {
    self.collectionViewCalendarLayout = [[LIYCollectionViewCalendarLayout alloc] init];
    self.collectionViewCalendarLayout.dayColumnHeaderHeight = 0;
    self.collectionViewCalendarLayout.hourHeight = 50.0; //TODO const

    [self setCollectionViewSectionWidth];
    self.collectionViewCalendarLayout.delegate = self;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.collectionViewCalendarLayout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor colorWithHexString:@"#ededed"];
    [self.view addSubview:self.collectionView];

    [self.collectionView registerClass:MSEventCell.class forCellWithReuseIdentifier:MSEventCellReuseIdentifier];
    [self.collectionView registerClass:MSTimeRowHeader.class forSupplementaryViewOfKind:MSCollectionElementKindTimeRowHeader withReuseIdentifier:MSTimeRowHeaderReuseIdentifier];

    // TODO: we really don't need this, but we're required to register a class for the day column header. Maybe fork MSCollectionViewCalendarLayout to make day column
    // header optional
    [self.collectionView registerClass:MSTimeRowHeader.class forSupplementaryViewOfKind:MSCollectionElementKindDayColumnHeader withReuseIdentifier:MSDayColumnHeaderReuseIdentifier];

    // These are optional. If you don't want any of the decoration views, just don't register a class for them.
    [self.collectionViewCalendarLayout registerClass:MSCurrentTimeIndicator.class forDecorationViewOfKind:MSCollectionElementKindCurrentTimeIndicator];
    [self.collectionViewCalendarLayout registerClass:MSCurrentTimeGridline.class forDecorationViewOfKind:MSCollectionElementKindCurrentTimeHorizontalGridline];
    [self.collectionViewCalendarLayout registerClass:MSGridline.class forDecorationViewOfKind:MSCollectionElementKindVerticalGridline];
    [self.collectionViewCalendarLayout registerClass:MSGridline.class forDecorationViewOfKind:MSCollectionElementKindHorizontalGridline];
    [self.collectionViewCalendarLayout registerClass:MSTimeRowHeaderBackground.class forDecorationViewOfKind:MSCollectionElementKindTimeRowHeaderBackground];
}

- (void)setCollectionViewSectionWidth {
    self.collectionViewCalendarLayout.sectionWidth = self.view.frame.size.width - 66.0f;
}

- (void)updateDayPickerDate {
    if (![self isViewLoaded]) {
        return;
    }

    if (![self.selectedDate isSameDayAsDate:self.dayPicker.currentDateSelected]) {
        [self setDayPickerDate:self.selectedDate];

        // clear out events immediately because reloadEvents loads events asynchronously
        self.nonAllDayEvents = [NSMutableArray array];
        self.allDayEvents = [NSMutableArray array];
        [self.collectionViewCalendarLayout invalidateLayoutCache];
        [self.collectionView reloadData];
    }
}

- (void)setDayPickerDate:(NSDate *)date {
    // hack documented here: https://github.com/jonathantribouharet/JTCalendar#warning-2
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kJTCalendarDaySelected" object:date];

    [self.dayPicker setCurrentDateSelected:date];
    self.dayPicker.currentDate = date;
}

- (NSDate *)nearestValidDateFromDate:(NSDate *)date {
    CGFloat scrollIntervalSeconds = self.scrollIntervalMinutes * 60.0f;
    NSTimeInterval seconds = ceil([date timeIntervalSinceReferenceDate] / scrollIntervalSeconds) * scrollIntervalSeconds;
    NSDate *roundDateTime = [NSDate dateWithTimeIntervalSinceReferenceDate:seconds];
    return roundDateTime;
}

- (void)setupConstraints {
    [self setupDayPickerConstraints];

    [self setupDayColumnHeaderConstraints];

    [self setupCollectionViewConstraints];
}

- (void)setupDayPickerConstraints {
    [self.dayPickerContentViewContainer autoPinToTopLayoutGuideOfViewController:self withInset:0];
    [self.dayPickerContentViewContainer autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [self.dayPickerContentViewContainer autoPinEdgeToSuperviewEdge:ALEdgeTrailing];

    [self.dayPickerContentView autoPinEdgesToSuperviewEdgesWithInsets:ALEdgeInsetsZero excludingEdge:ALEdgeTop];
    self.dayPickerContentViewHeightConstraint = [self.dayPickerContentView autoSetDimension:ALDimensionHeight toSize:self.dayPickerWeekHeight];
    self.dayPickerContentViewContainerHeightConstraint = [self.dayPickerContentViewContainer autoSetDimension:ALDimensionHeight toSize:0];
    [self.dayPickerContentView enableWeekMonthPanWithMinimumHeight:self.dayPickerWeekHeight andMaximumHeight:self.dayPickerMonthHeight byUpdatingContainerHeightConstraint:self.dayPickerContentViewContainerHeightConstraint andContentViewHeightConstraint:self.dayPickerContentViewHeightConstraint];

    [self updateDayPickerHeight];
}

- (void)updateDayPickerHeight {
    if (self.showDayPicker) {
        self.dayPickerContentViewContainerHeightConstraint.constant = self.dayPickerContentViewHeightConstraint.constant;
    } else {
        self.dayPickerContentViewContainerHeightConstraint.constant = 0;
    }
    self.dayPickerContentViewContainer.hidden = !self.showDayPicker;
}

- (void)setupDayColumnHeaderConstraints {
    [self.dayColumnHeader positionInView:self.view];
    [self.dayColumnHeader autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.dayPickerContentViewContainer];
}

- (void)setupCollectionViewConstraints {
    [self.collectionView liy_pinBelowView:self.dayColumnHeader];
}

- (void)reloadEvents {
    if (![self isViewLoaded] || !self.visibleCalendars || self.visibleCalendars.count == 0) {
        self.nonAllDayEvents = @[];
        self.allDayEvents = @[];
        [self.collectionViewCalendarLayout invalidateLayoutCache];
        [self.collectionView reloadData];
        return;
    }

    typeof(self) __weak weakSelf = self;
    [[LIYCalendarService sharedInstance] eventsForDate:self.selectedDate calendars:self.visibleCalendars completion:^(NSArray *nonAllDayEvents, NSArray *allDayEvents) {
        weakSelf.nonAllDayEvents = nonAllDayEvents;
        weakSelf.allDayEvents = allDayEvents;
        [weakSelf.collectionViewCalendarLayout invalidateLayoutCache];
        [weakSelf.collectionView reloadData];
    }];
}

- (void)setVisibleCalendarsFromUserDefaults {
    typeof(self) __weak weakSelf = self;
    [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted) {
            return;
        }
        NSArray *calendarIdentifiers = [LIYCalendarPickerViewController selectedCalendarIdentifiersFromUserDefaultsForEventStore:weakSelf.eventStore];
        weakSelf.visibleCalendars = [calendarIdentifiers map:^id(NSString *calendarIdentifier) {
            return [weakSelf.eventStore calendarWithIdentifier:calendarIdentifier];
        }];
    }];
}

- (void)addCalendarPickerButton {
    if (!self.navigationController) {
        return;
    }

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Calendars" style:UIBarButtonItemStylePlain target:self action:@selector(calendarPickerButtonTapped)];
}

- (void)setupDayColumnHeader {
    self.dayColumnHeader = [MSDayColumnHeader new];
    [self.dayColumnHeader updateAllDaySectionWithEvents:self.allDayEvents];
}

# pragma mark - properties

- (EKEventStore *)eventStore {
    return [LIYCalendarService sharedInstance].eventStore;
}

- (void)setSelectedDate:(NSDate *)selectedDate {
    [self setSelectedDateWithoutDayPicker:selectedDate];

    [self updateDayPickerDate];
}

- (void)setShowDayPicker:(BOOL)showDayPicker {
    _showDayPicker = showDayPicker;
    [self updateDayPickerHeight];
}

- (void)setVisibleCalendars:(NSArray *)visibleCalendars {
    _visibleCalendars = visibleCalendars;
    if (self.isViewLoaded) {
        [self reloadEvents];
    }
}

- (void)setAllDayEvents:(NSArray *)allDayEvents {
    _allDayEvents = allDayEvents;
    [self.dayColumnHeader updateAllDaySectionWithEvents:allDayEvents];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    EKEventViewController *vc = [[EKEventViewController alloc] init];
    EKEvent *event = self.nonAllDayEvents[indexPath.row];
    vc.event = event;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF =[c] %@", event.calendar.title];
    NSArray *matchingCalendars = [self.calendarNamesToFilterForEdit filteredArrayUsingPredicate:predicate];
    vc.allowsEditing = matchingCalendars.count == 0 && self.allowEventEditing;

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
    if (indexPath.row < self.nonAllDayEvents.count) {
        cell.selectedDate = self.selectedDate;
        cell.event = self.nonAllDayEvents[indexPath.row];
        cell.showEventTimes = self.showEventTimes;
    }

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view;

    if (kind == MSCollectionElementKindDayColumnHeader) {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:MSDayColumnHeaderReuseIdentifier forIndexPath:indexPath];
    } else if (kind == MSCollectionElementKindTimeRowHeader) {
        MSTimeRowHeader *timeRowHeader = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:MSTimeRowHeaderReuseIdentifier forIndexPath:indexPath];
        timeRowHeader.time = [self.collectionViewCalendarLayout dateForTimeRowHeaderAtIndexPath:indexPath];
        view = timeRowHeader;
    }

    return view;
}

#pragma mark - MSCollectionViewCalendarLayout

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout dayForSection:(NSInteger)section {
    return self.selectedDate;
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout startTimeForItemAtIndexPath:(NSIndexPath *)indexPath {
    EKEvent *event = self.nonAllDayEvents[indexPath.item];
    NSTimeInterval startDate = [event.startDate timeIntervalSince1970];
    startDate = fmax(startDate, [[self.selectedDate beginningOfDay] timeIntervalSince1970]);
    return [NSDate dateWithTimeIntervalSince1970:startDate];
}

- (NSDate *)collectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout endTimeForItemAtIndexPath:(NSIndexPath *)indexPath {
    EKEvent *event = self.nonAllDayEvents[indexPath.item];
    NSTimeInterval endDate = [event.endDate timeIntervalSince1970];
    endDate = fmin(endDate, [[self.selectedDate endOfDay] timeIntervalSince1970]);
    NSDate *startDate = [self collectionView:self.collectionView layout:self.collectionViewCalendarLayout startTimeForItemAtIndexPath:indexPath];

    if (endDate - [startDate timeIntervalSince1970] < 15 * 60) {
        endDate = [startDate timeIntervalSince1970] + 30 * 60; // set to minimum 30 min gap
    }
    return [NSDate dateWithTimeIntervalSince1970:endDate];
}

- (NSDate *)currentTimeComponentsForCollectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout {
    return [NSDate date];
}

#pragma mark - JTCalendarDataSource

- (BOOL)calendarHaveEvent:(JTCalendar *)calendar date:(NSDate *)date {
    return [[LIYCalendarService sharedInstance] calendars:self.visibleCalendars haveEventsOnDate:date];
}

- (void)calendarDidDateSelected:(JTCalendar *)calendar date:(NSDate *)date {
    self.selectedDate = [NSDate dateFromDayDate:date timeDate:self.selectedDate];
    [self reloadEvents];
}

@end