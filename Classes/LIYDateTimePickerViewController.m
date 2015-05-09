#import "LIYDateTimePickerViewController.h"
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
#import "NSDate+CupertinoYankee.h"
#import "UIColor+HexString.h"
#import "LIYTimeDisplayLine.h"
#import "LIYRelativeTimePicker.h"
#import "ALView+PureLayout.h"
#import "LIYCalendarService.h"

NSString *const MSEventCellReuseIdentifier = @"MSEventCellReuseIdentifier";
NSString *const MSDayColumnHeaderReuseIdentifier = @"MSDayColumnHeaderReuseIdentifier";
NSString *const MSTimeRowHeaderReuseIdentifier = @"MSTimeRowHeaderReuseIdentifier";
const NSInteger kLIYDayPickerHeight = 84;
const CGFloat kLIYGapToMidnight = 20.0f; // TODO should compute, this is from the start of the grid to the 12am line
const NSUInteger LIYDefaultScrollIntervalMinutes = 15;
const CGFloat LIYSaveButtonHeight = 44.0f;

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

#pragma mark - NSDate (LIYAdditional)

// TODO: this shouldn't be necessary as it's defined in MZDayPicker.h, but it's required for `pod lib lint` to succeed. Figure out how to fix that.
@implementation NSDate (LIYAdditional)

- (BOOL)isSameDayAsDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];

    NSCalendarUnit unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *comp1 = [calendar components:unitFlags fromDate:self];
    NSDateComponents *comp2 = [calendar components:unitFlags fromDate:date];

    return [comp1 day] == [comp2 day] &&
            [comp1 month] == [comp2 month] &&
            [comp1 year] == [comp2 year];
}
@end

#pragma mark - LIYDateTimePickerViewController

@interface LIYDateTimePickerViewController () <MZDayPickerDelegate, MZDayPickerDataSource, MSCollectionViewDelegateCalendarLayout, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) NSArray *allDayEvents;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) LIYTimeDisplayLine *timeDisplayLine;
@property (nonatomic) BOOL viewHasAppeared;
@property (nonatomic, strong) NSDate *dateBeforeRotation;
@property (nonatomic, strong) UIView *relativeTimePickerContainer;
@property (nonatomic, strong) UIView *dayPickerContainer;
@property (nonatomic, strong) UIView *saveButtonContainer;
@property (nonatomic, strong) NSLayoutConstraint *relativeTimePickerHeightConstraint;

@end

@implementation LIYDateTimePickerViewController

#pragma mark - class methods

+ (instancetype)timePickerForDate:(NSDate *)date delegate:(id <LIYDateTimePickerDelegate>)delegate {
    LIYDateTimePickerViewController *vc = [self new];
    vc.delegate = delegate;

    vc.date = date ?: [NSDate date];
    vc.selectedDate = vc.date;

    return vc;
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

    if (self.showCancelButton) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped:)];
    }

    [self setupCollectionView];

    [self setupContainerViews];

    if (self.showDayPicker) {
        [self setupDayPicker];
    }

    if (self.allowTimeSelection) {
        [self setupTimeSelection];
    }

    [self setupDayColumnHeader];

    [self setupConstraints];
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

- (void)setupContainerViews {
    self.dayPickerContainer = [UIView new];
    [self.view addSubview:self.dayPickerContainer];
    self.relativeTimePickerContainer = [UIView new];
    [self.view addSubview:self.relativeTimePickerContainer];
    self.saveButtonContainer = [UIView new];
    [self.view addSubview:self.saveButtonContainer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadEvents];

    if (self.showCalendarPickerButton) {
        [self addCalendarPickerButton];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (self.allowTimeSelection) {
        [self updateCollectionViewContentInset];
    }
    self.viewHasAppeared = YES;

    [self scrollToTime:self.selectedDate];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.dateBeforeRotation = self.selectedDate;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    self.viewHasAppeared = NO;
    [self updateCollectionViewContentInset];
    self.viewHasAppeared = YES;
    [self setCollectionViewSectionWidth];
    [self.collectionViewCalendarLayout invalidateLayoutCache];
    [self scrollToTime:self.dateBeforeRotation]; // required because rotation causes a scroll away from selectedDate
}

#pragma mark - Actions

- (void)saveButtonTapped {
    [self.delegate dateTimePicker:self didSelectDate:self.selectedDate];
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

#pragma mark - Convenience

- (void)commonInit {
    _scrollIntervalMinutes = LIYDefaultScrollIntervalMinutes;
    _showRelativeTimePicker = YES;
    _date = [NSDate date];
    _selectedDate = [NSDate date];
    _showDayPicker = YES;
    _allowTimeSelection = YES;
    _allowEventEditing = YES;
    _defaultColor1 = [UIColor colorWithHexString:@"59c7f1"];
    _defaultColor2 = [UIColor orangeColor];
    _saveButtonText = @"Save";
    _showDateInDayColumnHeader = YES;
}

- (void)setCollectionViewSectionWidth {
    self.collectionViewCalendarLayout.sectionWidth = self.view.frame.size.width - 66.0f;
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
    edgeInsets.top = [self collectionViewEdgeInsetTop];
    edgeInsets.bottom = [self collectionViewEdgeInsetBottom];
    self.collectionView.contentInset = edgeInsets;
}

- (CGFloat)collectionViewEdgeInsetTop {
    CGFloat viewControllerTopToMidnightBeginningOfDay = [self statusBarHeight] + [self navBarHeight] + kLIYDayPickerHeight + [self.dayColumnHeader height] +
            kLIYGapToMidnight;
    CGFloat edgeInsetTop = [self middleYForTimeLine] - viewControllerTopToMidnightBeginningOfDay;
    return edgeInsetTop;
}

- (CGFloat)collectionViewEdgeInsetBottom {
    CGFloat viewControllerTopToEndOfDayMidnightTop = [self statusBarHeight] + [self navBarHeight] + kLIYDayPickerHeight + [self.dayColumnHeader height] + self
            .collectionView.frame.size.height - kLIYGapToMidnight;
    CGFloat edgeInsetBottom = viewControllerTopToEndOfDayMidnightTop - [self middleYForTimeLine];
    return edgeInsetBottom;
}

- (void)setupTimeSelection {
    self.timeDisplayLine = [LIYTimeDisplayLine timeDisplayLineInView:self.view withBorderColor:self.defaultColor1 fontName:self.defaultSelectedFontFamilyName
                                                         initialDate:self.selectedDate];
    [self setupRelativeTimePicker];
    [self setupSaveButton];
}

- (void)setupRelativeTimePicker {
    [LIYRelativeTimePicker timePickerInView:self.relativeTimePickerContainer withBackgroundColor:self.defaultColor2 buttonTappedBlock:^(NSInteger minutes) {
        [self relativeTimeButtonTappedWithMinutes:minutes];
    }];
}

- (void)relativeTimeButtonTappedWithMinutes:(NSInteger)minutes {
    NSDate *newDate = [NSDate dateWithTimeIntervalSinceNow:minutes * 60];
    [self.delegate dateTimePicker:self didSelectDate:newDate];
}

- (void)cancelTapped:(id)sender {
    [self.delegate dateTimePicker:self didSelectDate:nil];
}

- (void)setSelectedDateFromLocation {
    CGFloat topOfViewControllerToStartOfGrid = [self statusBarHeight] + [self navBarHeight] + kLIYDayPickerHeight + [self.dayColumnHeader height];
    self.selectedDate = [self dateFromYCoordinate:[self middleYForTimeLine] - topOfViewControllerToStartOfGrid];
}

- (void)setSelectedDate:(NSDate *)selectedDate {
    _selectedDate = [self nearestValidDateFromDate:selectedDate];
    [self setSelectedTimeText];
}

- (void)setSelectedTimeText {
    [self.timeDisplayLine updateLabelFromDate:self.selectedDate];

    if (self.allowTimeSelection) {
        self.dayColumnHeader.date = self.selectedDate;
    }
}

- (void)setupSaveButton {
    self.saveButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.saveButton addTarget:self action:@selector(saveButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.saveButton.backgroundColor = self.defaultColor2;
    [self.saveButton setTitle:self.saveButtonText forState:UIControlStateNormal];
    self.saveButton.titleLabel.textColor = [UIColor whiteColor];
    self.saveButton.titleLabel.font = [UIFont fontWithName:self.defaultFontFamilyName size:18.0f];
    self.saveButton.accessibilityIdentifier = self.saveButtonText;

    [self.saveButtonContainer addSubview:self.saveButton];
    [self.saveButton autoPinEdgesToSuperviewEdgesWithInsets:ALEdgeInsetsZero];
}

// From the top of the view controller (top of screen because it goes under status bar) to the line for the selected time
- (CGFloat)middleYForTimeLine {
    return self.view.frame.size.height / 2.0f;
}

- (CGFloat)statusBarHeight {
    return self.navigationController.navigationBar.translucent ? 20.0f : 0.0f; // we have to use 20 always here regardless of if status bar height changes in call. Probably could fix if we use autolayout instead of frames.
}

- (CGFloat)navBarHeight {
    return self.navigationController.navigationBar.translucent ? 44.0f : 0.0f; // TODO can we get this programmatically?
}

- (void)scrollToTime:(NSDate *)dateTime {
    NSDate *roundDateTime = [self nearestValidDateFromDate:dateTime];
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:roundDateTime];

    CGFloat minuteFactor = dateComponents.minute / 60.0f;
    CGFloat timeFactor = dateComponents.hour + minuteFactor;
    CGFloat topInset = self.collectionView.contentInset.top;
    CGFloat timeY = (timeFactor * self.collectionViewCalendarLayout.hourHeight) - topInset;
    [self.collectionView setContentOffset:CGPointMake(0, timeY) animated:NO];
}

- (NSDate *)nearestValidDateFromDate:(NSDate *)date {
    CGFloat scrollIntervalSeconds = self.scrollIntervalMinutes * 60.0f;
    NSTimeInterval seconds = ceil([date timeIntervalSinceReferenceDate] / scrollIntervalSeconds) * scrollIntervalSeconds;
    NSDate *roundDateTime = [NSDate dateWithTimeIntervalSinceReferenceDate:seconds];
    return roundDateTime;
}

- (void)setupDayPicker {
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.dayPicker = [[MZDayPicker alloc] initWithFrame:CGRectZero month:9 year:2013];
    [self.dayPickerContainer addSubview:self.dayPicker];
    [self.dayPicker autoPinEdgesToSuperviewEdgesWithInsets:ALEdgeInsetsZero];

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
    [self setupDayPickerConstraints];

    [self setupDayColumnHeaderConstraints];

    [self setupCollectionViewConstraints];

    [self setupRelativeTimePickerConstraints];

    [self setupSaveButtonConstraints];
}

- (void)setupDayPickerConstraints {
    [self.dayPickerContainer autoPinEdgesToSuperviewEdgesWithInsets:ALEdgeInsetsZero excludingEdge:ALEdgeBottom];
    [self setContainerView:self.dayPickerContainer visible:self.dayPicker != nil withHeight:kLIYDayPickerHeight];
}

- (void)setContainerView:(UIView *)containerView visible:(BOOL)visible withHeight:(CGFloat)height {
    [containerView autoSetDimension:ALDimensionHeight toSize:visible ? height : 0];
    if (!visible) {
        containerView.hidden = YES;
    }
}

- (void)setupDayColumnHeaderConstraints {
    [self.dayColumnHeader positionInView:self.view];
    [self.dayColumnHeader autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.dayPickerContainer];
}

- (void)setupCollectionViewConstraints {
    [self pinView:self.collectionView belowView:self.dayColumnHeader];
}

- (void)setupRelativeTimePickerConstraints {
    [self pinView:self.relativeTimePickerContainer belowView:self.collectionView];
    [self updateRelativeTimePickerContainerHeight];
}

- (void)updateRelativeTimePickerContainerHeight {
    BOOL relativeTimePickerVisible = self.showRelativeTimePicker && self.allowTimeSelection;
    CGFloat height = relativeTimePickerVisible ? LIYSaveButtonHeight : 0;
    if (self.relativeTimePickerHeightConstraint) {
        self.relativeTimePickerHeightConstraint.constant = height;
    } else {
        self.relativeTimePickerHeightConstraint = [self.relativeTimePickerContainer autoSetDimension:ALDimensionHeight toSize:height];
    }
    self.relativeTimePickerContainer.hidden = !relativeTimePickerVisible;
}

- (void)setupSaveButtonConstraints {
    [self pinView:self.saveButtonContainer belowView:self.relativeTimePickerContainer];
    [self.saveButtonContainer autoPinToBottomLayoutGuideOfViewController:self withInset:0];
    [self setContainerView:self.saveButtonContainer visible:self.saveButton != nil withHeight:LIYSaveButtonHeight];
}

- (void)pinView:(UIView *)view belowView:(UIView *)otherView {
    [view autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [view autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
    [view autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:otherView];
}

/// y is measured where 0 is the top of the collection view (after day column header and optionally all day event view)
- (NSDate *)dateFromYCoordinate:(CGFloat)y {
    CGFloat intervalsPerHour = 60.0f / self.scrollIntervalMinutes;
    CGFloat hour = (CGFloat)(round([self hourAtYCoord:y] * intervalsPerHour) / intervalsPerHour);
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [cal components:NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.date];
    dateComponents.hour = (NSInteger)trunc(hour);
    dateComponents.minute = (NSInteger)round((hour - trunc(hour)) * 60);
    NSDate *selectedDate = [cal dateFromComponents:dateComponents];
    return selectedDate;
}

- (NSDate *)combineDateAndTime:(NSDate *)dateForDay timeDate:(NSDate *)dateForTime {

    NSDateComponents *timeComps = [[NSCalendar currentCalendar] components:(NSCalendarUnitMinute | NSCalendarUnitHour) fromDate:dateForTime];
    NSDateComponents *dateComps = [[NSCalendar currentCalendar] components:(NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear) fromDate:dateForDay];

    dateComps.hour = timeComps.hour;
    dateComps.minute = timeComps.minute;

    NSDate *toReturn = [[NSCalendar currentCalendar] dateFromComponents:dateComps];
    return toReturn;
}

// TODO: give this method a better name and fix the magic numbers below
- (NSDate *)endDate {
    return [self.date dateByAddingTimeInterval:60 * 60 * 24 * 14];
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
    [[LIYCalendarService sharedInstance] eventsForDate:self.date calendars:self.visibleCalendars completion:^(NSArray *nonAllDayEvents, NSArray *allDayEvents) {
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

/// y is measured where 0 is the top of the collection view (after day column header and optionally all day event view)
- (CGFloat)hourAtYCoord:(CGFloat)y {
    CGFloat hour = (y + self.collectionView.contentOffset.y - kLIYGapToMidnight) / self.collectionViewCalendarLayout.hourHeight;
    hour = (CGFloat)fmax(hour, 0);
    hour = (CGFloat)fmin(hour, 24);
    return hour;
}

- (void)addCalendarPickerButton {
    if (!self.navigationController) {
        return;
    }

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Calendars" style:UIBarButtonItemStylePlain target:self action:@selector(calendarPickerButtonTapped)];
}

- (void)setupDayColumnHeader {
    self.dayColumnHeader = [MSDayColumnHeader new];
    if (self.showDateInDayColumnHeader) {
        [self.dayColumnHeader configureForDateHeaderWithDayTitlePrefix:self.dayTitlePrefix defaultFontFamilyName:self.defaultFontFamilyName
                                             defaultBoldFontFamilyName:self.defaultSelectedFontFamilyName
                                                    timeHighlightColor:self.defaultColor1
                                                                  date:self.selectedDate
                                                      showTimeInHeader:self.self.allowTimeSelection];
    }

    [self.dayColumnHeader updateAllDaySectionWithEvents:self.allDayEvents];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.allowTimeSelection && self.viewHasAppeared) {
        [self setSelectedDateFromLocation];
    }
}

# pragma mark - properties

- (EKEventStore *)eventStore {
    return [LIYCalendarService sharedInstance].eventStore;
}

- (void)setShowRelativeTimePicker:(BOOL)showRelativeTimePicker {
    _showRelativeTimePicker = showRelativeTimePicker;
    [self updateRelativeTimePickerContainerHeight];
}

- (void)setDate:(NSDate *)date {
    _date = date;

    if (self.dayPicker.currentDate && ![date isSameDayAsDate:self.dayPicker.currentDate]) {
        [self.dayPicker setStartDate:self.date endDate:[self endDate]];
        [self.dayPicker setCurrentDate:date animated:YES];
    }

    // clear out events immediately because reloadEvents loads events asynchronously
    self.nonAllDayEvents = [NSMutableArray array];
    self.allDayEvents = [NSMutableArray array];
    [self.collectionViewCalendarLayout invalidateLayoutCache];
    [self.collectionView reloadData];
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
    if (self.isViewLoaded) {
        [self updateCollectionViewContentInset];
    }
    if (self.selectedDate && self.allowTimeSelection) {
        [self scrollToTime:self.selectedDate]; // it's possible the scroll changed when all day now shows
    }
}

#pragma mark - MZDayPickerDataSource

- (NSString *)dayPicker:(MZDayPicker *)dayPicker titleForCellDayNameLabelInDay:(MZDay *)day {
    return [self.dateFormatter stringFromDate:day.date];
}

#pragma mark - MZDayPickerDelegate

- (void)dayPicker:(MZDayPicker *)dayPicker didSelectDay:(MZDay *)day {
    NSDate *timeDate = self.date;
    if (self.selectedDate) {
        timeDate = self.selectedDate;
    }

    self.date = [self combineDateAndTime:day.date timeDate:timeDate];
    self.selectedDate = self.date;

    [self reloadEvents];
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

    if (endDate - [startDate timeIntervalSince1970] < 15 * 60) {
        endDate = [startDate timeIntervalSince1970] + 30 * 60; // set to minimum 30 min gap
    }
    return [NSDate dateWithTimeIntervalSince1970:endDate];
}

- (NSDate *)currentTimeComponentsForCollectionView:(UICollectionView *)collectionView layout:(MSCollectionViewCalendarLayout *)collectionViewCalendarLayout {
    return [NSDate date];
}

@end