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
#import "AHLabel.h"


typedef enum {
	AHGridCellTypePhoto,
    AHGridCellTypeText,
    AHGridCellTypeLink,
} AHGridCellType;

@class AHGrid;
@class AHRow;
@interface AHCell : TUIView

@property (nonatomic) AHGridCellType type;
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
@property (nonatomic, copy) TUIAttributedString *userString;
@property (nonatomic, copy) TUIAttributedString *dateString;
@property (nonatomic, copy) TUIAttributedString *mainString;
@property (nonatomic, copy) TUIAttributedString *linkURL;
@property (nonatomic, copy) TUIAttributedString *linkDescriptonString;
@property (nonatomic, copy) TUIAttributedString *likesString;
@property (nonatomic, copy) TUIAttributedString *commentsString;
@property (nonatomic, copy) TUIAttributedString *commentsTextInputPlaceholderString;

// Images
@property (nonatomic, strong) TUIImage *backgroundImage;
@property (nonatomic, strong) TUIImage *profileImage;
@property (nonatomic, strong) TUIImage *linkImage;
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
