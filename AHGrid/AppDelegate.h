//
//  AppDelegate.h
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AHGrid.h"
#import "INAppStoreWindow.h"

#define IN_RUNNING_LION (NSClassFromString(@"NSPopover") != nil)

@interface AppDelegate : NSObject <NSApplicationDelegate, TUIScrollingInterceptor>


@property (assign) IBOutlet INAppStoreWindow *window;
@property (nonatomic, strong) NSSearchField *searchField;

-(IBAction)toggleConfigurationMode:(id)sender;
-(IBAction)showCommentEditor:(id)sender;
-(IBAction)viewLarger:(id)sender;

@end
