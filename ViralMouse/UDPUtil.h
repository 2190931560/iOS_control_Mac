//
//  ServiceUtil.h
//  ViralMouse
//
//  Created by dlleng on 2018/3/24.
//  Copyright © 2018年 leng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UDPUtil : NSObject

+(UDPUtil*)share;
+(void)uninstance;

-(BOOL)startServer:(int)port;
-(void)stopServer;

//-(void)send:(char*)data length:(int)length;
//-(void)broadcast;
@end
