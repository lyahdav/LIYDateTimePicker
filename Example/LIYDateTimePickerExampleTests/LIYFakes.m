#import "LIYFakes.h"

@implementation LIYFakeTimePickerDelegate

- (void)dateTimePicker:(LIYDateTimePickerViewController *)dateTimePickerViewController didSelectDate:(NSDate *)selectedDate {
    _lastSelectedDate = selectedDate;
}

@end

@implementation LIYFakeUserDefaults

- (instancetype)init {
    self = [super init];
    if (self) {
        self.data = [@{} mutableCopy];
    }

    return self;
}

- (nullable id)objectForKey:(NSString *)defaultName {
    return self.data[defaultName];
}

- (void)setObject:(nullable id)value forKey:(NSString *)defaultName {
    self.data[defaultName] = value;
}

@end

