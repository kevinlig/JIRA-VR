
#include "DisplayManager.h"
#include "EAGLContextHelper.h"
#include "GlesHelper.h"
#include "UI/UnityView.h"

#include "UnityAppController.h"
#include "UI/UnityAppController+ViewHandling.h"

#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include "UnityMetalSupport.h"

static DisplayManager* _DisplayManager = nil;
extern bool _ios80orNewer;

@interface DisplayConnection()
@property (readonly, nonatomic)	UnityDisplaySurfaceGLES*	surfaceGLES;
@property (readonly, nonatomic)	UnityDisplaySurfaceMTL*		surfaceMTL;
@end

@implementation DisplayConnection
{
	BOOL						_needRecreateSurface;
	CGSize						_requestedRenderingSize;

	UIScreen*					_screen;
	UIWindow*					_window;
	UIView*						_view;

	CGSize						_screenSize;

	UnityDisplaySurfaceBase*	_surface;
}

@synthesize screen      = _screen;
@synthesize window      = _window;
@synthesize view        = _view;
@synthesize screenSize  = _screenSize;
@synthesize surface		= _surface;

@synthesize surfaceGLES;
- (UnityDisplaySurfaceGLES*)surfaceGLES	{ assert(_surface->api != apiMetal); return (UnityDisplaySurfaceGLES*)_surface; }
@synthesize surfaceMTL;
- (UnityDisplaySurfaceMTL*)surfaceMTL	{ assert(_surface->api == apiMetal); return (UnityDisplaySurfaceMTL*)_surface; }


- (id)init:(UIScreen*)targetScreen
{
	if( (self = [super init]) )
	{
		self->_screen = targetScreen;

		if([targetScreen respondsToSelector:@selector(preferredMode)])
			targetScreen.currentMode = targetScreen.preferredMode;
		if([targetScreen respondsToSelector:@selector(overscanCompensation)])
			targetScreen.overscanCompensation = UIScreenOverscanCompensationInsetApplicationFrame;

		self->_screenSize = targetScreen.currentMode.size;

		self->_needRecreateSurface = NO;
		self->_requestedRenderingSize = CGSizeMake(-1,-1);
	}
	return self;
}

- (void)updateScreenSize
{
	CGSize layerSize	= _view.layer.bounds.size;
	CGFloat	scale		= UnityScreenScaleFactor(_screen);
	_screenSize = CGSizeMake(layerSize.width * scale, layerSize.height * scale);
}

- (id)createView:(BOOL)useForRendering
{
	return [self createView:useForRendering showRightAway:YES];
}

- (id)createView:(BOOL)useForRendering showRightAway:(BOOL)showRightAway;
{
	if(_view == nil)
	{
		_window = [[UIWindow alloc] initWithFrame: _screen.bounds];
		_window.screen = _screen;

		if(_screen == [UIScreen mainScreen])
		{
			_view = [GetAppController() initUnityView];
			NSAssert([_view isKindOfClass:[UnityView class]], @"You MUST use UnityView subclass as unity view");
		}
		else
		{
			_view = [(useForRendering ? [UnityRenderingView alloc] : [UIView alloc]) initWithFrame: _screen.bounds];
		}

		_view.contentScaleFactor = UnityScreenScaleFactor(self.screen);
		[self updateScreenSize];

		if(showRightAway)
		{
			[_window addSubview:_view];
			[_window makeKeyAndVisible];
		}
	}
	return self;
}

- (void)shouldShowWindow:(BOOL)show
{
	_window.hidden = show ? NO : YES;
	_window.screen = show ? _screen : nil;
}

- (void)initRendering
{
	if(_surface == 0)
	{
		int api = UnitySelectedRenderingAPI();
		if(api == apiMetal)
		{
			UnityDisplaySurfaceMTL* surf = new UnityDisplaySurfaceMTL();
			surf->layer			= (CAMetalLayer*)_view.layer;
			surf->device		= UnityGetMetalDevice();
			surf->commandQueue	= [surf->device newCommandQueue];
			_surface = surf;
		}
		else
		{
			UnityDisplaySurfaceGLES* surf = new UnityDisplaySurfaceGLES();
			surf->layer		= (CAEAGLLayer*)_view.layer;
			surf->context	= CreateContext(UnityGetDataContextEAGL());
			_surface = surf;
		}
		_surface->api	= UnitySelectedRenderingAPI();
	}
}


- (void)recreateSurface:(RenderingSurfaceParams)params
{
	[self initRendering];
	[self updateScreenSize];

	bool systemSizeChanged	= _surface->systemW != _screenSize.width || _surface->systemH != _screenSize.height;
	bool msaaChanged		= _supportsMSAA && (_surface->msaaSamples != params.msaaSampleCount);
	bool depthfmtChanged	= _surface->use24bitDepth != params.use24bitDepth;
	bool cvCacheChanged		= _surface->useCVTextureCache != params.useCVTextureCache;

	bool renderSizeChanged  = false;
	if(		(params.renderW > 0 && _surface->targetW != params.renderW)		// changed resolution
		||	(params.renderH > 0 && _surface->targetH != params.renderH)		// changed resolution
		||	(params.renderW <= 0 && _surface->targetW != _surface->systemW) // no longer need intermediate fb
		||	(params.renderH <= 0 && _surface->targetH != _surface->systemH) // no longer need intermediate fb
	)
	{
		renderSizeChanged = true;
	}

	bool recreateSystemSurface		= systemSizeChanged;
	bool recreateRenderingSurface	= systemSizeChanged || renderSizeChanged || msaaChanged || cvCacheChanged;
	bool recreateDepthbuffer		= systemSizeChanged || renderSizeChanged || msaaChanged || depthfmtChanged;


	_surface->use32bitColor		= params.use32bitColor;
	_surface->use24bitDepth		= params.use24bitDepth;
	_surface->useCVTextureCache	= params.useCVTextureCache;

	_surface->systemW = _screenSize.width;
	_surface->systemH = _screenSize.height;

	_surface->targetW = params.renderW > 0 ? params.renderW : _surface->systemW;
	_surface->targetH = params.renderH > 0 ? params.renderH : _surface->systemH;

	_surface->msaaSamples = _supportsMSAA ? params.msaaSampleCount : 0;
	_surface->useCVTextureCache	= params.useCVTextureCache;

	if(UnitySelectedRenderingAPI() == apiMetal)
		recreateSystemSurface = recreateSystemSurface || self.surfaceMTL->systemColorRB == 0;
	else
		recreateSystemSurface = recreateSystemSurface || self.surfaceGLES->systemFB == 0;

	if (recreateSystemSurface)
		CreateSystemRenderingSurface(_surface);
	if(recreateRenderingSurface)
		CreateRenderingSurface(_surface);
	if(recreateDepthbuffer)
		CreateSharedDepthbuffer(_surface);
	if (recreateSystemSurface || recreateRenderingSurface)
		CreateUnityRenderBuffers(_surface);
}

- (void)dealloc
{
	if(_surface)
	{
		DestroySystemRenderingSurface(_surface);
		DestroyRenderingSurface(_surface);
		DestroySharedDepthbuffer(_surface);
		DestroyUnityRenderBuffers(_surface);

		if(UnitySelectedRenderingAPI() == apiMetal)
		{
			self.surfaceMTL->device	= nil;
			self.surfaceMTL->layer	= nil;
		}
		else
		{
			self.surfaceGLES->context	= nil;
			self.surfaceGLES->layer		= nil;
		}
	}

	delete _surface;
	_surface = 0;

	[_view release];
	_view = nil;

	[_window release];
	_window = nil;

	[super dealloc];
}

- (void)present
{
	PreparePresent(self.surface);
	Present(self.surface);

	if(_needRecreateSurface)
	{
		RenderingSurfaceParams params =
		{
			_surface->msaaSamples, (int)_requestedRenderingSize.width, (int)_requestedRenderingSize.height,
			_surface->use32bitColor, _surface->use24bitDepth, _surface->cvTextureCache != 0
		};
		[self recreateSurface:params];

		_needRecreateSurface = NO;
		_requestedRenderingSize = CGSizeMake(_surface->targetW, _surface->targetH);
	}
}


- (void)requestRenderingResolution:(CGSize)res
{
	_requestedRenderingSize = res;
	_needRecreateSurface    = YES;
}
@end


@implementation DisplayManager
{
	NSMutableDictionary*	_displayConnection;
	DisplayConnection*  	_mainDisplay;
}

@synthesize mainDisplay     = _mainDisplay;
- (void)registerScreen:(UIScreen*)screen
{
	NSValue* key = [NSValue valueWithPointer:screen];
	NSValue* val = [NSValue valueWithPointer: [[DisplayConnection alloc] init:screen]];
	[_displayConnection setObject:val forKey:key];
}

- (id)init
{
	if( (self = [super init]) )
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
											  selector:@selector(screenDidConnect:)
											  name:UIScreenDidConnectNotification
											  object:nil
		];

		[[NSNotificationCenter defaultCenter] addObserver:self
											  selector:@selector(screenDidDisconnect:)
											  name:UIScreenDidDisconnectNotification
											  object:nil
		];

		_displayConnection = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
		[[UIScreen screens] enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL* stop) {
			[self registerScreen:(UIScreen*)object];
		}];

		// on pre-ios6 on devices that dont support airplay (iphone3gs) [UIScreen screens] will return empty array
		if([_displayConnection count] == 0)
			[self registerScreen:[UIScreen mainScreen]];

		_mainDisplay = [self display:[UIScreen mainScreen]];
	}
	return self;
}

- (int)displayCount
{
	return (int)_displayConnection.count;
}

- (DisplayConnection*)mainDisplay
{
	return _mainDisplay;
}

- (BOOL)displayAvailable:(UIScreen*)targetScreen;
{
	return [self display:targetScreen] != nil;
}

- (DisplayConnection*)display:(UIScreen*)targetScreen
{
	NSValue* key = [NSValue valueWithPointer:targetScreen];
	NSValue* val = [_displayConnection objectForKey:key];

	return val ? (DisplayConnection*)(val.pointerValue) : nil;
}

- (void)updateDisplayListInUnity
{
	UnityUpdateDisplayList();
}

- (void)enumerateDisplaysWithBlock:(void (^)(DisplayConnection* conn))block
{
	[_displayConnection enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop)
		{
			DisplayConnection* conn = (DisplayConnection*)((NSValue*)obj).pointerValue;
			if(conn.surface != nil)
				block(conn);
		}
	];
}

- (void)prepareFrameRendering
{
	PrepareFrameRendering();
}
- (void)startFrameRendering
{
	[self enumerateDisplaysWithBlock:^(DisplayConnection* conn)
		{
			PrepareRendering(conn.surface);
		}
	];
}
- (void)teardownRendering
{
	[self enumerateDisplaysWithBlock:^(DisplayConnection* conn)
		{
			TeardownRendering(conn.surface);
		}
	];
	TeardownFrameRendering();
}
- (void)present
{
	[self enumerateDisplaysWithBlock:^(DisplayConnection* conn)
		{
			[conn present];
		}
	];
}


- (void)screenDidConnect:(NSNotification*)notification
{
	[self registerScreen: (UIScreen*)[notification object]];
	[self updateDisplayListInUnity];
}

- (void)screenDidDisconnect:(NSNotification*)notification
{
	UIScreen* screen = (UIScreen*)[notification object];
	DisplayConnection* conn = [[DisplayManager Instance] display:screen];
	if(conn != nil)
	{
		UnityDisableRenderBuffers(conn.surface->unityColorBuffer, conn.surface->unityDepthBuffer);

		[_displayConnection removeObjectForKey:[NSValue valueWithPointer:screen]];
		[self updateDisplayListInUnity];
	}
}

+ (void)Initialize
{
	NSAssert(_DisplayManager == nil, @"[DisplayManager Initialize] called after creating handler");
	if(!_DisplayManager)
		_DisplayManager = [[DisplayManager alloc] init];
}

+ (DisplayManager*)Instance
{
	if(!_DisplayManager)
		_DisplayManager = [[DisplayManager alloc] init];

	return _DisplayManager;
}

@end

//==============================================================================
//
//  Unity Interface:

static void EnsureDisplayIsInited(DisplayConnection* conn)
{
	// main screen view will be created in AppController,
	// so we can assume that we need to init secondary display from script
	// meaning: gles + show right away

	if(conn.view == nil)
		[conn createView:YES];

	int api = UnitySelectedRenderingAPI();

	bool needRecreate = false;
	if(conn.surface == 0)		needRecreate = true;
	else if(api == apiMetal)	needRecreate = conn.surfaceMTL->layer == nil;
	else						needRecreate = conn.surfaceGLES->systemFB == 0;

	if(needRecreate)
	{
		RenderingSurfaceParams params = {0, -1, -1, UnityUse32bitDisplayBuffer(), UnityUse24bitDepthBuffer(), false};
		[conn recreateSurface:params];
		{
			// make sure we end up with correct context/fbo setup
			DisplayConnection* main = [[DisplayManager Instance] mainDisplay];

			if(api != apiMetal)
				[EAGLContext setCurrentContext:UnityGetMainScreenContextGLES()];

			PrepareRendering(main.surface);
		}
	}
}

extern "C" int UnityDisplayManager_DisplayCount()
{
	return [[DisplayManager Instance] displayCount];
}

extern "C" bool UnityDisplayManager_DisplayAvailable(void* nativeDisplay)
{
	return [[DisplayManager Instance] displayAvailable:(UIScreen*)nativeDisplay];
}

extern "C" void UnityDisplayManager_DisplaySystemResolution(void* nativeDisplay, int* w, int* h)
{
	DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
	EnsureDisplayIsInited(conn);

	*w = (int)conn.surface->systemW;
	*h = (int)conn.surface->systemH;
}

extern "C" void UnityDisplayManager_DisplayRenderingResolution(void* nativeDisplay, int* w, int* h)
{
	DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
	EnsureDisplayIsInited(conn);

	*w = (int)conn.surface->targetW;
	*h = (int)conn.surface->targetH;
}

extern "C" void UnityDisplayManager_DisplayRenderingBuffers(void* nativeDisplay, void** colorBuffer, void** depthBuffer)
{
	DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
	EnsureDisplayIsInited(conn);

	if(colorBuffer) *colorBuffer = conn.surface->unityColorBuffer;
	if(depthBuffer) *depthBuffer = conn.surface->unityDepthBuffer;
}

extern "C" void UnityDisplayManager_SetRenderingResolution(void* nativeDisplay, int w, int h)
{
	DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
	EnsureDisplayIsInited(conn);

	if((UIScreen*)nativeDisplay == [UIScreen mainScreen])
		UnityRequestRenderingResolution(w,h);
	else
		[conn requestRenderingResolution:CGSizeMake(w,h)];
}

extern "C" void UnityDisplayManager_ShouldShowWindowOnDisplay(void* nativeDisplay, bool show)
{
	DisplayConnection* conn = [[DisplayManager Instance] display:(UIScreen*)nativeDisplay];
	if(conn != [DisplayManager Instance].mainDisplay)
		[conn shouldShowWindow:show];
}

extern "C" EAGLContext* UnityGetMainScreenContextGLES()
{
	return GetMainDisplay().surfaceGLES->context;
}

extern "C" float UnityScreenScaleFactor(UIScreen* screen)
{
#if defined(__IPHONE_8_0)
	if([screen respondsToSelector:@selector(nativeScale)])
		return screen.nativeScale;
#endif
	return screen.scale;
}

extern "C" void UnityStartFrameRendering()
{
	[[DisplayManager Instance] startFrameRendering];
}
