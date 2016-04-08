#line 2 "Font.fx"

#include "shaders/RaCommon.fx"

mat4x4 WorldView : TRANSFORM;
vec4 DiffuseColor : DIFFUSE;
texture TexMap : TEXTURE;

sampler TexMapSamplerClamp = sampler_state
{
    Texture   = <TexMap>;
    AddressU  = Clamp;
    AddressV  = Clamp;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
};

sampler TexMapSamplerClampLinear = sampler_state
{
    Texture   = <TexMap>;
    AddressU  = Clamp;
    AddressV  = Clamp;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
};

struct appData
{
	vec4	Position	: POSITION;    
   	vec4	Color		: COLOR;
   	vec2	TexCoord	: TEXCOORD0;
};

struct VS_REGULAR
{
	vec4 Position : POSITION;
	vec4 Diffuse : COLOR0;
	vec2 TexCoord : TEXCOORD0;
};

VS_REGULAR VSRegular(appData input)
{
	VS_REGULAR Out = (VS_REGULAR)0;
	//Out.Position = mul( float4(Position.xy, 0.5f, 1.f), WorldView);
	Out.Position = vec4(input.Position.xy, 0.5f, 1.0f);
	Out.Diffuse = input.Color;
	Out.TexCoord = input.TexCoord;
	return Out;
}

vec4 PSRegular(VS_REGULAR input) : COLOR
{
	return tex2D( TexMapSamplerClamp, input.TexCoord ) * input.Diffuse;
}

vec4 PSRegularScaled(VS_REGULAR input) : COLOR
{
	return tex2D( TexMapSamplerClampLinear, input.TexCoord ) * input.Diffuse;
}

struct VS_SELECTIONQUAD
{
	vec4 Position : POSITION;
	vec4 Diffuse : COLOR0;
};

VS_SELECTIONQUAD VSSelectionQuad(float3 Position : POSITION)
{
	VS_SELECTIONQUAD Out = (VS_SELECTIONQUAD)0;
	Out.Position = mul( vec4(Position.xy, 0.0f, 1.0), WorldView);
	Out.Diffuse = DiffuseColor;
	return Out;
}

technique Regular
{
	pass P0
	{
		VertexShader = compile vs_1_1 VSRegular();
		PixelShader = compile ps_1_1 PSRegular();
		AlphaTestEnable		= false;
		AlphaBlendEnable = true;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
	}
}

technique RegularScaled
{
	pass P0
	{
		VertexShader = compile vs_1_1 VSRegular();
		PixelShader = compile ps_1_1 PSRegularScaled();
		AlphaTestEnable		= false;
		AlphaBlendEnable = true;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
	}
}

technique SelectionQuad
{
	pass P0
	{
		VertexShader = compile vs_1_1 VSSelectionQuad();
		PixelShader  = NULL;
		AlphaTestEnable		= false;
		AlphaBlendEnable = true;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		ColorOp[0]   = SelectArg1;
		ColorArg1[0] = Diffuse;
		AlphaOp[0]   = SelectArg1;
		AlphaArg1[0] = Diffuse;
		ColorOp[1] = Disable;
		AlphaOp[1] = Disable;
		TexCoordIndex[0] =0;
		TextureTransformFlags[0] = Disable;
	    Sampler[0] = <TexMapSamplerClamp>;
	}
}
