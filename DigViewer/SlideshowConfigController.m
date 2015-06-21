//
//  SlideshowConfigController.m
//  DigViewer
//
//  Created by opiopan on 2015/05/08.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "SlideshowConfigController.h"
#import "TransitionEffects.h"

@implementation SlideshowConfigController{
    NSUserDefaultsController* _controller;
}

//-----------------------------------------------------------------------------------------
// シングルトンパターンの実装
//-----------------------------------------------------------------------------------------
+ (id)sharedController
{
    static SlideshowConfigController* sharedController = nil;
    
    if (!sharedController){
        sharedController = [[SlideshowConfigController alloc] init];
    }
    
    return sharedController;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)init
{
    self = [super init];
    if (self){
        _controller = [NSUserDefaultsController sharedUserDefaultsController];
        _updateCount = 0;
        _interval = [_controller.values valueForKey:@"slideshowInterval"];
        _transition = [[_controller.values valueForKey:@"slideshowTransition"] intValue];
        _viewType = [[_controller.values valueForKey:@"slideshowViewType"] intValue];
        _showOnTheOtherScreen = [[_controller.values valueForKey:@"slideshowShowOnTheOtherScreen"] boolValue];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// 属性の実装
//-----------------------------------------------------------------------------------------
- (void)setInterval:(NSNumber*)interval
{
    _interval = interval;
    [_controller.values setValue:_interval forKey:@"slideshowInterval"];
    if (!_interval){
        _interval = [_controller.values valueForKey:@"slideshowInterval"];
    }
    _updateCount++;
}

- (void)setTransition:(SlideshowTransition)transition
{
    _transition = transition;
    [_controller.values setValue:@(_transition) forKey:@"slideshowTransition"];
    _updateCount++;
}

- (void)setViewType:(SlideshowViewType)viewType
{
    _viewType = viewType;
    [_controller.values setValue:@(_viewType) forKey:@"slideshowViewType"];
    _updateCount++;
}

- (void)setShowOnTheOtherScreen:(BOOL)showOnTheOtherScreen
{
    _showOnTheOtherScreen = showOnTheOtherScreen;
    [_controller.values setValue:@(_showOnTheOtherScreen) forKey:@"slideshowShowOnTheOtherScreen"];
    _updateCount++;
}

//-----------------------------------------------------------------------------------------
// 遷移効果オブジェクトファクトリ
//-----------------------------------------------------------------------------------------
- (TransitionEffect*)transitionEffect
{
    static NSArray* effects;
    if (!effects){
        effects = @[[TransitionEffect new],
                    [[EffectByCATransition alloc] initWithType:SlideshowTransitionFade],
                    [[EffectByCATransition alloc] initWithType:SlideshowTransitionMoveIn],
                    [[EffectByCATransition alloc] initWithType:SlideshowTransitionPush],
                    [[EffectByCATransition alloc] initWithType:SlideshowTransitionReveal]];
    }
    return effects[_transition];
}

@end
