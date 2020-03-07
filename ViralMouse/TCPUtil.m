//
//  TCPUtil.m
//  ViralMouse
//
//  Created by dlleng on 2018/3/30.
//  Copyright © 2018年 leng. All rights reserved.
//

#import "TCPUtil.h"
#import "GCDAsyncSocket.h"
#import "defines.h"
#import "ViralUtil.h"
#import "VideoEncoder.h"

@interface TCPUtil()<GCDAsyncSocketDelegate>
@property(nonatomic,strong)GCDAsyncSocket *gcdSocket;
@property(nonatomic,strong)NSMutableArray *arrSockets;
@end

@implementation TCPUtil
static TCPUtil *gTcp = nil;
+(TCPUtil*)share
{
    if(gTcp == nil)
    {
        gTcp = [[TCPUtil alloc] init];
    }
    return gTcp;
}
-(instancetype)init
{
    self = [super init];
    if(self)
    {
        self.gcdSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_queue_create("TCPUtil", DISPATCH_QUEUE_PRIORITY_DEFAULT)];;
        self.arrSockets = [NSMutableArray array];
    }
    return self;
}
-(BOOL)startServerAtPort:(uint16_t)port
{
    NSError *err;
    BOOL ret = [self.gcdSocket acceptOnPort:port error:&err];
    if(err)NSLog(@"acceptOnPort err = %@",err);
    return ret;
}
-(void)stopServer
{
    [self.gcdSocket disconnect];
}

//-(BOOL)connect:(NSString*)host port:(uint16_t)port
//{
//    NSError *err;
//    BOOL ret = [self.gcdSocket connectToHost:host onPort:port withTimeout:3 error:&err];
//    if(err)NSLog(@"connectToHost err = %@",err);
//    return ret;
//}
//-(void)disconnect
//{
//    [self.gcdSocket disconnect];
//}

-(void)send:(char*)buf length:(int)len withSocket:(GCDAsyncSocket*)socket
{
    [socket writeData:[NSData dataWithBytes:buf length:len] withTimeout:-1 tag:0];
}

-(void)SendAll:(NSData*)data
{
    long len = PACKAGE_MIN_LEN + data.length;
    char* buf = (char*)malloc(len);
    makePackage(vVideoData, buf, (char*)data.bytes, data.length);
    NSData *packageData = [NSData dataWithBytes:buf length:len];
    for (GCDAsyncSocket *sock in self.arrSockets) {
        [sock writeData:packageData withTimeout:-1 tag:0];
    }
    free(buf);
}
#pragma mark GCDAsyncSocketDelegate
#pragma mark server
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSLog(@"连接进来");
    [self.arrSockets addObject:newSocket];
    [newSocket readDataWithTimeout:-1 tag:0];
}
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"didReadData %ld",data.length);
    [self processData:(char*)data.bytes length:data.length withSocket:sock];
    [sock readDataWithTimeout:-1 tag:0];
}
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err
{
    NSLog(@"客户的关闭连接");
    [sock disconnect];
    [self.arrSockets removeObject:sock];
    if(self.arrSockets.count == 0)
        [[VideoEncoder share] stopEncode];
    NSLog(@"剩余连接数=%ld",self.arrSockets.count);
}
//- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
//{
//
//    [sock readDataWithTimeout:-1 tag:0];
//}
-(void)processData:(char*)buf length:(long)length withSocket:(GCDAsyncSocket*)sock
{
    if(length<=0)
        return;
    
    uint16_t event=0;
    uint32_t packageLen=0;
    if(0 == checkPackageBuf(buf, (uint32_t)length, &event, &packageLen))
    {
        printf("check package error!!!\n");
        return;
    }
    switch (event) {
        case vMouseMove:
        {
            float param[2];
            getDataFromPackage((char*)param, packageLen-PACKAGE_MIN_LEN, buf);
            [ViralUtil PostMouseMove:CGPointMake(param[0], param[1])];
            //NSLog(@"鼠标移动 %d %d",packageLen,length);
        }
            break;
        case vMouseLButtonDown:
            [ViralUtil PostLButtonDown];
            break;
        case vMouseLButtonUp:
            [ViralUtil PostLButtonUp];
            break;
        case vMouseLButtonClick:
            [ViralUtil PostLButtonClick];
            break;
        case vMouseLButtonDoubleClick:
            [ViralUtil PostLButtonDoubleClick];
            break;
        case vMouseLButtonTrebleClick:
            [ViralUtil PostLButtonTrebleClick];
            break;
        case vMouseRButtonClick:
            [ViralUtil PostRButtonClick];
            break;
        case vMouseLButtonDraged:
        {
            float param[2];
            getDataFromPackage((char*)param, packageLen-PACKAGE_MIN_LEN, buf);
            [ViralUtil PostDragEvent:CGPointMake(param[0], param[1])];
        }
            break;
        case vMouseScrollWheel:
        {
            float param[2];
            getDataFromPackage((char*)param, packageLen-PACKAGE_MIN_LEN, buf);
            [ViralUtil PostScrollEvent:CGPointMake(param[0], param[1])];
        }
            break;
        case vVideoStart:
            [[VideoEncoder share] startEncode];
            break;
        case vVideoEnd:
            [[VideoEncoder share] stopEncode];
            break;
        default:
            break;
    }
    
    [self processData:buf+packageLen length:length-packageLen withSocket:sock];
}
@end
