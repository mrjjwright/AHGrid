//
//  AHCell.h
//  Crew
//
//  Created by John Wright on 12/10/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "AHGrid.h"
#import "TUIKit.h"

@class AHGrid;
@class AHRow;
@interface AHCell : TUIView

@property (nonatomic, strong) AHRow *row;
@property (nonatomic, weak) AHGrid *grid;
@property (nonatomic) NSUInteger index;
@property (nonatomic) BOOL selected;

// Text
@property (nonatomic, copy) NSAttributedString *userString;
@property (nonatomic, copy) NSAttributedString *dateString;
@property (nonatomic, copy) NSAttributedString *mainString;
@property (nonatomic, copy) NSAttributedString *likesString;
@property (nonatomic, copy) NSAttributedString *commentsString;
@property (nonatomic, copy) NSAttributedString *commentsTextInputPlaceholderString;

// Images
@property (nonatomic, strong) TUIImage *profileImage;
@property (nonatomic, strong) TUIImage *smallPhotoImage;
@property (nonatomic, strong) TUIImage *largePhotoImage;

// Action buttons
@property (nonatomic, strong) TUIImage *firstButtonImage;
@property (nonatomic, strong) TUIImage *secondButtonImage;
@property (nonatomic, strong) TUIImage *thirdButtonImage;


@end
