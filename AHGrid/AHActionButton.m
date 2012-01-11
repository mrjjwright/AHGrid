//
//  AHActionButton.m
//  AHGrid
//
//  Created by John Wright on 1/10/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHActionButton.h"

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