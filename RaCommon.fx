#include "shaders/RaDefines.fx"

#include "shaders/dataTypes.fx"

#ifdef DISABLE_DIFFUSEMAP
	#ifdef DISABLE_BUMPMAP
		#ifndef DISABLE_SPECULAR
			#define DRAW_ONLY_SPEC
		#endif
	#endif
#endif

#ifdef DRAW_ONLY_SPEC
	#define DEFAULT_DIFFUSE_MAP_COLOR vec4(0,0,0,1)
#else
	#define DEFAULT_DIFFUSE_MAP_COLOR vec4(1,1,1,1)
#endif	

// VARIABLES
struct Light
{
	float3	pos;
	float3	dir;
	float4	color;
	float4	specularColor;
	float	attenuation;
};

int			srcBlend = 5;
int			destBlend = 6;
bool		alphaBlendEnable = true;

int			alphaRef = 20;
int			CullMode = 3;	//D3DCULL_CCW
#define FH2_HARDCODED_PARALLAX_BIAS 0.0025

scalar		GlobalTime;
scalar		WindSpeed = 0;

vec4		HemiMapConstants;

//tl: This is a scalar replicated to a vec4 to make 1.3 shaders more efficient (they can't access .rg directly)
vec4		Transparency = 1.0f;

mat4x4	World;
mat4x4	ViewProjection;
mat4x4	WorldViewProjection; 

bool		AlphaTest	= false;

vec4		FogRange : fogRange;
vec4		FogColor : fogColor;

scalar calcFog(scalar w)
{
	half2 fogVals = w*FogRange.xy + FogRange.zw;
	half close = max(fogVals.y, FogColor.w);
	half far = pow(fogVals.x,3);
	return close-far;
}

#ifdef PSVERSION
	#if PSVERSION >= 20
		#define CEXP(constant) constant
	#else
		// These are _d2 on CPU to fit [-1,+1] range
		#define CEXP(constant) (2.f * constant)
	#endif
#endif

#define NO_VAL vec3(1, 1, 0)

vec4 showChannel(
	vec3 diffuse = NO_VAL, 
	vec3 normal = NO_VAL, 
	scalar specular = 0, 
	scalar alpha = 0,
	vec3 shadow = 0,
	vec3 environment = NO_VAL)
{
	vec4 returnVal = vec4(0, 1, 1, 0);
#ifdef DIFFUSE_CHANNEL
	returnVal = vec4(diffuse, 1);
#endif

#ifdef NORMAL_CHANNEL
	returnVal = vec4(normal, 1);
#endif
	
#ifdef SPECULAR_CHANNEL
	returnVal = vec4(specular, specular, specular, 1);
#endif
	
#ifdef ALPHA_CHANNEL
	returnVal = vec4(alpha, alpha, alpha, 1);
#endif
	
#ifdef ENVIRONMENT_CHANNEL
	returnVal = vec4(environment, 1);
#endif
	
#ifdef SHADOW_CHANNEL
	returnVal = vec4(shadow, 1);
#endif
	
	return returnVal;
}



// Common dynamic shadow stuff

#if !defined(SHADOWVERSION) && defined(PSVERSION)
#define SHADOWVERSION PSVERSION
#elif !defined(SHADOWVERSION)
#define SHADOWVERSION 0
#endif

mat4x4 	ShadowProjMat : ShadowProjMatrix;
mat4x4 	ShadowOccProjMat : ShadowOccProjMatrix;
mat4x4 	ShadowTrapMat : ShadowTrapMatrix;

texture ShadowMap : SHADOWMAP;
sampler ShadowMapSampler 
#ifdef _CUSTOMSHADOWSAMPLER_
: register(_CUSTOMSHADOWSAMPLER_)
#endif
= sampler_state
{
	Texture = (ShadowMap);
#if NVIDIA
	MinFilter = Linear;
	MagFilter = Linear;
#else
	MinFilter = Point;
	MagFilter = Point;
#endif
	MipFilter = None;
	AddressU = Clamp;
	AddressV = Clamp;
	AddressW = Clamp;
};

texture ShadowOccluderMap : SHADOWOCCLUDERMAP;
sampler ShadowOccluderMapSampler 
= sampler_state
{
	Texture = (ShadowOccluderMap);
#if NVIDIA
	MinFilter = Linear;
	MagFilter = Linear;
#else
	MinFilter = Point;
	MagFilter = Point;
#endif
	MipFilter = None;
	AddressU = Clamp;
	AddressV = Clamp;
	AddressW = Clamp;
};

//tl: Make _sure_ pos and matrices are in same space!
vec4 calcShadowProjection(vec4 pos, uniform scalar BIAS = -0.003, uniform bool ISOCCLUDER = false)
{
	vec4 texShadow1 =  mul(pos, ShadowTrapMat);

	vec2 texShadow2;
	if(ISOCCLUDER)
		texShadow2 = mul(pos, ShadowOccProjMat).zw;
	else
		texShadow2 = mul(pos, ShadowProjMat).zw;
		
	texShadow2.x += BIAS;
#if !NVIDIA
	texShadow1.z = texShadow2.x;
#else
	texShadow1.z = (texShadow2.x*texShadow1.w)/texShadow2.y; 	// (zL*wT)/wL == zL/wL post homo
#endif

	return texShadow1;
}

//tl: Make _sure_ pos and matrices are in same space!
vec4 calcShadowProjectionExact(vec4 pos, uniform scalar BIAS = -0.003)
{
	vec4 texShadow1 =  mul(pos, ShadowTrapMat);
	vec2 texShadow2 = mul(pos, ShadowProjMat).zw;
	texShadow2.x += BIAS;
	texShadow1.z = texShadow2.x;

	return texShadow1;
}

vec4 getShadowFactorNV(sampler shadowSampler, vec4 shadowCoords, uniform int NSAMPLES = 4, uniform int VERSION = SHADOWVERSION)
{
	if(VERSION == 13)
		return tex2D(shadowSampler, shadowCoords);
	else if(VERSION >= 14)
		return tex2Dproj(shadowSampler, shadowCoords);

	//if(NSAMPLES <= 4)
}

vec4 getShadowFactorExactNV(sampler shadowSampler, vec4 shadowCoords, uniform int NSAMPLES = 4, uniform int VERSION = SHADOWVERSION)
{
	shadowCoords.z *= shadowCoords.w;
	
	if(VERSION == 13)
		return tex2D(shadowSampler, shadowCoords);
	else if(VERSION >= 14)
		return tex2Dproj(shadowSampler, shadowCoords);

	//if(NSAMPLES <= 4)
}

vec4 getShadowFactorExactOther(sampler shadowSampler, vec4 shadowCoords, uniform int NSAMPLES = 4, uniform int VERSION = SHADOWVERSION)
{
	if(VERSION == 13)
	{
		scalar samples = tex2D(shadowSampler, shadowCoords);
		return samples >= saturate(shadowCoords.z);
	}
	else if(VERSION == 14)
	{
		scalar samples = tex2Dproj(shadowSampler, shadowCoords);
		return samples >= saturate(shadowCoords.z);
	}
	else if(VERSION >= 20)
	{
		if(NSAMPLES == 1)
		{
			scalar samples = tex2Dproj(shadowSampler, shadowCoords);
			return samples >= saturate(shadowCoords.z);
		}
		else
		{
			vec4 texel = vec4(0.5 / 1024.0, 0.5 / 1024.0, 0, 0);
			vec4 samples = 0;
			samples.x = tex2Dproj(shadowSampler, shadowCoords);
			samples.y = tex2Dproj(shadowSampler, shadowCoords + vec4(texel.x, 0, 0, 0));
			samples.z = tex2Dproj(shadowSampler, shadowCoords + vec4(0, texel.y, 0, 0));
			samples.w = tex2Dproj(shadowSampler, shadowCoords + texel);
			vec4 cmpbits = samples >= saturate(shadowCoords.z);
			return dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));
		}
	}
}

// Currently fixed to 3 or 4.
vec4 getShadowFactor(sampler shadowSampler, vec4 shadowCoords, uniform int NSAMPLES = 4, uniform int VERSION = SHADOWVERSION)
{
#if NVIDIA
	return getShadowFactorNV(shadowSampler, shadowCoords, NSAMPLES, VERSION);
#else
	return getShadowFactorExactOther(shadowSampler, shadowCoords, NSAMPLES, VERSION);
#endif
}

vec4 getShadowFactorExact(sampler shadowSampler, vec4 shadowCoords, uniform int NSAMPLES = 4, uniform int VERSION = SHADOWVERSION)
{
#if NVIDIA
	return getShadowFactorExactNV(shadowSampler, shadowCoords, NSAMPLES, VERSION);
#else
	return getShadowFactorExactOther(shadowSampler, shadowCoords, NSAMPLES, VERSION);
#endif
}

texture SpecLUT64SpecularColor;
sampler SpecLUT64Sampler = sampler_state
{
	Texture = (SpecLUT64SpecularColor);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = CLAMP;
	AddressV  = CLAMP;
};

texture NormalizationCube;
sampler NormalizationCubeSampler = sampler_state
{
	Texture = (NormalizationCube);
	MipFilter = POINT;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	AddressW  = WRAP;
};

#define NRMDONTCARE 0
#define NRMCUBE		1
#define NRMMATH		2
#define NRMCHEAP	3
vec3 fastNormalize(vec3 invec, uniform int preferMethod = NRMDONTCARE)
{
	if(preferMethod == NRMCUBE)
	{
		return texCUBE(NormalizationCubeSampler, invec) * 2 - 1;
	}
	else if(preferMethod == NRMMATH)
	{
		#if _FORCE_1_3_SHADERS_	
			return invec;
		#else
			return normalize(invec);
		#endif
	}
	else if(preferMethod == NRMCHEAP)
	{
		// Approximate renormalize: V + V * (1 - ||V||2) / 2
		return invec + invec * (1 - dot(invec, invec)) / 2;
	}
	else
	{
#if defined(PSVERSION) && PSVERSION > 20 && NVIDIA
		return normalize(invec);
#else
		return texCUBE(NormalizationCubeSampler, invec) * 2 - 1;
#endif
	}
}
