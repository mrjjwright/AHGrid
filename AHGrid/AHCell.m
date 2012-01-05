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
    TUIImageView *imageView;
}

@synthesize attributedString;
@synthesize row;
@synthesize grid;


- (id)initWithStyle:(TUITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		
        self.clipsToBounds = YES;
        textRenderer = [[TUITextRenderer alloc] init];
		
		/*
		 Add the text renderer to the view so events get routed to it properly.
		 Text selection, dictionary popup, etc should just work.
		 You can add more than one.
		 
		 The text renderer encapsulates an attributed string and a frame.
		 The attributed string in this case is set by setAttributedString:
		 which is configured by the table view delegate.  The frame needs to be 
		 set before it can be drawn, we do that in drawRect: below.
		 */
		self.textRenderers = [NSArray arrayWithObjects:textRenderer, nil];
        
        imageView = [[TUIImageView alloc] initWithImage:[TUIImage imageNamed:@"pet_plumes.jpg"]];
        imageView.layer.contentsGravity = kCAGravityResizeAspect;
        imageView.clipsToBounds = YES;
        [self addSubview:imageView];
	}
	return self;
}


//- (BOOL)performKeyAction:(NSEvent *)event{
//    [grid performKeyAction:event];
//}


-(void) layoutSubviews {
    imageView.frame = self.bounds;
}

- (NSAttributedString *)attributedString
{
	return textRenderer.attributedString;
}

- (void)setAttributedString:(NSAttributedString *)a
{
	attributedString = a;
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
        
    
        imageView.layer.cornerRadius = 6;
        imageView.layer.borderWidth = 2;
        imageView.layer.borderColor = [TUIColor  yellowColor].CGColor;
	} else {
		// light gray background
		CGContextSetRGBFillColor(ctx, .97, .97, .97, 1);
		CGContextFillRect(ctx, b);

        imageView.layer.cornerRadius = 0;
        imageView.layer.borderWidth = 0;

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
