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

    // The TUINSView for TUIKit to wrap the listView
    TUINSView *listViewNSView;
    
    // Detail views
    NSView *detailView;
    NSScrollView *detailScrollView;
    NSImageView *largeImageView;

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
    listView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    listView.delegate = self;
    listView.backgroundColor = [TUIColor redColor];
    listView.dataSource = self;
    listView.horizontalScrolling = YES;
    listView.horizontalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleWhenMouseInside;
    

    listViewNSView = [[TUINSView alloc] initWithFrame:CGRectZero];
    listViewNSView.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin | NSViewWidthSizable | NSViewHeightSizable;    
    listViewNSView.rootView = listView;
    [self addSubview:listViewNSView];
    [listView reloadData];
}

-(void) setGrid:(AHGrid *)g {
    grid = g;
    listViewNSView.scrollingInterceptor = self;
}

#pragma mark - Layout

-(void) viewWillDraw {
    if (animating) return [super viewWillDraw];
    CGRect b = self.bounds;
    CGRect listRect = b;
    if (self.expanded) {
        listRect.size.height = 250;
    }
    listViewNSView.frame = listRect; 
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
    
    if (!detailScrollView) {
        detailScrollView = [[NSScrollView alloc] initWithFrame:CGRectMake(0, 250, self.bounds.size.width, 100)];
        detailScrollView.backgroundColor = [NSColor colorWithDeviceRed:0.79 green:0.79 blue:0.79 alpha:1.0];
        detailView = [[NSView alloc] initWithFrame:CGRectMake(0, 250, self.bounds.size.width, 400)];
        detailScrollView.documentView = detailView;
        [self addSubview:detailScrollView];
        
        largeImageView = [[NSImageView alloc] initWithFrame:detailView.bounds];
        largeImageView.image = [NSImage imageNamed:@"pet_plumes.jpg"];
        [detailView addSubview:largeImageView];
        [detailScrollView setAlphaValue:0];
    }  
    CGFloat alpha = expanded ? 1.0 : 0;
    [[detailScrollView animator] setAlphaValue:alpha];
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
        if (expanded) {
            [detailScrollView scrollWheel:event];
        } else {
            [self.grid scrollWheel:event];
        }
    } else { 
        [listView scrollWheel:event];
    }
    return NO;
}


@end
