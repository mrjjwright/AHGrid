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
    
    NSMutableArray *cells;

    // The nsView for TUIKit that fits into the AppKit view hierarchy
    TUINSView *nsView;

    // A container TUIScrollView to hold the expanded cell.
    // Scrollable because some cells might have long content.
    // Lazily created.
    TUIScrollView *cellScrollView;
    
    //A container TUIView to hold the cellScrollView and the listView
    TUIView *containerView;
    
    TUIImageView *largeImageView;
}

@synthesize grid;
@synthesize index;
@synthesize listView;
@synthesize expanded;
@synthesize animating;

- (void)awakeFromNib {
    
    cells = [NSMutableArray array];
    
    for (int i = 0; i < 100; i++) {
        [cells addObject:[NSMutableDictionary dictionary]];
    }
    
    // The horizontal table view
    listView = [[TUITableView alloc] initWithFrame:CGRectZero];
    //listView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    listView.delegate = self;
    listView.backgroundColor = [TUIColor redColor];
    listView.dataSource = self;
    listView.horizontalScrolling = YES;
    listView.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleWhenMouseInside;
    
    containerView = [[TUIView alloc] initWithFrame:CGRectZero];    
    [containerView addSubview:listView];

    nsView = [[TUINSView alloc] initWithFrame:CGRectZero];
    //nsView.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin | NSViewWidthSizable | NSViewHeightSizable;    
    nsView.rootView = containerView;
    [self addSubview:nsView];
    [listView reloadData];
}

-(void) setGrid:(AHGrid *)g {
    grid = g;
    nsView.scrollingInterceptor = self;
}

#pragma mark - Layout

-(void) viewWillDraw {
    if (animating) return [super viewWillDraw];
    CGRect b = self.bounds;
    CGRect listRect = b;
    if (self.expanded) {
        listRect.size.height = 250;
    }
    nsView.frame = b; 
    containerView.frame = b;
    listView.frame = listRect;
}

#pragma mark -
#pragma mark TUITableView Delegate Methods


- (CGFloat)tableView:(TUITableView *)tableView heightForRowAtIndexPath:(TUIFastIndexPath *)indexPath {
    return 350;
}

- (NSInteger)numberOfSectionsInTableView:(TUITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(TUITableView *)table numberOfRowsInSection:(NSInteger)section
{
	return [cells count];
}


- (TUITableViewCell *)tableView:(TUITableView *)tableView cellForRowAtIndexPath:(TUIFastIndexPath *)indexPath
{
	AHCell *cell = reusableTableCellOfClass(tableView, AHCell);
	
	TUIAttributedString *s = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"example cell %d", indexPath.row]];
	s.color = [TUIColor blackColor];
	s.font = [TUIFont systemFontOfSize:11];
	cell.attributedString = s;
	cell.row = self;
    cell.grid = grid;
	return cell;
}

- (void)tableView:(TUITableView *)tableView didClickRowAtIndexPath:(TUIFastIndexPath *)indexPath withEvent:(NSEvent *)event
{
	if([event clickCount] == 1) {
		// do something cool
	}
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
    [grid togglExpansionForRow:self.index];
}

-(void) setExpandedWithAnimation:(BOOL)e {
    expanded = e;
    
    if (!cellScrollView) {
        cellScrollView = [[TUIScrollView alloc] initWithFrame:CGRectMake(0, 250, self.bounds.size.width, 400)];
        cellScrollView.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
        cellScrollView.backgroundColor = [TUIColor blueColor];
        cellScrollView.contentSize = CGSizeMake(self.bounds.size.width, 800);
        [containerView addSubview:cellScrollView];
        
        largeImageView = [[TUIImageView alloc] initWithImage:[TUIImage imageNamed:@"pet_plumes.jpg"]];
        largeImageView.frame = cellScrollView.bounds;
        largeImageView.clipsToBounds = YES;
        [cellScrollView addSubview:largeImageView];
        cellScrollView.alpha = 0;
        [containerView sendSubviewToBack:cellScrollView];
    }
    [TUIView animateWithDuration:0.7 animations:^{
        cellScrollView.alpha = 0.2;
    }];
    
}

-(BOOL) isVerticalScroll:(NSEvent*) event {
    
    // Get the amount of scrolling
    double dx = 0.0;
    double dy = 0.0;
    
    CGEventRef cgEvent = [event CGEvent];
    const int64_t isContinuous = CGEventGetIntegerValueField(cgEvent, kCGScrollWheelEventIsContinuous);
    
    if(isContinuous) {
        dx = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventPointDeltaAxis2);
        dy = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventPointDeltaAxis1);
    } else {
        CGEventSourceRef source = CGEventCreateSourceFromEvent(cgEvent);
        if(source) {
            const double pixelsPerLine = CGEventSourceGetPixelsPerLine(source);
            dx = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventFixedPtDeltaAxis2) * pixelsPerLine;
            dy = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventFixedPtDeltaAxis1) * pixelsPerLine;
            CFRelease(source);
        } else {
            NSLog(@"Critical: NULL source from CGEventCreateSourceFromEvent");
        }
    }
    
    if (fabsf(dx) > fabsf(dy)) return NO;
    return YES;
}

- (BOOL)shouldScrollWheel:(NSEvent *)event {
    if ([self isVerticalScroll:event]) {
        [self.grid scrollWheel:event];
    } else { 
        [listView scrollWheel:event];
    }
    return NO;
}


@end
