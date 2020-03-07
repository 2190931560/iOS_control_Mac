//
//  defines.h
//  ViralMouse
//
//  Created by dlleng on 2018/3/24.
//  Copyright © 2018年 leng. All rights reserved.
//

#ifndef defines_h
#define defines_h

#include <stdint.h>

typedef enum{
    vMouseMove=1,               //float*2  dataLen
    vMouseLButtonDown,          //0
    vMouseLButtonUp,            //0
    vMouseLButtonClick,         //0
    vMouseLButtonDoubleClick,   //0
    vMouseLButtonTrebleClick,   //0
    vMouseRButtonClick,         //0
    vMouseLButtonDraged,        //float*2
    vMouseScrollWheel,          //float*2
    vVideoStart,
    vVideoEnd,
    vVideoData,
    vBroadcast,                 //strlen(system info)
}ViralMouseEvent;

//typedef struct
//{
//    char start;
//    uint16_t event;
//    uint32_t len;
//    float x;
//    float y;
//    char end;
//}UDPPackage;

#define PACKAGE_MIN_LEN 8

#define SERVER_PORT 51235
#define CLIENT_PORT 51236
#define HTTP_PORT 51237
#define TCP_PORT 51238

// |-|--|--|...|-|
//  1  2  4  n  1
//  'v' event len(8+dataLen) data 'm'
// return: package length
uint16_t makePackage(ViralMouseEvent event,char *outBuf,char *param,uint32_t paramLen);
// return: 1=success 0=fail
uint8_t checkPackageBuf(char *buf,uint32_t bufLen,uint16_t* event,uint32_t* packageLen);
void getDataFromPackage(char *data,uint32_t dataLen,char *package);
int getPackageLength(char *buf,uint32_t len);
#endif /* defines_h */
