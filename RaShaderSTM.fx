//#define _FORCE_1_4_SHADERS_ 1

#if _FORCE_1_4_SHADERS_ || _FORCE_1_3_SHADERS_
	//#include "shaders/STM1_4.fx"

	// 1_4 settings
	// remove features
	#define _CRACK_ 		0
	#define  _PARALLAXDETAIL_ 	0
	#define  _NBASE_		0
	#define  _NDETAIL_		0
	#define  _CRACK_		0
	#define  _NCRACK_		0
	#define  _SHADOW_		0
	#define _USESPECULAR_ 		0
	#define _USEPERPIXELNORMALIZE_	0
#else
	// Quality settings.
	#if RAPATH <= 1
		#define _USEPERPIXELNORMALIZE_ 		1
	#else
		#define _USEPERPIXELNORMALIZE_ 		0
	#endif
	
	// if we want to run the same path on 1_4 we should disable this.
	#define _USERENORMALIZEDTEXTURES_ 	1
	#define _USESPECULAR_  1
	//#define USEVERTEXSPECULAR 1
#endif

#include "shaders/RaCommon.fx"
#include "shaders/RaShaderSTMCommon.fx"

#define skyNormal 	vec3(0.78,0.52,0.65)


//tl: Alias packed data indices to regular indices:
#ifdef TexBasePackedInd
	#define TexBaseInd	TexBasePackedInd
#endif
#ifdef TexDetailPackedInd
	#define TexDetailInd	TexDetailPackedInd
#endif
#ifdef TexDirtPackedInd
	#define TexDirtInd	TexDirtPackedInd
#endif
#ifdef TexCrackPackedInd
	#define TexCrackInd	TexCrackPackedInd
#endif
#ifdef TexLightMapPackedInd
	#define TexLightMapInd	TexLightMapPackedInd
#endif

#if ( _NBASE_||_NDETAIL_ || _NCRACK_ || _PARALLAXDETAIL_)
	#define PERPIXEL
#else
	#define _CRACK_  0 // We do not allow crack if we run on the non per pixel path.
#endif

#define MPSMODEL PSMODEL

struct VS_IN
{
	vec4 Pos					: POSITION;
	vec3 Normal					: NORMAL;
	vec3 Tan					: TANGENT;
	vec4 TexSets[NUM_TEXSETS]			: TEXCOORD0;
};

//
// setup interpolators
//
#ifdef PERPIXEL
	#define __LVEC_INTER 0
	#define __EYEVEC_INTER 1
	#define __TEXBASE_INTER 2
#else
	#define __LVEC_INTER 0
	#define __EYEVEC_INTER 1
	//#define __NORMAL_INTER 2
	#define __TEXBASE_INTER 2
#endif


	#define __TEXLMAP_INTER __TEXBASE_INTER + _LIGHTMAP_
#if	(_DETAIL_||_NDETAIL_||_PARALLAXDETAIL_)
	#define __TEXDETAIL_INTER __TEXLMAP_INTER + 1
#else
	#define __TEXDETAIL_INTER __TEXLMAP_INTER
#endif

#if	_SHADOW_
	#define __TEXSHADOW_INTER __TEXDETAIL_INTER+1
#else
	#define __TEXSHADOW_INTER __TEXDETAIL_INTER
#endif

#if	_DIRT_
	#define __TEXDIRT_INTER __TEXSHADOW_INTER + 1
#else
	#define __TEXDIRT_INTER __TEXSHADOW_INTER
#endif

#if	(_CRACK_||_NCRACK_)
	#define __TEXCRACK_INTER __TEXDIRT_INTER+1
#else
	#define __TEXCRACK_INTER __TEXDIRT_INTER
#endif

#define MAX_INTERPS __TEXCRACK_INTER + 1

struct VS_OUT
{
	vec4 Pos					: POSITION0;
	vec4 InvDotAndLightAtt				: COLOR0;
	vec4 ColorOrPointLightFog			: COLOR1;
	vec4 Interpolated[MAX_INTERPS]			: TEXCOORD0;
	
	scalar Fog					: FOG;
};

// common vars
Light		Lights[NUM_LIGHTS];

float getBinormalFlipping(VS_IN input)
{
	return 1.f + input.Pos.w * -2.f;
}

mat3x3 getTanBasisTranspose(VS_IN input, vec3 Normal, vec3 Tan)
{
	// Cross product to create BiNormal
	float flip = getBinormalFlipping(input);
	vec3 binormal = normalize(cross(Tan, Normal)) * flip;
	
	// calculate the objI
	return transpose(mat3x3(Tan, binormal, Normal));
}

vec3 getVectorTo(vec3 vertexPos, vec3 camPos)
{
	return camPos - vertexPos;
}

//
// common vertex shader methods
//
VS_OUT 
vsStaticMesh(VS_IN indata)
{
	VS_OUT Out = (VS_OUT)0;
 
 	// output position early
 	vec4 unpackedPos = float4(indata.Pos.xyz,1) * PosUnpack;
 	Out.Pos	= mul(unpackedPos, WorldViewProjection);
	vec3 unpackedNormal = indata.Normal * NormalUnpack.x + NormalUnpack.y;
	#if _POINTLIGHT_
		vec3 unpackedTan = indata.Tan * NormalUnpack.x + NormalUnpack.y;
		mat3x3 objI = getTanBasisTranspose(indata, unpackedNormal, unpackedTan);
	
		Out.Interpolated[__EYEVEC_INTER].rgb = mul(getVectorTo(unpackedPos, ObjectSpaceCamPos), objI);
		Out.Interpolated[__LVEC_INTER].rgb = mul(getVectorTo(unpackedPos, Lights[0].pos), objI);

		// Transform eye pos to tangent space	
		#if (!_USEPERPIXELNORMALIZE_)
			Out.Interpolated[__EYEVEC_INTER].rgb = normalize(Out.Interpolated[__EYEVEC_INTER].rgb);
		#endif
	
		Out.InvDotAndLightAtt.b = Lights[0].attenuation;						
	#else
		#ifdef PERPIXEL
			vec3 unpackedTan = indata.Tan * NormalUnpack.x + NormalUnpack.y;
			mat3x3 objI = getTanBasisTranspose(indata, unpackedNormal, unpackedTan);
		
			Out.Interpolated[__EYEVEC_INTER].rgb = mul(getVectorTo(unpackedPos, ObjectSpaceCamPos), objI);
			Out.Interpolated[__LVEC_INTER].rgb = mul(-Lights[0].dir, objI);
			
			// Transform eye pos to tangent space	
			#if (!_USEPERPIXELNORMALIZE_)
				Out.Interpolated[__EYEVEC_INTER].rgb = normalize(Out.Interpolated[__EYEVEC_INTER].rgb);
				Out.Interpolated[__LVEC_INTER].rgb = normalize(Out.Interpolated[__LVEC_INTER].rgb);
			#endif
		
			Out.InvDotAndLightAtt.a = 1-(saturate(dot(unpackedNormal*0.2, -Lights[0].dir)));
			Out.InvDotAndLightAtt.b = Lights[0].attenuation;
		#else

			#ifdef USEVERTEXSPECULAR
				scalar ndotl = dot(-Lights[0].dir, unpackedNormal);
				scalar vdotr = dot(reflect(Lights[0].dir, unpackedNormal), normalize(getVectorTo(unpackedPos, ObjectSpaceCamPos)));
				vec4 lighting = lit(ndotl, vdotr, 32);
				//Out.Interpolated[__NORMAL_INTER].rgb = lighting.z * CEXP(StaticSpecularColor);	
			#else
				vec3 unpackedTan = indata.Tan * NormalUnpack.x + NormalUnpack.y;
				mat3x3 objI = getTanBasisTranspose(indata, unpackedNormal, unpackedTan);
			
				Out.Interpolated[__EYEVEC_INTER].rgb = mul(getVectorTo(unpackedPos, ObjectSpaceCamPos), objI);
				Out.Interpolated[__LVEC_INTER].rgb = mul(-Lights[0].dir, objI);

				//Out.Interpolated[__EYEVEC_INTER].rgb = getVectorTo(unpackedPos, ObjectSpaceCamPos);
				//Out.Interpolated[__LVEC_INTER].rgb = -Lights[0].dir;
				#if (!_USEPERPIXELNORMALIZE_)
					Out.Interpolated[__EYEVEC_INTER].rgb = normalize(Out.Interpolated[__EYEVEC_INTER].rgb);
					Out.Interpolated[__LVEC_INTER].rgb = normalize(Out.Interpolated[__LVEC_INTER].rgb);
				#endif
				
			#endif
						
			scalar invDot = 1-saturate(dot(unpackedNormal*0.2, -Lights[0].dir));
			Out.InvDotAndLightAtt.rgb = skyNormal.z * CEXP(StaticSkyColor) * invDot;
			Out.ColorOrPointLightFog.rgb =  saturate(dot(unpackedNormal, -Lights[0].dir))*CEXP(Lights[0].color);
		#endif
	#endif
	
	#if	_LIGHTMAP_
		 Out.Interpolated[__TEXLMAP_INTER].xy =  indata.TexSets[TexLightMapInd].xy * TexUnpack * LightMapOffset.xy + LightMapOffset.zw;
	#endif
	
	#if	_BASE_
		Out.Interpolated[__TEXBASE_INTER].xy = indata.TexSets[TexBaseInd].xy * TexUnpack;
	#endif
	
	#if (_DETAIL_ || _NDETAIL_)
		Out.Interpolated[__TEXDETAIL_INTER].xy = indata.TexSets[TexDetailInd].xy * TexUnpack;
	#endif
	
	#if _DIRT_
		Out.Interpolated[__TEXDIRT_INTER].xy = indata.TexSets[TexDirtInd].xy * TexUnpack;
	#endif
	
	#if _CRACK_
		Out.Interpolated[__TEXCRACK_INTER].xy = indata.TexSets[TexCrackInd].xy * TexUnpack;
	#endif 
	
	#if _SHADOW_
		Out.Interpolated[__TEXSHADOW_INTER] = calcShadowProjectionExact(unpackedPos);
	#endif
	 
	 #if _POINTLIGHT_
		Out.ColorOrPointLightFog.a = calcFog(Out.Pos.w);
	#else
		Out.Fog = calcFog(Out.Pos.w);
	#endif

	return Out;
}

#if _PARALLAXDETAIL_
float2 
calculateParallaxCoordinatesFromAlpha(vec2 inHeightTexCoords, sampler2D inHeightSampler, vec4 inScaleBias, vec3 inEyeVecNormalized)
{
	vec2 height = tex2D(inHeightSampler, inHeightTexCoords).aa;
	float2 eyeVecN = inEyeVecNormalized.xy * vec2(1,-1);
	vec4 fakeBias = vec4(FH2_HARDCODED_PARALLAX_BIAS, FH2_HARDCODED_PARALLAX_BIAS, 0.0, 0.0);
	height = height * fakeBias.xy + fakeBias.wz;
	return inHeightTexCoords + height * eyeVecN.xy;
}
#endif


vec4 
getCompositeDiffuse(VS_OUT indata, vec3 normTanEyeVec, out scalar gloss)
{
	//vec4 base, detail, dirt, crack;
	vec4 totalDiffuse = 0;
	gloss = StaticGloss;
	
#if _BASE_
	totalDiffuse = tex2D(DiffuseMapSampler, indata.Interpolated[__TEXBASE_INTER].xy);
#endif

#if _PARALLAXDETAIL_
	vec4 detail = tex2D(DetailMapSampler, calculateParallaxCoordinatesFromAlpha(indata.Interpolated[__TEXDETAIL_INTER].xy, NormalMapSampler, ParallaxScaleBias, normTanEyeVec));
#elif _DETAIL_
	vec4 detail = tex2D(DetailMapSampler, indata.Interpolated[__TEXDETAIL_INTER].xy);
#endif

#if (_DETAIL_|| _PARALLAXDETAIL_)
	//tl: assumes base has .a = 1 (which should be the case)
//	totalDiffuse.rgb *= detail.rgb;
	totalDiffuse *= detail;
	#if (!_ALPHATEST_)
		gloss = detail.a;
		totalDiffuse.a = Transparency.a;
	#else
		totalDiffuse.a *= Transparency.a;
	#endif
#else
	totalDiffuse.a *= Transparency.a;
#endif		

#if _DIRT_
	totalDiffuse.rgb *= tex2D(DirtMapSampler, indata.Interpolated[__TEXDIRT_INTER].xy).rgb;
#endif
		
#if _CRACK_
	vec4 crack = tex2D(CrackMapSampler, indata.Interpolated[__TEXCRACK_INTER].xy);
	totalDiffuse.rgb = lerp(totalDiffuse.rgb, crack.rgb, crack.a);
#endif
	
	return totalDiffuse;
}

vec3 reNormalize(vec3 t)
{
	return normalize(t);
	//vec3 tempVec = t;
	//return (tempVec * (1 - saturate(dot(tempVec, tempVec))) + tempVec * 2)/2;
	
	//vec3 tempVec = 0.5*(t);
	//return (tempVec * (1 - saturate(dot(tempVec, tempVec))) + tempVec * 2)/2;
	
}

// This also includes the composite gloss map
vec3 
getCompositeNormals(VS_OUT indata, vec3 normTanEyeVec)
{
	vec3 totalNormal = 0;
	
	#if	_NBASE_
		totalNormal = tex2D(NormalMapSampler, indata.Interpolated[__TEXBASE_INTER].xy);
	#endif

	#if _PARALLAXDETAIL_
		totalNormal = tex2D(NormalMapSampler, calculateParallaxCoordinatesFromAlpha(indata.Interpolated[__TEXDETAIL_INTER].xy, NormalMapSampler, ParallaxScaleBias, normTanEyeVec));
	#elif _NDETAIL_
		totalNormal = tex2D(NormalMapSampler, indata.Interpolated[__TEXDETAIL_INTER].xy);
	#endif

	#if _NCRACK_
		vec4 cracknormal = tex2D(CrackNormalMapSampler, indata.Interpolated[__TEXCRACK_INTER].xy);
		scalar crackmask = tex2D(CrackMapSampler, indata.Interpolated[__TEXCRACK_INTER].xy).a;
		totalNormal = lerp(totalNormal, cracknormal.rgb, crackmask);
	#endif

	#if _USERENORMALIZEDTEXTURES_
		totalNormal.xyz = normalize(totalNormal.xyz * 2 - 1);
	#else
		totalNormal.xyz = totalNormal.xyz * 2 - 1;
	#endif

	return totalNormal;
}


vec3 
getLightmap(VS_OUT indata)
{
	#if _LIGHTMAP_
		return  tex2D(LightMapSampler, indata.Interpolated[__TEXLMAP_INTER].xy);
	#else
		return vec3(1,1,1);
	#endif
}

vec3 
getDiffuseVertexLighting(vec3 lightmap, VS_OUT indata)
{
#if 	_LIGHTMAP_
	vec3 diffuse = indata.ColorOrPointLightFog.rgb;
	vec3 bumpedSky = lightmap.b * indata.InvDotAndLightAtt.rgb;
	
	// we add ambient here as well to get correct ambient for surfaces parallel to the sun
	vec3 bumpedDiff = diffuse + bumpedSky;
	diffuse = lerp(bumpedSky, bumpedDiff, lightmap.g);
	diffuse += lightmap.r * SinglePointColor;
	
#else
	vec3 diffuse =	indata.ColorOrPointLightFog.rgb;
	vec3 bumpedSky = indata.InvDotAndLightAtt.rgb;

	diffuse *= lightmap.g;
	diffuse += bumpedSky;
#endif

	return diffuse;
}


vec3 
getDiffusePixelLighting(vec3 lightmap, vec3 compNormals, vec3 normalizedLightVec, VS_OUT indata)
{
	vec3 diffuse = saturate(dot(compNormals, normalizedLightVec)) * CEXP(Lights[0].color);
	//pre-calc: lightmap.b *= invDot
	vec3 bumpedSky = lightmap.b * dot(compNormals, skyNormal) * CEXP(StaticSkyColor);
	diffuse = bumpedSky + diffuse*lightmap.g;
	
	diffuse += lightmap.r * CEXP(SinglePointColor); //tl: Jonas, disable once we know which materials are actually affected.
	
	return diffuse;
}

scalar 
getSpecularPixelLighting(vec3 lightmap, vec3 compNormals, vec3 normalizedLightVec, vec3 eyeVec, scalar gloss)
{
	vec3 halfVec = normalize(normalizedLightVec + eyeVec);
	scalar specular = saturate(dot(compNormals.xyz, halfVec));

	// todo dep texlookup for spec
	specular = pow(specular, 32);
	
	// mask
	specular *= lightmap.g * gloss;
		
	return specular;
}


vec3
getPointPixelLighting(VS_OUT indata, vec3 compNormal, vec3 normLightVec, vec3 normEyeVec, scalar gloss)
{
	vec3 pointDiff = saturate(dot(compNormal.xyz, normLightVec)) * Lights[0].color;
	vec3 lightPos = indata.Interpolated[__LVEC_INTER].rgb;
	scalar sat = 1.0 - saturate(dot(lightPos, lightPos) * indata.InvDotAndLightAtt.b);

	#if _USESPECULAR_
		scalar specular = getSpecularPixelLighting(1, compNormal, normLightVec, normEyeVec, gloss);
		pointDiff += specular * CEXP(StaticSpecularColor);
	#endif

	return saturate(pointDiff * sat * indata.ColorOrPointLightFog.a);
}



vec4 
psStaticMesh(VS_OUT indata) : COLOR
{
//scalar x = 0.5;
//return vec4(x,x,x,1);
//return 1;
#if _FINDSHADER_
	return vec4(1,1,0.4,1);
#endif

	scalar gloss;
	vec4 FinalColor;

#if _POINTLIGHT_
	#if _FORCE_1_4_SHADERS_
		// precaution.
		return 0;
	#endif
	vec3 normEyeVec = indata.Interpolated[__EYEVEC_INTER].rgb;
	vec3 normLightVec = indata.Interpolated[__LVEC_INTER].rgb;
	
	#if	_USEPERPIXELNORMALIZE_	
		normEyeVec = normalize(normEyeVec);
	#endif
	
	// here we must do it since we upload the unnormalized lightvec
	#if	_USEPERPIXELNORMALIZE_	
		normLightVec = normalize(normLightVec);
	#endif
	FinalColor = getCompositeDiffuse(indata, normEyeVec, gloss);
	
	#ifdef PERPIXEL
		vec3 compNormals = getCompositeNormals(indata, normEyeVec);
	#else
		vec3 compNormals = vec3(0,0,1);
	#endif
	
	vec3 diffuse = getPointPixelLighting(indata, compNormals, normLightVec, normEyeVec, gloss);
	
	FinalColor.rgb = 2*(FinalColor * diffuse);
	
	return FinalColor;
#else	//if _POINTLIGHT_

	#ifdef PERPIXEL
		vec3 normEyeVec = indata.Interpolated[__EYEVEC_INTER].rgb;
		#if	_USEPERPIXELNORMALIZE_	
			normEyeVec = normalize(normEyeVec);
		#endif
		
		vec3 normLightVec = indata.Interpolated[__LVEC_INTER].rgb;
		#if	_USEPERPIXELNORMALIZE_	
			normLightVec = normalize(normLightVec);
		#endif
			
		FinalColor = getCompositeDiffuse(indata, normEyeVec, gloss);
		
		#ifdef	DIFFUSE_CHANNEL
			return float4(FinalColor.rgb,1);
		#endif
		
		vec3 compNormals = getCompositeNormals(indata, normEyeVec);
		
		
		// directional light + lightmap etc	
		vec3 lightmap = getLightmap(indata);
		
		#if _SHADOW_
			lightmap.g *= getShadowFactorExact(ShadowMapSampler, indata.Interpolated[__TEXSHADOW_INTER], 3);
		#endif
	
		vec3 diffuse = getDiffusePixelLighting(lightmap, compNormals.rgb, normLightVec, indata);
			
		#ifdef	SHADOW_CHANNEL		
			return float4(diffuse,1);
		#endif
		
		FinalColor.rgb *= 2 * diffuse;
		
		#if _USESPECULAR_
			scalar specular = getSpecularPixelLighting(lightmap, compNormals, normLightVec, normEyeVec, gloss);
			FinalColor.rgb += specular * CEXP(StaticSpecularColor);
		#endif
		
	#else //if PERPIXEL
	
		FinalColor = getCompositeDiffuse(indata, 0, gloss);

		#ifdef	DIFFUSE_CHANNEL
			return float4(FinalColor.rgb,1);
		#endif
		
		vec3 lightmap = getLightmap(indata);
	
		#if _SHADOW_
			lightmap.g *= getShadowFactor(ShadowMapSampler, indata.Interpolated[__TEXSHADOW_INTER], 3);		
		#endif

		vec3 diffuse = getDiffuseVertexLighting(lightmap, indata);

		#ifdef	SHADOW_CHANNEL		
			return float4(diffuse,1);
		#endif

		FinalColor.rgb *= 2 * diffuse;

#if !_FORCE_1_3_SHADERS_
		#if _USESPECULAR_
			#ifdef USEVERTEXSPECULAR			
				FinalColor.rgb += indata.Interpolated[__NORMAL_INTER].rgb;
			#else
				vec3 normEyeVec = indata.Interpolated[__EYEVEC_INTER].rgb;
				#if	_USEPERPIXELNORMALIZE_	
					normEyeVec = normalize(normEyeVec);
				#endif
				vec3 normLightVec = indata.Interpolated[__LVEC_INTER].rgb;
			
				//scalar specular = getSpecularPixelLighting(lightmap, vec4(normalize(indata.Interpolated[__NORMAL_INTER].rgb), StaticGloss), normLightVec, normEyeVec);
				scalar specular = getSpecularPixelLighting(lightmap, vec4(0.f,0.f,1.f, StaticGloss), normLightVec, normEyeVec, gloss);
				FinalColor.rgb += specular * CEXP(StaticSpecularColor);
			#endif
		#endif //if _USESPECULAR_
	#endif //if PERPIXEL
#endif
#endif //if _POINTLIGHT_

	return FinalColor;
};

technique defaultTechnique
{
	pass P0
	{
		vertexShader	= compile vs_1_1 vsStaticMesh();
		pixelShader		= compile MPSMODEL psStaticMesh();

		ZFunc = LESS;

// In wait of NV driver hack...
//#if NVIDIA && defined(PSVERSION) && PSVERSION <= 14
//		TextureTransformFlags[0] = PROJECTED;
//#endif

#ifdef ENABLE_WIREFRAME
		FillMode		= WireFrame;
#endif

#if _POINTLIGHT_
		ZFunc			= LessEqual;
		AlphaBlendEnable= true;
		SrcBlend		= ONE;
		DestBlend		= ONE;
		fogenable		= false;
#else
		fogenable		= true;
#endif
		AlphaTestEnable = < AlphaTest >;
		AlphaRef = 127; // temporary hack by johan because "m_shaderSettings.m_alphaTestRef = 127" somehow doesn't work
	}
}
//#endif
