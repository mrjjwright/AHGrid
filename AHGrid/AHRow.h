//
//  AHRow.h
//  Crew
//
//  Created by John Wright on 1/3/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TUIKit.h"
#import "AHGrid.h"

@class AHGrid;

@interface AHRow : NSTableCellView <TUITableViewDelegate, TUITableViewDataSource, TUIScrollingInterceptor>

@property (nonatomic, weak) AHGrid *grid;
@property (nonatomic) NSInteger index;
@property (nonatomic, strong) TUITableView *listView;
@property (nonatomic) BOOL expanded;
@property (nonatomic) BOOL animating;

-(void) setExpandedWithAnimation:(BOOL)e;
@end
