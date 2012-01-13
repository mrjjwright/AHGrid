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
}

@synthesize gridNSView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
}

-(void) initGrid:(AHGrid *)grid {
    userStringFont = [TUIFont boldSystemFontOfSize:11];

    NSArray *pictures =[NSArray arrayWithObjects:@"jw_profile.jpg", @"girl_bubble.jpg",@"john_amy.jpg", @"wide.jpg", nil];
    grid.rowConfigureBlock = ^(AHGrid* grid, AHRow *row, NSUInteger index) {
        row.titleString = [NSString stringWithFormat:@"Example Row %d", index];
        return row; 
    };
    grid.numberOfRows = 10;
    
    grid.cellConfigureBlock = ^(AHGrid *grid, AHRow* row, AHCell *cell, NSUInteger index) {        
        cell.profileImage = [TUIImage imageNamed:[pictures objectAtIndex:index % ([pictures count])] cache:YES];
        cell.smallPhotoImage = [TUIImage imageNamed:[pictures objectAtIndex:index % ([pictures count])]   cache:YES];
        cell.firstButtonImage = [TUIImage imageNamed:@"heart.png"  cache:YES];
        cell.secondButtonImage = [TUIImage imageNamed:@"reply.png" cache:YES];
        TUIAttributedString *userString = [TUIAttributedString stringWithString:@"John Wright"];
        userString.font = userStringFont;
        cell.userString = userString;
        
        return cell;
    };
}

@end
