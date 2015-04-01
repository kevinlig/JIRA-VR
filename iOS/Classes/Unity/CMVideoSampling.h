#pragma once

// small helper for getting texture from CMSampleBuffer
// uses CVOpenGLESTextureCache if available and falls back to simple copy otherwise

typedef struct
CMVideoSampling
{
    // CVOpenGLESTextureCache support
    void*   cvTextureCache;
    void*   cvTextureCacheTexture;
	void*	cvImageBuffer;
    // double-buffered pixel read if no CVOpenGLESTextureCache support
    int     glTex[2];
}
CMVideoSampling;

void CMVideoSampling_Initialize(CMVideoSampling* sampling);
void CMVideoSampling_Uninitialize(CMVideoSampling* sampling);

// buffer is CMSampleBufferRef
intptr_t  CMVideoSampling_SampleBuffer(CMVideoSampling* sampling, void* buffer, size_t* w, size_t* h);
intptr_t  CMVideoSampling_LastSampledTexture(CMVideoSampling* sampling);
