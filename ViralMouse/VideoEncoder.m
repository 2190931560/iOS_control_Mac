//
//  VideoEncoder.m
//  ViralMouse
//
//  Created by dlleng on 2018/3/30.
//  Copyright © 2018年 leng. All rights reserved.
//

#import "VideoEncoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import <Cocoa/Cocoa.h>
#import "TCPUtil.h"
#import <time.h>

#define FPS 30
//#define TEST_FILE

@interface VideoEncoder()
{
@public
    VTCompressionSessionRef _encodeSesion;
    dispatch_queue_t _encodeQueue;
    long    _frameCount;
    BOOL    _spsppsFound;
    dispatch_source_t _timer;
}
@end
#ifdef TEST_FILE
FILE    *_h264File;
#endif
@implementation VideoEncoder
static VideoEncoder *gEncoder = nil;
+(instancetype)share
{
    if(gEncoder == nil)
    {
        gEncoder = [[VideoEncoder alloc] init];
    }
    return gEncoder;
}

-(void)startEncode
{
#ifdef TEST_FILE
    _h264File = fopen("/Users/dlleng/Downloads/test.h264", "wb");
#endif
    CGDirectDisplayID displayId = CGMainDisplayID();
    CGImageRef imageRef = CGDisplayCreateImage(displayId);
    
    int width = (int)CGImageGetWidth(imageRef);
    int height = (int)CGImageGetHeight(imageRef);
    CGImageRelease(imageRef);
    if(width >= 1920)
    {
        width = width/2;
        height = height/2;
    }
    [self startEncodeSession:width height:height framerate:FPS bitrate:width*1024];
    
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 1.0/FPS * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_timer, ^{
        [self timerAction];
    });
    dispatch_resume(_timer);
    
    
}
-(void)stopEncode
{
    if(_timer)
    {
        dispatch_source_cancel(_timer);
        
        _timer = nil;
        [self stopEncodeSession];
    }
#ifdef TEST_FILE
    fclose(_h264File);
#endif
}

-(void)timerAction
{
    @autoreleasepool{
//    struct timeval tv;
//    gettimeofday(&tv, NULL);
//    int64_t ts = (int64_t)tv.tv_sec*1000 + tv.tv_usec/1000;
//    NSLog(@"== timer ==%lld",ts);
    CGDirectDisplayID displayId = CGMainDisplayID();
    CGImageRef imageRef = CGDisplayCreateImage(displayId);
    if(!imageRef)return;
    CVPixelBufferRef pixelBuf = [self pixelBufferFromCGImage:imageRef];
    CGImageRelease(imageRef);
    [self encodeFrame:pixelBuf];
    CVPixelBufferRelease(pixelBuf);
    }
}

-(instancetype)init
{
    self = [super init];
    if(self)
    {
        _spsppsFound = false;
        _frameCount = 0;
        _encodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
                              };
    
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, CGImageGetWidth(image),
                                          CGImageGetHeight(image), kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    if (status!=kCVReturnSuccess) {
        NSLog(@"Operation failed");
    }
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, CGImageGetWidth(image),
                                                 CGImageGetHeight(image), 8, 4*CGImageGetWidth(image), rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    
    // 倒转图片
  //  CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
//    CGAffineTransform flipVertical = CGAffineTransformMake( 1, 0, 0, -1, 0, CGImageGetHeight(image) );
//    CGContextConcatCTM(context, flipVertical);
//    CGAffineTransform flipHorizontal = CGAffineTransformMake( -1.0, 0.0, 0.0, 1.0, CGImageGetWidth(image), 0.0 );
//    CGContextConcatCTM(context, flipHorizontal);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
}

#pragma mark - videotoolbox methods
- (int)startEncodeSession:(int)width height:(int)height framerate:(int)fps bitrate:(int)bt
{
    OSStatus status;
    _frameCount = 0;
    
    VTCompressionOutputCallback cb = encodeOutputCallback;
    status = VTCompressionSessionCreate(kCFAllocatorDefault, width, height, kCMVideoCodecType_H264, NULL, NULL, NULL, cb, (__bridge void *)(self), &_encodeSesion);
    
    if (status != noErr) {
        NSLog(@"VTCompressionSessionCreate failed. ret=%d", (int)status);
        return -1;
    }
    // 设置实时编码输出，降低编码延迟
    status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    NSLog(@"set realtime  return: %d", (int)status);
    
    // h264 profile, 直播一般使用baseline，可减少由于b帧带来的延时
    status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
    NSLog(@"set profile   return: %d", (int)status);
    
    // 设置编码码率(比特率)，如果不设置，默认将会以很低的码率编码，导致编码出来的视频很模糊
    status  = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(bt)); // bps
    status += VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@(bt*2/8), @1]); // Bps
    NSLog(@"set bitrate   return: %d", (int)status);
    
    
    // 设置关键帧间隔，即gop size
    status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(fps*2));
    
    // 设置帧率，只用于初始化session，不是实际FPS
    status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(fps));
    NSLog(@"set framerate return: %d", (int)status);
    
    // 开始编码
    status = VTCompressionSessionPrepareToEncodeFrames(_encodeSesion);
    NSLog(@"start encode  return: %d", (int)status);
    
    return 0;
}


// 编码一帧图像，使用queue，防止阻塞系统摄像头采集线程
- (void) encodeFrame:(CVImageBufferRef )imageBuffer
{
    dispatch_sync(_encodeQueue, ^{
        
        // pts,必须设置，否则会导致编码出来的数据非常大，原因未知
        CMTime pts = CMTimeMake(_frameCount, 1000);
        CMTime duration = kCMTimeInvalid;
        
        VTEncodeInfoFlags flags;
        
        // 送入编码器编码
        OSStatus statusCode = VTCompressionSessionEncodeFrame(_encodeSesion,
                                                              imageBuffer,
                                                              pts, duration,
                                                              NULL, NULL, &flags);
        
        if (statusCode != noErr) {
            NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
            
            [self stopEncodeSession];
            return;
        }
    });
}

- (void) stopEncodeSession
{
    if(_encodeSesion){
        VTCompressionSessionCompleteFrames(_encodeSesion, kCMTimeInvalid);
        
        VTCompressionSessionInvalidate(_encodeSesion);
        
        CFRelease(_encodeSesion);
        _encodeSesion = NULL;
    }
    _spsppsFound = false;
    _frameCount = 0;
}
- (void) writeH264Data:(char*)data length:(size_t)length addStartCode:(BOOL)b
{
    //NSLog(@"===%d",data[4]&0x1f);
    // 添加4字节的 h264 协议 start code
    const Byte bytes[] = {0x00,0x00,0x00,0x01};
    NSMutableData *h264Data = [NSMutableData data];
    if(b)
       [h264Data appendBytes:bytes length:4];
    [h264Data appendBytes:data length:length];
    
    [[TCPUtil share] SendAll:h264Data];
#ifdef TEST_FILE
    if (_h264File) {
        if(b)
            fwrite(bytes, 1, 4, _h264File);

        fwrite(data, 1, length, _h264File);
    } else {
        NSLog(@"_h264File null error, check if it open successed");
    }
#endif
}
// 编码回调，每当系统编码完一帧之后，会异步掉用该方法，此为c语言方法
void encodeOutputCallback(void *userData, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags,
                          CMSampleBufferRef sampleBuffer )
{
    if (status != noErr) {
        NSLog(@"didCompressH264 error: with status %d, infoFlags %d", (int)status, (int)infoFlags);
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    VideoEncoder* vc = (__bridge VideoEncoder*)userData;
    
    // 判断当前帧是否为关键帧
    bool keyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    
    // 获取sps & pps数据. sps pps只需获取一次，保存在h264文件开头即可
    if (keyframe && !vc->_spsppsFound)
    {
        size_t spsSize, spsCount;
        size_t ppsSize, ppsCount;
        
        const uint8_t *spsData, *ppsData;
        
        CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
        OSStatus err0 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 0, &spsData, &spsSize, &spsCount, 0 );
        OSStatus err1 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 1, &ppsData, &ppsSize, &ppsCount, 0 );
        
        if (err0==noErr && err1==noErr)
        {
            vc->_spsppsFound = true;
            [vc writeH264Data:(char *)spsData length:spsSize addStartCode:YES];
            [vc writeH264Data:(char *)ppsData length:ppsSize addStartCode:YES];
            
            NSLog(@"got sps/pps data. Length: sps=%zu, pps=%zu", spsSize, ppsSize);
        }
    }
    
    size_t lengthAtOffset, totalLength;
    char *data;
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    OSStatus error = CMBlockBufferGetDataPointer(dataBuffer, 0, &lengthAtOffset, &totalLength, &data);
  
    if (error == noErr) {
        size_t offset = 0;
        const int AVCCHeaderLength = 4; // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
        // 循环获取nalu数据
        NSMutableData *vData = [NSMutableData data];
        NSMutableData *seiData = [NSMutableData data];
        while (offset < totalLength - AVCCHeaderLength) {
            uint32_t naluLength = 0;
            memcpy(&naluLength, data + offset, AVCCHeaderLength); // 获取nalu的长度，
            
            // 大端模式转化为系统端模式
            naluLength = CFSwapInt32BigToHost(naluLength);
            Byte *p = (Byte*)(data+offset);
            //NSLog(@"(%02x)%d got nalu data, length=%d, totalLength=%zu",p[5],p[4]&0x1f, naluLength, totalLength);
            if((p[4]&0x1f) == 6)
            {
                [seiData appendBytes:data+offset length:naluLength+AVCCHeaderLength];
            }
            else //sei
            {
                [vData appendBytes:data+offset length:naluLength+AVCCHeaderLength];
            }
            // 保存nalu数据到文件
            // 读取下一个nalu，一次回调可能包含多个nalu
            offset += AVCCHeaderLength + naluLength;
        }
        [vc writeH264Data:(char*)seiData.bytes length:seiData.length addStartCode:NO];
        [vc writeH264Data:(char*)vData.bytes length:vData.length addStartCode:NO];
    }
    //NSLog(@"==============");
}

@end
