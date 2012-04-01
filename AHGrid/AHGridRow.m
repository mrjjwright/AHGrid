//
//  AHRow.m
//  Swift
//
//  Created by John Wright on 1/3/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHGridRow.h"
#import "AHGridCell.h"
#import "AHGrid.h"

@implementation AHGridRow {
}

@synthesize animating;
@synthesize grid;
@synthesize index;
@synthesize listView;
@synthesize selected;
@synthesize titleString;
@synthesize numberOfCells;
@synthesize associatedObject;
@synthesize headerView;

@synthesize logicalSize;
@synthesize xLargeCell;

-(CGRect) frameForHeaderView {
    CGRect b = self.bounds;
    b.size.height = grid.rowHeaderHeight;
    b.origin.x = 10;
    b.origin.y = NSMaxY(listView.frame);
    return b;
}

-(CGRect) frameForXLargeCell {
    if (!xLargeCell) return CGRectZero;
    CGRect xlargeCellFrame = self.bounds;
    xlargeCellFrame.origin.y = (listView.frame.size.height + grid.rowHeaderHeight + 15);
    xlargeCellFrame.size.height -= xlargeCellFrame.origin.y;
    return xlargeCellFrame;
} 

-(CGRect) frameForListView {
    CGRect b = self.bounds;
    CGRect listRect = b;
    listRect.size.height -= [self frameForHeaderView].size.height;
    if (self.logicalSize == AHGridLogicalSizeXLarge) {
        listRect.size.height = [grid cellSizeForLogicalSize:AHGridLogicalSizeSmall].height;
    }
    return listRect;
}


- (id)initWithFrame:(CGRect)frame andGrid:(AHGrid*) g
{
	if((self = [super initWithFrame:frame])) {
        grid = g;
        self.backgroundColor = grid.backgroundColor;
        listView = [[TUILayout alloc] initWithFrame:CGRectZero];
        listView.backgroundColor = grid.backgroundColor;
        listView.dataSource = self;
        listView.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
        listView.typeOfLayout = TUILayoutHorizontal;
        listView.horizontalScrolling = YES;
        listView.spaceBetweenViews = 15;
        listView.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
        self.logicalSize = AHGridLogicalSizeMedium;
        [self addSubview:listView];  
    }
    return self;
}

-(void) setHeaderView:(TUIView *)h {
    headerView = h;
    if (!headerView.superview) {
        [self addSubview:headerView];
    }
    headerView.frame = [self frameForHeaderView];
}

-(void) setGrid:(AHGrid *)g {
    grid = g;
}

#pragma mark - Layout

-(void) layoutSubviews {
    if (animating) {
        if(xLargeCell) {
            CGRect r = [self frameForXLargeCell];
            xLargeCell.frame = r;
        }
        listView.frame = [self frameForListView];
        headerView.frame = [self frameForHeaderView];
        return [super layoutSubviews];
    }
    listView.frame = [self frameForListView];
    
    if (xLargeCell) {
        xLargeCell.frame = [self frameForXLargeCell];
        [xLargeCell setNeedsLayout];
    }

    if (headerView) {
        headerView.frame = [self frameForHeaderView];
        [self sendSubviewToBack:headerView];
    }
    
    
    if (!listView.reloadedDate) {
        //In case the the list view hasn't been loaded yet
        [listView reloadData];
    }
    [listView setNeedsLayout];
    [super layoutSubviews];
}

#pragma mark  - TUILayout DataSource Methods

-(TUIView*) layout:(TUILayout *)l viewForObjectAtIndex:(NSInteger)i {
    
    AHGridCell *cell = (AHGridCell*) [listView dequeueReusableView];
	cell.row = self;
    [cell prepareForReuse];
    cell.selected = (index == grid.selectedRowIndex) && (i == grid.selectedCellIndex);
    cell.grid = grid;
    cell.index = i;
    cell.logicalSize = self.logicalSize;
    if (self.logicalSize == AHGridLogicalSizeXLarge) cell.logicalSize = AHGridLogicalSizeSmall;
    
    if (grid.configureCellBlock) {
        grid.configureCellBlock(grid, self, cell, i);
    }
    return cell;
}

- (NSUInteger)numberOfObjectsInLayout:(TUILayout *)l {
    if (grid.numberOfCellsBlock) {
        return grid.numberOfCellsBlock(grid, self);
    };
    return numberOfCells;
}

- (CGSize)sizeOfObjectAtIndex:(NSUInteger)index {
    if (self.logicalSize == AHGridLogicalSizeXLarge) {
        return [grid cellSizeForLogicalSize:AHGridLogicalSizeSmall];
    }
    return [grid cellSizeForLogicalSize:self.logicalSize];
}


#pragma mark - Events

-(NSMenu*) menuForEvent:(NSEvent *)event {
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove",nil) action:@selector(remove:) keyEquivalent:@""];
    item.target =self;
    [menu addItem:item];
    
    NSMenuItem *item1 = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Toggle Expand To Fill",nil) action:@selector(toggleExpanded) keyEquivalent:@""];
    item1.target = self;
    [menu addItem:item1];
    
    
    NSMenuItem *item2 = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Insert Object",nil) action:@selector(insertObject) keyEquivalent:@""];
    item2.target = self;
    [menu addItem:item2];
    return menu;
}



#pragma mark - Key Handling

- (BOOL)performKeyAction:(NSEvent *)event {
   return [grid performKeyAction:event];
}



@end
