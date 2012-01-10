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
@property (nonatomic, strong) TUITextView *commentEditor;
@property (nonatomic) BOOL expanded;

// Sizing
@property (nonatomic) CGFloat padding;
@property (nonatomic) CGFloat profilePictureWidth;
@property (nonatomic) CGFloat profilePictureHeight;


// Text
@property (nonatomic, copy) NSAttributedString *userString;
@property (nonatomic, copy) NSAttributedString *dateString;
@property (nonatomic, copy) NSAttributedString *mainString;
@property (nonatomic, copy) NSAttributedString *likesString;
@property (nonatomic, copy) NSAttributedString *commentsString;
@property (nonatomic, copy) NSAttributedString *commentsTextInputPlaceholderString;

// Images
@property (nonatomic, strong) TUIImage *backgroundImage;
@property (nonatomic, strong) TUIImage *profileImage;
@property (nonatomic, strong) TUIImage *smallPhotoImage;
@property (nonatomic, strong) TUIImage *largePhotoImage;

// Action buttons
@property (nonatomic, strong) TUIImage *firstButtonImage;
@property (nonatomic, strong) TUIImage *secondButtonImage;
@property (nonatomic, strong) TUIImage *thirdButtonImage;

-(void) prepareForReuse;
-(void) showCommentEditor;
- (void) hideCommentEditor;
- (void) toggleCommentEditor;

@end
