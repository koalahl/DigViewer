//
//  ThumbnailConfigController.h
//  DigViewer
//
//  Created by opiopan on 2015/04/26.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

enum FolderThumbnailRepresentationType{
    FolderThumbnailIconOnImage = 0,
    FolderThumbnailImageInIcon,
    FolderThumbnailOnlyImage
};

@interface ThumbnailConfigController : NSObject

@property (weak, nonatomic) id delegate;

@property (strong, nonatomic) NSNumber* updateCount;

@property (strong, nonatomic) NSNumber* defaultSize;
@property (assign, nonatomic) enum FolderThumbnailRepresentationType representationType;
@property (assign, readonly, nonatomic) BOOL isVisibleFolderIcon;
@property (strong, nonatomic) NSNumber* folderIconSize;
@property (strong, nonatomic) NSNumber* folderIconSizeRepresentation;
@property (strong, nonatomic) NSNumber* folderIconOpacity;
@property (strong, nonatomic) NSNumber* folderIconOpacityRepresentation;
@property (assign, nonatomic) BOOL useEmbeddedThumbnail;
@property (assign, nonatomic) BOOL useEmbeddedThumbnailForRAW;

+ (id) sharedController;

- (void) loadDefaults;
- (void) resetDefaults;

@end
