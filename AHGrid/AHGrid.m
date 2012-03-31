//
//  AHScreen.m
//  Swift
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import "AHGrid.h"
#import "AHGridRow.h"
#import "AHGridCell.h"

@interface AHGrid()

-(void) selectCellInAdjacentRow:(AHGridRow*) row;

@end

@implementation AHGrid {
    CGRect lastBounds;
    BOOL animating;
    BOOL firstLayout;
    NSUInteger numberOfRows;
    CFAbsoluteTime lastSelectionTime; //used to space out actions on selection
}

@synthesize rowViews;
@synthesize configureRowBlock;
@synthesize reloadedBlock;
@synthesize configureCellBlock;
@synthesize selectedRow;
@synthesize selectedCell;
@synthesize selectedRowIndex;
@synthesize selectedCellIndex;
@synthesize numberOfRowsBlock;
@synthesize numberOfCellsBlock;
@synthesize cellClass;
@synthesize rowHeaderClass;
@synthesize rowHeaderHeight;

@synthesize smallCellSize;
@synthesize mediumCellSize;
@synthesize largeCellSize;
@synthesize xLargeCellSize;

#pragma mark - Init & Layout

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
        self.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0];
        self.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
        self.verticalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleWhenScrolling;
        self.autoresizingMask = TUIViewAutoresizingFlexibleSize;    
        selectedRowIndex = -1;
        selectedCellIndex = -1;
        self.dataSource = self;
        self.spaceBetweenViews = 15;
        self.viewClass = [AHGridRow class];
        lastSelectionTime = CFAbsoluteTimeGetCurrent();
    }
    return self;
}


-(void) reloadData {
    
    self.selectedRow = nil;
    self.selectedCell = nil;
    self.selectedCellIndex = -1;
    self.selectedRowIndex = -1;
    
    
    for (TUIView *row in self.rowViews) {
        [row removeFromSuperview];
    }
    self.rowViews =  nil;
    self.rowViews = [NSMutableArray array];
    numberOfRows = numberOfRowsBlock ? numberOfRowsBlock(self) : 0;
    
    if (numberOfRows > 0) {
        for (int i = 0; i < numberOfRows; i++) {
            Class rowClass = self.viewClass ? self.viewClass : [AHGridRow class];
            AHGridRow *rowView = (AHGridRow*) [[rowClass alloc] initWithFrame:CGRectZero andGrid:self];
            rowView.logicalSize =  AHGridLogicalSizeMedium;
            rowView.index = i;
            if (rowHeaderClass) {
                rowView.headerView = [[rowHeaderClass alloc] initWithFrame:CGRectZero];
            }
            rowView.listView.viewClass = cellClass ? cellClass : [AHGridCell class];
            rowView.grid = self;
            
            if (configureRowBlock) {
                configureRowBlock(self, rowView, i);
            }
            
            [self.rowViews addObject:rowView];
        }
        
        [super reloadData];
        [self scrollToTopAnimated:NO];
    }
    
    if (reloadedBlock) {
        reloadedBlock(self);
    }
}

-(void) layoutSubviews {
    if (!CGSizeEqualToSize(lastBounds.size, self.bounds.size) && firstLayout && 
        !animating) {
        lastBounds = self.bounds;
        //[self reloadData];
    }
    firstLayout = YES;
    
    if (self.selectedRow) [self.selectedRow setNeedsLayout];
    
    lastBounds = self.bounds;
    [super layoutSubviews];
}


#pragma mark - TUILayoutDataSource methods

-(TUIView*) layout:(TUILayout *)l viewForObjectAtIndex:(NSInteger)index {
    if (!rowViews.count) {
        return nil;
    }
    AHGridRow *rowView = [rowViews objectAtIndex:index];
    rowView.index = index;
    rowView.grid = self;
    if (configureRowBlock) {
        configureRowBlock(self, rowView, index);
    }
    
    return rowView;
}


- (NSUInteger)numberOfObjectsInLayout:(TUILayout *)l {
    return numberOfRows;
}

- (CGSize)sizeOfObjectAtIndex:(NSUInteger)index {
    AHGridRow *rowView = [rowViews objectAtIndex:index];
    CGSize size = [self rowSizeForLogicalSize:rowView.logicalSize];
    return size;
}


#pragma mark - Selection

- (BOOL)performKeyAction:(NSEvent *)event
{    
    if (!self.selectedRow || !self.selectedCell || animating) return YES;
    
    NSUInteger oldCellIndex = selectedCellIndex;
    NSUInteger newCellIndex = selectedCellIndex;
    NSUInteger oldRowIndex = selectedRowIndex;
    NSUInteger newRowIndex = selectedRowIndex;
    
    NSUInteger numberOfCellsInSelectedRow = self.selectedRow.listView.numberOfCells;
    
    BOOL shouldResize = self.selectedRow.logicalSize == AHGridLogicalSizeXLarge;
    
    unichar keyChar = [[event charactersIgnoringModifiers] characterAtIndex:0];
    
    switch(keyChar) {
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
            if (shouldResize) {
                [self toggleSelectedCellSize];  
                return YES;   
            }
            newRowIndex += 1;
            if (oldRowIndex != newRowIndex && (newRowIndex < numberOfRows)) {
                [self selectCellInAdjacentRow:(AHGridRow*) [self viewForIndex:newRowIndex]];
            }
            return YES;
        }
        case NSUpArrowFunctionKey: {
            if (shouldResize) {
                [self toggleSelectedCellSize];  
                return YES;   
            }
            newRowIndex -= 1;
            newRowIndex = MAX(newRowIndex, 0);
            if (oldRowIndex != newRowIndex && (newRowIndex < numberOfRows)) {
                [self selectCellInAdjacentRow:(AHGridRow*) [self viewForIndex:newRowIndex]];
            }
            return YES;
        }
        case 27: {
            // escape key
            NSInteger direction = shouldResize ? 1 : -1;
            [self toggleSelectedCellSize:direction];  
            return YES;
            break;
        }
        case 13:
        case 32:{
            // Enter key
            [self toggleSelectedCellSize:1];  
            return YES;
            break;
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
    }
}


- (void) setSelectedCell:(AHGridCell *) cell 
{
    if (cell.index == selectedCellIndex && cell.row.index == selectedRowIndex) return;
    __block AHGridCell *oldSelectedCell = self.selectedCell;
    if (oldSelectedCell) oldSelectedCell.selected = NO;
    
    selectedCellIndex = cell.index;
    self.selectedRow = cell.row;
    selectedCell = cell;
    
    if (self.selectedCell) {
        self.selectedCell.selected = YES;
        
        //        double SELECTION_TIME_INTERVAL = 0.3;
        //        double timeSinceLastSelection = CFAbsoluteTimeGetCurrent() -lastSelectionTime;
        //        
        //        if (timeSinceLastSelection > SELECTION_TIME_INTERVAL && lastSelectedAndExpandedCell  && selectedCell.logicalSize != lastSelectedAndExpandedCell.logicalSize) {
        //            AHGridCellSize targetSize = oldSelectedCell.logicalSize;
        //            [self downsizeCell:lastSelectedAndExpandedCell upsizeCell:selectedCell toSize:targetSize completionBlock:^{
        //                lastSelectedAndExpandedCell = selectedCell;
        //            }];
        //        } 
        //        
        //        if (oldSelectedCell.logicalSize > AHGridCellSizeMedium) {
        //            [self resizeCell:oldSelectedCell toSize:AHGridCellSizeMedium completionBlock:nil];
        //        }
        //Scroll to this object
        [self.selectedRow.listView scrollRectToVisible:self.selectedCell.frame animated:YES];
        
        [self.nsWindow makeFirstResponderIfNotAlreadyInResponderChain:self.selectedCell];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAHGridChangedCellSelection object:nil]];        
    }
    lastSelectionTime = CFAbsoluteTimeGetCurrent();
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


#pragma mark - Resizing


-(CGSize) rowSizeForLogicalSize:(AHGridLogicalSize) logicalSize {
    if (logicalSize != AHGridLogicalSizeXLarge) {
        return CGSizeMake(self.bounds.size.width,[self cellSizeForLogicalSize:logicalSize].height + self.rowHeaderHeight);
    } 
    //xLarge rows take up the whole size of the grid
    return self.visibleRect.size;
}

-(CGSize) cellSizeForLogicalSize:(AHGridLogicalSize) cellSize {
    
    if (CGSizeEqualToSize(CGSizeZero, self.mediumCellSize)) {
        mediumCellSize = CGSizeMake(350, 200);
    }
    if (CGSizeEqualToSize(CGSizeZero, self.smallCellSize)) {
        smallCellSize = CGSizeMake(250, 100);
    }

    switch (cellSize) {
        case AHGridLogicalSizeSmall:
            return self.smallCellSize;
            break;
        case AHGridLogicalSizeMedium:
            return self.mediumCellSize;
            break;
        case AHGridLogicalSizeLarge: //Hard coded for now but plan to  defer to allow calling a supplied block for a dynamic calculation
            return CGSizeMake(roundf(self.mediumCellSize.width * 1.85), self.mediumCellSize.height + 80);
            break;
        case AHGridLogicalSizeXLarge:
            return CGSizeMake(self.bounds.size.width, self.visibleRect.size.height - self.smallCellSize.height - self.rowHeaderHeight);
            break;
        default:
            break;
    }
    return self.mediumCellSize;
}


-(AHGridLogicalSize) nextCellSizeRelativeToSize:(AHGridLogicalSize) cellSize direction:(NSInteger) direction {
    AHGridLogicalSize targetCellSize = (cellSize + direction) % 4;
    targetCellSize = MAX(1, targetCellSize);
    return targetCellSize;
}

-(void) toggleSelectedCellSize:(NSInteger) direction {
    AHGridLogicalSize currentSize = self.selectedRow.xLargeCell ? AHGridLogicalSizeXLarge : self.selectedCell.logicalSize;
    AHGridLogicalSize targetCellSize = [self nextCellSizeRelativeToSize:currentSize direction:direction];
    [self resizeSelectedCellToSize:targetCellSize];
}

-(void) toggleSelectedCellSize {
    [self toggleSelectedCellSize:1];
}

-(void) resizeSelectedCellToSize:(AHGridLogicalSize) targetCellSize {
    // __block AHGridCell *cell = (AHGridCell*) [self.selectedRow.listView viewForIndex:self.selectedCellIndex];
    if (targetCellSize == AHGridLogicalSizeLarge || (targetCellSize == AHGridLogicalSizeMedium && self.selectedRow.logicalSize == AHGridLogicalSizeLarge)) {
        [self resizeRowToLogicalSize:targetCellSize animationBlock:^{
            [self resizeCellsOfRow:self.selectedRow toSize:targetCellSize]; 
        } completionBlock:nil];
        return;
    }
    if (targetCellSize == AHGridLogicalSizeXLarge || self.selectedRow.logicalSize == AHGridLogicalSizeXLarge) {
        [self xLargeResize:targetCellSize];
    }
}

-(void) resizeCell:(AHGridCell*) cell toSize:(AHGridLogicalSize) logicalSize completionBlock:(void (^)())completionBlock  {
    if (animating) return;
    
    // Are you ready for some block action?!!
    
    if (cell && [self xLargeResize:logicalSize]) {
        
        CGSize targetSize = [self cellSizeForLogicalSize:logicalSize];
        // Let the cell know it will be resizing, so that it can setup anything needed for the resize, such as additional subviews
        cell.resizing = YES;
        
        // Let the current runloop finish so that visual changes needed for resizing, e.g. adding a subview,
        //can be applied after the last call.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_current_queue(), ^{
            
            // This block will complete after the cell is done resizing
            void (^myCompletionBlock)() = ^() {
                // The cell is done resizing
                cell.resizing = NO;
                [self.nsWindow makeFirstResponderIfNotAlreadyInResponderChain:cell];
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAHGridDidResizeCell object:[NSNumber numberWithInteger:logicalSize]]];
                if (completionBlock) completionBlock();
            };
            
            // ready to resize
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAHGridWillResizeCell object:[NSNumber numberWithInteger:logicalSize]]];
            
            if (self.selectedRow.logicalSize == logicalSize) {
                // just resize the cell
                [cell.row.listView resizeObjectAtIndex:self.selectedCellIndex toSize:targetSize animationBlock:^{
                    // cells can perform any needed animations in this method
                    cell.logicalSize = logicalSize;
                } completionBlock:myCompletionBlock];
            } // resize the row at the same time
            else [self resizeRowToLogicalSize:logicalSize animationBlock:^{
                [cell.row.listView resizeObjectAtIndex:self.selectedCellIndex toSize:targetSize animationBlock:^{
                    cell.logicalSize = logicalSize;
                } completionBlock:nil];
            } completionBlock:myCompletionBlock];            
        });        
    }
}

// Swap sizes between rows
// The row is not resized;
-(void) downsizeCell:(AHGridCell*) downCell upsizeCell:(AHGridCell*) upCell toSize:(AHGridLogicalSize) logicalSize completionBlock:(void (^)())completionBlock {
    if (!downCell || !upCell) return;
    animating = YES;
    NSString *downIndex = [NSString stringWithFormat:@"%d", downCell.index];
    NSString *upIndex = [NSString stringWithFormat:@"%d", upCell.index];
    NSArray *indexes = [NSArray arrayWithObjects:downIndex, upIndex, nil];
    AHGridLogicalSize downLogicalSize = [self nextCellSizeRelativeToSize:logicalSize direction:-1];
    CGSize downSize = [self cellSizeForLogicalSize:downLogicalSize];
    CGSize upSize = [self cellSizeForLogicalSize:logicalSize];
    NSArray *sizes = [NSArray arrayWithObjects:[NSValue valueWithSize:downSize], [NSValue valueWithSize:upSize], nil];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAHGridWillResizeCell object:[NSNumber numberWithInteger:logicalSize]]];
    
    upCell.resizing = YES;
    downCell.resizing = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_current_queue(), ^{
        [self.selectedRow.listView resizeObjectAtIndexes:indexes sizes:sizes animationBlock:^{
            downCell.logicalSize = downLogicalSize;
            upCell.logicalSize = logicalSize;
        } completion:^{
            animating = NO;
            downCell.resizing = NO;
            upCell.resizing = NO;
            [self.nsWindow makeFirstResponderIfNotAlreadyInResponderChain:upCell];
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAHGridDidResizeCell object:[NSNumber numberWithInteger:logicalSize]]];
            if (completionBlock) completionBlock();
        }];
    });
}


-(void) resizeRowToLogicalSize:(AHGridLogicalSize) logicalSize animationBlock:(void (^)())animationBlock completionBlock:(void (^)())completionBlock {
    
    animating = YES;
    self.selectedRow.animating = YES;
    
    CGFloat height = [self rowSizeForLogicalSize:logicalSize].height;
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAHGridWillResizeRow object:[NSNumber numberWithInteger:logicalSize]]];
    //resize the row to be able to hold the size of the cell
    [self resizeObjectAtIndex:self.selectedRow.index toSize:CGSizeMake(self.bounds.size.width, height) animationBlock:^{
        [self scrollRectToVisible:self.selectedRow.frame animated:YES];
        self.selectedRow.logicalSize = logicalSize;  
        if (animationBlock) animationBlock();
        [self.selectedRow layoutSubviews];
    } completionBlock:^{
        if (self.selectedRow.logicalSize == AHGridLogicalSizeXLarge) {
            self.verticalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
            self.scrollEnabled = NO;
        } else {
            self.verticalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleWhenMouseInside;
            self. scrollEnabled = YES;
        }
        animating = NO;
        self.selectedRow.animating = NO;
        if (completionBlock) completionBlock();
        [self setNeedsLayout];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAHGridDidResizeRow object:[NSNumber numberWithInteger:logicalSize]]];
        
    }];    
}

-(void) resizeCellsOfRow:(AHGridRow*) row toSize:(AHGridLogicalSize) logicalSize {
    CGSize size = [self cellSizeForLogicalSize:logicalSize];
    [row.listView.visibleViews enumerateObjectsUsingBlock:^(AHGridCell *cell, NSUInteger idx, BOOL *stop) {
        cell.resizing = YES;
    }];
    
    // Tell all visible views they are going to be resized
    [row.listView resizeObjectsToSize:size animationBlock:^{
        [row.listView.visibleViews enumerateObjectsUsingBlock:^(AHGridCell *cell, NSUInteger idx, BOOL *stop) {
            cell.logicalSize = logicalSize;
        }];
    } completionBlock:^{
        // Tell all visible views they done being resized
        [row.listView.visibleViews enumerateObjectsUsingBlock:^(AHGridCell *cell, NSUInteger idx, BOOL *stop) {
            cell.resizing = NO;
        }];
        
    }];
}

// When moving to the xlarge state
-(BOOL) xLargeResize:(AHGridLogicalSize) targetLogicalSize {
    __block AHGridCell *cell = (AHGridCell*) [self.selectedRow.listView viewForIndex:self.selectedCellIndex];
    
    if (targetLogicalSize == AHGridLogicalSizeXLarge) {
        
        // This change ownerships of the cell being resized to fill the whole window to the row
        // so that the animation of the cell growing above the scrolling list looks ok
        AHGridCell *newCell = (AHGridCell*) [self.selectedRow.listView replaceViewForObjectAtIndex:cell.index withSize:[self cellSizeForLogicalSize:AHGridLogicalSizeLarge]];
        newCell.logicalSize = AHGridLogicalSizeLarge;
        self.selectedCell = newCell;
        
        // Adjust the cell that will be animated position relatively for scroll position
        CGRect f = cell.frame;
        f.origin.x +=  -NSMinX(self.selectedRow.listView.visibleRect);
        cell.frame = f;
        
        // Let the current runloop finish so that visual changes needed for resizing, e.g. adding a subview,
        animating = YES;
        //can be applied after the last call.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_current_queue(), ^{
            [self resizeRowToLogicalSize:AHGridLogicalSizeXLarge animationBlock:^{
                [self resizeCellsOfRow:self.selectedRow toSize:AHGridLogicalSizeSmall];
                self.selectedRow.xLargeCell = cell;
                [self.selectedRow addSubview:self.selectedRow.xLargeCell];
                self.selectedRow.xLargeCell.logicalSize = AHGridLogicalSizeXLarge;
                [self.selectedRow.xLargeCell layoutSubviews];
                [self.selectedRow layoutSubviews];
            } completionBlock:^{
                animating = NO;
            }];
        });
        return NO;
    } else if (self.selectedRow.logicalSize == AHGridLogicalSizeXLarge && self.selectedRow.xLargeCell && self.selectedRow.xLargeCell.superview) {
        animating = YES;
        // remove the xlarge cell and resize the row
        [self resizeRowToLogicalSize:AHGridLogicalSizeMedium animationBlock:^{
            [self resizeCellsOfRow:self.selectedRow toSize:AHGridLogicalSizeMedium];
            //fade out the xlarge cell
            self.selectedRow.xLargeCell.alpha = 0;
        } completionBlock:^{
            animating = NO;
            [self.selectedRow.xLargeCell removeFromSuperview];
            self.selectedRow.xLargeCell = nil;
        }];
        return NO;
    }
    
    return YES;
}


#pragma mark - Scrolling

- (TUIScrollView*)delegateScrollViewForEvent:(NSEvent *)event {
    // If gesture events are sent to both horizontal and vertical scrollviews it's doesn't hurt anything
    // but they are necessary.
    if (self.selectedRow && self.selectedRow.xLargeCell) {
        return nil;
    }
    if (event.type == NSEventTypeBeginGesture || event.type == NSEventTypeEndGesture) {
        return self;
    }
    if (fabs([event deltaX]) < fabs([event deltaY])) { // Vertical
        return self;
    }
    return nil;
}


@end
