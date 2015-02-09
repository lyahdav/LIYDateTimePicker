#import "ViewController.h"
#import "LIYDateTimePickerViewController.h"
#import "NSArray+ObjectiveSugar.h"
#import "LIYCalendarPickerViewController.h"
#import <EventKit/EventKit.h>

@interface ViewController () <LIYDateTimePickerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *selectedTimeLabel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, strong) NSArray *visibleCalendars;

@end

@implementation ViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initCalendars];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kLIYCalendarCellIdentifier];
}

#pragma mark - convenience

- (void)initCalendars {
    self.eventStore = [[EKEventStore alloc] init];
    [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
    }];
    self.visibleCalendars = [NSArray array];
}

#pragma mark - actions

- (IBAction)onPickTimeTap:(id)sender {
    LIYDateTimePickerViewController *vc = [LIYDateTimePickerViewController timePickerForDate:[NSDate date] delegate:self];
    vc.showEventTimes = YES;
    vc.visibleCalendars = self.visibleCalendars;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)showCalendarTap:(UIButton *)sender {
    LIYDateTimePickerViewController *vc = [LIYDateTimePickerViewController timePickerForDate:[NSDate date] delegate:self];
    vc.showEventTimes = YES;
    vc.showDayColumnHeader = NO;
    vc.visibleCalendars = self.visibleCalendars;
    vc.allowTimeSelection = NO;
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)selectCalendarsButtonTapped:(UIButton *)sender {
    typeof(self) __weak weakSelf = self;
    NSArray *selectedCalendarIdentifiers = [self.visibleCalendars map:^id(EKCalendar *calendar) {
        return calendar.calendarIdentifier;
    }];
    LIYCalendarPickerViewController *calendarPickerViewController =
            [LIYCalendarPickerViewController calendarPickerWithEventStore:self.eventStore selectedCalendarIdentifiers:selectedCalendarIdentifiers completion:^(NSArray *newSelectedCalendarIdentifiers) {
                weakSelf.visibleCalendars = [newSelectedCalendarIdentifiers map:^id(NSString *calendarIdentifier) {
                    return [weakSelf.eventStore calendarWithIdentifier:calendarIdentifier];
                }];
                [weakSelf.tableView reloadData];
            }];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:calendarPickerViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - LIYDateTimePickerDelegate

- (void)dateTimePicker:(LIYDateTimePickerViewController *)dateTimePickerViewController didSelectDate:(NSDate *)selectedDate {
    self.selectedTimeLabel.text = [selectedDate description];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.visibleCalendars count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLIYCalendarCellIdentifier];
    EKCalendar *calendar = self.visibleCalendars[(NSUInteger)indexPath.row];
    cell.textLabel.text = calendar.title;
    return cell;
}

@end
