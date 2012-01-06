//
//  AppDelegate.m
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import "AppDelegate.h"
#import "AHGrid.h"

@implementation AppDelegate {
    AHGrid *grid;
}

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    TUINSView *nsView = [[TUINSView alloc] initWithFrame:[_window.contentView frame]];
    nsView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    grid = [[AHGrid alloc] initWithFrame:nsView.bounds];
    TUIView *containerView = [[TUIView alloc] initWithFrame:nsView.bounds];
    [containerView addSubview:grid];
    nsView.rootView = containerView;
    grid.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0];
    grid.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    nsView.scrollingInterceptor = self;
    // Insert code here to initialize your application
    [grid reloadData];
    [_window.contentView addSubview:nsView];
}

-(IBAction)toggleConfigurationMode:(id)sender {
    [grid toggleConfigurationMode];
}

-(BOOL) isVerticalScroll:(NSEvent*) event {
    
    // Get the amount of scrolling
    double dx = 0.0;
    double dy = 0.0;
    
    CGEventRef cgEvent = [event CGEvent];
    const int64_t isContinuous = CGEventGetIntegerValueField(cgEvent, kCGScrollWheelEventIsContinuous);
    
    if(isContinuous) {
        dx = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventPointDeltaAxis2);
        dy = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventPointDeltaAxis1);
    } else {
        CGEventSourceRef source = CGEventCreateSourceFromEvent(cgEvent);
        if(source) {
            const double pixelsPerLine = CGEventSourceGetPixelsPerLine(source);
            dx = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventFixedPtDeltaAxis2) * pixelsPerLine;
            dy = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventFixedPtDeltaAxis1) * pixelsPerLine;
            CFRelease(source);
        } else {
            NSLog(@"Critical: NULL source from CGEventCreateSourceFromEvent");
        }
    }
    
    if (fabsf(dx) > fabsf(dy)) return NO;
    return YES;
}

- (BOOL)shouldScrollWheel:(NSEvent *)event {
    if ([self isVerticalScroll:event]) {
        [grid scrollWheel:event];
        return NO;
    }
    return YES;
}

@end
