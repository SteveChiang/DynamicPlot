//
//  DynamicPlotView.h
//  DynamicPlot
//
//  Created by Steve Chiang on 12/5/20.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
@interface DynamicPlotView : UIView <CPTPlotDataSource, CPTPlotSpaceDelegate>
@end
