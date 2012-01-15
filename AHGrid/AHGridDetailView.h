//
//  AHGridDetailView.h
//  AHGrid
//
//  Created by John Wright on 1/15/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TUIKit.h"

@interface AHGridDetailView : TUIView

@property (nonatomic) CGFloat profileImageHeight;
@property (nonatomic) CGFloat profileImageWidth;
@property (nonatomic, strong) TUIImageView *profilePictureImageView;
@property (nonatomic, strong) TUITableView *commentsTableView;
@property (nonatomic, copy ) NSAttributedString *userString;
@property (nonatomic, copy) NSString *dateString;

@end
