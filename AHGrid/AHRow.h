//
//  AHRow.h
//  Crew
//
//  Created by John Wright on 1/3/12.
//  Copyright (c) 2012 AirHeart. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TUIKit.h"
#import "AHGrid.h"
#import "TUILayout.h"
#import "AHDetailView.h"

@class AHGrid;

@interface AHRow : TUIView <TUILayoutDataSource>

@property (nonatomic, strong) AHDetailView *detailView;
@property (nonatomic) BOOL animating;
@property (nonatomic, weak) AHGrid *grid;
@property (nonatomic) NSUInteger index;
@property (nonatomic, strong) TUILayout *listView;
@property (nonatomic) BOOL expanded;
@property (nonatomic, strong) NSMutableArray *cells;
@property (nonatomic) BOOL selected;


@property (nonatomic,strong) NSString * titleString;

@end
