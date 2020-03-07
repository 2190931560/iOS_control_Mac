//
//  VideoEncoder.h
//  ViralMouse
//
//  Created by dlleng on 2018/3/30.
//  Copyright © 2018年 leng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoEncoder : NSObject

+(instancetype)share;
-(void)startEncode;
-(void)stopEncode;

@end
