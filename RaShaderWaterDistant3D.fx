//#define USE_FRESNEL

#if _FORCE_1_3_SHADERS_
	#define PS_14
	#define VS_NORMALIZE
#else
	#define USE_SPECULAR
	//#define USE_SHADOWS
	#define PIXEL_CAMSPACE
	#define USE_3DTEXTURE
	#define PS_20
#endif

#define USE_HEIGHTALPHA

//#define DEBUG

#include "shaders/RaShaderWaterBase.fx"