#import "LIYDateTimePickerViewController.h"
#import "LIYTimeDisplayLine.h"
#import "LIYRelativeTimePicker.h"
#import "PureLayout.h"
#import "LIYJTCalendar.h"
#import "UIView+LIYUtilities.h"
#import "LIYCalendarViewControllerSubclass.h"

const CGFloat LIYSaveButtonHeight = 44.0f;

@interface LIYDateTimePickerViewController () <UIScrollViewDelegate>

@property (nonatomic) BOOL viewHasAppeared;
@property (nonatomic, strong) NSDate *selectedDateBeforePan;
@property (nonatomic, strong) LIYTimeDisplayLine *timeDisplayLine;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIView *relativeTimePickerContainer;
@property (nonatomic, strong) UIView *saveButtonContainer;
@property (nonatomic, strong) NSLayoutConstraint *relativeTimePickerHeightConstraint;

@end

@implementation LIYDateTimePickerViewController

#pragma mark - class methods

+ (instancetype)timePickerForDate:(NSDate *)date delegate:(id <LIYDateTimePickerDelegate>)delegate {
    LIYDateTimePickerViewController *dateTimePicker = [self new];
    dateTimePicker.delegate = delegate;
    if (date) {
        dateTimePicker.selectedDate = date;
    }
    return dateTimePicker;
}

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self updateCollectionViewContentInset];
    self.viewHasAppeared = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    self.viewHasAppeared = NO;
    [self updateCollectionViewContentInset];
    self.viewHasAppeared = YES;
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark - LIYCalendarViewController

- (void)commonInit {
    [super commonInit];
    _showRelativeTimePicker = NO;
    _showDateInDayColumnHeader = YES;
}

- (void)setupViews {
    [super setupViews];
    [self setupTimeSelection];
    [self setupDayPickerReloadAppearance];
    [self setupCancelButton];
    [self setupDateInDayColumnHeader];
}

- (void)scrollToTimeByFactor:(CGFloat)timeFactor {
    CGFloat topInset = self.collectionView.contentInset.top;
    CGFloat timeY = (timeFactor * self.collectionViewCalendarLayout.hourHeight) - topInset;
    [self.collectionView setContentOffset:CGPointMake(0, timeY) animated:NO];
}

- (void)setSelectedDateWithoutDayPicker:(NSDate *)selectedDateTime {
    [super setSelectedDateWithoutDayPicker:selectedDateTime];
    [self setSelectedTimeText];
}

- (void)setupCalendarBottomConstraint {
    [self.saveButtonContainer autoPinToBottomLayoutGuideOfViewController:self withInset:0];
}

- (void)setAllDayEvents:(NSArray *)allDayEvents {
    [super setAllDayEvents:allDayEvents];

    if (self.isViewLoaded) {
        [self.view layoutIfNeeded];
        [self updateCollectionViewContentInset];
    }
    [self scrollToTime:self.selectedDate]; // it's possible the scroll changed when all day now shows
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.dayPicker.panGestureState == UIGestureRecognizerStateChanged) {
        self.selectedDateBeforePan = self.selectedDate;
    }
    if (self.dayPicker.panGestureState == UIGestureRecognizerStatePossible && self.viewHasAppeared) {
        [self setSelectedDateFromLocation];
    }
}

#pragma mark - properties

- (void)setShowRelativeTimePicker:(BOOL)showRelativeTimePicker {
    _showRelativeTimePicker = showRelativeTimePicker;
    [self updateRelativeTimePickerContainerHeight];
}

#pragma mark - actions

- (void)saveButtonTapped {
    [self.delegate dateTimePicker:self didSelectDate:self.selectedDate];
}

- (void)cancelTapped {
    [self.delegate dateTimePicker:self didSelectDate:nil];
}

#pragma mark - convenience

- (void)setupTimeSelection {
    self.timeDisplayLine = [LIYTimeDisplayLine timeDisplayLineInView:self.view withBorderColor:self.defaultColor1 fontName:self.defaultSelectedFontFamilyName
                                                         initialDate:self.selectedDate verticallyCenteredWithView:self.collectionView];
    [self setupContainerViews];
    [self setupRelativeTimePicker];
    [self setupSaveButton];

    [self setupRelativeTimePickerConstraints];
    [self setupSaveButtonConstraints];
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

- (void)setupContainerViews {
    self.relativeTimePickerContainer = [UIView new];
    [self.view addSubview:self.relativeTimePickerContainer];
    self.saveButtonContainer = [UIView new];
    [self.view addSubview:self.saveButtonContainer];
}

- (void)setupDayPickerReloadAppearance {
    typeof(self) __weak weakSelf = self;
    self.dayPicker.reloadAppearanceBlock = ^(LIYJTCalendar *calendar){
        [weakSelf updateViewForMonthWeekToggle];
    };
}

- (void)setupCancelButton {
    if (self.showCancelButton) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped)];
    }
}

- (void)setupDateInDayColumnHeader {
    if (self.showDateInDayColumnHeader) {
        [self.dayColumnHeader configureForDateHeaderWithDayTitlePrefix:self.dayTitlePrefix defaultFontFamilyName:self.defaultFontFamilyName
                                             defaultBoldFontFamilyName:self.defaultSelectedFontFamilyName
                                                    timeHighlightColor:self.defaultColor1
                                                                  date:self.selectedDate
                                                      showTimeInHeader:YES];
    }
}

- (void)setupRelativeTimePickerConstraints {
    [self.relativeTimePickerContainer liy_pinBelowView:self.collectionView];
    [self updateRelativeTimePickerContainerHeight];
}

- (void)setupSaveButtonConstraints {
    [self.saveButtonContainer liy_pinBelowView:self.relativeTimePickerContainer];
    [self setContainerView:self.saveButtonContainer visible:self.saveButton != nil withHeight:LIYSaveButtonHeight];
}

- (void)updateRelativeTimePickerContainerHeight {
    BOOL relativeTimePickerVisible = self.showRelativeTimePicker;
    CGFloat height = relativeTimePickerVisible ? LIYSaveButtonHeight : 0;
    if (self.relativeTimePickerHeightConstraint) {
        self.relativeTimePickerHeightConstraint.constant = height;
    } else {
        self.relativeTimePickerHeightConstraint = [self.relativeTimePickerContainer autoSetDimension:ALDimensionHeight toSize:height];
    }
    self.relativeTimePickerContainer.hidden = !relativeTimePickerVisible;
}

// allows user to scroll to midnight at start and end of day
- (void)updateCollectionViewContentInset {
    if (self.collectionView == nil) {
        return;
    }

    UIEdgeInsets edgeInsets = self.collectionView.contentInset;
    edgeInsets.top = [self collectionViewContentInset];
    edgeInsets.bottom = [self collectionViewContentInset];
    self.collectionView.contentInset = edgeInsets;
}

- (void)updateViewForMonthWeekToggle {
    NSDate *previousSelectedDate = self.selectedDateBeforePan ?: self.selectedDate;
    self.selectedDateBeforePan = nil;
    [self.view layoutIfNeeded];
    [self updateCollectionViewContentInset];
    [self scrollToTime:previousSelectedDate];
}

- (void)setSelectedTimeText {
    [self.timeDisplayLine updateLabelFromDate:self.selectedDate];

    self.dayColumnHeader.date = self.selectedDate;
}

- (void)setSelectedDateFromLocation {
    [self setSelectedDateWithoutDayPicker:[self dateFromYCoordinate:[self middleYForTimeLine]]];
}

- (void)setContainerView:(UIView *)containerView visible:(BOOL)visible withHeight:(CGFloat)height {
    [containerView autoSetDimension:ALDimensionHeight toSize:visible ? height : 0];
    if (!visible) {
        containerView.hidden = YES;
    }
}

- (CGFloat)collectionViewContentInset {
    return [self middleYForTimeLine] - kLIYGapToMidnight;
}

- (CGFloat)middleYForTimeLine {
    return self.collectionView.frame.size.height / 2.0f;
}

/// y is measured where 0 is the top of the collection view
- (NSDate *)dateFromYCoordinate:(CGFloat)y {
    CGFloat intervalsPerHour = 60.0f / self.scrollIntervalMinutes;
    CGFloat hour = (CGFloat)(round([self hourAtYCoordinate:y] * intervalsPerHour) / intervalsPerHour);
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [cal components:NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.dayPicker.currentDateSelected];
    dateComponents.hour = (NSInteger)trunc(hour);
    dateComponents.minute = (NSInteger)round((hour - trunc(hour)) * 60);
    NSDate *date = [cal dateFromComponents:dateComponents];
    return date;
}

@end