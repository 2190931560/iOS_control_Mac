//
//  TCPUtil.m
//  ViralMouse
//
//  Created by dlleng on 2018/3/30.
//  Copyright © 2018年 leng. All rights reserved.
//

#import "TCPUtil.h"
#import "GCDAsyncSocket.h"
#import "VideoDecoder.h"

@interface TCPUtil()<GCDAsyncSocketDelegate>
@property(nonatomic,strong)GCDAsyncSocket *gcdSocket;
@property(nonatomic,copy)ConnectBlock connectBlock;
@property(nonatomic,strong)NSMutableData *packageData;
//@property(nonatomic,strong)NSMutableArray *arrSockets;
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
        //self.arrSockets = [NSMutableArray array];
    }
    return self;
}
//-(BOOL)startServerAtPort:(uint16_t)port
//{
//    NSError *err;
//    BOOL ret = [self.gcdSocket acceptOnPort:port error:&err];
//    if(err)NSLog(@"acceptOnPort err = %@",err);
//    return ret;
//}
//-(void)stopServer
//{
//    [self.gcdSocket disconnect];
//}

-(BOOL)connect:(NSString*)host port:(uint16_t)port block:(ConnectBlock)block
{
    self.connectBlock = block;
    NSError *err;
    BOOL ret = [self.gcdSocket connectToHost:host onPort:port withTimeout:3 error:&err];
    if(err)NSLog(@"connectToHost err = %@",err);
    return ret;
}
-(void)disconnect
{
    [self.gcdSocket disconnect];
    self.connectBlock = nil;
}

-(void)send:(char*)buf length:(long)len
{
    [self.gcdSocket writeData:[NSData dataWithBytes:buf length:len] withTimeout:-1 tag:0];
}
-(void)sendEvent:(ViralMouseEvent)event withData:(NSData*)data
{
    if(data == nil)
    {
        long len = PACKAGE_MIN_LEN;
        char *buf = (char*)malloc(len);
        makePackage(event, buf, 0, 0);
        [self send:buf length:len];
    }
    else
    {
        long len = PACKAGE_MIN_LEN + data.length;
        char *buf = (char*)malloc(len);
        makePackage(event, buf, (char*)data.bytes, data.length);
        [self send:buf length:len];
    }
    
}
#pragma mark GCDAsyncSocketDelegate
#pragma mark server
//- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
//{
//  //  [self.arrSockets addObject:newSocket];
//    [newSocket readDataWithTimeout:-1 tag:0];
//}
#pragma mark client
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    if(self.connectBlock)
        self.connectBlock(YES);
    //NSLog(@"连接成功");
    [sock readDataWithTimeout:-1 tag:0];
}
//#define TEST_FILE
#ifdef TEST_FILE
FILE    *_h264File = nil;
#endif

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    char *p = (char*)data.bytes;

    [self processData:p length:data.length withSocket:sock];
    
    [sock readDataWithTimeout:-1 tag:0];
}
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err
{
    if(self.connectBlock)
        self.connectBlock(NO);
    
    NSLog(@"断开连接=%@",err);
}

-(void)processData:(char*)buf length:(long)length withSocket:(GCDAsyncSocket*)sock
{
    //NSLog(@"processData %ld",length);
    if(buf[0] =='v')
    {
        self.packageData = [NSMutableData dataWithBytes:buf length:length];
        
    }else
    {
        [self.packageData appendBytes:buf length:length];
    }
    
    if(self.packageData.length == 0)
        return;
    
    while (_packageData.length>0)
    {
        char *p = _packageData.mutableBytes;
        uint16_t event=0;
        uint32_t packageLen=0;
        if(0 == checkPackageBuf((char*)_packageData.mutableBytes, (uint32_t)_packageData.length, &event, &packageLen))
        {
            //NSLog(@"check package error!!!(%ld)(%c)\n",_packageData.length,p[0]);
            return;
        }
        if(_packageData.length<packageLen)
            return;
        
        switch (event) {
            case vVideoData:
            {
                //NSLog(@"收到视频流");
                char *param = (char*)malloc(packageLen-PACKAGE_MIN_LEN);
                getDataFromPackage((char*)param, packageLen-PACKAGE_MIN_LEN, _packageData.mutableBytes);

#ifdef TEST_FILE
                if(_h264File == NULL)
                {
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                    NSString *docDir = [paths objectAtIndex:0];
                    docDir = [docDir stringByAppendingPathComponent:@"itest.h264"];
                    _h264File = fopen("/Users/leng/Downloads/test2.h264", "wb");
                }
                if (_h264File) {
                    fwrite(param, 1, packageLen-PACKAGE_MIN_LEN, _h264File);
                }
#endif
                [[VideoDecoder share] decodeBuffer:param length:packageLen-PACKAGE_MIN_LEN];
                free(param);
            }
                break;
            default:
                break;
        }
        
        _packageData = [NSMutableData dataWithBytes:p+packageLen length:_packageData.length-packageLen];
    }
    
}
@end
