//
//  AHGridNSView.h
//  AHGrid
//
//  Created by John Wright on 1/13/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "TUIKit.h"
#import "INAppStoreWindow.h"
#import "AHGrid.h"
#import "AHGridPickerView.h"

@interface AHGridNSView : NSView <TUIScrollingInterceptor>
#define IN_RUNNING_LION (NSClassFromString(@"NSPopover") != nil)

@property (assign) IBOutlet id<AHGridInitDelegate> gridInitDelegate;
@property (assign) IBOutlet INAppStoreWindow *window;
@property (nonatomic, strong) NSSearchField *searchField;
@property (nonatomic, strong) AHGrid *grid;
@property (nonatomic, strong) AHGridPickerView *picker;

-(IBAction)toggleConfigurationMode:(id)sender;
-(IBAction)showCommentEditor:(id)sender;
-(IBAction)viewLarger:(id)sender;

@end
