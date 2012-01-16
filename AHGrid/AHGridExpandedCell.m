//
//  AHDetailView.m
//  AHGrid
//
//  Created by John Wright on 1/12/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHGridExpandedCell.h"

@implementation AHGridExpandedCell {
    TUILabel *mainLabel;
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

-(CGRect) frameForMainLabel {
    CGRect b = self.bounds;
    b.size.width *= 0.8;
    return ABRectCenteredInRect(b, self.bounds);
}



-(id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
        // Add subviews
        photoImageView = [[TUIImageView alloc] initWithFrame:[self frameForPhotoImageView]];
        //photoImageView.layer.cornerRadius = 6;
        photoImageView.clipsToBounds = YES;
        photoImageView.layer.contents = kCAGravityResizeAspect;
        [self addSubview:photoImageView];
        
        // Main Label
        mainLabel = [[TUILabel alloc] initWithFrame:[self frameForMainLabel]];
        mainLabel.backgroundColor = [TUIColor clearColor];
        self.contentSize = frame.size;
    }
    return self;
}

-(void) layoutSubviews {
    mainLabel.frame = [self frameForMainLabel];
    photoImageView.frame = [self frameForPhotoImageView];
    [super layoutSubviews];
}


-(void) setCellToExpand:(AHCell *)cell {
    photoImageView.image = nil;
    [photoImageView removeFromSuperview];
    [mainLabel removeFromSuperview];
    switch (cell.type) {
        case AHGridCellTypePhoto:
        {   
            [self addSubview:photoImageView];
            photoImageView.image = cell.smallPhotoImage;
            photoImageView.frame = [self frameForPhotoImageView];
            self.contentSize = CGSizeMake(self.bounds.size.width,[self photoImageSize].height); 
            break;
        }    
        case AHGridCellTypeText:
        {
            [self addSubview:mainLabel];
            mainLabel.attributedString = cell.mainString;
            mainLabel.frame = [self frameForMainLabel];
            self.contentSize = CGSizeMake(self.bounds.size.width, mainLabel.frame.size.height); 
        }
        case AHGridCellTypeLink:
        {
            
        }
        default:
            break;
    }
    [self setNeedsLayout];
}

@end
