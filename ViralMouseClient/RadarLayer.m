//
//  RadarLayer.m
//  ViralMouseClient
//
//  Created by dlleng on 2018/3/29.
//  Copyright © 2018年 leng. All rights reserved.
//
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define MAX_LIFE 60;

@interface DrawModel : NSObject
@property(assign)CGPoint point;
@property(assign)int life;

@end
@implementation DrawModel
@end



#import "RadarLayer.h"
@interface RadarLayer()
{
    CADisplayLink *displayLink;
}
@property(atomic,strong)NSMutableArray *array;
@end
@implementation RadarLayer

-(void)tap:(CGPoint)point
{
    if(!self.array)
        self.array = [NSMutableArray array];
    @synchronized(self)
    {
        DrawModel *draw = [[DrawModel alloc] init];
        draw.point = point;
        draw.life = MAX_LIFE;
        [self.array addObject:draw];
    }
    
    
    if(!displayLink){
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerAction:)];
        displayLink.preferredFramesPerSecond = 30;
        //将定时器添加到runloop中
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
    }
}
-(void)timerAction:(id)sender
{
    [self setNeedsDisplay];
    //NSLog(@"timer");
}
-(void)drawInContext:(CGContextRef)ctx
{
    if(!self.array)
        self.array = [NSMutableArray array];
    @synchronized(self)
    {
        for(int i=0;i<self.array.count;i++)
        {
            DrawModel *draw = self.array[i];
            draw.life--;
            float w = 600 - draw.life*10.0;
            CGContextAddEllipseInRect(ctx, CGRectMake(draw.point.x-w, draw.point.y-w, w*2, w*2));
            //设置属性（颜色）
            //[[UIColor colorWithWhite:1 alpha:draw.life/60.0] set];
            //CGContextSetRGBFillColor(ctx, 0, 0, 1, 1);
            CGContextSetRGBStrokeColor(ctx, 1, 1, 1, draw.life/60.0);
            CGContextSetLineWidth(ctx, 3);
            //2.渲染
            //CGContextFillPath(ctx);
            CGContextStrokePath(ctx);
            if(draw.life<=0)
                [self.array removeObject:draw];
        }
        
        if(self.array.count == 0 && displayLink)
        {
            [displayLink invalidate];
            displayLink = nil;
        }
    }
    
}

@end
