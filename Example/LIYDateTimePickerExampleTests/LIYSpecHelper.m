#import "LIYSpecHelper.h"
#import "Kiwi.h"
#import "LIYDateTimePickerViewController.h"
#import "NSDate+LIYUtilities.h"
#import "LIYMockEventStore.h"

@implementation LIYSpecHelper

+ (void)rotateDeviceToOrientation:(enum UIInterfaceOrientation)orientation {
    [[UIDevice currentDevice] setValue:@(orientation) forKey:@"orientation"];

    // tick the run loop to trigger any asynchronous processing while rotating.
    [LIYSpecHelper tickRunLoopForSeconds:1];
}

+ (void)tickRunLoopForSeconds:(NSTimeInterval)seconds {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
}

+ (void)tickRunLoop {
    [LIYSpecHelper tickRunLoopForSeconds:0.1];
}

+ (LIYDateTimePickerViewController *)visiblePickerViewController {
    LIYDateTimePickerViewController *pickerViewController = [LIYDateTimePickerViewController new];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:pickerViewController];
    navigationController.navigationBar.translucent = NO;
    [UIApplication sharedApplication].keyWindow.rootViewController = navigationController;

    // must wait for run loop for view controller to be rendered
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

    return pickerViewController;
}

+ (LIYDateTimePickerViewController *)pickerViewControllerWithAllDayEventAtDate:(NSDate *)date {
    // mock event store
    LIYMockEventStore *mockEventStore = [LIYMockEventStore mockEventStoreWithAllDayEventAt:date];
    [EKEventStore stub:@selector(new) andReturn:mockEventStore];

    // load VC
    LIYDateTimePickerViewController *pickerViewController = [LIYSpecHelper visiblePickerViewController];
    pickerViewController.visibleCalendars = @[[EKCalendar nullMock]];

    return pickerViewController;
}

+ (void)stubCurrentDateAs:(NSString *)dateString {
    [NSDate stub:@selector(date) andReturn:[NSDate liy_dateFromString:dateString]];
}

+ (LIYDateTimePickerViewController *)pickerViewControllerWithEventAtDate:(NSDate *)startDate endDate:(NSDate *)endDate {
    // mock event store
    LIYMockEventStore *mockEventStore = [LIYMockEventStore mockEventStore];
    [mockEventStore addNonAllDayEventAtDate:startDate endDate:endDate];
    [EKEventStore stub:@selector(new) andReturn:mockEventStore];

    // load picker view controller
    LIYDateTimePickerViewController *pickerViewController = [LIYSpecHelper visiblePickerViewController];
    pickerViewController.visibleCalendars = @[[EKCalendar nullMock]];

    return pickerViewController;
}

@end