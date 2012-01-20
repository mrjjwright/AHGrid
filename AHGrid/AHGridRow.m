//
//  AHRow.m
//  Crew
//
//  Created by John Wright on 1/3/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHGridRow.h"
#import "AHGridCell.h"

@implementation AHGridRow {
    TUIImageView *largeImageView;
    TUIView *headerView;
    BOOL dataLoaded;
    TUILabel *titleLabel;
}

@synthesize animating;
@synthesize expandedCell;
@synthesize grid;
@synthesize index;
@synthesize listView;
@synthesize expanded;
@synthesize selected;
@synthesize titleString;
@synthesize numberOfCells;

-(CGRect) frameForHeaderView {
    CGRect b = self.bounds;
    b.size = CGSizeMake(300, 25);
    b.origin.x = 10;
    b.origin.y = NSMaxY(listView.frame) + 5;
    return b;
    
}

-(CGRect) frameForexpandedCell {
    CGRect expandedCellFrame = self.bounds;
    expandedCellFrame.origin.y += 200;
    expandedCellFrame.size.height -= 200;
    return expandedCellFrame;
} 


- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
        self.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
        
        self.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0];
                
        listView = [[TUILayout alloc] initWithFrame:CGRectZero];
        listView.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0];
        listView.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
        listView.dataSource = self;
        listView.typeOfLayout = TUILayoutHorizontal;
        listView.horizontalScrolling = YES;
        listView.spaceBetweenViews = 5;
        listView.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleWhenMouseInside;
        [self addSubview:listView];
        
        titleLabel = [[TUILabel alloc] initWithFrame:CGRectMake(10, self.bounds.size.height - 25, 300, 25)];
        titleLabel.text = titleString;
        titleLabel.font = [TUIFont boldSystemFontOfSize:12];
        titleLabel.textColor = [TUIColor blackColor];
        titleLabel.backgroundColor = [TUIColor clearColor];
        [self addSubview:titleLabel];
        
        expandedCell = [[AHGridExpandedCell alloc] initWithFrame:[self frameForexpandedCell]];
        expandedCell.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        [self addSubview:expandedCell];
        expandedCell.alpha = 0;
        [self sendSubviewToBack:expandedCell];
    }
    return self;
}

-(void) setGrid:(AHGrid *)g {
    grid = g;
}

#pragma mark - Layout

-(void) layoutSubviews {
    if (animating) {
        return [super layoutSubviews];
    }
    CGRect b = self.bounds;
    CGRect listRect = b;
    listRect.size.height = 175;
    listView.frame = listRect;
    if (!dataLoaded) {
        [listView reloadData];
        dataLoaded = YES;
    }
    
    if (!self.expanded || (self.expanded && !animating)) {
        expandedCell.frame = [self frameForexpandedCell];
        [expandedCell setNeedsLayout];
    }

    titleLabel.frame = [self frameForHeaderView];
    titleLabel.text = titleString;
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
    
    if (grid.configureCellBlock) {
        grid.configureCellBlock(grid, self, cell, i);
    }
    return cell;
}

- (NSUInteger)numberOfObjectsInLayout:(TUILayout *)l {
    return numberOfCells;
}

- (CGSize)sizeOfObjectAtIndex:(NSUInteger)index {
    CGSize size = self.bounds.size;
    size.height -= 25;
    size.width = 275;
    return size;
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


#pragma mark - Expansion


#pragma mark - Key Handling

- (BOOL)performKeyAction:(NSEvent *)event {
   return [grid performKeyAction:event];
}



@end
