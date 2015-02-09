#import <Foundation/Foundation.h>

static NSString *const kLIYCalendarCellIdentifier = @"calendarCell";

@class EKEventStore;

@interface LIYCalendarPickerViewController : UITableViewController

+ (instancetype)calendarPickerWithEventStore:(EKEventStore *)eventStore selectedCalendarIdentifiers:(NSArray *)selectedCalendarIdentifiers completion:(void (^)(NSArray *))completion;

@property (nonatomic, strong) EKEventStore *eventStore;
@property (nonatomic, copy) void (^completionBlock)(NSArray *);
@property (nonatomic, readonly) NSArray *selectedCalendarIdentifiers;

@end
