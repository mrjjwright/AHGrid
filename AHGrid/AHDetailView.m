//
//  AHDetailView.m
//  AHGrid
//
//  Created by John Wright on 1/12/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHDetailView.h"

@implementation AHDetailView {
    TUIView *commentsView;
    TUILabel *userLabel;
}
@synthesize profileImageWidth;
@synthesize profileImageHeight;
@synthesize userString;
@synthesize dateString;
@synthesize photoImageView;
@synthesize profileImageView;


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

- (CGRect) frameForCommentsView {
    CGRect frame = self.bounds;
    frame.origin.x = NSMaxX([self frameForPhotoImageView]) + 5;
    return frame;
}

- (CGRect) frameForProfileImageView {
    CGRect frame = self.visibleRect;
    frame.origin.y = self.contentSize.height - profileImageHeight - 5;
    frame.origin.x = 5;
    frame.size = CGSizeMake(profileImageWidth, profileImageHeight);
    return frame;
}

- (CGRect) frameForUserLabel {
    CGRect frame = [self frameForProfileImageView];
    frame.origin.x = NSMaxX(frame) + 5;
    frame.origin.y += 20;
    frame.size.width = 250;
    frame.size.height = 25;
    return frame;
}

-(id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
        // Default value for sizing properties
        profileImageHeight = 50;
        profileImageWidth = 50;
        
        // Add subviews
        photoImageView = [[TUIImageView alloc] initWithFrame:[self frameForPhotoImageView]];
        //photoImageView.layer.cornerRadius = 6;
        photoImageView.clipsToBounds = YES;
        photoImageView.layer.contents = kCAGravityResizeAspect;
        [self addSubview:photoImageView];
        
        commentsView = [[TUIView alloc] initWithFrame:[self frameForCommentsView]];
        [self addSubview:commentsView];
        profileImageView = [[TUIImageView alloc] initWithFrame:[self frameForProfileImageView]];
        [self addSubview:profileImageView];
        
        userLabel = [[TUILabel alloc] initWithFrame:[self frameForUserLabel]];
        userLabel.font = [TUIFont boldSystemFontOfSize:11];
        userLabel.backgroundColor = [TUIColor clearColor];
        [self addSubview:userLabel];
        
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
    profileImageView.frame = [self frameForProfileImageView];
    userLabel.frame = [self frameForUserLabel];
    [super layoutSubviews];
}

-(void) setUserString:(NSAttributedString *)u {
    userString = [u copy];
    userLabel.attributedString = u;
    [self setNeedsDisplay];
}


@end
