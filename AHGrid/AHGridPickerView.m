//
//  AHGridMasterView.m
//  AHGrid
//
//  Created by John Wright on 1/13/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHGridPickerView.h"

#define kHeaderHeight 40
#define kSearchFieldHeight 32


@implementation AHGridPickerHeaderView {
}


@synthesize labelRenderer;

-(id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		labelRenderer = [[TUITextRenderer alloc] init];
		self.textRenderers = [NSArray arrayWithObjects:labelRenderer, nil];
		self.opaque = TRUE;
	}
	return self;
}

-(void)headerWillBecomePinned {
    self.opaque = FALSE;
    [super headerWillBecomePinned];
}

-(void)headerWillBecomeUnpinned {
    self.opaque = TRUE;
    [super headerWillBecomeUnpinned];
}

-(void)drawRect:(CGRect)rect {
    CGRect b = self.bounds;
    CGContextRef g;
    if((g = TUIGraphicsGetCurrentContext()) != nil){
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:g flipped:FALSE]];
        
        if(!self.pinnedToViewport){
            [[NSColor whiteColor] set];
            NSRectFill(self.bounds);
        }
        
        NSColor *start = [NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.8 alpha:0.9];
        NSColor *end = [NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha:0.9];
        NSGradient *gradient = nil;
        
        gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
        CGRect gradientRect = b;
        [gradient drawInRect:gradientRect angle:90];
        
        [[start shadowWithLevel:0.1] set];
        NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
        
        CGFloat labelHeight = 18;
        self.labelRenderer.frame = CGRectMake(15, roundf((self.bounds.size.height - labelHeight) / 2.0), self.bounds.size.width - 30, labelHeight);
        [self.labelRenderer draw];
    }
    
}
@end



@implementation AHGridPickerCellView {
    TUITextRenderer *textRenderer;
}

@synthesize attributedString;

- (id)initWithStyle:(TUITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		textRenderer = [[TUITextRenderer alloc] init];
		
		self.textRenderers = [NSArray arrayWithObjects:textRenderer, nil];
	}
	return self;
}


- (NSAttributedString *)attributedString
{
	return textRenderer.attributedString;
}

- (void)setAttributedString:(NSAttributedString *)a
{
	textRenderer.attributedString = a;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGRect b = self.bounds;
	
    CGContextRef ctx = TUIGraphicsGetCurrentContext();
    
	if(self.selected) {
		// selected background
		CGContextSetRGBFillColor(ctx, .87, .87, .87, 1);
		CGContextFillRect(ctx, b);
	} else {
		// light gray background
		CGContextSetRGBFillColor(ctx, .97, .97, .97, 1);
		CGContextFillRect(ctx, b);
		
		// emboss
		CGContextSetRGBFillColor(ctx, 1, 1, 1, 0.9); // light at the top
		CGContextFillRect(ctx, CGRectMake(0, b.size.height-1, b.size.width, 1));
		CGContextSetRGBFillColor(ctx, 0, 0, 0, 0.08); // dark at the bottom
		CGContextFillRect(ctx, CGRectMake(0, 0, b.size.width, 1));
	}
	
	// text
	CGRect textRect = CGRectOffset(b, 10, -10);
	textRenderer.frame = textRect; // set the frame so it knows where to draw itself
	[textRenderer draw];	
}

@end

#define kSearchFieldWidth 215


@implementation AHGridPickerView {
    TUINSView *nsView;
    NSSearchField *searchField;
    BOOL firstLoadComplete;
}

@synthesize grid;
@synthesize pickerTableView;
@synthesize headerConfigureBlock;
@synthesize cellConfigureBlock;
@synthesize reorderBlock;
@synthesize headerHeight;
@synthesize cellHeight;
@synthesize numberOfSections;
@synthesize numberOfRowsBlock;

- (NSRect) frameForSearchField {
    NSRect frame = self.bounds;
    CGFloat startOfHeader = NSMaxY(frame) - headerHeight;
    frame.origin.y = startOfHeader + ((headerHeight - kSearchFieldHeight)/2);
    frame.origin.x = NSMidX(self.bounds) - (kSearchFieldWidth / 2.f);
    frame.size.height = kSearchFieldHeight;
    frame.size.width = kSearchFieldWidth;
    return frame;
}

-(NSRect) frameForPickerTableView {
    NSRect frame = self.bounds;
    frame.size.height -= (headerHeight);
    return frame;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        headerHeight = 40;
        cellHeight = 50;
        numberOfSections = 8;
        searchField = [[NSSearchField alloc] initWithFrame:[self frameForSearchField]];
        searchField.autoresizingMask = NSViewMinXMargin | NSViewWidthSizable;
        [searchField setTarget:self];
        [searchField setAction:@selector(searchAction:)];
        [self addSubview:searchField];
        
        nsView = [[TUINSView alloc] initWithFrame:[self frameForPickerTableView]];
        nsView.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
        [self addSubview:nsView];
        
        pickerTableView = [[TUITableView alloc] initWithFrame:nsView.bounds];
        pickerTableView.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0]; 
        pickerTableView.verticalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleWhenMouseInside;
        pickerTableView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        TUIView *containerView = [[TUIView alloc] initWithFrame:nsView.bounds];
        containerView.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0];
        containerView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        [containerView addSubview:pickerTableView];
        nsView.rootView = containerView;
        pickerTableView.dataSource = self;
        pickerTableView.delegate = self;
        
    }
    
    return self;
}


-(void) resizeSubviewsWithOldSize:(NSSize)oldSize {
    searchField.frame = [self frameForSearchField];
    nsView.frame = [self frameForPickerTableView];
    pickerTableView.frame = nsView.bounds;
    [pickerTableView setNeedsLayout];
}

#pragma mark - TUITableView methods

- (NSInteger)numberOfSectionsInTableView:(TUITableView *)tableView
{
	return numberOfSections;
}

- (NSInteger)tableView:(TUITableView *)table numberOfRowsInSection:(NSInteger)section
{
	if (numberOfRowsBlock) return numberOfRowsBlock(self, section);
    if (section == 0) {
        return grid.numberOfRows;
    }
    return 25;
}

- (CGFloat)tableView:(TUITableView *)tableView heightForRowAtIndexPath:(TUIFastIndexPath *)indexPath
{
	return cellHeight;
}

- (TUIView *)tableView:(TUITableView *)tableView headerViewForSection:(NSInteger)section
{
	AHGridPickerHeaderView *view = [[AHGridPickerHeaderView alloc] initWithFrame:CGRectMake(0, 0, 100, headerHeight)];
    if (headerConfigureBlock) {
        headerConfigureBlock(self, view, section);
    }
    return view;
}

- (TUITableViewCell *)tableView:(TUITableView *)tableView cellForRowAtIndexPath:(TUIFastIndexPath *)indexPath
{
	AHGridPickerCellView *cell = reusableTableCellOfClass(tableView, AHGridPickerCellView);
	
    if (cellConfigureBlock) {
        cellConfigureBlock(self, cell, indexPath.section, indexPath.row);
    }
	
	return cell;
}

- (void)tableView:(TUITableView *)tableView didClickRowAtIndexPath:(TUIFastIndexPath *)indexPath withEvent:(NSEvent *)event
{
	if([event clickCount] == 1) {
		// do something cool
	}
	
	if(event.type == NSRightMouseUp){
		// show context menu
	}
}
- (BOOL)tableView:(TUITableView *)tableView shouldSelectRowAtIndexPath:(TUIFastIndexPath *)indexPath forEvent:(NSEvent *)event{
	switch (event.type) {
		case NSRightMouseDown:
			return NO;
	}
    
	return YES;
}

-(BOOL)tableView:(TUITableView *)tableView canMoveRowAtIndexPath:(TUIFastIndexPath *)indexPath {
    // return TRUE to enable row reordering by dragging; don't implement this method or return
    // FALSE to disable
    return TRUE;
}

-(void)tableView:(TUITableView *)tableView moveRowAtIndexPath:(TUIFastIndexPath *)fromIndexPath toIndexPath:(TUIFastIndexPath *)toIndexPath {
    // update the model to reflect the changed index paths; since this example isn't backed by
    // a "real" model, after dropping a cell the table will revert to it's previous state
    if (reorderBlock) reorderBlock(self, fromIndexPath.section, fromIndexPath.row, toIndexPath.section, toIndexPath.row);
}

-(TUIFastIndexPath *)tableView:(TUITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(TUIFastIndexPath *)fromPath toProposedIndexPath:(TUIFastIndexPath *)proposedPath {
    // optionally revise the drag-to-reorder drop target index path by returning a different index path
    // than proposedPath.  if proposedPath is suitable, return that.  if this method is not implemented,
    // proposedPath is used by default.
    return proposedPath;
}

#pragma mark - IBActions

-(IBAction)searchAction:(id)sender {
    NSLog(@"%@", [sender stringValue]);
}


@end
