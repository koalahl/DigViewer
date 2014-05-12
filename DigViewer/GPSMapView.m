//
//  GPSMapView.m
//  DigViewer
//
//  Created by opiopan on 2014/03/30.
//  Copyright (c) 2014年 opiopan. All rights reserved.
//

#import "GPSMapView.h"
#import "NSColor+JavascriptColorSpace.h"
#include <math.h>

@implementation GPSMapView{
    BOOL        _hasBeenLoaded;
    NSString*   _apiKey;
    GPSInfo*    _gpsInfo;
    NSColor*    _fovColor;
    NSColor*    _arrowColor;
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    if (aSelector == @selector(onLoad)) return NO;
    if (aSelector == @selector(reflectGpsInfo)) return NO;
    return YES;
}

- (NSString*) apiKey
{
    return _apiKey;
}

- (void) setApiKey:(NSString *)apiKey
{
    _apiKey = [apiKey copy];
    
    if (!_hasBeenLoaded){
        self.UIDelegate = self;
        WebScriptObject* win = [self windowScriptObject];
        [win setValue:self forKey:@"digViewerBridge"];
        
        NSString* htmlString = @
            "<!DOCTYPE html>"
            "<html>"
            "   <head>"
            "       <meta class=\"DigViewer\" name=\"viewport\" content=\"initial-scale=1.0, user-scalable=no\" />"
            "       <style class=\"DigViewer\" type=\"text/css\">"
            "           html { height: 100%% }"
            "           body { height: 100%%; margin: 0; padding: 0 }"
            "           #map_canvas { height: 100%% }"
            "       </style>"
            "       <script class=\"DigViewer\" type=\"text/javascript\" src=\"GPSMapView.js\"></script>"
            "   </head>"
            "   <body>"
            "       <div id=\"base\">"
            "           <div id=\"map_canvas\" style=\"width:100%%; height:100%%\">loading...</div>"
            "       </div>"
            "   </body>"
            "</html>";
        [[self mainFrame] loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] resourceURL]];
    }else{
        [self onLoad];
    }
}

- (void)onLoad
{
    NSString* script = [NSString stringWithFormat:@"setKey(\"%@\")", _apiKey];
    [[self windowScriptObject] evaluateWebScript:script];
}

- (GPSInfo*) gpsInfo
{
    return _gpsInfo;
}

- (void) setGpsInfo:(GPSInfo *)gpsInfo
{
    _gpsInfo = gpsInfo;
    WebScriptObject* window = [self windowScriptObject];
    NSString* script = nil;
    if (_gpsInfo){
        double FOVangle = -1;
        double FOVscale = 0;
        if (gpsInfo.focalLengthIn35mm){
            double sensorSize = _gpsInfo.rotation.integerValue < 5 ? 36.0 / 2.0 : 24.0 / 2.0;
            FOVangle = atan(sensorSize / _gpsInfo.focalLengthIn35mm.doubleValue);
            FOVscale = 1.0 / cos(FOVangle);
            FOVangle = FOVangle * (180 / M_PI);
        }
        script = [NSString stringWithFormat:@"setMarker(%@, %@, %@, %f, %f, %@, %@);",
                  _gpsInfo.latitude, _gpsInfo.longitude,
                  _gpsInfo.imageDirection ? _gpsInfo.imageDirection : @"null",
                  FOVangle, FOVscale,
                  _fovColor ? [_fovColor javascriptColor] : @"null",
                  _arrowColor ? [_arrowColor javascriptColor] : @"null"];
    }else{
        script = @"resetMarker();";
    }
    [window evaluateWebScript:script];
}

- (NSColor*) fovColor
{
    return _fovColor;
}

- (void) setFovColor:(NSColor *)fovColor
{
    _fovColor = [fovColor copy];
    self.gpsInfo = _gpsInfo;
}

- (NSColor*) arrowColor
{
    return _arrowColor;
}

- (void) setArrowColor:(NSColor *)arrowColor
{
    _arrowColor = [arrowColor copy];
    self.gpsInfo = _gpsInfo;
}

- (void) reflectGpsInfo
{
    if (_gpsInfo){
        self.gpsInfo = _gpsInfo;
    }
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame:frameRect];
    WebScriptObject* window = [self windowScriptObject];
    [window evaluateWebScript:@"setHeading();"];
}

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame
{
    NSLog(@"Javascript: %@\n", message);
}

@end
