//
//  AHCell.h
//  Swift
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "TUIKit.h"
#import "AHGrid.h"


@interface AHGridCell : TUIView

@property (nonatomic, strong) AHGridRow *row;
@property (nonatomic, weak) AHGrid *grid;
@property (nonatomic) NSUInteger index;
@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL expanded;
@property (nonatomic) AHGridLogicalSize logicalSize;
@property (nonatomic) BOOL resizing;

@property (nonatomic, strong) TUIImage *image;
@property (nonatomic, copy) TUIAttributedString *text;


-(void) prepareForReuse;

// Animations and actions needed for size changes

@end
