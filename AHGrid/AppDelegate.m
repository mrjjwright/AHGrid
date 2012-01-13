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
@synthesize searchField;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Lion full Screen support
    if (IN_RUNNING_LION) {
        [self.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    }
    
    // Add a search bar to the InAppStoreWindow
    self.window.titleBarHeight = 40.0;
    NSView *titleBarView = self.window.titleBarView;
    NSSize searchFieldSize = NSMakeSize(250.f, 32.f);
    NSRect searchFieldFrame = NSMakeRect(NSMaxX(titleBarView.bounds) - (searchFieldSize.width + 25.0f), NSMidY(titleBarView.bounds) - (searchFieldSize.height / 2.f), searchFieldSize.width, searchFieldSize.height);
    searchField = [[NSSearchField alloc] initWithFrame:searchFieldFrame];
    [titleBarView addSubview:searchField];
    

    TUINSView *nsView = [[TUINSView alloc] initWithFrame:[_window.contentView frame]];
    nsView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    grid = [[AHGrid alloc] initWithFrame:nsView.bounds];
    TUIView *containerView = [[TUIView alloc] initWithFrame:nsView.bounds];
    containerView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
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
   // [grid toggleConfigurationMode];
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
            if (grid.selectedCell && (grid.selectedRowIndex != -1) && grid.selectedRow.expanded && grid.detailView) {
                [grid.detailView scrollWheel:event];
            } else {
                [grid scrollWheel:event];
            }
            return NO;
            
        }
    }
    [grid scrollWheel:event];
    return NO;
}




@end
