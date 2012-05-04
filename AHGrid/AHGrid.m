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


@end

@implementation AHGrid {
    CGRect lastBounds;
    BOOL animating;
    BOOL firstLayout;
    NSUInteger numberOfRows;
    CFAbsoluteTime lastSelectionTime; //used to space out actions on selection
}

@synthesize configureRowBlock;
@synthesize configureCellBlock;
@synthesize numberOfCellsBlock;
@synthesize loadAllHandler, loadNewHandler, loadOldHandler;

@synthesize selectedRow;
@synthesize selectedCell;
@synthesize selectedRowIndex;
@synthesize selectedCellIndex;
@synthesize numberOfRowsBlock;
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
        self.cellClass = [AHGridCell class];
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

    numberOfRows = numberOfRowsBlock ? numberOfRowsBlock(self) : 0;
    
    [super reloadData];
    [self scrollToTopAnimated:NO];
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
    AHGridRow *rowView = (AHGridRow*)[self dequeueReusableView];
    rowView.logicalSize =  AHGridLogicalSizeMedium;
    if (rowHeaderClass && !rowView.headerView) {
        rowView.headerView = [[rowHeaderClass alloc] initWithFrame:CGRectZero];
    }         
    rowView.index = index;
    rowView.grid = self;
    if (configureRowBlock) {
        configureRowBlock(self, rowView);
    }
    
    return rowView;
}


- (NSUInteger)numberOfObjectsInLayout:(TUILayout *)l {
    return numberOfRows;
}

- (CGSize)sizeOfObjectAtIndex:(NSUInteger)index {
    CGSize size = [self rowSizeForLogicalSize:AHGridLogicalSizeMedium];
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
                [self selectAndScrollToCellWithIndex:newCellIndex];
            }
            return YES;;
        }
        case NSRightArrowFunctionKey:  {
            newCellIndex +=1;
            if (oldCellIndex != newCellIndex && (newCellIndex < numberOfCellsInSelectedRow)) {
                [self selectAndScrollToCellWithIndex:newCellIndex];
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
                [self selectCellInAdjacentRow:(AHGridRow*) [self viewForIndex:newRowIndex] scrollTo:YES];
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
                [self selectCellInAdjacentRow:(AHGridRow*) [self viewForIndex:newRowIndex] scrollTo:YES];
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

-(void) selectAndScrollToCellWithIndex:(NSUInteger) cellIndex {
    self.selectedCell = (AHGridCell*) [self.selectedRow.listView viewForIndex:cellIndex];
    [self scrollRectToVisible:self.selectedRow.frame animated:YES];
    [self.selectedRow.listView scrollRectToVisible:self.selectedCell.frame animated:YES];
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
        //Scroll to this object
        //[self.selectedRow.listView scrollRectToVisible:self.selectedCell.frame animated:YES];
        
        [self.nsWindow makeFirstResponderIfNotAlreadyInResponderChain:self.selectedCell];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAHGridChangedCellSelection object:nil]];        
    }
    lastSelectionTime = CFAbsoluteTimeGetCurrent();
}


-(void) selectCellInAdjacentRow:(AHGridRow*) row scrollTo:(BOOL) scrollTo {
    CGRect v = self.selectedRow.listView.visibleRect;
    CGRect r = self.selectedCell.frame;
    // Adjust the point for the scroll position
    CGFloat relativeOffset = r.origin.x - (v.origin.x - roundf(self.selectedCell.bounds.size.width/2));
    CGRect rowVisible = row.listView.visibleRect;
    CGPoint point = CGPointMake(NSMinX(rowVisible) + relativeOffset, 0);
    self.selectedCell = (AHGridCell*) [row.listView viewAtPoint:point];
    if (scrollTo) {
        [self scrollRectToVisible:self.selectedRow.frame animated:YES];
        [self.selectedRow.listView scrollRectToVisible:self.selectedCell.frame animated:YES];
    }
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
    //Skip large for now
    if (targetCellSize == AHGridLogicalSizeLarge) {
        targetCellSize = AHGridLogicalSizeXLarge;
    }
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
        [self resizeRowAtIndex:self.selectedRowIndex toLogicalSize:targetCellSize animationBlock:^{
            [self resizeCellsOfRow:self.selectedRow toSize:targetCellSize]; 
        } completionBlock:nil];
        return;
    }
    if (targetCellSize == AHGridLogicalSizeXLarge || self.selectedRow.logicalSize == AHGridLogicalSizeXLarge) {
        [self resizeFadeInOutXLarge:targetCellSize];            
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
            else [self resizeRowAtIndex:self.selectedRowIndex toLogicalSize:logicalSize animationBlock:^{
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
    NSString *downIndex = [NSString stringWithFormat:@"%ld", downCell.index];
    NSString *upIndex = [NSString stringWithFormat:@"%ld", upCell.index];
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


-(void) resizeRowAtIndex:(NSInteger) index toLogicalSize:(AHGridLogicalSize) logicalSize animationBlock:(void (^)())animationBlock completionBlock:(void (^)())completionBlock {
    
    AHGridRow *row = (AHGridRow*)[self viewForIndex:index];
    
    animating = YES;
    row.animating = YES;
    
    CGFloat height = [self rowSizeForLogicalSize:logicalSize].height;
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAHGridWillResizeRow object:[NSNumber numberWithInteger:logicalSize]]];
    [self beginUpdates];
    self.scrollToObjectIndex = self.selectedRowIndex;
    //resize the row to be able to hold the size of the cell
    [self resizeObjectAtIndex:self.selectedRow.index toSize:CGSizeMake(self.bounds.size.width, height) animationBlock:^{
        row.logicalSize = logicalSize;  
        [row layoutSubviews];
        if (animationBlock) animationBlock();
    } completionBlock:^{
        if (self.selectedRow.logicalSize == AHGridLogicalSizeXLarge) {
            self.verticalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
            self.scrollEnabled = NO;
        } else {
            self.verticalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleWhenMouseInside;
            self. scrollEnabled = YES;
        }
        animating = NO;
        row.animating = NO;
        if (completionBlock) completionBlock();
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAHGridDidResizeRow object:[NSNumber numberWithInteger:logicalSize]]];
        
    }];
    [self endUpdates];
}

-(void) resizeCellsOfRow:(AHGridRow*) row toSize:(AHGridLogicalSize) logicalSize {
    CGSize size = [self cellSizeForLogicalSize:logicalSize];
    [row.listView beginUpdates];
    row.listView.scrollToObjectIndex = self.selectedCellIndex;
    [row.listView.visibleViews enumerateObjectsUsingBlock:^(AHGridCell *cell, NSUInteger idx, BOOL *stop) {
        cell.resizing = YES;
    }];
    
    // Tell all visible views they are going to be resized
    [row.listView resizeObjectsToSize:size animationBlock:^{
        [row.listView.visibleViews enumerateObjectsUsingBlock:^(AHGridCell *cell, NSUInteger idx, BOOL *stop) {
            cell.logicalSize = logicalSize;
        }];        
    } completionBlock:^{
        [row.listView.visibleViews enumerateObjectsUsingBlock:^(AHGridCell *cell, NSUInteger idx, BOOL *stop) {
            cell.resizing = NO;
        }];        
    }];
    [row.listView endUpdates];
}

// When moving to the xlarge state
-(BOOL) xLargeResize:(AHGridLogicalSize) targetLogicalSize {
    __block AHGridCell *cell = (AHGridCell*) [self.selectedRow.listView viewForIndex:self.selectedCellIndex];
    
    if (targetLogicalSize == AHGridLogicalSizeXLarge) {
        
        // This change ownerships of the cell being resized to fill the whole window to the row
        // so that the animation of the cell growing above the scrolling list looks ok
        AHGridCell *newCell = (AHGridCell*) [self.selectedRow.listView replaceViewForObjectAtIndex:cell.index withSize:[self cellSizeForLogicalSize:AHGridLogicalSizeLarge]];
        NSAssert(newCell, @"Didnt get a replacment cell in xlarge resize");
        NSAssert(CGRectContainsRect(self.selectedRow.listView.visibleRect, newCell.frame), @"The selected cell needs to be visible for this animation.  Trigger this animation from a mouse click on the selected cell.");
        
        newCell.logicalSize = AHGridLogicalSizeLarge;
        self.selectedCell = newCell;
        cell.selected = NO;
        
        // Adjust the cell so that it will be animated position relatively for scroll position
        CGRect f = cell.frame;
        f.origin.x +=  -NSMinX(self.selectedRow.listView.visibleRect);
        cell.frame = f;
        
        animating = YES;
        
        // Let the current runloop finish so that visual changes needed for resizing, e.g. adding a subview,
        //can be applied after the last call.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0), dispatch_get_current_queue(), ^{
            [self resizeRowAtIndex:self.selectedRowIndex toLogicalSize:AHGridLogicalSizeXLarge animationBlock:^{
                [self resizeCellsOfRow:self.selectedRow toSize:AHGridLogicalSizeSmall];
                self.selectedRow.xLargeCell = cell;
                self.selectedRow.logicalSize = AHGridLogicalSizeXLarge;
                [self.selectedRow addSubview:self.selectedRow.xLargeCell];
                self.selectedRow.xLargeCell.logicalSize = AHGridLogicalSizeXLarge;
                [self.selectedRow layoutSubviews];
            } completionBlock:^{
                animating = NO;
            }];
        });
        return NO;
    } else if (self.selectedRow.logicalSize == AHGridLogicalSizeXLarge && self.selectedRow.xLargeCell && self.selectedRow.xLargeCell.superview) {
        animating = YES;
        self.selectedRow.animating = YES;
        // remove the xlarge cell and resize the row
        [self resizeRowAtIndex:self.selectedRowIndex toLogicalSize:AHGridLogicalSizeMedium animationBlock:^{
            [self resizeCellsOfRow:self.selectedRow toSize:AHGridLogicalSizeMedium];
            //fade out the xlarge cell
            [self.selectedRow layoutSubviews];
            self.selectedRow.xLargeCell.alpha = 0;
        } completionBlock:^{
            animating = NO;
            self.selectedRow.animating = YES;
            [self.selectedRow.xLargeCell removeFromSuperview];
            self.selectedRow.xLargeCell = nil;
        }];
        return NO;
    }
    
    return YES;
}

// When moving to the xlarge state
-(void) resizeFadeInOutXLarge:(AHGridLogicalSize) targetLogicalSize {
    
    if (targetLogicalSize == AHGridLogicalSizeXLarge) {
        
        animating = YES;
        
        // Create an xlarge cell for the row
        CGRect f = CGRectZero;
        f.origin.y = [self cellSizeForLogicalSize:AHGridLogicalSizeSmall].height + 100;
        f.size.height = self.bounds.size.height - f.origin.y -100;
        Class cellClassToUse = self.cellClass ? self.cellClass : [AHGridCell class];
        AHGridCell *xlargeCell = [[cellClassToUse alloc] initWithFrame:f];
        xlargeCell.alpha = 0;
        [self.selectedRow addSubview:xlargeCell];
        self.selectedRow.xLargeCell = xlargeCell;
        
        self.selectedRow.animating = YES;
        animating = YES;
        [self resizeRowAtIndex:self.selectedRowIndex toLogicalSize:AHGridLogicalSizeXLarge animationBlock:^{
            [self resizeCellsOfRow:self.selectedRow toSize:AHGridLogicalSizeSmall];
            xlargeCell.alpha = 1;
            self.selectedRow.xLargeCell.logicalSize = AHGridLogicalSizeXLarge;
        } completionBlock:^{
            self.selectedRow.animating = NO;
            [self.selectedRow layoutSubviews];
            animating = NO;
        }];
    } else if (self.selectedRow.logicalSize == AHGridLogicalSizeXLarge && self.selectedRow.xLargeCell && self.selectedRow.xLargeCell.superview) {
        // remove the xlarge cell and resize the row
        [self resizeRowAtIndex:self.selectedRowIndex toLogicalSize:AHGridLogicalSizeMedium animationBlock:^{
            [self resizeCellsOfRow:self.selectedRow toSize:AHGridLogicalSizeMedium];
            //fade out the xlarge cell
            self.selectedRow.xLargeCell.alpha = 0;
        } completionBlock:^{
            [self.selectedRow.xLargeCell removeFromSuperview];
            self.selectedRow.animating = NO;
            [self.selectedRow layoutSubviews];
            animating = NO;
            [self.selectedRow.xLargeCell removeFromSuperview];
            self.selectedRow.xLargeCell = nil;
        }];
    }
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
