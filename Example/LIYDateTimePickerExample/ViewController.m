#import "ViewController.h"
#import "LIYDateTimePickerViewController.h"
#import "NSArray+ObjectiveSugar.h"
#import "LIYCalendarPickerViewController.h"
#import <EventKit/EventKit.h>

@interface ViewController () <LIYDateTimePickerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *selectedTimeLabel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) EKEventStore *eventStore;

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
}

#pragma mark - actions

- (IBAction)onPickTimeTap:(id)sender {
    LIYDateTimePickerViewController *vc = [LIYDateTimePickerViewController timePickerForDate:[NSDate date] delegate:self];
    vc.showCalendarPickerButton = YES;
    vc.showEventTimes = YES;
    [vc setVisibleCalendarsFromUserDefaults];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)showCalendarTap:(UIButton *)sender {
    LIYDateTimePickerViewController *vc = [LIYDateTimePickerViewController timePickerForDate:[NSDate date] delegate:self];
    vc.showCalendarPickerButton = YES;
    vc.showEventTimes = YES;
    vc.showDayColumnHeader = NO;
    vc.allowTimeSelection = NO;
    [vc setVisibleCalendarsFromUserDefaults];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - LIYDateTimePickerDelegate

- (void)dateTimePicker:(LIYDateTimePickerViewController *)dateTimePickerViewController didSelectDate:(NSDate *)selectedDate {
    self.selectedTimeLabel.text = [selectedDate description];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
