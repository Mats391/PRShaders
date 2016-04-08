#line 2 "Decals.fx"

#include "shaders/RaCommon.fx"
//#include "shaders/datatypes.fx"

// UNIFORM INPUTS
mat4x4 worldViewProjection : WorldViewProjection;
mat4x3 instanceTransformations[10]: InstanceTransformations;
mat4x4 shadowTransformations[10] : ShadowTransformations;
vec4 shadowViewPortMaps[10] : ShadowViewPortMaps;

// offset x/y heightmapsize z / hemilerpbias w
//vec4 hemiMapInfo : HemiMapInfo;
//vec4 skyColor : SkyColor;

vec4 ambientColor : AmbientColor;
vec4 sunColor : SunColor;
vec4 sunDirection : SunDirection;


vec2 decalFadeDistanceAndInterval : DecalFadeDistanceAndInterval = vec2(100.f, 30.f);

texture texture0: TEXLAYER0;
texture texture1: HemiMapTexture;
texture shadowMapTex: ShadowMapTex;
//texture shadowMapOccluderTex: ShadowMapOccluderTex;

sampler sampler0 = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
sampler sampler1 = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };
//sampler ShadowMapSampler = sampler_state { Texture = (shadowMapTex); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };
//sampler sampler3 = sampler_state { Texture = (shadowMapOccluderTex); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; MipFilter = NONE; };

struct appdata {
   	vec4	Pos				: POSITION;    
   	vec4	Normal				: NORMAL;       	
   	vec4	Color				: COLOR;
   	vec4	TexCoordsInstanceIndexAndAlpha	: TEXCOORD0;
};


struct OUT_vsDecal {
	vec4 HPos		: POSITION;
	vec2 Texture0		: TEXCOORD0;	
	vec3 Color 		: TEXCOORD1;
	vec3 Diffuse		: TEXCOORD2;
	vec4 Alpha		: COLOR0;
	
	scalar Fog		: FOG;
};

OUT_vsDecal vsDecal(appdata input)
{
	OUT_vsDecal Out;
	   	   	
   	int index = input.TexCoordsInstanceIndexAndAlpha.z;
   	
  	vec3 Pos = mul(input.Pos, instanceTransformations[index]);
 	Out.HPos = mul(vec4(Pos.xyz, 1.0f), worldViewProjection);
 	
 	vec3 worldNorm = mul(input.Normal.xyz, (mat3x3)instanceTransformations[index]);
 	Out.Diffuse = saturate(dot(worldNorm, -sunDirection)) * sunColor;
 	
 	scalar alpha = 1.0f - saturate((Out.HPos.z - decalFadeDistanceAndInterval.x)/decalFadeDistanceAndInterval.y);
	alpha *= input.TexCoordsInstanceIndexAndAlpha.w;
	Out.Alpha = alpha;
	Out.Color = input.Color;
	
	Out.Texture0 = input.TexCoordsInstanceIndexAndAlpha.xy;
	
	Out.Fog = calcFog(Out.HPos.w); 	 

	return Out;
}

vec4 psDecal(	OUT_vsDecal indata) : COLOR
{
	//return 1;
	vec3 lighting =  ambientColor + indata.Diffuse;
	vec4 outColor = tex2D(sampler0, indata.Texture0);// * indata.Color;
	
	outColor.rgb *= indata.Color * lighting;
	outColor.a *= indata.Alpha;
	
	
	return outColor;
}



struct OUT_vsDecalShadowed {
	vec4 HPos		: POSITION;
	vec2 Texture0		: TEXCOORD0;	
	vec4 TexShadow		: TEXCOORD1;
	vec4 ViewPortMap 	: TEXCOORD2;
	vec3 Color 		: TEXCOORD3;
	vec3 Diffuse		: TEXCOORD4;
	vec4 Alpha		: COLOR0;	
	scalar Fog		: FOG;
	
};

OUT_vsDecalShadowed vsDecalShadowed(appdata input)
{
	OUT_vsDecalShadowed Out;
	   	   	
   	int index = input.TexCoordsInstanceIndexAndAlpha.z;
   	
  	vec3 Pos = mul(input.Pos, instanceTransformations[index]);
 	Out.HPos = mul(vec4(Pos.xyz, 1.0f), worldViewProjection);
 	
 	vec3 worldNorm = mul(input.Normal.xyz, (mat3x3)instanceTransformations[index]);
 	Out.Diffuse = saturate(dot(worldNorm, -sunDirection)) * sunColor;

 	vec3 color = input.Color;
 	scalar alpha = 1.0f - saturate((Out.HPos.z - decalFadeDistanceAndInterval.x)/decalFadeDistanceAndInterval.y);
	alpha *= input.TexCoordsInstanceIndexAndAlpha.w;
	Out.Alpha = alpha;


	Out.Color = color;
 	
 	Out.ViewPortMap = shadowViewPortMaps[index];
 	Out.TexShadow =  mul(vec4(Pos, 1), shadowTransformations[index]);
	Out.TexShadow.z -= 0.007;
	
	Out.Texture0 = input.TexCoordsInstanceIndexAndAlpha.xy;
	Out.Fog = calcFog(Out.HPos.w); 	 
	
	return Out;
}

vec4 psDecalShadowed(	OUT_vsDecalShadowed indata) : COLOR
{
	//return 1;
	vec2 texel = vec2(1.0 / 1024.0, 1.0 / 1024.0);
	vec4 samples;

/*	indata.TexShadow.xy = clamp(indata.TexShadow.xy,  indata.ViewPortMap.xy, indata.ViewPortMap.zw);
	samples.x = tex2D(ShadowMapSampler, indata.TexShadow);
	samples.y = tex2D(ShadowMapSampler, indata.TexShadow + vec2(texel.x, 0));
	samples.z = tex2D(ShadowMapSampler, indata.TexShadow + vec2(0, texel.y));
	samples.w = tex2D(ShadowMapSampler, indata.TexShadow + texel);
	
	vec4 cmpbits = samples >= saturate(indata.TexShadow.z);
	scalar dirShadow = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));
	*/
	scalar dirShadow = 1;
		
	vec4 outColor = tex2D(sampler0, indata.Texture0);
	outColor.rgb *=  indata.Color;
	outColor.a *= indata.Alpha;
	
	vec3 lighting =  ambientColor.rgb + indata.Diffuse*dirShadow;
	
	outColor.rgb *= lighting;
	
	return outColor;
}


technique Decal
<
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0 },
		{ 0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_NORMAL, 0 },
		{ 0, D3DDECLTYPE_D3DCOLOR, D3DDECLUSAGE_COLOR, 0 },
		{ 0, D3DDECLTYPE_FLOAT4, D3DDECLUSAGE_TEXCOORD, 0 },		
		DECLARATION_END	// End macro
	};
>
{
	pass p0 
	{	
		//FillMode = WireFrame;
		AlphaTestEnable = TRUE;
		ZEnable = TRUE;	
		ZWriteEnable = FALSE;		
		AlphaRef = 0;
		AlphaFunc = GREATER;
		CullMode = CW;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;				
		FogEnable = TRUE;
		
 		VertexShader = compile vs_1_1 vsDecal();
		PixelShader = compile LOWPSMODEL psDecal();
	}

#if !_FORCE_1_3_SHADERS_
	pass p1
	{
		//FillMode = WireFrame;
		AlphaTestEnable = TRUE;
		ZEnable = TRUE;	
		ZWriteEnable = FALSE;		
		AlphaRef = 0;
		AlphaFunc = GREATER;
		CullMode = CW;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;				
		FogEnable = TRUE;
		
 		VertexShader = compile vs_1_1 vsDecal();
		PixelShader = compile ps_1_3 psDecal();
	}
#else
	pass p1
	{
		//FillMode = WireFrame;
		AlphaTestEnable = TRUE;
		ZEnable = TRUE;	
		ZWriteEnable = FALSE;		
		AlphaRef = 0;
		AlphaFunc = GREATER;
		CullMode = CW;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;				
		FogEnable = TRUE;
		
 		VertexShader = compile vs_1_1 vsDecalShadowed();
		PixelShader = compile ps_1_4 psDecalShadowed();
	}
#endif
}

