//
// Created by Liron Yahdav on 5/8/15.
// Copyright (c) 2015 Liron Yahdav. All rights reserved.
//

#import "UIView+LIYSpecAdditions.h"

@implementation UIView (LIYSpecAdditions)

- (UILabel *)liy_specsFindLabelWithText:(NSString *)text {
    NSPredicate *labelPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        if ([evaluatedObject isKindOfClass:[UILabel class]]) {
            UILabel *label = evaluatedObject;
            if ([self liy_isViewVisible:label] && [[evaluatedObject text] isEqualToString:text]) {
                return YES;
            }
        }
        return NO;
    }];

    return (UILabel *)[self liy_traverseDescendantsWithPredicate:labelPredicate];
}

- (UIView *)liy_specsFindViewWithAccessibilityLabel:(NSString *)accessibilityLabel {
    NSPredicate *accessibilityLabelPredicate = [NSPredicate predicateWithBlock:^BOOL(UIView *evaluatedView, NSDictionary *bindings) {
        return [self liy_isViewVisible:evaluatedView] && [evaluatedView.accessibilityLabel isEqualToString:accessibilityLabel];
    }];

    return [self liy_traverseDescendantsWithPredicate:accessibilityLabelPredicate];
}

- (UIView *)liy_specsFindViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier {
    NSPredicate *accessibilityIdentifierPredicate = [NSPredicate predicateWithBlock:^BOOL(UIView *evaluatedView, NSDictionary *bindings) {
        return [self liy_isViewVisible:evaluatedView] && [evaluatedView.accessibilityIdentifier isEqualToString:accessibilityIdentifier];
    }];

    return [self liy_traverseDescendantsWithPredicate:accessibilityIdentifierPredicate];
}

- (void)liy_specsTapButtonWithAccessibilityIdentifier:(NSString *)accessibilityIdentifer {
    UIButton *button = (UIButton *)[self liy_specsFindViewWithAccessibilityIdentifier:accessibilityIdentifer];
    NSAssert(button != nil, @"Could not find button with accessibility identifier %@", accessibilityIdentifer);
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - convenience

- (BOOL)liy_isViewVisible:(UIView *)view {
    UIView *currentView = view;
    while (currentView) {
        if (currentView.hidden) {
            return NO;
        } else {
            currentView = currentView.superview;
        }
    }
    return YES;
}

- (UIView *)liy_traverseDescendantsWithPredicate:(NSPredicate *)predicate {
    if ([predicate evaluateWithObject:self]) {
        return self;
    }

    // check subviews
    for (UIView *subview in [self subviews]) {
        UIView *result = [subview liy_traverseDescendantsWithPredicate:predicate];
        if (result) {
            return result;
        }
    }

    return nil;
}

@end
