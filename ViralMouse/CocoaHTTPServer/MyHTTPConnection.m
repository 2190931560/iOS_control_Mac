#import "MyHTTPConnection.h"
#import "HTTPDynamicFileResponse.h"
#import "HTTPDataResponse.h"
//#import "HTTPResponseTest.h"
#import "HTTPLogging.h"

#import <AppKit/AppKit.h>

// Log levels: off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;


@implementation MyHTTPConnection
- (NSImage *)imageResize:(NSImage*)anImage newSize:(NSSize)newSize {
    NSImage *sourceImage = anImage;
    //[sourceImage setScalesWhenResized:YES];
    
    // Report an error if the source isn't a valid image
    if (![sourceImage isValid]){
        NSLog(@"Invalid Image");
    } else {
        NSImage *smallImage = [[NSImage alloc] initWithSize: newSize];
        [smallImage lockFocus];
        [sourceImage setSize: newSize];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, newSize.width, newSize.height) operation:NSCompositingOperationCopy fraction:1.0];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;
}
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    path = [path stringByRemovingPercentEncoding];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isdirect;
    [fm fileExistsAtPath:path isDirectory:&isdirect];
    if(isdirect)
    {
        //遍历目录的另一种方法：（不递归枚举文件夹种的内容）
        NSArray *dirArray = [fm contentsOfDirectoryAtPath:path error:nil];
        NSMutableArray *arr = [NSMutableArray array];
        for (NSString *str in dirArray) {
            if(![str hasPrefix:@"."])
            {
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                dic[@"name"] = str;
                
                NSString *fullpath = [path stringByAppendingPathComponent:str];
                [fm fileExistsAtPath:fullpath isDirectory:&isdirect];
                dic[@"isdirect"] = @(isdirect);
                NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:fullpath];
                icon = [self imageResize:icon newSize:NSMakeSize(64, 64)];
                //NSLog(@"%@",icon);
                
                NSDictionary *dictionary = @{NSImageCompressionFactor:[NSNumber numberWithFloat:0.5]};
                
                NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:[icon TIFFRepresentation]];
                
                
                NSData *tiff_data = [imageRep representationUsingType:NSPNGFileType properties:dictionary];
                //[tiff_data writeToFile:@"/Users/dlleng/Downloads/1.tiff" atomically:YES];
                NSString *base64 = [tiff_data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                dic[@"icon"] = base64;
                
                [arr addObject:dic];
            }
        }
        
        return [[HTTPDataResponse alloc] initWithData: [NSJSONSerialization dataWithJSONObject:arr options:NSJSONWritingPrettyPrinted error:nil]];
    }
    else
    {
        NSData *data = [NSData dataWithContentsOfFile:path];
        return [[HTTPDataResponse alloc] initWithData: data];
    }
    
}

@end
