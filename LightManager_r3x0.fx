#include "shaders/datatypes.fx"

mat4x4 mVP : VIEWPROJ;
mat4x4 mWVP : WORLDVIEWPROJ;

mat4x4 mObjW : OBJWORLD;
mat4x4 mCamV : CAMVIEW;
mat4x4 mCamP : CAMPROJ;

mat4x4 mLightVP : LIGHTVIEWPROJ;
mat4x4 mLightOccluderVP : LIGHTOCCLUDERVIEWPROJ;
mat4x4 mCamVI : CAMVIEWI;
mat4x4 mCamPI : CAMPROJI;
vec4 vViewportMap : VIEWPORTMAP;
vec4 vViewportMap2 : VIEWPORTMAP2;

vec4 EyePos : EYEPOS;
vec4 EyeDof : EYEDOF;

vec4 LightWorldPos : LIGHTWORLDPOS;
vec4 LightDir : LIGHTDIR;
vec4 LightPos : LIGHTPOS;
vec4 LightCol : LIGHTCOL;
scalar LightAttenuationRange : LIGHTATTENUATIONRANGE;
scalar LightAttenuationRangeInv : LIGHTATTENUATIONRANGEINV;

vec4 vProjectorMask : PROJECTORMASK;

vec4 paraboloidZValues : PARABOLOIDZVALUES;

dword dwStencilFunc : STENCILFUNC = 3;
dword dwStencilRef : STENCILREF = 0;
dword dwStencilPass : STENCILPASS = 1;

scalar ShadowIntensityBias : SHADOWINTENSITYBIAS;
scalar LightmapIntensityBias : LIGHTMAPINTENSITYBIAS;

texture texture0 : TEXLAYER0;
texture texture1 : TEXLAYER1;
texture texture2 : TEXLAYER2;
texture texture3 : TEXLAYER3;
texture texture4 : TEXLAYER4;
texture texture5 : TEXLAYER5;
texture texture6 : TEXLAYER6;

sampler sampler0 = sampler_state { Texture = (texture0); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler1 = sampler_state { Texture = (texture1); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler2 = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler3 = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler4 = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler5 = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };
sampler sampler6 = sampler_state { Texture = (texture6); AddressU = CLAMP; AddressV = CLAMP; MinFilter = POINT; MagFilter = POINT; };

sampler sampler2bilin = sampler_state { Texture = (texture2); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler3bilin = sampler_state { Texture = (texture3); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = None;};
sampler sampler4bilin = sampler_state { Texture = (texture4); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler5bilin = sampler_state { Texture = (texture5); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler6bilin = sampler_state { Texture = (texture6); AddressU = CLAMP; AddressV = CLAMP; MinFilter = LINEAR; MagFilter = LINEAR; };
//sampler sampler6bilinwrap = sampler_state { Texture = (texture6); AddressU = WRAP; AddressV = WRAP; MinFilter = LINEAR; MagFilter = LINEAR; };

struct APP2VS_Quad
{
    vec2	Pos : POSITION0;
    vec2	TexCoord0 : TEXCOORD0;
};

struct APP2VS_D3DXMesh
{
    vec4	Pos : POSITION0;
    //vec2	TexCoord0 : TEXCOORD0;
};

struct VS2PS_Quad
{
    vec4	Pos 		: POSITION;
    vec2	TexCoord0	: TEXCOORD0;
};

struct VS2PS_Quad_SunLightStatic
{
    vec4	Pos 		: POSITION;
    vec2	TexCoord0	: TEXCOORD0;
    vec2	TCLightmap	: TEXCOORD1;
};

struct VS2PS_D3DXMesh
{
    vec4	Pos 		: POSITION;
    vec4	TexCoord0	: TEXCOORD0;
};

struct VS2PS_D3DXMesh2
{
    vec4	Pos 		: POSITION;
    vec4	wPos		: TEXCOORD0;
};

struct PS2FB_DiffSpec
{
    vec4	Col0 		: COLOR0;
    vec4	Col1 		: COLOR1;
};

struct PS2FB_Combine
{
    vec4	Col0 		: COLOR0;
};

VS2PS_Quad vsDx9_SunLightDynamicObjects(APP2VS_Quad indata)
{
	VS2PS_Quad outdata;	
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0;
 	
	return outdata;
}

VS2PS_Quad vsDx9_SunLightStaticObjects(APP2VS_Quad indata)
{
	VS2PS_Quad outdata;	
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0;

	return outdata;
}

PS2FB_DiffSpec psDx9_SunLightDynamicObjects(VS2PS_Quad indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = tex2D(sampler0, indata.TexCoord0);
	vec3 viewPos = tex2D(sampler1, indata.TexCoord0);
	vec4 lightMap = tex2D(sampler2, indata.TexCoord0);

	scalar diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));
	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));

	scalar spec = saturate(dot(viewNormal.xyz, halfVec));
	scalar shadowIntensity = saturate(lightMap.a+ShadowIntensityBias);
	outdata.Col0 = diff * LightCol * shadowIntensity;
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * shadowIntensity * shadowIntensity;
	
	return outdata;
}

PS2FB_DiffSpec psDx9_SunLightDynamicSkinObjects(VS2PS_Quad indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = tex2D(sampler0, indata.TexCoord0);
	vec3 viewPos = tex2D(sampler1, indata.TexCoord0);
	vec4 lightMap = tex2D(sampler2, indata.TexCoord0);

	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar specTmp = dot(viewNormal.xyz, halfVec)+0.5;
	scalar spec = saturate(specTmp/1.5);

	scalar shadowIntensity = saturate(lightMap.a+ShadowIntensityBias);
	outdata.Col0 = 0;
	outdata.Col1 = pow(spec, 16) * viewNormal.a * LightCol * shadowIntensity * shadowIntensity;
	
	return outdata;
}

PS2FB_DiffSpec psDx9_SunLightStaticObjects(VS2PS_Quad indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = tex2D(sampler0, indata.TexCoord0);
	vec3 viewPos = tex2D(sampler1, indata.TexCoord0);
	vec4 lightMap = tex2D(sampler2, indata.TexCoord0);
		
	scalar diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));
	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec));

	scalar shadowIntensity = saturate(lightMap.a+ShadowIntensityBias);
	outdata.Col0 = diff * LightCol * shadowIntensity;
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * shadowIntensity * shadowIntensity;
	
	return outdata;
}

PS2FB_DiffSpec psDx9_SunLightTransparent(VS2PS_Quad indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = tex2D(sampler0, indata.TexCoord0);
	vec4 wPos = tex2D(sampler1, indata.TexCoord0);
	vec4 diffTex = tex2D(sampler5, indata.TexCoord0);

//	wPos.w = 1;
//	wPos.xy = wPos.xy*2 - 1;
//	wPos = mul(wPos, mCamPI);
//	wPos.xyz /= wPos.w;
//	wPos.w = 1;
//	wPos = mul(wPos, mCamVI);

	scalar diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));
//	vec3 halfVec = normalize(-LightDir.xyz + normalize(-wPos.xyz));
//	scalar spec = saturate(dot(viewNormal.xyz, halfVec));

	outdata.Col0 = diff * LightCol * diffTex.a;
	outdata.Col1 = 0; //TL don't need specular decals; //pow(spec, 36) * viewNormal.a * LightCol * diffTex.a;
	
	return outdata;
}

VS2PS_D3DXMesh vsDx9_SunLightShadowDynamicObjects(APP2VS_D3DXMesh indata)
{
	VS2PS_D3DXMesh outdata;

	vec4 scaledPos = indata.Pos + vec4(0, 0, 0.5, 0);
	scaledPos = mul(scaledPos, mObjW);
	scaledPos = mul(scaledPos, mCamV);
	scaledPos = mul(scaledPos, mCamP);
	outdata.Pos = scaledPos;
//outdata.Pos = mul(indata.Pos + vec4(0, 0, 0.5, 0), mWVP);

 	outdata.TexCoord0.xy = outdata.Pos.xy/outdata.Pos.w;
 	outdata.TexCoord0.xy = (outdata.TexCoord0.xy * 0.5) + 0.5;
 	outdata.TexCoord0.y = 1-outdata.TexCoord0.y;
outdata.TexCoord0.x += 0.5 / 800.0;
outdata.TexCoord0.y += 0.5 / 600.0;
	outdata.TexCoord0.xy = outdata.TexCoord0.xy * outdata.Pos.w;
	outdata.TexCoord0.zw = outdata.Pos.zw;

	return outdata;
}

PS2FB_DiffSpec psDx9_SunLightShadowDynamicObjectsNV(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = (tex2Dproj(sampler0, indata.TexCoord0));
	vec4 viewPos = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 lightUV = mul(viewPos, mLightVP);
	lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);
	
	/*
	vec4 samples;
	samples.x = tex2D(sampler3, lightUV);
	samples.y = tex2D(sampler3, lightUV + vec2(texel, 0));
	samples.z = tex2D(sampler3, lightUV + vec2(0, texel));
	samples.w = tex2D(sampler3, lightUV + vec2(texel, texel));
	*/
	
	scalar avgShadowValue = tex2Dproj(sampler3bilin, lightUV); // HW percentage closer filtering.

	scalar texel = 1.0 / 1024.0;
	vec4 staticSamples;
	staticSamples.x = tex2D(sampler4bilin, lightUV + vec2(-texel*1, -texel*2)).r;
	staticSamples.y = tex2D(sampler4bilin, lightUV + vec2( texel*1, -texel*2)).r;
	staticSamples.z = tex2D(sampler4bilin, lightUV + vec2(-texel*1,  texel*2)).r;
	staticSamples.w = tex2D(sampler4bilin, lightUV + vec2( texel*1,  texel*2)).r;
	staticSamples.x = dot(staticSamples, 0.25);
		
	/*const scalar epsilon = 0.05;
	vec4 cmpbits = (samples.xyzw + epsilon) >= saturate(lightUV.zzzz);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));*/
	
	scalar diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));

	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec));

	outdata.Col0 = diff * LightCol * avgShadowValue * staticSamples.x;
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * avgShadowValue * staticSamples.x;

	return outdata;
}

PS2FB_DiffSpec psDx9_SunLightShadowDynamicObjects(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = (tex2Dproj(sampler0, indata.TexCoord0));
	vec4 viewPos = tex2Dproj(sampler1, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);
	lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);

	vec4 lightUV2 = mul(viewPos, mLightOccluderVP);
	
	scalar texel = 1.0 / 1024.0;
	vec4 samples;
	samples.x = tex2D(sampler3, lightUV);
	samples.y = tex2D(sampler3, lightUV + vec2(texel, 0));
	samples.z = tex2D(sampler3, lightUV + vec2(0, texel));
	samples.w = tex2D(sampler3, lightUV + vec2(texel, texel));

	vec4 staticSamples;
	staticSamples.x = tex2D(sampler4bilin, lightUV + vec2(-texel*1, -texel*2)).r;
	staticSamples.y = tex2D(sampler4bilin, lightUV + vec2( texel*1, -texel*2)).r;
	staticSamples.z = tex2D(sampler4bilin, lightUV + vec2(-texel*1,  texel*2)).r;
	staticSamples.w = tex2D(sampler4bilin, lightUV + vec2( texel*1,  texel*2)).r;

	staticSamples.x = dot(staticSamples, 0.25);
		
	const scalar epsilon = 0.05;
	vec4 cmpbits = (samples.xyzw + epsilon) >= saturate(lightUV.zzzz);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));
	
	scalar diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));

	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec));

	outdata.Col0 = diff * LightCol * avgShadowValue * staticSamples.x;
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * avgShadowValue * staticSamples.x;

	return outdata;
}

PS2FB_DiffSpec psDx9_SunLightShadowDynamic1pObjectsNV(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = (tex2Dproj(sampler0, indata.TexCoord0));
	vec4 viewPos = tex2Dproj(sampler1, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);
	lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);
	
	/*
	vec4 samples;
	samples.x = tex2D(sampler3, lightUV);
	samples.y = tex2D(sampler3, lightUV + vec2(texel, 0));
	samples.z = tex2D(sampler3, lightUV + vec2(0, texel));
	samples.w = tex2D(sampler3, lightUV + vec2(texel, texel));*/
	scalar avgShadowValue = tex2D(sampler3bilin, lightUV); // HW percentage closer filtering.

	scalar texel = 1.0 / 1024.0;
	vec4 staticSamples;
	staticSamples.x = tex2D(sampler4bilin, lightUV + vec2(-texel*1, -texel*2)).r;
	staticSamples.y = tex2D(sampler4bilin, lightUV + vec2( texel*1, -texel*2)).r;
	staticSamples.z = tex2D(sampler4bilin, lightUV + vec2(-texel*1,  texel*2)).r;
	staticSamples.w = tex2D(sampler4bilin, lightUV + vec2( texel*1,  texel*2)).r;
	staticSamples.x = dot(staticSamples, 0.25);
		
	/*const scalar epsilon = 0.05;
	vec4 cmpbits = (samples.xyzw + epsilon) >= saturate(lightUV.zzzz);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));*/
	
	scalar diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));

	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec));

	//scalar totShadow = avgShadowValue*staticSamples.x;
	scalar totShadow = staticSamples.x;

	outdata.Col0 =  diff * LightCol * totShadow;
	//outdata.Col0 = diff * LightCol * saturate(totShadow+0.35);
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * totShadow;

	return outdata;
}

PS2FB_DiffSpec psDx9_SunLightShadowDynamic1pObjects(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = (tex2Dproj(sampler0, indata.TexCoord0));
	vec4 viewPos = tex2Dproj(sampler1, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);
	lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);
	
	scalar texel = 1.0 / 1024.0;
/*
	vec4 samples;
	samples.x = tex2D(sampler3, lightUV);
	samples.y = tex2D(sampler3, lightUV + vec2(texel, 0));
	samples.z = tex2D(sampler3, lightUV + vec2(0, texel));
	samples.w = tex2D(sampler3, lightUV + vec2(texel, texel));
*/

	vec4 staticSamples;
	staticSamples.x = tex2D(sampler4bilin, lightUV + vec2(-texel*1, -texel*2)).r;
	staticSamples.y = tex2D(sampler4bilin, lightUV + vec2( texel*1, -texel*2)).r;
	staticSamples.z = tex2D(sampler4bilin, lightUV + vec2(-texel*1,  texel*2)).r;
	staticSamples.w = tex2D(sampler4bilin, lightUV + vec2( texel*1,  texel*2)).r;
	staticSamples.x = dot(staticSamples, 0.25);
	
/*	
	const scalar epsilon = 0.05;
	vec4 cmpbits = (samples.xyzw + epsilon) >= saturate(lightUV.zzzz);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));
*/

	scalar diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));

	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec));

	//scalar totShadow = avgShadowValue*staticSamples.x;
	scalar totShadow = staticSamples.x;

	outdata.Col0 =  diff * LightCol * totShadow;
	//outdata.Col0 = diff * LightCol * saturate(totShadow+0.35);
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * totShadow;

	return outdata;
}

VS2PS_D3DXMesh vsDx9_SunLightShadowStaticObjects(APP2VS_D3DXMesh indata)
{
	VS2PS_D3DXMesh outdata;

//	vec4 scaledPos = indata.Pos + vec4(0, 0, 0.5, 0);
//	outdata.Pos = mul(scaledPos, mWVP);

	vec4 scaledPos = indata.Pos + vec4(0, 0, 0.5, 0);
	scaledPos = mul(scaledPos, mObjW);
	scaledPos = mul(scaledPos, mCamV);
	scaledPos = mul(scaledPos, mCamP);
	outdata.Pos = scaledPos;

 	outdata.TexCoord0.xy = outdata.Pos.xy/outdata.Pos.w;
 	outdata.TexCoord0.xy = (outdata.TexCoord0.xy * 0.5) + 0.5;
 	outdata.TexCoord0.y = 1-outdata.TexCoord0.y;
outdata.TexCoord0.x += 0.000625;
outdata.TexCoord0.y += 0.000833;
	outdata.TexCoord0.xy = outdata.TexCoord0.xy * outdata.Pos.w;
	outdata.TexCoord0.zw = outdata.Pos.zw;
	
	return outdata;
}

PS2FB_DiffSpec psDx9_SunLightShadowStaticObjectsNV(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = tex2Dproj(sampler0, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 lightMap = tex2Dproj(sampler2, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);
	
	//lightUV.xy = clamp(lightUV.xy, vViewportMap.zw, vViewportMap.xy+vViewportMap.zw);
	lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);
	//lightUV.z *= lightUV.w;
	
	/*scalar texel = 1.0 / 1024.0;
	vec4 samples;
	samples.x = tex2D(sampler3, lightUV);
	samples.y = tex2D(sampler3, lightUV + vec2(texel, 0));
	samples.z = tex2D(sampler3, lightUV + vec2(0, texel));
	samples.w = tex2D(sampler3, lightUV + vec2(texel, texel));*/
	lightUV.z = /*clamp(lightUV.z, 0, 0.999);//*/saturate(lightUV.z) - 0.001;
	scalar avgShadowValue = tex2Dproj(sampler3bilin, lightUV); // HW percentage closer filtering.
		
	/*const scalar epsilon = 0.0075;
//const scalar epsilon = 0.085;
//	scalar epsilon = 0.00000001;// -projPos.z / 100;
	vec4 cmpbits = (samples.xyzw + epsilon) >= saturate(lightUV.zzzz);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));*/
	
	scalar diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));
	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec));

	outdata.Col0 = diff * LightCol * saturate((lightMap.a * avgShadowValue) + ShadowIntensityBias);
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * saturate(lightMap.a*avgShadowValue+ShadowIntensityBias);
	
	return outdata;
}

PS2FB_DiffSpec psDx9_SunLightShadowStaticObjects(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = tex2Dproj(sampler0, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 lightMap = tex2Dproj(sampler2, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);

	//lightUV.xy = clamp(lightUV.xy, vViewportMap.zw, vViewportMap.xy+vViewportMap.zw);
	lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);
	
	scalar texel = 1.0 / 1024.0;
	vec4 samples;
	samples.x = tex2D(sampler3, lightUV);
	samples.y = tex2D(sampler3, lightUV + vec2(texel, 0));
	samples.z = tex2D(sampler3, lightUV + vec2(0, texel));
	samples.w = tex2D(sampler3, lightUV + vec2(texel, texel));
		
	const scalar epsilon = 0.0075;
//const scalar epsilon = 0.085;
//	scalar epsilon = 0.00000001;// -projPos.z / 100;
	vec4 cmpbits = (samples.xyzw + epsilon) >= saturate(lightUV.zzzz);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));
	
	scalar diff = saturate(dot(viewNormal.xyz, -LightDir.xyz));
	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec));

	outdata.Col0 = diff * LightCol * saturate((lightMap.a*avgShadowValue)+ShadowIntensityBias);
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol * saturate(lightMap.a*avgShadowValue+ShadowIntensityBias);
	
	return outdata;
}

VS2PS_D3DXMesh vsDx9_PointLight(APP2VS_D3DXMesh indata)
{
	VS2PS_D3DXMesh outdata;

 	vec3 wPos = indata.Pos * LightAttenuationRange + LightWorldPos.xyz;
 	outdata.Pos = mul(vec4(wPos, 1), mVP);

 	outdata.TexCoord0.xy = outdata.Pos.xy/outdata.Pos.w;
 	outdata.TexCoord0.xy = (outdata.TexCoord0.xy * 0.5) + 0.5;
 	outdata.TexCoord0.y = 1-outdata.TexCoord0.y;
outdata.TexCoord0.x += 0.000625;
outdata.TexCoord0.y += 0.000833;
	outdata.TexCoord0.xy = outdata.TexCoord0.xy * outdata.Pos.w;
	outdata.TexCoord0.zw = outdata.Pos.zw;

	return outdata;
}

PS2FB_DiffSpec psDx9_PointLight(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
	vec4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;

	vec4 radialAtt = tex1D(sampler4bilin, lightDist);

	scalar diff = saturate(dot(viewNormal.xyz, normalize(lightVec))) * radialAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;
		
	outdata.Col0 = max(diff * LightCol, currDiff);
	outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

	return outdata;
}

PS2FB_DiffSpec psDx9_PointLightNV40(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;

	vec4 radialAtt = tex1D(sampler4bilin, lightDist);

	scalar diff = saturate(dot(viewNormal.xyz, normalize(lightVec))) * radialAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;
		
	outdata.Col0 = diff * LightCol;
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol;

	return outdata;
}

PS2FB_DiffSpec psDx9_PointLight2(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
	vec4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);
	vec4 lightmap = tex2Dproj(sampler5, indata.TexCoord0);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;

	vec4 radialAtt = tex1D(sampler4bilin, lightDist);

	scalar diff = saturate(dot(viewNormal.xyz, normalize(lightVec))) * radialAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

outdata.Col0 = max(diff * LightCol, currDiff);
//	outdata.Col0 = max(max(lightmap,diff * LightCol), currDiff);
	outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

	return outdata;
}

PS2FB_DiffSpec psDx9_PointLightShadowNV(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
	vec4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 paraPos1 = -lightVec;
	paraPos1 = normalize(paraPos1);
	paraPos1 = mul(paraPos1, mCamVI);
	scalar hemiSel = paraPos1.z;
	vec3 paraPos2 = paraPos1 - vec3(0, 0, 1);
	paraPos1 += vec3(0, 0, 1);
	
	paraPos1.xy /= paraPos1.z;
	paraPos2.xy /= paraPos2.z;
	
	//paraboloidZValues.x *= 1;
	//paraboloidZValues.y += 1;
	scalar paraPosZ = lightDist*paraboloidZValues.x + paraboloidZValues.y;
	//scalar paraPosZ = (paraPos1.z - paraboloidZValues.y) / paraboloidZValues.x;//lightDist*paraboloidZValues.x + paraboloidZValues.y;
	
	paraPos1.xy = saturate(paraPos1.xy * vec2(0.5, -0.5) + 0.5);
	paraPos1.xy = paraPos1.xy * vViewportMap.wz + vViewportMap.xy;
	paraPos2.xy = saturate(paraPos2.xy * vec2(-0.5, 0.5) + 0.5);
	paraPos2.xy = paraPos2.xy * vViewportMap.wz + vViewportMap.xy;
	
	vec2 avgPara;
	avgPara.x = tex2Dproj(sampler5bilin, vec4(paraPos1.xy, paraPosZ, 1));
	avgPara.y = tex2Dproj(sampler6bilin, vec4(paraPos2.xy, paraPosZ, 1));

	//const scalar epsilon = 0.0075;
	//vec2 avgPara = (paraSamples.xy + epsilon) >= paraPosZ;

	scalar diff = saturate(dot(viewNormal.xyz, normalize(lightVec))) * radialAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = 0;//saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;
		
	scalar shad = hemiSel >= 0 ? avgPara.x : avgPara.y;
	outdata.Col0 = max(diff * LightCol * shad, currDiff);
	outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

	return outdata;
}



PS2FB_DiffSpec psDx9_PointLightShadow(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
	vec4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 paraPos1 = -lightVec;
	paraPos1 = normalize(paraPos1);
	paraPos1 = mul(paraPos1, mCamVI);
	scalar hemiSel = paraPos1.z;
	vec3 paraPos2 = paraPos1 - vec3(0, 0, 1);
	paraPos1 += vec3(0, 0, 1);
	
	paraPos1.xy /= paraPos1.z;
	paraPos2.xy /= paraPos2.z;
	scalar paraPosZ = lightDist*paraboloidZValues.x + paraboloidZValues.y;
	
	paraPos1.xy = saturate(paraPos1.xy * vec2(0.5, -0.5) + 0.5);
	paraPos1.xy = paraPos1.xy * vViewportMap.wz + vViewportMap.xy;
	paraPos2.xy = saturate(paraPos2.xy * vec2(-0.5, 0.5) + 0.5);
	paraPos2.xy = paraPos2.xy * vViewportMap.wz + vViewportMap.xy;

	vec2 paraSamples;
	paraSamples.x = tex2D(sampler5, paraPos1);
	paraSamples.y = tex2D(sampler6, paraPos2);

	const scalar epsilon = 0.0075;
	vec2 avgPara = (paraSamples.xy + epsilon) >= paraPosZ;

	scalar diff = saturate(dot(viewNormal.xyz, normalize(lightVec))) * radialAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = 0;//saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;
		
	scalar shad = hemiSel >= 0 ? avgPara.x : avgPara.y;
	outdata.Col0 = max(diff * LightCol * shad, currDiff);
	outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

	return outdata;
}

PS2FB_DiffSpec psDx9_PointLightShadowNV40(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 paraPos1 = -lightVec;
	paraPos1 = normalize(paraPos1);
	paraPos1 = mul(paraPos1, mCamVI);
	scalar hemiSel = paraPos1.z;
	vec3 paraPos2 = paraPos1 - vec3(0, 0, 1);
	paraPos1 += vec3(0, 0, 1);
	
	paraPos1.xy /= paraPos1.z;
	paraPos2.xy /= paraPos2.z;
	scalar paraPosZ = lightDist*paraboloidZValues.x + paraboloidZValues.y;
	paraPosZ += paraPosZ + 0.5;
	
	paraPos1.xy = saturate(paraPos1.xy * vec2(0.5, -0.5) + 0.5);
	paraPos1.xy = paraPos1.xy * vViewportMap.wz + vViewportMap.xy;
	paraPos2.xy = saturate(paraPos2.xy * vec2(-0.5, 0.5) + 0.5);
	paraPos2.xy = paraPos2.xy * vViewportMap.wz + vViewportMap.xy;

	vec2 paraSamples;
	paraSamples.x = tex2D(sampler5, paraPos1);
	paraSamples.y = tex2D(sampler6, paraPos2);

	const scalar epsilon = 0.0075;
	vec2 avgPara = (paraSamples.xy + epsilon) >= paraPosZ;

	scalar diff = saturate(dot(viewNormal.xyz, normalize(lightVec))) * radialAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(-viewPos.xyz));
	scalar spec = 0;//saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;
		
	scalar shad = hemiSel >= 0 ? avgPara.x : avgPara.y;
	outdata.Col0 = diff * LightCol * shad;
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol;

	return outdata;
}

VS2PS_D3DXMesh2 vsDx9_PointLightGlow(APP2VS_D3DXMesh indata)
{
	VS2PS_D3DXMesh2 outdata;

	scalar scale = LightAttenuationRange;
 	vec3 wPos = (indata.Pos*scale) + LightWorldPos.xyz;
 	outdata.Pos = mul(vec4(wPos, 1), mVP);

	outdata.wPos = dot(normalize(EyePos-LightWorldPos.xyz),normalize(wPos-LightWorldPos.xyz));
	outdata.wPos = outdata.wPos*outdata.wPos*outdata.wPos*outdata.wPos;
	return outdata;
}

vec4 psDx9_PointLightGlow(VS2PS_D3DXMesh2 indata) : COLOR
{
	return vec4(LightCol * indata.wPos.rgb,1);	
}

VS2PS_D3DXMesh vsDx9_SpotLight(APP2VS_D3DXMesh indata)
{
	VS2PS_D3DXMesh outdata;

	vec4 scaledPos = indata.Pos * vec4(1.5, 1.5, 1, 1) + vec4(0, 0, 0.5, 0);
 	outdata.Pos = mul(scaledPos, mWVP);

 	outdata.TexCoord0.xy = outdata.Pos.xy/outdata.Pos.w;
 	outdata.TexCoord0.xy = (outdata.TexCoord0.xy * 0.5) + 0.5;
 	outdata.TexCoord0.y = 1-outdata.TexCoord0.y;
outdata.TexCoord0.x += 0.000625;
outdata.TexCoord0.y += 0.000833;
	outdata.TexCoord0.xy = outdata.TexCoord0.xy * outdata.Pos.w;
	outdata.TexCoord0.zw = outdata.Pos.zw;

	return outdata;
}

PS2FB_DiffSpec psDx9_SpotLightNV40(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 lightVecN = normalize(lightVec);
	scalar fallOff = dot(-lightVecN, LightDir);
	vec4 conicalAtt = tex1D(sampler5bilin, 1-(fallOff*fallOff));

	scalar diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt * conicalAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

	outdata.Col0 = diff * LightCol;
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol;

	return outdata;
}

PS2FB_DiffSpec psDx9_SpotLight(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
	vec4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 lightVecN = normalize(lightVec);
	scalar fallOff = dot(-lightVecN, LightDir);
	vec4 conicalAtt = tex1D(sampler5bilin, 1-(fallOff*fallOff));

	scalar diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt * conicalAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

	outdata.Col0 = max(diff * LightCol, currDiff);
	outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

	return outdata;
}

PS2FB_DiffSpec psDx9_SpotLightShadowNV(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
	vec4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);
	lightUV.xyz /= lightUV.w;
	lightUV.xy = lightUV.xy * vec2(0.5, -0.5) + 0.5;

	//scalar texel = 1.0 / 1024.0;
	//const scalar epsilon = 0.005;
	vec4 samples = tex2D(sampler6bilin, lightUV);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 lightVecN = normalize(lightVec);
	scalar fallOff = dot(-lightVecN, LightDir);
	vec4 conicalAtt = tex1D(sampler5bilin, 1-(fallOff*fallOff));

	scalar diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt * conicalAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

	outdata.Col0 = max(diff * LightCol, currDiff);
	outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

	return outdata;
}

PS2FB_DiffSpec psDx9_SpotLightShadowNV40(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);
	lightUV.xyz /= lightUV.w;
	lightUV.xy = lightUV.xy * vec2(0.5, -0.5) + 0.5;

	//scalar texel = 1.0 / 1024.0;
	//const scalar epsilon = 0.005;
	vec4 samples = tex2D(sampler6, lightUV);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 lightVecN = normalize(lightVec);
	scalar fallOff = dot(-lightVecN, LightDir);
	vec4 conicalAtt = tex1D(sampler5bilin, 1-(fallOff*fallOff));

	scalar diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt * conicalAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

	outdata.Col0 = diff * LightCol;
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol;

	return outdata;
}

PS2FB_DiffSpec psDx9_SpotLightShadow(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
	vec4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);
	lightUV.xyz /= lightUV.w;
	lightUV.xy = lightUV.xy * vec2(0.5, -0.5) + 0.5;

	//scalar texel = 1.0 / 1024.0;
	//const scalar epsilon = 0.005;
	vec4 samples = tex2D(sampler6, lightUV);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 lightVecN = normalize(lightVec);
	scalar fallOff = dot(-lightVecN, LightDir);
	vec4 conicalAtt = tex1D(sampler5bilin, 1-(fallOff*fallOff));

	scalar diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt * conicalAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

	outdata.Col0 = max(diff * LightCol, currDiff);
	outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

	return outdata;
}

VS2PS_D3DXMesh vsDx9_SpotProjector(APP2VS_D3DXMesh indata)
{
	VS2PS_D3DXMesh outdata;

	scalar near = 0.01;
	scalar far = 10;
	scalar vdist = far-near;
	
	vec4 properPos = indata.Pos + vec4(0, 0, 0.5, 0);
	//properPos.xy *= properPos.z;
 	outdata.Pos = mul(properPos, mWVP);

 	outdata.TexCoord0.xy = outdata.Pos.xy/outdata.Pos.w;
 	outdata.TexCoord0.xy = (outdata.TexCoord0.xy * 0.5) + 0.5;
 	outdata.TexCoord0.y = 1-outdata.TexCoord0.y;
outdata.TexCoord0.x += 0.000625;
outdata.TexCoord0.y += 0.000833;
	outdata.TexCoord0.xy = outdata.TexCoord0.xy * outdata.Pos.w;
	outdata.TexCoord0.zw = outdata.Pos.zw;

	return outdata;
}

PS2FB_DiffSpec psDx9_SpotProjectorNV40(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);
	lightUV.xy /= lightUV.w;
	lightUV.xy = lightUV.xy * 0.5 + 0.5;
	vec4 headlight = tex2D(sampler5bilin, lightUV);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 lightVecN = normalize(lightVec);

	scalar diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

	diff *= saturate(dot(headlight.rgb, vProjectorMask.rgb)) * saturate(dot(-LightDir.xyz, lightVec));
	outdata.Col0 = diff * LightCol;
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol;

	return outdata;
}

PS2FB_DiffSpec psDx9_SpotProjector(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
	vec4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);
	lightUV.xy /= lightUV.w;
	lightUV.xy = lightUV.xy * 0.5 + 0.5;
	vec4 headlight = tex2D(sampler5bilin, lightUV);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 lightVecN = normalize(lightVec);

	scalar diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

	diff *= saturate(dot(headlight.rgb, vProjectorMask.rgb)) * saturate(dot(-LightDir.xyz, lightVec));
	outdata.Col0 = max(diff * LightCol, currDiff);
	outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

	return outdata;
}

PS2FB_DiffSpec psDx9_SpotProjectorShadowNV(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
	vec4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);
	lightUV.xyz /= lightUV.w;
	
	vec2 headlightuv = lightUV.xy * vec2(0.5, 0.5) + 0.5;
	vec4 headlight = tex2D(sampler5bilin, headlightuv);

//	lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);
//	lightUV.xy = lightUV.xy * vec2(0.5, -0.5) + 0.5;
//	lightUV.xy = lightUV.xy * vec2(1, -1);

	/*scalar texel = 1.0 / 1024.0;
	const scalar epsilon = 0.005;
	vec4 samples;
	samples.x = tex2D(sampler6, lightUV);
	samples.y = tex2D(sampler6, lightUV + vec2(texel, 0));
	samples.z = tex2D(sampler6, lightUV + vec2(0, texel));
	samples.w = tex2D(sampler6, lightUV + vec2(texel, texel));
	vec4 avgSamples = (samples.xyzw+epsilon) > lightUV.zzzz;
	avgSamples = dot(avgSamples, 0.25);*/
	vec4 avgSamples = tex2D(sampler6bilin, lightUV);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 lightVecN = normalize(lightVec);

	scalar diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

	diff *= (dot(headlight.rgb, vProjectorMask.rgb));
	diff *= avgSamples * saturate(dot(-LightDir.xyz, lightVec));
	outdata.Col0 = max(diff * LightCol, currDiff);
	outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

	return outdata;
}

PS2FB_DiffSpec psDx9_SpotProjectorShadowNV40(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	//vec4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
	//vec4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);
	lightUV.xyz	 /= lightUV.w;
	
		
	vec2 headlightuv = lightUV.xy * vec2(0.5, 0.5) + 0.5;
	vec4 headlight = tex2D(sampler5bilin, headlightuv);

	
//	lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);
	lightUV.xy = saturate(lightUV.xy * vec2(0.5, -0.5) + 0.5);
	lightUV.xy = lightUV.xy * vViewportMap.zw + vViewportMap.xy;

	scalar texel = 1.0 / 1024.0;
	const scalar epsilon = 0.005;
	vec4 samples;
	samples.x = tex2D(sampler6, lightUV);
	samples.y = tex2D(sampler6, lightUV + vec2(texel, 0));
	samples.z = tex2D(sampler6, lightUV + vec2(0, texel));
	samples.w = tex2D(sampler6, lightUV + vec2(texel, texel));
	vec4 avgSamples = (samples.xyzw+epsilon) > lightUV.zzzz;
	avgSamples = dot(avgSamples, 0.25);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 lightVecN = normalize(lightVec);

	scalar diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

	diff *= (dot(headlight.rgb, vProjectorMask.rgb));
	diff *= avgSamples * saturate(dot(-LightDir.xyz, lightVec));
	outdata.Col0 = diff * LightCol;
	outdata.Col1 = pow(spec, 36) * viewNormal.a * LightCol;

	return outdata;
}

PS2FB_DiffSpec psDx9_SpotProjectorShadow(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	
	vec4 currDiff = tex2Dproj(sampler0, indata.TexCoord0);
	vec4 currSpec = tex2Dproj(sampler1, indata.TexCoord0);
	
	vec4 viewNormal = tex2Dproj(sampler2, indata.TexCoord0);
	vec4 viewPos = tex2Dproj(sampler3, indata.TexCoord0);

	vec4 lightUV = mul(viewPos, mLightVP);
	lightUV.xyz	 /= 1.1* lightUV.w;
		
	vec2 headlightuv = lightUV.xy * vec2(0.5, 0.5) + 0.5;
	vec4 headlight = tex2D(sampler5bilin, headlightuv);

	
//	lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);
	lightUV.xy = lightUV.xy * vec2(0.5, -0.5) + 0.5;
	lightUV.xy = saturate(lightUV.xy * vViewportMap.zw + vViewportMap.xy);
//	lightUV.xy = lightUV.xy * vec2(1, -1);

	scalar texel = 1.0 / 1024.0;
	const scalar epsilon = 0.005;
	vec4 samples;
	samples.x = tex2D(sampler6, lightUV);
	samples.y = tex2D(sampler6, lightUV + vec2(texel, 0));
	samples.z = tex2D(sampler6, lightUV + vec2(0, texel));
	samples.w = tex2D(sampler6, lightUV + vec2(texel, texel));
	vec4 avgSamples = (samples.xyzw+epsilon) > lightUV.zzzz;
	avgSamples = dot(avgSamples, 0.25);

	vec3 lightVec = LightPos.xyz - viewPos;
	scalar lightDist = length(lightVec);
	lightDist *= LightAttenuationRangeInv;
	vec4 radialAtt = tex1D(sampler4bilin, lightDist);
	
	vec3 lightVecN = normalize(lightVec);

	scalar diff = saturate(dot(viewNormal.xyz, lightVecN)) * radialAtt;
	vec3 halfVec = normalize(-LightDir.xyz + normalize(viewPos.xyz-EyePos.xyz));
	scalar spec = saturate(dot(viewNormal.xyz, halfVec)) * radialAtt;

	diff *= (dot(headlight.rgb, vProjectorMask.rgb));
	diff *= avgSamples * saturate(dot(-LightDir.xyz, lightVec));
	outdata.Col0 = max(diff * LightCol, currDiff);
	outdata.Col1 = max(pow(spec, 36) * viewNormal.a * LightCol, currSpec);

	return outdata;
}

VS2PS_D3DXMesh vsDx9_BlitBackLightContribPoint(APP2VS_D3DXMesh indata)
{
	VS2PS_D3DXMesh outdata;

 	vec3 wPos = indata.Pos * LightAttenuationRange + LightWorldPos.xyz;
 	outdata.Pos = mul(vec4(wPos, 1), mVP);

 	outdata.TexCoord0.xy = outdata.Pos.xy/outdata.Pos.w;
 	outdata.TexCoord0.xy = (outdata.TexCoord0.xy * 0.5) + 0.5;
 	outdata.TexCoord0.y = 1-outdata.TexCoord0.y;
outdata.TexCoord0.x += 0.000625;
outdata.TexCoord0.y += 0.000833;
	outdata.TexCoord0.xy = outdata.TexCoord0.xy * outdata.Pos.w;
	outdata.TexCoord0.zw = outdata.Pos.zw;

	return outdata;
}

VS2PS_D3DXMesh vsDx9_BlitBackLightContribSpot(APP2VS_D3DXMesh indata)
{
	VS2PS_D3DXMesh outdata;

	vec4 scaledPos = indata.Pos * vec4(1.5, 1.5, 1, 1) + vec4(0, 0, 0.5, 0);
 	outdata.Pos = mul(scaledPos, mWVP);
 	
 	outdata.TexCoord0.xy = outdata.Pos.xy/outdata.Pos.w;
 	outdata.TexCoord0.xy = (outdata.TexCoord0.xy * 0.5) + 0.5;
 	outdata.TexCoord0.y = 1-outdata.TexCoord0.y;
outdata.TexCoord0.x += 0.000625;
outdata.TexCoord0.y += 0.000833;
	outdata.TexCoord0.xy = outdata.TexCoord0.xy * outdata.Pos.w;
	outdata.TexCoord0.zw = outdata.Pos.zw;

	return outdata;
}

VS2PS_D3DXMesh vsDx9_BlitBackLightContribSpotProjector(APP2VS_D3DXMesh indata)
{
	VS2PS_D3DXMesh outdata;

	scalar near = 0.01;
	scalar far = 10;
	scalar vdist = far-near;
	
	vec4 properPos = indata.Pos + vec4(0, 0, 0.5, 0);
	//properPos.z *= vdist;
	//properPos.z += near;
//properPos.z += 0.1;
	//properPos.xy *= properPos.z;
	
 	outdata.Pos = mul(properPos, mWVP);
 	
 	outdata.TexCoord0.xy = outdata.Pos.xy/outdata.Pos.w;
 	outdata.TexCoord0.xy = (outdata.TexCoord0.xy * 0.5) + 0.5;
 	outdata.TexCoord0.y = 1-outdata.TexCoord0.y;
outdata.TexCoord0.x += 0.000625;
outdata.TexCoord0.y += 0.000833;
	outdata.TexCoord0.xy = outdata.TexCoord0.xy * outdata.Pos.w;
	outdata.TexCoord0.zw = outdata.Pos.zw;

	return outdata;
}

PS2FB_DiffSpec psDx9_BlitBackLightContrib(VS2PS_D3DXMesh indata)
{
	PS2FB_DiffSpec outdata;
	outdata.Col0 = tex2Dproj(sampler0, indata.TexCoord0);
	outdata.Col1 = tex2Dproj(sampler1, indata.TexCoord0);
	return outdata;
}

VS2PS_Quad vsDx9_Combine(APP2VS_Quad indata)
{
	VS2PS_Quad outdata;	
 	outdata.Pos = vec4(indata.Pos.x, indata.Pos.y, 0, 1);
 	outdata.TexCoord0 = indata.TexCoord0;
	return outdata;
}

PS2FB_Combine psDx9_Combine(VS2PS_Quad indata)
{
	PS2FB_Combine outdata;
	
	vec4 lightmap = tex2D(sampler0, indata.TexCoord0);
	vec4 diffTex = tex2D(sampler1, indata.TexCoord0);
	vec4 diff1 = tex2D(sampler2, indata.TexCoord0);
	vec4 spec1 = tex2D(sampler3, indata.TexCoord0);

	vec4 diffTot = (lightmap+LightmapIntensityBias) + diff1;
	vec4 specTot = spec1;

	outdata.Col0 = diffTot * diffTex + specTot;

	return outdata;
}

PS2FB_Combine psDx9_CombineTransparent(VS2PS_Quad indata)
{
	PS2FB_Combine outdata;
	
	vec4 lightmap = tex2D(sampler0, indata.TexCoord0);
	vec4 diffTex = tex2D(sampler1, indata.TexCoord0);
	vec4 diff1 = tex2D(sampler2, indata.TexCoord0);
	vec4 spec1 = tex2D(sampler3, indata.TexCoord0);

	//scalar sunDot = saturate(dot(EyeDof, -LightDir.xyz));
	//scalar expDot = sunDot*sunDot*sunDot*sunDot*sunDot*sunDot;
	//expDot = clamp(expDot, 0, 0.25);

	vec4 diffTot = lightmap + diff1;// - expDot;

	vec4 specTot = spec1;

	outdata.Col0 = diffTot * diffTex + specTot;
	outdata.Col0.a = diffTex.a;

	return outdata;
}

technique SunLight
{
	pass opaqueDynamicObjects
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilRef = (dwStencilRef);
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = (dwStencilPass);
		
		VertexShader = compile vs_1_1 vsDx9_SunLightDynamicObjects();
		PixelShader = compile PS2_EXT psDx9_SunLightDynamicObjects();
	}
	pass opaqueDynamicSkinObjects
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilRef = (dwStencilRef);
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = (dwStencilPass);
		
		VertexShader = compile vs_1_1 vsDx9_SunLightDynamicObjects();
		PixelShader = compile PS2_EXT psDx9_SunLightDynamicSkinObjects();
	}
	pass opaqueStaticObjects
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilRef = (dwStencilRef);
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_SunLightStaticObjects();
		PixelShader = compile PS2_EXT psDx9_SunLightStaticObjects();
	}

	pass transparent
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
//StencilFunc = EQUAL;
//StencilRef = 3;
StencilFunc = NEVER;
//StencilRef = 223;
//StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_SunLightDynamicObjects();
		PixelShader = compile PS2_EXT psDx9_SunLightTransparent();
	}
}
technique SunLightShadowNV <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass opaqueDynamicObjects
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		
		CullMode = NONE;
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilRef = 0x20;
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = INCR;
		
		VertexShader = compile vs_1_1 vsDx9_SunLightShadowDynamicObjects();
		PixelShader = compile PS2_EXT psDx9_SunLightShadowDynamicObjectsNV();
	}
	pass opaqueDynamic1pObjects
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		
		CullMode = NONE;
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilRef = 0x80;
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = DECR;
		
		VertexShader = compile vs_1_1 vsDx9_SunLightShadowDynamicObjects();
		PixelShader = compile PS2_EXT psDx9_SunLightShadowDynamic1pObjectsNV();
	}
	pass opaqueStaticObjects
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		
		CullMode = NONE;	
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilRef = 0x40;
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = INCR;
		
		DepthBias = 0.000;
		SlopeScaleDepthBias = 2;
				
		VertexShader = compile vs_1_1 vsDx9_SunLightShadowStaticObjects();
		PixelShader = compile PS2_EXT psDx9_SunLightShadowStaticObjectsNV();
	}
	pass foobar
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
		
//		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
StencilFunc = EQUAL;
StencilRef = 240;
		//StencilFunc = NOTEQUAL;
		//StencilRef = 1;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_SunLightShadowStaticObjects();
		PixelShader = compile PS2_EXT psDx9_SunLightShadowStaticObjectsNV();
	}
}

technique SunLightShadow <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass opaqueDynamicObjects
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		
		CullMode = NONE;
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilRef = 0x20;
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = INCR;
		
		VertexShader = compile vs_1_1 vsDx9_SunLightShadowDynamicObjects();
		PixelShader = compile PS2_EXT psDx9_SunLightShadowDynamicObjects();
	}
	pass opaqueDynamic1pObjects
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		
		CullMode = NONE;
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilRef = 0x80;
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = DECR;
		
		VertexShader = compile vs_1_1 vsDx9_SunLightShadowDynamicObjects();
		PixelShader = compile PS2_EXT psDx9_SunLightShadowDynamic1pObjects();
	}
	pass opaqueStaticObjects
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		
		CullMode = NONE;	
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilRef = 0x40;
		StencilMask = 0xFF;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = INCR;
				
		VertexShader = compile vs_1_1 vsDx9_SunLightShadowStaticObjects();
		PixelShader = compile PS2_EXT psDx9_SunLightShadowStaticObjects();
	}
	pass foobar
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
		
//		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
StencilFunc = EQUAL;
StencilRef = 240;
		//StencilFunc = NOTEQUAL;
		//StencilRef = 1;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_SunLightShadowStaticObjects();
		PixelShader = compile PS2_EXT psDx9_SunLightShadowStaticObjects();
	}
}

technique PointLight <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
//		ZFunc = LESSEQUAL;
//		CullMode = NONE;
//		ZFunc = GREATER;
//		CullMode = CW;
		
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		//StencilFunc = (dwStencilFunc);//NOTEQUAL;
		//StencilRef = (dwStencilRef);//1;
		StencilFunc = NOTEQUAL;
		StencilRef = 1;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_PointLight();
		PixelShader = compile PS2_EXT psDx9_PointLight();
	}

	pass p1
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
//		ZFunc = LESSEQUAL;
//		CullMode = NONE;
//		ZFunc = GREATER;
//		CullMode = CW;
		
		AlphaBlendEnable = FALSE;

		StencilFunc = (dwStencilFunc);//EQUAL;
		
		VertexShader = compile vs_1_1 vsDx9_PointLight();
		PixelShader = compile PS2_EXT psDx9_PointLight2();
	}
}

technique PointLightNV40 <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ColorWriteEnable  = RED|GREEN|BLUE|ALPHA;
		ColorWriteEnable1 = RED|GREEN|BLUE|ALPHA;
		ColorWriteEnable2 = RED|GREEN|BLUE|ALPHA;
		ColorWriteEnable3 = RED|GREEN|BLUE|ALPHA;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		
		CullMode = NONE;
		
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		BlendOp = MAX;

		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilMask = 0xFF;
		StencilRef = 0x55;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_PointLight();
		PixelShader = compile PS2_EXT psDx9_PointLightNV40();
	}
	
	pass ReplaceStencil
	{
		ColorWriteEnable  = 0;
		ColorWriteEnable1 = 0;
		ColorWriteEnable2 = 0;
		ColorWriteEnable3 = 0;
		
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESS;
		CullMode = NONE;
		
		AlphaBlendEnable = FALSE;
		
		StencilEnable = TRUE;
		StencilFunc = ALWAYS;
		StencilMask = 0xFF;
		StencilRef = 0x55;
		StencilFAIL = KEEP;
		StencilZFail = REPLACE;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_PointLight();
		PixelShader = asm
		{
			ps.1.1
			def c0, 0, 0, 0, 0
			mov r0, c0
		};
	}

	/*pass p1
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
//		ZFunc = LESSEQUAL;
//		CullMode = NONE;
//		ZFunc = GREATER;
//		CullMode = CW;
		
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		BlendOp = MAX;

		StencilFunc = (dwStencilFunc);//EQUAL;
		
		VertexShader = compile vs_1_1 vsDx9_PointLight();
		PixelShader = compile PS2_EXT psDx9_PointLight2();
	}*/
}

technique PointLightShadowNV <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
		
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 1;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_PointLight();
		PixelShader = compile PS2_EXT psDx9_PointLightShadowNV();
	}
}

technique PointLightShadow <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
		
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 1;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_PointLight();
		PixelShader = compile PS2_EXT psDx9_PointLightShadow();
	}
}

technique PointLightShadowNV40 <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ColorWriteEnable  = RED|GREEN|BLUE|ALPHA;
		ColorWriteEnable1 = RED|GREEN|BLUE|ALPHA;
		ColorWriteEnable2 = RED|GREEN|BLUE|ALPHA;
		ColorWriteEnable3 = RED|GREEN|BLUE|ALPHA;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		
		CullMode = NONE;
		
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		BlendOp = MAX;

		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilMask = 0xFF;
		StencilRef = 0x55;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_PointLight();
		PixelShader = compile PS2_EXT psDx9_PointLightShadowNV40();
	}
	
	pass ReplaceStencil
	{
		ColorWriteEnable = 0;
		ColorWriteEnable1 = 0;
		ColorWriteEnable2 = 0;
		ColorWriteEnable3 = 0;
		
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESS;
		CullMode = NONE;
		
		AlphaBlendEnable = FALSE;
		
		StencilEnable = TRUE;
		StencilFunc = ALWAYS;
		StencilMask = 0xFF;
		StencilRef = 0x55;
		StencilFAIL = KEEP;
		StencilZFail = REPLACE;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_PointLight();
		PixelShader = asm
		{
			ps.1.1
			def c0, 0, 0, 0, 0
			mov r0, c0
		};
	}
}

technique PointLightGlow <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;
		CullMode = CCW;
		
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCCOLOR;
		DestBlend = ONE;

		StencilEnable = FALSE;
		
		VertexShader = compile vs_1_1 vsDx9_PointLightGlow();
		PixelShader = compile ps_1_1 psDx9_PointLightGlow();
	}
}

technique SpotLight <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
		
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		
		VertexShader = compile vs_1_1 vsDx9_SpotLight();
		PixelShader = compile PS2_EXT psDx9_SpotLight();
	}
}

technique SpotLightNV40 <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
		
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		BlendOp = MAX;
		
		StencilEnable = FALSE;
		
		VertexShader = compile vs_1_1 vsDx9_SpotLight();
		PixelShader = compile PS2_EXT psDx9_SpotLightNV40();
	}
}


technique SpotLightShadow <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
		
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 1;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_SpotLight();
		PixelShader = compile PS2_EXT psDx9_SpotLightShadow();
	}
}

technique SpotLightShadowNV40 <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
		
		AlphaBlendEnable = FALSE;

		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 1;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_SpotLight();
		PixelShader = compile PS2_EXT psDx9_SpotLightShadowNV40();
	}
}

technique SpotProjector <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
//		CullMode = NONE;
//ZFunc = LESSEQUAL;
//CullMode = NONE;
		
		AlphaBlendEnable = FALSE;
//		StencilEnable = FALSE;
	
		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 1;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
	
		VertexShader = compile vs_1_1 vsDx9_SpotProjector();
		PixelShader = compile PS2_EXT psDx9_SpotProjector();
	}
}

technique SpotProjectorNV40 <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
//		CullMode = NONE;
//ZFunc = LESSEQUAL;
//CullMode = NONE;
		
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		BlendOp = MAX;
//		StencilEnable = FALSE;
	
		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 1;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
	
		VertexShader = compile vs_1_1 vsDx9_SpotProjector();
		PixelShader = compile PS2_EXT psDx9_SpotProjectorNV40();
	}
}

technique SpotProjectorShadowNV <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
//ZFunc = LESSEQUAL;
//CullMode = NONE;
		
		AlphaBlendEnable = FALSE;
//		StencilEnable = FALSE;
	
		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 1;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
	
		VertexShader = compile vs_1_1 vsDx9_SpotProjector();
		PixelShader = compile PS2_EXT psDx9_SpotProjectorShadowNV();
	}
}

technique SpotProjectorShadow <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
//ZFunc = LESSEQUAL;
//CullMode = NONE;
		
		AlphaBlendEnable = FALSE;
//		StencilEnable = FALSE;
	
		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 1;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
	
		VertexShader = compile vs_1_1 vsDx9_SpotProjector();
		PixelShader = compile PS2_EXT psDx9_SpotProjectorShadow();
	}
}

technique SpotProjectorShadowNV40 <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass p0
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
//ZFunc = LESSEQUAL;
//CullMode = NONE;
		
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;
		BlendOp = MAX;		
	
		StencilEnable = TRUE;
		StencilFunc = NOTEQUAL;
		StencilRef = 1;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
	
		VertexShader = compile vs_1_1 vsDx9_SpotProjector();
		PixelShader = compile PS2_EXT psDx9_SpotProjectorShadowNV40();
	}
}

technique BlitBackLightContrib <
	int Declaration[] = 
	{
		// StreamNo, DataType, Usage, UsageIdx
		0, D3DDECLTYPE_FLOAT3, D3DDECLUSAGE_POSITION, 0,
		DECLARATION_END	// End macro
	};
>
{
	pass point
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
		
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		
		VertexShader = compile vs_1_1 vsDx9_BlitBackLightContribPoint();
		PixelShader = compile PS2_EXT psDx9_BlitBackLightContrib();
	}

	pass spot
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
		
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		
		VertexShader = compile vs_1_1 vsDx9_BlitBackLightContribSpot();
		PixelShader = compile PS2_EXT psDx9_BlitBackLightContrib();
	}

	pass spotprojector
	{
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		ZFunc = GREATER;
		CullMode = NONE;
//ZFunc = LESSEQUAL;
//CullMode = NONE;
		
		AlphaBlendEnable = FALSE;
		StencilEnable = FALSE;
		
		VertexShader = compile vs_1_1 vsDx9_BlitBackLightContribSpotProjector();
		PixelShader = compile PS2_EXT psDx9_BlitBackLightContrib();
	}
}

technique Combine
{
	pass opaque
	{
		ZEnable = FALSE;
		AlphaBlendEnable = FALSE;

		StencilEnable = FALSE;
		
		VertexShader = compile vs_1_1 vsDx9_Combine();
		PixelShader = compile PS2_EXT psDx9_Combine();
	}
	
	pass transparent
	{
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
//		DestBlend = DESTALPHA;
		DestBlend = INVSRCALPHA;

		StencilEnable = TRUE;
		StencilFunc = EQUAL;
		StencilRef = 3;
		StencilFail = KEEP;
		StencilZFail = KEEP;
		StencilPass = KEEP;
		
		VertexShader = compile vs_1_1 vsDx9_Combine();
		PixelShader = compile PS2_EXT psDx9_CombineTransparent();
	}
}
