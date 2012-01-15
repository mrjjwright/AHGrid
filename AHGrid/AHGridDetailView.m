//
//  AHGridDetailView.m
//  AHGrid
//
//  Created by John Wright on 1/15/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "AHGridDetailView.h"

@implementation AHGridDetailView {
    TUILabel *userLabel;
}

@synthesize profileImageWidth;
@synthesize profileImageHeight;
@synthesize commentsTableView;
@synthesize profilePictureImageView;
@synthesize userString;
@synthesize dateString;

- (CGRect) frameForProfilePictureImageView {
    CGRect frame = self.bounds;
    frame.origin.y = NSMaxY(frame) - profileImageHeight - 5;
    frame.origin.x = 5;
    frame.size = CGSizeMake(profileImageWidth, profileImageHeight);
    return frame;
}

- (CGRect) frameForUserLabel {
    CGRect frame = [self frameForProfilePictureImageView];
    frame.origin.x = NSMaxX(frame) + 5;
    frame.origin.y += 20;
    frame.size.width = 250;
    frame.size.height = 25;
    return frame;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Default value for sizing properties
        profileImageHeight = 50;
        profileImageWidth = 50;
        
        profilePictureImageView = [[TUIImageView alloc] initWithFrame:[self frameForProfilePictureImageView]];
        [self addSubview:profilePictureImageView];
        
        userLabel = [[TUILabel alloc] initWithFrame:[self frameForUserLabel]];
        userLabel.font = [TUIFont boldSystemFontOfSize:11];
        userLabel.backgroundColor = [TUIColor clearColor];
        [self addSubview:userLabel];

    }
    
    return self;
}

-(void) layoutSubviews {
    profilePictureImageView.frame = [self frameForProfilePictureImageView];
    userLabel.frame = [self frameForUserLabel];
    [super layoutSubviews];
}

-(void) setUserString:(NSAttributedString *)u {
    userString = [u copy];
    userLabel.attributedString = u;
    [self setNeedsDisplay];
}


@end
