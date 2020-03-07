//
//  ServiceUtil.h
//  ViralMouse
//
//  Created by dlleng on 2018/3/24.
//  Copyright © 2018年 leng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "defines.h"

typedef void(^SearchBlock)(NSDictionary *diction);

@interface UDPUtil : NSObject

+(UDPUtil*)share;
+(void)uninstance;
-(BOOL)startServer:(int)port;

-(void)send:(char*)data length:(int)length;
-(void)stopServer;
-(void)broadcast:(SearchBlock)block;

//-(void)sendEvent:(ViralMouseEvent)event x:(float)x y:(float)y;
-(NSString*)getServerIP;

-(void)createAddr4:(char*)ip port:(int)port;
@end
