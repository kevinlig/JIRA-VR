
#include "EAGLContextHelper.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

extern "C" bool AllocateRenderBufferStorageFromEAGLLayer(void* eaglContext, void* eaglLayer)
{
    return [(EAGLContext*)eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)eaglLayer];
}
extern "C" void DeallocateRenderBufferStorageFromEAGLLayer(void* eaglContext)
{
    [(EAGLContext*)eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:nil];
}

EAGLContext* CreateContext(EAGLContext* parent)
{
    EAGLContext* ret = nil;

    if(parent)
    {
        ret = [[EAGLContext alloc] initWithAPI:[parent API] sharegroup:[parent sharegroup]];
    }
    else
    {
    	const int startApi = _ios70orNewer ? kEAGLRenderingAPIOpenGLES3 : kEAGLRenderingAPIOpenGLES2;
        for(int api = startApi ; api >= kEAGLRenderingAPIOpenGLES2 && !ret ; --api)
        {
            if (UnityIsRenderingAPISupported(api))
                ret = [[EAGLContext alloc] initWithAPI:api];
        }
    }

    return ret;
}

EAGLContextSetCurrentAutoRestore::EAGLContextSetCurrentAutoRestore(EAGLContext* cur_)
  : old([EAGLContext currentContext]),
    cur(cur_)
{
    if (old != cur)
        [EAGLContext setCurrentContext:cur];
}

EAGLContextSetCurrentAutoRestore::~EAGLContextSetCurrentAutoRestore()
{
    if (old != cur)
        [EAGLContext setCurrentContext:old];
}


extern "C" EAGLContext* UnityCreateContextEAGL(EAGLContext* parent, int api)
{
	const EAGLRenderingAPI	targetApi	= parent ? parent.API : (EAGLRenderingAPI)api;
	EAGLSharegroup*			group		= parent ? parent.sharegroup : nil;

	return [[EAGLContext alloc] initWithAPI:targetApi sharegroup:group];
}

extern "C" void UnityMakeCurrentContextEAGL(EAGLContext* context)
{
	[EAGLContext setCurrentContext:context];
}

