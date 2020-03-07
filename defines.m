//
//  defines.c
//  ViralMouse
//
//  Created by dlleng on 2018/3/28.
//  Copyright © 2018年 leng. All rights reserved.
//

#include <string.h>
#include "defines.h"
#import <stdio.h>


uint16_t makePackage(ViralMouseEvent event,char *outBuf,char *param,uint32_t paramLen)
{
    uint32_t ret = PACKAGE_MIN_LEN + paramLen;
    outBuf[0] = 'v';
    outBuf[1] = event&0xff;
    outBuf[2] = (event>>8)&0xff;
    outBuf[3] = ret&0xff;
    outBuf[4] = (ret>>8)&0xff;
    outBuf[5] = (ret>>16)&0xff;
    outBuf[6] = (ret>>24)&0xff;
    if(paramLen>0)
        memcpy(outBuf+7, param, paramLen);
    outBuf[ret-1] = 'm';
    
    return ret;
}
// return: 1=success 0=fail
uint8_t checkPackageBuf(char *buf,uint32_t bufLen,uint16_t* event,uint32_t* packageLen)
{
    if(bufLen<PACKAGE_MIN_LEN)
    {
        printf("checkPackageBuf bufLen<6\n");
        return 0;
    }
    if(buf[0] != 'v')
    {
        printf("checkPackageBuf buf[0]!='v'\n");
        return 0;
    }
    *event = (buf[1]&0xff) + ((buf[2]<<8)&0xff00);
    *packageLen = (buf[3]&0xff) + ((buf[4]<<8)&0xff00) + ((buf[5]<<16)&0xff0000) + ((buf[6]<<24)&0xff000000);
    
    if(*packageLen>bufLen)
    {
        printf("checkPackageBuf *packageLen>bufLen\n");
        return 0;
    }
    if(buf[*packageLen - 1] != 'm')
    {
        printf("checkPackageBuf buf[*packageLen - 1] != 'm'\n");
        return 0;
    }
    return 1;
    
}
void getDataFromPackage(char *data,uint32_t dataLen,char *package)
{
    memcpy(data, package+7, dataLen);
}
int getPackageLength(char *buf,uint32_t len)
{
    if(len<6)
        return 0;
    if(buf[0] != 'v')
        return 0;
    
    int packageLen = (buf[3]&0xff) + ((buf[4]<<8)&0xff00) + ((buf[5]<<16)&0xff0000) + ((buf[6]<<24)&0xff000000);
    return packageLen;
}
