//
//  DynamicPlotView.m
//  DynamicPlot
//
//  Created by Steve Chiang on 12/5/20.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "DynamicPlotView.h"
#define xMax 20
const NSUInteger kMaxDataPoints = 50; // cache 50 records
NSString *const ReadingLine = @"Reading";
NSString *const MaxLine = @"Max Warning Line";
NSString *const MinLine = @"Min Warning Line";
@interface DynamicPlotView() {
    double mMinValue;
    double mMaxValue;
    
    double mWarningMin;
    double mWarningMax;
    
    CGFloat mCurrentValue;
    NSString *mUnit;
    
    NSMutableArray *plotData;
	NSUInteger mCurrentIndex;
	NSTimer *mDataTimer;
    CPTGraph *mGraph;
    CPTGraphHostingView *mHostView;
}
-(void)setupParams;
-(void)generateGraph;
-(void)generateData;
-(void)newData:(NSTimer *)theTimer;
@end

@implementation DynamicPlotView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupParams];
        
        [self generateGraph];
        [self addSubview:mHostView];
        [self generateData];
    }
    return self;
}

-(void)setupParams {
    plotData  = [[NSMutableArray alloc] initWithCapacity:kMaxDataPoints];
    mDataTimer = nil;
    
    mMinValue = -20;
    mMaxValue = 70;
    mWarningMin = 10;
    mWarningMax = 50;
    
    mUnit = @"Unit";
}

-(void)generateGraph {
    mHostView = [[CPTGraphHostingView alloc] initWithFrame:self.bounds];
    mGraph = [[CPTXYGraph alloc] initWithFrame:self.bounds];
    [mGraph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    mHostView.hostedGraph = mGraph;
	mGraph.plotAreaFrame.paddingTop	= 15.0;
	mGraph.plotAreaFrame.paddingRight = 10.0;
	mGraph.plotAreaFrame.paddingBottom = 30.0;
	mGraph.plotAreaFrame.paddingLeft = 65.0;
    
	// Grid line styles
	CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
	majorGridLineStyle.lineWidth = 0.75;
	majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
    
	CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
	minorGridLineStyle.lineWidth = 0.25;
	minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
    
    // Axes
	// X axis
	CPTXYAxisSet *axisSet = (CPTXYAxisSet*)mGraph.axisSet;
	CPTXYAxis *x = axisSet.xAxis;
	x.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
	x.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(0);
	x.majorGridLineStyle = majorGridLineStyle;
	x.minorGridLineStyle = minorGridLineStyle;
	x.minorTicksPerInterval = 9;
	x.title	= @"";
	x.titleOffset = 35.0;
	NSNumberFormatter *labelFormatter = [[NSNumberFormatter alloc] init];
	labelFormatter.numberStyle = NSNumberFormatterNoStyle;
	x.labelFormatter = labelFormatter;
	[labelFormatter release];
    
	// Y axis
	CPTXYAxis *y = axisSet.yAxis;
	y.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
	y.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(0);
	y.majorGridLineStyle = majorGridLineStyle;
	y.minorGridLineStyle = minorGridLineStyle;
	y.minorTicksPerInterval	 = 3;
	y.labelOffset = 5.0;
	y.title	 = mUnit;
	y.titleOffset = 40.0;
	y.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    
	// rotate labels by 45 degree
	x.labelRotation = M_PI * 0.25;
    
    // --- lines ---
	CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle lineStyle];
    
    // reading line
	CPTScatterPlot *readingLinePlot = [[[CPTScatterPlot alloc] init] autorelease];
	readingLinePlot.identifier = ReadingLine;
	readingLinePlot.cachePrecision = CPTPlotCachePrecisionDouble;
    
	lineStyle.lineWidth	= 1.0;
	lineStyle.lineColor	= [CPTColor greenColor];
	readingLinePlot.dataLineStyle = lineStyle;
    
	readingLinePlot.dataSource = self;
	[mGraph addPlot:readingLinePlot];
    
    // Add plot symbols
	CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
	symbolLineStyle.lineColor = [CPTColor greenColor];
	CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
	plotSymbol.fill = [CPTFill fillWithColor:[CPTColor greenColor]];
	plotSymbol.lineStyle = symbolLineStyle;
	plotSymbol.size = CGSizeMake(5.0, 5.0);
	readingLinePlot.plotSymbol = plotSymbol;
    
    
    // max line
    CPTScatterPlot *maxLinePlot = [[[CPTScatterPlot alloc] init] autorelease];
	maxLinePlot.identifier = MaxLine;
    readingLinePlot.cachePrecision = CPTPlotCachePrecisionDouble;
    
	lineStyle.lineWidth	= 2.0;
	lineStyle.lineColor	 = [CPTColor redColor];
	lineStyle.dashPattern = [NSArray arrayWithObjects:[NSNumber numberWithInteger:10], [NSNumber numberWithInteger:6], nil];
	maxLinePlot.dataLineStyle = lineStyle;
    
	maxLinePlot.dataSource = self;
	[mGraph addPlot:maxLinePlot];
    
    // min line
    CPTScatterPlot *minLinePlot = [[[CPTScatterPlot alloc] init] autorelease];
	minLinePlot.identifier = MinLine;
    readingLinePlot.cachePrecision = CPTPlotCachePrecisionDouble;
    
	lineStyle = [CPTMutableLineStyle lineStyle];
	lineStyle.lineWidth	= 2.0;
	lineStyle.lineColor = [CPTColor orangeColor];
	lineStyle.dashPattern = [NSArray arrayWithObjects:[NSNumber numberWithInteger:10], [NSNumber numberWithInteger:6], nil];
	minLinePlot.dataLineStyle = lineStyle;
    
	minLinePlot.dataSource = self;
	[mGraph addPlot:minLinePlot];
    
	// Plot space
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace*)mGraph.defaultPlotSpace;
	plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(0) length:CPTDecimalFromUnsignedInteger(xMax - 1)];
	plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(mMinValue-10) length:CPTDecimalFromDouble(mMaxValue-mMinValue+20)];
    plotSpace.allowsUserInteraction = YES;
    plotSpace.delegate = self;
}

-(void)generateData {
    [plotData removeAllObjects];
	mCurrentIndex = 0;
	[mDataTimer release];
	mDataTimer = [[NSTimer timerWithTimeInterval:0.5
                                          target:self
                                        selector:@selector(newData:)
                                        userInfo:nil
                                         repeats:YES] retain];
	[[NSRunLoop mainRunLoop] addTimer:mDataTimer forMode:NSDefaultRunLoopMode];
}

-(void)newData:(NSTimer *)theTimer {
	CPTPlot *readingLinePlot = [mGraph plotWithIdentifier:ReadingLine];
    CPTPlot *maxLinePlot = [mGraph plotWithIdentifier:MaxLine];
    CPTPlot *minLinePlot = [mGraph plotWithIdentifier:MinLine];
	if (readingLinePlot && maxLinePlot && minLinePlot) {
		if ( plotData.count >= kMaxDataPoints ) {
			[plotData removeObjectAtIndex:0];
			[readingLinePlot deleteDataInIndexRange:NSMakeRange(0, 1)];
            [maxLinePlot deleteDataInIndexRange:NSMakeRange(0, 1)];
            [minLinePlot deleteDataInIndexRange:NSMakeRange(0, 1)];
		}
        
		CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace*)mGraph.defaultPlotSpace;
		NSUInteger location	 = (mCurrentIndex >= xMax ? mCurrentIndex - xMax + 1 : 0);
		plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(location)
														length:CPTDecimalFromUnsignedInteger(xMax - 1)];
        
		mCurrentIndex++;
        double rnd = (arc4random() % 90);
        rnd -= 20.0f;
		[plotData addObject:[NSNumber numberWithDouble:rnd]];
		[readingLinePlot insertDataAtIndex:plotData.count - 1 numberOfRecords:1];
        [maxLinePlot insertDataAtIndex:plotData.count - 1 numberOfRecords:1];
        [minLinePlot insertDataAtIndex:plotData.count - 1 numberOfRecords:1];
	}
    
}

#pragma mark - Plot Protocols
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
	return [plotData count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSNumber *num = nil;
	switch ( fieldEnum ) {
		case CPTScatterPlotFieldX:
			num = [NSNumber numberWithUnsignedInteger:index + mCurrentIndex - plotData.count];
			break;
            
		case CPTScatterPlotFieldY:
            if (plot.identifier == ReadingLine) {
                num = [plotData objectAtIndex:index];
            } else if (plot.identifier == MaxLine){
                num = [NSNumber numberWithDouble:mWarningMax];
            } else if (plot.identifier == MinLine) {
                num = [NSNumber numberWithDouble:mWarningMin];
            }
			break;
	}
	return num;
}

-(CPTPlotRange*)plotSpace:(CPTPlotSpace*)space willChangePlotRangeTo:(CPTPlotRange*)newRange forCoordinate:(CPTCoordinate)coordinate
{
	if (coordinate == CPTCoordinateY) {
        CPTPlotRange *maxRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(mMinValue-10) length:CPTDecimalFromDouble(mMaxValue-mMinValue+20)];
		CPTMutablePlotRange *changedRange = [[newRange mutableCopy] autorelease];
		[changedRange shiftEndToFitInRange:maxRange];
		[changedRange shiftLocationToFitInRange:maxRange];
		newRange = changedRange;
	}
	return newRange;
}

@end
