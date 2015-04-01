#pragma once

// we allow to build with sdk 7.0 (and run on ios6) so we need to take an extra care about Metal support
// it is expected to substitute Metal.h so only objc

#ifdef __cplusplus
	extern "C" typedef MTLDeviceRef (*MTLCreateSystemDefaultDeviceFunc)();
#else
	typedef MTLDeviceRef (*MTLCreateSystemDefaultDeviceFunc)();
#endif


#if UNITY_CAN_USE_METAL

	#import <Metal/Metal.h>
	#import <QuartzCore/CAMetalLayer.h>

#else

	typedef NSUInteger MTLPixelFormat;
	enum
	{
		MTLPixelFormatBGRA8Unorm,
		MTLPixelFormatBGRA8Unorm_sRGB,
	};

	@interface CAMetalLayer : CALayer
		@property (readwrite) BOOL framebufferOnly;
		@property (readwrite) CGSize drawableSize;
		@property BOOL presentsWithTransaction;
		@property (readwrite, retain) id <MTLDevice> device;
		@property (readwrite) MTLPixelFormat pixelFormat;
		- (id <CAMetalDrawable>)newDrawable;
	@end

	@protocol MTLDevice
		- (id <MTLCommandQueue>)newCommandQueue;
	@end

#endif
