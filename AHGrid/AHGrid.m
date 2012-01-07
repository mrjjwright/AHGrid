//
//  AHScreen.m
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import "AHGrid.h"
#import "AHRow.h"


@interface AHGrid()

@property (nonatomic) NSInteger expandedRowIndex;

@end

@implementation AHGrid {
    NSMutableArray *rows;
    CGFloat configurationModeRowHeight;
}

@synthesize expandedRowIndex;
@synthesize inConfigurationMode;

@synthesize selectedRow;
@synthesize selectedCell;

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
        configurationModeRowHeight = 100;
        
        self.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
        self.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin | NSViewWidthSizable | NSViewHeightSizable;    
        // Initialization code here.
        rows = [NSMutableArray array];
        for (int i = 0; i < 10; i++) {
            NSDictionary *rowInfo = [NSDictionary dictionary];
            [rows addObject:rowInfo];
        }
        expandedRowIndex = -1;
        self.dataSource = self;
        self.viewClass = [AHRow class];
    }
    return self;
}


# pragma mark NSTableViewDelegate methods


#pragma mark - TUILayoutDataSource methods

-(TUIView*) layout:(TUILayout *)l viewForObjectAtIndex:(NSInteger)index {
    
    AHRow *rowView = (AHRow*) [self dequeueReusableView];
    rowView.index = index;
    rowView.grid = self;
    if (expandedRowIndex >=0 && index == expandedRowIndex) {
        rowView.expanded = YES;
    } else {
        rowView.expanded = NO;
    }
    
    return rowView;
}

- (NSUInteger)numberOfObjectsInLayout:(TUILayout *)l {
    return [rows count];
}

- (CGSize)sizeOfObjectAtIndex:(NSUInteger)index {
    CGSize size = self.bounds.size;
    if (inConfigurationMode) {
        size.height = configurationModeRowHeight;
    }
    
    if (index == expandedRowIndex) {
        size.height = self.visibleRect.size.height;
    } else {
        size.height = 250;        
    }
    return size;
}


#pragma mark - Key Navigation

- (BOOL)performKeyAction:(NSEvent *)event
{    
    if (!selectedRow || !selectedCell) return YES;

    
    NSUInteger oldCellIndex = selectedCell.index;
    NSUInteger newCellIndex = selectedCell.index;
    
    NSUInteger numberOfCellsInSelectedRow = [self.selectedRow.cells count];
    
    switch([[event charactersIgnoringModifiers] characterAtIndex:0]) {
        case NSLeftArrowFunctionKey: {
            newCellIndex -= 1;
            newCellIndex = MAX(newCellIndex, 0);
            if (oldCellIndex != newCellIndex && newCellIndex < numberOfCellsInSelectedRow) {
                self.selectedCell = (AHCell*) [selectedRow.listView viewForIndex:newCellIndex];
                return YES;
            }
            break;
        }
        case NSRightArrowFunctionKey:  {
            newCellIndex +=1;
            if (oldCellIndex != newCellIndex && (newCellIndex < numberOfCellsInSelectedRow)) {
                self.selectedCell = (AHCell*) [selectedRow.listView viewForIndex:newCellIndex];
                return YES;
            }
            break;
        }
            //        case NSDownArrowFunctionKey: {
            //            AHRow *nextRow = [self rowViewAtRow:newIndex + 1 makeIfNecessary:NO];
            //            if (self.selectedRow != nil) {
            //                NSInteger rowIndex = [self.objects indexOfObject:self.selectedRow];
            //                if (rowIndex + 2 >= [self.objects count]) return YES;
            //                nextRow = [self.objects objectAtIndex:rowIndex + 2];
            //            }
            //            [self selectCellInAdjacentRow:nextRow];
            //            return YES;
            //        }
            //        case NSUpArrowFunctionKey: {
            //            Row *nextRow = [self.objects objectAtIndex:1];
            //            if (self.selectedRow != nil) {
            //                NSInteger rowIndex = [self.objects indexOfObject:self.selectedRow];
            //                if ((rowIndex - 2) < 0) return YES;
            //                nextRow = [self.objects objectAtIndex:rowIndex - 2];
            //            } 
            //            [self selectCellInAdjacentRow:nextRow];
            //            return YES;
            //        }
    }    
    
    return [super performKeyAction:event];
}


- (void) setSelectedRow:(AHRow *) row 
{
    if (row == selectedRow) return;
    if (selectedRow) {
        selectedRow.selected = NO;
        [selectedRow setNeedsDisplay];
    }
    selectedRow = row;
    if (selectedRow) {
        selectedRow.selected = YES;
        [selectedRow  setNeedsDisplay];
        
        //Scroll to this object
        [self scrollRectToVisible:selectedRow.frame animated:YES];
        [self.nsWindow makeFirstResponderIfNotAlreadyInResponderChain:self.selectedRow];
    }
}

- (void) setSelectedCell:(AHCell *) cell 
{
    if (cell == selectedCell) return;
    if (selectedCell) {
        selectedCell.selected = NO;
       [selectedCell setNeedsDisplay]; 
    }
    selectedCell = cell;
    if (selectedCell) {
        selectedCell.selected = YES;
        [selectedCell  setNeedsDisplay];
        
        //Scroll to this object
        [selectedRow.listView scrollRectToVisible:selectedCell.frame animated:YES];
        [self.nsWindow makeFirstResponderIfNotAlreadyInResponderChain:self.selectedCell];
    }
}


//-(void) selectCellInAdjacentRow:(AHRow*) row {
//    if (row != nil) {
//        CGPoint point = CGPointMake(0, 0);
//        if (self.selectedRow && self.selectedCell) {
//            CGRect v = self.selectedAHRow.listView.visibleRect;
//            CGRect r = self.selectedAHCell.frame;
//            // Adjust the point for the scroll position
//            CGFloat relativeOffset = r.origin.x - (v.origin.x - roundf(self.selectedAHCell.bounds.size.width/2));
//            CGRect rowVisible = row.listView.visibleRect;
//            point = CGPointMake(NSMinX(rowVisible) + relativeOffset, 0);
//        }
//        
//        // TODO
//        AHCell *cellToSelect; //(AHCell*) [self.selectedRow.listView viewAtPoint:point];
//    }
//}

# pragma mark - Configuration

//-(void) toggleConfigurationMode {
//    inConfigurationMode = !inConfigurationMode;
//    [NSAnimationContext beginGrouping];
//    [[NSAnimationContext currentContext] setDuration:0.3];
//    [self beginUpdates];
//    [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [rows count])] ];
//    [self endUpdates];
//    [NSAnimationContext endGrouping];
//}


@end
