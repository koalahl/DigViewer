//
//  NSView+ViewControllerAssociation_.m
//  DigViewer
//
//  Created by opiopan on 2013/01/12.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "NSView+ViewControllerAssociation.h"

@implementation NSView (ViewControllerAssociation)

- (void) associateSubViewWithController:(NSViewController*)controller
{
    NSView* subView = controller.view;
    subView.frame = self.frame;
    [subView setFrameOrigin:NSZeroPoint];
    [self addSubview:subView];
}

@end
