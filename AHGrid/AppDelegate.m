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
    NSMutableDictionary *gridModel;
    TUIFont *textFont;
}

@synthesize nsView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    TUIView *containerView = [[TUIView alloc] initWithFrame:nsView.bounds];
    containerView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    AHGrid *grid = [[AHGrid alloc] initWithFrame:nsView.bounds];
    [containerView addSubview:grid];
    grid.autoresizingMask = TUIViewAutoresizingFlexibleSize;
    nsView.rootView = containerView;
    nsView.scrollingInterceptor = (id<TUIScrollingInterceptor>) grid;    

    
    textFont = [TUIFont fontWithName:@"HelveticaNeue" size:12];
    
    // Setup model
    NSUInteger numberOfRows = 10;
    NSUInteger numExampleCellsPerRow = 20;
    
    //Setup an example model
    gridModel = [NSMutableDictionary dictionary];
    
    NSArray *pictures =[NSArray arrayWithObjects:@"jw_profile.jpg", @"henri.jpg",@"john_amy.jpg", @"wide.jpg", nil];
    NSArray *text =[NSArray arrayWithObjects:@".....finally watching Black Swan....damn, why didn't I keep taking that tap dancing class...LMAO..", @"SNOW DAY! I get to play with the ponies completely uninterrupted today! It would be swell if the temp would get above 28 degrees, though... Sure glad I stocked up on food and warming beverages yesterday. :)",@"\"Darkness cannot drive out darkness; only light can do that. Hate cannot drive out hate; only love can do that\" MLK Jr.", @"Application Done!", nil];
    
    for (NSUInteger i=0; i< numberOfRows; i++) {
        NSMutableArray *cellModels = [NSMutableArray array];
        for (NSUInteger j=0; j < numExampleCellsPerRow; j++ ) {
            NSMutableDictionary *cellModel = [NSMutableDictionary dictionary];
            [cellModel setObject:[pictures objectAtIndex:j % ([pictures count])] forKey:@"image"];
            [cellModel setObject:[text objectAtIndex:j % [text count]] forKey:@"text"];
            [cellModels addObject:cellModel];
        }
        [gridModel setObject:cellModels forKey:[NSNumber numberWithInteger:i]];
    }
    

    // Setup grid properties
    
    grid.configureRowBlock = ^(AHGrid* grid, AHGridRow *row, NSUInteger index) {
        row.titleString = [NSString stringWithFormat:@"Example Row %d", index];
    };
    
    grid.numberOfRowsBlock = ^(AHGrid *grid) {
        return numberOfRows;
    };
    
    grid.numberOfCellsBlock = ^(AHGrid *grid, AHGridRow *row) {
        return numExampleCellsPerRow;
    };
    
    // Configure cells
    grid.configureCellBlock = ^(AHGrid *grid, AHGridRow* row, AHGridCell *cell, NSUInteger index) {
        NSMutableArray *rows = [gridModel objectForKey:[NSNumber numberWithInteger:row.index]];
        NSMutableDictionary *cellModel = [rows objectAtIndex:index];
        cell.image = [TUIImage imageNamed:[cellModel objectForKey:@"image"] cache:YES];
        cell.backgroundColor = [TUIColor whiteColor];
        TUIAttributedString *textString = [TUIAttributedString stringWithString:[cellModel objectForKey:@"text"]];
        textString.font = textFont;
        cell.text = textString;
    };
    
    [grid reloadData];
    
}




@end
