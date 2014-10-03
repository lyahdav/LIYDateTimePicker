//
//  MSCurrentTimeGridline.m
//  Example
//
//  Created by Eric Horacek on 2/27/13.
//  Copyright (c) 2013 Monospace Ltd. All rights reserved.
//

#import "MSCurrentTimeGridline.h"
#import "UIColor+HexString.h"

@implementation MSCurrentTimeGridline

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithHexString:@"59c7f1"];
    }
    return self;
}

@end
