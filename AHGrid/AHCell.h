//
//  AHCell.h
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "AHGrid.h"
#import "TUIKit.h"

@class AHGrid;
@class AHRow;
@interface AHCell : TUIView

@property (nonatomic, copy) NSAttributedString *attributedString;
@property (nonatomic, strong) AHRow *row;
@property (nonatomic, weak) AHGrid *grid;
@property (nonatomic) NSUInteger *index;
@property (nonatomic) BOOL selected;
@end
