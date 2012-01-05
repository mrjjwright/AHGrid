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

- (void) awakeFromNib
{
    configurationModeRowHeight = 100;
    
    // Initialization code here.
    rows = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        NSDictionary *rowInfo = [NSDictionary dictionary];
        [rows addObject:rowInfo];
    }
    expandedRowIndex = -1;
    self.dataSource = self;
    self.delegate = self;
}


# pragma mark NSTableViewDelegate methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [rows count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    AHRow *rowView = [tableView makeViewWithIdentifier:@"AHRow" owner:self];
    rowView.index = row;
    rowView.grid = self;
    if (expandedRowIndex >=0 && row == expandedRowIndex) {
        rowView.expanded = YES;
    } else {
        rowView.expanded = NO;
    }
    
    return rowView;
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    if (inConfigurationMode) {
        return configurationModeRowHeight;
    }
    
    if (row == expandedRowIndex) {
        return self.visibleRect.size.height;
    } else {
        return 250;        
    }
}

-(void) selectFirstRowIfNeeded {
    if (self.selectedRow == -1) {
        [[self rowViewAtRow:0 makeIfNecessary:NO] viewAtColumn:0];
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
}

-(void) togglExpansionForRow:(NSInteger) rowIndex {
    
    expandedRowIndex = expandedRowIndex < 0 ? rowIndex : -1;
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.5];
    self.selectedAHRow.animating = YES;
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        self.selectedAHRow.animating = NO;
        [self.selectedAHRow setNeedsDisplay:YES];
    }];
        
    [self selectFirstRowIfNeeded];
    [self.selectedAHRow setExpandedWithAnimation:(expandedRowIndex >= 0)];
    [self beginUpdates];
    [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndex:rowIndex]];
    [self scrollRectToVisible:[self rectOfRow:rowIndex]];
    [self endUpdates];
    [NSAnimationContext endGrouping];    
}

#pragma mark - Key Navigation
- (BOOL)performKeyEquivalent:(NSEvent *)event
{    
    [self selectFirstRowIfNeeded];
    
    if (!self.selectedAHRow.listView.indexPathForSelectedRow) {
        [self.selectedAHRow.listView selectRowAtIndexPath:[self.selectedAHRow.listView.indexPathsForVisibleRows objectAtIndex:0] animated:YES scrollPosition:TUITableViewScrollPositionToVisible];
    }
    
    TUIFastIndexPath *selectedCellIndexPath = [self.selectedAHRow.listView indexPathForSelectedRow];
    
    NSUInteger oldCellIndex = selectedCellIndexPath.row;
    NSUInteger newCellIndex = selectedCellIndexPath.row;
    NSUInteger numberOfCellsInSelectedRow = [self.selectedAHRow.listView numberOfRowsInSection:0];
    
    switch([[event charactersIgnoringModifiers] characterAtIndex:0]) {
        case NSLeftArrowFunctionKey: {
            newCellIndex -= 1;
            newCellIndex = MAX(newCellIndex, 0);
            if (oldCellIndex != newCellIndex && newCellIndex < numberOfCellsInSelectedRow) {
                [self.selectedAHRow.listView selectRowAtIndexPath:[TUIFastIndexPath indexPathForRow:newCellIndex inSection:0] animated:YES scrollPosition:TUITableViewScrollPositionToVisible];
                return YES;
            }
            break;
        }
        case NSRightArrowFunctionKey:  {
            newCellIndex +=1;
            NSLog(@"%ld", newCellIndex);
            if (oldCellIndex != newCellIndex && (newCellIndex < numberOfCellsInSelectedRow)) {
                [self.selectedAHRow.listView selectRowAtIndexPath:[TUIFastIndexPath indexPathForRow:newCellIndex inSection:0] animated:YES scrollPosition:TUITableViewScrollPositionToVisible];
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
    
    return [super performKeyEquivalent:event];
}


-(AHRow*) selectedAHRow {
    [self selectFirstRowIfNeeded];
    return [[self rowViewAtRow:0 makeIfNecessary:NO] viewAtColumn:0];
}

-(AHCell*) selectedAHCell {
    if (!self.selectedAHRow) return nil;
    return (AHCell*) [self.selectedAHRow.listView cellForRowAtIndexPath:[self.selectedAHRow.listView indexPathForSelectedRow]];
}



//- (void) setSelectedRow:(AHRow *) row 
//{
//    if (selectedRow) [selectedRow setNeedsDisplay:YES];
//    selectedRow = row;
//    [selectedRow  setNeedsDisplay:YES];
//    
//    //Scroll to this object
//    [self scrollRectToVisible:selectedRow.frame];
//    [self.window makeFirstResponderIfNotAlreadyInResponderChain:self.selectedRow];
//}



-(void) selectCellInAdjacentRow:(AHRow*) row {
    if (row != nil) {
        CGPoint point = CGPointMake(0, 0);
        if (self.selectedRow && self.selectedCell) {
            CGRect v = self.selectedAHRow.listView.visibleRect;
            CGRect r = self.selectedAHCell.frame;
            // Adjust the point for the scroll position
            CGFloat relativeOffset = r.origin.x - (v.origin.x - roundf(self.selectedAHCell.bounds.size.width/2));
            CGRect rowVisible = row.listView.visibleRect;
            point = CGPointMake(NSMinX(rowVisible) + relativeOffset, 0);
        }
        
        // TODO
        AHCell *cellToSelect; //(AHCell*) [self.selectedRow.listView viewAtPoint:point];
    }
}

# pragma mark - Configuration

-(void) toggleConfigurationMode {
    inConfigurationMode = !inConfigurationMode;
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.3];
    [self beginUpdates];
    [self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [rows count])] ];
    [self endUpdates];
    [NSAnimationContext endGrouping];
}


@end
