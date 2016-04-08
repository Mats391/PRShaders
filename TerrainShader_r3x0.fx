
// DirectX9 (R3XX) Deferred rendering path
#define USE_PLANE_MAPPING 1

struct APP2VS_vsDx9_zFill
{
    vec4	Pos0 : POSITION0;
    vec4	Pos1 : POSITION1;
    vec4	MorphDelta : POSITION2;
};

vec4 vsDx9_zFill(APP2VS_vsDx9_zFill indata) : POSITION
{
	vec4 wPos;
	wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
	wPos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;
	
	scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
	scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
	scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
	wPos.y -= yDelta * vScaleTransY.x;

 	return mul(wPos, mViewProj);
}


struct APP2VS_detailDiffuse
{
    vec4	Pos0 : POSITION0;
    vec4	Pos1 : POSITION1;
    vec4	MorphDelta : POSITION2;
    vec2	TexCoord0 : TEXCOORD0;
    vec3	Normal : NORMAL;
};


struct VS2PS_vsDx9_detailDiffuse
{
    vec4	Pos : POSITION;
    vec4	Tex0 : TEXCOORD0;
    vec2	Tex2 : TEXCOORD2;
    vec4	BlendValueAndFade : COLOR0;
    vec4	Tex3 : TEXCOORD3;
};

vec4 psDx9_detailDiffuse(VS2PS_vsDx9_detailDiffuse indata) : COLOR
{
#ifndef USE_PLANE_MAPPING
	vec4 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);
	vec4 component = tex2D(sampler1Clamp, indata.Tex0.xy);
	vec4 detailmap = 2*tex2D(sampler2Wrap, indata.Tex1.zw);
	vec4 lowDetailmap = 2*tex2D(sampler3Wrap, indata.Tex2);

	scalar chartcontrib = dot(vComponentsel, component);

	vec4 detailout = ((detailmap * (1-indata.BlendValueAndFade.w)) + (lowDetailmap.z * indata.BlendValueAndFade.w));

	return chartcontrib * detailout * colormap;

#else

	vec4 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);
	vec4 component = tex2D(sampler1Clamp, indata.Tex0.xy);
	vec4 lowComponent = tex2D(sampler4Clamp, indata.Tex0.xy);
	vec4 detailmap = tex2D(sampler2Wrap, indata.Tex0.zw);
	vec4 yplaneLowDetailmap = 2*tex2D(sampler3Wrap, indata.Tex2);
	vec4 xplaneLowDetailmap = 2*tex2D(sampler3Wrap, indata.Tex3.xy);
	vec4 zplaneLowDetailmap = 2*tex2D(sampler3Wrap, indata.Tex3.zw);
	vec3 blendValue = indata.BlendValueAndFade.xyz;

	scalar chartcontrib = dot(vComponentsel, component);

	scalar color = lerp(1, yplaneLowDetailmap.z, saturate(lowComponent.x+lowComponent.y));
	scalar totBlendValue = blendValue.x + blendValue.y + blendValue.z;
	scalar blue = (xplaneLowDetailmap.y * blendValue.x/totBlendValue) + (yplaneLowDetailmap.x * blendValue.y/totBlendValue) + (zplaneLowDetailmap.y * blendValue.z/totBlendValue);
	color *= lerp(1, blue, lowComponent.z);

	vec4 lowDetailmap = color;
	vec4 bothDetailmap = detailmap * lowDetailmap;
	vec4 detailout = 2 * lerp(bothDetailmap, 0.5*lowDetailmap, indata.BlendValueAndFade.w);

	return chartcontrib * detailout * colormap;
#endif	
}

VS2PS_vsDx9_detailDiffuse vsDx9_detailDiffuse(APP2VS_detailDiffuse indata)
{
	VS2PS_vsDx9_detailDiffuse outdata;
	
	vec4 wPos;
	wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
	wPos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;

	scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
	scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
	scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
	wPos.y -= yDelta * vScaleTransY.x;

	float3 tex = float3((indata.Pos0.y * vTexScale.z), -(((indata.Pos1.x - yDelta) * vTexScale.y)) , (indata.Pos0.x * vTexScale.x));
	float2 xPlaneTexCord = tex.xy;
	float2 yPlaneTexCord = tex.zx;
	float2 zPlaneTexCord = tex.zy;

 	outdata.Pos = mul(wPos, mViewProj);

 	outdata.Tex0.xy = yPlaneTexCord;
 	
	outdata.Tex0.zw = yPlaneTexCord.xy * vNearTexTiling.z;
 	
 	outdata.Tex2 = yPlaneTexCord * vFarTexTiling.z;
	outdata.Tex3.xy = xPlaneTexCord.xy * vFarTexTiling.xy;
	outdata.Tex3.y += vFarTexTiling.w;
	outdata.Tex3.zw = zPlaneTexCord.xy * vFarTexTiling.xy;
	outdata.Tex3.w += vFarTexTiling.w;

	outdata.BlendValueAndFade.w = interpVal;
	outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - 0.5);

	return outdata;
}




struct APP2VS_detailDiffuseMounten
{
    vec4	Pos0 : POSITION0;
    vec4	Pos1 : POSITION1;
    vec4	MorphDelta : POSITION2;
    vec2	TexCoord0 : TEXCOORD0;
    vec3	Normal : NORMAL;
};


struct VS2PS_vsDx9_detailDiffuseMounten
{
    vec4	Pos : POSITION;
    vec4	Tex0 : TEXCOORD0;
    vec2	Tex2 : TEXCOORD2;
    vec4	BlendValueAndFade : COLOR0;
    vec4	Tex3 : TEXCOORD3;
    vec4	Tex5 : TEXCOORD6;
};

vec4 psDx9_detailDiffuseMounten(VS2PS_vsDx9_detailDiffuseMounten indata) : COLOR
{
#ifndef USE_PLANE_MAPPING
	vec4 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);
	vec4 component = tex2D(sampler1Clamp, indata.Tex0.xy);
	vec4 detailmap = 2*tex2D(sampler2Wrap, indata.Tex0.zw);
	vec4 lowDetailmap = 2*tex2D(sampler3Wrap, indata.Tex2);

	scalar chartcontrib = dot(vComponentsel, component);

	vec4 detailout = ((detailmap * (1-indata.ColorAndFadeLerp.w)) + (lowDetailmap.z * indata.ColorAndFadeLerp.w));

	return chartcontrib * detailout * colormap;
	
#else
	
	vec4 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);
	vec4 component = tex2D(sampler1Clamp, indata.Tex0.xy);
	vec4 lowComponent = tex2D(sampler4Clamp, indata.Tex0.xy);
	vec4 yplaneDetailmap = tex2D(sampler2Wrap, indata.Tex0.zw);
	vec4 xplaneDetailmap = tex2D(sampler2Wrap, indata.Tex5.xy);
	vec4 zplaneDetailmap = tex2D(sampler2Wrap, indata.Tex5.zw);
	vec4 yplaneLowDetailmap = 2*tex2D(sampler3Wrap, indata.Tex2);
	vec4 xplaneLowDetailmap = 2*tex2D(sampler3Wrap, indata.Tex3.xy);
	vec4 zplaneLowDetailmap = 2*tex2D(sampler3Wrap, indata.Tex3.zw);
	vec3 blendValue = indata.BlendValueAndFade.xyz;

	scalar chartcontrib = dot(vComponentsel, component);

	scalar color = lerp(1, yplaneLowDetailmap.z, saturate(lowComponent.x+lowComponent.y));
	scalar totBlendValue = blendValue.x + blendValue.y + blendValue.z;
	scalar blue = (xplaneLowDetailmap.y * blendValue.x/totBlendValue) + (yplaneLowDetailmap.x * blendValue.y/totBlendValue) + (zplaneLowDetailmap.y * blendValue.z/totBlendValue);
	color *= lerp(1, blue, lowComponent.z);

	vec4 detailmap = (xplaneDetailmap * blendValue.x/totBlendValue) + (yplaneDetailmap * blendValue.y/totBlendValue) + (zplaneDetailmap * blendValue.z/totBlendValue);

	vec4 lowDetailmap = color;

	vec4 bothDetailmap = detailmap * lowDetailmap;
	vec4 detailout = 2 * lerp(bothDetailmap, 0.5*lowDetailmap, indata.BlendValueAndFade.w);

	return chartcontrib * detailout * colormap;
#endif	
}

VS2PS_vsDx9_detailDiffuseMounten vsDx9_detailDiffuseMounten(APP2VS_detailDiffuseMounten indata)
{
	VS2PS_vsDx9_detailDiffuseMounten outdata;
	
	vec4 wPos;
	wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
	wPos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;

	scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
	scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
	scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
	wPos.y -= yDelta * vScaleTransY.x;

	float3 tex = float3((indata.Pos0.y * vTexScale.z), -(((indata.Pos1.x - yDelta) * vTexScale.y)) , (indata.Pos0.x * vTexScale.x));
	float2 xPlaneTexCord = tex.xy;
	float2 yPlaneTexCord = tex.zx;
	float2 zPlaneTexCord = tex.zy;

 	outdata.Pos = mul(wPos, mViewProj);
 	outdata.Tex0.xy = yPlaneTexCord;

	outdata.Tex0.zw = yPlaneTexCord * vNearTexTiling.z; 
	outdata.Tex5.xy = xPlaneTexCord.xy * vNearTexTiling.xy;
	outdata.Tex5.y += vNearTexTiling.w;
	outdata.Tex5.zw = zPlaneTexCord.xy * vNearTexTiling.xy;
	outdata.Tex5.w += vNearTexTiling.w;
 	
 	outdata.Tex2 = yPlaneTexCord * vFarTexTiling.z;
	outdata.Tex3.xy = xPlaneTexCord.xy * vFarTexTiling.xy;
	outdata.Tex3.y += vFarTexTiling.w;
	outdata.Tex3.zw = zPlaneTexCord.xy * vFarTexTiling.xy;
	outdata.Tex3.w += vFarTexTiling.w;

	outdata.BlendValueAndFade.w = interpVal;
	outdata.BlendValueAndFade.xyz = saturate(abs(indata.Normal) - 0.5);
	
	return outdata;
}





struct APP2VS_diffuseLOD1Plus
{
    vec4	Pos0 : POSITION0;
    vec4	Pos1 : POSITION1;
    vec4	MorphDelta : POSITION2;
    vec2	TexCoord0 : TEXCOORD0;
    vec2	TexCoord1 : TEXCOORD1;
    vec3	Normal : NORMAL;
};


struct VS2PS_vsDx9_diffuseLOD1Plus
{
	vec4	Pos : POSITION;
   	vec4	Tex0 : TEXCOORD0;
   	vec4	Tex2 : TEXCOORD2;
    	vec3	BlendValue : COLOR0;
};

vec4 psDx9_diffuseLOD1Plus(VS2PS_vsDx9_diffuseLOD1Plus indata) : COLOR
{
#ifndef USE_PLANE_MAPPING
	vec4 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);
	vec4 lowDetailmap = 2*tex2D(sampler3Wrap, indata.Tex0.zw);
	
	return lowDetailmap.z * colormap;	

#else	
	
	vec4 colormap = tex2D(sampler0Clamp, indata.Tex0.xy);
	vec4 lowComponent = tex2D(sampler2Clamp, indata.Tex0.xy);
	vec4 yplaneLowDetailmap = 2*tex2D(sampler3Wrap, indata.Tex0.zw);
	vec4 xplaneLowDetailmap = 2*tex2D(sampler3Wrap, indata.Tex2.xy);
	vec4 zplaneLowDetailmap = 2*tex2D(sampler3Wrap, indata.Tex2.zw);
	vec3 blendValue = indata.BlendValue;
	
	scalar color = lerp(1, yplaneLowDetailmap.z, saturate(lowComponent.x+lowComponent.y));
	scalar totBlendValue = blendValue.x + blendValue.y + blendValue.z;
	scalar blue = (xplaneLowDetailmap.y * blendValue.x/totBlendValue) + (yplaneLowDetailmap.x * blendValue.y/totBlendValue) + (zplaneLowDetailmap.y * blendValue.z/totBlendValue);
	color *= lerp(1, blue, lowComponent.z);
	
	vec4 lowDetailmap = color;

	return lowDetailmap * colormap;	
#endif	
}

VS2PS_vsDx9_diffuseLOD1Plus vsDx9_diffuseLOD1Plus(APP2VS_diffuseLOD1Plus indata)
{
	VS2PS_vsDx9_diffuseLOD1Plus outdata;
	
	vec4 wPos;
	wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
	wPos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;

	scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
	scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
	scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
	wPos.y -= yDelta * vScaleTransY.x;

	float3 tex = float3(saturate(indata.Pos0.y * vTexScale.z), -(((indata.Pos1.x - yDelta) * vTexScale.y)) , saturate(indata.Pos0.x * vTexScale.x));
	float2 xPlaneTexCord = tex.xy;
	float2 yPlaneTexCord = tex.zx;
	float2 zPlaneTexCord = tex.zy;

 	outdata.Pos = mul(wPos, mViewProj);
 	
 	outdata.Tex0.xy = yPlaneTexCord;

 	outdata.Tex0.zw = yPlaneTexCord * vFarTexTiling.z;
	outdata.Tex2.xy = xPlaneTexCord.xy * vFarTexTiling.xy;
	outdata.Tex2.y += vFarTexTiling.w;
	outdata.Tex2.zw = zPlaneTexCord.xy * vFarTexTiling.xy;
	outdata.Tex2.w += vFarTexTiling.w;

	outdata.BlendValue = saturate(abs(indata.Normal) - 0.5);
 	
	return outdata;
}

struct APP2VS_detailLightmap
{
    vec4	Pos0 : POSITION0;
    vec4	Pos1 : POSITION1;
    vec4	MorphDelta : POSITION2;
    vec2	TexCoord0 : TEXCOORD0;
    vec3	Normal : NORMAL;
};


struct VS2PS_vsDx9_detailLightmap
{
    vec4	Pos : POSITION;
    vec2	Tex0 : TEXCOORD0;
    vec3	wPos		: TEXCOORD1;
    vec3	wNormal		: TEXCOORD2;
};

struct PS2FB_detailLightmap
{
    vec4	Col0 		: COLOR0;
    vec4	Col1 		: COLOR1;
    vec4	Col2 		: COLOR2;
};

PS2FB_detailLightmap psDx9_detailLightmap(VS2PS_vsDx9_detailLightmap indata)
{
	PS2FB_detailLightmap outdata;
	outdata.Col0 = vSunColor.w*tex2D(sampler0Clamp, indata.Tex0);
	outdata.Col1 = vec4(indata.wPos, 0);
	outdata.Col2 = vec4(indata.wNormal, 0);
	return outdata;
}

VS2PS_vsDx9_detailLightmap vsDx9_detailLightmap(APP2VS_detailLightmap indata)
{
	VS2PS_vsDx9_detailLightmap outdata;
	
	vec4 wPos;
	wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
	wPos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;

	scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
	scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
	scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
	wPos.y -= yDelta * vScaleTransY.x;

 	outdata.Pos = mul(wPos, mViewProj);
 	outdata.Tex0 = indata.TexCoord0;
 	outdata.wPos = mul(wPos, mView);
 	outdata.wNormal = indata.Normal;
 	
	return outdata;
}


struct APP2VS_fullMRT
{
    vec4	Pos0 : POSITION0;
    vec4	Pos1 : POSITION1;
    vec4	MorphDelta : POSITION2;
    vec2	TexCoord0 : TEXCOORD0;
    vec3	Normal : NORMAL;
};


struct VS2PS_fullMRT
{
    vec4	Pos 		: POSITION;
    vec2	TexCoord0	: TEXCOORD0;
    vec3	wPos		: TEXCOORD1;
    vec3	wNormal		: TEXCOORD2;
//    vec2	TexCoord1	: TEXCOORD3;
};

struct PS2FB_fullMRT
{
    vec4	Col0 		: COLOR0;
    vec4	Col1 		: COLOR1;
    vec4	Col2 		: COLOR2;
//    vec4	Col3 		: COLOR3;
};

PS2FB_fullMRT psDx9_fullMRT(VS2PS_fullMRT indata)
{
	PS2FB_fullMRT outdata;

	vec4 lightmap = vSunColor.w*tex2D(sampler1Clamp, indata.TexCoord0);
	outdata.Col0 = lightmap;
	outdata.Col1 = vec4(indata.wPos, 0);
	outdata.Col2 = vec4(indata.wNormal, 0);
	
	return outdata;
}

VS2PS_fullMRT vsDx9_fullMRT(APP2VS_fullMRT indata)
{
	VS2PS_fullMRT outdata;
	
	vec4 wPos;
	wPos.xz = (indata.Pos0.xy * vScaleTransXZ.xy) + vScaleTransXZ.zw;
	wPos.yw = (indata.Pos1.xw * vScaleTransY.xy) + vScaleTransY.zw;

	scalar cameraDist = length(wPos.xz - vCamerapos.xz) + vCamerapos.w;
	scalar interpVal = saturate(cameraDist * vNearFarMorphLimits.x - vNearFarMorphLimits.y);
	scalar yDelta = dot(vMorphDeltaSelector, indata.MorphDelta) * interpVal;
	wPos.y -= yDelta * vScaleTransY.x;

 	outdata.Pos = mul(wPos, mViewProj);
 	
 	outdata.TexCoord0 = indata.TexCoord0;
// 	outdata.TexCoord1 = indata.TexCoord0 * 8;
 	outdata.wPos = mul(wPos, mView);
 	outdata.wNormal = indata.Normal;

	return outdata;
}

technique RPDirectX9
{
	pass zFill
	{
		CullMode = CW;
	
		ColorWriteEnable = 0;
		
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		StencilEnable = TRUE;
		StencilFunc = ALWAYS;
		StencilRef = 0x80;
		//StencilMask = 255;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = REPLACE;
		//StencilWriteMask = 255;
		
		
		VertexShader = compile vs_1_1 vsDx9_zFill();
		PixelShader = asm {
			ps.1.1
			def c0, 0, 0, 0, 0
			mov r0, c0
		};
	}
	pass detailDiffuse
	{
		CullMode = NONE;
		ColorWriteEnable = RED|GREEN|BLUE|ALPHA;

		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = EQUAL;
		
		StencilEnable = FALSE;

		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

		VertexShader = compile vs_1_1 vsDx9_detailDiffuse();
		PixelShader = compile PS2_EXT psDx9_detailDiffuse();
	}
	pass diffuseLOD1Plus
	{
		CullMode = CW;
		ColorWriteEnable = RED|GREEN|BLUE|ALPHA;

		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		
		StencilEnable = TRUE;
		StencilFunc = ALWAYS;
		StencilRef = 0x80;
		//StencilMask = 255;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = REPLACE;
		//StencilWriteMask = 255;
		
		AlphaBlendEnable = FALSE;

		VertexShader = compile vs_1_1 vsDx9_diffuseLOD1Plus();
		PixelShader = compile PS2_EXT psDx9_diffuseLOD1Plus();
	}
	pass detailLightmap
	{
		CullMode = CW;
		ColorWriteEnable = RED|GREEN|BLUE|ALPHA;

		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = EQUAL;

		StencilEnable = FALSE;
		
		AlphaBlendEnable = FALSE;

		VertexShader = compile vs_1_1 vsDx9_detailLightmap();
		PixelShader = compile PS2_EXT psDx9_detailLightmap();
	}
	pass fullMRT
	{	
		CullMode = CW;
		ColorWriteEnable = RED|GREEN|BLUE|ALPHA;

		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = EQUAL;
		
		StencilEnable = FALSE;

		AlphaBlendEnable = FALSE;

		VertexShader = compile vs_1_1 vsDx9_fullMRT();
		PixelShader = compile PS2_EXT psDx9_fullMRT();
	}
	pass detailDiffuseMounten
	{
		CullMode = NONE;
		ColorWriteEnable = RED|GREEN|BLUE|ALPHA;

		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = EQUAL;
		
		StencilEnable = FALSE;

		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

		VertexShader = compile vs_1_1 vsDx9_detailDiffuseMounten();
		PixelShader = compile PS2_EXT psDx9_detailDiffuseMounten();
	}
}
