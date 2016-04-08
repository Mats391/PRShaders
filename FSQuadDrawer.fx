#include "shaders/datatypes.fx"

texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
//texture texture2 : TEXLAYER2;
//texture texture3 : TEXLAYER3;

sampler sampler0point = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler1point = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
//sampler sampler2 = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
//sampler sampler3 = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler0bilin = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler0aniso = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = ANISOTROPIC; MagFilter = ANISOTROPIC; MaxAnisotropy = 8; };

dword dwStencilRef : STENCILREF = 0;
dword dwStencilPass : STENCILPASS = 1; // KEEP

mat4x4 convertPosTo8BitMat : CONVERTPOSTO8BITMAT;

mat4x4 customMtx : CUSTOMMTX;

vec4 scaleDown2x2SampleOffsets[4] : SCALEDOWN2X2SAMPLEOFFSETS;
vec4 scaleDown4x4SampleOffsets[16] : SCALEDOWN4X4SAMPLEOFFSETS;
vec4 scaleDown4x4LinearSampleOffsets[4] : SCALEDOWN4X4LINEARSAMPLEOFFSETS;
vec4 gaussianBlur5x5CheapSampleOffsets[13] : GAUSSIANBLUR5X5CHEAPSAMPLEOFFSETS;
scalar gaussianBlur5x5CheapSampleWeights[13] : GAUSSIANBLUR5X5CHEAPSAMPLEWEIGHTS;
vec4 gaussianBlur15x15HorizontalSampleOffsets[15] : GAUSSIANBLUR15X15HORIZONTALSAMPLEOFFSETS;
scalar gaussianBlur15x15HorizontalSampleWeights[15] : GAUSSIANBLUR15X15HORIZONTALSAMPLEWEIGHTS;
vec4 gaussianBlur15x15VerticalSampleOffsets[15] : GAUSSIANBLUR15X15VERTICALSAMPLEOFFSETS;
scalar gaussianBlur15x15VerticalSampleWeights[15] : GAUSSIANBLUR15X15VERTICALSAMPLEWEIGHTS;
vec4 growablePoisson13SampleOffsets[12] : GROWABLEPOISSON13SAMPLEOFFSETS;

scalar glowHorizOffsets[5] : GLOWHORIZOFFSETS;
scalar glowHorizWeights[5] : GLOWHORIZWEIGHTS;
scalar glowVertOffsets[5] : GLOWVERTOFFSETS;
scalar glowVertWeights[5] : GLOWVERTWEIGHTS;

scalar bloomHorizOffsets[5] : BLOOMHORIZOFFSETS;
scalar bloomVertOffsets[5] : BLOOMVERTOFFSETS;

scalar highPassGate : HIGHPASSGATE; // 3d optics blur; xxxx.yyyy; x - aspect ratio(H/V), y - blur amount(0=no blur, 0.9=full blur)

scalar blurStrength : BLURSTRENGTH; // 3d optics blur; xxxx.yyyy; x - inner radius, y - outer radius

vec2 texelSize : TEXELSIZE;

struct APP2VS_blit
{
    vec2	Pos : POSITION0;
    vec2	TexCoord0 : TEXCOORD0;
};

struct VS2PS_4TapFilter
{
    vec4	Pos 		 : POSITION;
    vec2	FilterCoords[4] : TEXCOORD0;
};

struct VS2PS_5SampleFilter
{
    vec4	Pos 		    : POSITION;
    vec2	TexCoord0		: TEXCOORD0;
    vec4	FilterCoords[2] : TEXCOORD1;
};

struct VS2PS_blit_
{
    vec4	Pos 		: POSITION;
    vec2	TexCoord0	: TEXCOORD0;
};


#if _FORCE_1_3_SHADERS_

struct VS2PS_blit
{
    vec4	Pos 		: POSITION;
    vec2	TexCoord0	: TEXCOORD0;
    vec2	TexCoord1	: TEXCOORD1;
    vec2	TexCoord2	: TEXCOORD2;
    vec2	TexCoord3	: TEXCOORD3;
};


struct VS2PS_5SampleFilter14
{
    vec4	Pos 		    : POSITION;
    vec2	FilterCoords[4] : TEXCOORD0;
};

VS2PS_blit vsDx9_blit(APP2VS_blit indata)
{
	VS2PS_blit outdata;
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0 + scaleDown2x2SampleOffsets[0];
 	outdata.TexCoord1 = indata.TexCoord0 + scaleDown2x2SampleOffsets[1];
 	outdata.TexCoord2 = indata.TexCoord0 + scaleDown2x2SampleOffsets[2];
 	outdata.TexCoord3 = indata.TexCoord0 + scaleDown2x2SampleOffsets[3];
	return outdata;
}

#else

struct VS2PS_blit
{
    vec4	Pos 		: POSITION;
    vec2	TexCoord0	: TEXCOORD0;
};

struct VS2PS_5SampleFilter14
{
    vec4	Pos 		    : POSITION;
    vec2	FilterCoords[5] : TEXCOORD0;
};

VS2PS_blit vsDx9_blit(APP2VS_blit indata)
{
	VS2PS_blit outdata;	
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0;
	return outdata;
}

VS2PS_blit vsDx9_blitCustom(APP2VS_blit indata)
{
	VS2PS_blit outdata;	
 	outdata.Pos = mul(vec4(indata.Pos.x, indata.Pos.y, 0, 1), customMtx);
 	outdata.TexCoord0 = indata.TexCoord0;
	return outdata;
}

#endif

struct VS2PS_tr_blit
{
    vec4	Pos 		: POSITION;
    vec2	TexCoord0	: TEXCOORD0;
};

VS2PS_tr_blit vsDx9_tr_blit(APP2VS_blit indata) // TODO: implement support for old shader versions. TODO: try to use fakeHDRWeights as variables
{
	VS2PS_tr_blit outdata;
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0;
	return outdata;
}

const float tr_gauss[9] = {0.087544737,0.085811235,0.080813978,0.073123511,0.063570527,0.053098567,0.042612598,0.032856512,0.024340702};

vec4 psDx9_tr_opticsBlurH(VS2PS_tr_blit indata) : COLOR
{
    vec1 aspectRatio = highPassGate/1000.f; // floor() isn't used for perfomance reasons
    vec1 blurSize = 0.0033333333/aspectRatio;
    vec4 color = tex2D(sampler0point, indata.TexCoord0)*tr_gauss[0];
    for (int i=1;i<9;i++)
    {
        color += tex2D(sampler0bilin, vec2(indata.TexCoord0.x + i*blurSize, indata.TexCoord0.y))*tr_gauss[i];
        color += tex2D(sampler0bilin, vec2(indata.TexCoord0.x - i*blurSize, indata.TexCoord0.y))*tr_gauss[i];
    }
    return color;
}

vec4 psDx9_tr_opticsBlurV(VS2PS_tr_blit indata) : COLOR
{
    vec1 blurSize = 0.0033333333; // 1/300 - no ghosting for vertical resolutions up to 1200 pixels
    vec4 color = tex2D(sampler0point, indata.TexCoord0)*tr_gauss[0];
    for (int i=1;i<9;i++)
    {
        color += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y + i*blurSize))*tr_gauss[i];
        color += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y - i*blurSize))*tr_gauss[i];
    }
    return color;
}

vec4 psDx9_tr_opticsNoBlurCircle(VS2PS_tr_blit indata) : COLOR
{
   vec1 aspectRatio = highPassGate/1000.f; // aspect ratio (1.333 for 4:3) (floor() isn't used for perfomance reasons)
   vec1 blurAmountMod = frac(highPassGate)/0.9; // used for the fade-in effect
   vec1 radius1 = blurStrength/1000.f; // 0.2 by default (floor() isn't used for perfomance reasons)
   vec1 radius2 = frac(blurStrength); // 0.25 by default
   vec1 dist = length((indata.TexCoord0-0.5)*float2(aspectRatio,1)); // get distance from the center of the screen
   vec1 blurAmount = saturate((dist - radius1)/(radius2-radius1))*blurAmountMod;
   return vec4(tex2D(sampler0aniso, indata.TexCoord0).rgb, blurAmount);
}

vec4 psDx9_tr_PassThrough_point(VS2PS_tr_blit indata) : COLOR
{
	return tex2D(sampler0point, indata.TexCoord0);
}
vec4 psDx9_tr_PassThrough_aniso(VS2PS_tr_blit indata) : COLOR
{
	return tex2D(sampler0aniso, indata.TexCoord0);
}

VS2PS_blit_ vsDx9_blitMagnified(APP2VS_blit indata)
{
	VS2PS_blit_ outdata;
 	outdata.Pos = vec4(indata.Pos.x*1.1, indata.Pos.y*1.1, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0;
	return outdata;
}

VS2PS_4TapFilter vsDx9_4TapFilter(APP2VS_blit indata, uniform vec4 offsets[4])
{
	VS2PS_4TapFilter outdata;
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);

 	for (int i = 0; i < 4; ++i)
 	{
 		outdata.FilterCoords[i] = indata.TexCoord0 + offsets[i].xy;
 	}

	return outdata;
}

VS2PS_5SampleFilter vsDx9_5SampleFilter(APP2VS_blit indata, uniform scalar offsets[5], uniform bool horizontal)
{
	VS2PS_5SampleFilter outdata;
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);

	if(horizontal)
	{
		outdata.TexCoord0 = indata.TexCoord0 + float2(offsets[4],0);
	}
	else
	{
		outdata.TexCoord0 = indata.TexCoord0 + float2(0,offsets[4]);
	}

	for(int i=0; i<2; ++i)
	{
		if(horizontal)
		{
			outdata.FilterCoords[i].xy = indata.TexCoord0.xy + float2(offsets[i*2],0);
			outdata.FilterCoords[i].zw = indata.TexCoord0.xy + float2(offsets[i*2+1],0);
		}
		else
		{
			outdata.FilterCoords[i].xy = indata.TexCoord0.xy + float2(0,offsets[i*2]);
			outdata.FilterCoords[i].zw = indata.TexCoord0.xy + float2(0,offsets[i*2+1]);
		}
	}

	return outdata;
}

VS2PS_5SampleFilter14 vsDx9_5SampleFilter14(APP2VS_blit indata, uniform scalar offsets[5], uniform bool horizontal)
{
	VS2PS_5SampleFilter14 outdata;
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);

#if !_FORCE_1_3_SHADERS_
	for(int i=0; i<5; ++i)
#else
	for(int i=0; i<4; ++i)
#endif
	{
		if(horizontal)
		{
			outdata.FilterCoords[i] = indata.TexCoord0 + float2(offsets[i],0);
		}
		else
		{
			outdata.FilterCoords[i] = indata.TexCoord0 + float2(0,offsets[i]);
		}
	}

	return outdata;
}

struct VS2PS_Down4x4Filter14
{
    vec4	Pos 		: POSITION;
    vec2	TexCoord0	: TEXCOORD0;
    vec2	TexCoord1	: TEXCOORD1;
    vec2	TexCoord2	: TEXCOORD2;
    vec2	TexCoord3	: TEXCOORD3;
};

VS2PS_Down4x4Filter14 vsDx9_Down4x4Filter14(APP2VS_blit indata)
{
	VS2PS_Down4x4Filter14 outdata;
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0 + scaleDown4x4SampleOffsets[0];
 	outdata.TexCoord1 = indata.TexCoord0 + scaleDown4x4SampleOffsets[4]*2;
 	outdata.TexCoord2 = indata.TexCoord0 + scaleDown4x4SampleOffsets[8]*2;
 	outdata.TexCoord3 = indata.TexCoord0 + scaleDown4x4SampleOffsets[12]*2;
	return outdata;
}

vec4 psDx9_FSBMPassThrough(VS2PS_blit indata) : COLOR
{
	return tex2D(sampler0point, indata.TexCoord0);
}

vec4 psDx9_FSBMPassThroughBilinear(VS2PS_blit indata) : COLOR
{
	return tex2D(sampler0bilin, indata.TexCoord0);
}

vec4 psDx9_FSBMPassThroughSaturateAlpha(VS2PS_blit indata) : COLOR
{
	vec4 color =  tex2D(sampler0point, indata.TexCoord0);
	color.a = 1.f;
	return color;
}


vec4 psDx9_FSBMCopyOtherRGBToAlpha(VS2PS_blit indata) : COLOR
{
	vec4 color = tex2D(sampler0point, indata.TexCoord0);
	
	vec3 avg = 1.0/3;
	
	color.a = dot(avg, color);
	
	return color;
}


vec4 psDx9_FSBMConvertPosTo8Bit(VS2PS_blit indata) : COLOR
{
	vec4 viewPos = tex2D(sampler0point, indata.TexCoord0);
	viewPos /= 50;
	viewPos = viewPos * 0.5 + 0.5;
	return viewPos;
}

vec4 psDx9_FSBMConvertNormalTo8Bit(VS2PS_blit indata) : COLOR
{
	return normalize(tex2D(sampler0point, indata.TexCoord0)) / 2 + 0.5;
	//return tex2D(sampler0point, indata.TexCoord0).a;
}

vec4 psDx9_FSBMConvertShadowMapFrontTo8Bit(VS2PS_blit indata) : COLOR
{
	vec4 depths = tex2D(sampler0point, indata.TexCoord0);
	return depths;
}

vec4 psDx9_FSBMConvertShadowMapBackTo8Bit(VS2PS_blit indata) : COLOR
{
	return -tex2D(sampler0point, indata.TexCoord0);
}

vec4 psDx9_FSBMScaleUp4x4LinearFilter(VS2PS_blit indata) : COLOR
{
	return tex2D(sampler0bilin, indata.TexCoord0);
}

#if _FORCE_1_3_SHADERS_

vec4 psDx9_FSBMScaleDown2x2Filter(VS2PS_blit indata) : COLOR
{
	vec4 accum;
	accum = tex2D(sampler0point, indata.TexCoord0);
	accum += tex2D(sampler0point, indata.TexCoord1);
	accum += tex2D(sampler0point, indata.TexCoord2);
	accum += tex2D(sampler0point, indata.TexCoord3);

	return accum * 0.25; // div 4
}

#else

vec4 psDx9_FSBMScaleDown2x2Filter(VS2PS_blit indata) : COLOR
{
	vec4 accum;
	accum = tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[0]);
	accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[1]);
	accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[2]);
	accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown2x2SampleOffsets[3]);

	return accum * 0.25; // div 4
}

#endif

vec4 psDx9_FSBMScaleDown4x4Filter(VS2PS_blit indata) : COLOR
{
	vec4 accum = 0;

	for(int tap = 0; tap < 16; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + scaleDown4x4SampleOffsets[tap]);

	return accum * 0.0625; // div 16
}

vec4 psDx9_FSBMScaleDown4x4Filter14(VS2PS_Down4x4Filter14 indata) : COLOR
{
	vec4 accum;
	accum = tex2D(sampler0bilin, indata.TexCoord0);
	accum += tex2D(sampler0bilin, indata.TexCoord1);
	accum += tex2D(sampler0bilin, indata.TexCoord2);
	accum += tex2D(sampler0bilin, indata.TexCoord3);

	return accum * 0.25; // div 4
}

vec4 psDx9_FSBMScaleDown4x4LinearFilter(VS2PS_4TapFilter indata) : COLOR
{
	vec4 accum = float4(0,0,0,0);
	accum = tex2D(sampler0bilin, indata.FilterCoords[0].xy);
	accum += tex2D(sampler0bilin, indata.FilterCoords[1].xy);
	accum += tex2D(sampler0bilin, indata.FilterCoords[2].xy);
	accum += tex2D(sampler0bilin, indata.FilterCoords[3].xy);

	return accum/4;
}

vec4 psDx9_FSBMGaussianBlur5x5CheapFilter(VS2PS_blit indata) : COLOR
{
	vec4 accum = 0;

	for(int tap = 0; tap < 13; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur5x5CheapSampleOffsets[tap]) * gaussianBlur5x5CheapSampleWeights[tap];

	return accum;
}

vec4 psDx9_FSBMGaussianBlur5x5CheapFilterBlend(VS2PS_blit indata) : COLOR
{
	vec4 accum = 0;

	for(int tap = 0; tap < 13; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur5x5CheapSampleOffsets[tap]) * gaussianBlur5x5CheapSampleWeights[tap];

	accum.a = blurStrength;
	return accum;
}

vec4 psDx9_FSBMGaussianBlur15x15HorizontalFilter(VS2PS_blit indata) : COLOR
{
	vec4 accum = 0;

	for(int tap = 0; tap < 15; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur15x15HorizontalSampleOffsets[tap]) * gaussianBlur15x15HorizontalSampleWeights[tap];

	return accum;
}

vec4 psDx9_FSBMGaussianBlur15x15VerticalFilter(VS2PS_blit indata) : COLOR
{
	vec4 accum = 0;

	for(int tap = 0; tap < 15; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + gaussianBlur15x15VerticalSampleOffsets[tap]) * gaussianBlur15x15VerticalSampleWeights[tap];

	return accum;
}

vec4 psDx9_FSBMGaussianBlur15x15HorizontalFilter2(VS2PS_blit indata) : COLOR
{
	vec4 accum = 0;

	for(int tap = 0; tap < 15; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + 2*gaussianBlur15x15HorizontalSampleOffsets[tap]) * gaussianBlur15x15HorizontalSampleWeights[tap];

	return accum;
}

vec4 psDx9_FSBMGaussianBlur15x15VerticalFilter2(VS2PS_blit indata) : COLOR
{
	vec4 accum = 0;

	for(int tap = 0; tap < 15; ++tap)
		accum += tex2D(sampler0point, indata.TexCoord0 + 2*gaussianBlur15x15VerticalSampleOffsets[tap]) * gaussianBlur15x15VerticalSampleWeights[tap];

	return accum;
}

vec4 psDx9_FSBMGrowablePoisson13Filter(VS2PS_blit indata) : COLOR
{
	vec4 accum = 0;
	scalar samples = 1;

	accum = tex2D(sampler0point, indata.TexCoord0);
	for(int tap = 0; tap < 11; ++tap)
	{
//		vec4 v = tex2D(sampler0point, indata.TexCoord0 + growablePoisson13SampleOffsets[tap]*1);
		vec4 v = tex2D(sampler0point, indata.TexCoord0 + growablePoisson13SampleOffsets[tap]*0.1*accum.a);
		if(v.a > 0)
		{
			accum.rgb += v;
			samples += 1;
		}
	}

//return tex2D(sampler0point, indata.TexCoord0);
	return accum / samples;
}

vec4 psDx9_FSBMGrowablePoisson13AndDilationFilter(VS2PS_blit indata) : COLOR
{
	vec4 center = tex2D(sampler0point, indata.TexCoord0);
	
	vec4 accum = 0;
	if(center.a > 0)
	{
		accum.rgb = center;
		accum.a = 1;
	}

	for(int tap = 0; tap < 11; ++tap)
	{
		scalar scale = 3*(center.a);
		if(scale == 0)
			scale = 1.5;
		vec4 v = tex2D(sampler0point, indata.TexCoord0 + growablePoisson13SampleOffsets[tap]*scale);
		if(v.a > 0)
		{
			accum.rgb += v;
			accum.a += 1;
		}
	}

//	if(center.a == 0)
//	{
//		accum.gb = center.gb;
//		accum.r / accum.a;
//		return accum;
//	}
//	else
		return accum / accum.a;
}

vec4 psDx9_FSBMGlowFilter(VS2PS_5SampleFilter indata, uniform scalar weights[5], uniform bool horizontal) : COLOR
{
	vec4 color = weights[0] * tex2D(sampler0bilin, indata.FilterCoords[0].xy);
	color += weights[1] * tex2D(sampler0bilin, indata.FilterCoords[0].zw);
	color += weights[2] * tex2D(sampler0bilin, indata.FilterCoords[1].xy);
	color += weights[3] * tex2D(sampler0bilin, indata.FilterCoords[1].zw);
	color += weights[4] * tex2D(sampler0bilin, indata.TexCoord0);

	return color;
}

vec4 psDx9_FSBMGlowFilter14(VS2PS_5SampleFilter14 indata, uniform scalar weights[5]) : COLOR
{
	vec4 color = weights[0] * tex2D(sampler0bilin, indata.FilterCoords[0].xy);
	color += weights[1] * tex2D(sampler0bilin, indata.FilterCoords[1].xy);
	color += weights[2] * tex2D(sampler0bilin, indata.FilterCoords[2].xy);
	color += weights[3] * tex2D(sampler0bilin, indata.FilterCoords[3].xy);
#if !_FORCE_1_3_SHADERS_
	color += weights[4] * tex2D(sampler0bilin, indata.FilterCoords[4].xy);
#endif

	return color;
}

vec4 psDx9_FSBMHighPassFilter(VS2PS_blit indata) : COLOR
{
	vec4 color = tex2D(sampler0point, indata.TexCoord0);

	color -= highPassGate;

#if _FORCE_1_3_SHADERS_
	return saturate(color);
#else
	return max(color,0);
#endif
}

vec4 psDx9_FSBMHighPassFilterFade(VS2PS_blit indata) : COLOR
{
	vec4 color = tex2D(sampler0point, indata.TexCoord0);

	color.rgb = saturate(color.rgb - highPassGate);
	color.a = blurStrength;
	
	return color;
}

vec4 psDx9_FSBMClear(VS2PS_blit_ indata) : COLOR
{
	return float4(0,0,0,0);
}

vec4 psDx9_FSBMExtractGlowFilter(VS2PS_blit indata) : COLOR
{
	vec4 color = tex2D(sampler0point, indata.TexCoord0);

	color.rgb = color.a;
	color.a = 1;

	return color;
}

vec4 psDx9_FSBMExtractHDRFilterFade(VS2PS_blit indata) : COLOR
{
	vec4 color = tex2D(sampler0point, indata.TexCoord0);

	color.rgb = saturate(color.a - highPassGate);
	color.a = blurStrength;

	return color;
}

vec4 psDx9_FSBMLuminancePlusBrightPassFilter(VS2PS_blit indata) : COLOR
{
	vec4 color = tex2D(sampler0point, indata.TexCoord0) * highPassGate;
//	float luminance = dot(color, float3(0.299f, 0.587f, 0.114f));
	return color;
}

vec4 psDx9_FSBMBloomFilter(VS2PS_5SampleFilter indata, uniform bool is_blur) : COLOR
{
	vec4 color = vec4(0.f,0.f,0.f,0.f);
	
	if( is_blur )
	{
		color.a = blurStrength;
	}
	
	color.rgb += tex2D(sampler0bilin, indata.TexCoord0.xy);

	for(int i=0; i<2; ++i)
	{
		color.rgb += tex2D(sampler0bilin, indata.FilterCoords[i].xy);
		color.rgb += tex2D(sampler0bilin, indata.FilterCoords[i].zw);
	}

	color.rgb /= 5;
	return color;
}

vec4 psDx9_FSBMBloomFilter14(VS2PS_5SampleFilter14 indata, uniform bool is_blur) : COLOR
{
	vec4 color = vec4(0.f,0.f,0.f,0.f);

	if( is_blur )
	{
		color.a = blurStrength;
	}
	
#if !_FORCE_1_3_SHADERS_
	for(int i=0; i<5; ++i)
	{
		color.rgb += tex2D(sampler0bilin, indata.FilterCoords[i]);
	}
	color.rgb /= 5;
#else
	for(int i=0; i<4; ++i)
	{
		color.rgb += tex2D(sampler0bilin, indata.FilterCoords[i]);
	}
	color.rgb /= 4;
#endif
	return color;
}

vec4 psDx9_FSBMScaleUpBloomFilter(VS2PS_blit indata) : COLOR
{
	scalar offSet = 0.01;

	vec4 close = tex2D(sampler0point, indata.TexCoord0);
/*	
	close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x - offSet*4.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x - offSet*3.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x - offSet*2.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x - offSet*1.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x + offSet*1.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x + offSet*2.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x + offSet*3.5), indata.TexCoord0.y));
	close += tex2D(sampler0bilin, vec2((indata.TexCoord0.x + offSet*4.5), indata.TexCoord0.y));

	close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y - offSet*4.5));
	close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y - offSet*3.5));
	close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y - offSet*2.5));
	close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y - offSet*1.5));
	close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y + offSet*1.5));
	close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y + offSet*2.5));
	close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y + offSet*3.5));
	//close += tex2D(sampler0bilin, vec2(indata.TexCoord0.x, indata.TexCoord0.y + offSet*4.5));

	return close / 16;
*/
	return close;
}

vec4 psDx9_FSBMBlur(VS2PS_blit indata) : COLOR
{
	return vec4( tex2D(sampler0point, indata.TexCoord0).rgb, blurStrength );
}

//
//	Techniques
//

#if !(_FORCE_1_4_SHADERS_ || _FORCE_1_3_SHADERS_)
technique Blit
{
	pass FSBMPassThrough
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMPassThrough();
	}

	pass FSBMBlend
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMPassThrough();
	}

	pass FSBMConvertPosTo8Bit
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMConvertPosTo8Bit();
	}

	pass FSBMConvertNormalTo8Bit
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMConvertNormalTo8Bit();
	}

	pass FSBMConvertShadowMapFrontTo8Bit
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMConvertShadowMapFrontTo8Bit();
	}

	pass FSBMConvertShadowMapBackTo8Bit
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMConvertShadowMapBackTo8Bit();
	}

	pass FSBMScaleUp4x4LinearFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMScaleUp4x4LinearFilter();
	}

	pass FSBMScaleDown2x2Filter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMScaleDown2x2Filter();
	}

	pass FSBMScaleDown4x4Filter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMScaleDown4x4Filter();
	}

	pass FSBMScaleDown4x4LinearFilter // pass 9, tinnitus
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_4TapFilter(scaleDown4x4LinearSampleOffsets);//vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMScaleDown4x4LinearFilter();
	}

	pass FSBMGaussianBlur5x5CheapFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMGaussianBlur5x5CheapFilter();
	}

	pass FSBMGaussianBlur15x15HorizontalFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMGaussianBlur15x15HorizontalFilter();//psDx9_FSBMGaussianBlur15x15HorizontalFilter2();
	}

	pass FSBMGaussianBlur15x15VerticalFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMGaussianBlur15x15VerticalFilter();//psDx9_FSBMGaussianBlur15x15VerticalFilter2();
	}

	pass FSBMGrowablePoisson13Filter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMGrowablePoisson13Filter();
	}

	pass FSBMGrowablePoisson13AndDilationFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMGrowablePoisson13AndDilationFilter();
	}

	pass FSBMScaleUpBloomFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMScaleUpBloomFilter();
	}

	pass FSBMPassThroughSaturateAlpha
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMPassThroughSaturateAlpha();
	}

	pass FSBMCopyOtherRGBToAlpha
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		ColorWriteEnable = ALPHA;
		
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMCopyOtherRGBToAlpha();
	}

	// X-Pack additions
	pass FSBMPassThroughBilinear
	{
  		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_tr_blit();
		PixelShader = compile ps_1_4 psDx9_tr_PassThrough_point();
	}

	pass FSBMPassThroughBilinearAdditive
	{
/* 		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE; */
		//VertexShader = compile vs_1_1 vsDx9_blit();
		//PixelShader = compile PS2_EXT psDx9_FSBMPassThroughBilinear();

		  /*ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;*/
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = ZERO;
		DestBlend = ONE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_tr_blit();
		PixelShader = compile ps_1_4 psDx9_tr_PassThrough_point();
	}

	pass FSMBlur
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMScaleUp4x4LinearFilterAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMGaussianBlur5x5CheapFilterBlend
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMGaussianBlur5x5CheapFilterAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMScaleUpBloomFilterAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMGlowHorizontalFilter // pass 25
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_tr_blit();
		PixelShader = compile PS2_EXT psDx9_tr_opticsBlurH();
	}

	pass FSBMGlowVerticalFilter // pass 26
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_tr_blit();
		PixelShader = compile PS2_EXT psDx9_tr_opticsBlurV();
	}

	pass FSBMGlowVerticalFilterAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMHighPassFilter
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMHighPassFilterFade  // pass 29
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_tr_blit();
		PixelShader = compile ps_1_4 psDx9_tr_PassThrough_point();
	}

	pass FSBMExtractGlowFilter
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMExtractHDRFilterFade
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMClearAlpha
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		ColorWriteEnable = ALPHA;

		VertexShader = compile vs_1_1 vsDx9_blitMagnified(); // is this needed? -mosq
		PixelShader = compile ps_1_4 psDx9_FSBMClear();
	}

	pass FSBMAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}
	
	pass FSBMAdditiveBilinear  // pass 34
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		VertexShader = compile vs_1_1 vsDx9_tr_blit();
		PixelShader = compile PS2_EXT psDx9_tr_opticsNoBlurCircle();
	}

	pass FSBMBloomHorizFilter   // pass 35
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_tr_blit();
		PixelShader = compile ps_1_4 psDx9_tr_PassThrough_point();
	}

	pass FSBMBloomHorizFilterAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMBloomVertFilter   // pass 37
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_tr_blit();
		PixelShader = compile ps_1_4 psDx9_tr_PassThrough_point();
	}
	
	pass FSBMBloomVertFilterAdditive
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMBloomVertFilterBlur
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMBloomVertFilterAdditiveBlur
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMLuminancePlusBrightPassFilter
	{
		VertexShader = NULL;
		PixelShader = NULL;
	}

	pass FSBMScaleDown4x4LinearFilterHorizontal // pass 42
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_tr_blit();
		PixelShader = compile ps_1_4 psDx9_tr_PassThrough_aniso();
	}

	pass FSBMScaleDown4x4LinearFilterVertical // pass 43
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_tr_blit();
		PixelShader = compile ps_1_4 psDx9_tr_PassThrough_aniso();
	}

	pass FSBMClear
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_4 psDx9_FSBMClear();
	}
	
	pass FSBMBlendCustom
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		VertexShader = compile vs_1_1 vsDx9_blitCustom();
		PixelShader = compile ps_1_1 psDx9_FSBMPassThrough();
	}

}
#else

technique Blit // formerly known as Blit_1_4
{
	pass FSBMPassThrough
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMPassThrough();
	}

	pass FSBMBlend
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMPassThrough();
	}

	pass FSBMConvertPosTo8Bit
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		//PixelShader = compile PS2_EXT psDx9_FSBMConvertPosTo8Bit();
		PixelShader = compile ps_1_1 psDx9_FSBMConvertPosTo8Bit();
	}

	pass FSBMConvertNormalTo8Bit
	{
/*		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMConvertNormalTo8Bit();
		*/
	}

	pass FSBMConvertShadowMapFrontTo8Bit
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMConvertShadowMapFrontTo8Bit();
	}

	pass FSBMConvertShadowMapBackTo8Bit
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMConvertShadowMapBackTo8Bit();
	}

	pass FSBMScaleUp4x4LinearFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMScaleUp4x4LinearFilter();
	}

	pass FSBMScaleDown2x2Filter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMScaleDown2x2Filter();
	}

	pass FSBMScaleDown4x4Filter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_Down4x4Filter14();
		PixelShader = compile LOWPSMODEL psDx9_FSBMScaleDown4x4LinearFilter();
		
	}

	pass FSBMScaleDown4x4LinearFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_4TapFilter(scaleDown4x4LinearSampleOffsets);
		PixelShader = compile LOWPSMODEL psDx9_FSBMScaleDown4x4LinearFilter();
	}

	pass FSBMGaussianBlur5x5CheapFilter
	{
		/*ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMGaussianBlur5x5CheapFilter();
		*/
	}

	pass FSBMGaussianBlur15x15HorizontalFilter
	{
	/*	ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMGaussianBlur15x15HorizontalFilter();//psDx9_FSBMGaussianBlur15x15HorizontalFilter2();
		*/
	}

	pass FSBMGaussianBlur15x15VerticalFilter
	{
		/*ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMGaussianBlur15x15VerticalFilter();//psDx9_FSBMGaussianBlur15x15VerticalFilter2();
		*/
	}

	pass FSBMGrowablePoisson13Filter
	{
		/*ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMGrowablePoisson13Filter();
		*/
	}

	pass FSBMGrowablePoisson13AndDilationFilter
	{
		/*ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMGrowablePoisson13AndDilationFilter();
		*/
	}

	pass FSBMScaleUpBloomFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMScaleUpBloomFilter();
	}
	
	pass FSBMPassThroughSaturateAlpha
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMPassThroughSaturateAlpha();
	}
	
	pass FSBMCopyOtherRGBToAlpha
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		ColorWriteEnable = ALPHA;
		
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMCopyOtherRGBToAlpha();
	}
	
	// X-Pack additions	
	pass FSBMPassThroughBilinear
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMPassThroughBilinear();
	}

	pass FSBMPassThroughBilinearAdditive
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMPassThroughBilinear();
	}

	pass FSMBlur
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMBlur();
	}
	
	pass FSBMScaleUp4x4LinearFilterAdditive
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMScaleUp4x4LinearFilter();
	}
	
	pass FSBMGaussianBlur5x5CheapFilterBlend
	{
/*	
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		AlphaTestEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMGaussianBlur5x5CheapFilterBlend();
*/		
	}

	pass FSBMGaussianBlur5x5CheapFilterAdditive
	{
/*
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile PS2_EXT psDx9_FSBMGaussianBlur5x5CheapFilter();
*/		
	}
	
	pass FSBMScaleUpBloomFilterAdditive
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMScaleUpBloomFilter();
	}

	pass FSBMGlowHorizontalFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		VertexShader = compile vs_1_1 vsDx9_5SampleFilter14(glowHorizOffsets, true);
		PixelShader = compile LOWPSMODEL psDx9_FSBMGlowFilter14(glowHorizWeights);
	}
	
	pass FSBMGlowVerticalFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		VertexShader = compile vs_1_1 vsDx9_5SampleFilter14(glowVertOffsets, false);
		PixelShader = compile LOWPSMODEL psDx9_FSBMGlowFilter14(glowVertWeights);
	}

	pass FSBMGlowVerticalFilterAdditive
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

		VertexShader = compile vs_1_1 vsDx9_5SampleFilter14(glowVertOffsets, false);
		PixelShader = compile LOWPSMODEL psDx9_FSBMGlowFilter14(glowVertWeights);
	}

	pass FSBMHighPassFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMHighPassFilter();	
	}

	pass FSBMHighPassFilterFade
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = INVSRCALPHA;
		DestBlend = SRCALPHA;

		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMHighPassFilterFade();	
	}

	pass FSBMExtractGlowFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMExtractGlowFilter();
	}

	pass FSBMExtractHDRFilterFade
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = INVSRCALPHA;
		DestBlend = SRCALPHA;

		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMExtractHDRFilterFade();
	}

	pass FSBMClearAlpha
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		ColorWriteEnable = ALPHA;

		VertexShader = compile vs_1_1 vsDx9_blitMagnified();
		PixelShader = compile LOWPSMODEL psDx9_FSBMClear();
	}

	pass FSBMAdditive
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = ONE;
		DestBlend = ONE;

		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMPassThrough();
	}
	
	pass FSBMAdditiveBilinear
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = ONE;
		DestBlend = ONE;

		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMPassThroughBilinear();
	}
	
	pass FSBMBloomHorizFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		VertexShader = compile vs_1_1 vsDx9_5SampleFilter14(bloomHorizOffsets, true);
		PixelShader = compile LOWPSMODEL psDx9_FSBMBloomFilter14(false);
	}

	pass FSBMBloomHorizFilterAdditive
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = ONE;
		DestBlend = ONE;

		VertexShader = compile vs_1_1 vsDx9_5SampleFilter14(bloomHorizOffsets, true);
		PixelShader = compile LOWPSMODEL psDx9_FSBMBloomFilter14(false);
	}

	pass FSBMBloomVertFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		VertexShader = compile vs_1_1 vsDx9_5SampleFilter14(bloomVertOffsets, false);
		PixelShader = compile LOWPSMODEL psDx9_FSBMBloomFilter14(false);
	}
	
	pass FSBMBloomVertFilterAdditive
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = ONE;
		DestBlend = ONE;

		VertexShader = compile vs_1_1 vsDx9_5SampleFilter14(bloomVertOffsets, false);
		PixelShader = compile LOWPSMODEL psDx9_FSBMBloomFilter14(false);
	}

	pass FSBMBloomVertFilterBlur
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		VertexShader = compile vs_1_1 vsDx9_5SampleFilter14(bloomVertOffsets, false);
		PixelShader = compile LOWPSMODEL psDx9_FSBMBloomFilter14(true);
	}

	pass FSBMBloomVertFilterAdditiveBlur
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = ONE;

		VertexShader = compile vs_1_1 vsDx9_5SampleFilter14(bloomVertOffsets, false);
		PixelShader = compile LOWPSMODEL psDx9_FSBMBloomFilter14(true);
	}

	pass FSBMLuminancePlusBrightPassFilter
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_1_1 psDx9_FSBMLuminancePlusBrightPassFilter();
	}		
	
	pass FSBMScaleDown4x4LinearFilterHorizontal
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_4TapFilter(scaleDown4x4LinearSampleOffsets);
		PixelShader = compile LOWPSMODEL psDx9_FSBMScaleDown4x4LinearFilter();
	}

	pass FSBMScaleDown4x4LinearFilterVertical
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_4TapFilter(scaleDown4x4LinearSampleOffsets);
		PixelShader = compile LOWPSMODEL psDx9_FSBMScaleDown4x4LinearFilter();
	}
	
	pass FSBMClear
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile LOWPSMODEL psDx9_FSBMClear();
	}

	pass FSBMBlendCustom
	{
		ZEnable = FALSE;
		AlphaBlendEnable = TRUE;
		StencilEnable = FALSE;
		AlphaTestEnable = FALSE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		VertexShader = compile vs_1_1 vsDx9_blitCustom();
		PixelShader = compile ps_1_1 psDx9_FSBMPassThrough();
	}
}
#endif

vec4 psDx9_StencilGather(VS2PS_blit indata) : COLOR
{
	return dwStencilRef / 255.0;
}

vec4 psDx9_StencilMap(VS2PS_blit indata) : COLOR
{
	vec4 stencil = tex2D(sampler0point, indata.TexCoord0);
	return tex1D(sampler1point, stencil.x / 255.0);
}

#if !_FORCE_1_4_SHADERS_
technique StencilPasses
{
	pass StencilGather
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;

		StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = EQUAL;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_StencilGather();
	}

	pass StencilMap
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		StencilEnable = FALSE;
		
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = compile ps_2_a psDx9_StencilMap();
	}
}
#endif

#if !_FORCE_1_4_SHADERS_
// Why doesn't this work for 1.4???
technique ResetStencilCuller
{
	pass NV4X
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = ALWAYS;
		
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		ColorWriteEnable = 0;
		ColorWriteEnable1 = 0;
		ColorWriteEnable2 = 0;
		ColorWriteEnable3 = 0;
		
		StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilMask = 0xFF;
		StencilWriteMask = 0xFF;
		StencilFunc = EQUAL;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = (dwStencilPass);
		TwoSidedStencilMode = FALSE;
		
		VertexShader = compile vs_1_1 vsDx9_blit();
		PixelShader = asm
		{
			ps.1.1
			def c0, 0, 0, 0, 0
			mov r0, c0
		};
	}
}
#endif
