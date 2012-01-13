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
    TUIImageView *largeImageView;
    TUIView *headerView;
    BOOL dataLoaded;
    TUIFont *userStringFont;
    TUILabel *titleLabel;
}

@synthesize animating;
@synthesize detailView;
@synthesize cells;
@synthesize grid;
@synthesize index;
@synthesize listView;
@synthesize expanded;
@synthesize selected;
@synthesize titleString;

-(CGRect) frameForHeaderView {
    CGRect b = self.bounds;
    b.size = CGSizeMake(300, 25);
    b.origin.x = 10;
    b.origin.y = NSMaxY(listView.frame) + 5;
    return b;
    
}

-(CGRect) frameForDetailView {
    CGRect detailViewFrame = self.bounds;
    detailViewFrame.origin.y += 200;
    detailViewFrame.size.height -= 200;
    return detailViewFrame;
} 


- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
        cells = [NSMutableArray array];
        self.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
        for (int i = 0; i < 100; i++) {
            [cells addObject:[NSMutableDictionary dictionary]];
        }
        
        userStringFont = [TUIFont boldSystemFontOfSize:11];
        
        listView = [[TUILayout alloc] initWithFrame:CGRectZero];
        listView.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0];
        listView.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
        listView.dataSource = self;
        listView.typeOfLayout = TUILayoutHorizontal;
        listView.horizontalScrolling = YES;
        listView.spaceBetweenViews = 5;
        listView.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleWhenMouseInside;
        listView.viewClass = [AHCell class];
        [self addSubview:listView];
        
        titleLabel = [[TUILabel alloc] initWithFrame:CGRectMake(10, self.bounds.size.height - 25, 300, 25)];
        titleLabel.text = titleString;
        titleLabel.font = [TUIFont boldSystemFontOfSize:12];
        titleLabel.textColor = [TUIColor blackColor];
        titleLabel.backgroundColor = [TUIColor clearColor];
        [self addSubview:titleLabel];
        
        detailView = [[AHDetailView alloc] initWithFrame:[self frameForDetailView]];
        detailView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        [self addSubview:detailView];
        detailView.alpha = 0;
        [self sendSubviewToBack:detailView];
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
        detailView.frame = [self frameForDetailView];
        [detailView setNeedsLayout];
    }

    
    titleLabel.frame = [self frameForHeaderView];
    titleLabel.text = titleString;
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
    
    NSArray *pictures =[NSArray arrayWithObjects:@"jw_profile.jpg", @"girl_bubble.jpg", @"amy_john.jpg",@"john_amy.jpg", nil];
    
    cell.profileImage = [TUIImage imageNamed:[pictures objectAtIndex:arc4random() % 3] cache:YES];
    cell.smallPhotoImage = [TUIImage imageNamed:[pictures objectAtIndex:arc4random() % 3]   cache:YES];
    cell.firstButtonImage = [TUIImage imageNamed:@"heart.png"  cache:YES];
    cell.secondButtonImage = [TUIImage imageNamed:@"reply.png" cache:YES];
    TUIAttributedString *userString = [TUIAttributedString stringWithString:@"John Wright"];
    userString.font = userStringFont;
    cell.userString = userString;
    
	return cell;
}

- (NSUInteger)numberOfObjectsInLayout:(TUILayout *)l {
    return [cells count];
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
