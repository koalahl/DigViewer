//
//  DVRemoteServer.h
//  DigViewer
//
//  Created by opiopan on 2015/09/04.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVRemoteProtcol.h"
#import "DVRemoteSession.h"

@protocol DVRemoteServerDelegate;

//-----------------------------------------------------------------------------------------
// DVRemoteServer宣言
//-----------------------------------------------------------------------------------------
@interface DVRemoteServer : NSObject <NSNetServiceDelegate, DVRemoteSessionDelegate>

@property (weak, nonatomic) id <DVRemoteServerDelegate> delegate;
@property (strong, nonatomic) NSRunLoop* runLoop;

+ (DVRemoteServer*)sharedServer;

- (BOOL)establishServer;
- (void)sendMeta:(NSDictionary*)meta;
- (void)sendThumbnail:(NSData*)thumbnail forNodeID:(NSArray*)nodeID inDocument:(NSString*)documentName;

@end

//-----------------------------------------------------------------------------------------
// デリゲートプロトコル
//-----------------------------------------------------------------------------------------
@protocol DVRemoteServerDelegate <NSObject>
- (void)dvrServer:(DVRemoteServer*)server needMoveToNeighborImageOfDocument:(NSString*)document
    withDirection:(DVRCommand)direction;
- (void)dvrServer:(DVRemoteServer*)server needSendThumbnails:(NSArray*)ids forDocument:(NSString*)document;
@end

