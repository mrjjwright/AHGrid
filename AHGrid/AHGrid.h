//
//  AHScreen.h
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AHRow.h"
#import "AHCell.h"
#import "TUIKit.h"
#import "TUILayout.h"
#import "AHGridExpandedCell.h"
#import "AHGridPickerView.h"
#import "AHGridDetailView.h"

@class AHGrid;
@class AHRow;
@class AHCell;
@class AHGridPickerView;
@class AHGridDetailView;
@protocol AHGridInitDelegate;

typedef void(^AHGridRowConfigureBlock)(AHGrid* grid, AHRow *row, NSUInteger index);
typedef void(^AHGridCellConfigureBlock)(AHGrid* grid, AHRow *row, AHCell *cell, NSUInteger index);

@interface AHGrid : TUILayout  <TUILayoutDataSource>


@property (nonatomic, weak) id<AHGridInitDelegate> initDelegate;
@property (nonatomic, weak) AHGridPickerView *picker;
@property (nonatomic, weak) AHGridDetailView *detailView;
@property (nonatomic) NSInteger numberOfRows;
@property (nonatomic, weak) AHRow *selectedRow;
@property (nonatomic, weak) AHCell *selectedCell;
@property (nonatomic) NSInteger selectedRowIndex;
@property (nonatomic) NSInteger selectedCellIndex;
@property (nonatomic) NSInteger expandedRowIndex;
@property (nonatomic) BOOL inConfigurationMode;
@property (nonatomic, copy) AHGridRowConfigureBlock rowConfigureBlock; 
@property (nonatomic, copy) AHGridCellConfigureBlock cellConfigureBlock; 


-(void) toggleSelectedRowExpanded;
-(void) showCommentEditorOnSelectedCell;
-(void) populateDetailView;
@end


@protocol AHGridInitDelegate <NSObject>

@required
// Populating subview items 
- (void)initGrid:(AHGrid *)grid;
@end
