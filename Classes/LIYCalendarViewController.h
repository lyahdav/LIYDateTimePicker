#import <UIKit/UIKit.h>
#import "MSDayColumnHeader.h"
#import "MSCollectionViewCalendarLayout.h"

static const CGFloat kLIYGapToMidnight = 20.0f; // TODO should compute, this is from the start of the grid to the 12am line

@class LIYCalendarViewController;
@class LIYJTCalendar;

@interface LIYCalendarViewController : UIViewController

@property (nonatomic, assign) BOOL showDayPicker;
@property (nonatomic, assign) BOOL showEventTimes;
@property (nonatomic, assign) BOOL showCalendarPickerButton;
@property (nonatomic, assign) BOOL allowEventEditing;
@property (nonatomic, assign) CGFloat dayPickerWeekHeight;
@property (nonatomic, assign) CGFloat dayPickerMonthHeight;
@property (nonatomic, strong) NSDate *selectedDate;
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
@property (nonatomic) NSUInteger scrollIntervalMinutes;
@property (strong, nonatomic) LIYJTCalendar *dayPicker;

- (void)reloadEvents;
+ (instancetype)calendarForDate:(NSDate *)date;
- (void)switchToMonthPicker;
- (void)switchToWeekPicker;
- (void)scrollToTime:(NSDate *)dateTime;
- (void)setVisibleCalendarsFromUserDefaults;

@end
