#import "ViewController.h"
#import "LIYDateTimePickerViewController.h"
#import "NSArray+ObjectiveSugar.h"
#import <EventKit/EventKit.h>

static NSString *const kLIYCalendarCellIdentifier = @"calendarCell";

@interface ViewController () <LIYDateTimePickerDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, weak) IBOutlet UILabel *selectedTimeLabel;
@property(nonatomic, weak) IBOutlet UITableView *tableView;
@property(nonatomic, strong) EKEventStore *eventStore;
@property(nonatomic, strong) NSArray *calendars;
@property(nonatomic, strong) NSArray *visibleCalendars;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initCalendars];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kLIYCalendarCellIdentifier];
}

- (void)initCalendars {
    self.eventStore = [[EKEventStore alloc] init];
    EKEventStore *__weak weakEventStore = self.eventStore;
    typeof(self) __weak weakSelf = self;
    [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted) {
            return;
        }
        weakSelf.calendars = [weakEventStore calendarsForEntityType:EKEntityTypeEvent];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
            [weakSelf.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        });
    }];
}

- (IBAction)onPickTimeTap:(id)sender {
    LIYDateTimePickerViewController *vc = [LIYDateTimePickerViewController timePickerForDate:[NSDate date] delegate:self];
    vc.showEventTimes = YES;
    vc.visibleCalendars = self.visibleCalendars;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)dateTimePicker:(LIYDateTimePickerViewController *)dateTimePickerViewController didSelectDate:(NSDate *)selectedDate {
    self.selectedTimeLabel.text = [selectedDate description];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)showCalendarTap:(UIButton *)sender {
    LIYDateTimePickerViewController *vc = [LIYDateTimePickerViewController timePickerForDate:[NSDate date] delegate:self];
    vc.showEventTimes = YES;
    vc.showDayColumnHeader = NO;
    vc.visibleCalendars = self.visibleCalendars;
    vc.allowTimeSelection = NO;
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSArray *)visibleCalendars {
    if (self.tableView.indexPathsForSelectedRows.count == 0) {
        return nil;
    }

    return [self.tableView.indexPathsForSelectedRows map:^id(NSIndexPath *indexPath) {
        EKCalendar *calendar = self.calendars[indexPath.row];
        return calendar;
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.calendars count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kLIYCalendarCellIdentifier];
    EKCalendar *calendar = self.calendars[indexPath.row];
    cell.textLabel.text = calendar.title;
    return cell;
}

@end
