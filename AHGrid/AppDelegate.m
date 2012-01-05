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
    grid.superview.wantsLayer = YES;
    grid.wantsLayer = YES;
    // Insert code here to initialize your application
    [grid reloadData];
}

-(IBAction)toggleConfigurationMode:(id)sender {
    [grid toggleConfigurationMode];
}

@end
