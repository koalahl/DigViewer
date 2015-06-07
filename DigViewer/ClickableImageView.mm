//
//  ClickableImageView.m
//  DigViewer
//
//  Created by opiopan on 2013/01/17.
//  Copyright (c) 2013年 opiopan. All rights reserved.
//

#import "ClickableImageView.h"
#import "ImageRenderer.h"
#import "ImageFrameLayer.h"
#import "TwoFingerGestureRecognizer.h"
#include "CoreFoundationHelper.h"

@implementation ClickableImageView{
    ImageRenderer* _renderer;
    NSColor* _backgroundColor;
    CGFloat _scale;
    
    ImageFrameLayer* _frameLayer;
    NSMutableArray* _touchGestureRecognizers;
    NSPoint _panningBaias;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self){
        [self initialize];
    }
    return self;
}

- (void)awakeFromNib
{
    [self initialize];
}

- (void)initialize
{
    _relationalImageAccessor = [RelationalImageAccessor new];
    
    self.isDrawingByLayer = NO;
    
    _touchGestureRecognizers = [NSMutableArray array];
    TwoFingerGestureRecognizer* twoFIngerGestureRecognizer = [TwoFingerGestureRecognizer new];
    twoFIngerGestureRecognizer.view = self;
    twoFIngerGestureRecognizer.magnifyGestureHandler = @selector(handleMagnifyGesture:);
    twoFIngerGestureRecognizer.panGestureHandler = @selector(handleTwoFingerPanGesture:);
    [_touchGestureRecognizers addObject:twoFIngerGestureRecognizer];
    
    [self setAcceptsTouchEvents:YES];
}

//-----------------------------------------------------------------------------------------
// 画像登録
//-----------------------------------------------------------------------------------------
- (void)setRelationalImage:(id)relationalImage
{
    if (_relationalImage != relationalImage){
        _relationalImage = relationalImage;
        if (_relationalImage){
            _renderer = [ImageRenderer imageRendererWithPath:[_relationalImageAccessor imagePathOfObject:_relationalImage]];
        }else{
            _renderer = [ImageRenderer imageRendererWithPath:nil];
        }
        _scale = 1.0;
        [self displayIfNeeded];
        self.needsDisplay = true;
        if (_isDrawingByLayer){
            [_frameLayer setImage:_renderer.image withRotation:_renderer.rotation];
        }
    }else{
        self.zoomRatio = 1.0;
    }
}

//-----------------------------------------------------------------------------------------
// 描画方法指定
//-----------------------------------------------------------------------------------------
- (void)setIsDrawingByLayer:(BOOL)isDrawingByLayer
{
    _isDrawingByLayer = isDrawingByLayer;
    if (_isDrawingByLayer){
        _frameLayer = [ImageFrameLayer layer];
        _frameLayer.delegate = self;
        _frameLayer.bounds = [self bounds];
        _frameLayer.needsDisplayOnBoundsChange = NO;
        _frameLayer.backgroundColor = _backgroundColor.CGColor;
        _frameLayer.isFitFrame = self.imageScaling == NSImageScaleProportionallyDown;
        _frameLayer.magnificationFilter = [self CALayerFilterTypeFromImageViewFilterType:_magnificationFilter];
        _frameLayer.minificationFilter = [self CALayerFilterTypeFromImageViewFilterType:_minificationFilter];
        [_frameLayer setImage:_renderer.image withRotation:_renderer.rotation];
        [_frameLayer setNeedsDisplay];
        [self setLayer:_frameLayer];
        [self setWantsLayer:YES];
    }else{
        [self setLayer:nil];
        [self setWantsLayer:NO];
        _frameLayer = nil;
    }
    [self display];
}

//-----------------------------------------------------------------------------------------
// 属性設定
//-----------------------------------------------------------------------------------------
- (void)setImageScaling:(NSImageScaling)imageScaling
{
    [super setImageScaling:imageScaling];
    if (_isDrawingByLayer){
        _frameLayer.isFitFrame = self.imageScaling == NSImageScaleProportionallyDown;
    }
}

- (void)setBackgroundColor:(NSColor *)value
{
    _backgroundColor = value;
    if (_isDrawingByLayer){
        _frameLayer.backgroundColor = _backgroundColor.CGColor;
    }
    [self display];
}

- (void)setMagnificationFilter:(ImageViewFilterType)magnificationFilter
{
    _magnificationFilter = magnificationFilter;
    if (_isDrawingByLayer){
        _frameLayer.magnificationFilter = [self CALayerFilterTypeFromImageViewFilterType:_magnificationFilter];
    }
}

- (void)setMinificationFilter:(ImageViewFilterType)minificationFilter
{
    _minificationFilter = minificationFilter;
    if (_isDrawingByLayer){
        _frameLayer.minificationFilter = [self CALayerFilterTypeFromImageViewFilterType:_minificationFilter];
    }
}

- (CGFloat)zoomRatio
{
    return _isDrawingByLayer ? _frameLayer.scale : 1.0;
}

- (void)setZoomRatio:(CGFloat)zoomRatio
{
    if (_isDrawingByLayer){
        _frameLayer.scale = zoomRatio;
    }
}

//-----------------------------------------------------------------------------------------
// ImageViewFilterTypeからCALayerのフィルタータイプへの変換
//-----------------------------------------------------------------------------------------
- (NSString*)CALayerFilterTypeFromImageViewFilterType:(ImageViewFilterType)type
{
    return type == ImageViewFilterBilinear  ? kCAFilterLinear :
           type == ImageViewFilterTrilinear ? kCAFilterTrilinear :
                                              kCAFilterNearest;
}


//-----------------------------------------------------------------------------------------
// イベント処理
//-----------------------------------------------------------------------------------------
- (void)mouseDown:(NSEvent *)theEvent
{
    // editable = YESの場合、NSImageViewはmouseDownでマウスをキャプチャしてしまい
    // mouseUpイベントが到達しないため、オーバライドする
}

- (void)mouseUp:(NSEvent*)event
{
    if([event clickCount] == 2) {
        [self.delegate performSelector:@selector(onDoubleClickableImageView:) withObject:self afterDelay:0.0f];
    }
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    // editable = YES時のドロップインを抑止
    return NSDragOperationNone;
}

//-----------------------------------------------------------------------------------------
// タッチイベントをジェスチャーリコグナイザーに回送
//-----------------------------------------------------------------------------------------
- (void)touchesBeganWithEvent:(NSEvent *)event
{
    [_touchGestureRecognizers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)touchesMovedWithEvent:(NSEvent *)event
{
    [_touchGestureRecognizers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)touchesEndedWithEvent:(NSEvent *)event
{
    [_touchGestureRecognizers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)touchesCancelledWithEvent:(NSEvent *)event
{
    [_touchGestureRecognizers makeObjectsPerformSelector:_cmd withObject:event];
}

- (void)magnifyWithEvent:(NSEvent *)event
{
    [_touchGestureRecognizers makeObjectsPerformSelector:_cmd withObject:event];
}

//-----------------------------------------------------------------------------------------
// ジェスチャー処理
//-----------------------------------------------------------------------------------------
static const CGFloat MagnificationGestureScale = 5.0;
static const CGFloat PanningGestureScale = 4.0;

- (void)handleMagnifyGesture:(TwoFingerGestureRecognizer*)gesture
{
    if (_isDrawingByLayer){
        NSPoint pointer = gesture.initialPoint;
        pointer.x -= self.frame.size.width / 2;
        pointer.y -= self.frame.size.height / 2;
        CGPoint origin = _frameLayer.offset;
        origin.x -= pointer.x;
        origin.y -= pointer.y;
        origin.x /= (_frameLayer.scale * _frameLayer.transisionalScale);
        origin.y /= (_frameLayer.scale * _frameLayer.transisionalScale);
        
        CGFloat magnification = gesture.magnification * MagnificationGestureScale;
        CGFloat transisionalScale;
        if (magnification > 0){
            transisionalScale = (1.0 + magnification);
        }else{
            transisionalScale = 1.0 / (1  - magnification);
        }
        if (transisionalScale * _frameLayer.scale < 1.0){
            CGFloat compensatedScale = (transisionalScale * _frameLayer.scale - 1.0) * 0.25 + 1.0;
            transisionalScale = compensatedScale / _frameLayer.scale;
        }
        
        origin.x *= (_frameLayer.scale * transisionalScale);
        origin.y *= (_frameLayer.scale * transisionalScale);
        origin.x += pointer.x;
        origin.y += pointer.y;
        
        [_frameLayer setTransisionalScale:transisionalScale withOffset:origin];
        
        if (gesture.state == TouchGestureStateEnded ||
            gesture.state == TouchGestureStateCanceled ||
            gesture.state == TouchGestureStateFailed){
            [_frameLayer fixScale];
        }
    }
}

- (void)handleTwoFingerPanGesture:(TwoFingerGestureRecognizer*)gesture
{
    if (_isDrawingByLayer){
        if (gesture.state == TouchGestureStateBegan){
            _panningBaias = [_frameLayer startPanning];
        }
        
        CGPoint offset = gesture.panningDelta;
        offset.x = offset.x * PanningGestureScale + _panningBaias.x;
        offset.y = offset.y * PanningGestureScale + _panningBaias.y;
        
        _frameLayer.transisionalOffset = offset;
        
        if (gesture.state == TouchGestureStateEnded ||
            gesture.state == TouchGestureStateCanceled ||
            gesture.state == TouchGestureStateFailed){
            CGPoint velocity = gesture.panningVelocity;
            velocity.x *= PanningGestureScale;
            velocity.y *= PanningGestureScale;
            [_frameLayer fixOffsetWithVelocity:velocity];
        }
    }
}

//-----------------------------------------------------------------------------------------
// 描画 (Layerモードの場合は本メソッドは呼び出されない)
//-----------------------------------------------------------------------------------------
- (void)drawRect:(NSRect)dirtyRect
{
    if (_isDrawingByLayer){
        return;
    }
    
    [self.backgroundColor setFill];
    NSRectFill(dirtyRect);
    
    if (!_renderer.image){
        return;
    }
    
    if (![[_renderer.image class] isSubclassOfClass:NSImage.class]){
        CGImageRef cgimage = (__bridge CGImageRef)_renderer.image;
        NSInteger rotation = _renderer.rotation;
        NSRect boundsRect = self.bounds;
        CGSize orgSize = CGSizeMake(CGImageGetWidth(cgimage), CGImageGetHeight(cgimage));
        CGSize imageSize;
        if (rotation >= 5 && rotation <=8){
            imageSize = CGSizeMake(CGImageGetHeight(cgimage), CGImageGetWidth(cgimage));
        }else{
            imageSize = CGSizeMake(CGImageGetWidth(cgimage), CGImageGetHeight(cgimage));
        }
        CGFloat xRatio = boundsRect.size.width / imageSize.width;
        CGFloat yRatio = boundsRect.size.height / imageSize.height;
        CGFloat ratio;
        if (xRatio >= 1.0 && yRatio >= 1.0 && self.imageScaling == NSImageScaleProportionallyDown){
            ratio = 1.0;
        }else{
            ratio = xRatio > yRatio ? yRatio : xRatio;
        }
        CGFloat xOffset = (boundsRect.size.width - imageSize.width * ratio) / 2;
        CGFloat yOffset = (boundsRect.size.height - imageSize.height * ratio) / 2;
        CGContextRef context = reinterpret_cast<CGContext*>([[NSGraphicsContext currentContext] graphicsPort]);
        switch (rotation){
            case 1:
            case 2:
                /* no rotation */
                CGContextTranslateCTM (context, xOffset, yOffset);
                break;
            case 5:
            case 8:
                /* 90 degrees rotation */
                CGContextRotateCTM(context, M_PI / 2.);
                CGContextTranslateCTM (context, yOffset, -xOffset - orgSize.height * ratio);
                break;
            case 3:
            case 4:
                /* 180 degrees rotation */
                CGContextRotateCTM(context, -M_PI);
                CGContextTranslateCTM (context, -xOffset - orgSize.width * ratio, -yOffset - orgSize.height * ratio);
                break;
            case 6:
            case 7:
                /* 270 degrees rotation */
                CGContextRotateCTM(context, -M_PI / 2.);
                CGContextTranslateCTM (context,  -yOffset - orgSize.width * ratio, xOffset);
                break;
        }
        CGContextScaleCTM(context, ratio, ratio);
        CGContextDrawImage(context, CGRectMake(0, 0, orgSize.width, orgSize.height), cgimage);
    }else{
        NSImage* image = _renderer.image;
        NSRect boundsRect = self.bounds;
        NSSize imageSize = image.size;
        CGFloat xRatio = boundsRect.size.width / imageSize.width;
        CGFloat yRatio = boundsRect.size.height / imageSize.height;
        CGFloat ratio;
        if (xRatio >= 1.0 && yRatio >= 1.0 && self.imageScaling == NSImageScaleProportionallyDown){
            ratio = 1.0;
        }else{
            ratio = xRatio > yRatio ? yRatio : xRatio;
        }
        NSRect imageRect;
        imageRect.size.width = imageSize.width * ratio;
        imageRect.size.height = imageSize.height * ratio;
        imageRect.origin.x = boundsRect.origin.x + (boundsRect.size.width - imageRect.size.width) / 2;
        imageRect.origin.y = boundsRect.origin.y + (boundsRect.size.height - imageRect.size.height) / 2;
        
        [image drawInRect:imageRect];
    }
}

@end
