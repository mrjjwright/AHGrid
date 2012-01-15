//
//  AHGridMasterView.h
//  AHGrid
//
//  Created by John Wright on 1/13/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TUIKit.h"

@class AHGridPickerView;
@class AHGridPickerHeaderView;
@class AHGridPickerCellView;

typedef void(^AHGridPickerHeaderBlock)(AHGridPickerView* picker, AHGridPickerHeaderView *cell, NSUInteger section);
typedef void(^AHGridPickerCellBlock)(AHGridPickerView* picker, AHGridPickerCellView *cell, TUIFastIndexPath *indexPath);
typedef NSInteger(^AHGridPickerNumberofRowsBlock)(AHGridPickerView* picker, NSUInteger section);


@interface AHGridPickerHeaderView : TUITableViewSectionHeader 

@property (nonatomic, strong) TUITextRenderer *labelRenderer;

@end

@interface AHGridPickerCellView : TUITableViewCell 

@property (nonatomic, copy) NSAttributedString *attributedString;

@end


@interface AHGridPickerView : NSView <TUITableViewDelegate, TUITableViewDataSource>

@property (nonatomic, strong) TUITableView *pickerTableView;
@property (nonatomic, copy) AHGridPickerHeaderBlock headerConfigureBlock; 
@property (nonatomic, copy) AHGridPickerCellBlock cellConfigureBlock;
@property (nonatomic, copy) AHGridPickerNumberofRowsBlock numberOfRowsBlock;
@property (nonatomic) NSInteger numberOfSections;
@property (nonatomic) NSInteger headerHeight;
@property (nonatomic) NSInteger cellHeight;

@end