//
//  AHGridMasterView.m
//  AHGrid
//
//  Created by John Wright on 1/13/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHGridMasterView.h"

#define kHeaderHeight 40
#define kSearchFieldHeight 32

@interface AHGridMasterHeaderView : TUITableViewSectionHeader 
@property (nonatomic, strong) TUITextRenderer *labelRenderer;
@end


@implementation AHGridMasterHeaderView  


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
        [gradient drawInRect:self.bounds angle:90];
        
        [[start shadowWithLevel:0.1] set];
        NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
        
        CGFloat labelHeight = 18;
        self.labelRenderer.frame = CGRectMake(15, roundf((self.bounds.size.height - labelHeight) / 2.0), self.bounds.size.width - 30, labelHeight);
        [self.labelRenderer draw];
        
    }
    
}
@end

@interface AHGridMasterCellView : TUITableViewCell 

@property (nonatomic, copy) NSAttributedString *attributedString;

@end

@implementation AHGridMasterCellView {
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
	CGRect textRect = CGRectOffset(b, 15, -15);
	textRenderer.frame = textRect; // set the frame so it knows where to draw itself
	[textRenderer draw];
	
}

@end

#define kSearchFieldWidth 215

@implementation AHGridMasterView {
    TUINSView *nsView;
    TUITableView *pickerTableView;
    NSSearchField *searchField;
    NSColor *backgroundColor;
    TUIFont *headerFont;
    TUIFont *pickerCellFont;
}

- (NSRect) frameForSearchField {
    NSRect frame = self.bounds;
    CGFloat startOfHeader = NSMaxY(frame) - kHeaderHeight;
    frame.origin.y = startOfHeader + ((kSearchFieldHeight - kSearchFieldHeight)/2);
    frame.origin.x = NSMidX(self.bounds) - (kSearchFieldWidth / 2.f);
    frame.size.height = kSearchFieldHeight;
    frame.size.width = kSearchFieldWidth;
    return frame;
}

-(NSRect) frameForPickerTableView {
    NSRect frame = self.bounds;
    frame.size.height -= kHeaderHeight;
    return frame;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        headerFont = [TUIFont fontWithName:@"HelveticaNeue" size:15];
		pickerCellFont = [TUIFont fontWithName:@"HelveticaNeue-Bold" size:15];

        backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"bg_dark.jpg"]];
        searchField = [[NSSearchField alloc] initWithFrame:[self frameForSearchField]];
        searchField.autoresizingMask = NSViewMinYMargin;
        [self addSubview:searchField];
        
        nsView = [[TUINSView alloc] initWithFrame:[self frameForPickerTableView]];
        nsView.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
        [self addSubview:nsView];
        
        pickerTableView = [[TUITableView alloc] initWithFrame:nsView.bounds];
        pickerTableView.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0]; 
        pickerTableView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        TUIView *containerView = [[TUIView alloc] initWithFrame:nsView.bounds];
        containerView.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0];
        containerView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        [containerView addSubview:pickerTableView];
        nsView.rootView = containerView;
        pickerTableView.dataSource = self;
        pickerTableView.delegate = self;
        [pickerTableView reloadData];
    }
    
    return self;
}


-(void) drawRect:(NSRect)dirtyRect {
    searchField.frame = [self frameForSearchField];
    nsView.frame = [self frameForPickerTableView];
//    [backgroundColor set];
//    NSRectFill(self.bounds);
}

#pragma mark - TUITableView methods

- (NSInteger)numberOfSectionsInTableView:(TUITableView *)tableView
{
	return 8;
}

- (NSInteger)tableView:(TUITableView *)table numberOfRowsInSection:(NSInteger)section
{
	return 25;
}

- (CGFloat)tableView:(TUITableView *)tableView heightForRowAtIndexPath:(TUIFastIndexPath *)indexPath
{
	return 50.0;
}

- (TUIView *)tableView:(TUITableView *)tableView headerViewForSection:(NSInteger)section
{
	AHGridMasterHeaderView *view = [[AHGridMasterHeaderView alloc] initWithFrame:CGRectMake(0, 0, 100, 32)];
	TUIAttributedString *title = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"Example Section %d", section]];
	title.color = [TUIColor blackColor];
	title.font = headerFont;
	view.labelRenderer.attributedString = title;
    return view;
}

- (TUITableViewCell *)tableView:(TUITableView *)tableView cellForRowAtIndexPath:(TUIFastIndexPath *)indexPath
{
	AHGridMasterCellView *cell = reusableTableCellOfClass(tableView, AHGridMasterCellView);
	
	TUIAttributedString *s = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"example cell %d", indexPath.row]];
	s.color = [TUIColor blackColor];
	s.font = headerFont;
	[s setFont:pickerCellFont inRange:NSMakeRange(8, 4)]; // make the word "cell" bold
	cell.attributedString = s;
	
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
    NSLog(@"Move dragged row: %@ => %@", fromIndexPath, toIndexPath);
}

-(TUIFastIndexPath *)tableView:(TUITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(TUIFastIndexPath *)fromPath toProposedIndexPath:(TUIFastIndexPath *)proposedPath {
    // optionally revise the drag-to-reorder drop target index path by returning a different index path
    // than proposedPath.  if proposedPath is suitable, return that.  if this method is not implemented,
    // proposedPath is used by default.
    return proposedPath;
}




@end
