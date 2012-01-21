//
//  AHDetailView.m
//  AHGrid
//
//  Created by John Wright on 1/12/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHGridExpandedCell.h"

@implementation AHGridExpandedCell {
    TUIImageView *photoImageView;
}

-(void) prepareForReuse {
    photoImageView.image = nil;
}

- (CGSize) photoImageSize {
    CGSize size = photoImageView.image.size;
    if (self.bounds.size.height > 400) {
        size.height = MIN(self.bounds.size.height, size.height);
    }
    CGFloat heightFactor = size.height / photoImageView.image.size.height;
    CGFloat widthFactor = size.width / photoImageView.image.size.width;
    CGFloat scaleFactor = 0.0;
    if (widthFactor < heightFactor) 
        scaleFactor = widthFactor;
    else
        scaleFactor = heightFactor;
    
    size.width  = photoImageView.image.size.width * scaleFactor;
    size.height = photoImageView.image.size.height * scaleFactor;
    return size;
}

- (CGRect) frameForPhotoImageView {
    CGRect frame = CGRectZero;
    if (photoImageView.image) {
        frame.size = [self photoImageSize];
    } else {
        frame.size = CGSizeMake(720, 500);
    }
    // move the frame over to make room for the comments view
    frame.origin.y = self.contentSize.height - frame.size.height -5;
    frame.origin.x = roundf((self.bounds.size.width - frame.size.width)/2);
    return frame;
}


-(id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Add subviews
    }
    return self;
}

-(void) layoutSubviews {
    photoImageView.frame = [self frameForPhotoImageView];
    [super layoutSubviews];
}


// this is only called if there is no AHGridConfigureExpandedCellBlock on the grid
-(void) setCellToExpand:(AHGridCell *)cell { 
    if (cell.image && !photoImageView) {
        photoImageView = [[TUIImageView alloc] initWithFrame:[self frameForPhotoImageView]];
        //photoImageView.layer.cornerRadius = 6;
        photoImageView.clipsToBounds = YES;
        photoImageView.layer.contents = kCAGravityResizeAspect;
        [self addSubview:photoImageView];
    }
    photoImageView.image = nil;
    [photoImageView removeFromSuperview];
    [self addSubview:photoImageView];
    photoImageView.image = cell.image;
    photoImageView.frame = [self frameForPhotoImageView];
    CGFloat contentHeight = photoImageView.image ? [self photoImageSize].height : self.bounds.size.height;
    self.contentSize = CGSizeMake(self.bounds.size.width,contentHeight); 
    [self setNeedsLayout];
}

@end
