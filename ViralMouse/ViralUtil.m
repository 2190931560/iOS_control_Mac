//
//  ViralUtil.m
//  ViralMouse
//
//  Created by dlleng on 2018/3/24.
//  Copyright © 2018年 leng. All rights reserved.
//

#import "ViralUtil.h"

@implementation ViralUtil

+(void)PostMouseMove:(CGPoint)offsetPoint      //移动鼠标
{
    CGPoint currentPoint = CGEventGetLocation(CGEventCreate(NULL));
    currentPoint = CGPointMake(currentPoint.x+offsetPoint.x, currentPoint.y+offsetPoint.y);
    [self PostMouseEvent:kCGMouseButtonLeft type:kCGEventMouseMoved point:currentPoint];
}
+(void)PostScrollEvent:(CGPoint)offsetPoint    //2个手指scroll
{
    CGEventRef theEvent = CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 2, 2*offsetPoint.y,2*offsetPoint.x);
    CGEventPost(kCGHIDEventTap, theEvent);
    CFRelease(theEvent);
}
+(void)PostDragEvent:(CGPoint)offsetPoint      //按住左键的拖动
{
    CGPoint currentPoint = CGEventGetLocation(CGEventCreate(NULL));
    currentPoint = CGPointMake(currentPoint.x+offsetPoint.x, currentPoint.y+offsetPoint.y);
    CGEventRef theEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDragged, currentPoint, kCGMouseButtonLeft);
    CGEventSetType(theEvent, kCGEventLeftMouseDragged);
    CGEventPost(kCGHIDEventTap, theEvent);
    CFRelease(theEvent);
}
+(void)PostLButtonUp                           //左键抬起
{
    [self PostMouseEvent:kCGMouseButtonLeft type:kCGEventLeftMouseUp];
}
+(void)PostLButtonDown                         //左键按下
{
    [self PostMouseEvent:kCGMouseButtonLeft type:kCGEventLeftMouseDown];
}
+(void)PostLButtonClick                        //左键单击
{
    CGEventRef theEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, CGEventGetLocation(CGEventCreate(NULL)), kCGMouseButtonLeft);
    CGEventSetIntegerValueField(theEvent, kCGMouseEventClickState, 1);
    CGEventPost(kCGHIDEventTap, theEvent);
    CGEventSetType(theEvent, kCGEventLeftMouseUp);
    CGEventPost(kCGHIDEventTap, theEvent);
    CFRelease(theEvent);
}
+(void)PostLButtonDoubleClick                  //左键双击
{
    CGEventRef theEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, CGEventGetLocation(CGEventCreate(NULL)), kCGMouseButtonLeft);
    CGEventSetIntegerValueField(theEvent, kCGMouseEventClickState, 2);
    CGEventPost(kCGHIDEventTap, theEvent);
    CGEventSetType(theEvent, kCGEventLeftMouseUp);
    CGEventPost(kCGHIDEventTap, theEvent);
    CGEventSetType(theEvent, kCGEventLeftMouseDown);
    CGEventPost(kCGHIDEventTap, theEvent);
    CGEventSetType(theEvent, kCGEventLeftMouseUp);
    CGEventPost(kCGHIDEventTap, theEvent);
    CFRelease(theEvent);
}
+(void)PostLButtonTrebleClick                  //左键三击
{
    CGEventRef theEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, CGEventGetLocation(CGEventCreate(NULL)), kCGMouseButtonLeft);
    CGEventSetIntegerValueField(theEvent, kCGMouseEventClickState, 3);
    CGEventPost(kCGHIDEventTap, theEvent);
    CGEventSetType(theEvent, kCGEventLeftMouseUp);
    CGEventPost(kCGHIDEventTap, theEvent);
    CGEventSetType(theEvent, kCGEventLeftMouseDown);
    CGEventPost(kCGHIDEventTap, theEvent);
    CGEventSetType(theEvent, kCGEventLeftMouseUp);
    CGEventPost(kCGHIDEventTap, theEvent);
    CGEventSetType(theEvent, kCGEventLeftMouseDown);
    CGEventPost(kCGHIDEventTap, theEvent);
    CGEventSetType(theEvent, kCGEventLeftMouseUp);
    CGEventPost(kCGHIDEventTap, theEvent);
    CFRelease(theEvent);
}
+(void)PostRButtonClick                        //右键单击
{
    CGEventRef theEvent = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, CGEventGetLocation(CGEventCreate(NULL)), kCGMouseButtonRight);
    CGEventSetIntegerValueField(theEvent, kCGMouseEventClickState, 1);
    CGEventPost(kCGHIDEventTap, theEvent);
    CGEventSetType(theEvent, kCGEventRightMouseUp);
    CGEventPost(kCGHIDEventTap, theEvent);
    CFRelease(theEvent);
}

//////////////////////////////////////////////////////////////////////////////////



+(void)PostMouseEvent:(CGMouseButton)button type:(CGEventType)type
{
    CGEventRef theEvent = CGEventCreateMouseEvent(NULL, type, CGEventGetLocation(CGEventCreate(NULL)), button);
    CGEventSetType(theEvent, type);
    CGEventPost(kCGHIDEventTap, theEvent);
    CFRelease(theEvent);
}

+(void)PostMouseEvent:(CGMouseButton) button type:(CGEventType) type point:(CGPoint)point
{
    CGEventRef theEvent = CGEventCreateMouseEvent(NULL, type, point, button);
    CGEventSetType(theEvent, type);
    CGEventPost(kCGHIDEventTap, theEvent);
    CFRelease(theEvent);
}

+(void)writeString:(NSString *)valueToSet withFlags:(int)flags
{
    UniChar buffer;
    CGEventRef keyEventDown = CGEventCreateKeyboardEvent(NULL, 1, true);
    CGEventRef keyEventUp = CGEventCreateKeyboardEvent(NULL, 1, false);
    CGEventSetFlags(keyEventDown,0);
    CGEventSetFlags(keyEventUp,0);
    for (int i = 0; i < [valueToSet length]; i++) {
        [valueToSet getCharacters:&buffer range:NSMakeRange(i, 1)];
        CGEventKeyboardSetUnicodeString(keyEventDown, 1, &buffer);
        CGEventSetFlags(keyEventDown,flags);
        CGEventPost(kCGSessionEventTap, keyEventDown);
        CGEventKeyboardSetUnicodeString(keyEventUp, 1, &buffer);
        CGEventSetFlags(keyEventUp,flags);
        CGEventPost(kCGSessionEventTap, keyEventUp);
        
    }
    CFRelease(keyEventUp);
    CFRelease(keyEventDown);
}

@end
