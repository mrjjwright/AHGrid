//
//  AHGridNSView.m
//  AHGrid
//
//  Created by John Wright on 1/13/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHGridNSView.h"


#define kPickerWidth 250

@implementation AHGridNSView {
    TUINSView *nsView;
    TUINSView *detailViewContainer;
}


@synthesize window;
@synthesize searchField;
@synthesize grid;
@synthesize gridInitDelegate;
@synthesize picker;
@synthesize detailView;

-(NSRect) frameForGrid {
    NSRect b = self.bounds;
    b.size.width -= kPickerWidth;
    b.origin.x += kPickerWidth;
    return b;
}

-(NSRect) frameForPicker {
    NSRect b = self.bounds;
    b.size.width = kPickerWidth;
    return b;    
}


-(void) awakeFromNib {
    
    self.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    
    // Lion full Screen support
    if (IN_RUNNING_LION) {
        [self.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    }
    
    // The container TUI NSView
    nsView = [[TUINSView alloc] initWithFrame:[self frameForGrid]];
    
    // Setup the grid
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
    
    // setup the picker
    picker = [[AHGridPickerView alloc] initWithFrame:[self frameForPicker]];
    grid.picker = picker;
    picker.grid = grid;
    [self addSubview:nsView];
    [self addSubview:picker];
    
    // Init the detail views
    detailView = [[AHGridDetailView alloc] initWithFrame:self.bounds];
    detailViewContainer = [[TUINSView alloc] initWithFrame:self.bounds];
    detailViewContainer.rootView = detailView;
    grid.detailView = detailView;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDetailView:) name:@"AHGridToggledSelectedRow" object:nil];
}

-(void) drawRect:(NSRect)dirtyRect {
    picker.frame = [self frameForPicker];
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
            if (grid.selectedCell && (grid.selectedRowIndex != -1) && grid.selectedRow.expanded && grid.selectedRow.expandedCell) {
                [grid.selectedRow.expandedCell scrollWheel:event];
            } else {
                [grid scrollWheel:event];
            }
            return NO;
            
        }
    }
    [grid scrollWheel:event];
    return NO;
}

-(void) showDetailView:(NSNotification*) notification {
    [picker removeFromSuperview];
    [self addSubview:detailViewContainer];
    detailViewContainer.frame = picker.bounds;
}


@end
