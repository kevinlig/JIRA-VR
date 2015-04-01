
#include "CVTextureCache.h"

#ifdef __IPHONE_5_0

#include "DisplayManager.h"

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <CoreVideo/CVOpenGLESTextureCache.h>

#include "UnityMetalSupport.h"
#if UNITY_CAN_USE_METAL
	#include <CoreVideo/CVMetalTextureCache.h>
#else
	const CFStringRef kCVPixelBufferMetalCompatibilityKey = CFSTR("MetalCompatibility");
	typedef void* CVMetalTextureCacheRef;
	typedef void* CVMetalTextureRef;
	inline CVReturn			CVMetalTextureCacheCreate(CFAllocatorRef, CFDictionaryRef, MTLDeviceRef, CFDictionaryRef, CVMetalTextureCacheRef*)	{ return 0; }
	inline CVReturn			CVMetalTextureCacheCreateTextureFromImage(CFAllocatorRef, CVMetalTextureCacheRef, CVImageBufferRef, CFDictionaryRef, MTLPixelFormat, size_t, size_t, size_t, CVMetalTextureRef*)	{ return 0; }
	inline void				CVMetalTextureCacheFlush(CVMetalTextureCacheRef, uint64_t options)	{ }
	inline MTLTextureRef	CVMetalTextureGetTexture(CVMetalTextureRef)	{ return nil; }
#endif
const CFStringRef kCVPixelBufferOpenGLESCompatibilityKey = CFSTR("OpenGLESCompatibility");

bool CanUseCVTextureCache()
{
	return _ios50orNewer;
}


void* CreateCVTextureCache()
{
	if(!CanUseCVTextureCache())
		return 0;

	void* ret = 0;

	CVReturn err = 0;
	if(UnitySelectedRenderingAPI() == apiMetal)
		err = CVMetalTextureCacheCreate(kCFAllocatorDefault, 0, UnityGetMetalDevice(), 0, (CVMetalTextureCacheRef*)&ret);
	else
		err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, 0, UnityGetMainScreenContextGLES(), 0, (CVOpenGLESTextureCacheRef*)&ret);

	if(err)
	{
		::printf("Error at CVOpenGLESTextureCacheCreate: %d", err);
		ret = 0;
	}
	return ret;
}

void FlushCVTextureCache(void* cache)
{
	if(!CanUseCVTextureCache())
		return;

	if(UnitySelectedRenderingAPI() == apiMetal)
		CVMetalTextureCacheFlush((CVMetalTextureCacheRef)cache, 0);
	else
		CVOpenGLESTextureCacheFlush((CVOpenGLESTextureCacheRef)cache, 0);
}

void* CreateTextureFromCVTextureCache(void* cache, void* image, unsigned w, unsigned h)
{
	if(!CanUseCVTextureCache())
		return 0;

	void* texture = 0;

	if(!cache || !image)
		return 0;

	CVReturn err = 0;
	if(UnitySelectedRenderingAPI() == apiMetal)
	{
		err = CVMetalTextureCacheCreateTextureFromImage(
			kCFAllocatorDefault, (CVMetalTextureCacheRef)cache, (CVImageBufferRef)image, 0,
			MTLPixelFormatBGRA8Unorm, w, h, 0, (CVMetalTextureRef*)&texture
		);
	}
	else
	{
		err = CVOpenGLESTextureCacheCreateTextureFromImage(
			kCFAllocatorDefault, (CVOpenGLESTextureCacheRef)cache, (CVImageBufferRef)image, 0,
			GL_TEXTURE_2D, GL_RGBA, w, h, GL_BGRA_EXT, GL_UNSIGNED_BYTE,
			0, (CVOpenGLESTextureRef*)&texture
		);
	}

	if(err)
	{
		::printf("Error at CVOpenGLESTextureCacheCreateTextureFromImage: %d", err);
		texture = 0;
	}
	return texture;
}

unsigned GetGLTextureFromCVTextureCache(void* texture)
{
	if(!CanUseCVTextureCache())
		return 0;
	assert(UnitySelectedRenderingAPI() != apiMetal);
	return CVOpenGLESTextureGetName((CVOpenGLESTextureRef)texture);
}
id<MTLTexture> GetMetalTextureFromCVTextureCache(void* texture)
{
	assert(UnitySelectedRenderingAPI() == apiMetal);
	return CVMetalTextureGetTexture((CVMetalTextureRef)texture);
}
uintptr_t GetTextureFromCVTextureCache(void* texture)
{
	if(UnitySelectedRenderingAPI() == apiMetal)
		return (uintptr_t)(__bridge void*)GetMetalTextureFromCVTextureCache(texture);
	else
		return (uintptr_t)GetGLTextureFromCVTextureCache(texture);
}

void* CreatePixelBufferForCVTextureCache(unsigned w, unsigned h)
{
	NSString* apiKey = UnitySelectedRenderingAPI() == apiMetal	? (NSString*)kCVPixelBufferMetalCompatibilityKey
																: (NSString*)kCVPixelBufferOpenGLESCompatibilityKey;
	CVPixelBufferRef pb = 0;

#if __has_feature(objc_dictionary_literals)
	NSDictionary* options = @{	(NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
								(NSString*)kCVPixelBufferWidthKey : @(w),
								(NSString*)kCVPixelBufferHeightKey : @(h),
								apiKey : @(YES),
								(NSString*)kCVPixelBufferIOSurfacePropertiesKey : @{}
							};
#else
	NSArray* keys = [NSArray arrayWithObjects:
		(NSString*)kCVPixelBufferPixelFormatTypeKey,
		(NSString*)kCVPixelBufferWidthKey,
		(NSString*)kCVPixelBufferHeightKey,
		apiKey,
		(NSString*)kCVPixelBufferIOSurfacePropertiesKey,
		nil
	];
	NSArray* values = [NSArray arrayWithObjects:
		[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],
		[NSNumber numberWithInt:w],
		[NSNumber numberWithInt:h],
		[NSNumber numberWithInt:YES],
		[NSDictionary dictionary],
		nil
	];
	NSDictionary* options = [NSDictionary dictionaryWithObjects:values forKeys:keys];
#endif

	CVPixelBufferCreate(kCFAllocatorDefault, w, h, kCVPixelFormatType_32BGRA, (CFDictionaryRef)options, &pb);
	return pb;
}

void* CreateReadableRTFromCVTextureCache(void* cache, unsigned w, unsigned h, void** pb)
{
	*pb = CreatePixelBufferForCVTextureCache(w, h);
	return CreateTextureFromCVTextureCache(cache, *pb, w, h);
}

#else

bool		CanUseCVTextureCache()													{ return false; }
void*		CreateCVTextureCache()													{ return 0; }
void		FlushCVTextureCache(void*)												{}
void*		CreateTextureFromCVTextureCache(void*, void*, unsigned, unsigned)		{ return 0; }
unsigned	GetGLTextureFromCVTextureCache(void*)									{ return 0; }
void*		CreatePixelBufferForTextureCache(unsigned, unsigned)					{ return 0; }
void* 		CreateReadableRTFromCVTextureCache(void*, unsigned, unsigned, void**)	{ return 0;}

#endif // __IPHONE_5_0
