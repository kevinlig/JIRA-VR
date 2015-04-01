
#include "CMVideoSampling.h"

#include "CVTextureCache.h"
#include "GLESHelper.h"

#include <OpenGLES/ES2/glext.h>
#include <AVFoundation/AVFoundation.h>

void CMVideoSampling_Initialize(CMVideoSampling* sampling)
{
    ::memset(sampling, 0x00, sizeof(CMVideoSampling));
    if(CanUseCVTextureCache())
        sampling->cvTextureCache = CreateCVTextureCache();
    else
        GLES_CHK(glGenTextures(2, (GLuint*)sampling->glTex));
}

void CMVideoSampling_Uninitialize(CMVideoSampling* sampling)
{
	if(sampling->cvImageBuffer)
	{
		CFRelease(sampling->cvImageBuffer);
		sampling->cvImageBuffer = 0;
	}
    if(sampling->cvTextureCacheTexture)
    {
        CFRelease(sampling->cvTextureCacheTexture);
        sampling->cvTextureCacheTexture = 0;
    }
    if(sampling->cvTextureCache)
    {
        CFRelease(sampling->cvTextureCache);
        sampling->cvTextureCache = 0;
    }
    if(sampling->glTex[0])
    {
        GLES_CHK(glDeleteTextures(2, (GLuint*)sampling->glTex));
        sampling->glTex[0] = sampling->glTex[1] = 0;
    }
}

intptr_t CMVideoSampling_SampleBuffer(CMVideoSampling* sampling, void* buffer, size_t* w, size_t* h)
{
	intptr_t retTex = 0;

	if(sampling->cvImageBuffer)
		CFRelease(sampling->cvImageBuffer);

    CVImageBufferRef cvImageBuffer = CMSampleBufferGetImageBuffer((CMSampleBufferRef)buffer);
	CFRetain(cvImageBuffer);

	*w = CVPixelBufferGetWidth(cvImageBuffer);
	*h = CVPixelBufferGetHeight(cvImageBuffer);

    if(CanUseCVTextureCache())
    {
        if(sampling->cvTextureCacheTexture)
        {
            CFRelease(sampling->cvTextureCacheTexture);
            FlushCVTextureCache(sampling->cvTextureCache);
        }
		sampling->cvTextureCacheTexture = CreateTextureFromCVTextureCache(sampling->cvTextureCache, cvImageBuffer, (unsigned)*w, (unsigned)*h);
		if(sampling->cvTextureCacheTexture)
			retTex = GetTextureFromCVTextureCache(sampling->cvTextureCacheTexture);
    }
    else
    {
        retTex = (intptr_t)sampling->glTex[1];

        CVPixelBufferLockBaseAddress(cvImageBuffer,0);
        void* texData = CVPixelBufferGetBaseAddress(cvImageBuffer);

        // TODO: provide unity interface?
        GLES_CHK(glBindTexture(GL_TEXTURE_2D, (GLuint)retTex));
        GLES_CHK(glTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)*w, (GLsizei)*h, 0, GL_BGRA_EXT, GL_UNSIGNED_BYTE, texData));

        CVPixelBufferUnlockBaseAddress(cvImageBuffer,0);

        // swap read and draw textures
        {
            int __temp = sampling->glTex[0];
            sampling->glTex[0] = sampling->glTex[1];
            sampling->glTex[1] = __temp;
        }
    }

    sampling->cvImageBuffer = cvImageBuffer;

	if(UnitySelectedRenderingAPI() == apiOpenGLES2 || UnitySelectedRenderingAPI() == apiOpenGLES3)
	{
		GLES_CHK(glBindTexture(GL_TEXTURE_2D, (GLuint)retTex));
		GLES_CHK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
		GLES_CHK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
		GLES_CHK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
		GLES_CHK(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));
		GLES_CHK(glBindTexture(GL_TEXTURE_2D, 0));
	}

	return retTex;
}

intptr_t CMVideoSampling_LastSampledTexture(CMVideoSampling* sampling)
{
	return GetTextureFromCVTextureCache(sampling->cvTextureCacheTexture);
}
