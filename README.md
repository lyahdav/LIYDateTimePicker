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
        NSLog(@"Selected date: %@", [selectedDate description]);
        [self.navigationController popViewControllerAnimated:YES];
    }


## Requirements

LIYDateTimePicker requires either iOS 7.x and above.

## Installation

Simply add the following lines to your Podfile:

    pod 'MZDayPicker', :git => 'https://github.com/joefrank99/MZDayPicker.git'
    pod 'LIYDateTimePicker', :git => 'https://github.com/lyahdav/LIYDateTimePicker.git'

NOTE: this pod requires a fork of MZDayPicker. Unfortunately according to http://stackoverflow.com/a/17735833/62 you cannot specify dependencies in a pod to pods on github. Instead you'll have to add the MZDayPicker fork before LIYDateTimePicker as shown above. You'll have to do the same for the actual LIYDateTimePicker Pod itself as well.

## Author

Liron Yahdav

## License

LIYDateTimePicker is available under the MIT license. See the LICENSE file for more info.

## Attribution

Thanks to Icons8 for the <a
href="http://icons8.com/web-app/3979/Checklist">Checklist icon</a>
