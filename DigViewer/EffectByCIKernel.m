//
//  EffectByCIKernel.m
//  DigViewer
//
//  Created by opiopan on 2015/06/23.
//  Copyright (c) 2015年 opiopan. All rights reserved.
//

#import "EffectByCIKernel.h"

//=========================================================================================
// フラグメントシェーダーを駆動するカスタムCIFilterの実装
//=========================================================================================
@interface FilterForTransition : CIFilter <NSCopying>
@property (nonatomic) CIImage* inputImage;
@property (nonatomic) CIImage* inputTargetImage;
@property (nonatomic) NSNumber* inputTime;
- (instancetype)initWithShaderPath:(NSString*)path;
@end

@implementation FilterForTransition{
    CIKernel* _kernel;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)initWithShaderPath:(NSString *)path
{
    self = [self init];
    if (self){
        NSError* error;
        NSString* kernelProgram = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
        _kernel = [CIKernel kernelWithString:kernelProgram];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// コピー
//-----------------------------------------------------------------------------------------
- (id)copyWithZone:(NSZone *)zone
{
    FilterForTransition* copy = [super copyWithZone:zone];
    if (copy){
        copy->_kernel = self->_kernel;
        copy->_inputImage = self->_inputImage;
        copy->_inputTargetImage = self->_inputTargetImage;
        copy->_inputTime = self->_inputTime;
    }
    
    return copy;
}

//-----------------------------------------------------------------------------------------
// 遷移イメージ生成
//-----------------------------------------------------------------------------------------
- (CIImage *)outputImage
{
    return [self apply:_kernel, _inputImage, _inputTargetImage, _inputTime,
                       kCIApplyOptionDefinition, _inputImage.definition, nil];
}

@end

//=========================================================================================
// EffectByCIKernelの実装
//=========================================================================================
@implementation EffectByCIKernel{
    FilterForTransition* _filter;
}

//-----------------------------------------------------------------------------------------
// 初期化
//-----------------------------------------------------------------------------------------
- (instancetype)initWithShaderPath:(NSString *)path duration:(CGFloat)duration
{
    self = [self init];
    if (self){
        self.duration = duration;
        _filter = [[FilterForTransition alloc] initWithShaderPath:path];
    }
    return self;
}

//-----------------------------------------------------------------------------------------
// filte返却
//-----------------------------------------------------------------------------------------
- (CIFilter *)filter
{
    return _filter;
}

@end
