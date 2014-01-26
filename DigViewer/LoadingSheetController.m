//
//  LoadingSheetController.m
//  DigViewer
//
//  Created by opiopan on 2013/01/09.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "LoadingSheetController.h"
#import "PathNode.h"

@implementation LoadingSheetController{
    NSString*                  path;
    PathNode*                  root;
    PathNodeProgress*          pathNodeProgress;
    NSWindow*                  modalWindow;
    id                         modalDelegate;
    SEL                        didEndSelector;
    PathNodeOmmitingCondition* condition;
}

@synthesize phase;
@synthesize targetFolder;
@synthesize isIndeterminate;
@synthesize progress;
@synthesize panel;
@synthesize progressIndicator;

- (id)init
{
    self = [super init];
    if (self) {
        pathNodeProgress = [[PathNodeProgress alloc] init];
        isIndeterminate = YES;
        progress = [NSNumber numberWithDouble:0.0];
        [NSBundle loadNibNamed:@"LoadingSheet" owner:self];
    }
    
    return self;
}

- (void) loadPath:(NSString*)p forWindow:(NSWindow*)window modalDelegate:(id)delegate didEndSelector:(SEL)selector
        condition:(PathNodeOmmitingCondition*)cond;
{
    path = p;
    modalWindow = window;
    modalDelegate = delegate;
    didEndSelector = selector;
    condition = cond;
    
    [self performSelectorInBackground:@selector(loadPinnedFileInBackground) withObject:nil];
    [self performSelector:@selector(showPanel) withObject:nil afterDelay:0.5f];
}

- (void) awakeFromNib
{
    [progressIndicator startAnimation:self];
}

- (void) loadPinnedFileInBackground
{
    @autoreleasepool {
        self.phase = NSLocalizedString(@"Now loading a pinned file in the folder:", nil);
        self.targetFolder = path;
        PathfinderPinnedFile* pinnedFile = [PathfinderPinnedFile pinnedFileWithPath:path];
        if (pinnedFile){
            self.phase = NSLocalizedString(@"Now recognizing a pinned file in the folder:", nil);
            self.isIndeterminate = NO;
            root = [PathNode pathNodeWithPinnedFile:pinnedFile ommitingCondition:condition progress:pathNodeProgress];
        }else{
            self.phase = NSLocalizedString(@"Now searching image files in the folder:", nil),
            root = [PathNode pathNodeWithPath:path  ommitingCondition:condition progress:pathNodeProgress];
        }
        [self performSelectorOnMainThread:@selector(didEndLoading) withObject:nil waitUntilDone:NO];
    }
}

- (void) didEndLoading{
    [panel close];
    [modalDelegate performSelector:didEndSelector withObject:root afterDelay:0.0f];
    panel = nil;
}

- (void) showPanel
{
    if (panel && pathNodeProgress.progress < 0.5){
        [[NSApplication sharedApplication] beginSheet:panel
                                       modalForWindow:modalWindow
                                        modalDelegate:nil
                                       didEndSelector:nil
                                          contextInfo:nil];
        [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.1f];
    }
}

- (void) updateProgress{
    self.progress = [NSNumber numberWithDouble:pathNodeProgress.progress];
    NSString* newTarget = pathNodeProgress.target;
    if (newTarget && ![newTarget isEqual:self.targetFolder]){
        self.targetFolder = newTarget;
    }
    if (panel){
        [self performSelector:@selector(updateProgress) withObject:nil afterDelay:0.1f];
    }
}

- (IBAction)onCancel:(id)sender {
    pathNodeProgress.isCanceled = YES;
}

@end
