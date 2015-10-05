//
// Created by Liron Yahdav on 5/8/15.
// Copyright (c) 2015 Liron Yahdav. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIView (LIYSpecAdditions)

- (UILabel *)liy_specsFindLabelWithText:(NSString *)text;
- (UIView *)liy_specsFindViewWithAccessibilityLabel:(NSString *)accessibilityLabel;
- (UIView *)liy_specsFindViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier;
- (void)liy_specsTapButtonWithAccessibilityIdentifier:(NSString *)accessibilityIdentifer;

@end