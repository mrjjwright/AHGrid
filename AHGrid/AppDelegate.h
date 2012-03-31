//
//  AppDelegate.h
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AHGrid.h"
#import "TUIKit.h"

#define IN_RUNNING_LION (NSClassFromString(@"NSPopover") != nil)

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet TUINSView *nsView;

@end
