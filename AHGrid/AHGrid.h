//
//  AHScreen.h
//  Swift
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AHGridRow.h"
#import "AHGridCell.h"
#import "TUIKit.h"
#import "TUILayout.h"
#import "AHGridTypes.h"


@class AHGrid;
@class AHGridRow;
@class AHGridCell;


#define kAHGridWillResizeCell @"kAHGridWillResizeCell"
#define kAHGridDidResizeCell @"kAHGridDidResizeCell"
#define kAHGridWillResizeRow @"kAHGridWillResizeRow"
#define kAHGridDidResizeRow @"kAHGridDidResizeRow"
#define kAHGridChangedCellSelection @"kAHGridChangedCellSelection"

typedef NSUInteger(^AHGridNumberOfRowsBlock)(AHGrid *grid);
typedef void(^AHGridConfigureRowBlock)(AHGrid* grid, AHGridRow *row);
typedef NSUInteger(^AHGridNumberOfCellsBlock)(AHGrid *grid, AHGridRow *row);
typedef void(^AHGridConfigureCellBlock)(AHGrid* grid, AHGridRow *row, AHGridCell *cell);
typedef void(^AHGridRowLoadCallback)( NSUInteger numOfNewCells);
typedef void (^AHGridRowLoadHandler) (AHGrid* grid, AHGridRow *row, AHGridRowLoadCallback callback);

@interface AHGrid : TUILayout  <TUILayoutDataSource>

@property (nonatomic, weak) Class cellClass; 
@property (nonatomic, weak) Class rowHeaderClass;

@property (nonatomic, weak) AHGridRow *selectedRow;
@property (nonatomic, weak) AHGridCell *selectedCell;
@property (nonatomic) NSInteger selectedRowIndex;
@property (nonatomic) NSInteger selectedCellIndex;

@property (nonatomic) CGSize smallCellSize;
@property (nonatomic) CGSize mediumCellSize;
@property (nonatomic) CGSize largeCellSize;
@property (nonatomic) CGSize xLargeCellSize;
@property (nonatomic) CGFloat rowHeaderHeight;

@property (nonatomic, copy) AHGridNumberOfRowsBlock numberOfRowsBlock;
@property (nonatomic, copy) AHGridConfigureRowBlock configureRowBlock;
@property (nonatomic, copy) AHGridNumberOfCellsBlock numberOfCellsBlock;
@property (nonatomic, copy) AHGridConfigureCellBlock configureCellBlock;
@property (nonatomic, copy) AHGridRowLoadHandler loadAllHandler;
@property (nonatomic, copy) AHGridRowLoadHandler loadNewHandler;
@property (nonatomic, copy) AHGridRowLoadHandler loadOldHandler;


-(CGSize) rowSizeForLogicalSize:(AHGridLogicalSize) logicalSize;
-(CGSize) cellSizeForLogicalSize:(AHGridLogicalSize) cellSize;
-(void) resizeSelectedCellToSize:(AHGridLogicalSize) targetCellSize;
-(void) resizeCell:(AHGridCell*) cell toSize:(AHGridLogicalSize) logicalSize completionBlock:(void (^)())completionBlock;
-(void) toggleSelectedCellSize;
-(void) selectAndScrollToCellWithIndex:(NSUInteger) cellIndex;
-(void) selectCellInAdjacentRow:(AHGridRow*) row scrollTo:(BOOL) scrollTo;

@end