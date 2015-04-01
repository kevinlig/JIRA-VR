#pragma once

#include "GlesHelper.h"

@class EAGLContext;
@class UnityView;

typedef struct
RenderingSurfaceParams
{
	int  msaaSampleCount;
	int  renderW;
	int  renderH;

	bool use32bitColor;
	bool use24bitDepth;
	bool useCVTextureCache;
}
RenderingSurfaceParams;


@interface DisplayConnection : NSObject
- (id)init:(UIScreen*)targetScreen;
- (void)dealloc;

- (id)createView:(BOOL)useForRendering showRightAway:(BOOL)showRightAway;
- (id)createView:(BOOL)useForRendering;
- (void)initRendering;
- (void)recreateSurface:(RenderingSurfaceParams)params;

- (void)shouldShowWindow:(BOOL)show;
- (void)requestRenderingResolution:(CGSize)res;
- (void)present;


@property (readonly, copy, nonatomic)	UIScreen*				screen;
@property (readonly, copy, nonatomic)	UIWindow*				window;
@property (readonly, copy, nonatomic)	UIView*					view;


@property (readonly, nonatomic)			CGSize						screenSize;
@property (readonly, nonatomic)			UnityDisplaySurfaceBase*	surface;
@end


@interface DisplayManager : NSObject
- (int)displayCount;
- (BOOL)displayAvailable:(UIScreen*)targetScreen;
- (DisplayConnection*)display:(UIScreen*)targetScreen;

- (void)updateDisplayListInUnity;

- (void)prepareFrameRendering;
- (void)startFrameRendering;
- (void)present;
- (void)teardownRendering;

- (void)enumerateDisplaysWithBlock:(void (^)(DisplayConnection* conn))block;

+ (void)Initialize;
+ (DisplayManager*)Instance;

@property (readonly, nonatomic)	DisplayConnection*	mainDisplay;
@end

inline DisplayConnection*			GetMainDisplay()
{
	return [DisplayManager Instance].mainDisplay;
}
inline UnityDisplaySurfaceBase*		GetMainDisplaySurface()
{
	return GetMainDisplay().surface;
}
