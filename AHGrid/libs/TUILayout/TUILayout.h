//
//  TUILayout.h
//  Swift
//
//  Created by John Wright on 11/13/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#define kTUILayoutViewHeight @"kTUILayoutViewHeight"
#define kTUILayoutViewWidth @"kTUILayoutViewWidth"

#import "TUIKit.h"

@interface NSString(TUICompare)

-(NSComparisonResult)compareNumberStrings:(NSString *)str;

@end

#define kTUILayoutAnimation @"TUILayoutAnimation"

@class TUILayout;
typedef void(^TUILayoutHandler)(TUILayout *layout);

typedef enum {
	TUILayoutScrollPositionNone,        
	TUILayoutScrollPositionTop,    
	TUILayoutScrollPositionMiddle,   
	TUILayoutScrollPositionBottom,
	TUILayoutScrollPositionToVisible, // currently the only supported arg
} TUILayoutScrollPosition;


// a callback handler to be used in various layout operations
typedef enum {
	TUILayoutVertical,
    TUILayoutHorizontal,
} TUILayoutType;


@protocol TUILayoutDataSource;

@interface TUILayout : TUIScrollView <TUIScrollViewDelegate>

@property (nonatomic, weak) NSObject<TUILayoutDataSource> *dataSource;

@property (nonatomic, weak) Class viewClass;
@property (nonatomic) TUILayoutType typeOfLayout;
@property (nonatomic) CGFloat spaceBetweenViews;
@property (nonatomic, readonly) NSInteger numberOfCells;
@property (nonatomic, strong) NSDate *reloadedDate;
@property (nonatomic, copy) TUILayoutHandler reloadHandler;
@property (nonatomic, readonly) NSArray *visibleViews;

#pragma mark - General

- (TUIView *)dequeueReusableView;
- (void)reloadData;
- (TUIView*) viewForIndex:(NSUInteger) index;
- (TUIView*) viewAtPoint:(CGPoint) point;
- (void)scrollToObjectAtIndex:(NSUInteger)index atScrollPosition:(TUILayoutScrollPosition)scrollPosition animated:(BOOL)animated;
- (CGRect) rectForObjectAtIndex:(NSUInteger) index;
-(TUIView*) replaceViewForObjectAtIndex:(NSUInteger) index withSize:(CGSize) size;

#pragma mark - Layout transactions
-(void) beginUpdates;
-(void) endUpdates;

#pragma mark - Resizing
- (void) resizeObjectAtIndexes:(NSArray*) objectIndexes sizes:(NSArray*) sizes animationBlock:(void (^)())animationBlock completion:(void (^)())completionBlock;
-(void) resizeObjectsToSize:(CGSize) size animationBlock:(void (^)())animationBlock completionBlock:(void (^)())completion; 
- (void) resizeObjectAtIndex:(NSUInteger) index toSize:(CGSize) size animationBlock:(void (^)())animationBlock  completionBlock:(void (^)())completionBlock;

#pragma mark - Adding and removing views
-(void) insertObjectAtIndex:(NSUInteger) index;
-(void) insertObjectAtIndex:(NSUInteger) index  animationBlock:(void (^)())animationBlock  completionBlock:(void (^)())completionBlock;
-(void) removeObjectsAtIndexes:(NSIndexSet *)indexes;

# pragma mark - Scrolling
-(BOOL) isVerticalScroll:(NSEvent*) event;

@end

//////////////////////////////////////////////////////////////
#pragma mark Protocol TUILayoutDataSource
//////////////////////////////////////////////////////////////

@protocol TUILayoutDataSource <NSObject>

@required
// Populating subview items 
- (NSUInteger)numberOfObjectsInLayout:(TUILayout *)layout;
- (CGSize)sizeOfObjectAtIndex:(NSUInteger)index;
- (TUIView *)layout:(TUILayout *)layout viewForObjectAtIndex:(NSInteger)index;

@optional
// Required to enable editing mode
- (void)layout:(TUILayout *)layout deleteObjectAtIndex:(NSInteger)index;

@end



