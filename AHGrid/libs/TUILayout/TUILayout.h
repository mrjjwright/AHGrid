//
//  TUILayout.h
//  Crew
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


// a callback handler to be used in various layout operations
typedef void(^TUILayoutHandler)();
typedef enum {
	TUILayoutVertical,
    TUILayoutHorizontal,
} TUILayoutType;


@protocol TUILayoutDataSource;

@interface TUILayout : TUIScrollView <TUIScrollViewDelegate>

@property (nonatomic, weak) NSObject<TUILayoutDataSource> *dataSource;

@property (nonatomic, weak) Class viewClass;
@property (nonatomic) TUILayoutType typeOfLayout;


#pragma mark - General

- (TUIView *)dequeueReusableView;
- (void)reloadData;

#pragma mark - Layout transactions
-(void) beginUpdates;
-(void) endUpdates;

#pragma mark - Resizing
- (void) resizeObjectsToSize:(CGSize) size animated:(BOOL) animated completion:(void (^)())completion;
-(void) resizeObjectAtIndex:(NSUInteger) index toSize:(CGSize) size  completion:(void (^)())completion;

#pragma mark - Adding and removing views
-(void) insertObjectAtIndex:(NSUInteger) index;
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



