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
    TUIFont *userStringFont;
    TUIFont *headerFont;
    TUIFont *pickerCellFont;
}

@synthesize gridNSView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
}

-(void) initGrid:(AHGrid *)grid {
    userStringFont = [TUIFont boldSystemFontOfSize:11];
    headerFont = [TUIFont fontWithName:@"HelveticaNeue" size:15];
    pickerCellFont = [TUIFont fontWithName:@"HelveticaNeue-Bold" size:15];

    NSArray *pictures =[NSArray arrayWithObjects:@"jw_profile.jpg", @"girl_bubble.jpg",@"john_amy.jpg", @"wide.jpg", nil];
    
    // Configure grid visual style
    grid.numberOfRows = 10;
    
    // Configure rows
    grid.rowConfigureBlock = ^(AHGrid* grid, AHRow *row, NSUInteger index) {
        row.titleString = [NSString stringWithFormat:@"Example Row %d", index];
    };

    // Configure cells
    grid.cellConfigureBlock = ^(AHGrid *grid, AHRow* row, AHCell *cell, NSUInteger index) {        
        cell.profileImage = [TUIImage imageNamed:[pictures objectAtIndex:index % ([pictures count])] cache:YES];
        cell.smallPhotoImage = [TUIImage imageNamed:[pictures objectAtIndex:index % ([pictures count])]   cache:YES];
        cell.firstButtonImage = [TUIImage imageNamed:@"heart.png"  cache:YES];
        cell.secondButtonImage = [TUIImage imageNamed:@"reply.png" cache:YES];
        TUIAttributedString *userString = [TUIAttributedString stringWithString:@"John Wright"];
        userString.font = userStringFont;
        cell.userString = userString;
    };
    
    // Configure the picker header
    grid.picker.headerConfigureBlock = ^(AHGridPickerView* master, AHGridPickerHeaderView *headerView, NSUInteger section) {
        
        TUIAttributedString *title = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"Example Section %d", section]];
        title.color = [TUIColor blackColor];
        title.font = headerFont;
        headerView.labelRenderer.attributedString = title;
    };
    
    // Configure the picker cell
    grid.picker.cellConfigureBlock = ^(AHGridPickerView *masterView, AHGridPickerCellView *cell, TUIFastIndexPath *indexPath) {
        TUIAttributedString *s = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"example cell %d", indexPath.row]];
        s.color = [TUIColor blackColor];
        s.font = headerFont;
        [s setFont:pickerCellFont inRange:NSMakeRange(8, 4)]; // make the word "cell" bold
        cell.attributedString = s; 
    };
}

@end
