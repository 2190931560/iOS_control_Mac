//
//  ViralUtil.h
//  ViralMouse
//
//  Created by dlleng on 2018/3/24.
//  Copyright © 2018年 leng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ViralUtil : NSObject


/////////////////////////////////////////////////////////////////////////////
+(void)PostMouseMove:(CGPoint)offsetPoint;      //移动鼠标
+(void)PostScrollEvent:(CGPoint)offsetPoint;    //2个手指scroll
+(void)PostDragEvent:(CGPoint)offsetPoint;      //按住左键的拖动
+(void)PostLButtonUp;                           //左键抬起
+(void)PostLButtonDown;                         //左键按下
+(void)PostLButtonClick;                        //左键单击
+(void)PostLButtonDoubleClick;                  //左键双击
+(void)PostLButtonTrebleClick;                  //左键三击
+(void)PostRButtonClick;                        //右键单击

+(void)writeString:(NSString *)valueToSet withFlags:(int)flags;

@end

