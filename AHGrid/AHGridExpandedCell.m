//
//  AHDetailView.m
//  AHGrid
//
//  Created by John Wright on 1/12/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHGridExpandedCell.h"

@implementation AHGridExpandedCell {
    TUILabel *textLabel;
}

@synthesize photoImageView;


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
        photoImageView = [[TUIImageView alloc] initWithFrame:[self frameForPhotoImageView]];
        //photoImageView.layer.cornerRadius = 6;
        photoImageView.clipsToBounds = YES;
        photoImageView.layer.contents = kCAGravityResizeAspect;
        [self addSubview:photoImageView];
        
        
        self.contentSize = frame.size;
    }
    return self;
}

-(void) layoutSubviews {
    CGRect b = self.bounds;
    if (photoImageView.image && b.size.height > 0) {
        self.contentSize = CGSizeMake(b.size.width,[self photoImageSize].height);    
    } else {
        self.contentSize = b.size;    
    }
    photoImageView.frame = [self frameForPhotoImageView];
    [super layoutSubviews];
}



@end
