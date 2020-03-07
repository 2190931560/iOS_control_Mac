//
//  ViewController.m
//  ViralMouseClient
//
//  Created by dlleng on 2018/3/24.
//  Copyright © 2018年 leng. All rights reserved.
//

#import "MouseViewController.h"
//#import "UDPUtil.h"
#import "defines.h"
#import <math.h>
#import "TCPUtil.h"
#import "OpenGLLayer.h"
#import "VideoDecoder.h"

@interface MouseViewController ()
@property(weak)UIButton *btnBack;
@property(weak)UIButton *btnRotate;
@property(weak)OpenGLLayer *glLayer;

@end

@implementation MouseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    //单击
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singletap:)];
    tap.numberOfTouchesRequired = 1;
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
    //双击
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubletap:)];
    tap.numberOfTouchesRequired = 1;
    tap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tap];
    //三击
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(trebletap:)];
    tap.numberOfTouchesRequired = 1;
    tap.numberOfTapsRequired = 3;
    [self.view addGestureRecognizer:tap];
    //右击
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(righttap:)];
    tap.numberOfTouchesRequired = 2;
    tap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tap];
    
    //创建layer 显示视频
    OpenGLLayer *glLayer = [[OpenGLLayer alloc] initWithFrame:self.view.frame];
    [self.view.layer addSublayer:glLayer];
    self.glLayer = glLayer;
    [VideoDecoder share].glLayer = glLayer;
    
    //创建按钮
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 60, 60)];
    btn.backgroundColor = [UIColor blueColor];
    [btn addTarget:self action:@selector(btnBack:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"返回" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    self.btnBack = btn;
    
    btn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-20-30, 20, 60, 60)];
    btn.backgroundColor = [UIColor blueColor];
    [btn addTarget:self action:@selector(btnRotate:) forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:@"视频" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    self.btnRotate = btn;
}
-(void)btnBack:(UIButton*)button
{
    [[TCPUtil share] disconnect];
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)btnRotate:(UIButton*)button
{
    static BOOL b = true;
    if(b)
       [[TCPUtil share] sendEvent:vVideoStart withData:nil];
    else
        [[TCPUtil share] sendEvent:vVideoEnd withData:nil];
    b = !b;
    return;
    CGSize size = [UIScreen mainScreen].bounds.size;
    if(!button.selected)
    {
        [UIView animateWithDuration:0.7 animations:^{
            self.view.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.view.frame = CGRectMake(0, 0, size.width, size.height);
            self.btnBack.frame = CGRectMake(20, 20, 30, 30);
            self.btnRotate.frame = CGRectMake(size.height-20-30, 20, 30, 30);
        }];
        
    }
    else
    {
        [UIView animateWithDuration:0.7 animations:^{
            self.view.transform = CGAffineTransformIdentity;
            self.view.frame = CGRectMake(0, 0, size.width, size.height);
            self.btnBack.frame = CGRectMake(20, 20, 30, 30);
            self.btnRotate.frame = CGRectMake(size.width-20-30, 20, 30, 30);
        }];
        
    }
    
    button.selected = !button.selected;
}
//手势
-(void)singletap:(UITapGestureRecognizer*)tap
{
    //NSLog(@"单击");
    [[TCPUtil share] sendEvent:vMouseLButtonClick withData:nil];
}
-(void)doubletap:(UITapGestureRecognizer*)tap
{
    //NSLog(@"双击");
    [[TCPUtil share] sendEvent:vMouseLButtonDoubleClick withData:nil];
}
-(void)trebletap:(UITapGestureRecognizer*)tap
{
    //NSLog(@"三击");
    [[TCPUtil share] sendEvent:vMouseLButtonTrebleClick withData:nil];
}
-(void)righttap:(UITapGestureRecognizer*)tap
{
    //NSLog(@"右击");
    [[TCPUtil share] sendEvent:vMouseRButtonClick withData:nil];
}


long numOfTouchs = 0;
bool bDown = false;
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    bDown = false;
}
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    CGPoint p1 = [touch locationInView:self.view];
    CGPoint p2 = [touch previousLocationInView:self.view];
    float x = p1.x - p2.x;
    float y = p1.y - p2.y;
    float xy[2] = {x,y};
    NSData *data = [NSData dataWithBytes:xy length:sizeof(xy)];
    
    numOfTouchs = event.allTouches.count;
    if(numOfTouchs == 3 && bDown == false){
        [[TCPUtil share] sendEvent:vMouseLButtonDown withData:nil];
        bDown = true;
    }

    
    if(numOfTouchs == 1) //移动鼠标
    {
        [[TCPUtil share] sendEvent:vMouseMove withData:data];
    }
    else if(numOfTouchs == 2) //滚轮
    {
        [[TCPUtil share] sendEvent:vMouseScrollWheel withData:data];
    }
    else if(numOfTouchs == 3)//拖动
    {
        [[TCPUtil share] sendEvent:vMouseLButtonDraged withData:data];
    }
}
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if(bDown)
        [[TCPUtil share] sendEvent:vMouseLButtonUp withData:nil];
    numOfTouchs = 0;
}
@end
