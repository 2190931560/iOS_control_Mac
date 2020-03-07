//
//  ServiceUtil.m
//  ViralMouse
//
//  Created by dlleng on 2018/3/24.
//  Copyright © 2018年 leng. All rights reserved.
//

#import "UDPUtil.h"
#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#include <unistd.h>
#import <ifaddrs.h>
#import <netdb.h>
#import "defines.h"
//#import "ViralUtil.h"

@interface UDPUtil()
@property(assign)int mSocket;
@property(assign)struct sockaddr_in *mAddr4;
@property(strong)dispatch_source_t rcvSource;

@end
@implementation UDPUtil
static UDPUtil *gServer = nil;


+(UDPUtil*)share
{
    if(gServer == nil)
    {
        gServer = [[UDPUtil alloc] init];
        gServer.mAddr4 = nil;
        gServer.mSocket = -1;
    }
    
    return gServer;
}
+(void)uninstance
{
    if(gServer)
    {
        [gServer stopServer];
        gServer = nil;
    }
}
-(BOOL)startServer:(int)port
{
    if(_mSocket != -1){
        NSLog(@"socket is runing,please not recreate");
        return true;
    }
    _mSocket = socket(AF_INET, SOCK_DGRAM, 0);
    if(_mSocket == -1)
    {
        NSLog(@"create socket failed");
        return false;
    }
    //UDP广播必须设置socket属性
     int on = 1;
     if (setsockopt(_mSocket, SOL_SOCKET, SO_BROADCAST, &on, sizeof(on)) == -1)
     {
         printf("setsockopt failed ! error message :%s\n", strerror(errno));
         return false;
     }
    if (fcntl(_mSocket, F_SETFL, O_NONBLOCK) == -1)
    {
        printf("fcntl O_NONBLOCK failed ! error message :%s\n", strerror(errno));
        return false;
    }
    
    int reuseOn = 1;
    if (setsockopt(_mSocket, SOL_SOCKET, SO_REUSEADDR, &reuseOn, sizeof(reuseOn)) == -1)
    {
        printf("setsockopt SO_REUSEADDR failed ! error message :%s\n", strerror(errno));
        return false;
    }
    
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(port);
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    if(bind(_mSocket,(struct sockaddr *)&addr4,sizeof(addr4))==-1)
    {
        printf("bind IP failed ! error message : %s\n",strerror(errno));
        close(_mSocket);
        _mSocket = -1;
        return false;
    }
    self.rcvSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, _mSocket, 0, dispatch_get_global_queue(0, 0));
    dispatch_source_set_event_handler(self.rcvSource, ^{@autoreleasepool{
        char buf[1024]={0};
        struct sockaddr_in client_addr;
        socklen_t addrlen=sizeof(client_addr);

        memset(&client_addr,0,sizeof(client_addr));
        long len = recvfrom(self.mSocket,buf,sizeof(buf),0,(struct sockaddr *)&client_addr,&addrlen);
        if(len == -1)
        {
            printf("recvfrom failed ! error message : %s\n",strerror(errno));
        }else
        {
            //printf("from %s:%d:%s\n",inet_ntoa(client_addr.sin_addr),ntohs(client_addr.sin_port),buf);
            [self processMsg:buf len:len addr:client_addr];
        }
        memset(buf,0,sizeof(buf));

    }});
    dispatch_source_set_cancel_handler(self.rcvSource, ^{
        if(self.mAddr4){
            free(self.mAddr4);
            self.mAddr4 = nil;
        }
        if(self.mSocket != -1){
            close(self.mSocket);
            self.mSocket = -1;
        }
    });
    dispatch_resume(self.rcvSource);

    return true;
}

-(void)processMsg:(char*)buf len:(long)length addr:(struct sockaddr_in)client
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
        case vBroadcast:
        {
            if(self.mSocket != -1)
            {
                NSLog(@"收到广播，回复");
                //NSLog(@"%@",[NSHost currentHost]);
                NSString *name = [[NSHost currentHost] localizedName];
                long len = PACKAGE_MIN_LEN + strlen(name.UTF8String);
                char *buf = (char*)malloc(len);
                
                makePackage(vBroadcast, buf, (char*)name.UTF8String, (uint32_t)strlen(name.UTF8String));
                
                if (-1 == sendto(self.mSocket, buf, len, 0, (struct sockaddr*)&client, sizeof(struct sockaddr)))
                {
                    printf("broadfast failed ! error message :%s\n", strerror(errno));
                }
                free(buf);
            }
        }
            break;
        default:
            break;
    }

    [self processMsg:buf+packageLen len:length-packageLen addr:client];
}

-(void)stopServer
{
     if(self.rcvSource)
         dispatch_source_cancel(self.rcvSource);
}


//- (NSString *) routerIp
//{
//
//    NSString *address = @"error";
//    struct ifaddrs *interfaces = NULL;
//    struct ifaddrs *temp_addr = NULL;
//    int success = 0;
//
//    // retrieve the current interfaces - returns 0 on success
//    success = getifaddrs(&interfaces);
//    if (success == 0)
//    {
//        // Loop through linked list of interfaces
//        temp_addr = interfaces;
//        while(temp_addr != NULL)
//        {
//            if(temp_addr->ifa_addr->sa_family == AF_INET)
//            {
//                // Check if interface is en0 which is the wifi connection on the iPhone
//                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
//                {
//                    // Get NSString from C String //ifa_addr
//                    char buffer[64] = {0};
//                    strcpy(buffer, inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr));
//                    address = [NSString stringWithUTF8String:buffer];                }
//            }
//
//            temp_addr = temp_addr->ifa_next;
//        }
//    }
//
//    // Free memory
//    freeifaddrs(interfaces);
//
//    return address;
//}

//-(void)broadcast
//{
//    if(self.mSocket == -1){
//        printf("socket is not init\n");
//        return;
//    }
//    
//    //UDP广播必须设置socket属性
//    int on = 1;
//    if (setsockopt(self.mSocket, SOL_SOCKET, SO_BROADCAST, &on, sizeof(on)) == -1)
//    {
//        printf("setsockopt 1 failed ! error message :%s\n", strerror(errno));
//        return;
//    }
//    struct sockaddr_in addr4;
//    memset(&addr4, 0, sizeof(addr4));
//    addr4.sin_len = sizeof(addr4);
//    addr4.sin_family = AF_INET;
//    addr4.sin_port = htons(CLIENT_PORT);
//    addr4.sin_addr.s_addr = inet_addr([self routerIp].UTF8String);
//    
//    int len = PACKAGE_MIN_LEN + 0;
//    char *buf = (char*)malloc(len);
//    makePackage(vBroadcast, buf, 0, 0);
//    
//    if (-1 == sendto(self.mSocket, buf, len, 0, (struct sockaddr*)&addr4, sizeof(struct sockaddr)))
//    {
//        printf("broadfast failed ! error message :%s\n", strerror(errno));
//    }
//    free(buf);
//    on = 0;
//    if (setsockopt(self.mSocket, SOL_SOCKET, SO_BROADCAST, &on, sizeof(on)) == -1)
//    {
//        printf("setsockopt 0 failed ! error message :%s\n", strerror(errno));
//        return;
//    }
//}

//-(void)createAddr4:(char*)ip port:(int)port
//{
//    if(self.mAddr4)
//        free(self.mAddr4);
//    self.mAddr4 = (struct sockaddr_in *)malloc(sizeof(struct sockaddr_in));
//    memset(self.mAddr4, 0, sizeof(struct sockaddr_in));
//    self.mAddr4->sin_len = sizeof(struct sockaddr_in);
//    self.mAddr4->sin_family = AF_INET;
//    self.mAddr4->sin_port = htons(port);
//    self.mAddr4->sin_addr.s_addr = inet_addr(ip);
//
//
//}

//-(void)send:(char*)data length:(int)length
//{
//    if(self.mSocket != -1 && self.mAddr4)
//    {
//        if (-1 == sendto(self.mSocket, data, length, 0, (struct sockaddr*)self.mAddr4, sizeof(struct sockaddr)))
//        {
//            printf("sendto failed ! error message :%s\n", strerror(errno));
//        }
//    }
//}
@end
