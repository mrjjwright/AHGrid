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
    BOOL inspectNextScrollDirection;
}

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    TUINSView *nsView = [[TUINSView alloc] initWithFrame:[_window.contentView frame]];
    nsView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    grid = [[AHGrid alloc] initWithFrame:nsView.bounds];
    TUIView *containerView = [[TUIView alloc] initWithFrame:nsView.bounds];
    containerView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    [containerView addSubview:grid];
    nsView.rootView = containerView;
    grid.backgroundColor = [TUIColor colorWithPatternImage:[TUIImage imageNamed:@"bg.jpg"]];

    grid.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    nsView.scrollingInterceptor = self;
    // Insert code here to initialize your application
    [grid reloadData];
    [_window.contentView addSubview:nsView];
}

-(IBAction)toggleConfigurationMode:(id)sender {
    [grid toggleConfigurationMode];
}

-(IBAction)showCommentEditor:(id)sender {
    [grid showCommentEditorOnSelectedCell];
}


- (BOOL)shouldScrollWheel:(NSEvent *)event {
    
    if ([event phase] == NSEventPhaseBegan) {
        return YES;
    } else if ([event phase] == NSEventPhaseChanged){
        // Horizontal
        if (fabs([event scrollingDeltaX]) > fabs([event scrollingDeltaY])) {
            return YES;
            
        } else if (fabs([event scrollingDeltaX]) < fabs([event scrollingDeltaY])) { // Vertical
            [grid scrollWheel:event];
            return NO;
            
        }
    }
    [grid scrollWheel:event];
    return NO;
}




@end
