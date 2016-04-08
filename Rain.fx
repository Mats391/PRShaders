#include "shaders/datatypes.fx"

mat4x4 wvp : WORLDVIEWPROJ;

vec4 cellPositions[32] : CELLPOSITIONS;
vec4 deviations[16] : DEVIATIONGROUPS;

vec4 particleColor: PARTICLECOLOR;

vec4 cameraPos : CAMERAPOS;

vec3 fadeOutRange : FADEOUTRANGE;
vec3 fadeOutDelta : FADEOUTDELTA;

vec3 pointScale : POINTSCALE;
scalar particleSize : PARTICLESIZE;
scalar maxParticleSize : PARTICLEMAXSIZE;

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
	vec4 Data : COLOR0;
	vec2 TexCoord: TEXCOORD0;
};

/////////////////////////////////////////////
// Point Technique
/////////////////////////////////////////////

struct POINT_VSOUT
{
	vec4 Pos: POSITION;
	vec2 TexCoord : TEXCOORD0;
	vec4 Color : COLOR0;
	scalar pointSize : PSIZE;
};

POINT_VSOUT vsPoint(VSINPUT input)
{
	POINT_VSOUT output;

	vec3 cellPos = cellPositions[input.Data.x];
	vec3 deviation = deviations[input.Data.y];
	
	vec3 particlePos = input.Pos + cellPos + deviation;

	vec3 camDelta = abs(cameraPos.xyz-particlePos);
	scalar camDist = length(camDelta);
	
	camDelta -= fadeOutRange;
	camDelta /= fadeOutDelta;
	scalar alpha = 1.f-length(saturate(camDelta));

	output.Color = vec4(particleColor.rgb,particleColor.a*alpha);
	
	output.Pos = mul(vec4(particlePos,1), wvp);
	output.TexCoord = input.TexCoord;
	
	output.pointSize = min(particleSize * sqrt(1/(pointScale[0]+pointScale[1]*camDist)), maxParticleSize);
	
	return output;
}

vec4 psPoint(POINT_VSOUT input) : COLOR
{
	vec4 texCol = tex2D(sampler0, input.TexCoord);
	return texCol * input.Color;
}

technique Point
{
	pass p0
	{
		FogEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = false;//TRUE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SrcAlpha;
		DestBlend = One;//InvSrcAlpha;
		CullMode = NONE;
		
		VertexShader = compile vs_1_1 vsPoint();
		PixelShader = compile ps_1_4 psPoint();
	}
}

/////////////////////////////////////////////
// Line Technique
/////////////////////////////////////////////

struct LINE_VSOUT
{
	vec4 Pos: POSITION;
	vec2 TexCoord : TEXCOORD0;
	vec4 Color : COLOR0;
};

LINE_VSOUT vsLine(VSINPUT input)
{
	LINE_VSOUT output;

	vec3 cellPos = cellPositions[input.Data.x];
	vec3 particlePos = input.Pos + cellPos;

	vec3 camDelta = abs(cameraPos.xyz-particlePos);
	camDelta -= fadeOutRange;
	camDelta /= fadeOutDelta;
	scalar alpha = 1.f-length(saturate(camDelta));

	output.Color = vec4(particleColor.rgb,particleColor.a*alpha);
	
	output.Pos = mul(vec4(particlePos,1), wvp);
	output.TexCoord = input.TexCoord;

	return output;
}

vec4 psLine(LINE_VSOUT input) : COLOR
{
	return input.Color;
}

technique Line
{
	pass p0
	{
		FogEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = false;//TRUE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SrcAlpha;
		DestBlend = One;//InvSrcAlpha;
		CullMode = NONE;
		
		VertexShader = compile vs_1_1 vsLine();
		PixelShader = compile ps_1_4 psLine();
	}
}

/////////////////////////////////////////////
// Debug Cell Technique
/////////////////////////////////////////////

struct CELL_VSOUT
{
	vec4 Pos: POSITION;
	vec2 TexCoord : TEXCOORD0;
	vec4 Color : COLOR0;
};

CELL_VSOUT vsCells(VSINPUT input)
{
	CELL_VSOUT output;

	vec3 cellPos = cellPositions[input.Data.x];
	vec3 particlePos = input.Pos + cellPos;

	output.Color = particleColor;
	
	output.Pos = mul(vec4(particlePos,1), wvp);
	output.TexCoord = input.TexCoord;

	return output;
}

vec4 psCells(CELL_VSOUT input) : COLOR
{
	return input.Color;
}

technique Cells
{
	pass p0
	{
		FogEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = false;//TRUE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SrcAlpha;
		DestBlend = One;//InvSrcAlpha;
		CullMode = NONE;
		
		VertexShader = compile vs_1_1 vsCells();
		PixelShader = compile ps_1_4 psCells();
	}
}