
#ifndef _TRAMPOLINE_UNITY_GLESSUPPORT_H_
#define _TRAMPOLINE_UNITY_GLESSUPPORT_H_

#include <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>


#define ENABLE_UNITY_GLES_DEBUG 1
#define MSAA_DEFAULT_SAMPLE_COUNT 0

#define GLES_UPSCALE_FILTER GL_LINEAR
//#define GLES_UPSCALE_FILTER GL_NEAREST

extern	bool	_supportsDiscard;
extern	bool	_supportsMSAA;
extern	bool	_supportsPackedStencil;

#ifdef __cplusplus
extern "C" {
#endif

void CheckGLESError(const char* file, int line);

#ifdef __cplusplus
} // extern "C"
#endif


#if ENABLE_UNITY_GLES_DEBUG
	#define GLESAssert()	do { CheckGLESError (__FILE__, __LINE__); } while(0)
	#define GLES_CHK(expr)	do { {expr;} GLESAssert(); } while(0)
#else
	#define GLESAssert()	do { } while(0)
	#define GLES_CHK(expr)	do { expr; } while(0)
#endif


#endif // _TRAMPOLINE_UNITY_GLESSUPPORT_H_
