//
//  AHRow.h
//  Swift
//
//  Created by John Wright on 1/3/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TUIKit.h"
#import "TUILayout.h"
#import "AHGridTypes.h"

@class AHGrid;
@class AHGridCell;
@interface AHGridRow : TUIView <TUILayoutDataSource>

@property (nonatomic) NSInteger numberOfCells;
@property (nonatomic) AHGridLogicalSize logicalSize;
@property (nonatomic, strong) AHGridCell *xLargeCell;
@property (nonatomic) BOOL animating;
@property (nonatomic, weak) AHGrid *grid;
@property (nonatomic) NSUInteger index;
@property (nonatomic, strong) TUILayout *listView;
@property (nonatomic) BOOL selected;
@property (nonatomic, weak) id associatedObject;
@property (nonatomic, strong) NSString * titleString;
@property (nonatomic, strong) TUIView *headerView;

- (id)initWithFrame:(CGRect)frame andGrid:(AHGrid*) g;

@end