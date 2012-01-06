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
}

@synthesize window = _window;
@synthesize grid;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    TUINSView *nsView = [[TUINSView alloc] initWithFrame:[window.contentView frame]];
    AHGrid *grid = [[AHGrid alloc] initWithFrame:nsView.bounds];
    nsView.rootView = grid;
    // Insert code here to initialize your application
    [grid reloadData];
}

-(IBAction)toggleConfigurationMode:(id)sender {
    [grid toggleConfigurationMode];
}

@end
