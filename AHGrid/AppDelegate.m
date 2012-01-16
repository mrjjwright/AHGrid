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
    TUIFont *userStringFont;
    TUIFont *headerFont;
    TUIFont *pickerCellFont;
}

@synthesize gridNSView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
}

-(void) initGrid:(AHGrid *)grid {
    
    userStringFont = [TUIFont boldSystemFontOfSize:11];
    pickerCellFont = [TUIFont fontWithName:@"HelveticaNeue" size:12];
    headerFont = [TUIFont fontWithName:@"HelveticaNeue-Bold" size:12];

    // Setup model
    NSInteger numberOfRows = 10;
    NSInteger numExampleCellsPerRow = 20;
    
    //Setup an example model
    gridModel = [NSMutableDictionary dictionary];

    NSArray *pictures =[NSArray arrayWithObjects:@"jw_profile.jpg", @"girl_bubble.jpg",@"john_amy.jpg", @"wide.jpg", nil];
    NSArray *names =[NSArray arrayWithObjects:@"John Wright", @"Dana Brown",@"Heather Gault", @"Rob Capillo", nil];
    NSArray *text =[NSArray arrayWithObjects:@".....finally watching Black Swan....damn, why didn't I keep taking that tap dancing class...LMAO..", @"SNOW DAY! I get to play with the ponies completely uninterrupted today! It would be swell if the temp would get above 28 degrees, though... Sure glad I stocked up on food and warming beverages yesterday. :)",@"\"Darkness cannot drive out darkness; only light can do that. Hate cannot drive out hate; only love can do that\" MLK Jr.", @"Application Done!", nil];
    NSArray *linkDescriptions =[NSArray arrayWithObjects:@"Works in Progress…", @"Capitalism Magazine - What We Should Remember on Martin Luther King Day: Judge People by Their Chara",@"London Show Offers | Current Offers - On One Bikes", @"Superhero School: An Epicenter for Disruptive Innovation", nil];
    NSArray *links =[NSArray arrayWithObjects:@" http://www.facebook.com/l.php?u=http%3A%2F%2Fwp.me%2Fp11rIR-4X&h=3AQHfsf_PAQFk8SSMwg-YZsaxB-MZgmKS-3-5g9LJYCWmcA", @"http://www.facebook.com/l.php?u=http%3A%2F%2Fwww.capitalismmagazine.com%2Fculture%2Fhistory%2F2399-what-we-should-remember-on-martin-luther-king-day-judge-people-by-their-character-not-skin-color.html&h=_AQFfH398AQELPwd7JPEosNO18dVdBGWqLFjFy1KyuvquNg",@"http://www.on-one.co.uk/c/q/current_offers/london_show_offers", @"http://emergentbydesign.com/2011/11/09/superhero-school-an-epicenter-for-disruptive-innovation/", nil];
    NSArray *linkPics = [NSArray arrayWithObjects:@"wip.jp", @"mlk.jpg", @"bike_frame.jpg", @"school.png", nil];
    
    
    for (NSUInteger i=0; i< numberOfRows; i++) {
        NSMutableArray *cellModels = [NSMutableArray array];
        for (NSUInteger j=0; j < numExampleCellsPerRow; j++ ) {
            NSMutableDictionary *cellModel = [NSMutableDictionary dictionary];
            NSUInteger cellType = arc4random() % 3;
            switch (cellType) {
                case AHGridCellTypePhoto:
                    [cellModel setObject:[pictures objectAtIndex:j % ([pictures count])] forKey:@"photo"];
                    break;
                case AHGridCellTypeText:
                    [cellModel setObject:[text objectAtIndex:j % [text count]] forKey:@"mainText"];
                    break;
                case AHGridCellTypeLink:
                    [cellModel setObject:[linkDescriptions objectAtIndex:j % [linkDescriptions count]] forKey:@"linkDescription"];                    
                    [cellModel setObject:[links objectAtIndex:j % [links count]] forKey:@"linkURL"];                    
                    [cellModel setObject:[linkPics objectAtIndex:j % [linkPics count]] forKey:@"linkPic"]; 
                    break;
                default:
                    break;
            }
            [cellModel setObject:[NSNumber numberWithInteger:cellType] forKey:@"type"];
            [cellModel setObject:[names objectAtIndex:j % [names count]] forKey:@"user"];                    
            [cellModel setObject:[pictures objectAtIndex:j % [pictures count]] forKey:@"profilePic"];                    
            [cellModels addObject:cellModel];
        }
        [gridModel setObject:cellModels forKey:[NSNumber numberWithInteger:i]];
    }

    // Setup grid properties
    grid.numberOfRows = numberOfRows;
    grid.picker.cellHeight = 35;
    grid.picker.numberOfSections = 2;
    
    
    // Configure rows
    grid.rowConfigureBlock = ^(AHGrid* grid, AHRow *row, NSUInteger index) {
        row.titleString = [NSString stringWithFormat:@"Example Row %d", index];
    };
    
    grid.numberOfCellsBlock = ^(AHGrid *grid, AHRow *row) {
        return numExampleCellsPerRow;  
    };

    // Configure cells
    grid.cellConfigureBlock = ^(AHGrid *grid, AHRow* row, AHCell *cell, NSUInteger index) {
        NSMutableArray *rows = [gridModel objectForKey:[NSNumber numberWithInteger:row.index]];
        NSMutableDictionary *cellModel = [rows objectAtIndex:index];
        TUIAttributedString *userString = [TUIAttributedString stringWithString:[cellModel objectForKey:@"user"]];
        userString.font = userStringFont;
        cell.userString = userString;
        cell.profileImage = [TUIImage imageNamed:[cellModel objectForKey:@"profilePic"] cache:YES];
        cell.firstButtonImage = [TUIImage imageNamed:@"heart.png" cache:YES];
        cell.secondButtonImage = [TUIImage imageNamed:@"comment.png" cache:YES];
        
        AHGridCellType cellType = [[cellModel objectForKey:@"type"] unsignedIntValue];
        cell.type = cellType;
        switch (cellType) {
            case AHGridCellTypePhoto:
                cell.smallPhotoImage = [TUIImage imageNamed:[cellModel objectForKey:@"photo"] cache:YES];
                break;
            case AHGridCellTypeText: 
            {
                TUIAttributedString *mainString = [TUIAttributedString stringWithString:[cellModel objectForKey:@"mainText"]];
                mainString.font = pickerCellFont;
                cell.mainString = mainString;
                break;
            }
            case AHGridCellTypeLink:
                cell.linkDescriptonString = [TUIAttributedString stringWithString:[cellModel objectForKey:@"linkDescription"]];
                cell.linkImage = [TUIImage imageNamed:[cellModel objectForKey:@"linkPic"] cache:YES];
                break;
            default:
                break;
        }
    };
    
    // Configure the picker
    grid.picker.numberOfRowsBlock = ^(AHGridPickerView* picker, NSUInteger section) {
        return picker.grid.numberOfRows;
    };
    
    grid.picker.headerConfigureBlock = ^(AHGridPickerView* master, AHGridPickerHeaderView *headerView, NSUInteger section) {
        
        TUIAttributedString *title = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"Example Section %d", section]];
        title.color = [TUIColor blackColor];
        title.font = headerFont;
        headerView.labelRenderer.attributedString = title;
    };
    
    // Configure the picker cell
    grid.picker.cellConfigureBlock = ^(AHGridPickerView *masterView, AHGridPickerCellView *cell, NSUInteger section, NSUInteger row) {
        TUIAttributedString *s = [TUIAttributedString stringWithString:[NSString stringWithFormat:@"example cell %d", row]];
        s.color = [TUIColor blackColor];
        s.font = headerFont;
        [s setFont:pickerCellFont inRange:NSMakeRange(8, 4)]; // make the word "cell" bold
        cell.attributedString = s; 
    };
    
    grid.picker.reorderBlock = ^(AHGridPickerView* picker, NSUInteger fromSection, NSUInteger fromRow, NSUInteger toSection, NSUInteger toRow) {
       NSLog(@"Move dragged row: %lu => %lu", fromRow, toRow);  
    };
}

@end
