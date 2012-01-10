//
//  AHCell.m
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import "AHCell.h"
#import "TUIKit.h"


@interface AHActionButton : TUIView 
@property (nonatomic, strong) NSString *imageName;
@property (nonatomic) BOOL selected;
@end

@implementation AHActionButton {
    BOOL animating;
}

@synthesize imageName;
@synthesize selected;

-(id) initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
        self.backgroundColor = [TUIColor clearColor];
    }
    return self;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}


- (void)mouseUp:(NSEvent *)event
{
	[super mouseUp:event];
    [self setNeedsDisplay];
}

-(void) mouseDown:(NSEvent *)theEvent  {
    
    [super mouseDown:theEvent];
    // rather than a simple -setNeedsDisplay, let's fade it back out
    animating = YES;
	[TUIView animateWithDuration:0.5 animations:^{
		[self redraw]; // -redraw forces a .contents update immediately based on drawRect, and it happens inside an animation block, so CoreAnimation gives us a cross-fade for free
	} completion:^(BOOL finished) {
        animating = NO;
        [self redraw];
    }];
    
}

-(void) drawRect:(CGRect)rect {
    CGRect b = self.bounds;
    CGContextRef ctx = TUIGraphicsGetCurrentContext();
    
    TUIImage *image = [TUIImage imageNamed:imageName cache:YES];
    
    CGRect imageRect = ABIntegralRectWithSizeCenteredInRect([image size], b);
    
    if(animating || selected) { // simple way to check if the mouse is currently down inside of 'v'.  See the other methods in TUINSView for more.
        
        // first draw a slight white emboss below
        CGContextSaveGState(ctx);
        CGContextClipToMask(ctx, CGRectOffset(imageRect, 0, -1), image.CGImage);
        CGContextSetRGBFillColor(ctx, 1, 1, 1, 0.5);
        CGContextFillRect(ctx, b);
        CGContextRestoreGState(ctx);
        
        // replace image with a dynamically generated fancy inset image
        // 1. use the image as a mask to draw a blue gradient
        // 2. generate an inner shadow image based on the mask, then overlay that on top
        image = [TUIImage imageWithSize:imageRect.size drawing:^(CGContextRef ctx) {
            CGRect r;
            r.origin = CGPointZero;
            r.size = imageRect.size;
            
            CGContextClipToMask(ctx, r, image.CGImage);
            CGContextDrawLinearGradientBetweenPoints(ctx, CGPointMake(0, r.size.height), (CGFloat[]){0,0,1,1}, CGPointZero, (CGFloat[]){0,0.6,1,1});
            TUIImage *innerShadow = [image innerShadowWithOffset:CGSizeMake(0, -1) radius:3.0 color:[TUIColor blackColor] backgroundColor:[TUIColor cyanColor]];
            CGContextSetBlendMode(ctx, kCGBlendModeOverlay);
            CGContextDrawImage(ctx, r, innerShadow.CGImage);
        }];
    }
    
    [image drawInRect:imageRect]; // draw 'image' (might be the regular one, or the dynamically generated one)
    
    // draw the index
    //        TUIAttributedString *s = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"%ld", v.tag]];
    //        [s ab_drawInRect:CGRectOffset(imageRect, imageRect.size.width, -15)];
}



@end


@implementation AHCell {
    TUITextRenderer *userTextRenderer;
    BOOL showingCommentEditor;
    
    TUIImageView *smallPhotoImageView;
    TUIImageView *profileImageView;
    
    AHActionButton *firstButton;
    AHActionButton *secondButton;
    
    BOOL animating;
}


@synthesize row;
@synthesize grid;
@synthesize index;
@synthesize selected;
@synthesize commentEditor;

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
		
        padding = 5;
        profilePictureWidth = 30;
        profilePictureHeight = 30;
        
        self.clipsToBounds = YES;
        self.layer.cornerRadius = 3;
        
        userTextRenderer = [[TUITextRenderer alloc] init];
        self.textRenderers = [NSArray arrayWithObjects:userTextRenderer, nil];
	}
	return self;
}

# pragma mark - Cell Properties

-(void) prepareForReuse {
    self.selected = NO;
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
        [self addSubview:profileImageView];
    } 
    
    if (!profileImage && profileImageView && profileImageView.superview) {
        [profileImageView removeFromSuperview];
    }
    
    if (profileImage && profileImageView && !profileImageView.superview) {
        [self addSubview:profileImageView];
    }
}

-(void) setFirstButtonImage:(TUIImage *)s {
    firstButtonImage = s;
    
    if ( firstButtonImage && !firstButton) {
        firstButton = [[AHActionButton alloc] initWithFrame:CGRectZero];
        firstButton.imageName = @"heart.png";
        [self addSubview:firstButton];
    } 
    
    if (!firstButtonImage && firstButton && firstButton.superview) {
        [firstButton removeFromSuperview];
    }
    
    if (firstButtonImage && firstButton && !firstButton.superview) {
        [self addSubview:firstButton];
    }
}

-(void) setSecondButtonImage:(TUIImage *)s {
    secondButtonImage = s;
    
    if ( secondButtonImage && !secondButton) {
        secondButton = [[AHActionButton alloc] initWithFrame:CGRectZero];
        secondButton.imageName = @"reply.png";
        secondButton.selected = YES;
        [self addSubview:secondButton];
    } 
    
    if (!secondButtonImage && secondButton && secondButton.superview) {
        [secondButton removeFromSuperview];
    }
    
    if (secondButtonImage && secondButton && !secondButton.superview) {
        [self addSubview:secondButton];
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
    
    CGRect profileImageFrame = CGRectMake(padding, b.size.height - padding - profilePictureHeight, profilePictureWidth, profilePictureHeight);
    
    CGFloat headerHeight = padding + padding + profilePictureHeight;
    
    CGRect smallPhotoFrame = b;
    smallPhotoFrame.size.height -= headerHeight + padding;
    smallPhotoFrame.size.width -= (padding * 2);
    smallPhotoFrame.origin.x = (b.size.width - smallPhotoFrame.size.width)/2;
    smallPhotoFrame.origin.y = padding;
    
    CGRect buttonsFrame = b;
    buttonsFrame.size.height = 30;
    buttonsFrame.size.width = 80;
    buttonsFrame.origin.x = NSMaxX(b) - 80;
    buttonsFrame.origin.y = NSMaxY(smallPhotoFrame) + padding;
    
    
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
    
	// text
	CGRect userStringRect = CGRectMake(padding + profilePictureWidth + padding, b.size.height - 35, 100, 25);
	userTextRenderer.frame = userStringRect; // set the frame so it knows where to draw itself
	[userTextRenderer draw];
}


#pragma mark - Selection

-(BOOL)acceptsFirstResponder {
    return TRUE;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)mouseDown:(NSEvent *)event
{
    grid.selectedCell = self;
	[super mouseDown:event]; // may make the text renderer first responder, so we want to do the selection before this	
}

- (void)mouseUp:(NSEvent *)event
{
	[super mouseUp:event];
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
        commentEditor.delegate =  (__strong id) self;
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
    if (character == 27 && commentEditor && showingCommentEditor) {
        [self hideCommentEditor];
        return YES;
    }
    return [super performKeyAction:event];
}




@end
