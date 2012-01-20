//
//  AHCell.m
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import "AHGridCell.h"
#import "TUIKit.h"
#import "AHActionButton.h"
#import "TUIImageView+AHExtensions.h"

@implementation AHGridCell {
    TUITextRenderer *textRenderer;
}

@synthesize row;
@synthesize grid;
@synthesize index;
@synthesize selected;
@synthesize expanded;
@synthesize text;
@synthesize image;

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
        self.opaque = YES;
        textRenderer = [[TUITextRenderer alloc] init];
        self.textRenderers = [NSArray arrayWithObjects:textRenderer, nil];
	}
	return self;
}

# pragma mark - Cell Properties

-(void) prepareForReuse {
    self.image = nil;
    textRenderer.attributedString = nil;
    self.selected = NO;
    expanded = NO;
}

-(void) setText:(TUIAttributedString *)t {
    text = [t copy];
    textRenderer.attributedString = text;
    [self setNeedsDisplay];
}

-(void) layoutSubviews {
    if (self.selected) {
        self.layer.borderColor = [TUIColor yellowColor].CGColor;
        self.layer.borderWidth = 4;
    } else {
        self.layer.borderWidth = 0;
    }    
}

-(void) drawRect:(CGRect)rect {
    if (image) {
        [image drawInRect:self.bounds];
    }
    
    
    textRenderer.frame = self.bounds;
    if (textRenderer) {
        [textRenderer draw];
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
    NSString *chars = [event characters];
    unichar character = [chars characterAtIndex: 0];
    if ((character == 13 || character == 32) && !expanded) {
        [grid toggleSelectedRowExpanded];
        return YES;
    }
    return [grid performKeyAction:event];
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
            [grid toggleSelectedRowExpanded];
        }
    } else if ([event clickCount] == 1) {
        grid.selectedCell = self;
    }
	[super mouseDown:event]; // may make the text renderer first responder, so we want to do the selection before this	
}



@end
