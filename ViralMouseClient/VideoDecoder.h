//
//  VideoDecoder.h
//  ViralMouseClient
//
//  Created by dlleng on 2018/3/30.
//  Copyright © 2018年 leng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OpenGLLayer.h"

@interface VideoDecoder : NSObject
@property(nonatomic,weak)OpenGLLayer *glLayer;

+(instancetype)share;

-(void)decodeBuffer:(char*)buffer length:(long)size;

@end
