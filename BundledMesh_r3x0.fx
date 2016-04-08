
struct OUT_vsDiffuseZ 
{
	vec4 HPos			: POSITION;
	vec2 TexCoord		: TEXCOORD0;
};

struct OUT_vsFullMRT {
	vec4 HPos			: POSITION;
	vec2 TexCoord			: TEXCOORD0;
	vec3 Mat1			: TEXCOORD1;
	vec3 Mat2			: TEXCOORD2;
	vec3 Mat3			: TEXCOORD3;
	vec3 GroundUVAndLerp		: TEXCOORD4;
    	vec4 wPos			: TEXCOORD5;
};

struct OUT_vsFullMRTAnimatedUV {
	vec4 HPos			: POSITION;
	vec2 TexCoord1		: TEXCOORD0;
	vec3 Mat1			: TEXCOORD1;
	vec3 Mat2			: TEXCOORD2;
	vec3 Mat3			: TEXCOORD3;
	vec3 GroundUVAndLerp		: TEXCOORD4;
   	vec4 wPos			: TEXCOORD5;
	vec2 TexCoord2		: TEXCOORD6;
};

struct PS2FB_diffuseZ
{
	vec4	Color		: COLOR0;
};

struct PS2FB_fullMRT
{
    vec4	Col0 		: COLOR0;
    vec4	Col1 		: COLOR1;
    vec4	Col2 		: COLOR2;
    //vec4	Col3 		: COLOR3;
};

struct VS_OUTPUT_AlphaDX9 {
	vec4 HPos	: POSITION;
	vec4 Tex0	: TEXCOORD0;
	vec4 Tex1	: TEXCOORD1;
	vec4 wPos	: TEXCOORD2;
};

// [mharris]
OUT_vsDiffuseZ vsDiffuseZ
(
	appdataDiffuseZ input,
	uniform mat4x4 ViewProj
)
{
	OUT_vsDiffuseZ Out;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;
 
	vec3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
	Out.HPos = mul(vec4(Pos.xyz, 1.0), ViewProj);
	// Pass-through texcoords
	Out.TexCoord = input.TexCoord;
	return Out;
}

// [mharris]
OUT_vsDiffuseZ vsDiffuseZAnimatedUV
(
	appdataDiffuseZAnimatedUV input,
	uniform mat4x4 ViewProj
)
{
	OUT_vsDiffuseZ Out;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;
 
	vec3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
	Out.HPos = mul(vec4(Pos.xyz, 1.0), ViewProj);

	// Pass-through texcoords
//	Out.TexCoord = input.TexCoord;
	
	mat3x3 tmp = uvMatrix[IndexArray[3]];
	Out.TexCoord = mul(vec3(input.TexCoord1, 1.0), tmp).xy + input.TexCoord0;
	return Out;
}

OUT_vsFullMRT vsFullMRT
(
	appdata input,
	uniform mat4x4 ViewProj,
	uniform mat4x4 ViewInv,
	uniform scalar NormalOffsetScale
)
{
	OUT_vsFullMRT Out = (OUT_vsFullMRT)0;
   	   	
   	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;
 
 	vec3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
 	Out.HPos = mul(vec4(Pos.xyz, 1.0), ViewProj);
 	Out.wPos = mul(vec4(Pos.xyz, 1.0), viewMatrix);

 	// Hemi lookup values
 	vec3 AlmostNormal = mul(input.Normal, mOneBoneSkinning[IndexArray[0]]);
 	Out.GroundUVAndLerp.xy = (Pos +(hemiMapInfo.z/2) + AlmostNormal*1).xz / hemiMapInfo.z;
	Out.GroundUVAndLerp.y = 1-Out.GroundUVAndLerp.y;
 	Out.GroundUVAndLerp.z = (AlmostNormal.y+1)/2;
 	Out.GroundUVAndLerp.z -= hemiMapInfo.w;
 	 	
	// Cross product to create BiNormal
	vec3 binormal = normalize(cross(input.Tan, input.Normal));
	
	// Calculate tangent->view space transformation
	mat3x3 tanBasis = mat3x3(input.Tan, binormal, input.Normal);
	mat3x3 tanToView = transpose(mul(mul(tanBasis, mOneBoneSkinning[IndexArray[0]]), viewITMatrix));
	Out.Mat1 = tanToView[0];
	Out.Mat2 = tanToView[1];
	Out.Mat3 = tanToView[2];

	// Pass-through texcoords
	Out.TexCoord = input.TexCoord;
	
	return Out;
}

OUT_vsFullMRTAnimatedUV vsFullMRTAnimatedUV
(
	appdataAnimatedUV input,
	uniform mat4x4 ViewProj,
	uniform mat4x4 ViewInv,
	uniform scalar NormalOffsetScale
)
{
	OUT_vsFullMRTAnimatedUV Out = (OUT_vsFullMRTAnimatedUV)0;
   	   	
   	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;

	// Transform texcoords
//	Out.TexCoord = uvMatrix[IndexArray[3]].xy + input.TexCoord0;
	mat3x3 tmp = uvMatrix[IndexArray[3]];
	Out.TexCoord1 = mul(vec3(input.TexCoord1, 1.0), tmp).xy + input.TexCoord0;
//	Out.TexCoord = input.TexCoord0;
//	Out.TexCoord = vec2(0.0, 0.0);
//	Out.TexCoord = tmp2;
 
 	vec3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
 	Out.HPos = mul(vec4(Pos.xyz, 1.0), ViewProj);
 	Out.wPos = mul(vec4(Pos.xyz, 1.0), viewMatrix);
	
	//Out.wPos = Out.HPos;

 	// Hemi lookup values
 	vec3 AlmostNormal = mul(input.Normal, mOneBoneSkinning[IndexArray[0]]);
 	Out.GroundUVAndLerp.xy = (Pos +(hemiMapInfo.z/2) + AlmostNormal*1).xz / hemiMapInfo.z;
	Out.GroundUVAndLerp.y = 1-Out.GroundUVAndLerp.y;
 	Out.GroundUVAndLerp.z = (AlmostNormal.y+1)/2;
 	Out.GroundUVAndLerp.z -= hemiMapInfo.w;
 	 	
	// Cross product to create BiNormal
	vec3 binormal = normalize(cross(input.Tan, input.Normal));
	
	// Calculate tangent->view space transformation
	mat3x3 tanBasis = mat3x3(input.Tan, binormal, input.Normal);
	mat3x3 tanToView = transpose(mul(mul(tanBasis, mOneBoneSkinning[IndexArray[0]]), viewITMatrix));
	Out.Mat1 = tanToView[0];
	Out.Mat2 = tanToView[1];
	Out.Mat3 = tanToView[2];

	Out.TexCoord2 = input.TexCoord0;
	
	return Out;
}

VS_OUTPUT_AlphaDX9 vsAlphaDX9DirectionalShadow(appdata input, uniform mat4x4 ViewProj)
{
	VS_OUTPUT_AlphaDX9 Out;
   	   	
   	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(input.BlendIndices);
	int IndexArray[4] = (int[4])IndexVector;
 
 	vec3 Pos = mul(input.Pos, mOneBoneSkinning[IndexArray[0]]);
 	Out.HPos = mul(vec4(Pos.xyz, 1.0), ViewProj);
 	Out.wPos = mul(vec4(Pos.xyz, 1.0), viewMatrix);
	Out.Tex0 = vec4(input.TexCoord.xy, 1.0, 1.0);

	/*Out.Tex1.xy = Out.HPos.xy/Out.HPos.w;
 	Out.Tex1.xy = (Out.Tex1.xy + 1) / 2;
 	Out.Tex1.y = 1-Out.Tex1.y;
 	*/
 // Hacked to only support 800/600
 	Out.Tex1.xy = Out.HPos.xy/Out.HPos.w;
 	Out.Tex1.xy = (Out.Tex1.xy * 0.5) + 0.5;
 	Out.Tex1.y = 1-Out.Tex1.y;
Out.Tex1.x += 0.000625;
Out.Tex1.y += 0.000833;
	Out.Tex1.xy = Out.Tex1.xy * Out.HPos.w;
	Out.Tex1.zw = Out.HPos.zw;
	
	
	return Out;
}

PS2FB_diffuseZ psDiffuseZ(OUT_vsDiffuseZ indata)
{
	PS2FB_diffuseZ outdata;
	outdata.Color = tex2D(sampler2Aniso, indata.TexCoord);
	return outdata;
}

PS2FB_fullMRT psFullMRT(	OUT_vsFullMRT indata,
					uniform vec4 SkyColor,
					uniform vec4 AmbientColor)
{
	PS2FB_fullMRT outdata;
	
	vec4 expandedNormal = tex2D(sampler0, indata.TexCoord);
	expandedNormal.xyz = (expandedNormal.xyz * 2) - 1;
	outdata.Col2.x = dot(expandedNormal, indata.Mat1);
	outdata.Col2.y = dot(expandedNormal, indata.Mat2);
	outdata.Col2.z = dot(expandedNormal, indata.Mat3);
	outdata.Col2.w = expandedNormal.a;

	vec4 groundcolor = tex2D(sampler1, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, SkyColor, indata.GroundUVAndLerp.z);
//	outdata.Col0 = groundcolor.a*groundcolor.a;
//	outdata.Col0 += AmbientColor*hemicolor;
outdata.Col0 = AmbientColor*hemicolor;

	outdata.Col1 = indata.wPos;

	//outdata.Col3 = tex2D(sampler2Aniso, indata.TexCoord);
	return outdata;
}

PS2FB_fullMRT psFullMRTAnimatedUV(	OUT_vsFullMRTAnimatedUV indata,
					uniform vec4 SkyColor,
					uniform vec4 AmbientColor)
{
	PS2FB_fullMRT outdata;
	
	vec4 expandedNormal = tex2D(sampler0, indata.TexCoord1);
	expandedNormal.xyz = (expandedNormal.xyz * 2) - 1;
	outdata.Col2.x = dot(expandedNormal, indata.Mat1);
	outdata.Col2.y = dot(expandedNormal, indata.Mat2);
	outdata.Col2.z = dot(expandedNormal, indata.Mat3);
	outdata.Col2.w = expandedNormal.a;

	vec4 groundcolor = tex2D(sampler1, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, SkyColor, indata.GroundUVAndLerp.z);
//	outdata.Col0 = groundcolor.a*groundcolor.a;
//	outdata.Col0 += AmbientColor*hemicolor;
outdata.Col0 = AmbientColor*hemicolor;

	outdata.Col1 = indata.wPos;

//	outdata.Col0 = float4(1,0,0,1);
	//outdata.Col3 = tex2D(sampler2Aniso, indata.TexCoord1);
	return outdata;
}

PS2FB_fullMRT psFullMRTwGI(	OUT_vsFullMRT indata,
					uniform vec4 SkyColor,
					uniform vec4 AmbientColor)
{
	PS2FB_fullMRT outdata;
	
	vec4 expandedNormal = tex2D(sampler0, indata.TexCoord);
	expandedNormal.xyz = (expandedNormal.xyz * 2) - 1;
	outdata.Col2.x = dot(expandedNormal, indata.Mat1);
	outdata.Col2.y = dot(expandedNormal, indata.Mat2);
	outdata.Col2.z = dot(expandedNormal, indata.Mat3);
	outdata.Col2.w = expandedNormal.a;

	vec4 groundcolor = tex2D(sampler1, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, SkyColor, indata.GroundUVAndLerp.z);
//	outdata.Col0 = groundcolor.a*groundcolor.a;
//	outdata.Col0 += AmbientColor*hemicolor;
outdata.Col0 = AmbientColor*hemicolor;
	outdata.Col0 *= tex2D(sampler3, indata.TexCoord);

	outdata.Col1 = indata.wPos;

	//outdata.Col3 = tex2D(sampler2Aniso, indata.TexCoord);
	return outdata;
}

PS2FB_fullMRT psFullMRTwGIAnimatedUV(	OUT_vsFullMRTAnimatedUV indata,
					uniform vec4 SkyColor,
					uniform vec4 AmbientColor)
{
	PS2FB_fullMRT outdata;
	
	vec4 expandedNormal = tex2D(sampler0, indata.TexCoord1);
	expandedNormal.xyz = (expandedNormal.xyz * 2) - 1;
	outdata.Col2.x = dot(expandedNormal, indata.Mat1);
	outdata.Col2.y = dot(expandedNormal, indata.Mat2);
	outdata.Col2.z = dot(expandedNormal, indata.Mat3);
	outdata.Col2.w = expandedNormal.a;

	vec4 groundcolor = tex2D(sampler1, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, SkyColor, indata.GroundUVAndLerp.z);
//	outdata.Col0 = groundcolor.a*groundcolor.a;
//	outdata.Col0 += AmbientColor*hemicolor;
outdata.Col0 = AmbientColor*hemicolor;
	outdata.Col0 *= tex2D(sampler3, indata.TexCoord2);

	outdata.Col1 = indata.wPos;

	//outdata.Col3 = tex2D(sampler2Aniso, indata.TexCoord1);
	return outdata;
}

PS2FB_fullMRT psFullMRTHemiShadows(	OUT_vsFullMRT indata,
					uniform vec4 SkyColor,
					uniform vec4 AmbientColor)
{
	PS2FB_fullMRT outdata;
	
	vec4 expandedNormal = tex2D(sampler0, indata.TexCoord);
	expandedNormal.xyz = (expandedNormal.xyz * 2) - 1;
	outdata.Col2.x = dot(expandedNormal, indata.Mat1);
	outdata.Col2.y = dot(expandedNormal, indata.Mat2);
	outdata.Col2.z = dot(expandedNormal, indata.Mat3);
	outdata.Col2.w = expandedNormal.a;

	vec4 groundcolor = tex2D(sampler1, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, SkyColor, indata.GroundUVAndLerp.z);
	outdata.Col0 = AmbientColor*hemicolor;
	outdata.Col0 *= groundcolor.a*groundcolor.a;

	outdata.Col1 = indata.wPos;

	//outdata.Col3 = tex2D(sampler2, indata.TexCoord);
	return outdata;
}

PS2FB_fullMRT psFullMRTHemiShadowsAnimatedUV(	OUT_vsFullMRTAnimatedUV indata,
					uniform vec4 SkyColor,
					uniform vec4 AmbientColor)
{
	PS2FB_fullMRT outdata;
	
	vec4 expandedNormal = tex2D(sampler0, indata.TexCoord1);
	expandedNormal.xyz = (expandedNormal.xyz * 2) - 1;
	outdata.Col2.x = dot(expandedNormal, indata.Mat1);
	outdata.Col2.y = dot(expandedNormal, indata.Mat2);
	outdata.Col2.z = dot(expandedNormal, indata.Mat3);
	outdata.Col2.w = expandedNormal.a;

	vec4 groundcolor = tex2D(sampler1, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, SkyColor, indata.GroundUVAndLerp.z);
	outdata.Col0 = AmbientColor*hemicolor;
	outdata.Col0 *= groundcolor.a*groundcolor.a;

	outdata.Col1 = indata.wPos;

	//outdata.Col3 = tex2D(sampler2, indata.TexCoord1);
	return outdata;
}

PS2FB_fullMRT psFullMRTwGIHemiShadows(	OUT_vsFullMRT indata,
					uniform vec4 SkyColor,
					uniform vec4 AmbientColor)
{
	PS2FB_fullMRT outdata;
	
	vec4 expandedNormal = tex2D(sampler0, indata.TexCoord);
	expandedNormal.xyz = (expandedNormal.xyz * 2) - 1;
	outdata.Col2.x = dot(expandedNormal, indata.Mat1);
	outdata.Col2.y = dot(expandedNormal, indata.Mat2);
	outdata.Col2.z = dot(expandedNormal, indata.Mat3);
	outdata.Col2.w = expandedNormal.a;

	vec4 groundcolor = tex2D(sampler1, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, SkyColor, indata.GroundUVAndLerp.z);
	outdata.Col0 = AmbientColor*hemicolor;
	outdata.Col0 *= groundcolor.a*groundcolor.a;
	outdata.Col0 *= tex2D(sampler3, indata.TexCoord);


	outdata.Col1 = indata.wPos;

	//outdata.Col3 = tex2D(sampler2, indata.TexCoord);
	return outdata;
}

PS2FB_fullMRT psFullMRTwGIHemiShadowsAnimatedUV(	OUT_vsFullMRTAnimatedUV indata,
					uniform vec4 SkyColor,
					uniform vec4 AmbientColor)
{
	PS2FB_fullMRT outdata;
	
	vec4 expandedNormal = tex2D(sampler0, indata.TexCoord1);
	expandedNormal.xyz = (expandedNormal.xyz * 2) - 1;
	outdata.Col2.x = dot(expandedNormal, indata.Mat1);
	outdata.Col2.y = dot(expandedNormal, indata.Mat2);
	outdata.Col2.z = dot(expandedNormal, indata.Mat3);
	outdata.Col2.w = expandedNormal.a;

	vec4 groundcolor = tex2D(sampler1, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, SkyColor, indata.GroundUVAndLerp.z);
	outdata.Col0 = AmbientColor*hemicolor;
	outdata.Col0 *= groundcolor.a*groundcolor.a;
	outdata.Col0 *= tex2D(sampler3, indata.TexCoord2);

	outdata.Col1 = indata.wPos;

	//outdata.Col3 = tex2D(sampler2, indata.TexCoord1);
	return outdata;
}

PS2FB_fullMRT psFullMRTAlphaBlend(	OUT_vsFullMRT indata,
					uniform vec4 SkyColor,
					uniform vec4 AmbientColor)
{
	PS2FB_fullMRT outdata;
	
	vec4 expandedNormal = tex2D(sampler0, indata.TexCoord);
	expandedNormal.xyz = (expandedNormal.xyz * 2) - 1;
	outdata.Col2.x = dot(expandedNormal, indata.Mat1);
	outdata.Col2.y = dot(expandedNormal, indata.Mat2);
	outdata.Col2.z = dot(expandedNormal, indata.Mat3);
	outdata.Col2.w = expandedNormal.a;

	vec4 groundcolor = tex2D(sampler1, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, SkyColor, indata.GroundUVAndLerp.z);
	outdata.Col0 = groundcolor.a*groundcolor.a;
	outdata.Col0 += AmbientColor*hemicolor;
//outdata.Col0 = AmbientColor*hemicolor;

	outdata.Col1 = indata.wPos;

	//outdata.Col3 = tex2D(sampler2Aniso, indata.TexCoord);
	return outdata;
}

vec4 psAlphaDX9(VS_OUTPUT_Alpha indata) : COLOR
{
	vec4 diffuse = tex2D(sampler0, indata.DiffuseMap);
	vec4 projlight = tex2Dproj(sampler1, indata.Tex1);
	
	vec4 Output = diffuse * projlight + projlight.a;
	Output.a = diffuse.a;
	return Output;
}

vec4 psAlphaDX9DirectionalShadow(VS_OUTPUT_AlphaDX9 indata) : COLOR
{
	vec4 diffuse = tex2D(sampler0, indata.Tex0);
	vec4 projlight = tex2Dproj(sampler1, indata.Tex1);

	vec4 lightUV = mul(indata.wPos, mLightVP);
	lightUV.xy = clamp(lightUV.xy, vViewportMap.xy, vViewportMap.zw);
	
	scalar texel = 1.0 / 1024.0; // Fixme when shadowMap size isn't constant any more...
	vec4 samplesShadowMap;
	samplesShadowMap.x = tex2D(sampler2point, lightUV);
	samplesShadowMap.y = tex2D(sampler2point, lightUV + vec2(texel, 0));
	samplesShadowMap.z = tex2D(sampler2point, lightUV + vec2(0, texel));
	samplesShadowMap.w = tex2D(sampler2point, lightUV + vec2(texel, texel));

	vec4 staticOccluderSamples;
	staticOccluderSamples.x = tex2D(sampler3, lightUV + vec2(-texel*1, -texel*2)).b;
	staticOccluderSamples.y = tex2D(sampler3, lightUV + vec2( texel*1, -texel*2)).b;
	staticOccluderSamples.z = tex2D(sampler3, lightUV + vec2(-texel*1,  texel*2)).b;
	//staticSamples.w = tex2D(sampler4bilin, lightUV + vec2( texel*1,  texel*2)).b;
	staticOccluderSamples.x = dot(staticOccluderSamples.xyz, 0.33);
		
	const scalar epsilon = 0.05;
	vec4 cmpbits = (samplesShadowMap.xyzw + epsilon) >= saturate(lightUV.zzzz);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25)) * staticOccluderSamples.x;
	
	vec4 Output = diffuse * projlight * avgShadowValue + projlight.a * avgShadowValue;
	Output.a = diffuse.a;
	return Output;
}

vec4 psAlphaDX9DirectionalDecal(VS_OUTPUT_Alpha indata) : COLOR
{
	vec4 diffuse = tex2D(sampler0, indata.DiffuseMap);
	vec4 projlight = tex2Dproj(sampler1, indata.Tex1);
	vec4 diffuseLight = tex2Dproj(sampler2, indata.Tex1);
	vec4 lightMapAmbient = tex2Dproj(sampler3, indata.Tex1);
	
	vec4 Output = (diffuse * ((projlight+lightMapAmbient) * (diffuseLight+lightMapAmbient))) + projlight.a;
	Output.a = diffuse.a;
	return Output;

}

// [mharris]
technique DiffuseZ
{
	pass p0
	{
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = TRUE;

		StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;
	
 		VertexShader = compile vs_1_1 vsDiffuseZ(viewProjMatrix);
		PixelShader = compile PS2_EXT psDiffuseZ();	
	}
	
	pass p1 // Animated UV
	{
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
		ZWriteEnable = TRUE;

		StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;
	
 		VertexShader = compile vs_1_1 vsDiffuseZAnimatedUV(viewProjMatrix);
		PixelShader = compile PS2_EXT psDiffuseZ();	
	}
}

technique FullMRT
{
	pass p0
	{	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = EQUAL;
		ZWriteEnable = FALSE;

		StencilEnable = FALSE;
		/*StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;*/
	
 		VertexShader = compile vs_1_1 vsFullMRT(viewProjMatrix, viewInverseMatrix,  normalOffsetScale);
		PixelShader = compile PS2_EXT psFullMRT(skyColor, ambientColor);	
	}
	pass p1wGI
	{	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = EQUAL;
		ZWriteEnable = FALSE;


		StencilEnable = FALSE;
		/*StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;*/
	
 		VertexShader = compile vs_1_1 vsFullMRT(viewProjMatrix, viewInverseMatrix, normalOffsetScale);
		PixelShader = compile PS2_EXT psFullMRTwGI(skyColor, ambientColor);	
	}
}

technique FullMRTHemiShadows
{
	pass p0
	{	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = EQUAL;
		ZWriteEnable = FALSE;

		StencilEnable = FALSE;
		/*StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;*/
	
 		VertexShader = compile vs_1_1 vsFullMRT(viewProjMatrix, viewInverseMatrix, normalOffsetScale);
		PixelShader = compile PS2_EXT psFullMRTHemiShadows(skyColor, ambientColor);	
	}
	pass p1wGI
	{	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = EQUAL;
		ZWriteEnable = FALSE;

		/*StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;*/
	
 		VertexShader = compile vs_1_1 vsFullMRT(viewProjMatrix, viewInverseMatrix, normalOffsetScale);
		PixelShader = compile PS2_EXT psFullMRTwGIHemiShadows(skyColor, ambientColor);	
	}
}

technique FullMRTAnimatedUV
{
	pass p0
	{	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = EQUAL;
		ZWriteEnable = FALSE;


		StencilEnable = FALSE;	
		/*StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;*/
	
 		VertexShader = compile vs_1_1 vsFullMRTAnimatedUV(viewProjMatrix, viewInverseMatrix, normalOffsetScale);
		PixelShader = compile PS2_EXT psFullMRTAnimatedUV(skyColor, ambientColor);	
	}
	pass p1wGI
	{	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = EQUAL;
		ZWriteEnable = FALSE;

		StencilEnable = FALSE;
		/*StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;*/
	
 		VertexShader = compile vs_1_1 vsFullMRTAnimatedUV(viewProjMatrix, viewInverseMatrix, normalOffsetScale);
		PixelShader = compile PS2_EXT psFullMRTwGIAnimatedUV(skyColor, ambientColor);	
	}
}

technique FullMRTAnimatedUVHemiShadows
{
	pass p0
	{	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = EQUAL;
		ZWriteEnable = FALSE;

		StencilEnable = FALSE;
		/*StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;*/
	
 		VertexShader = compile vs_1_1 vsFullMRTAnimatedUV(viewProjMatrix, viewInverseMatrix, normalOffsetScale);
		PixelShader = compile PS2_EXT psFullMRTHemiShadowsAnimatedUV(skyColor, ambientColor);	
	}
	pass p1wGI
	{	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = EQUAL;
		ZWriteEnable = FALSE;

		StencilEnable = FALSE;
		/*StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;*/
	
 		VertexShader = compile vs_1_1 vsFullMRTAnimatedUV(viewProjMatrix, viewInverseMatrix, normalOffsetScale);
		PixelShader = compile PS2_EXT psFullMRTwGIHemiShadowsAnimatedUV(skyColor, ambientColor);	
	}
}

technique FullMRTAlphaBlend
{
	pass p0
	{	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZFunc = LESSEQUAL;
//		ZWriteEnable = TRUE;
		ZWriteEnable = FALSE;
		CullMode = NONE;

		StencilEnable = FALSE;
		/*StencilEnable = TRUE;
		StencilRef = 3;
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;*/
	
 		VertexShader = compile vs_1_1 vsFullMRT(viewProjMatrix, viewInverseMatrix, normalOffsetScale);
		PixelShader = compile PS2_EXT psFullMRTAlphaBlend(skyColor, ambientColor);	
	}
}


technique alphaDX9
{
	pass p0 
	{		
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;

		VertexShader = compile vs_1_1 vsAlpha(viewProjMatrix);
		PixelShader = compile PS2_EXT psAlphaDX9();
	}
}

technique alphaDX9DirectionalShadow
{
	pass p0 
	{		
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;

		VertexShader = compile vs_1_1 vsAlphaDX9DirectionalShadow(viewProjMatrix);
		PixelShader = compile PS2_EXT psAlphaDX9DirectionalShadow();
	}
}

technique alphaDX9DirectionalDecal
{
	pass p0 
	{		
		ZEnable = TRUE;
		ZWriteEnable = FALSE;
		CullMode = NONE;
		AlphaBlendEnable = TRUE;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
		AlphaFunc = GREATER;

		VertexShader = compile vs_1_1 vsAlpha(viewProjMatrix);
		PixelShader = compile PS2_EXT psAlphaDX9DirectionalDecal();
	}
}
