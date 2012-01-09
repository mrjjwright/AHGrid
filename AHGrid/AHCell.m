//
//  AHCell.m
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import "AHCell.h"
#import "TUIKit.h"

@implementation AHCell {
    TUITextRenderer *textRenderer;
    BOOL showingCommentEditor;
    
    TUIImageView *smallPhotoImageView;
    
    BOOL animating;
}

@synthesize row;
@synthesize grid;
@synthesize index;
@synthesize selected;
@synthesize commentEditor;

// Text
@synthesize userString;
@synthesize dateString;
@synthesize mainString;
@synthesize likesString;
@synthesize commentsString;
@synthesize commentsTextInputPlaceholderString;

// Images
@synthesize profileImage;
@synthesize smallPhotoImage;
@synthesize largePhotoImage;

// Action buttons
@synthesize firstButtonImage;
@synthesize secondButtonImage;
@synthesize thirdButtonImage;


- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
		
        self.clipsToBounds = YES;
        textRenderer = [[TUITextRenderer alloc] init];
        self.textRenderers = [NSArray arrayWithObjects:textRenderer, nil];
        
        smallPhotoImageView = [[TUIImageView alloc] initWithImage:[TUIImage imageNamed:@"pet_plumes.jpg"]];
        smallPhotoImageView.layer.contentsGravity = kCAGravityResizeAspect;
        smallPhotoImageView.clipsToBounds = YES;
        [self addSubview:smallPhotoImageView];
	}
	return self;
}

-(void) prepareForReuse {
    self.selected = NO;
    showingCommentEditor = NO;
}


-(void) layoutSubviews {
    CGRect b = self.bounds;

    // Default position for all items
    CGRect commentEditorFrame = b;
    commentEditorFrame.size.height = 100;
    CGRect smallPhotoFrame = b;
    
    if (showingCommentEditor) {
        // Move everything else up
        smallPhotoFrame.origin.y = NSMaxY(commentEditorFrame);
    }
    commentEditor.frame = commentEditorFrame;
    smallPhotoImageView.frame = smallPhotoFrame;
}

- (void)drawRect:(CGRect)rect
{
	CGRect b = self.bounds;
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	
	if(self.selected) {
		// selected background
		CGContextSetRGBFillColor(ctx, .87, .87, .87, 1);
		CGContextFillRect(ctx, b);
        
        smallPhotoImageView.layer.cornerRadius = 6;
        smallPhotoImageView.layer.borderWidth = 2;
        smallPhotoImageView.layer.borderColor = [TUIColor  yellowColor].CGColor;
	} else {
		// light gray background
		CGContextSetRGBFillColor(ctx, .97, .97, .97, 1);
		CGContextFillRect(ctx, b);
        
        smallPhotoImageView.layer.cornerRadius = 0;
        smallPhotoImageView.layer.borderWidth = 0;
        
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


#pragma mark - Selection

-(BOOL)acceptsFirstResponder {
    return TRUE;
}

- (void)mouseDown:(NSEvent *)event
{
    grid.selectedCell = self;
	[super mouseDown:event]; // may make the text renderer first responder, so we want to do the selection before this	
}


-(NSMenu*) menuForEvent:(NSEvent *)event {
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Comment",nil) action:@selector(toggleCommentEditor) keyEquivalent:@""];
    item.target =self;
    [menu addItem:item];
    
    NSMenuItem *item1 = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Toggle Expand To Fill",nil) action:@selector(toggleExpanded) keyEquivalent:@""];
    item1.target = self.row;
    [menu addItem:item1];

    return menu;
}


#pragma mark - Comments


-(BOOL) textView:(TUITextView*) textView doCommandBySelector:(SEL) commandSelector {
    if (commandSelector == @selector(cancelOperation:)) {
        [self showCommentEditor];
        return YES;
    } else if (commandSelector == @selector(insertNewline:)) {
        // The user pressed enter, fire off the comment
//        JokinglyOperation *operation = [FacebookClient operationForComment:textView.text on:self.fbObject]; 
//        [operation addHandler:^(JokinglyOperation *operation) {
//            // TODO animate in comment
//        }];
//        [[FacebookClient operationQueue] addOperation:operation];
        return YES;
    }
    return NO;
}


- (void) showCommentEditor {
    if (!self.selected) {
        grid.selectedCell = self;
    }
    if (!commentEditor) {
        CGRect frame = self.bounds;
        frame.size.height *= 0.2;
        commentEditor = [[TUITextView alloc] initWithFrame:frame];
        commentEditor.backgroundColor = [TUIColor whiteColor];
        commentEditor.layer.borderColor = [TUIColor yellowColor].CGColor;
        commentEditor.layer.borderWidth = 1;
        commentEditor.layer.cornerRadius = 4;
        commentEditor.layer.shadowColor = [TUIColor blackColor].CGColor;
        commentEditor.layer.shadowOffset = CGSizeMake(2, 2);
        commentEditor.delegate =  (__strong id) self;
        commentEditor.contentInset = TUIEdgeInsetsMake(5, 5, 5, 5);
        commentEditor.hidden = YES;
        commentEditor.spellCheckingEnabled = YES;
        [self addSubview:commentEditor];
        commentEditor.editable = YES;
        [self sendSubviewToBack:commentEditor];
    }
    
    commentEditor.hidden = NO;
    [TUIView animateWithDuration:0.3 animations:^{
        CGRect frame = smallPhotoImageView.frame;
        frame.origin.y = NSMaxY(commentEditor.frame);
        smallPhotoImageView.frame = frame;
        [self.nsWindow makeFirstResponderIfNotAlreadyInResponderChain:commentEditor];
    } completion:^(BOOL finished) {
        [self setNeedsLayout];
    }];
}

- (void) hideCommentEditor {
    if (commentEditor && !commentEditor.hidden) {
        [[self nsWindow] tui_makeFirstResponder:self];
        [TUIView animateWithDuration:0.3 animations:^{
            smallPhotoImageView.frame = self.bounds;
        } completion:^(BOOL finished) {
            commentEditor.hidden = YES;
            [self setNeedsLayout];
        }];
    }
}

- (void) toggleCommentEditor {
    showingCommentEditor = !showingCommentEditor;
    showingCommentEditor ? [self showCommentEditor] : [self hideCommentEditor];
}


@end
