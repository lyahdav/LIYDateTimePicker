#import "LIYCalendarPickerViewController.h"
#import <EventKit/EventKit.h>
#import <ObjectiveSugar/ObjectiveSugar.h>

static NSString *LIYSelectedCalendarIdentifiersKey = @"LIYSelectedCalendarIdentifiers";

@interface LIYEventSourceWithCalendars : NSObject

@property (nonatomic, strong) NSString *eventSourceName;
@property (nonatomic, strong) NSArray *calendars;

@end

@implementation LIYEventSourceWithCalendars
@end

@interface LIYCalendarPickerViewController ()

@property (nonatomic, strong) NSArray *groupedCalendars;
@property (nonatomic, strong) NSArray *initialSelectedCalendarIdentifiers;

@end

@implementation LIYCalendarPickerViewController

#pragma mark - class methods

+ (instancetype)calendarPickerWithEventStore:(EKEventStore *)eventStore selectedCalendarIdentifiers:(NSArray *)selectedCalendarIdentifiers completion:(void (^)(NSArray *))completion {
    LIYCalendarPickerViewController *calendarPickerViewController = [LIYCalendarPickerViewController new];
    calendarPickerViewController.eventStore = eventStore;
    calendarPickerViewController.completionBlock = completion;
    calendarPickerViewController.initialSelectedCalendarIdentifiers = selectedCalendarIdentifiers;
    return calendarPickerViewController;
}

+ (instancetype)calendarPickerWithCalendarsFromUserDefaultsWithEventStore:(EKEventStore *)eventStore completion:(void (^)(NSArray *))completion {
    LIYCalendarPickerViewController *calendarPickerViewController = [LIYCalendarPickerViewController new];
    calendarPickerViewController.eventStore = eventStore;
    calendarPickerViewController.completionBlock = ^(NSArray *selectedCalendarIdentifiers) {
        [self setSelectedCalendarIdenfiersInUserDefaults:selectedCalendarIdentifiers];
        completion(selectedCalendarIdentifiers);
    };
    calendarPickerViewController.initialSelectedCalendarIdentifiers = [self selectedCalendarIdentifiersFromUserDefaultsForEventStore:eventStore];
    return calendarPickerViewController;
}

+ (NSArray *)selectedCalendarIdentifiersFromUserDefaultsForEventStore:(EKEventStore *)eventStore {
    NSArray *selectedCalendarIdentifiers = [[NSUserDefaults standardUserDefaults] arrayForKey:LIYSelectedCalendarIdentifiersKey];
    return selectedCalendarIdentifiers ?: @[eventStore.defaultCalendarForNewEvents.calendarIdentifier];
}

+ (void)setSelectedCalendarIdenfiersInUserDefaults:(NSArray *)calendarIdentifiers {
    [[NSUserDefaults standardUserDefaults] setObject:calendarIdentifiers forKey:LIYSelectedCalendarIdentifiersKey];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Select Calendars";

    self.tableView.allowsMultipleSelection = YES;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kLIYCalendarCellIdentifier];

    self.groupedCalendars = [self calendarsBySource];
    [self.tableView reloadData];
    [self selectInitialCalendars];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self
                                                                             action:@selector(doneButtonTapped)];
}

#pragma mark - actions

- (void)doneButtonTapped {
    self.completionBlock(self.selectedCalendarIdentifiers);
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - convenience

- (void)selectInitialCalendars {
    [self.initialSelectedCalendarIdentifiers each:^(NSString *calendarIdentifier) {
        NSIndexPath *indexPath = [self indexPathForCalendarIdentifier:calendarIdentifier];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }];
}

- (NSIndexPath *)indexPathForCalendarIdentifier:(NSString *)calendarIdentifier {
    EKCalendar *calendarToFind = [self.eventStore calendarWithIdentifier:calendarIdentifier];
    NSInteger section = 0;
    for (LIYEventSourceWithCalendars *eventSourceWithCalendars in self.groupedCalendars) {
        NSInteger row = 0;
        for (EKCalendar *calendar in eventSourceWithCalendars.calendars) {
            if ([calendar.calendarIdentifier isEqualToString:calendarToFind.calendarIdentifier]) {
                return [NSIndexPath indexPathForRow:row inSection:section];
            }
            row++;
        }
        section++;
    }
    return nil;
}

/// returns an array of LIYEventSourceWithCalendars
- (NSArray *)calendarsBySource {
    NSMutableArray *calendarsBySource = [NSMutableArray array];
    for (EKSource *source in [self.eventStore sources]) {
        LIYEventSourceWithCalendars *eventSourceWithCalendars = [LIYEventSourceWithCalendars new];
        eventSourceWithCalendars.eventSourceName = source.title;
        eventSourceWithCalendars.calendars = [[source calendarsForEntityType:EKEntityTypeEvent] allObjects];
        [calendarsBySource addObject:eventSourceWithCalendars];
    }
    return calendarsBySource;
}

- (EKCalendar *)calendarForIndexPath:(NSIndexPath *)indexPath {
    LIYEventSourceWithCalendars *eventSourceWithCalendars = self.groupedCalendars[(NSUInteger)indexPath.section];
    EKCalendar *calendar = eventSourceWithCalendars.calendars[(NSUInteger)indexPath.row];
    return calendar;
}

#pragma mark - properties

- (NSArray *)selectedCalendarIdentifiers {
    if (self.tableView.indexPathsForSelectedRows == nil) {
        return @[];
    } else {
        return [self.tableView.indexPathsForSelectedRows map:^id(NSIndexPath *indexPath) {
            EKCalendar *calendar = [self calendarForIndexPath:indexPath];
            return calendar.calendarIdentifier;
        }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groupedCalendars.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    LIYEventSourceWithCalendars *eventSourceWithCalendars = self.groupedCalendars[(NSUInteger)section];
    return eventSourceWithCalendars.eventSourceName;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    LIYEventSourceWithCalendars *eventSourceWithCalendars = self.groupedCalendars[(NSUInteger)section];
    return eventSourceWithCalendars.calendars.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EKCalendar *calendar = [self calendarForIndexPath:indexPath];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLIYCalendarCellIdentifier];
    cell.textLabel.text = calendar.title;
    return cell;
}

@end
