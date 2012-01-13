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
}
@synthesize profileImageWidth;
@synthesize profileImageHeight;
@synthesize userString;
@synthesize dateString;
@synthesize photoImageView;
@synthesize profileImageView;


- (CGRect) frameForPhotoImageView {
    CGRect frame = CGRectZero;
    if (photoImageView.image) {
        frame.size = photoImageView.image.size;
    } else {
        frame.size = CGSizeMake(720, 500);
    }
    // move the frame over to make room for the comments view
    frame.origin.y = self.contentSize.height - frame.size.height;
    frame.origin.x = roundf((self.bounds.size.width - frame.size.width)/2);
    return frame;
}

- (CGRect) frameForCommentsView {
    CGRect frame = self.bounds;
    frame.origin.x = NSMaxX([self frameForPhotoImageView]) + 5;
    return frame;
}

- (CGRect) frameForProfileImageView {
    CGRect frame = self.bounds;
    frame.origin.y = self.contentSize.height - profileImageHeight - 5;
    frame.origin.x = 5;
    frame.size = CGSizeMake(profileImageWidth, profileImageHeight);
    return frame;
}


-(id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        
        // Default value for sizing properties
        profileImageHeight = 50;
        profileImageWidth = 50;
        
        // Add subviews
        photoImageView = [[TUIImageView alloc] initWithFrame:[self frameForPhotoImageView]];
        photoImageView.clipsToBounds = YES;
        [self addSubview:photoImageView];
        commentsView = [[TUIView alloc] initWithFrame:[self frameForCommentsView]];
        [self addSubview:commentsView];
        profileImageView = [[TUIImageView alloc] initWithFrame:[self frameForProfileImageView]];
        [self addSubview:profileImageView];
        self.contentSize = frame.size;
    }
    return self;
}

-(void) layoutSubviews {
    CGRect b = self.bounds;
    if (photoImageView.image && b.size.height > 0) {
        self.contentSize = CGSizeMake(b.size.width, photoImageView.image.size.height);    
    } else {
        self.contentSize = b.size;    
    }
    photoImageView.frame = [self frameForPhotoImageView];
    profileImageView.frame = [self frameForProfileImageView];
    [super layoutSubviews];
}


@end
