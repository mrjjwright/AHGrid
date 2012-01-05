//
//  TUITableView+SectionDragging.m
//  Crew
//
//  Created by John Wright on 10/20/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import "TUITableView+SectionDragging.h"

// Dragged sections should be just above pinned headers
#define kTUITableViewDraggedSectionZPosition 1001


@interface TUITableView (SectionDraggingPrivate)

- (BOOL)_preLayoutSections;
- (void)_layoutSectionHeaders:(BOOL)needLayout;
- (void)_layoutSections:(BOOL)needLayout;

@end

@implementation TUITableView (SectionDragging)

/**
 * @brief Mouse down in a section
 */
-(void)__mouseDownInSection:(TUITableViewSectionHeader *)section offset:(CGPoint)offset event:(NSEvent *)event {
    [self __beginDraggingSection:section offset:offset location:[[section superview] localPointForEvent:event]];
}

/**
 * @brief Mouse up in a section
 */
-(void)__mouseUpInSection:(TUITableViewSectionHeader *)section offset:(CGPoint)offset event:(NSEvent *)event {
    [self __endDraggingSection:section offset:offset location:[[section superview] localPointForEvent:event]];
}

/**
 * @brief A section was dragged
 * 
 * If reordering is permitted by the table, this will begin a move operation.
 */
-(void)__mouseDraggedSection:(TUITableViewSectionHeader *)section offset:(CGPoint)offset event:(NSEvent *)event {
    [self __updateDraggingSection:section offset:offset location:[[section superview] localPointForEvent:event]];
}

/**
 * @brief Determine if we're dragging a section or not
 */
-(BOOL)__isDraggingSection {
    return _dragToReorderSection != nil && _currentDragToReorderSectionIndex >= 0;
}

/**
 * @brief Begin dragging a section
 */
-(void)__beginDraggingSection:(TUITableViewSectionHeader *)section offset:(CGPoint)offset location:(CGPoint)location {
    
    _currentDragToReorderLocation = location;
    _currentDragToReorderMouseOffset = offset;
    
    [_dragToReorderSection release];
    _dragToReorderSection = [section retain];
    
    _currentDragToReorderSectionIndex = -1;
    _previousDragToReorderSectionIndex = -1;
    
}

/**
 * @brief Update section dragging
 */
-(void)__updateDraggingSection:(TUITableViewSectionHeader *)section offset:(CGPoint)offset location:(CGPoint)location {
    BOOL animate = TRUE;
    
    // note the location in any event
    _currentDragToReorderLocation = location;
    _currentDragToReorderMouseOffset = offset;
    
    // determine if reordering this cell is permitted or not via our data source (this should probably be done only once somewhere)
    if(self.dataSource == nil || ![self.dataSource respondsToSelector:@selector(tableView:canMoveSectionAtIndex:)] || ![self.dataSource tableView:self canMoveSectionAtIndex:section.index]){
        return; // reordering is not permitted
    }

    
    // return if there wasn't a proper drag
    if(![section didDrag]) return;
    
    // initialize defaults on the first drag
    if(_currentDragToReorderSectionIndex < 0 || _previousDragToReorderSectionIndex < 0){
        // make sure the dragged section is on top
        _dragToReorderSection.layer.zPosition = kTUITableViewDraggedSectionZPosition;
        
        // setup section indexes to track
        _currentDragToReorderSectionIndex = section.index;
        _previousDragToReorderSectionIndex = section.index;
        return; // just initialize on the first event
    }
    
    CGRect visible = [self visibleRect];
    // dragged section destination frame
    CGRect dest = CGRectMake(0, roundf(MAX(visible.origin.y, MIN(visible.origin.y + visible.size.height - section.frame.size.height, location.y + visible.origin.y - offset.y))), self.bounds.size.width, section.frame.size.height);
    // bring to front
    [[section superview] bringSubviewToFront:section];
    // move the section
    section.frame = dest;
    
    // constraint the location to just below the list of sections
//    CGFloat endOfSections = [self rectForSection:[_sectionInfo count] -1].origin.y;
//    NSLog(@"end of sections is %f", endOfSections);
//    location = CGPointMake(location.x, MAX(0, MIN(endOfSections, location.y)));
    
    // scroll content if necessary (scroll view figures out whether it's necessary or not)
    [self beginContinuousScrollForDragAtPoint:location animated:TRUE];
    
    NSInteger sectionIndexUnderMouse = [self indexOfSectionWithHeaderAtVerticalOffset:location.y + visible.origin.y];
    //NSLog(@"section index under mouse %ld", sectionIndexUnderMouse);
    if (sectionIndexUnderMouse == -1) {
        sectionIndexUnderMouse = [_sectionInfo count] - 1;
    }
    // note the previous index
    _previousDragToReorderSectionIndex = _currentDragToReorderSectionIndex;
    _previousDragToReorderInsertionMethod = _currentDragToReorderInsertionMethod;
    
    // note the current index
    _currentDragToReorderSectionIndex = sectionIndexUnderMouse;
    _currentDragToReorderInsertionMethod = TUITableViewInsertionMethodAtIndex;
    
    
    // ordered index paths for enumeration
    NSInteger fromIndex = -1;
    NSInteger toIndex = -1;
    
    if(sectionIndexUnderMouse < _previousDragToReorderSectionIndex ){
        fromIndex = sectionIndexUnderMouse;
        toIndex = _previousDragToReorderSectionIndex;
    }else if(sectionIndexUnderMouse > _previousDragToReorderSectionIndex){
        fromIndex = _previousDragToReorderSectionIndex;
        toIndex = sectionIndexUnderMouse;
    }else {
        fromIndex = sectionIndexUnderMouse;
        toIndex = sectionIndexUnderMouse;
    }
        
    // we now have the final destination index update surrounding
    // sections to make room for the dragged section
    if(sectionIndexUnderMouse >=0 && fromIndex >= 0 && toIndex >= 0){
        
        // begin animations
        if(animate){
            [TUIView beginAnimations:NSStringFromSelector(_cmd) context:NULL];
        }
        
        // update other section headers
        for(NSInteger i = 0; i <= [_sectionInfo count]; i++){
            TUIView *headerView;
            if ((headerView = [self headerViewForSection:i]) != nil && (headerView != section)) {
                CGRect frame = [self rectForSection:i];
                CGRect target;
                
                if(i >= sectionIndexUnderMouse && i < section.index){
                    // the visited index is above the origin and below the current index;
                    // shift the view down by the height of the dragged cell
                    target = CGRectMake(frame.origin.x, frame.origin.y - section.frame.size.height, frame.size.width, frame.size.height);
                }else if( i <= sectionIndexUnderMouse && i > section.index){
                    // the visited index is below the origin and above the current index;
                    // shift the cell up by the height of the dragged cell
                    target = CGRectMake(frame.origin.x, frame.origin.y + section.frame.size.height, frame.size.width, frame.size.height);
                }else{
                    // the visited cell is outside the affected range and should be returned to its
                    // normal frame
                    target = frame;
                }
                
                // only animate if we actually need to
                if(!CGRectEqualToRect(target, headerView.frame)){
                    headerView.frame = target;
                }
            }
        }
        
        // commit animations
        if(animate){
            [TUIView commitAnimations];
        }
        
    }
    
}

/**
 * @brief Finish dragging a section
 */
-(void)__endDraggingSection:(TUITableViewSectionHeader *)section offset:(CGPoint)offset location:(CGPoint)location {
    BOOL animate = TRUE;
    
    // cancel our continuous scroll
    [self endContinuousScrollAnimated:TRUE];
    
    // finalize drag to reorder if we have a drag index
    if(_currentDragToReorderSectionIndex >= 0){
        NSInteger targetIndex;
        
        switch(_currentDragToReorderInsertionMethod){
            case TUITableViewInsertionMethodBeforeIndex:
                // insert "before" is equivalent to insert "at" as subsequent indexes are shifted down to
                // accommodate the insert.  the distinction is only useful for presentation.
                targetIndex = _currentDragToReorderSectionIndex;
                break;
            case TUITableViewInsertionMethodAfterIndex:
                targetIndex = _currentDragToReorderSectionIndex + 1;
                break;
            case TUITableViewInsertionMethodAtIndex:
            default:
                targetIndex = _currentDragToReorderSectionIndex;
                break;
        }
        
        // only update the data source if the drag ended on a different index path
        // than it started; otherwise just clean up the view
        if(targetIndex != section.index){
            // notify our data source that the row will be reordered
            if(self.dataSource != nil && [self.dataSource respondsToSelector:@selector(tableView:moveSectionAtIndex:toIndex:)]){
                [self.dataSource tableView:self moveSectionAtIndex:section.index toIndex:targetIndex];
            }
        }
        
        // compute the final section destination frame
        CGRect frame = [self rectForHeaderOfSection:_currentDragToReorderSectionIndex];
        // adjust if necessary based on the insertion method
        switch(_currentDragToReorderInsertionMethod){
            case TUITableViewInsertionMethodBeforeIndex:
                frame = CGRectMake(frame.origin.x, frame.origin.y + section.frame.size.height, frame.size.width, frame.size.height);
                break;
            case TUITableViewInsertionMethodAfterIndex:
                frame = CGRectMake(frame.origin.x, frame.origin.y - section.frame.size.height, frame.size.width, frame.size.height);
                break;
            case TUITableViewInsertionMethodAtIndex:
            default:
                // do nothing. this case is just here to avoid complier complaints...
                break;
        }
        
        // move the section to its final frame and layout to make sure all the internal caching/geometry
        // stuff is consistent.
        if(animate && !CGRectEqualToRect(section.frame, frame)){
            // disable user interaction until the animation has completed and the table has reloaded
            [self setUserInteractionEnabled:FALSE];
            [TUIView animateWithDuration:0.2
                              animations:^ { section.frame = frame; }
                              completion:^(BOOL finished) {
                                  // reload the table when we're done (implicitly restores z-position)
                                  if(finished) [self reloadData];
                                  // restore user interactivity
                                  [self setUserInteractionEnabled:TRUE];
                              }
             ];
        }else{
            section.frame = frame;
            section.layer.zPosition = 0;
            [self reloadData];
        }
        
        // clear state
        _currentDragToReorderSectionIndex  = -1;
        
    }else{
        section.layer.zPosition = 0;
    }
    
    _previousDragToReorderSectionIndex = -1;
    
    // and clean up
    [_dragToReorderSection release];
    _dragToReorderSection = nil;
    
    _currentDragToReorderLocation = CGPointZero;
    _currentDragToReorderMouseOffset = CGPointZero;
    
}

@end