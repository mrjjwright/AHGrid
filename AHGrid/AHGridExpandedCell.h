//
//  AHDetailView.h
//  AHGrid
//
//  Created by John Wright on 1/12/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import "TUIKit.h"

@interface AHGridExpandedCell : TUIScrollView

@property (nonatomic) CGFloat profileImageHeight;
@property (nonatomic) CGFloat profileImageWidth;

@property (nonatomic, copy ) NSAttributedString *userString;
@property (nonatomic, copy) NSString *dateString;
@property (nonatomic, strong) TUIImageView *profileImageView;
@property (nonatomic, strong) TUIImageView *photoImageView;

@end