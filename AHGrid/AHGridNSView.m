//
//  AHGridNSView.m
//  AHGrid
//
//  Created by John Wright on 1/13/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHGridNSView.h"

@implementation AHGridNSView


@synthesize window;
@synthesize searchField;
@synthesize grid;
@synthesize gridInitDelegate;

-(void) awakeFromNib {
    
    self.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    
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
    searchField.autoresizingMask = TUIViewAutoresizingFlexibleLeftMargin;
    [titleBarView addSubview:searchField];
    
    
    grid = [[AHGrid alloc] initWithFrame:self.bounds];
    TUIView *containerView = [[TUIView alloc] initWithFrame:self.bounds];
    containerView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    [containerView addSubview:grid];
    self.rootView = containerView;
    grid.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0];
    
    grid.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    self.scrollingInterceptor = self;
    if (gridInitDelegate) {
        grid.initDelegate = gridInitDelegate;
    }
}


-(IBAction)toggleConfigurationMode:(id)sender {
    // [grid toggleConfigurationMode];
}

-(IBAction)showCommentEditor:(id)sender {
    [grid showCommentEditorOnSelectedCell];
}

-(IBAction)viewLarger:(id)sender {
    if (grid.selectedRowIndex != -1 && !grid.selectedRow.expanded) {
        [grid toggleSelectedRowExpanded];
    }
}


- (BOOL)shouldScrollWheel:(NSEvent *)event {
    
    if ([event phase] == NSEventPhaseBegan) {
        return YES;
    } else if ([event phase] == NSEventPhaseChanged){
        // Horizontal
        if (fabs([event scrollingDeltaX]) > fabs([event scrollingDeltaY])) {
            return YES;
            
        } else if (fabs([event scrollingDeltaX]) < fabs([event scrollingDeltaY])) { // Vertical
            if (grid.selectedCell && (grid.selectedRowIndex != -1) && grid.selectedRow.expanded && grid.selectedRow.detailView) {
                [grid.selectedRow.detailView scrollWheel:event];
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
