
// Speed to always add to wind, decrease for less movement
#define WIND_ADD 5

#define LEAF_MOVEMENT 1024

#ifndef _HASSHADOW_
#define _HASSHADOW_ 0
#endif

#include "shaders/dataTypes.fx"
#include "shaders/RaCommon.fx"
 
//vec3	TreeSkyColor;
vec4 	OverGrowthAmbient;
Light	Lights[1];
vec4	PosUnpack;
vec2	NormalUnpack;
scalar	TexUnpack;
scalar	ObjRadius = 2;

// If we are not rendering the far away trees we don't need/want 2_0 shaders
#ifndef OVERGROWTH
	#define _FORCE_1_4_SHADERS_ 1
#endif

struct VS_OUTPUT
{
	vec4 Pos	: POSITION0;
	vec2 Tex0	: TEXCOORD0;
#if _HASSHADOW_
	vec4 TexShadow	: TEXCOORD1;
#endif
	vec4 Color  : COLOR0;
	scalar Fog	: FOG;
};

texture	DiffuseMap;
sampler DiffuseMapSampler = sampler_state
{
	Texture = (DiffuseMap);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU  = WRAP;
	AddressV  = WRAP;
	MipMapLodBias = 0;
};

// INPUTS TO THE VERTEX SHADER FROM THE APP
string reqVertexElement[] = 
{
#ifdef OVERGROWTH	//tl: TODO - Compress overgrowth patches as well.
 	"Position",
 	"Normal",
	"TBase2D"
#else
 	"PositionPacked",
 	"NormalPacked8",
	"TBasePacked2D"
#endif
};

VS_OUTPUT basicVertexShader
(
	vec4 inPos: POSITION0,
	vec3 normal: NORMAL,
	vec2 tex0	: TEXCOORD0
)
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

#ifndef OVERGROWTH
	inPos *= PosUnpack;
	WindSpeed += WIND_ADD;
	inPos.xyz +=  sin((GlobalTime / (ObjRadius + inPos.y)) * WindSpeed) * (ObjRadius + inPos.y) * (ObjRadius + inPos.y) / LEAF_MOVEMENT;// *  WindSpeed / 16384;//clamp(abs(inPos.z * inPos.x), 0, WindSpeed);
#endif
	Out.Pos		= mul(vec4(inPos.xyz, 1), WorldViewProjection);

	Out.Fog		= calcFog(Out.Pos.w);
	Out.Tex0	= tex0;

#ifdef OVERGROWTH
	Out.Tex0 /= 32767.0f;
 	normal = normal * 2.0f - 1.0f;
#else
  	normal = normal * NormalUnpack.x + NormalUnpack.y;
	Out.Tex0 *= TexUnpack;
#endif	
	
#ifdef _POINTLIGHT_
	vec3 lightVec = vec3(Lights[0].pos.xyz - inPos);
	float LdotN	= 0.125;//saturate( (dot(normal, -normalize(lightVec))));
#else
	scalar LdotN	= saturate( (dot(normal, -Lights[0].dir ) + 0.6 ) / 1.4 );
#endif

#ifdef OVERGROWTH
	Out.Color.rgb = Lights[0].color * (inPos.w / 32767) * LdotN* (inPos.w / 32767) ;
	OverGrowthAmbient *= (inPos.w / 32767);
#else	
	Out.Color.rgb = Lights[0].color * LdotN;
#endif

#if _HASSHADOW_
	Out.TexShadow = calcShadowProjection(vec4(inPos.xyz, 1));
#elif !defined(_POINTLIGHT_)
	Out.Color.rgb += OverGrowthAmbient * 1 / CEXP(1);
#endif

#ifdef _POINTLIGHT_
	Out.Color.rgb *= 1 - saturate(dot(lightVec, lightVec) * Lights[0].attenuation * 0.1);
	Out.Color.rgb *= calcFog(Out.Pos.w);
#endif
	Out.Color.a = Transparency;
	Out.Color = Out.Color * 0.5;

	return Out;
}

vec4 basicPixelShader(VS_OUTPUT VsOut) : COLOR
{
	vec4 vertexColor = vec4(CEXP(VsOut.Color.rgb), VsOut.Color.a*2);
	vec4 diffuseMap = tex2D(DiffuseMapSampler, VsOut.Tex0);

#if _HASSHADOW_
	vertexColor.rgb *= getShadowFactor(ShadowMapSampler, VsOut.TexShadow, 1, 20);
	vertexColor.rgb += CEXP(OverGrowthAmbient)/2;
#endif

	//tl: use compressed color register to avoid this being compiled as a 2.0 shader.
	vec4 outCol = diffuseMap * vertexColor * 2;
	
#if defined(OVERGROWTH) && HASALPHA2MASK
	outCol.a *= 2 * diffuseMap.a;
#endif

	return outCol;
};

string GlobalParameters[] =
{
#if _HASSHADOW_
	"ShadowMap",
#endif
	"GlobalTime",
	"FogRange",
#ifndef _POINTLIGHT_
	"FogColor"
#endif
};

string InstanceParameters[] =
{
#if _HASSHADOW_
	"ShadowProjMat",
	"ShadowTrapMat",
#endif
	"WorldViewProjection",
	"Transparency",
	"WindSpeed",
	"Lights",
#ifndef _POINTLIGHT_
	"OverGrowthAmbient"
#endif
};

string TemplateParameters[] = 
{
	"DiffuseMap",
	"PosUnpack",
	"NormalUnpack",
	"TexUnpack"
};

technique defaultTechnique
{
	pass P0
	{
		vertexShader		= compile VSMODEL basicVertexShader();
#if _HASSHADOW_
	#if !NVIDIA
		pixelShader			= compile PSMODEL basicPixelShader();
	#else
		TextureTransformFlags[1] = PROJECTED;
		Sampler[0] = (DiffuseMapSampler);
		Sampler[1] = (ShadowMapSampler);
		PixelShaderConstantF[0] = (OverGrowthAmbient);
		pixelShader = asm
		{
			ps_1_3
			tex t0
			tex t1
			mul_x4 r0.xyz, v0, t1
			add r0.xyz, r0, c0
			mul r0.xyz, r0, t0
			+mul_x4 r0.w, v0.w, t0.w
		#if defined(OVERGROWTH) && HASALPHA2MASK
			mul_x2 r0.w, r0.w, t0.w
		#endif
		};
	#endif
#else
	#if 0
			pixelShader			= compile PSMODEL basicPixelShader();
	#else
			Sampler[0] = (DiffuseMapSampler);
			pixelShader = asm
			{
				ps_1_3
				tex t0
#ifdef _POINTLIGHT_
				add r0.rgb, v0, v0
				+mov r0.a, v0.a
				mul_x4 r0, t0, r0
#else
				mul_x4 r0, t0, v0
#endif
			#if defined(OVERGROWTH) && HASALPHA2MASK
				mul_x2 r0.a, r0.a, t0.a
			#endif
			};
	#endif
#endif
#ifdef ENABLE_WIREFRAME
		FillMode			= WireFrame;
#endif

#if HASALPHA2MASK
		Alpha2Mask = 1;
#endif

		AlphaTestEnable		= true;

		AlphaRef			= 127;
		SrcBlend			= < srcBlend >;
		DestBlend			= < destBlend >;

#ifdef _POINTLIGHT_
		FogEnable			= false;
		AlphaBlendEnable	= true;
	SrcBlend			= one;
	DestBlend			= one;
#else
		AlphaBlendEnable	= false;
		FogEnable			= true;
#endif
		CullMode			= NONE;
	}
}
