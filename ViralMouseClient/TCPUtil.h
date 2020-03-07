//
//  TCPUtil.h
//  ViralMouse
//
//  Created by dlleng on 2018/3/30.
//  Copyright © 2018年 leng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "defines.h"

typedef void(^ConnectBlock)(BOOL bsuccess);

@interface TCPUtil : NSObject

+(TCPUtil*)share;
//-(BOOL)startServerAtPort:(uint16_t)port;
//-(void)stopServer;

-(BOOL)connect:(NSString*)host port:(uint16_t)port block:(ConnectBlock)block;
-(void)disconnect;

-(void)send:(char*)buf length:(long)len;

-(void)sendEvent:(ViralMouseEvent)event withData:(NSData*)data;

@end
