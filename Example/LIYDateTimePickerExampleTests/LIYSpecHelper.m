#import "LIYSpecHelper.h"
#import <EventKit/EventKit.h>
#import <CupertinoYankee/NSDate+CupertinoYankee.h>
#import "Kiwi.h"
#import "LIYDateTimePickerViewController.h"

@interface LIYMockEventStore : EKEventStore
@property (nonatomic, strong) NSMutableArray *events;
- (void)addAllDayEventAtDate:(NSDate *)date;
@end

@implementation LIYMockEventStore
- (instancetype)init {
    self = [super init];
    if (self) {
        self.events = [NSMutableArray array];
    }
    return self;
}

- (void)addAllDayEventAtDate:(NSDate *)date {
    EKEvent *event = [EKEvent nullMock];
    [event stub:@selector(isAllDay) andReturn:theValue(YES)];
    [event stub:@selector(startDate) andReturn:[date beginningOfDay]];
    [event stub:@selector(endDate) andReturn:[date endOfDay]];
    [self.events addObject:event];
}

- (NSArray *)eventsMatchingPredicate:(NSPredicate *)predicate {
    return self.events;
}

- (void)requestAccessToEntityType:(EKEntityType)entityType completion:(EKEventStoreRequestAccessCompletionHandler)completion {
    completion(YES, nil);
}

@end

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

+ (LIYMockEventStore *)mockEventStore {
    return [LIYMockEventStore new];
}

+ (LIYMockEventStore *)mockEventStoreWithAllDayEventAt:(NSDate *)date {
    LIYMockEventStore *mockEventStore = [LIYSpecHelper mockEventStore];
    [mockEventStore addAllDayEventAtDate:date];
    return mockEventStore;
}

+ (NSString *)dayOfMonthFromDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:date];
    return [@(components.month) description];
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
    LIYMockEventStore *mockEventStore = [LIYSpecHelper mockEventStoreWithAllDayEventAt:date];
    [EKEventStore stub:@selector(new) andReturn:mockEventStore];

    // load VC
    LIYDateTimePickerViewController *pickerViewController = [LIYSpecHelper visiblePickerViewController];
    pickerViewController.visibleCalendars = @[[EKCalendar nullMock]];

    return pickerViewController;
}

@end