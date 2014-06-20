# LIYDateTimePicker

[![Version](https://img.shields.io/cocoapods/v/LIYDateTimePicker.svg?style=flat)](http://cocoadocs.org/docsets/LIYDateTimePicker)
[![License](https://img.shields.io/cocoapods/l/LIYDateTimePicker.svg?style=flat)](http://cocoadocs.org/docsets/LIYDateTimePicker)
[![Platform](https://img.shields.io/cocoapods/p/LIYDateTimePicker.svg?style=flat)](http://cocoadocs.org/docsets/LIYDateTimePicker)

<img src="https://raw.githubusercontent.com/lyahdav/LIYDateTimePicker/master/Screens/Screen1.png" alt="Calendar" width="320px"/>
<img src="https://raw.githubusercontent.com/lyahdav/LIYDateTimePicker/master/Screens/Screen2.png" alt="Calendar" width="320px"/>

## Usage

To run the example project; clone the repo, and run `pod install` from the Example directory first.

All you need to use this in your app is:

    LIYDateTimePickerViewController *vc = [LIYDateTimePickerViewController timePickerForDate:[NSDate date] delegate:self];
    [self.navigationController pushViewController:vc animated:YES];

And implement the `LIYDateTimePickerDelegate`:

    - (void)dateTimePicker:(LIYDateTimePickerViewController *)dateTimePickerViewController didSelectDate:(NSDate *)selectedDate {
        self.selectedTimeLabel.text = [selectedDate description];
        [self.navigationController popViewControllerAnimated:YES];
    }


## Requirements

LIYDateTimePicker requires either iOS 7.x and above.

## Installation

LIYDateTimePicker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "LIYDateTimePicker"

## Author

Liron Yahdav

## License

LIYDateTimePicker is available under the MIT license. See the LICENSE file for more info.

