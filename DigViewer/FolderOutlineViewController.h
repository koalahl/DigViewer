//
//  FolderOutlineView.h
//  DigViewer
//
//  Created by opiopan on 2013/01/12.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FolderOutlineViewController : NSViewController

@property (weak) IBOutlet NSTableView *imageTableView;
@property (weak) IBOutlet NSArrayController *imageArrayController;

@end
