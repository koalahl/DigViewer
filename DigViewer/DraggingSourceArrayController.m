//
//  DraggingSourceArrayController.m
//  DigViewer
//
//  Created by opiopan on 2015/04/12.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "DraggingSourceArrayController.h"
#import "PathNode.h"

@implementation DraggingSourceArrayController

//-----------------------------------------------------------------------------------------
// NSTableViewのDragging Source実装
//-----------------------------------------------------------------------------------------
- (BOOL)tableView:(NSTableView*)tableView writeRowsWithIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pboard
{
    return [self writeItemsAtIndexes:indexes toPasteboard:pboard] != 0;
}

//-----------------------------------------------------------------------------------------
// IKImageBrowserViewのDragging Source実装
//-----------------------------------------------------------------------------------------
- (NSUInteger)imageBrowser:(IKImageBrowserView *)aBrowser writeItemsAtIndexes:(NSIndexSet *)indexes
              toPasteboard:(NSPasteboard *)pboard
{
    return [self writeItemsAtIndexes:indexes toPasteboard:pboard];
}

//-----------------------------------------------------------------------------------------
// NSTableViewのDragging Source実装
//-----------------------------------------------------------------------------------------
- (NSUInteger)writeItemsAtIndexes:(NSIndexSet *)indexes toPasteboard:(NSPasteboard *)pboard
{
    NSMutableArray* plist = [NSMutableArray arrayWithCapacity:indexes.count];
    for (NSUInteger i = indexes.firstIndex; i != NSNotFound; i = [indexes indexGreaterThanIndex:i]){
        PathNode* node = self.arrangedObjects[i];
        [plist addObject:node.originalPath];
    }
    [pboard declareTypes:@[NSFilenamesPboardType] owner:self];
    [pboard setPropertyList:plist forType:NSFilenamesPboardType];
    
    return plist.count;
}


@end
