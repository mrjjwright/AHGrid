//
//  AHGridNSView.m
//  AHGrid
//
//  Created by John Wright on 1/13/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHGridNSView.h"


#define kMasterViewWidth 225

@implementation AHGridNSView {
    TUINSView *nsView;
}


@synthesize window;
@synthesize searchField;
@synthesize grid;
@synthesize gridInitDelegate;
@synthesize masterView;

-(NSRect) frameForGrid {
    NSRect b = self.bounds;
    b.size.width -= kMasterViewWidth;
    b.origin.x += kMasterViewWidth;
    return b;
}

-(NSRect) frameForMasterView {
    NSRect b = self.bounds;
    b.size.width = kMasterViewWidth;
    return b;    
}


-(void) awakeFromNib {
    
    self.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    
    // Lion full Screen support
    if (IN_RUNNING_LION) {
        [self.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    }
    
    nsView = [[TUINSView alloc] initWithFrame:[self frameForGrid]];
    [self addSubview:nsView];
    
    grid = [[AHGrid alloc] initWithFrame:nsView.bounds];
    TUIView *containerView = [[TUIView alloc] initWithFrame:nsView.bounds];
    containerView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    [containerView addSubview:grid];
    nsView.rootView = containerView;
    grid.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0];
    grid.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    nsView.scrollingInterceptor = self;
    if (gridInitDelegate) {
        grid.initDelegate = gridInitDelegate;
    }
    
    //Initialize Master View
    masterView = [[AHGridMasterView alloc] initWithFrame:[self frameForMasterView]];
    [self addSubview:masterView];
}

-(void) drawRect:(NSRect)dirtyRect {
    masterView.frame = [self frameForMasterView];
    nsView.frame = [self frameForGrid];
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
