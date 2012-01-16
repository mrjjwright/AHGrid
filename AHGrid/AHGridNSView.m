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
    NSView *nsViewContainer;
    NSSplitView *splitView;
    NSInteger numDrawRects;
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
    nsViewContainer = [[NSView alloc] initWithFrame:[self frameForGrid]];
    CGRect nsViewFrame = CGRectMake(0, 0, nsViewContainer.bounds.size.width, nsViewContainer.bounds.size.height);
    nsView = [[TUINSView alloc] initWithFrame:nsViewFrame];
    [nsViewContainer addSubview:nsView];
    
    // Setup the grid
    grid = [[AHGrid alloc] initWithFrame:nsViewFrame];
    TUIView *containerView = [[TUIView alloc] initWithFrame:nsViewFrame];
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
    
    // Init the detail views
    detailView = [[AHGridDetailView alloc] initWithFrame:self.bounds];
    detailViewContainer = [[TUINSView alloc] initWithFrame:self.bounds];
    detailViewContainer.rootView = detailView;
    grid.detailView = detailView;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleDetailView:) name:kAHGridWillToggleExpansionOfRow object:nil];
    
    splitView = [[NSSplitView alloc]initWithFrame:self.bounds];
    splitView.delegate = self;
    [splitView setVertical:YES];
    [splitView addSubview:picker];
    [splitView addSubview:nsViewContainer];
    [self addSubview:splitView];
    splitView.dividerStyle = NSSplitViewDividerStyleThin;
    [splitView adjustSubviews];
}

-(void) resizeSubviewsWithOldSize:(NSSize)oldSize {
    picker.frame = [self frameForPicker];
    nsViewContainer.frame = [self frameForGrid];
    CGRect nsViewFrame = CGRectMake(0, 0, nsViewContainer.bounds.size.width, nsViewContainer.bounds.size.height);
    nsView.frame = nsViewFrame;
    splitView.frame = self.bounds;
    [splitView adjustSubviews];
    grid.bounds = nsViewFrame;
    [grid setNeedsLayout];
}


- (CGFloat)splitView:(NSSplitView *)sender
constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
    if (offset == 0) {
        return kPickerWidth;
    }
    return self.bounds.size.width - kPickerWidth;
}


- (CGFloat)splitView:(NSSplitView *)sender
constrainMaxCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
    if (offset == 0) {
        return kPickerWidth;
    }
    return self.bounds.size.width - kPickerWidth;
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

-(void) toggleDetailView:(NSNotification*) notification {
    if (!grid.selectedRow.expanded) {
        [splitView replaceSubview:picker with:detailViewContainer];
        detailViewContainer.frame = [self frameForPicker];        
    } else {
        [splitView replaceSubview:detailViewContainer with:picker];
        picker.frame = [self frameForPicker];
    }
}


@end
