//
//  PreferencesDefaultsController.m
//  DigViewer
//
//  Created by opiopan on 2014/04/30.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "PreferencesDefaultsController.h"

@implementation PreferencesDefaultsController

+ (NSDictionary *)defaultValues
{
    static NSDictionary* defaults = nil;
    if (!defaults){
        NSData* blackData = [NSArchiver archivedDataWithRootObject:[NSColor blackColor]];
        NSData* redData = [NSArchiver archivedDataWithRootObject:[NSColor redColor]];
        NSArray* zeroArray = [NSArray array];
        defaults = @{@"imageSetType":                 @0,
                     @"imageSetMaxFileSize":          @5,
                     @"imageSetMaxFileSizeMin":       @0.1,
                     @"imageSetOmittingExt":          zeroArray,
                     @"imageBackgroundColor":         blackData,
                     @"gestureEnable":                @YES,
                     @"slideshowInterval":            @5,
                     @"slideshowIntervalMin":         @0.5,
                     @"slideshowIntervalDef":         @5,
                     @"mapFovColor":                  redData,
                     @"mapArrowColor":                redData,
                     @"mapFovGrade":                  @30,
                     @"mapFovGradeMin":               @1,
                     @"mapFovGradeMax":               @100,
                     @"mapType":                      @0,
                     @"mapEnableStreetView":          @YES,
                     @"mapMoveToHomePos":             @YES,
                     @"dndEnable":                    @YES,
                     @"dndMultiple":                  @YES,
                     @"defImageViewType":             @0,
                     @"defFitToWindow":               @YES,
                     @"defShowNavigator":             @YES,
                     @"defShowInspector":             @NO,
                     @"thumbDefaultSize":             @100,
                     @"thumbRepresentationType":      @0,
                     @"thumbFolderSize":              @(1./3.),
                     @"thumbFolderOpacity":           @1.0,
                     @"pathNodeSortType":             @0,
                     @"pathNodeSortCaseInsensitive":  @YES,
                     @"pathNodeSortAsNumeric":        @YES,
                     @"pathNodeSortByDateTime":       @NO};
    }
    return defaults;
}

- (id)init
{
    self = [super init];
    if (self){
        NSDictionary* defaults = [PreferencesDefaultsController defaultValues];
        [[[NSUserDefaultsController sharedUserDefaultsController] defaults] registerDefaults:defaults];
    }
    return self;
}

@end
