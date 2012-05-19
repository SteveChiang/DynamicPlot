//
//  ViewController.m
//  DynamicPlot
//
//  Created by Steve Chiang on 12/5/20.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "DynamicPlotView.h"
@implementation ViewController
@synthesize mPlotView;
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    DynamicPlotView *dpv = [[DynamicPlotView alloc] initWithFrame:CGRectMake(0, 0, mPlotView.frame.size.width, mPlotView.frame.size.height)];
    [mPlotView addSubview:dpv];
    [dpv release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

-(void) dealloc {
    [mPlotView release];
    [super dealloc];
}

@end
