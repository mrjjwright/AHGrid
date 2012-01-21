//
//  TUIImageView+AHExtensions.m
//  AHGrid
//
//  Created by John Wright on 1/15/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "TUIImageView+AHExtensions.h"

@implementation TUIImageView (AHExtensions)


-(void) constrainToSize:(CGSize) constrainedSize {
    CGSize size = self.image.size;
    if (CGSizeEqualToSize(size, CGSizeZero)) return;
    CGFloat heightFactor = constrainedSize.height / size.height;
    CGFloat widthFactor = constrainedSize.width / size.width;
    CGFloat scaleFactor = 0.0;
    if (widthFactor < heightFactor) 
        scaleFactor = widthFactor;
    else
        scaleFactor = heightFactor;
    
    size.width  = self.image.size.width * scaleFactor;
    size.height = self.image.size.height * scaleFactor;
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

@end
