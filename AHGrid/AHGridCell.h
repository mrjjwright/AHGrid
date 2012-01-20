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
@class AHGridRow;

@interface AHGridCell : TUIView

@property (nonatomic, strong) AHGridRow *row;
@property (nonatomic, weak) AHGrid *grid;
@property (nonatomic) NSUInteger index;
@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL expanded;

@property (nonatomic, strong) TUIImage *image;
@property (nonatomic, copy) TUIAttributedString *text;


-(void) prepareForReuse;

@end
