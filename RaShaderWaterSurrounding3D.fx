

#if _FORCE_1_3_SHADERS_
	#define PS_14
	#define VS_NORMALIZE
#else
	#define USE_FRESNEL
	#define USE_SPECULAR
	//#define USE_SHADOWS
	#define PIXEL_CAMSPACE
	#define USE_3DTEXTURE
	#define PS_20
#endif

#define USE_HEIGHTALPHA
#define NO_LIGHTMAP

#include "shaders/RaShaderWaterBase.fx"