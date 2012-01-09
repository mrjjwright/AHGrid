//
//  AHRow.m
//  Crew
//
//  Created by John Wright on 1/3/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHRow.h"
#import "AHCell.h"


@implementation AHRow {
    
    TUIView *detailView;
    TUIScrollView *detailScrollView;
    TUIImageView *largeImageView;
    BOOL dataLoaded;
}

@synthesize cells;
@synthesize grid;
@synthesize index;
@synthesize listView;
@synthesize expanded;
@synthesize animating;
@synthesize selected;

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
        cells = [NSMutableArray array];
        self.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
        for (int i = 0; i < 100; i++) {
            [cells addObject:[NSMutableDictionary dictionary]];
        }
        
        listView = [[TUILayout alloc] initWithFrame:CGRectZero];
        listView.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
        listView.dataSource = self;
        listView.typeOfLayout = TUILayoutHorizontal;
        listView.backgroundColor = [TUIColor clearColor];
        listView.horizontalScrolling = YES;
        listView.spaceBetweenViews = 15;
        listView.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleWhenMouseInside;
        listView.viewClass = [AHCell class];
        [self addSubview:listView];
    }
    return self;
}

-(void) setGrid:(AHGrid *)g {
    grid = g;
}

#pragma mark - Layout

-(void) layoutSubviews {
    if (animating) return [super layoutSubviews];
    CGRect b = self.bounds;
    CGRect listRect = b;
    if (self.expanded) {
        listRect.size.height = 250;
    }
    listView.frame = listRect;
    if (!dataLoaded) {
        [listView reloadData];
        dataLoaded = YES;
    }
    [super layoutSubviews];
}

#pragma mark  - TUILayout DataSource Methods



-(TUIView*) layout:(TUILayout *)l viewForObjectAtIndex:(NSInteger)i {
    
    AHCell *cell = (AHCell*) [listView dequeueReusableView];
	
//	TUIAttributedString *s = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"example cell %d", i]];
//	s.color = [TUIColor blackColor];
//	s.font = [TUIFont systemFontOfSize:11];
//	cell.attributedString = s;
    
    
	cell.row = self;
    [cell prepareForReuse];
    cell.selected = (index == grid.selectedRowIndex) && (i == grid.selectedCellIndex);
    cell.grid = grid;
    cell.index = i;
	return cell;
}

- (NSUInteger)numberOfObjectsInLayout:(TUILayout *)l {
    return [cells count];
}

- (CGSize)sizeOfObjectAtIndex:(NSUInteger)index {
    CGSize size = self.bounds.size;
    size.width = 350;
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

-(void) toggleExpanded {
    CGFloat height = expanded  ? 250 : grid.visibleRect.size.height;
    animating = YES;

    [grid resizeObjectAtIndex:self.index toSize:CGSizeMake(self.bounds.size.width, height) animationBlock:^{
        // Fade in the detail view
        
        if (!detailScrollView) {
            detailScrollView = [[TUIScrollView alloc] initWithFrame:CGRectMake(0, 250, self.bounds.size.width, 300)];
            detailScrollView.backgroundColor = [TUIColor clearColor];
            [self addSubview:detailScrollView];
            detailView = [[TUIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 400)];
            largeImageView = [[TUIImageView alloc] initWithFrame:detailView.bounds];
            largeImageView.backgroundColor = [TUIColor greenColor];
            largeImageView.image = [TUIImage imageNamed:@"pet_plumes.jpg"];
            [detailView addSubview:largeImageView];
            [detailScrollView addSubview:detailView];
            detailScrollView.alpha = 0;
            [detailScrollView scrollToTopAnimated:NO];
        } 
        
        CGFloat alpha = expanded ? 0 : 1.0;
        detailScrollView.alpha = alpha;
        
        CGRect b = self.bounds; 
        CGRect listRect = b;
        listRect.size.height = 250;
        listView.frame = listRect;
        
        detailScrollView.frame = CGRectMake(0, 250, self.bounds.size.width, 300);
        detailView.frame =  detailScrollView.bounds;
        
        // scroll the grid into place
        [grid scrollRectToVisible:self.frame animated:YES];
    }  completionBlock:^{
        expanded = !expanded;
        grid.scrollEnabled = !expanded;
        if (expanded) {
            grid.verticalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
        } else {
            grid.verticalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleWhenMouseInside;
        }
        animating = NO;
        [self setNeedsLayout];
    }];
}


@end
