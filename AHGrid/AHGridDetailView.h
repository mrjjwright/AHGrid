//
//  AHGridDetailView.h
//  AHGrid
//
//  Created by John Wright on 1/15/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TUIKit.h"
#import "AHGrid.h"

@class AHCell;

@interface AHGridDetailView : TUIView

@property (nonatomic, weak) AHGrid *grid;

-(void) update;


@end
