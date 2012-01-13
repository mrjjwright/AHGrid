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

-(void) selectCellInAdjacentRow:(AHRow*) row;

@end

@implementation AHGrid {
    NSMutableArray *rows;
    CGFloat configurationModeRowHeight;
    NSMutableArray *rowViews;
    CGRect lastBounds;
    BOOL animating;
}

@synthesize expandedRowIndex;
@synthesize inConfigurationMode;

@synthesize selectedRow;
@synthesize selectedCell;
@synthesize selectedRowIndex;
@synthesize selectedCellIndex;
@synthesize detailView;


-(CGRect) frameForDetailView {
    CGRect detailViewFrame = self.visibleRect;
    detailViewFrame.origin.y += 200;
    detailViewFrame.size.height -= 200;
    return detailViewFrame;
} 

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
        configurationModeRowHeight = 100;
        selectedRowIndex = -1;
        selectedCellIndex = -1;
        self.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
        self.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin | NSViewWidthSizable | NSViewHeightSizable;    
        // Initialization code here.
        rows = [NSMutableArray array];
        rowViews = [NSMutableArray array];
        for (int i = 0; i < 10; i++) {
            NSDictionary *rowInfo = [NSDictionary dictionary];
            [rows addObject:rowInfo];
            AHRow *rowView = (AHRow*) [[AHRow alloc] initWithFrame:CGRectZero];
            rowView.index = i;
            rowView.grid = self;
            [rowViews addObject:rowView];
        }
        expandedRowIndex = -1;
        self.dataSource = self;
        self.spaceBetweenViews = 15;
        self.viewClass = [AHRow class];
        
        detailView = [[AHDetailView alloc] initWithFrame:[self frameForDetailView]];
        detailView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        [self addSubview:detailView];
        detailView.alpha = 0;
        [self sendSubviewToBack:detailView];
    }
    return self;
}



-(void) layoutSubviews {
    if (!CGSizeEqualToSize(lastBounds.size, self.bounds.size)) {
        lastBounds = self.bounds;
        [self reloadData];
    }
    
    lastBounds = self.bounds;
    if (!self.selectedRow.expanded || (expandedRowIndex >= 0  && !self.selectedRow.expanded) || (self.selectedRow.expanded && !animating)) {
        detailView.frame = [self frameForDetailView];
        [detailView setNeedsLayout];
    }
    [super layoutSubviews];
}


#pragma mark - TUILayoutDataSource methods

-(TUIView*) layout:(TUILayout *)l viewForObjectAtIndex:(NSInteger)index {
    AHRow *rowView = [rowViews objectAtIndex:index];
    rowView.index = index;
    rowView.grid = self;
    
    rowView.expanded = NO;
    if (expandedRowIndex >=0 && index == expandedRowIndex) {
        rowView.expanded = YES;
    } else {
        rowView.expanded = NO;
    }
    rowView.titleString = @"John Wright's feed";
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
    
    NSUInteger numberOfCellsInSelectedRow = [self.selectedRow.cells count];
    NSUInteger numberOfRows = [rows count];
    
    switch([[event charactersIgnoringModifiers] characterAtIndex:0]) {
        case NSLeftArrowFunctionKey: {
            newCellIndex -= 1;
            newCellIndex = MAX(newCellIndex, 0);
            if (oldCellIndex != newCellIndex && newCellIndex < numberOfCellsInSelectedRow) {
                self.selectedCell = (AHCell*) [self.selectedRow.listView viewForIndex:newCellIndex];
            }
            return YES;;
        }
        case NSRightArrowFunctionKey:  {
            newCellIndex +=1;
            if (oldCellIndex != newCellIndex && (newCellIndex < numberOfCellsInSelectedRow)) {
                self.selectedCell = (AHCell*) [self.selectedRow.listView viewForIndex:newCellIndex];
            }
            return YES;
        }
        case NSDownArrowFunctionKey: {
             if (self.selectedRow.expanded == YES) return YES;
            newRowIndex += 1;
            if (oldRowIndex != newRowIndex && (newRowIndex < numberOfRows)) {
                [self selectCellInAdjacentRow:(AHRow*) [self viewForIndex:newRowIndex]];
            }
            return YES;
        }
        case NSUpArrowFunctionKey: {
             if (self.selectedRow.expanded == YES) return YES;
            newRowIndex -= 1;
            newRowIndex = MAX(newRowIndex, 0);
            if (oldRowIndex != newRowIndex && (newRowIndex < numberOfRows)) {
                [self selectCellInAdjacentRow:(AHRow*) [self viewForIndex:newRowIndex]];
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


-(AHRow*) selectedRow {
    if (selectedRowIndex >=0) {
        return (AHRow*) [self viewForIndex:selectedRowIndex];        
    }
    return  nil;
}

-(AHCell*) selectedCell {
    if (selectedCellIndex >= 0) {
        return (AHCell*) [self.selectedRow.listView viewForIndex:selectedCellIndex];
    }
    return nil;
}

- (void) setSelectedRow:(AHRow *) row 
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

- (void) setSelectedCell:(AHCell *) cell 
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
            self.selectedCell.expanded = YES;
            detailView.userString = self.selectedCell.userString;
            detailView.photoImageView.image =  self.selectedCell.smallPhotoImage;
            detailView.profileImageView.image = self.selectedCell.profileImage;
            [detailView layoutSubviews];
            [detailView scrollToTopAnimated:NO];
        }
    }
}

-(void) selectCellInAdjacentRow:(AHRow*) row {
    CGRect v = self.selectedRow.listView.visibleRect;
    CGRect r = self.selectedCell.frame;
    // Adjust the point for the scroll position
    CGFloat relativeOffset = r.origin.x - (v.origin.x - roundf(self.selectedCell.bounds.size.width/2));
    CGRect rowVisible = row.listView.visibleRect;
    CGPoint point = CGPointMake(NSMinX(rowVisible) + relativeOffset, 0);
    self.selectedCell = (AHCell*) [row.listView viewAtPoint:point];
}

# pragma mark - Configuration

#pragma mark - Expansion

-(void) toggleSelectedRowExpanded {
    CGFloat height = expandedRowIndex >=0  ? 200 : self.visibleRect.size.height;
    animating = YES;
    
    [self resizeObjectAtIndex:self.selectedRow.index toSize:CGSizeMake(self.bounds.size.width, height) animationBlock:^{
        // Fade in the detail view
        detailView.userString = self.selectedCell.userString;
        detailView.photoImageView.image =  self.selectedCell.smallPhotoImage;
        detailView.profileImageView.image = self.selectedCell.profileImage;
        [detailView scrollToTopAnimated:YES];
        
        CGFloat alpha = expandedRowIndex >=0 ? 0 : 1.0;
        detailView.alpha = alpha;
        
        [self.selectedRow layoutSubviews];        
        
        // scroll the grid into place
        [self scrollRectToVisible:self.selectedRow.frame animated:YES];
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
        [self setNeedsLayout];
        [detailView scrollToTopAnimated:YES];
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


# pragma mark - Actions


-(void) showCommentEditorOnSelectedCell {
    if (self.selectedCell) {
        [self.selectedCell showCommentEditor];
    }
}



@end
