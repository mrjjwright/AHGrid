//
//  AHScreen.h
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AHRow.h"
#import "AHCell.h"
#import "TUIKit.h"
#import "TUILayout.h"

@class AHRow;
@class AHCell;

@interface AHGrid : TUILayout  <TUILayoutDataSource>

@property (nonatomic, weak) AHRow *selectedRow;
@property (nonatomic, weak) AHCell *selectedCell;
@property (nonatomic) NSInteger selectedRowIndex;
@property (nonatomic) NSInteger selectedCellIndex;

@property (nonatomic) BOOL inConfigurationMode;

//-(IBAction)configure:(id)sender;
//- (void) saveConfiguration;
//-(void) removeRow:(AHRow*) row;
-(void) togglExpansionForRow:(NSInteger) rowIndex;
-(void) toggleConfigurationMode;

-(void)showCommentEditorForCell:(AHCell*) cell;

@end
