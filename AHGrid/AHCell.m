//
//  AHCell.m
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import "AHCell.h"
#import "TUIKit.h"
#import "AHActionButton.h"


@implementation AHCell {
    TUITextRenderer *userTextRenderer;
    BOOL showingCommentEditor;
    
    TUIImageView *smallPhotoImageView;
    TUIImageView *profileImageView;
    
    AHActionButton *firstButton;
    AHActionButton *secondButton;
    
    BOOL animating;
    TUIView *headerView;
    
    NSInteger trackingCounter;
}

@synthesize row;
@synthesize grid;
@synthesize index;
@synthesize selected;
@synthesize commentEditor;
@synthesize expanded;

// Sizing
@synthesize padding;
@synthesize profilePictureWidth;
@synthesize profilePictureHeight;


// Text
@synthesize userString;
@synthesize dateString;
@synthesize mainString;
@synthesize likesString;
@synthesize commentsString;
@synthesize commentsTextInputPlaceholderString;

// Images
@synthesize backgroundImage;
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
		trackingCounter = 0;
        padding = 5;
        profilePictureWidth = 30;
        profilePictureHeight = 30;
        
        
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 3;
        
        userTextRenderer = [[TUITextRenderer alloc] init];
        self.textRenderers = [NSArray arrayWithObjects:userTextRenderer, nil];
        headerView = [[TUIView alloc] initWithFrame:CGRectZero];
        headerView.opaque = YES;
        __weak TUITextRenderer *weakUserTextRender = userTextRenderer;
        __weak AHCell *weakSelf = self;
        headerView.drawRect   = ^(TUIView *v, CGRect rect) {
            CGRect b = v.bounds;
            // text
            TUIImage *image = [TUIImage imageNamed:@"bg.jpg" cache:YES];
            [image drawInRect:rect];
            CGRect userStringRect = CGRectMake(weakSelf.padding + weakSelf.profilePictureWidth + weakSelf.padding, b.size.height - 35, 100, 25);
            weakUserTextRender.frame = userStringRect; // set the frame so it knows where to draw itself
            [weakUserTextRender draw];
        };
        headerView.backgroundColor = [TUIColor colorWithPatternImage:[TUIImage imageNamed:@"bg.jpg"]];
        [self addSubview:headerView];
	}
	return self;
}

# pragma mark - Cell Properties

-(void) prepareForReuse {
    self.selected = NO;
    expanded = NO;
    showingCommentEditor = NO;
    if (commentEditor && commentEditor.text && commentEditor.text.length > 0) commentEditor.text = @"";
}

-(void) setSmallPhotoImage:(TUIImage *)s {
    smallPhotoImage = s;
    
    if ( smallPhotoImage && !smallPhotoImageView) {
        smallPhotoImageView = [[TUIImageView alloc] initWithImage:smallPhotoImage];
        smallPhotoImageView.layer.cornerRadius = 3;
        smallPhotoImageView.layer.contentsGravity = kCAGravityResizeAspect;
        smallPhotoImageView.clipsToBounds = YES;
        [self addSubview:smallPhotoImageView];
        [self sendSubviewToBack:smallPhotoImageView];
    } 
    
    if (!smallPhotoImage && smallPhotoImageView && smallPhotoImageView.superview) {
        [smallPhotoImageView removeFromSuperview];
    }
    
    if (smallPhotoImage && smallPhotoImageView && !smallPhotoImageView.superview) {
        [self addSubview:smallPhotoImageView];
    }
}

-(void) setProfileImage:(TUIImage *)s {
    profileImage = s;
    
    if ( profileImage && !smallPhotoImageView) {
        profileImageView = [[TUIImageView alloc] initWithImage:profileImage];
        profileImageView.layer.cornerRadius = 3;
        profileImageView.layer.contentsGravity = kCAGravityResizeAspect;
        profileImageView.clipsToBounds = YES;
        [headerView addSubview:profileImageView];
    } 
    
    if (!profileImage && profileImageView && profileImageView.superview) {
        [profileImageView removeFromSuperview];
    }
    
    if (profileImage && profileImageView && !profileImageView.superview) {
        [headerView addSubview:profileImageView];
    }
}

-(void) setFirstButtonImage:(TUIImage *)s {
    firstButtonImage = s;
    
    if ( firstButtonImage && !firstButton) {
        firstButton = [[AHActionButton alloc] initWithFrame:CGRectZero];
        firstButton.imageName = @"heart.png";
        firstButton.hidden = YES;
        [headerView addSubview:firstButton];
    } 
    
    if (!firstButtonImage && firstButton && firstButton.superview) {
        [firstButton removeFromSuperview];
    }
    
    if (firstButtonImage && firstButton && !firstButton.superview) {
        [headerView addSubview:firstButton];
    }
}

-(void) setSecondButtonImage:(TUIImage *)s {
    secondButtonImage = s;
    
    if ( secondButtonImage && !secondButton) {
        secondButton = [[AHActionButton alloc] initWithFrame:CGRectZero];
        secondButton.imageName = @"reply.png";
        secondButton.hidden = YES;
        [headerView addSubview:secondButton];
    } 
    
    if (!secondButtonImage && secondButton && secondButton.superview) {
        [secondButton removeFromSuperview];
    }
    
    if (secondButtonImage && secondButton && !secondButton.superview) {
        [headerView addSubview:secondButton];
    }
}


-(void) setUserString:(NSAttributedString *)u  {
    userTextRenderer.attributedString = [u copy];
}

#pragma mark - Layout

-(CGRect) commentEditorFrame {
    CGRect b = self.bounds;
    CGRect frame = b;
    frame.size.height = 40;
    return frame;
}


-(void) layoutSubviews {
    
    CGRect b = self.bounds;
    
    // Default position for all items
    CGRect commentEditorFrame = b;
    
    CGFloat headerHeight = padding + padding + profilePictureHeight;
    CGRect headerFrame = CGRectMake(0, b.size.height - headerHeight, b.size.width, headerHeight);
    
    CGRect profileImageFrame = CGRectMake(padding, padding, profilePictureWidth, profilePictureHeight);
    
    CGRect smallPhotoFrame = b;
    smallPhotoFrame.size.height -= headerHeight + padding;
    smallPhotoFrame.size.width -= (padding * 2);
    smallPhotoFrame.origin.x = (b.size.width - smallPhotoFrame.size.width)/2;
    smallPhotoFrame.origin.y = padding;
    
    CGRect buttonsFrame = b;
    buttonsFrame.size.height = 30;
    buttonsFrame.size.width = 80;
    buttonsFrame.origin.x = NSMaxX(b) - 80;
    buttonsFrame.origin.y = padding;
    
    CGRect firstButtonFrame = buttonsFrame;
    firstButtonFrame.size.width = 30;
    CGRect secondButtonFrame = firstButtonFrame;
    secondButtonFrame.origin.x += 30;
    
    if (showingCommentEditor) {
        commentEditorFrame = [self commentEditorFrame];
        // Move everything else up
        smallPhotoFrame.origin.y = NSMaxY(commentEditorFrame);
        commentEditor.frame = commentEditorFrame;
    }
    
    if(self.selected) {
        self.layer.borderWidth = 3;
        self.layer.borderColor = [TUIColor  yellowColor].CGColor;
	} else {
        self.layer.borderWidth = 0;
	}
    
    headerView.frame = headerFrame;
    profileImageView.frame = profileImageFrame;
    firstButton.frame = firstButtonFrame;
    secondButton.frame = secondButtonFrame;
    smallPhotoImageView.frame = smallPhotoFrame;
}


- (void)drawRect:(CGRect)rect
{
	CGRect b = self.bounds;
	
    if (backgroundImage) {
        [backgroundImage drawInRect:b];
    }
    
    // light gray background
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(ctx, .97, .97, .97, 1);
    CGContextFillRect(ctx, b);    
}


#pragma mark - Selection

-(BOOL)acceptsFirstResponder {
    return TRUE;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}



-(NSMenu*) menuForEvent:(NSEvent *)event {
    NSMenu *menu = [[NSMenu alloc] init];
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Comment",nil) action:@selector(toggleCommentEditor) keyEquivalent:@"j"];
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
        [self hideCommentEditor];
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
    if (animating) return;
    
    if (!self.selected) {
        grid.selectedCell = self;
    }
    showingCommentEditor = YES;
    if (!commentEditor) {
        
        commentEditor = [[TUITextView alloc] initWithFrame:[self commentEditorFrame]];
        commentEditor.backgroundColor = [TUIColor colorWithWhite:0.95 alpha:1];
        commentEditor.layer.shadowColor = [TUIColor blackColor].CGColor;
        commentEditor.layer.shadowOffset = CGSizeMake(2, 2);
        commentEditor.delegate =   (id) self;
        commentEditor.font = [TUIFont systemFontOfSize:11];
        commentEditor.contentInset = TUIEdgeInsetsMake(2, 6, 2, 6);
        commentEditor.hidden = YES;
        commentEditor.spellCheckingEnabled = YES;
        [self addSubview:commentEditor];
        commentEditor.editable = YES;
        [self sendSubviewToBack:commentEditor];
    }
    
    commentEditor.hidden = NO;
    animating = YES;
    [TUIView animateWithDuration:0.3 animations:^{
        CGRect frame = smallPhotoImageView.frame;
        frame.origin.y = NSMaxY(commentEditor.frame);
        smallPhotoImageView.frame = frame;
        [self.nsWindow makeFirstResponderIfNotAlreadyInResponderChain:commentEditor];
    } completion:^(BOOL finished) {
        animating = NO;
        [self setNeedsLayout];
    }];
}

- (void) hideCommentEditor {
    if (animating) return;
    showingCommentEditor = NO;
    animating = YES;
    if (commentEditor && !commentEditor.hidden) {
        [[self nsWindow] tui_makeFirstResponder:self];
        [TUIView animateWithDuration:0.3 animations:^{
            smallPhotoImageView.frame = self.bounds;
        } completion:^(BOOL finished) {
            animating = NO;
            commentEditor.hidden = YES;
            [self setNeedsLayout];
        }];
    }
}

- (void) toggleCommentEditor {
    showingCommentEditor = !showingCommentEditor;
    showingCommentEditor ? [self showCommentEditor] : [self hideCommentEditor];
}

#pragma mark - Key Handling 

- (BOOL)performKeyAction:(NSEvent *)event {
    NSString *chars = [event characters];
    unichar character = [chars characterAtIndex: 0];
    NSLog(@"%d", character);
    if (character == 27 && commentEditor && showingCommentEditor) {
        [self hideCommentEditor];
        return YES;
    } else if (character == 13 && !expanded) {
        [row toggleExpanded];
        return YES;
    }
    return [super performKeyAction:event];
}

#pragma mark - Mouse handling

-(void) mouseUp:(NSEvent *)theEvent {
    [super mouseUp:theEvent];
}

- (void)mouseDown:(NSEvent *)event
{
    if ([event clickCount] == 2) {
        if (!row.expanded || (row.expanded && grid.selectedCell == self && self.expanded)) {
            grid.selectedCell = self;
            [row toggleExpanded];
        }
    } else if ([event clickCount] == 1) {
        grid.selectedCell = self;
    }
	[super mouseDown:event]; // may make the text renderer first responder, so we want to do the selection before this	
}

-(void) mouseEntered:(NSEvent *)theEvent {
    [TUIView animateWithDuration:0.3 animations:^{
        firstButton.hidden = NO;
        secondButton.hidden = NO;
    }];
    trackingCounter++;
}


- (void) mouseEntered:(NSEvent *)event onSubview:(TUIView *)subview {
    [TUIView animateWithDuration:0.3 animations:^{
        firstButton.hidden = NO;
        secondButton.hidden = NO;
    }];
    trackingCounter++;
}

-(void) mouseExited:(NSEvent *)event fromSubview:(TUIView *)subview {
    trackingCounter--;
    if (trackingCounter == 0) {
        [TUIView animateWithDuration:0.3 animations:^{
            firstButton.hidden = YES;
            secondButton.hidden = YES;
        }];
    }
}

- (void) mouseExited:(NSEvent *)theEvent {
    trackingCounter--;
    if (trackingCounter == 0) {
        [TUIView animateWithDuration:0.3 animations:^{
            firstButton.hidden = YES;
            secondButton.hidden = YES;
        }];
    }
}


@end
