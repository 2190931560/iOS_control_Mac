
#include <QuartzCore/QuartzCore.h>
#include <CoreVideo/CoreVideo.h>

@interface OpenGLLayer : CAEAGLLayer
@property CVPixelBufferRef pixelBuffer;
- (id)initWithFrame:(CGRect)frame;
- (void)resetRenderBuffer;
@end
