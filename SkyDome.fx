#line 2 "SkyDome.fx"
#include "shaders/datatypes.fx"

// UNIFORM INPUTS
mat4x4 viewProjMatrix : WorldViewProjection;
vec4 texOffset : TEXOFFSET;
vec4 texOffset2 : TEXOFFSET2;

vec4 flareParams : FLAREPARAMS;
vec4 underwaterFog : FogColor;

vec2 fadeOutDist : CLOUDSFADEOUTDIST;
vec2 cloudLerpFactors : CLOUDLERPFACTORS;

scalar lightingBlend : LIGHTINGBLEND;
vec3 lightingColor : LIGHTINGCOLOR;

texture texture0: TEXLAYER0;
texture texture1: TEXLAYER1;
texture texture2: TEXLAYER2;

sampler samplerClamp = sampler_state
{
	Texture = <texture0>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

sampler samplerWrap1 = sampler_state
{
	Texture = <texture1>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = WRAP;
	AddressV = WRAP;
};

sampler samplerWrap2 = sampler_state
{
	Texture = <texture2>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = WRAP;
	AddressV = WRAP;
};

struct appdata {
    vec4	Pos : POSITION;    
    vec4  BlendIndices : BLENDINDICES;    
    vec2	TexCoord : TEXCOORD0;
    vec2	TexCoord1 : TEXCOORD1;
};

struct appdataNoClouds {
    vec4	Pos : POSITION;    
    vec4  BlendIndices : BLENDINDICES;    
    vec2	TexCoord : TEXCOORD0;
};

struct VS_OUTPUT {
	vec4 HPos	: POSITION;
	vec2 Tex0	: TEXCOORD0;
	vec2 Tex1	: TEXCOORD1;
	vec4 FadeOut: COLOR0;
};

struct VS_OUTPUTNoClouds {
	vec4 HPos	: POSITION;
	vec2 Tex0	: TEXCOORD0;
};

struct VS_OUTPUTDualClouds {
	vec4 HPos	: POSITION;
	vec2 Tex0	: TEXCOORD0;
	vec2 Tex1	: TEXCOORD1;
	vec2 Tex2	: TEXCOORD2;
	vec4 FadeOut: COLOR0;
};

VS_OUTPUT vsSkyDome(appdata input)
{
	VS_OUTPUT Out;
 	Out.HPos = mul(vec4(input.Pos.xyz, 1.0), viewProjMatrix);
 	Out.Tex0 = input.TexCoord;
	Out.Tex1 = (input.TexCoord1.xy + texOffset.xy);
	float dist = length(input.Pos.xyz);
	Out.FadeOut = 1-saturate((dist - fadeOutDist.x) / fadeOutDist.y);	//tl: TODO - optimize out division
	Out.FadeOut *= input.Pos.y > 0;
	return Out;
}

VS_OUTPUTNoClouds vsSkyDomeNoClouds(appdataNoClouds input)
{
	VS_OUTPUTNoClouds Out;
	vec4 posScaled = vec4(input.Pos.xyz, 10.0); //plo: fix for artifacts on BFO.
	Out.HPos = mul(posScaled, viewProjMatrix);
	Out.Tex0 = input.TexCoord;
	return Out;
}

VS_OUTPUTDualClouds vsSkyDomeDualClouds(appdata input)
{
	VS_OUTPUTDualClouds Out;
 	Out.HPos = mul(vec4(input.Pos.xyz, 1.0), viewProjMatrix);
 	Out.Tex0 = input.TexCoord;
	Out.Tex1 = (input.TexCoord1.xy + texOffset.xy);
	Out.Tex2 = (input.TexCoord1.xy + texOffset2.xy);
	float dist = length(input.Pos.xyz);
	Out.FadeOut = 1-saturate((dist - fadeOutDist.x) / fadeOutDist.y);	//tl: TODO - optimize out division
	Out.FadeOut *= input.Pos.y > 0;
	return Out;
}

vec4 psSkyDome(VS_OUTPUT indata) : COLOR
{
	vec4 sky = tex2D(samplerClamp, indata.Tex0);
	vec4 cloud = tex2D(samplerWrap1, indata.Tex1) * indata.FadeOut;
	return vec4(lerp(sky.rgb,cloud.rgb,cloud.a), 1);
}

vec4 psSkyDomeLit(VS_OUTPUT indata) : COLOR
{
	vec4 sky = tex2D(samplerClamp, indata.Tex0);
	sky.rgb += lightingColor.rgb * (sky.a * lightingBlend);

	vec4 cloud = tex2D(samplerWrap1, indata.Tex1) * indata.FadeOut;
	return vec4(lerp(sky.rgb,cloud.rgb,cloud.a), 1);
}

vec4 psSkyDomeUnderWater(VS_OUTPUT indata) : COLOR
{
	return underwaterFog;
}

vec4 psSkyDomeNoClouds(VS_OUTPUT indata) : COLOR
{
	return tex2D(samplerClamp, indata.Tex0);
}

vec4 psSkyDomeNoCloudsLit(VS_OUTPUT indata) : COLOR
{
	vec4 sky = tex2D(samplerClamp, indata.Tex0);
	sky.rgb += lightingColor.rgb * (sky.a * lightingBlend);
	return sky;
}

vec4 psSkyDomeDualClouds(VS_OUTPUTDualClouds indata) : COLOR
{
	vec4 sky = tex2D(samplerClamp, indata.Tex0);
	vec4 cloud = tex2D(samplerWrap1, indata.Tex1);
	vec4 cloud2 = tex2D(samplerWrap2, indata.Tex2);
	vec4 tmp = cloud * cloudLerpFactors.x + cloud2 * cloudLerpFactors.y;
	tmp *=  indata.FadeOut;
	return lerp(sky, tmp, tmp.a);
}


VS_OUTPUTNoClouds vsSkyDomeSunFlare(appdataNoClouds input)
{
	VS_OUTPUTNoClouds Out;
 	//Out.HPos = input.Pos * 10000;
 	Out.HPos = mul(vec4(input.Pos.xyz, 1.0), viewProjMatrix);
 	Out.Tex0 = input.TexCoord;
	return Out;
}

vec4 psSkyDomeSunFlare(VS_OUTPUT indata) : COLOR
{
	//return 1;
	//return vec4(flareParams[0],0,0,1);
	vec3 rgb = tex2D(samplerClamp, indata.Tex0).rgb * flareParams[0];
	return vec4(rgb, 1);
}

vec4 psSkyDomeFlareOcclude(VS_OUTPUT indata) : COLOR
{
	vec4 p = tex2D(samplerClamp, indata.Tex0);
	return vec4(0, 1, 0, p.a);
}


technique SkyDomeUnderWater
{
	pass sky
	{
		AlphaBlendEnable = FALSE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

 		VertexShader = compile vs_1_1 vsSkyDome();
		PixelShader = compile ps_1_1 psSkyDomeUnderWater();
	}
}

technique SkyDomeNV3x
{
	pass sky
	{
		AlphaBlendEnable = FALSE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

 		VertexShader = compile vs_1_1 vsSkyDome();
		PixelShader = compile ps_1_1 psSkyDome();
	}
}

technique SkyDomeNV3xLit
{
	pass sky
	{
		AlphaBlendEnable = FALSE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

 		VertexShader = compile vs_1_1 vsSkyDome();
		PixelShader = compile ps_1_1 psSkyDomeLit();
	}
}

technique SkyDomeNV3xNoClouds
{
	pass sky
	{
		AlphaBlendEnable = FALSE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		
 		VertexShader = compile vs_1_1 vsSkyDomeNoClouds();
		PixelShader = compile ps_1_1 psSkyDomeNoClouds();
	}
}

technique SkyDomeNV3xNoCloudsLit
{
	pass sky
	{
		AlphaBlendEnable = FALSE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		
 		VertexShader = compile vs_1_1 vsSkyDomeNoClouds();
		PixelShader = compile ps_1_1 psSkyDomeNoCloudsLit();
	}
}

technique SkyDomeNV3xDualClouds
{
	pass sky
	{
		AlphaBlendEnable = FALSE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
			
 		VertexShader = compile vs_1_1 vsSkyDomeDualClouds();
		PixelShader = compile ps_1_1 psSkyDomeDualClouds();
	}
}

technique SkyDomeSunFlare
{
	pass sky
	{
		Zenable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = ALWAYS;
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		FogEnable = FALSE;
		//ColorWriteEnable = 0;
 		VertexShader = compile vs_1_1 vsSkyDomeSunFlare();
		PixelShader = compile ps_1_1 psSkyDomeSunFlare();
	}
}

technique SkyDomeFlareOccludeCheck
{
	pass sky
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = ALWAYS;
		CullMode = NONE;
		ColorWriteEnable = 0;

		AlphaBlendEnable = TRUE;

		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		AlphaTestEnable = TRUE;
		AlphaRef = 50;
		AlphaFunc = GREATER;

		
		//AlphaRef = 255;
		//AlphaFunc = LESS;
	
		FogEnable = FALSE;
			
 		VertexShader = compile vs_1_1 vsSkyDomeSunFlare();
		PixelShader = compile ps_1_1 psSkyDomeFlareOcclude();
	}
}

technique SkyDomeFlareOcclude
{
	pass sky
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESS;
		CullMode = NONE;
		ColorWriteEnable = 0;

		AlphaBlendEnable = TRUE;

		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		AlphaTestEnable = TRUE;
		AlphaRef = 50;
		AlphaFunc = GREATER;

		
		//AlphaRef = 255;
		//AlphaFunc = LESS;
	
		FogEnable = FALSE;
			
 		VertexShader = compile vs_1_1 vsSkyDomeSunFlare();
		PixelShader = compile ps_1_1 psSkyDomeFlareOcclude();
	}
}
