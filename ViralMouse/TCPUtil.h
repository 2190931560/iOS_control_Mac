//
//  TCPUtil.h
//  ViralMouse
//
//  Created by dlleng on 2018/3/30.
//  Copyright © 2018年 leng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCPUtil : NSObject

+(TCPUtil*)share;
-(BOOL)startServerAtPort:(uint16_t)port;
-(void)stopServer;

-(void)SendAll:(NSData*)data;

//-(BOOL)connect:(NSString*)host port:(uint16_t)port;
//-(void)disconnect;

//-(void)send:(char*)buf length:(int)len;

@end
