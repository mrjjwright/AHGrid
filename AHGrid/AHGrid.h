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
#import "AHDetailView.h"

@class AHRow;
@class AHCell;

@interface AHGrid : TUILayout  <TUILayoutDataSource>


@property (nonatomic, weak) AHRow *selectedRow;
@property (nonatomic, weak) AHCell *selectedCell;
@property (nonatomic) NSInteger selectedRowIndex;
@property (nonatomic) NSInteger selectedCellIndex;
@property (nonatomic) NSInteger expandedRowIndex;
@property (nonatomic) BOOL inConfigurationMode;

//-(IBAction)configure:(id)sender;
//- (void) saveConfiguration;
//-(void) removeRow:(AHRow*) row;
//-(void) toggleConfigurationMode;
//

-(void) toggleSelectedRowExpanded;
-(void) showCommentEditorOnSelectedCell;

@end
