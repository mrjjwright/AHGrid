//
//  AHScreen.h
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AHGridRow.h"
#import "AHGridCell.h"
#import "TUIKit.h"
#import "TUILayout.h"
#import "AHGridExpandedCell.h"

@class AHGrid;
@class AHGridRow;
@class AHGridCell;
@protocol AHGridInitDelegate;

#define kAHGridWillToggleExpansionOfRow @"kAHGridWillToggleExpansionOfRow"
#define kAHGridChangedCellSelection @"kAHGridChangedCellSelection"

typedef void(^AHGridConfigureRowBlock)(AHGrid* grid, AHGridRow *row, NSUInteger index);
typedef void(^AHGridConfigureCellBlock)(AHGrid* grid, AHGridRow *row, AHGridCell *cell, NSUInteger index);
typedef void(^AHGridConfigureExpandedCellBlock)(AHGrid* grid, AHGridRow *row, AHGridCell *cell, AHGridExpandedCell *expandedCell, NSUInteger index);
typedef NSInteger(^AHGridNumberOfCellsBlock)(AHGrid *grid, AHGridRow *row);

@interface AHGrid : TUILayout  <TUILayoutDataSource, TUIScrollingInterceptor>

@property (nonatomic, weak) Class cellClass; 
@property (nonatomic, weak) Class expandedCellClass; 
@property (nonatomic, weak) id<AHGridInitDelegate> initDelegate;
@property (nonatomic) NSInteger numberOfRows;
@property (nonatomic, weak) AHGridRow *selectedRow;
@property (nonatomic, weak) AHGridCell *selectedCell;
@property (nonatomic) NSInteger selectedRowIndex;
@property (nonatomic) NSInteger selectedCellIndex;
@property (nonatomic) NSInteger expandedRowIndex;
@property (nonatomic) BOOL inConfigurationMode;
@property (nonatomic, copy) AHGridConfigureRowBlock configureRowBlock; 
@property (nonatomic, copy) AHGridConfigureCellBlock configureCellBlock;
@property (nonatomic, copy) AHGridNumberOfCellsBlock numberOfCellsBlock;
@property (nonatomic, copy) AHGridConfigureExpandedCellBlock configureExpandedCellBlock;

-(void) toggleSelectedRowExpanded;

@end


@protocol AHGridInitDelegate <NSObject>

@required
// Populating subview items 
- (void)initGrid:(AHGrid *)grid;
@end
