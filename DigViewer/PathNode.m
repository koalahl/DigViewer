//
//  PathNode.m
//  DigViewer
//
//  Created by opiopan on 2013/01/05.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "PathNode.h"
#import "NodeID.h"
#import "PathfinderPinnedFile.h"
#import "NSImage+CapabilityDetermining.h"

#include <stdlib.h>

@implementation PathNode{
    NSMutableArray* representationImage;
}

@synthesize name;
@synthesize parent;
@synthesize children;
@synthesize images;
@synthesize indexInParent;
@synthesize imagePath;

//-----------------------------------------------------------------------------------------
// オブジェクト初期化
//-----------------------------------------------------------------------------------------
+ (PathNode*) pathNodeWithPath:(NSString*)path
{
    PathfinderPinnedFile* pinnedFile = [PathfinderPinnedFile pinnedFileWithPath:path];
    PathNode* root = nil;
    
    if (pinnedFile){
        // ピン留めファイルあり
        NSArray* last = nil;
        NSMutableArray* context = [NSMutableArray array];
        for (int i = 0; i < [pinnedFile count]; i++){
            if ([pinnedFile isFileAtIndex:i] && [NSImage isSupportedFileAtPath:[pinnedFile relativePathAtIndex:i]]){
                NSArray* pathComponents = [[pinnedFile relativePathAtIndex:i] pathComponents];
                NSString* filePath = [pinnedFile absolutePathAtIndex:i];
                if (!root){
                    root = [[PathNode alloc] initWithName:pathComponents[0] parent:nil indexInParent:0 path:nil];
                    [context addObject:root];
                }
                int j;
                for (j = 1;
                     last && j < last.count - 1 && j < pathComponents.count - 1 && [last[j] isEqualToString:pathComponents[j]];
                     j++);
                [context[j - 1] mergePathComponents:pathComponents atIndex:j withPath:filePath context:context];
                last = pathComponents;
            }
        }
    }else{
        // ピン留めファイルなし
    }
    
    return root;
}

- (id) initWithName:(NSString*)n parent:(PathNode*)p indexInParent:(NSUInteger)ip path:(NSString*)path;
{
    self = [self init];
    if (self){
        name = n;
        parent = p;
        indexInParent = ip;
        imagePath = path;
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// ファイルをツリーにマージ
//-----------------------------------------------------------------------------------------
- (void) mergePathComponents:(NSArray*)components atIndex:(NSUInteger)index withPath:(NSString*)path
                     context:(NSMutableArray*)context;
{
    if (index > context.count){
        [context addObject:self];
    }else{
        [context replaceObjectAtIndex:index - 1 withObject:self];
    }
    
    NSString* targetName = components[index];
    if (index == components.count - 1){
        if (!images){
            images = [[NSMutableArray alloc] init];
        }
        PathNode* newNode = [[PathNode alloc] initWithName:targetName parent:self indexInParent:images.count path:path];
        [images addObject:newNode];
    }else{
        if (!children){
            children = [[NSMutableArray alloc] init];
        }
        PathNode* child = nil;
        for (int i = 0; i < children.count; i++){
            PathNode* node = children[i];
            if ([node.name isEqualToString:targetName]){
                child = node;
                break;
            }
        }
        if (!child){
            child = [[PathNode alloc] initWithName:targetName parent:self indexInParent:children.count path:nil];
            [children addObject:child];
        }
        [child mergePathComponents:components atIndex:index + 1 withPath:path context:context];
    }
}

//-----------------------------------------------------------------------------------------
// 属性へのアクセサ
//-----------------------------------------------------------------------------------------
- (BOOL) isLeaf
{
    return children == nil;
}

- (PathNode*) me
{
    return self;
}

- (NSMutableArray*) images
{
    if (images){
        return images;
    }else{
        if (!representationImage){
            representationImage = [NSMutableArray arrayWithObject:[children objectAtIndex:0]];
        }
        return representationImage;
    }
}

- (PathNode*) imageNode
{
    if (imagePath){
        return self;
    }else if (images){
        return [[images objectAtIndex:0] imageNode];
    }else{
        return [[children objectAtIndex:0] imageNode];
    }
    
}

- (NSString*) imagePath
{
    return [self imageNode]->imagePath;
}

- (NSString*) imageName
{
    return [[self imagePath] lastPathComponent];
}

- (NSImage*) image
{
    static NSImage* stockedImage = nil;
    static NSString* stockedImagePath = nil;
    NSString* path = [self imagePath];
    if (!stockedImage || ![stockedImagePath isEqualToString:path]){
        stockedImage = [[NSImage alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]];
    }
    return stockedImage;
}

- (NSImage*) icon
{
    if (imagePath){
        return [[NSWorkspace sharedWorkspace] iconForFileType:[name pathExtension]];
    }else{
        return [[NSWorkspace sharedWorkspace] iconForFile:@"/var"];
    }
}

- (NodeID*) nodeID
{
    return [[NodeID alloc] initWithName:name image:self.icon];
}

- (NodeID*) imageID
{
    return [[NodeID alloc] initWithName:self.imageName image:self.imageNode.icon];
}

//-----------------------------------------------------------------------------------------
// ツリー・ウォーキング
//-----------------------------------------------------------------------------------------
- (PathNode*) nextImageNode
{
    return [[self imageNode]->parent nextImageNodeOfImageAtIndex:indexInParent senderIsImageNode:YES];
}

- (PathNode*) nextImageNodeOfImageAtIndex:(NSUInteger)index senderIsImageNode:(BOOL)isImageNode
{
    if (isImageNode){
        if (images && index + 1 < images.count){
            return images[index + 1];
        }else if (children){
            return [children[0] imageNode];
        }
    }else{
        if (children && index + 1 < children.count){
            return [children[index + 1] imageNode];
        }
    }
    return [parent nextImageNodeOfImageAtIndex:indexInParent senderIsImageNode:NO];
}

- (PathNode*) previousImageNode
{
    return [[self imageNode]->parent previousImageNodeOfImageAtIndex:indexInParent
                                                   senderIsImageNode:imagePath != nil];
}

- (PathNode*) previousImageNodeOfImageAtIndex:(NSUInteger)index senderIsImageNode:(BOOL)isImageNode
{
    if (index == NSNotFound){
        if (children){
            return [children.lastObject previousImageNodeOfImageAtIndex:index senderIsImageNode:NO];
        }else if (images){
            return [images.lastObject imageNode];
        }
    }else{
        if (isImageNode){
            if (index > 0){
                return images[index - 1];
            }
        }else{
            if (index > 0){
                return [children[index - 1] previousImageNodeOfImageAtIndex:NSNotFound senderIsImageNode:NO];
            }else if (images){
                return [images.lastObject imageNode];
            }
        }
    }
    return [parent previousImageNodeOfImageAtIndex:indexInParent senderIsImageNode:NO];
}

- (PathNode*) nextFolderNode
{
    if (imagePath){
        return [parent nextFolderNode];
    }else{
        return [parent nextFolderNodeOfNodeAtIndex:indexInParent];
    }
}

- (PathNode*) nextFolderNodeOfNodeAtIndex:(NSUInteger)index
{
    if (index + 1 < children.count){
        return children[index + 1];
    }else{
        return [parent nextFolderNodeOfNodeAtIndex:indexInParent];
    }
}

- (PathNode*) previousFolderNode
{
    if (imagePath){
        return [parent previousFolderNode];
    }else{
        return [parent previousFolderNodeOfNodeAtIndex:indexInParent];
    }
}

- (PathNode*) previousFolderNodeOfNodeAtIndex:(NSUInteger)index
{
    if (index > 0){
        return children[index - 1];
    }else{
        return self;
    }
}


//-----------------------------------------------------------------------------------------
// IndexPath生成
//-----------------------------------------------------------------------------------------
- (NSIndexPath*) indexPath
{
    NSUInteger* indexes = nil;
    NSUInteger size = [self generateIndexesInArray:&indexes withContext:1];
    NSIndexPath* indexPath = [NSIndexPath indexPathWithIndexes:indexes length:size];
    free(indexes);
    return indexPath;
}

- (NSUInteger) generateIndexesInArray:(NSUInteger**)array withContext:(NSUInteger)count
{
    if (parent){
        NSUInteger position = [parent generateIndexesInArray:array withContext:count + 1];
        if (*array){
            (*array)[position] = indexInParent;
        }
        return position + 1;
    }else{
        *array = malloc(sizeof(NSUInteger) * count);
        if (*array){
            (*array)[0] = 0;
        }
        return 1;
    }
}

@end
