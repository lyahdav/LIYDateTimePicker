//
//  MZDayPicker.m
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

#import "MZDayPicker.h"
#import "MZDayPickerCell.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+CupertinoYankee.h"

CGFloat const kDefaultDayLabelFontSize = 25.0f;
CGFloat const kDefaultDayNameLabelFontSize = 11.0f;

CGFloat const kDefaultCellHeight = 84.0f;
CGFloat const kDefaultCellWidth = 45.7f;
CGFloat const kDefaultCellFooterHeight = 8.0f;

CGFloat const kDefaultDayLabelMaxZoomValue = 10.0f;

NSInteger const kDefaultInitialInactiveDays = 30;
NSInteger const kDefaultFinalInactiveDays = 30;

#define kDefaultColorInactiveDay [UIColor lightGrayColor]
#define kDefaultColorBackground [UIColor whiteColor]

#define kDefaultShadowCellColor [UIColor darkGrayColor]
#define kDefaultShadowCellOffset CGSizeMake(0.0, 0.0)
#define kDefaultShadowCellRadius 5

#define kDefaultColorDay [UIColor grayColor]
#define kDefaultColorDayCurrent [UIColor whiteColor]
#define kDefaultColorDayName [UIColor grayColor]
#define kDefaultColorBottomBorder [UIColor colorWithRed:0.22f green:0.57f blue:0.80f alpha:1.00f]
#define kDefaultColorBottomBorderToday [UIColor redColor]


#define kDefaultColorCurrentDayHighlight [UIColor colorWithRed:89.0f/255.0f green:199.0f/255.0f blue:241.0f/255.0f alpha:1.00f]
#define kSelectedDayIndicatorViewTag 99



#define kDefaultDayLabelFont @"HelveticaNeue"
#define kDefaultDayNameLabelFont @"HelveticaNeue-Medium"


static BOOL NSRangeContainsRow(NSRange range, NSInteger row) {
	if (row <= range.location + range.length  && row >= range.location) {
		return YES;
	}
    
	return NO;
}

@interface MZDayPicker ()
<
UICollectionViewDelegate,
UICollectionViewDataSource
>

@property (nonatomic, assign) CGFloat dayCellFooterHeight;
@property (nonatomic, assign) CGRect initialFrame;// initialFrame property is a hack for initWithCoder:
@property (nonatomic, assign) CGSize dayCellSize;
@property (nonatomic, assign) NSRange activeDays;
@property (nonatomic, strong) NSArray *tableDaysData;
@property (nonatomic, strong) NSIndexPath *currentIndex;
@property (nonatomic, strong) UICollectionView *collectionView;

@end


@implementation MZDayPicker

- (void)setMonth:(NSInteger)month {
	if (_month != month) {
		_month = month;
        
		[self fillTableDataWithCurrentMonth];
		[self setupTableViewContent];
	}
}

- (void)setYear:(NSInteger)year {
	if (_year != year) {
		_year = year;
        
		[self fillTableDataWithCurrentMonth];
		[self setupTableViewContent];
	}
}

- (void)setStartDate:(NSDate *)startDate {
	if (self.endDate)
		[self setStartDate:startDate endDate:self.endDate];
	else
		[self setStartDate:startDate endDate:[startDate dateByAddingTimeInterval:3600 * 24]];
}

- (void)setEndDate:(NSDate *)endDate {
	if (self.startDate)
		[self setStartDate:self.startDate endDate:endDate];
	else
		[self setStartDate:[endDate dateByAddingTimeInterval:-3600 * 24] endDate:endDate];
}

- (void)setDayLabelFontSize:(CGFloat)dayLabelFontSize {
	_dayLabelFontSize = dayLabelFontSize;
	[self.collectionView reloadData];
}

- (void)setDayNameLabelFontSize:(CGFloat)dayNameLabelFontSize {
	_dayNameLabelFontSize = dayNameLabelFontSize;
	[self.collectionView reloadData];
}

- (void)setDayLabelFont:(NSString *)dayLabelFont
{
    _dayLabelFont = dayLabelFont;
    [self.collectionView reloadData];
}

- (void)setDayNameLabelFont:(NSString *)dayNameLabelFont
{
    _dayNameLabelFont = dayNameLabelFont;
    [self.collectionView reloadData];
}

- (void)setActiveDaysFrom:(NSInteger)fromDay toDay:(NSInteger)toDay
{
    self.activeDays = NSMakeRange(fromDay, toDay-fromDay);
}

- (void)setActiveDays:(NSRange)activeDays {
	_activeDays = activeDays;
    
	[self.collectionView reloadData];
    
	[self setupTableViewContent];
}

- (void)setCurrentDay:(NSInteger)currentDay
             animated:(BOOL)animated {
	_currentDay = currentDay;
    
	self.currentIndex = [NSIndexPath indexPathForRow:0 inSection:_currentDay];
    
	[self setupTableViewContent];
}

- (void)setCurrentDay:(NSInteger)currentDay {
	[self setCurrentDay:currentDay animated:NO];
}

- (void)setCurrentDate:(NSDate *)date animated:(BOOL)animated {
	if (date) {
		NSInteger components = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
        
		NSCalendar *currentCalendar = [NSCalendar currentCalendar];
		NSDateComponents *componentsFromDate = [currentCalendar components:components
		                                                          fromDate:date];
        
		[self.tableDaysData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		    MZDay *day = obj;
            
		    NSDateComponents *componentsFromDayDate = [currentCalendar components:components
		                                                                 fromDate:day.date];
            
		    NSDate *searchingDate = [currentCalendar dateFromComponents:componentsFromDate];
		    NSDate *dayDate = [currentCalendar dateFromComponents:componentsFromDayDate];
            
		    NSComparisonResult result = [searchingDate compare:dayDate];
            
		    if (result == NSOrderedSame) {
		        _currentDate = date;
		        [self setCurrentDay:idx
                           animated:animated];
		        *stop = YES;
			}
		}];
	}
}

- (void)setCurrentDate:(NSDate *)date {
	[self setCurrentDate:date animated:NO];
}

- (void)setCurrentIndex:(NSIndexPath *)currentIndex {
	_currentIndex = currentIndex;
    
    [self.collectionView scrollToItemAtIndexPath:currentIndex
                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                        animated:YES];
}

- (void)reloadData {
	[self.collectionView reloadData];
	[self setupTableViewContent];
}

- (void)setFrame:(CGRect)frame {
	if (CGRectIsEmpty(self.initialFrame)) self.initialFrame = frame;
    
	[super setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)];
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		_activeDayColor = kDefaultColorDay;
		_activeDayNameColor = kDefaultColorDayName;
        _currentDayNameColor = kDefaultColorDayCurrent;
        _currentDayHighlightColor = kDefaultColorCurrentDayHighlight;
		_inactiveDayColor = kDefaultColorInactiveDay;
		_backgroundPickerColor = kDefaultColorBackground;
		_bottomBorderColor = kDefaultColorBottomBorder;
        _bottomBorderColorToday = kDefaultColorBottomBorderToday;
		_dayLabelZoomScale = kDefaultDayLabelMaxZoomValue;
		_dayLabelFontSize = kDefaultDayLabelFontSize;
		_dayNameLabelFontSize = kDefaultDayNameLabelFontSize;
		_dayLabelFont = kDefaultDayLabelFont;
		_dayNameLabelFont = kDefaultDayLabelFont;
        
		[self setActiveDaysFrom:1
                          toDay:[NSDate dateFromDay:1
                                              month:self.month
                                               year:self.year].numberOfDaysInMonth - 1];
        
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
		self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)
                                                 collectionViewLayout:layout];
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
        self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 15);
		self.collectionView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		self.collectionView.backgroundColor = [UIColor clearColor];
		self.collectionView.showsVerticalScrollIndicator = NO;
		self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        [self.collectionView registerClass:[MZDayPickerCell class]
                forCellWithReuseIdentifier:NSStringFromClass([MZDayPickerCell class])];
        
		[self addSubview:self.collectionView];
        
		self.backgroundColor = kDefaultColorBackground;
        //People can set shadows themselves if they want them
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
    
	[self setupTableViewContent];
    
	[self setCurrentDate:self.currentDate animated:NO];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self =  [self initWithFrame:CGRectMake(0, 0, self.initialFrame.size.width, self.initialFrame.size.height)
                        dayCellSize:CGSizeMake(kDefaultCellWidth,
                                               kDefaultCellHeight)
                dayCellFooterHeight:kDefaultCellFooterHeight
                              month:1
                               year:1970];
        
		if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0) {
			self.frame = CGRectMake(self.initialFrame.origin.x, 0,
                                    self.frame.size.width,
                                    self.initialFrame.origin.y +
                                    self.frame.size.height +
                                    self.dayCellFooterHeight);
		}
		else {
			self.frame = CGRectMake(self.initialFrame.origin.x,
                                    self.initialFrame.origin.y,
                                    self.frame.size.width,
                                    self.initialFrame.size.height + self.dayCellFooterHeight);
		}
	}
    
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame
                  dayCellSize:(CGSize)cellSize
          dayCellFooterHeight:(CGFloat)footerHeight {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
	return [self initWithFrame:frame
                   dayCellSize:cellSize
           dayCellFooterHeight:kDefaultCellFooterHeight
                         month:components.month
                          year:components.year];
}

- (instancetype)initWithFrame:(CGRect)frame
                        month:(NSInteger)month
                         year:(NSInteger)year {
	return [self initWithFrame:frame
                       dayCellSize:CGSizeMake(kDefaultCellWidth, kDefaultCellHeight)
               dayCellFooterHeight:kDefaultCellFooterHeight
                             month:month
                          year:year];
}

- (instancetype)initWithFrame:(CGRect)frame
                  dayCellSize:(CGSize)cellSize
          dayCellFooterHeight:(CGFloat)footerHeight
                        month:(NSInteger)month
                         year:(NSInteger)year {
	_dayCellSize = cellSize;
	_dayCellFooterHeight = footerHeight;
    
    self = [self initWithFrame:frame];
    
	if (self) {
		_month = month;
		_year = year;
        
		[self fillTableDataWithCurrentMonth];
        
		self.currentDay = 14;
	}
    
	return self;
}

- (void)setupTableViewContent {
	// *|1|2|3|4|5
	CGFloat startActiveDaysWidth = (kDefaultInitialInactiveDays * self.dayCellSize.width) + ((self.activeDays.location - 1) * self.dayCellSize.width);
    
	CGFloat contentSizeLimit = startActiveDaysWidth + ((self.activeDays.length + 1) * self.dayCellSize.width) + (self.frame.size.width / 2) - (self.dayCellSize.width / 2);
    
	self.collectionView.contentSize = CGSizeMake(contentSizeLimit, self.collectionView.frame.size.height);
}

- (void)setStartDate:(NSDate *)startDate
             endDate:(NSDate *)endDate {
	_startDate = [NSDate dateWithNoTime:startDate middleDay:YES];
	_endDate = [NSDate dateWithNoTime:endDate middleDay:YES];
    
	NSMutableArray *tableData = [NSMutableArray array];
    
	NSDateFormatter *dateNameFormatter = [[NSDateFormatter alloc] init];
	[dateNameFormatter setDateFormat:@"EEEE"];
    
	NSDateFormatter *dateNumberFormatter = [[NSDateFormatter alloc] init];
	[dateNumberFormatter setDateFormat:@"dd"];
    
	for (int i = kDefaultInitialInactiveDays; i >= 1; i--) {
		NSDate *date = [_startDate dateByAddingTimeInterval:-(i * 60.0 * 60.0 * 24.0)];
        
		MZDay *newDay = [[MZDay alloc] init];
		newDay.day = @([[dateNumberFormatter stringFromDate:date] integerValue]);
		newDay.name = [dateNameFormatter stringFromDate:date];
		newDay.date = date;
        
		[tableData addObject:newDay];
	}
    
	NSInteger numberOfActiveDays = 0;
    
	for (NSDate *date = _startDate; [date compare:_endDate] <= 0; date = [date dateByAddingTimeInterval:24 * 60 * 60]) {
		MZDay *newDay = [[MZDay alloc] init];
		newDay.day = @([[dateNumberFormatter stringFromDate:date] integerValue]);
		newDay.name = [dateNameFormatter stringFromDate:date];
		newDay.date = date;
        
		[tableData addObject:newDay];
        
		numberOfActiveDays++;
	}
    
	for (int i = 1; i <= kDefaultFinalInactiveDays; i++) {
		NSDate *date = [_endDate dateByAddingTimeInterval:(i * 60.0 * 60.0 * 24.0)];
        
		MZDay *newDay = [[MZDay alloc] init];
		newDay.day = @([[dateNumberFormatter stringFromDate:date] integerValue]);
		newDay.name = [dateNameFormatter stringFromDate:date];
		newDay.date = date;
        
		[tableData addObject:newDay];
	}
    
	self.tableDaysData = [tableData copy];
    
	[self setActiveDaysFrom:1
                      toDay:numberOfActiveDays];
    
	[self.collectionView reloadData];
}

- (void)fillTableDataWithCurrentMonth {
	NSDate *startDate = [NSDate dateFromDay:1 month:self.month year:self.year];
	NSDate *endDate = [NSDate dateFromDay:startDate.numberOfDaysInMonth - 1 month:self.month year:self.year];
    
	[self setStartDate:startDate endDate:endDate];
}

- (MZDayPickerCell *)cellForDay:(MZDay *)day {
    return (MZDayPickerCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self.tableDaysData indexOfObject:day]]];
}

- (CGFloat)bottomBorderHeightForIndexPath:(NSIndexPath *)indexPath {
    MZDay *day = self.tableDaysData[indexPath.section];

    BOOL sameDay = [[[NSDate date] beginningOfDay] isSameDayAsDate:day.date];
    return sameDay ? 1.0f : 0.0f;
}




#pragma mark - Cell Formatting

-(void) formatCellForSelectedDay:(MZDayPickerCell *)cell{
    
    UIView *blueDot = [[UIView alloc]  initWithFrame:CGRectMake(2.0f, 42.0f, 40.0f, 40.0f)];
    blueDot.backgroundColor = self.selectedDayColor;
    blueDot.layer.cornerRadius = 20.0f;
    [blueDot.layer masksToBounds];
    blueDot.tag = kSelectedDayIndicatorViewTag;
    
    [cell.containerView insertSubview:blueDot atIndex:0];
}


-(void) formatCellDayLabel:(MZDayPickerCell *) cell forIndexPath:(NSIndexPath *) indexPath{
    
    MZDay *day = self.tableDaysData[indexPath.section];
    BOOL sameDay = [[[NSDate date] beginningOfDay] isSameDayAsDate:day.date];
    
    [[cell.containerView viewWithTag:kSelectedDayIndicatorViewTag] removeFromSuperview];
    

    
    if (![indexPath compare: _currentIndex]) {
        
        // selected day
        cell.dayLabel.font = [UIFont fontWithName:self.daySelectedFont size:self.dayLabelFontSize];
        cell.dayLabel.textColor = [UIColor whiteColor];
        [self formatCellForSelectedDay:cell];
        
    }else {
        
        if (sameDay) {

            // current day
            cell.dayLabel.textColor = self.currentDayHighlightColor;
            cell.dayLabel.font = [UIFont fontWithName:self.daySelectedFont size:self.dayLabelFontSize];
            
        }else{
        
            // normal day
            cell.dayLabel.font = [UIFont fontWithName:self.dayLabelFont size:self.dayLabelFontSize];
            cell. dayLabel.textColor = self.activeDayNameColor;
        }
        
    }
}


#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(dayPicker:scrollViewDidScroll:)]) {
		[self.delegate dayPicker:self scrollViewDidScroll:scrollView];
	}
    
	CGPoint centerTableViewPoint = [self convertPoint:CGPointMake(self.frame.size.width / 2.0, self.dayCellSize.width / 2.0) toView:self.collectionView];
	// Zooming visible cell's
	for (MZDayPickerCell *cell in self.collectionView.visibleCells) {
        // Distance between cell center point and center of tableView
        CGFloat distance = cell.center.x - centerTableViewPoint.x + 7.5;
        // Zoom step using cosinus
        CGFloat zoomStep = cosf(M_PI_2 * distance / cell.frame.size.width);

        
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        
        if (distance < self.dayCellSize.width && distance > -self.dayCellSize.width) {
            [cell setBottomBorderSlideHeight:zoomStep];
        }
        else {
            [cell setBottomBorderSlideHeight:[self bottomBorderHeightForIndexPath:indexPath]];
        }
        
        [self formatCellDayLabel:cell forIndexPath:indexPath];

	}
}





- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if ([self.delegate respondsToSelector:@selector(dayPicker:scrollViewDidEndDecelerating:)]) {
		[self.delegate dayPicker:self scrollViewDidEndDecelerating:scrollView];
	}
    
	[self scrollViewDidFinishScrolling:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if ([self.delegate respondsToSelector:@selector(dayPicker:scrollViewDidEndDragging:)]) {
		[self.delegate dayPicker:self scrollViewDidEndDragging:scrollView];
	}
    
	if (!decelerate) {
		[self scrollViewDidFinishScrolling:scrollView];
	}
}



- (void)scrollViewDidFinishScrolling:(UIScrollView *)scrollView {
	CGPoint centerTableViewPoint = [self convertPoint:CGPointMake(self.frame.size.width / 2.0, self.dayCellSize.width / 2.0) toView:self.collectionView];
    
	NSIndexPath *centerIndexPath = [self.collectionView indexPathForItemAtPoint:centerTableViewPoint];
    
	if ([centerIndexPath compare:self.currentIndex]) {
		if ([self.delegate respondsToSelector:@selector(dayPicker:willSelectDay:)])
			[self.delegate dayPicker:self willSelectDay:self.tableDaysData[centerIndexPath.section]];
	}
    
    _currentDay = centerIndexPath.section - 1;
    _currentDate = [(MZDay *)self.tableDaysData[centerIndexPath.section] date];
    self.currentIndex = centerIndexPath;
    
    if ([self.delegate respondsToSelector:@selector(dayPicker:didSelectDay:)]){
        [self.delegate dayPicker:self didSelectDay:self.tableDaysData[centerIndexPath.section]];
    }
}



#pragma mark - UICollectionViewDataSource

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout  *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.dayCellSize;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.tableDaysData.count;
}




- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
	MZDayPickerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([MZDayPickerCell class])
                                                                      forIndexPath:indexPath];
    
	if (!cell) {
		cell = [[MZDayPickerCell alloc] initWithSize:self.dayCellSize
                                        footerHeight:self.dayCellFooterHeight];
	}
    
	MZDay *day = self.tableDaysData[indexPath.section];
    
    cell.footerHeight = self.dayCellFooterHeight;
	cell.dayLabel.font = [UIFont fontWithName:self.dayLabelFont size:self.dayLabelFontSize];
    
	cell.dayLabel.textColor = self.activeDayNameColor;
	cell.dayNameLabel.font = [UIFont fontWithName:self.dayNameLabelFont size:self.dayNameLabelFontSize];
    
	cell.dayNameLabel.textColor = self.activeDayNameColor;
	cell.bottomBorderColor = self.bottomBorderColor;
    
	cell.dayLabel.text = [NSString stringWithFormat:@"%@", day.day];
	cell.dayNameLabel.text = [NSString stringWithFormat:@"%@", day.name.uppercaseString];
    
	if ([self.dataSource respondsToSelector:@selector(dayPicker:titleForCellDayLabelInDay:)]) {
		cell.dayLabel.text = [self.dataSource dayPicker:self titleForCellDayLabelInDay:day];
	}
    
	if ([self.dataSource respondsToSelector:@selector(dayPicker:titleForCellDayNameLabelInDay:)]) {
		cell.dayNameLabel.text = [self.dataSource dayPicker:self titleForCellDayNameLabelInDay:day].uppercaseString;
	}
    
    
    [self formatCellDayLabel:cell forIndexPath:indexPath];
    
	return cell;
}



- (void)setShadowForCell:(MZDayPickerCell *)cell {
	cell.containerView.layer.masksToBounds = NO;
	cell.containerView.layer.shadowOffset = kDefaultShadowCellOffset;
	cell.containerView.layer.shadowRadius = kDefaultShadowCellRadius;
	cell.containerView.layer.shadowOpacity = 0.0;
	cell.containerView.layer.shadowColor = kDefaultShadowCellColor.CGColor;
	cell.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRect:cell.containerView.bounds].CGPath;
}

#pragma mark - UICollectionViewDelegate Methods

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath compare:self.currentIndex]) {
        if ([self.delegate respondsToSelector:@selector(dayPicker:willSelectDay:)])
            [self.delegate dayPicker:self willSelectDay:self.tableDaysData[indexPath.section]];
        
        _currentDay = indexPath.section - 1;
        _currentDate = [(MZDay *)self.tableDaysData[indexPath.section] date];
        [self setCurrentIndex:indexPath];
        
        if ([self.delegate respondsToSelector:@selector(dayPicker:didSelectDay:)]){
            [self.delegate dayPicker:self didSelectDay:self.tableDaysData[self.currentIndex.section]];
        }
    }
    
    return YES;
}

@end

#pragma mark - NSDate (Additional) implementation

@implementation NSDate (Additional)

+ (NSDate *)dateFromDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year {
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [[NSDateComponents alloc] init];
	[calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    
	[components setDay:day];
    
	if (month <= 0) {
		[components setMonth:12 - month];
		[components setYear:year - 1];
	}
	else if (month >= 13) {
		[components setMonth:month - 12];
		[components setYear:year + 1];
	}
	else {
		[components setMonth:month];
		[components setYear:year];
	}
    
    
	return [NSDate dateWithNoTime:[calendar dateFromComponents:components] middleDay:NO];
}

+ (NSDate *)dateWithNoTime:(NSDate *)dateTime middleDay:(BOOL)middle {
	if (dateTime == nil) {
		dateTime = [NSDate date];
	}
    
	NSCalendar *calendar   = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	NSDateComponents *components = [[NSDateComponents alloc] init];
	components = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
	                         fromDate:dateTime];
    
	NSDate *dateOnly = [calendar dateFromComponents:components];
    
	if (middle)
		dateOnly = [dateOnly dateByAddingTimeInterval:(60.0 * 60.0 * 12.0)];          // Push to Middle of day.
    
	return dateOnly;
}

- (NSUInteger)numberOfDaysInMonth {
	NSCalendar *c = [NSCalendar currentCalendar];
	NSRange days = [c rangeOfUnit:NSDayCalendarUnit
	                       inUnit:NSMonthCalendarUnit
	                      forDate:self];
    
	return days.length;
}

- (BOOL)isSameDayAsDate:(NSDate*)date
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:self];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date];
    
    return [comp1 day] == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}

@end
