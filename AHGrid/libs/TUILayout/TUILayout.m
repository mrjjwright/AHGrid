//
//  TUILayout.m
//  Swift
//
//  Created by John Wright on 11/13/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

// ARC is compatible with iOS 4.0 upwards, but you need at least Xcode 4.2 with Clang LLVM 3.0 to compile it.

#if !__has_feature(objc_arc)
#error This project must be compiled with ARC (Xcode 4.2+ with LLVM 3.0 and above)
#endif

#import "TUILayout.h"
#import "AHGrid.h"

@implementation NSString(TUICompare)

-(NSComparisonResult)compareNumberStrings:(NSString *)str {
    NSNumber * me = [NSNumber numberWithInt:[self intValue]];
    NSNumber * you = [NSNumber numberWithInt:[str intValue]];
    
    return [you compare:me];
}

@end

#define kTUILayoutDefaultAnimationDuration 0.5
#define kTUILayoutMarkedForRemoval @"markedForRemoval"

@interface TUILayoutObject : NSObject

@property (nonatomic) CGSize size;
@property (nonatomic) CGRect oldFrame;
@property (nonatomic, readonly) CGRect calculatedFrame;
@property (nonatomic) BOOL markedForInsertion;
@property (nonatomic) BOOL markedForRemoval;
@property (nonatomic) BOOL markedForUpdate;
@property (nonatomic, strong) CAAnimation *animation;
@property (nonatomic) CGFloat x;
@property (nonatomic) CGFloat y;
@property (nonatomic) NSInteger index;
@property (nonatomic, strong) NSString *indexString;

@end

@implementation TUILayoutObject

@synthesize oldFrame;
@synthesize size;
@synthesize x;
@synthesize y;
@synthesize animation;
@synthesize markedForInsertion;
@synthesize markedForRemoval;
@synthesize markedForUpdate;
@synthesize index;
@synthesize indexString;

-(CGRect) calculatedFrame {
    return CGRectMake(self.x, self.y, self.size.width, self.size.height);
}

@end

@class TUILayoutTransaction;

@interface TUILayout()

@property (nonatomic, strong) NSMutableDictionary *objectViewsMap;
@property (nonatomic, readonly) TUILayoutTransaction *updatingTransaction;
@property (nonatomic, strong) TUILayoutTransaction *executingTransaction;
@property (nonatomic, strong) NSMutableArray *objects;

-(void) executeNextLayoutTransaction;
- (void) enqueueReusableView:(TUIView *)view;
- (TUIView *)createView;

@end

typedef enum {
	TUILayoutTransactionStateNormal,
	TUILayoutTransactionStatePrelayout,
	TUILayoutTransactionStateAnimating,
	TUILayoutTransactionStateDoneAnimating,
} TUILayoutTransactionState;


@interface TUILayoutTransaction : NSObject

@property (nonatomic, weak) TUILayout *layout;
@property (nonatomic, copy) TUILayoutHandler animationBlock;
@property (nonatomic) BOOL shouldAnimate;
@property (nonatomic) CGSize contentSize;
@property (nonatomic) CGRect rectForLayout;
@property (nonatomic) TUILayoutTransactionState state;
@property (nonatomic, weak) TUILayoutObject *scrollToObject;
@property (nonatomic, strong) NSMutableArray *changeList;
@property (nonatomic) CGSize objectSize;
@property (nonatomic) BOOL calculated;
@property (nonatomic) CGFloat animationDuration;

-(void) applyLayout;
-(void) addCompletionBlock:(TUILayoutHandler) block;

-(void) calculate;
-(void) calculateContentSize;
-(void) calculateContentOffset;
-(void) calculateContentOffsetIfScrolledRectToVisible:(CGRect) rect;
-(void) calculateRectForLayout;
-(void) calculateObjectOffsets;
-(void) calculateObjectOffsetsVertical;
-(void) calculateObjectOffsetsHorizontal;

-(NSMutableArray *)objectIndexesInRect:(CGRect)rect;
-(NSString*) indexKeyForObject:(TUILayoutObject*) object;

-(void) layoutObjects;
-(void) addSubviews;
-(TUIView*) addSubviewForObject:(TUILayoutObject*) object atIndex:(NSString*) objectIndex;
-(void) rebaseForInsertionsAndRemovals;
-(void) processChangeList;
-(void) processInsertions;
-(void) cleanup;
-(void) moveObjectsAfterPoint:(CGPoint) point byIndexAmount:(NSInteger) indexAmount;
@end

@implementation TUILayoutTransaction {
    NSMutableArray *completionBlocks;
    CGPoint contentOffset;
    BOOL calculatedContentSize;
    NSMutableArray *objectIndexesToBringIntoView;
    BOOL shouldChangeContentOffset;
    BOOL preLayoutPass;
    CGRect lastBounds;
}

@synthesize layout;
@synthesize animationBlock;
@synthesize shouldAnimate;
@synthesize contentSize;
@synthesize rectForLayout;
@synthesize state;
@synthesize scrollToObject;
@synthesize changeList;
@synthesize objectSize;
@synthesize calculated;
@synthesize animationDuration;

#pragma mark - Getters and Setters

-(void) addCompletionBlock:(TUILayoutHandler)block {
    if (block == nil) return;
    if (!completionBlocks) {
        completionBlocks = [NSMutableArray array];
    }
    [completionBlocks addObject:[block copy]];
}

-(NSMutableArray*) changeList {
    if (!changeList) {
        changeList = [NSMutableArray array];
    }
    return changeList;
}

#pragma mark - Layout


-(void) applyLayout {
    
    CGRect bounds = layout.bounds;
    if  ([layout.superview isKindOfClass:[AHGridRow class]]) {
        NSLog(@"AHGridRow");
    }
    
    if  ([layout isKindOfClass:[AHGrid class]]) {
        NSLog(@"AHGrid");
    }

    if (!calculated || !CGSizeEqualToSize(bounds.size, lastBounds.size)) {
        [self calculateContentSize];
        [self calculateContentOffset];
        [self processChangeList];
        [self calculateObjectOffsets]; 
        [self processInsertions];
        calculated = YES;
    }
    lastBounds = bounds;
    
        
    if (self.shouldAnimate && state != TUILayoutTransactionStateDoneAnimating) {
        if (state == TUILayoutTransactionStateNormal) {
            state = TUILayoutTransactionStatePrelayout;
            self.shouldAnimate = NO;
            [CATransaction begin];
            __weak NSMutableArray *weakCompletionBlocks = completionBlocks;
            __weak TUILayoutTransaction *weakSelf = self;
            [CATransaction setCompletionBlock:^{
                
                // In this CATransaction we do the actual animation
                weakSelf.state = TUILayoutTransactionStateAnimating;
                [CATransaction begin];                
                [CATransaction setCompletionBlock:^{
                    weakSelf.state = TUILayoutTransactionStateNormal;
                    shouldAnimate = NO;
                    for (TUILayoutHandler block in weakCompletionBlocks) block(weakSelf.layout);
                }];
                                
                // Recalculate the offsets
                [weakSelf calculateObjectOffsets];
                
                weakSelf.layout.contentSize = weakSelf.contentSize;
                CGFloat duration = weakSelf.animationDuration > 0 ? weakSelf.animationDuration :  kTUILayoutDefaultAnimationDuration;
                [TUIView animateWithDuration:duration animations:^{
                    if (weakSelf.scrollToObject) {
                        // scroll object to top
                        CGRect r = weakSelf.scrollToObject.calculatedFrame;
                        r.origin.y -= (weakSelf.rectForLayout.size.height - r.size.height);
                        r.size.height += (weakSelf.rectForLayout.size.height - r.size.height);
                        [weakSelf.layout scrollRectToVisible:r animated:NO];
                    } else  if (shouldChangeContentOffset) {
                        weakSelf.layout.contentOffset = contentOffset;
                    }
                    [weakSelf layoutObjects];
                    if  ([layout.superview isKindOfClass:[AHGridRow class]]) {
                        NSLog(@"AHGridRow");
                    }
                    
                    if  ([layout isKindOfClass:[AHGrid class]]) {
                        NSLog(@"AHGrid");
                    }

                    if (weakSelf.animationBlock) weakSelf.animationBlock(weakSelf.layout);
                }];
                [CATransaction commit];
            }];

                    
            // Process insertions and removals
            [weakSelf rebaseForInsertionsAndRemovals];

            // Bring in objects needed for the animation using their old positions
            // Update the model
            [self calculateRectForLayout];
            objectIndexesToBringIntoView = [self objectIndexesInRect:rectForLayout];
            [self addSubviews];
            
            [CATransaction commit];
        } 
    } else {
        layout.contentSize = contentSize;
        [self calculateRectForLayout];
        objectIndexesToBringIntoView = [self objectIndexesInRect:rectForLayout];
        [self addSubviews];
        [self layoutObjects];
        [self cleanup];        
    }
    
}

- (void) addSubviews {
    
    // Process objects that need to be scrolled into view
    NSMutableArray *objectIndexesToAdd = [objectIndexesToBringIntoView mutableCopy];
	[objectIndexesToAdd removeObjectsInArray:[layout.objectViewsMap allKeys]];
    
    // Remove any objects marked for insertion or deletion
    // These will be handled separately
    if (shouldAnimate && [changeList count] > 0) {
        for (TUILayoutObject * object in changeList) {
            if (object.markedForInsertion || object.markedForRemoval) {
                NSString *objectIndex = [NSString stringWithFormat:@"%d", object.index];;
                [objectIndexesToAdd removeObject:objectIndex];
            }
        }
    }
    
	for (NSString *objectIndex in objectIndexesToAdd) {
        TUILayoutObject *object = [layout.objects objectAtIndex:[objectIndex intValue]]; 
        [self addSubviewForObject:object atIndex:objectIndex];
    }
}

-(TUIView*) addSubviewForObject:(TUILayoutObject*) object atIndex:(NSString*) objectIndex {
    
    if([layout.objectViewsMap objectForKey:objectIndex]  && !object.markedForInsertion) {
        NSLog(@"!!! Warning: already have a view in place for index %@\n\n\n", object);
    } else {
        NSInteger index = [objectIndex integerValue];
        TUIView * v = [layout.dataSource layout:layout viewForObjectAtIndex:index];
        v.tag = index;
        if (state != TUILayoutTransactionStateNormal && !CGRectIsNull(object.oldFrame)) {
            if  ([layout.superview isKindOfClass:[AHGridRow class]]  && object.index == 3) {
                NSLog(@"AHGridRow");
            }
            v.frame = object.oldFrame;
        } else {
            v.frame = object.calculatedFrame;
        }
        [v removeAllAnimations];
        // Only add subviews if they are on screen
        if (!v.superview) {
            if (object.markedForInsertion) {
                // fade new views in
                [layout addSubview:v];
                [layout sendSubviewToBack:v];
                CABasicAnimation *fadeAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
                [fadeAnim setDuration:kTUILayoutDefaultAnimationDuration];
                [fadeAnim setFromValue:[NSNumber numberWithFloat:0.0f]];
                [fadeAnim setToValue:[NSNumber numberWithFloat:1.0f]];
                [v.layer addAnimation:fadeAnim forKey:kTUILayoutAnimation];
                v.frame = object.calculatedFrame;
            } else {
                [layout addSubview:v];
            }
        }
        [layout.objectViewsMap setObject:v forKey:objectIndex];
        [v layoutSubviews]; 
        return v;
    }
    return nil;
}

-(void) rebaseForInsertionsAndRemovals {
    if (shouldAnimate && [changeList count] > 0) {
        for (TUILayoutObject *object in changeList) {
            if (object.markedForInsertion || object.markedForRemoval) {
                NSInteger moveAmount =  object.markedForInsertion ? 1 : -1;
                [self moveObjectsAfterPoint:object.calculatedFrame.origin byIndexAmount:moveAmount];
            }
        }
    }
}



-(void) processChangeList {
    if ([changeList count] > 0) {
        for (TUILayoutObject *object in changeList) {
            if (object.markedForUpdate) {
                [layout.objects replaceObjectAtIndex:object.index withObject:object];
            } else if (object.markedForRemoval) {
                [layout.objects removeObjectAtIndex:object.index];
            } else {
                [layout.objects insertObject:object atIndex:object.index];
                object.index = [layout.objects indexOfObject:object];
                object.indexString = [NSString stringWithFormat:@"%ld", object.index];
            }
        }
    }
}

-(void) processInsertions {
    if ([changeList count] > 0) {
        for (TUILayoutObject *object in changeList) {
            if (object.markedForInsertion) {
                [self moveObjectsAfterPoint:object.calculatedFrame.origin byIndexAmount:-1];
                [self addSubviewForObject:object atIndex:object.indexString];
            }
        }
        [changeList removeAllObjects];
    }
    
}


-(void) layoutObjects {
    __weak TUILayoutTransaction *weakSelf = self;
    [layout.objectViewsMap enumerateKeysAndObjectsUsingBlock:^(NSString* key, TUIView *v, BOOL *stop) {
        NSInteger index = [key integerValue];
        TUILayoutObject *object = [weakSelf.layout.objects objectAtIndex:index];
        
        if (object.animation) {
            [v.layer addAnimation:object.animation forKey:kTUILayoutAnimation];
            object.animation = nil;
        }
        
        if  ([layout.superview isKindOfClass:[AHGridRow class]]  && object.index == 3) {
            NSLog(@"AHGridRow");
        }

        object.oldFrame = v.frame; 
        if (!CGRectEqualToRect(object.calculatedFrame, object.oldFrame)) 
        {
            v.frame = object.calculatedFrame;
        } 
        
        if (object.markedForInsertion) {
            // newly inserted views shouldn't be moved in
            [v.layer removeAnimationForKey:@"position"];
            [v.layer removeAnimationForKey:@"bounds"];
            // send new views to back so other views can animate over it
            [weakSelf.layout sendSubviewToBack:v];
            object.markedForInsertion = NO;
        } 
        
        [v layoutSubviews];
    }];
    
}

// Remove views marked for removal or no longer on screen
-(void) cleanup {
    __weak TUILayout *weakLayout = self.layout;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *indexesToRemove = [[NSMutableArray alloc] init];
        [weakLayout.objectViewsMap enumerateKeysAndObjectsUsingBlock:^(NSString* key, TUIView *v, BOOL *stop) {
            // check if this view is still on screen
            if (!CGRectIntersectsRect(rectForLayout, v.frame)) {
                [indexesToRemove addObject:key];   
            }
        }];
        
        for (NSString* index in indexesToRemove) {
            TUIView *v = [weakLayout.objectViewsMap objectForKey:index];
            [weakLayout enqueueReusableView:v];
            [v removeFromSuperview];
            [weakLayout.objectViewsMap removeObjectForKey:index];
        }
    });
}

// Shift the index of objects to views on the screen by a positive or negative amount
-(void) moveObjectsAfterPoint:(CGPoint) point byIndexAmount:(NSInteger) indexAmount  {
    if ([layout.objectViewsMap count]) {
        NSMutableDictionary *newObjectViewsMap = [[NSMutableDictionary alloc] init];
        [layout.objectViewsMap enumerateKeysAndObjectsUsingBlock:^(NSString* key, TUIView *v, BOOL *stop) {
            if (v.frame.origin.y < point.y) {
                NSInteger index = [key intValue] + indexAmount;
                NSString *newIndexKey = [NSString stringWithFormat:@"%d", index];
                [newObjectViewsMap setValue:v forKey:newIndexKey];
                [v setTag:index];
            } else {
                [newObjectViewsMap setValue:v forKey:key];
            }
        }];        
        // Replace map  
        [layout.objectViewsMap setDictionary:newObjectViewsMap];
    }
}

#pragma mark - Calculations

-(void) calculate {
    if (!calculated) {
        calculated = YES;
    }
    [self calculateRectForLayout];
}

-(void) calculateContentOffset {
    if (shouldAnimate && scrollToObject) {
        // scroll object to top
        CGRect visible = layout.visibleRect;
        CGRect rect = scrollToObject.calculatedFrame;
        rect.origin.y -= (visible.size.height - rect.size.height);
        rect.size.height += (visible.size.height - rect.size.height); 
        [self calculateContentOffsetIfScrolledRectToVisible:rect];
    }
    else if (shouldAnimate) {
        shouldChangeContentOffset = YES;
        contentOffset = layout.contentOffset;
        if (!CGSizeEqualToSize(layout.contentSize, CGSizeZero)) {
            contentOffset.x *= contentSize.width / layout.contentSize.width;
            contentOffset.y *= contentSize.height / layout.contentSize.height;
        }
    } else {
        shouldChangeContentOffset = NO;
    }
}

-(void) calculateContentOffsetIfScrolledRectToVisible:(CGRect) rect {
    CGRect visible = layout.visibleRect;
    if (layout.typeOfLayout == TUILayoutHorizontal) {
        if (rect.origin.x + rect.size.width > visible.origin.x + visible.size.width) {
            //Scroll right, have rect be flush with right of visible view
            contentOffset = CGPointMake(-rect.origin.x + visible.size.width - rect.size.width, 0);
        } else if (rect.origin.x  < visible.origin.x) {
            // Scroll left, rect flush with left of leftmost visible view
            contentOffset = CGPointMake(-rect.origin.x, 0);
        }
    } else if (rect.origin.y < visible.origin.y) {
        // scroll down, have rect be flush with bottom of visible view
        contentOffset = CGPointMake(0, -rect.origin.y);
    } else if (rect.origin.y + rect.size.height > visible.origin.y + visible.size.height) {
        // scroll up, rect to be flush with top of view
        contentOffset = CGPointMake(0, -rect.origin.y + visible.size.height - rect.size.height);
    }
    
}

-(void) calculateRectForLayout {
    if (!shouldAnimate) {
        // Update to the visibleRect of the scrollView
        rectForLayout = layout.visibleRect;
    } else {
        // Calculate the new visble rect
        rectForLayout = layout.bounds;
        CGPoint offset = contentOffset;
        offset.x = -offset.x;
        offset.y = -offset.y;
        rectForLayout.origin = offset;
    }
}

-(void) calculateContentSize {
    __block CGFloat calculatedHeight = 0;
    __block CGFloat calculatedWidth = 0;
    __block TUILayoutType layoutType = layout.typeOfLayout;
    __weak TUILayout *weakLayout = self.layout;
    NSInteger idx = 0;
    for (TUILayoutObject *object in layout.objects) {
        object.size = [weakLayout.dataSource sizeOfObjectAtIndex:idx];
        if (layoutType == TUILayoutVertical) {
            calculatedWidth = weakLayout.bounds.size.width;
            calculatedHeight += object.size.height + weakLayout.spaceBetweenViews;
        } else {
            calculatedHeight = weakLayout.bounds.size.height;
            calculatedWidth += object.size.width + weakLayout.spaceBetweenViews;
            
        }
        idx +=1;
    }
    // final contentSize is modified by the amount of insertions, removals, and resizes as reflected
    // in contentWidthChange and contentHeightChange
    for (TUILayoutObject *object in changeList) {
        if (object.markedForUpdate) {
            TUILayoutObject *oldObject = [layout.objects objectAtIndex:object.index];
            calculatedHeight += object.size.height - oldObject.size.height; 
            calculatedWidth += object.size.width - oldObject.size.width; 
        }
        if (object.markedForInsertion) {
            calculatedHeight += object.size.height;
            calculatedWidth += object.size.width;
        }
        if (object.markedForRemoval) {
            calculatedHeight -= object.size.height;
            calculatedWidth -= object.size.width;
        }
    }
    self.contentSize = CGSizeMake(calculatedWidth, calculatedHeight);
}

- (void) calculateObjectOffsets {
    (layout.typeOfLayout == TUILayoutVertical) ? [self calculateObjectOffsetsVertical] : [self calculateObjectOffsetsHorizontal];
}

- (void) calculateObjectOffsetsVertical {
    CGFloat offset = self.contentSize.height;  
    for (TUILayoutObject *object in layout.objects) {
        object.oldFrame = object.calculatedFrame;        
        offset -= object.size.height + layout.spaceBetweenViews;
        object.y = offset + layout.spaceBetweenViews;
    }
}

- (void) calculateObjectOffsetsHorizontal {
    CGFloat i = 0;  
    CGFloat offset = 0;
    for (TUILayoutObject *object in layout.objects) {
        if (i==0) {
            offset += layout.spaceBetweenViews;
        }
        
        object.x = offset;
        i += 1;
        offset += object.size.width + layout.spaceBetweenViews;
    }
}


#pragma mark - Geometry

- (NSMutableArray *)objectIndexesInRect:(CGRect)rect
{
	NSMutableArray *foundObjects = [NSMutableArray arrayWithCapacity:5];
	for(TUILayoutObject *object in layout.objects) {
        if(CGRectIntersectsRect(object.calculatedFrame, rect)) {
            [foundObjects addObject:object.indexString];
        }
	}
	return foundObjects;
}

-(NSString*) indexKeyForObject:(TUILayoutObject*) object {
    return [NSString stringWithFormat:@"%d", [layout.objects indexOfObject:object]];
}


-(TUILayoutObject*) objectAtTopOfScreen {
    NSArray *sortedIndexes = [[layout.objectViewsMap allKeys] sortedArrayUsingSelector:@selector(compareNumberStrings:)];
    if (sortedIndexes) {
        NSString *indexKey = [sortedIndexes lastObject];
        TUILayoutObject *object = [layout.objects objectAtIndex:[indexKey integerValue]];
        return object;
    } 
    return nil;
}



- (CGPoint) fixContentOffset:(CGPoint)offset forSize:(CGSize) size
{
	CGRect b = layout.bounds;
	CGSize s = size;
	
	//s.height += _contentInset.top;
	
	CGFloat mx = offset.x + s.width;
	if(s.width > b.size.width) {
		if(mx < b.size.width) {
			offset.x = b.size.width - s.width;
		}
		if(offset.x > 0.0) {
			offset.x = 0.0;
		}
	} else {
		if(mx > b.size.width) {
			offset.x = b.size.width - s.width;
		}
		if(offset.x < 0.0) {
			offset.x = 0.0;
		}
	}
    
	CGFloat my = offset.y + s.height;
	if(s.height > b.size.height) { // content bigger than bounds
		if(my < b.size.height) {
			offset.y = b.size.height - s.height;
		}
		if(offset.y > 0.0) {
			offset.y = 0.0;
		}
	} else { // content smaller than bounds
		if(0) { // let it move around in bounds
			if(my > b.size.height) {
				offset.y = b.size.height - s.height;
			}
			if(offset.y < 0.0) {
				offset.y = 0.0;
			}
		}
		if(1) { // pin to top
			offset.y = b.size.height - s.height;
		}
	}
	
	return offset;
}


//- (CGPoint) relativeContentOffset {
//    CGFloat previousYOffset =scrollView.contentSize.height + scrollView.contentOffset.y;
//    CGFloat previousXOffset = la.contentSize.width + scrollView.contentOffset.x;
//    CGFloat newYOffset = previousYOffset - self.updatingTransaction.contentSize.height;
//    CGFloat newXOffset = previousXOffset - self.contentSize.width;
//    CGPoint offset = CGPointMake(newXOffset, newYOffset);
//    offset = [self fixContentOffset:offset forSize:self.updatingTransaction.contentSize];
//    return offset;
//}

//-(CGRect) proposedVisibleRect {
//    CGRect b = self.bounds;
//    b.size.height += 100;
//	CGPoint offset = [self proposedContentOffset];
//	offset.x = -offset.x;
//	offset.y = -offset.y;
//	b.origin = offset;
//	return b;
//}
//


@end

@implementation TUILayout {
    NSMutableArray *updateStack;
    NSMutableArray *executionQueue;
    NSMutableArray *reusableViews;
    BOOL animating;
    BOOL didFirstLayout;
    TUILayoutTransaction *defaultTransaction;
}

@synthesize viewClass;
@synthesize executingTransaction;
@synthesize objectViewsMap;
@synthesize objects;
@synthesize dataSource;
@synthesize spaceBetweenViews;
@synthesize reloadedDate;
@synthesize typeOfLayout;
@synthesize reloadHandler;

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
        spaceBetweenViews = 0;
        self.objects = [NSMutableArray array];
        objectViewsMap = [NSMutableDictionary dictionary];
        updateStack = [NSMutableArray array];
        executionQueue = [NSMutableArray array];
        
        defaultTransaction = [[TUILayoutTransaction alloc] init];
        defaultTransaction.layout = self;
        
        self.typeOfLayout = TUILayoutVertical;
        self.viewClass = [TUIView class];
    }
    return self;
}

#pragma mark - Execute Transactions

- (void) layoutSubviews{
    // don't interfere with active animating transactions
    if (!self.executingTransaction || (self.executingTransaction && self.executingTransaction.state != TUILayoutTransactionStateAnimating)) [self executeNextLayoutTransaction];
    [super layoutSubviews];
}

-(void) executeNextLayoutTransaction {
    
    // check for any updates
    TUILayoutTransaction *nextTransaction = [executionQueue lastObject];
    // continue to execute the last transaction if no updates pending
    if (!nextTransaction) nextTransaction = self.executingTransaction;
    // On first layout, we use the default transaction
    if (!nextTransaction) nextTransaction = defaultTransaction;
    self.executingTransaction = nextTransaction;
    
    if ([executionQueue count] >= 1 && nextTransaction.state == TUILayoutTransactionStateNormal) {
        __weak TUILayout* weakSelf = self;
        __weak NSMutableArray *weakExecutionQueue = executionQueue;
        [nextTransaction addCompletionBlock: ^(TUILayout* l){
            if (weakSelf.executingTransaction.state == TUILayoutTransactionStateNormal) {
                [weakExecutionQueue removeLastObject];
            }
            [weakSelf performSelector:@selector(setNeedsLayout) withObject:nil afterDelay:0.01];
        }];
    }
    [nextTransaction applyLayout];
}

-(void) setNeedsLayout {
    [super setNeedsLayout];
}

-(void) beginUpdates {
    TUILayoutTransaction *transaction = [[TUILayoutTransaction alloc] init];
    transaction.shouldAnimate = YES;
    transaction.layout = self;
    [updateStack addObject:transaction];
}

- (TUILayoutTransaction*) updatingTransaction {
    TUILayoutTransaction *t = [updateStack lastObject];
    if (!t) t = self.executingTransaction;
    if (!t) t = defaultTransaction;
    return t;
}

-(void) endUpdates { 
    // Send this transaction be executed
    if ([updateStack count] > 0) {
        [executionQueue addObject:[updateStack lastObject]];
        [updateStack removeLastObject];
        [self setNeedsLayout];
    }
}

# pragma mark - Public

-(void) reloadData {
    if (!dataSource || ![dataSource respondsToSelector:@selector(numberOfObjectsInLayout:)]) {
        NSAssert(false, @"Must supply data source");
    }
    
    if (CGRectEqualToRect(CGRectZero, self.bounds)) {
        NSAssert(false, @"Calling reloadData with empty bounds");
    }
    
    reloadedDate = [NSDate date];
    
    [objectViewsMap enumerateKeysAndObjectsUsingBlock:^(NSString *indexKey, TUIView *view, BOOL *stop) {
        [self enqueueReusableView:view];
        [view removeFromSuperview];
    }];
    
    objectViewsMap = [NSMutableDictionary dictionary];
    NSUInteger numberOfObjects = [dataSource numberOfObjectsInLayout:self];
    self.objects = [NSMutableArray arrayWithCapacity:numberOfObjects];
    for (NSUInteger i =0; i < numberOfObjects; i++) {
        TUILayoutObject *object = [[TUILayoutObject alloc] init];
        [self.objects addObject:object];
        object.index = i;
        object.indexString = [NSString stringWithFormat:@"%d", i];
    }

    if (self.executingTransaction) {
        self.executingTransaction = nil;
        defaultTransaction.state = TUILayoutTransactionStatePrelayout;
        defaultTransaction.calculated = false;
        defaultTransaction = [[TUILayoutTransaction alloc] init];
        defaultTransaction.layout = self;
    }
    [self layoutSubviews];
    if (reloadHandler) {
        reloadHandler(self);
    }
}

- (TUIView*) dequeueReusableView
{
    TUIView *v = [reusableViews lastObject];
    if(v) [reusableViews removeLastObject];
    if (!v) v = [self createView];
	return v;
}

-(TUIView*) viewForIndex:(NSUInteger)index {
    if (!objects || ![objects count]) return nil;
    NSString *indexKey = [NSString stringWithFormat:@"%d", index];
    
    TUIView *v = [objectViewsMap objectForKey:indexKey];
    if (!v && (index <= [objects count] - 1)) {
        TUILayoutObject *object = [objects objectAtIndex:index];
        [self.executingTransaction addSubviewForObject:object atIndex:[NSString stringWithFormat:@"%d", index]];
        v = [objectViewsMap objectForKey:indexKey];
    }
    return v;
}


- (TUIView*) viewAtPoint:(CGPoint) point {
    for (TUILayoutObject *object in objects) {
        if (CGRectContainsPoint(object.calculatedFrame, point)) {
            TUIView *v = [objectViewsMap objectForKey:object.indexString];
            if (!v && (object.index <= [objects count] - 1)) {
                [self.executingTransaction addSubviewForObject:object atIndex:object.indexString];
                v = [objectViewsMap objectForKey:object.indexString];
            }
            return v;
        }
    }
    return nil;
}


- (CGRect) rectForObjectAtIndex:(NSUInteger) index {
    TUILayoutObject *object = [objects objectAtIndex:index];
    return object.calculatedFrame;
}

- (void)scrollToObjectAtIndex:(NSUInteger)index atScrollPosition:(TUILayoutScrollPosition)scrollPosition animated:(BOOL)animated
{
	CGRect v = [self visibleRect];
	CGRect r = [self rectForObjectAtIndex:index];
		
	switch(scrollPosition) {
		case TUITableViewScrollPositionNone:
			// do nothing
			break;
		case TUITableViewScrollPositionTop:
			r.origin.x -= (v.size.width - r.size.width);
			r.size.width += (v.size.width - r.size.width);
			[self scrollRectToVisible:r animated:animated];
			break;
		case TUITableViewScrollPositionToVisible:
		default:
			[self scrollRectToVisible:r animated:animated];
			break;
	}
}


-(void) setTypeOfLayout:(TUILayoutType)t {
    typeOfLayout = t;
    if (t == TUILayoutHorizontal) {
        self.horizontalScrolling = YES;
    }
}


// this method create a new view for the object at the specified index
// so that the existing view can be pulled out of the layout and used elsewhere,
// useful for certain animations.
// returns the replaced view
-(TUIView*) replaceViewForObjectAtIndex:(NSUInteger) index withSize:(CGSize) size {
    
    // This view has to already exist
    if (!objects || ![objects count]) return nil;
    NSString *indexKey = [NSString stringWithFormat:@"%d", index];
    TUILayoutObject *object = [self.objects objectAtIndex:index];
    
    // Make sure the view exists
    TUIView *v = [objectViewsMap objectForKey:indexKey];
    if (v) {
        // remove the view from our mapping
        [self.objectViewsMap removeObjectForKey:indexKey];
        // remove it so it won't be reused
        [reusableViews removeObject:v];
        //Add another one in it's place
        object.size = size;
        return [self.executingTransaction addSubviewForObject:object atIndex:[NSString stringWithFormat:@"%d", index]];
    }
    return nil;
}

- (void) resizeObjectAtIndexes:(NSArray*) objectIndexes sizes:(NSArray*) sizes animationBlock:(void (^)())animationBlock completion:(void (^)())completionBlock 
{
    [self beginUpdates];
    [objectIndexes enumerateObjectsUsingBlock:^(NSString *stringIndex, NSUInteger idx, BOOL *stop) {
        NSInteger index = [stringIndex integerValue];
        [self.updatingTransaction addCompletionBlock:completionBlock];
        self.updatingTransaction.animationBlock = animationBlock;
        self.updatingTransaction.animationDuration = 2.3;
        TUILayoutObject *oldObject = [self.objects objectAtIndex:index];
        TUILayoutObject *object = [[TUILayoutObject alloc] init];
        NSValue *objectSize = [sizes objectAtIndex:idx];
        object.size = [objectSize sizeValue];
        object.oldFrame = oldObject.oldFrame;
        object.markedForUpdate = YES;
        object.index = index;
        object.indexString = [NSString stringWithFormat:@"%d", index];
        [self.updatingTransaction.changeList addObject:object];
    }];
    [self endUpdates];
    
}


-(void) resizeObjectsToSize:(CGSize) size animationBlock:(void (^)())animationBlock completionBlock:(void (^)())completion {  
    [self beginUpdates];
    [self.updatingTransaction addCompletionBlock:completion];
    self.updatingTransaction.animationBlock = animationBlock;
    self.updatingTransaction.animationDuration = 0.5;
    [self.objects enumerateObjectsUsingBlock:^(TUILayoutObject *obj, NSUInteger idx, BOOL *stop) {
        TUILayoutObject *object = [[TUILayoutObject alloc] init];
        object.size = size;
        object.oldFrame = obj.oldFrame;
        object.markedForUpdate = YES;
        object.index = obj.index;
        object.indexString = [NSString stringWithFormat:@"%d", idx];
        [self.updatingTransaction.changeList addObject:object];
    }];
    [self endUpdates];
}

- (void) resizeObjectAtIndex:(NSUInteger) index toSize:(CGSize) size animationBlock:(void (^)())animationBlock  completionBlock:(void (^)())completionBlock {
    [self beginUpdates];
    [self.updatingTransaction addCompletionBlock:completionBlock];
    self.updatingTransaction.animationBlock = animationBlock;
    self.updatingTransaction.animationDuration = 0.5;
    TUILayoutObject *oldObject = [self.objects objectAtIndex:index];
    TUILayoutObject *object = [[TUILayoutObject alloc] init];
    object.size = size;
    object.oldFrame = oldObject.oldFrame;
    object.markedForUpdate = YES;
    object.index = index;
    object.indexString = [NSString stringWithFormat:@"%d", index];
    [self.updatingTransaction.changeList addObject:object];
    [self endUpdates];
}    

-(void) insertObjectAtIndex:(NSUInteger) index  {
    [self insertObjectAtIndex:index animationBlock:nil completionBlock:nil];
}

-(void) insertObjectAtIndex:(NSUInteger) index  animationBlock:(void (^)())animationBlock  completionBlock:(void (^)())completionBlock
{
    // Check for a valid insertion point
    NSAssert(index >= 0 && index <= ([self.objects count]), @"TUILayout object out of range");
    [self beginUpdates];
    TUILayoutObject *object = [[TUILayoutObject alloc] init];
    object.size = [dataSource sizeOfObjectAtIndex:index];
    object.markedForInsertion = YES;
    object.index = index;
    object.indexString = [NSString stringWithFormat:@"%d", index];
    [self.updatingTransaction.changeList addObject:object];
    self.updatingTransaction.animationBlock = animationBlock;
    [self.updatingTransaction addCompletionBlock:completionBlock];
    [self endUpdates];
}

-(void) removeObjectsAtIndexes:(NSIndexSet *)indexes {
    [self beginUpdates];
    
    // Update the model
    [self.objects removeObjectsAtIndexes:indexes];
    
    // If the object isn't visible there isn't anything todo except relayout
    __block BOOL objectVisible;
    
    
    __weak TUILayout *weakSelf = self;
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        // Valid index
        NSAssert(idx >= 0 || idx < ([self.objects count]), @"TUILayout object out of range");
        
        // Animate out view if it's on screen
        // NSString *indexKey = [NSString stringWithFormat:@"%d", idx];
        __weak TUIView *v = nil; //[objectViewsMap objectForKey:indexKey]; 
        if (v) {
            objectVisible = YES;
            [TUIView animateWithDuration:kTUILayoutDefaultAnimationDuration animations:^{
                v.alpha = 0;
            } completion:^(BOOL finished) {
                [v removeFromSuperview];
                [weakSelf enqueueReusableView:v];
            }];
            
            // Remove object from screen map
            //[objectViewsMap removeObjectForKey:indexKey];
        }
    }];
    
    [self endUpdates];
}


- (NSArray *)visibleViews
{
	return [objectViewsMap allValues];
}



#pragma mark - Getters and Setters


#pragma mark - View Reuse

- (void) enqueueReusableView:(TUIView *)view
{
	if(!reusableViews) {
		reusableViews = [[NSMutableArray alloc] init];
	}
    view.alpha = 1;
    view.backgroundColor = [TUIColor clearColor];
	[reusableViews addObject:view];
}


- (TUIView *)createView {
    TUIView *v = [[self.viewClass alloc] initWithFrame:CGRectZero];
    return v;
}

-(NSInteger) numberOfCells {
    NSInteger numberOfCells = [self.objects count];
    return numberOfCells;
}

#pragma mark - Scrolling

-(BOOL) isVerticalScroll:(NSEvent*) event {
    
    // Get the amount of scrolling
    double dx = 0.0;
    double dy = 0.0;
    
    CGEventRef cgEvent = [event CGEvent];
    const int64_t isContinuous = CGEventGetIntegerValueField(cgEvent, kCGScrollWheelEventIsContinuous);
    
    if(isContinuous) {
        dx = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventPointDeltaAxis2);
        dy = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventPointDeltaAxis1);
    } else {
        CGEventSourceRef source = CGEventCreateSourceFromEvent(cgEvent);
        if(source) {
            const double pixelsPerLine = CGEventSourceGetPixelsPerLine(source);
            dx = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventFixedPtDeltaAxis2) * pixelsPerLine;
            dy = CGEventGetDoubleValueField(cgEvent, kCGScrollWheelEventFixedPtDeltaAxis1) * pixelsPerLine;
            CFRelease(source);
        } else {
            NSLog(@"Critical: NULL source from CGEventCreateSourceFromEvent");
        }
    }
    
    if (fabsf(dx) > fabsf(dy)) return NO;
    return YES;
}


@end




