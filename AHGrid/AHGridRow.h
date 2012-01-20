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
#import "TUILayout.h"
#import "AHGridExpandedCell.h"

@class AHGrid;
@class AHGridExpandedCell;

@interface AHGridRow : TUIView <TUILayoutDataSource>

@property (nonatomic) NSInteger numberOfCells;
@property (nonatomic, strong) AHGridExpandedCell *expandedCell;
@property (nonatomic) BOOL animating;
@property (nonatomic, weak) AHGrid *grid;
@property (nonatomic) NSUInteger index;
@property (nonatomic, strong) TUILayout *listView;
@property (nonatomic) BOOL expanded;
@property (nonatomic) BOOL selected;
@property (nonatomic, weak) Class cellClass;

@property (nonatomic,strong) NSString * titleString;

@end
