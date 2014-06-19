#import "ViewController.h"
#import "LIYDateTimePickerViewController.h"

@interface ViewController () <LIYDateTimePickerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *selectedTimeLabel;

@end

@implementation ViewController

- (IBAction)onPickTimeTap:(id)sender {
    LIYDateTimePickerViewController *vc = [LIYDateTimePickerViewController timePickerForDate:[NSDate date] delegate:self];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)dateTimePicker:(LIYDateTimePickerViewController *)dateTimePickerViewController didSelectDate:(NSDate *)selectedDate {
    self.selectedTimeLabel.text = [selectedDate description];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
