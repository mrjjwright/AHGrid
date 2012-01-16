//
//  AHDetailView.h
//  AHGrid
//
//  Created by John Wright on 1/12/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "TUIKit.h"
#import "AHGrid.h"

@class AHCell;

@interface AHGridExpandedCell : TUIScrollView


-(void) setCellToExpand:(AHCell*) cell;

@end
