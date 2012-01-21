//
//  AHDetailView.h
//  AHGrid
//
//  Created by John Wright on 1/12/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "TUIKit.h"
#import "AHGrid.h"

@class AHGridCell;

@interface AHGridExpandedCell : TUIScrollView

-(void) expandCell:(AHGridCell*) cell;

@end
