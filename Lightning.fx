#include "shaders/datatypes.fx"

mat4x4 wvp : WORLDVIEWPROJ;

float4 lightningColor: LIGHTNINGCOLOR = {1,1,1,1};

texture texture0 : TEXTURE;

sampler sampler0 = sampler_state
{
	Texture = <texture0>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = CLAMP;
	AddressV = CLAMP;
};

struct VSINPUT
{
	vec3 Pos: POSITION;
	vec2 TexCoords: TEXCOORD0;
	vec4 Color : COLOR;
};

struct VSOUT
{
	vec4 Pos: POSITION;
	vec2 TexCoords: TEXCOORD0;
	vec4 Color : COLOR;
};

VSOUT vsLightning(VSINPUT input)
{
	VSOUT output;
	output.Pos = mul(vec4(input.Pos,1), wvp);
	output.TexCoords = input.TexCoords;
	output.Color = input.Color;
	return output;
}

vec4 psLightning(VSOUT input) : COLOR
{
	vec4 texCol = tex2D(sampler0, input.TexCoords);
	return vec4(texCol.rgb * lightningColor.rgb, texCol.a * lightningColor.a * input.Color.a);
}

technique Lightning
{
	pass p0
	{
		FogEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = TRUE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SrcAlpha;
		DestBlend = One;
		CullMode = NONE;
		
		VertexShader = compile vs_1_1 vsLightning();
		PixelShader = compile ps_1_4 psLightning();
	}
}