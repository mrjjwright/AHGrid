//
//  AHGridDetailView.m
//  AHGrid
//
//  Created by John Wright on 1/15/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHGridDetailView.h"

@implementation AHGridDetailView {
    AHCell *_cell;
}

@synthesize grid;

-(CGRect) frameForCell {
    CGRect b = self.bounds;
    b.origin.y = NSMaxY(b) - 250;
    b.size.height = 250;
    return b;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [TUIColor colorWithWhite:0.9 alpha:1.0];
        _cell = [[AHCell alloc] initWithFrame:[self frameForCell]];
        [self addSubview:_cell];
    }
    return self;
}

-(void) layoutSubviews {
    _cell.frame = [self frameForCell];
    [super layoutSubviews];
}

-(void) update {
    [_cell prepareForReuse];
    grid.configureCellBlock(grid, grid.selectedCell.row, _cell, grid.selectedCell.index); 
}

 
@end
