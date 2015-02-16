#import <Foundation/Foundation.h>

static NSString *const kLIYCalendarCellIdentifier = @"calendarCell";

@class EKEventStore;

@interface LIYCalendarPickerViewController : UITableViewController

+ (instancetype)calendarPickerWithEventStore:(EKEventStore *)eventStore selectedCalendarIdentifiers:(NSArray *)selectedCalendarIdentifiers completion:(void (^)(NSArray *))completion;
+ (instancetype)calendarPickerWithCalendarsFromUserDefaultsWithEventStore:(EKEventStore *)eventStore completion:(void (^)(NSArray *))completion;
+ (NSArray *)selectedCalendarIdentifiersFromUserDefaultsForEventStore:(EKEventStore *)eventStore;

@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, copy) void (^completionBlock)(NSArray *);
@property (nonatomic, readonly) NSArray *selectedCalendarIdentifiers;

@end
