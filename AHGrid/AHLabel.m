//
//  AHLabel.m
//  AHGrid
//
//  Created by John Wright on 1/17/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHLabel.h"

@implementation AHLabel

-(void) mouseDown:(NSEvent *)theEvent {
    [self.superview mouseDown:theEvent];
}

-(void) mouseUp:(NSEvent *)theEvent {
    [self.superview mouseUp:theEvent];
}

@end
