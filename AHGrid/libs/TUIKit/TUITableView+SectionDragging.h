//
//  TUITableView+SectionDragging.h
//  Crew
//
//  Created by John Wright on 10/20/11.
//  Copyright (c) 2011 AirHeart. All rights reserved.
//

#import "TUIKit.h"

@interface TUITableView (SectionDragging)

-(void)__mouseDownInSection:(TUITableViewSectionHeader *)section offset:(CGPoint)offset event:(NSEvent *)event;
-(void)__mouseUpInSection:(TUITableViewSectionHeader *)section offset:(CGPoint)offset event:(NSEvent *)event;
-(void)__mouseDraggedSection:(TUITableViewSectionHeader *)section offset:(CGPoint)offset event:(NSEvent *)event;

-(BOOL)__isDraggingSection;
-(void)__beginDraggingSection:(TUITableViewSectionHeader *)section offset:(CGPoint)offset location:(CGPoint)location;
-(void)__updateDraggingSection:(TUITableViewSectionHeader *)section offset:(CGPoint)offset location:(CGPoint)location;
-(void)__endDraggingSection:(TUITableViewSectionHeader *)section offset:(CGPoint)offset location:(CGPoint)location;

@end
