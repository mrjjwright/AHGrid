//
//  AHCell.m
//  Swift
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import "AHGridCell.h"
#import "TUIKit.h"
#import "AHActionButton.h"
#import "TUIImageView+AHExtensions.h"
#import "AHGrid.h"

@implementation AHGridCell {
    TUITextRenderer *textRenderer;
    TUIImage *mediumThumbnail;
    TUIImage *smallThumbnail;
    TUIImage *largeThumbnail;
}

@synthesize row;
@synthesize grid;
@synthesize index;
@synthesize selected;
@synthesize expanded;
@synthesize text;
@synthesize image;
@synthesize logicalSize;
@synthesize resizing;

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
        self.opaque = YES;
        self.layer.cornerRadius = 10;
        self.clipsToBounds = YES;
        self.backgroundColor = [TUIColor whiteColor];
        textRenderer = [[TUITextRenderer alloc] init];
        self.textRenderers = [NSArray arrayWithObjects:textRenderer, nil];
	}
	return self;
}

# pragma mark - Cell Properties

-(void) prepareForReuse {
    self.image = nil;
    smallThumbnail = nil;
    mediumThumbnail =  nil;
    textRenderer.attributedString = nil;
    self.selected = NO;
    expanded = NO;
    logicalSize = AHGridLogicalSizeMedium;
}

-(void) setText:(TUIAttributedString *)t {
    text = [t copy];
    textRenderer.attributedString = text;
    [self setNeedsDisplay];
}

-(void) setSelected:(BOOL)s {
    selected = s;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

-(void) drawRect:(CGRect)rect {
    
    CGContextRef ctx = TUIGraphicsGetCurrentContext();
    CGRect b = self.bounds;
    
    // First draw the background color for proper blending    
    CGContextSetFillColorWithColor(ctx, self.backgroundColor.CGColor);
    CGContextFillRect(ctx, b);
    
    // Make sure somebody doesn't turn this off
    CGContextSetShouldSmoothFonts(ctx, TRUE);

    if (image) {
        TUIImage *imageToDraw = image;
        
        if (self.logicalSize == AHGridLogicalSizeSmall) {
            if (!smallThumbnail) {
                smallThumbnail = [image thumbnail:[grid cellSizeForLogicalSize:AHGridLogicalSizeSmall]];
            }
            imageToDraw = smallThumbnail;
        }
        
        if (self.logicalSize == AHGridLogicalSizeMedium) {
            if (!mediumThumbnail) {
                mediumThumbnail = [image thumbnail:[grid cellSizeForLogicalSize:AHGridLogicalSizeMedium]];
            }
            imageToDraw = mediumThumbnail;
        }
        
        if (self.logicalSize == AHGridLogicalSizeLarge) {
            if (!largeThumbnail) {
                largeThumbnail = [image thumbnail:[grid cellSizeForLogicalSize:AHGridLogicalSizeLarge]];
            }
            imageToDraw = largeThumbnail;
        }

        
        [imageToDraw drawInRect:self.bounds];
    }
    
    textRenderer.frame = self.bounds;
    if (textRenderer) {
        [textRenderer draw];
    }
    
    if(self.selected && self.logicalSize != AHGridLogicalSizeXLarge)
    {
        self.layer.borderColor = [TUIColor yellowColor].CGColor;
        self.layer.borderWidth = 3;
    } else {
        self.layer.borderWidth = 0;
    }

}


#pragma mark - Selection

-(BOOL)acceptsFirstResponder {
    return TRUE;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}


#pragma mark - Key Handling 

- (BOOL)performKeyAction:(NSEvent *)event {
    return [grid performKeyAction:event];
}

#pragma mark - Mouse handling

-(void) mouseUp:(NSEvent *)theEvent {
    [super mouseUp:theEvent];
}


- (void)mouseDown:(NSEvent *)event
{
    if ([event clickCount] == 2) {
        [grid toggleSelectedCellSize];
    } else if ([event clickCount] == 1) {
        grid.selectedCell = self;
    }
	[super mouseDown:event]; // may make the text renderer first responder, so we want to do the selection before this	
}

-(void) setLogicalSize:(AHGridLogicalSize)c {
    logicalSize = c;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}





@end
