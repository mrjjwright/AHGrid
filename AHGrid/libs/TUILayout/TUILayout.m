//
//  TUILayout.m
//  Crew
//
//  Created by John Wright on 11/13/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

// ARC is compatible with iOS 4.0 upwards, but you need at least Xcode 4.2 with Clang LLVM 3.0 to compile it.

#if !__has_feature(objc_arc)
#error This project must be compiled with ARC (Xcode 4.2+ with LLVM 3.0 and above)
#endif

#import "TUILayout.h"

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
@property (nonatomic) TUILayoutType typeOfLayout;
@property (nonatomic, copy) TUILayoutHandler animationBlock;
@property (nonatomic) CGFloat spaceBetweenViews;
@property (nonatomic) BOOL shouldAnimate;
@property (nonatomic) CGSize contentSize;
@property (nonatomic) CGRect rectForLayout;
@property (nonatomic) TUILayoutTransactionState state;
@property (nonatomic, weak) TUILayoutObject *scrollToObject;
@property (nonatomic, strong) NSMutableArray *changeList;
@property (nonatomic) CGSize objectSize;

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
-(void) addSubviewForObject:(TUILayoutObject*) object atIndex:(NSString*) objectIndex;
-(void) rebaseForInsertionsAndRemovals;
-(void) processChangeList;
-(void) cleanup;
-(void) moveObjectsAfterPoint:(CGPoint) point byIndexAmount:(NSInteger) indexAmount;

-(CGFloat) offsetAtIndex:(NSInteger) index;

@end

@implementation TUILayoutTransaction {
    NSMutableArray *completionBlocks;
    CGPoint contentOffset;
    BOOL calculatedContentSize;
    NSMutableArray *objectIndexesToBringIntoView;
    BOOL calculated;
    BOOL shouldChangeContentOffset;
    BOOL preLayoutPass;
}

@synthesize layout;
@synthesize animationBlock;
@synthesize typeOfLayout;
@synthesize spaceBetweenViews;
@synthesize shouldAnimate;
@synthesize contentSize;
@synthesize rectForLayout;
@synthesize state;
@synthesize scrollToObject;
@synthesize changeList;
@synthesize objectSize;

- (id)init {
    
	if((self = [super init]))
	{
        spaceBetweenViews = 0;
        typeOfLayout = TUILayoutVertical;
    }
    return self;
}


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
    
    if (!calculated) {
        [self calculateContentSize];
        [self calculateContentOffset];
        [self processChangeList];
        [self calculateObjectOffsets]; 
        calculated = YES;
    }
        
    if (self.shouldAnimate && state != TUILayoutTransactionStateDoneAnimating) {
        if (state == TUILayoutTransactionStateNormal) {
            state = TUILayoutTransactionStatePrelayout;
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
                    for (TUILayoutHandler block in weakCompletionBlocks) block();
                }];
                                
                // Recalculate the offsets
                [weakSelf calculateObjectOffsets];
                
                weakSelf.layout.contentSize = weakSelf.contentSize;
                
                [TUIView animateWithDuration:kTUILayoutDefaultAnimationDuration animations:^{
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
                    if (weakSelf.animationBlock) weakSelf.animationBlock();
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

-(void) addSubviewForObject:(TUILayoutObject*) object atIndex:(NSString*) objectIndex {
    
    if([layout.objectViewsMap objectForKey:objectIndex]  && !object.markedForInsertion) {
        NSLog(@"!!! Warning: already have a view in place for index %@\n\n\n", object);
    } else {
        NSInteger index = [objectIndex integerValue];
        TUIView * v = [layout.dataSource layout:layout viewForObjectAtIndex:index];
        v.tag = index;
        if (state != TUILayoutTransactionStateNormal && !CGRectIsNull(object.oldFrame)) {
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
                CABasicAnimation *fadeAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
                [fadeAnim setDuration:kTUILayoutDefaultAnimationDuration];
                [fadeAnim setFromValue:[NSNumber numberWithFloat:0.0f]];
                [fadeAnim setToValue:[NSNumber numberWithFloat:1.0f]];
                [v.layer addAnimation:fadeAnim forKey:kTUILayoutAnimation];
            } else {
                [layout addSubview:v];
            }
        }
        [layout.objectViewsMap setObject:v forKey:objectIndex];
        [v setNeedsLayout]; 
    }
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
        
        CGRect oldFrame = v.frame; 
        if (!CGRectEqualToRect(object.calculatedFrame, oldFrame)) 
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
            if (v.frame.origin.y <= point.y) {
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
        contentOffset.x *= contentSize.width / layout.contentSize.width;
        contentOffset.y *= contentSize.height / layout.contentSize.height;
    } else {
        shouldChangeContentOffset = NO;
    }
}

-(void) calculateContentOffsetIfScrolledRectToVisible:(CGRect) rect {
    CGRect visible = layout.visibleRect;
    if (self.typeOfLayout == TUILayoutHorizontal) {
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
        // Update to the visibleRect of the scrollView, expanded a bit 
        // so that scrolling is smooth
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
    CGFloat calculatedHeight = 0;
    CGFloat calculatedWidth = 0;
    if (typeOfLayout == TUILayoutVertical) {
        calculatedWidth = self.layout.bounds.size.width;
        for (TUILayoutObject *object in layout.objects) {
            calculatedHeight += object.size.height;
        } 
    } else {
        calculatedHeight = self.layout.bounds.size.height;
        for (TUILayoutObject *object in layout.objects) {
            calculatedWidth += object.size.width;
        } 
    }
    // final contentSize is modified by the amount of insertions, removals, and resizes as reflected
    // in contentWidthChange and contentHeightChange
    for (TUILayoutObject *object in changeList) {
        if (object.markedForUpdate) {
            TUILayoutObject *oldObject = [layout.objects objectAtIndex:object.index];
            calculatedHeight += object.size.height - oldObject.size.height; 
            calculatedWidth += object.size.width - oldObject.size.width; 
        }
    }
    self.contentSize = CGSizeMake(calculatedWidth, calculatedHeight);
}

- (void) calculateObjectOffsets {
    (typeOfLayout == TUILayoutVertical) ? [self calculateObjectOffsetsVertical] : [self calculateObjectOffsetsHorizontal];
}

- (void) calculateObjectOffsetsVertical {
    CGFloat offset = self.contentSize.height;  
    for (TUILayoutObject *object in layout.objects) {
        object.oldFrame = object.calculatedFrame;
        offset -= object.size.height + spaceBetweenViews;
        object.y = offset + spaceBetweenViews;
    }
}

- (void) calculateObjectOffsetsHorizontal {
    CGFloat i = 0;  
    CGFloat offset = 0;
    for (TUILayoutObject *object in layout.objects) {
        object.oldFrame = object.calculatedFrame;
        object.x = i * (object.size.width + spaceBetweenViews);
        i += 1;
        offset += object.size.width + self.spaceBetweenViews;
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

-(CGRect) rectOfViewAtIndex:(NSInteger) index {
    TUILayoutObject *object = [layout.objects objectAtIndex:index];
    if (self.typeOfLayout == TUILayoutVertical) {
        return CGRectMake(0, [self offsetAtIndex:index], layout.bounds.size.width, object.size.height);
    }
    return CGRectMake([self offsetAtIndex:index], 0, object.size.width, layout.bounds.size.height);;
}

-(CGFloat) offsetAtIndex:(NSInteger) index {
    CGFloat offset = 0;
    int i = 0;
    for (TUILayoutObject *object in layout.objects) {
        offset += (self.typeOfLayout == TUILayoutVertical) ?  object.size.height : object.size.width;
        if (i == index) continue;
    }
    return offset;
}

- (TUIView*) viewAtPoint:(CGPoint) point {
    for (TUIView *view in layout.subviews) {
        if (CGRectContainsPoint(view.frame, point)) {
            return view;
        }
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

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
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
        [nextTransaction addCompletionBlock: ^{
            if (weakSelf.executingTransaction.state == TUILayoutTransactionStateNormal) {
                [weakExecutionQueue removeLastObject];
            }
            [weakSelf performSelector:@selector(setNeedsLayout) withObject:nil afterDelay:0.01];
        }];
    }
    [nextTransaction applyLayout];
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
                         
    [objectViewsMap enumerateKeysAndObjectsUsingBlock:^(NSString *indexKey, TUIView *view, BOOL *stop) {
        [view removeFromSuperview];
    }];
    
    objectViewsMap = [NSMutableDictionary dictionary];
    NSUInteger numberOfObjects = [dataSource numberOfObjectsInLayout:self];
    self.objects = [NSMutableArray arrayWithCapacity:numberOfObjects];
    for (NSUInteger i =0; i < numberOfObjects; i++) {
        TUILayoutObject *object = [[TUILayoutObject alloc] init];
        object.size = [dataSource sizeOfObjectAtIndex:i];
        [self.objects addObject:object];
        object.index = i;
        object.indexString = [NSString stringWithFormat:@"%d", i];
    }
    self.executingTransaction = nil;
    [self setNeedsLayout];
}

- (TUIView*) dequeueReusableView
{
    TUIView *v = [reusableViews lastObject];
    if(v) [reusableViews removeLastObject];
    if (!v) v = [self createView];
	return v;
}

-(TUIView*) viewForIndex:(NSUInteger)index {
    return [objectViewsMap objectForKey:[NSString stringWithFormat:@"%d", index]];
}


-(TUILayoutType) typeOfLayout {
    return self.updatingTransaction.typeOfLayout;
}

-(void) setTypeOfLayout:(TUILayoutType)t {
    self.updatingTransaction.typeOfLayout = t;
    if (t == TUILayoutHorizontal) {
        self.horizontalScrolling = YES;
    }
}

-(void) resizeObjectsToSize:(CGSize) size animated:(BOOL) animated completion:(void (^)())completion {  
    [self beginUpdates];
    [self.updatingTransaction addCompletionBlock:completion];
    self.updatingTransaction.objectSize = size; 
    [self endUpdates];
}

- (void) resizeObjectAtIndex:(NSUInteger) index toSize:(CGSize) size animationBlock:(void (^)())animationBlock  completionBlock:(void (^)())completionBlock {
    [self beginUpdates];
    [self.updatingTransaction addCompletionBlock:completionBlock];
    self.updatingTransaction.animationBlock = animationBlock;
    TUILayoutObject *object = [[TUILayoutObject alloc] init];
    object.size = size;
    object.markedForUpdate = YES;
    object.index = index;
    object.indexString = [NSString stringWithFormat:@"%d", index];
    [self.updatingTransaction.changeList addObject:object];
    [self endUpdates];
}    

-(void) insertObjectAtIndex:(NSUInteger) index  
{
    // Check for a valid insertion point
    NSAssert(NSLocationInRange(index, NSMakeRange(0, [self.objects count])), @"TUILayout object out of range");
    [self beginUpdates];
    TUILayoutObject *object = [[TUILayoutObject alloc] init];
    object.size = [dataSource sizeOfObjectAtIndex:index];
    [self.objects insertObject:object atIndex:index];
    object.markedForInsertion = YES;
    [self.updatingTransaction.changeList addObject:object];
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




