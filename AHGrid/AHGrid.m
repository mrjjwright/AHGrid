//
//  AHScreen.m
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import "AHGrid.h"
#import "AHGridRow.h"


@interface AHGrid()

-(void) selectCellInAdjacentRow:(AHGridRow*) row;

@end

@implementation AHGrid {
    NSMutableArray *rows;
    CGFloat configurationModeRowHeight;
    NSMutableArray *rowViews;
    CGRect lastBounds;
    BOOL animating;
    BOOL firstLayout;
}

@synthesize expandedRowIndex;
@synthesize inConfigurationMode;
@synthesize configureRowBlock;
@synthesize configureCellBlock;
@synthesize configureExpandedCellBlock;
@synthesize selectedRow;
@synthesize selectedCell;
@synthesize selectedRowIndex;
@synthesize selectedCellIndex;
@synthesize initDelegate;
@synthesize numberOfRows;
@synthesize numberOfCellsBlock;
@synthesize cellClass;

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
        self.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0];
        self.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
        self.verticalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleWhenScrolling;
        self.autoresizingMask = TUIViewAutoresizingFlexibleSize;    
        configurationModeRowHeight = 100;
        selectedRowIndex = -1;
        selectedCellIndex = -1;
        rows = [NSMutableArray array];
        expandedRowIndex = -1;
        self.dataSource = self;
        self.spaceBetweenViews = 15;
        self.viewClass = [AHGridRow class];
    }
    return self;
}

-(void) reloadData {
    if (initDelegate) {
        [initDelegate initGrid:self];
    }
    rowViews = nil;
    rowViews = [NSMutableArray array];
    numberOfRows = numberOfRows >= 0 ? numberOfRows : 10;
    for (int i = 0; i < numberOfRows; i++) {
        NSDictionary *rowInfo = [NSDictionary dictionary];
        [rows addObject:rowInfo];
        AHGridRow *rowView = (AHGridRow*) [[AHGridRow alloc] initWithFrame:CGRectZero];
        rowView.index = i;
        rowView.cellClass = cellClass;
        if (numberOfCellsBlock) {
            rowView.numberOfCells = numberOfCellsBlock(self, rowView);
        } else {
            rowView.numberOfCells = 10;
        }
        rowView.grid = self;
        [rowViews addObject:rowView];
    }
    [super reloadData];
}

-(void) layoutSubviews {
    
    if (!CGSizeEqualToSize(lastBounds.size, self.bounds.size) && firstLayout) {
        lastBounds = self.bounds;
        [self reloadData];
    }
    firstLayout = YES;
    
    lastBounds = self.bounds;
    [super layoutSubviews];
}


#pragma mark - TUILayoutDataSource methods

-(TUIView*) layout:(TUILayout *)l viewForObjectAtIndex:(NSInteger)index {
    AHGridRow *rowView = [rowViews objectAtIndex:index];
    rowView.index = index;
    rowView.grid = self;
    
    rowView.expanded = NO;
    if (expandedRowIndex >=0 && index == expandedRowIndex) {
        rowView.expanded = YES;
    } else {
        rowView.expanded = NO;
    }
    if (configureRowBlock) {
        configureRowBlock(self, rowView, index);
    }
    if (!rowView.titleString) {
        rowView.titleString = [NSString stringWithFormat:@"Example Row %d", index];
    }
    return rowView;
}


- (NSUInteger)numberOfObjectsInLayout:(TUILayout *)l {
    return numberOfRows;
}

- (CGSize)sizeOfObjectAtIndex:(NSUInteger)index {
    CGSize size = self.bounds.size;
    if (inConfigurationMode) {
        size.height = configurationModeRowHeight;
    }
    
    if (index == expandedRowIndex) {
        size.height = self.visibleRect.size.height;
    } else {
        size.height = 200;        
    }
    return size;
}


#pragma mark - Key Navigation

- (BOOL)performKeyAction:(NSEvent *)event
{    
    if (!self.selectedRow || !self.selectedCell) return YES;
    
    NSUInteger oldCellIndex = selectedCellIndex;
    NSUInteger newCellIndex = selectedCellIndex;
    NSUInteger oldRowIndex = selectedRowIndex;
    NSUInteger newRowIndex = selectedRowIndex;
    
    NSUInteger numberOfCellsInSelectedRow = self.selectedRow.numberOfCells;
    
    switch([[event charactersIgnoringModifiers] characterAtIndex:0]) {
        case NSLeftArrowFunctionKey: {
            newCellIndex -= 1;
            newCellIndex = MAX(newCellIndex, 0);
            if (oldCellIndex != newCellIndex && newCellIndex < numberOfCellsInSelectedRow) {
                self.selectedCell = (AHGridCell*) [self.selectedRow.listView viewForIndex:newCellIndex];
            }
            return YES;;
        }
        case NSRightArrowFunctionKey:  {
            newCellIndex +=1;
            if (oldCellIndex != newCellIndex && (newCellIndex < numberOfCellsInSelectedRow)) {
                self.selectedCell = (AHGridCell*) [self.selectedRow.listView viewForIndex:newCellIndex];
            }
            return YES;
        }
        case NSDownArrowFunctionKey: {
            if (self.selectedRow.expanded == YES) return YES;
            newRowIndex += 1;
            if (oldRowIndex != newRowIndex && (newRowIndex < numberOfRows)) {
                [self selectCellInAdjacentRow:(AHGridRow*) [self viewForIndex:newRowIndex]];
            }
            return YES;
        }
        case NSUpArrowFunctionKey: {
            if (self.selectedRow.expanded == YES) return YES;
            newRowIndex -= 1;
            newRowIndex = MAX(newRowIndex, 0);
            if (oldRowIndex != newRowIndex && (newRowIndex < numberOfRows)) {
                [self selectCellInAdjacentRow:(AHGridRow*) [self viewForIndex:newRowIndex]];
            }
            return YES;
        }
        case 27: {
            // Escape key
            if (self.selectedRow.expanded) {
                [self toggleSelectedRowExpanded];
                return YES;
            }
        }
        case 13:
        case 32:{
            // Escape key
            [self toggleSelectedRowExpanded];
            return YES;
        }
    }    
    return [super performKeyAction:event];
}


-(AHGridRow*) selectedRow {
    if (selectedRowIndex >=0) {
        return (AHGridRow*) [self viewForIndex:selectedRowIndex];        
    }
    return  nil;
}

-(AHGridCell*) selectedCell {
    if (selectedCellIndex >= 0) {
        return (AHGridCell*) [self.selectedRow.listView viewForIndex:selectedCellIndex];
    }
    return nil;
}

- (void) setSelectedRow:(AHGridRow *) row 
{
    if (row.index == selectedRowIndex) return;
    if (self.selectedRow) {
        self.selectedRow.selected = NO;
        [self.selectedRow setNeedsDisplay];
    }
    
    selectedRowIndex = row.index;
    
    if (self.selectedRow) {
        selectedRow.selected = YES;
        [self.selectedRow  setNeedsDisplay];
        
        //Scroll to this object
        [self scrollRectToVisible:self.selectedRow.frame animated:YES];
        [self.nsWindow makeFirstResponderIfNotAlreadyInResponderChain:self.selectedRow];
    }
}

-(void) setExpandedCell:(AHGridCell*) cell {
    if (configureExpandedCellBlock) configureExpandedCellBlock(self, self.selectedRow, self.selectedCell, self.selectedRow.expandedCell, self.selectedRowIndex);
    else
        [self.selectedRow.expandedCell setCellToExpand:self.selectedCell ];
}

- (void) setSelectedCell:(AHGridCell *) cell 
{
    if (cell.index == selectedCellIndex && cell.row.index == selectedRowIndex) return;
    if (self.selectedCell) {
        self.selectedCell.selected = NO;
        [self.selectedCell setNeedsLayout]; 
    } 
    
    selectedCellIndex = cell.index;
    self.selectedRow = cell.row;
    
    if (self.selectedCell) {
        self.selectedCell.selected = YES;
        [self.selectedCell setNeedsLayout];
        //Scroll to this object
        [self.selectedRow.listView scrollRectToVisible:self.selectedCell.frame animated:YES];
        [self.nsWindow makeFirstResponderIfNotAlreadyInResponderChain:self.selectedCell];
        
        if (expandedRowIndex >= 0) {
            [self setExpandedCell:self.selectedCell];    
            self.selectedCell.expanded = YES;
            [self.selectedRow.expandedCell layoutSubviews];
            [ self.selectedRow.expandedCell scrollToTopAnimated:NO];
        }
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAHGridChangedCellSelection object:[NSNumber numberWithInteger:self.selectedCellIndex]]];

    }
}

-(void) selectCellInAdjacentRow:(AHGridRow*) row {
    CGRect v = self.selectedRow.listView.visibleRect;
    CGRect r = self.selectedCell.frame;
    // Adjust the point for the scroll position
    CGFloat relativeOffset = r.origin.x - (v.origin.x - roundf(self.selectedCell.bounds.size.width/2));
    CGRect rowVisible = row.listView.visibleRect;
    CGPoint point = CGPointMake(NSMinX(rowVisible) + relativeOffset, 0);
    self.selectedCell = (AHGridCell*) [row.listView viewAtPoint:point];
}

# pragma mark - Configuration

#pragma mark - Expansion

-(void) toggleSelectedRowExpanded {
    CGFloat height = expandedRowIndex >=0  ? 200 : self.visibleRect.size.height;
    animating = YES;
    self.selectedRow.animating = YES;
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAHGridWillToggleExpansionOfRow object:self]];
    [self resizeObjectAtIndex:self.selectedRow.index toSize:CGSizeMake(self.bounds.size.width, height) animationBlock:^{
        
        [self setExpandedCell:self.selectedCell];
        
        // Fade in the expanded Cell view
        CGFloat alpha = expandedRowIndex >=0 ? 0.0 : 1.0;
        self.selectedRow.expandedCell.alpha = alpha;

        [self.selectedRow layoutSubviews];        
        [self scrollRectToVisible:self.selectedRow.frame animated:YES];
        [ self.selectedRow.expandedCell scrollToTopAnimated:NO];
    }  completionBlock:^{
        self.selectedRow.expanded = !self.selectedRow.expanded;
        self.selectedCell.expanded = !self.selectedCell.expanded;
        if (self.selectedRow.expanded) {
            expandedRowIndex = self.selectedRow.index;
        } else {
            expandedRowIndex = -1;
        }
        self.scrollEnabled = !self.selectedRow.expanded;
        if (expandedRowIndex >= 0) {
            [self.nsWindow setTitle:self.selectedRow.titleString];
            self.verticalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
            
        } else {
            [self.nsWindow setTitle:@"AHGrid"];
            self.verticalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleWhenMouseInside;
        }
        animating = NO;
        self.selectedRow.animating = NO;
        [self setNeedsLayout];
        [self.selectedRow.expandedCell scrollToTopAnimated:YES];
    }];
}

//- (void) saveConfiguration {
//    NSMutableArray *currentRows = [NSMutableArray array];
//    for (TUILayoutObject *object in self.objects) {
//        [currentRows addObject:object.dictionary];
//    }
//    [[NSUserDefaults standardUserDefaults] setValue:currentRows forKey:CrewScreenSave]; 
//}

//-(void) toggleConfigurationMode {
//    inConfigurationMode = !inConfigurationMode;
//    [NSAnimationContext beginGrouping];
//    [[NSAnimationContext currentContext] setDuration:0.3];
//    [self beginUpdates];
//    [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [rows count])] ];
//    [self endUpdates];
//    [NSAnimationContext endGrouping];
//}



#pragma mark - Scrolling

- (BOOL)shouldScrollWheel:(NSEvent *)event {
    
    if ([event phase] == NSEventPhaseBegan) {
        return YES;
    } else if ([event phase] == NSEventPhaseChanged){
        // Horizontal
        if (fabs([event scrollingDeltaX]) > fabs([event scrollingDeltaY])) {
            return YES;
            
        } else if (fabs([event scrollingDeltaX]) < fabs([event scrollingDeltaY])) { // Vertical
            if (self.selectedCell && (self.selectedRowIndex != -1) && self.selectedRow.expanded && self.selectedRow.expandedCell) {
                [self.selectedRow.expandedCell scrollWheel:event];
            } else {
                [self scrollWheel:event];
            }
            return NO;
            
        }
    }
    [self scrollWheel:event];
    return NO;
}


@end
