//
//  MZDayPickerCell.m
//  MZDayPicker
//
//  Created by Michał Zaborowski on 18.04.2013.
//  Copyright (c) 2013 whitecode. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "MZDayPickerCell.h"

@interface MZDayPickerCell ()
@property (nonatomic, strong) UIView *bottomBorderView;
@property (nonatomic, assign) CGSize cellSize;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *dayLabel;
@property (nonatomic, strong) UILabel *dayNameLabel;
@end

@implementation MZDayPickerCell

- (void)setBottomBorderSlideHeight:(CGFloat)height {
	CGRect bottomBorderRect = self.bottomBorderView.frame;
	bottomBorderRect.size.height = height * self.footerHeight;
	self.bottomBorderView.frame = bottomBorderRect;
}

- (void)setBottomBorderColor:(UIColor *)color {
	self.bottomBorderView.backgroundColor = color;
}

- (void)setFooterHeight:(CGFloat)footerHeight {
    _footerHeight = footerHeight;
	CGRect bottomBorderRect = self.bottomBorderView.frame;
	bottomBorderRect.size.height = footerHeight;
    bottomBorderRect.origin.y = self.frame.size.height - footerHeight;
	self.bottomBorderView.frame = bottomBorderRect;
}

- (instancetype)initWithSize:(CGSize)size
                footerHeight:(CGFloat)footerHeight {
	if (self = [super initWithFrame:CGRectMake(0, 0, size.width, size.height)]) {
		if (CGSizeEqualToSize(size, CGSizeZero)) {
			[NSException raise:NSInvalidArgumentException format:@"MZDayPickerCell size can't be zero!"];
        }
		else {
			self.cellSize = size;
        }
        
		self.footerHeight = footerHeight;
        
		[self applyCellStyle];
	}
    
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	return [self initWithSize:frame.size
	             footerHeight:8.f];
}

- (void)applyCellStyle {
	UIView *containingView = [[UIView alloc] initWithFrame:CGRectMake(self.footerHeight, 0, self.cellSize.width, self.cellSize.height)];
    
	self.dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.cellSize.width, self.cellSize.height)];
	self.dayLabel.center = CGPointMake(containingView.frame.size.width / 2, self.cellSize.height / 2.6);
	self.dayLabel.textAlignment = NSTextAlignmentCenter;
	self.dayLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:self.dayLabel.font.pointSize];
	self.dayLabel.backgroundColor = [UIColor clearColor];
    
	self.dayNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.cellSize.width, self.cellSize.height)];
	self.dayNameLabel.center = CGPointMake(containingView.frame.size.width / 2, self.cellSize.height / 1.3);
	self.dayNameLabel.textAlignment = NSTextAlignmentCenter;
	self.dayNameLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:self.dayNameLabel.font.pointSize];
	self.dayNameLabel.backgroundColor = [UIColor clearColor];
    
	[containingView addSubview:self.dayLabel];
	[containingView addSubview:self.dayNameLabel];
    
	self.containerView = containingView;
    
	self.bottomBorderView = [[UIView alloc] initWithFrame:CGRectMake(0, self.cellSize.height - self.footerHeight, containingView.bounds.size.width, self.footerHeight)];
	[containingView addSubview:self.bottomBorderView];
    
	[self addSubview:containingView];
}

@end
