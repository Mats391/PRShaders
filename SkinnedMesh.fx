//
// Description: 1,2 bone skinning 
//
// Author: Mats Dal

#include "shaders/datatypes.fx"

// Note: obj space light vectors
vec4 sunLightDir : SunLightDirection;
vec4 lightDir : LightDirection;
//scalar hemiMapInfo.z : hemiMapInfo.z;
scalar normalOffsetScale : NormalOffsetScale;
//scalar hemiMapInfo.w : hemiMapInfo.w;

// offset x/y hemiMapInfo.z z / hemiMapInfo.w w
vec4 hemiMapInfo : HemiMapInfo;

vec4 skyColor : SkyColor;
vec4 ambientColor : AmbientColor;
vec4 sunColor : SunColor;

vec4 lightPos : LightPosition;
scalar attenuationSqrInv : AttenuationSqrInv;
vec4 lightColor : LightColor;

scalar shadowAlphaThreshold : SHADOWALPHATHRESHOLD;

scalar coneAngle : ConeAngle;

vec4 worldEyePos : WorldEyePos;

vec4 objectEyePos : ObjectEyePos;

mat4x4 mLightVP : LIGHTVIEWPROJ;
	mat4x4 mLightVP2 : LIGHTVIEWPROJ2;
	mat4x4 mLightVP3 : LIGHTVIEWPROJ3;
vec4 vViewportMap : VIEWPORTMAP;

dword dwStencilRef : STENCILREF = 0;

mat4x4 mWorld : World;
mat4x4 mWorldT : WorldT;
mat4x4 mWorldView : WorldView;
mat4x4 mWorldViewI : WorldViewI; // (WorldViewIT)T = WorldViewI
mat4x4 mWorldViewProj	: WorldViewProjection;
mat4x3 mBoneArray[26]	: BoneArray;//  : register(c15) < bool sparseArray = true; int arrayStart = 15; >;

mat4x4 vpLightMat : vpLightMat;
mat4x4 vpLightTrapezMat : vpLightTrapezMat;

vec4 paraboloidValues : ParaboloidValues;
vec4 paraboloidZValues : ParaboloidZValues;

texture texture0: TEXLAYER0;
texture texture1: TEXLAYER1;
texture texture2: TEXLAYER2;
texture texture3: TEXLAYER3;
texture texture4: TEXLAYER4;

sampler sampler0 = sampler_state { Texture = (texture0); MipFilter = LINEAR; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler1 = sampler_state { Texture = (texture1); MipFilter = LINEAR; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler2 = sampler_state { Texture = (texture2); MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler3 = sampler_state { Texture = (texture3); MipFilter = LINEAR; MinFilter = LINEAR; MagFilter = LINEAR; };
sampler sampler4 = sampler_state { Texture = (texture4); MipFilter = LINEAR; MinFilter = LINEAR; MagFilter = LINEAR; };

sampler sampler2point = sampler_state { Texture = (texture2); MinFilter = POINT; MagFilter = POINT; };
sampler sampler3point = sampler_state { Texture = (texture3); MinFilter = POINT; MagFilter = POINT; };
sampler sampler4point = sampler_state { Texture = (texture4); MinFilter = POINT; MagFilter = POINT; };

struct APP2VS
{
	vec4	Pos 		: POSITION;    
	vec3	Normal 		: NORMAL;
	scalar	BlendWeights	: BLENDWEIGHT;
	vec4	BlendIndices 	: BLENDINDICES;    
	vec2	TexCoord0 	: TEXCOORD0;
};

// object based lighting

void skinSoldierForPP(uniform int NumBones, in APP2VS indata, in vec3 lightVec, out vec3 Pos, out vec3 Normal, out vec3 SkinnedLVec)
{
	scalar LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;    
	SkinnedLVec = 0.0;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	// Calculate the pos/normal using the "normal" weights 
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		
		Pos += mul(indata.Pos, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		Normal += mul(indata.Normal, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		mat3x3 mat = transpose((mat3x3)mBoneArray[IndexArray[iBone]]);
		SkinnedLVec += mul(lightVec, mat) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight; 
	
	// Now that we have the calculated weight, add in the final influence
	Pos += mul(indata.Pos, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	Normal += mul(indata.Normal, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	mat3x3 mat = transpose((mat3x3)mBoneArray[IndexArray[NumBones-1]]);
	SkinnedLVec += mul(lightVec, mat) * LastWeight;
	
	// Normalize normals
	Normal = normalize(Normal);
	//SkinnedLVec = normalize(SkinnedLVec); // Don't normalize
}

void skinSoldierForPointPP(uniform int NumBones, in APP2VS indata, in vec3 lightVec, out vec3 Pos, out vec3 Normal, out vec3 SkinnedLVec)
{
	scalar LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;    
	SkinnedLVec = 0.0;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	// Calculate the pos/normal using the "normal" weights 
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		
		vec3 sPos = mul(indata.Pos, mBoneArray[IndexArray[iBone]]);
		Pos += sPos * BlendWeightsArray[iBone];
		Normal += mul(indata.Normal, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		mat3x3 mat = transpose((mat3x3)mBoneArray[IndexArray[iBone]]);
		vec3 localLVec = lightVec - sPos;
		SkinnedLVec += mul(localLVec, mat) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight; 
	
	// Now that we have the calculated weight, add in the final influence
	vec3 sPos = mul(indata.Pos, mBoneArray[IndexArray[NumBones-1]]);
	Pos += sPos * LastWeight;
	Normal += mul(indata.Normal, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	mat3x3 mat = transpose((mat3x3)mBoneArray[IndexArray[NumBones-1]]);
	vec3 localLVec = lightVec - sPos;
	SkinnedLVec += mul(localLVec, mat) * LastWeight;
	
	// Normalize normals
	Normal = normalize(Normal);
	//SkinnedLVec = normalize(SkinnedLVec); // Don't normalize
}

void skinSoldierForSpotPP(uniform int NumBones, in APP2VS indata, in vec3 lightVec, in vec3 lightDir, out vec3 Pos, out vec3 Normal, out vec3 SkinnedLVec, out vec3 SkinnedLDir)
{
	scalar LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;    
	SkinnedLVec = 0.0;
	SkinnedLDir = 0.0;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	// Calculate the pos/normal using the "normal" weights 
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		
		vec3 sPos = mul(indata.Pos, mBoneArray[IndexArray[iBone]]);
		Pos += sPos * BlendWeightsArray[iBone];
		Normal += mul(indata.Normal, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		mat3x3 mat = transpose((mat3x3)mBoneArray[IndexArray[iBone]]);
		vec3 localLVec = lightVec - sPos;
		SkinnedLVec += mul(localLVec, mat) * BlendWeightsArray[iBone];
		SkinnedLDir += mul(lightDir, mat) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0f - LastWeight; 
	
	// Now that we have the calculated weight, add in the final influence
	vec3 sPos = mul(indata.Pos, mBoneArray[IndexArray[NumBones-1]]);
	Pos += sPos * LastWeight;
	Normal += mul(indata.Normal, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	mat3x3 mat = transpose((mat3x3)mBoneArray[IndexArray[NumBones-1]]);
	vec3 localLVec = lightVec - sPos;
	SkinnedLVec += mul(localLVec, mat) * LastWeight;
	SkinnedLDir += mul(lightDir, mat) * LastWeight;
	
	// Normalize normals
	Normal = normalize(Normal);
	SkinnedLVec = SkinnedLVec;//normalize(SkinnedLVec);
	SkinnedLDir = normalize(SkinnedLDir);
}


// tangent based lighting

struct APP2VStangent
{
	vec4	Pos 		: POSITION;    
	vec3	Normal 		: NORMAL;
	scalar	BlendWeights	: BLENDWEIGHT;
	vec4	BlendIndices 	: BLENDINDICES;    
	vec2	TexCoord0 	: TEXCOORD0;
    vec3  Tan : TANGENT;
};

void skinSoldierForPPtangent(uniform int NumBones, in APP2VStangent indata, in vec3 lightVec, out vec3 Pos, out vec3 Normal, out vec3 SkinnedLVec, out vec4 wPos, out vec3 HalfVec)
{
	scalar LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;    
	SkinnedLVec = 0.0;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	vec3 binormal = normalize(cross(indata.Tan, indata.Normal));
	mat3x3 TanBasis = mat3x3( indata.Tan, 
					binormal, 
					indata.Normal);
	mat3x3 worldI;	
	mat3x3 mat;	

	// Calculate the pos/normal using the "normal" weights 
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		
		Pos += mul(indata.Pos, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		
		// Calculate WorldTangent directly... inverse is the transpose for affine rotations
		worldI = mul(TanBasis, mBoneArray[IndexArray[iBone]]);
		Normal += worldI[2] * BlendWeightsArray[iBone]; 
		
		mat = transpose(worldI);
		SkinnedLVec += mul(lightVec, mat) * BlendWeightsArray[iBone];
		
	}
	LastWeight = 1.0 - LastWeight; 
	
	// Now that we have the calculated weight, add in the final influence
	Pos += mul(indata.Pos, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	
	// Calculate WorldTangent directly... inverse is the transpose for affine rotations
	worldI = mul(TanBasis, mBoneArray[IndexArray[NumBones-1]]);
	Normal += worldI[2]  * LastWeight; 
	
	mat = transpose(worldI);
	SkinnedLVec += mul(lightVec, mat) * LastWeight;

	// Calculate HalfVector
	wPos = mul(vec4(Pos.xyz, 1.0), mWorld); 
	vec3 tanEyeVec = mul(worldEyePos - wPos, mat);
	HalfVec = normalize(normalize(tanEyeVec) + SkinnedLVec);
	
	// Normalize normals
	Normal = normalize(Normal);
	//SkinnedLVec = normalize(SkinnedLVec); // Don't normalize
}

void skinSoldierForPointPPtangent(uniform int NumBones, in APP2VStangent indata, in vec3 lightVec, out vec3 Pos, out vec3 Normal, out vec3 SkinnedLVec, out vec3 HalfVec)
{
	scalar LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;    
	SkinnedLVec = 0.0;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	vec3 binormal = normalize(cross(indata.Tan, indata.Normal));
	mat3x3 TanBasis = mat3x3( indata.Tan, 
					binormal, 
					indata.Normal);
	mat3x3 worldI;	
	mat3x3 mat;	

	// Calculate the pos/normal using the "normal" weights 
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		
		vec3 sPos = mul(indata.Pos, mBoneArray[IndexArray[iBone]]);
		Pos += sPos * BlendWeightsArray[iBone];
		
		// Calculate WorldTangent directly... inverse is the transpose for affine rotations
		worldI = mul(TanBasis, mBoneArray[IndexArray[iBone]]);
		Normal += worldI[2] * BlendWeightsArray[iBone]; 
		mat = transpose(worldI);
		
		vec3 localLVec = lightVec - sPos;
		SkinnedLVec += mul(localLVec, mat) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight; 
	
	// Now that we have the calculated weight, add in the final influence
	vec3 sPos = mul(indata.Pos, mBoneArray[IndexArray[NumBones-1]]);
	Pos += sPos * LastWeight;

	worldI = mul(TanBasis, mBoneArray[IndexArray[NumBones-1]]);
	Normal += worldI[2]  * LastWeight; 
	mat = transpose(worldI);
	vec3 localLVec = lightVec - sPos;
	SkinnedLVec += mul(localLVec, mat) * LastWeight;

	// Calculate HalfVector
	vec4 wPos = mul(vec4(Pos.xyz, 1.0), mWorld); 
	vec3 tanEyeVec = mul(worldEyePos - wPos, mat);
	HalfVec = normalize(normalize(tanEyeVec) + SkinnedLVec);
	
	// Normalize normals
	Normal = normalize(Normal);
	//SkinnedLVec = normalize(SkinnedLVec); // Don't normalize
}

void skinSoldierForSpotPPtangent(uniform int NumBones, in APP2VStangent indata, in vec3 lightVec, in vec3 lightDir, out vec3 Pos, out vec3 Normal, out vec3 SkinnedLVec, out vec3 SkinnedLDir, out vec3 HalfVec)
{
	scalar LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;    
	SkinnedLVec = 0.0;
	SkinnedLDir = 0.0;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	vec3 binormal = normalize(cross(indata.Tan, indata.Normal));
	mat3x3 TanBasis = mat3x3( indata.Tan, 
					binormal, 
					indata.Normal);
	mat3x3 worldI;	
	mat3x3 mat;	

	// Calculate the pos/normal using the "normal" weights 
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		
		vec3 sPos = mul(indata.Pos, mBoneArray[IndexArray[iBone]]);
		Pos += sPos * BlendWeightsArray[iBone];
		// Calculate WorldTangent directly... inverse is the transpose for affine rotations
		worldI = mul(TanBasis, mBoneArray[IndexArray[iBone]]);
		Normal += worldI[2] * BlendWeightsArray[iBone]; 
		mat = transpose(worldI);
		
		vec3 localLVec = lightVec - sPos;
		SkinnedLVec += mul(localLVec, mat) * BlendWeightsArray[iBone];
		SkinnedLDir += mul(lightDir, mat) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight; 
	
	// Now that we have the calculated weight, add in the final influence
	vec3 sPos = mul(indata.Pos, mBoneArray[IndexArray[NumBones-1]]);
	Pos += sPos * LastWeight;
	// Calculate WorldTangent directly... inverse is the transpose for affine rotations
	worldI = mul(TanBasis, mBoneArray[IndexArray[NumBones-1]]);
	Normal += worldI[2] * LastWeight; 
	mat = transpose(worldI);
	
	vec3 localLVec = lightVec - sPos;
	SkinnedLVec += mul(localLVec, mat) * LastWeight;
	SkinnedLDir += mul(lightDir, mat) * LastWeight;

	// Calculate HalfVector
	vec4 wPos = mul(vec4(Pos.xyz, 1.0), mWorld); 
	vec3 tanEyeVec = mul(worldEyePos - wPos, mat);
	HalfVec = normalize(normalize(tanEyeVec) + SkinnedLVec);
	
	// Normalize normals
	Normal = normalize(Normal);
	//SkinnedLVec = SkinnedLVec;//normalize(SkinnedLVec);
	SkinnedLDir = normalize(SkinnedLDir);
}


void skinSoldierForPV(uniform int NumBones, in APP2VS indata, out vec3 Pos, out vec3 Normal)
{
	scalar LastWeight = 0.0;
	Pos = 0.0;
	Normal = 0.0;    

	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	// Calculate the pos/normal using the "normal" weights 
	// and accumulate the weights to calculate the last weight
	for (int iBone = 0; iBone < NumBones-1; iBone++)
	{
		LastWeight += BlendWeightsArray[iBone];
		
		Pos += mul(indata.Pos, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
		Normal += mul(indata.Normal, mBoneArray[IndexArray[iBone]]) * BlendWeightsArray[iBone];
	}
	LastWeight = 1.0 - LastWeight; 
	
	// Now that we have the calculated weight, add in the final influence
	Pos += mul(indata.Pos, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	Normal += mul(indata.Normal, mBoneArray[IndexArray[NumBones-1]]) * LastWeight;
	
	// Normalize normals
	Normal = normalize(Normal);
}

struct VS2PS_PP
{
	vec4	Pos		: POSITION;
	vec2	Tex0		: TEXCOORD0;
	vec3	GroundUVAndLerp	: TEXCOORD1;
	vec3	SkinnedLVec		: TEXCOORD2;
	vec3	HalfVec		: TEXCOORD3;
};

//----------- pp object based lighting

VS2PS_PP VShader_HemiAndSunPP(APP2VS indata, uniform int NumBones)
{
	VS2PS_PP outdata;
	vec3 Pos, Normal, SkinnedLVec;
	
	skinSoldierForPP(NumBones, indata, -sunLightDir, Pos, Normal, SkinnedLVec);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 

 	// Hemi lookup values
	vec4 wPos = mul(vec4(Pos.xyz, 1.0), mWorld); 
 	outdata.GroundUVAndLerp.xy = ((wPos +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy)/ hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;
	
	//[TS:040201] Please note that "normalize(worldEyePos-wPos") is in worldspace while "SkinnedLVec" is in SkinnedSpace/ObjectSpace can this be correct??
	//outdata.HalfVec = normalize(normalize(worldEyePos-wPos) + SkinnedLVec);
	outdata.HalfVec = normalize(normalize(objectEyePos-Pos) + SkinnedLVec);
	outdata.SkinnedLVec = normalize(SkinnedLVec);
	 	
	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

struct VS2PS_PP_Shadow
{
	vec4	Pos		: POSITION;
	vec2	Tex0		: TEXCOORD0;
	vec3	GroundUVAndLerp	: TEXCOORD1;
	vec3	SkinnedLVec		: TEXCOORD2;
	vec3	HalfVec		: TEXCOORD3;
	vec4	ShadowTex		: TEXCOORD4;
};

VS2PS_PP_Shadow VShader_HemiAndSunAndShadowPP(APP2VS indata, uniform int NumBones)
{
	VS2PS_PP_Shadow outdata;
	vec3 Pos, Normal, SkinnedLVec;
	
	skinSoldierForPP(NumBones, indata, -sunLightDir, Pos, Normal, SkinnedLVec);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 

	// Shadow
	outdata.ShadowTex =  mul(vec4(Pos, 1), vpLightTrapezMat);
	vec2 TexShadow2 = mul(vec4(Pos, 1), vpLightMat).zw;
	TexShadow2.x -= 0.007;
	outdata.ShadowTex.z = (TexShadow2.x*outdata.ShadowTex.w)/TexShadow2.y; 	// (zL*wT)/wL == zL/wL post homo

 	// Hemi lookup values
	vec4 wPos = mul(vec4(Pos.xyz, 1.0), mWorld); 
 	outdata.GroundUVAndLerp.xy = ((wPos +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy)/ hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;
	
	//[TS:040201] Please note that "normalize(worldEyePos-wPos") is in worldspace while "SkinnedLVec" is in SkinnedSpace/ObjectSpace can this be correct??
	//outdata.HalfVec = normalize(normalize(worldEyePos-wPos) + SkinnedLVec);
	outdata.HalfVec = normalize(normalize(objectEyePos-Pos) + SkinnedLVec);
	outdata.SkinnedLVec = normalize(SkinnedLVec);
	 	
	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}


vec4 PShader_HemiAndSunPP(VS2PS_PP indata) : COLOR
{
	vec4 groundcolor = tex2D(sampler0, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, skyColor, indata.GroundUVAndLerp.z);
	vec4 normal = tex2D(sampler1, indata.Tex0);
	vec3 expnormal = normalize((normal * 2) - 1);
	vec3 suncol = saturate(dot(expnormal.rgb, indata.SkinnedLVec)) * sunColor;
	scalar specular = pow(dot(expnormal.rgb, indata.HalfVec), 36)*normal.a;

	vec4 totalcolor = vec4(suncol, specular);	// Do something with spec-alpha later on
	totalcolor *= groundcolor.a*groundcolor.a;
	totalcolor.rgb += ambientColor*hemicolor;
	return totalcolor;
}

vec4 PShader_HemiAndSunAndShadowPP(VS2PS_PP_Shadow indata) : COLOR
{
	vec4 groundcolor = tex2D(sampler0, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, skyColor, indata.GroundUVAndLerp.z);
	vec4 normal = tex2D(sampler1, indata.Tex0);
		vec3 expnormal = normalize((normal * 2) - 1);
	vec3 suncol = saturate(dot(expnormal.rgb, indata.SkinnedLVec)) * sunColor;
	scalar specular = pow(dot(expnormal.rgb, indata.HalfVec), 36)*normal.a;

	vec4 texel = vec4(1.0/1024.0, 1.0/1024.0, 0, 0);
	vec4 samples;
	//indata.ShadowTex.xy = clamp(indata.ShadowTex.xy, vViewportMap.xy, vViewportMap.zw);
	samples.x = tex2Dproj(sampler3point, indata.ShadowTex);
	samples.y = tex2Dproj(sampler3point, indata.ShadowTex + vec4(texel.x, 0, 0, 0));
	samples.z = tex2Dproj(sampler3point, indata.ShadowTex + vec4(0, texel.y, 0, 0));
	samples.w = tex2Dproj(sampler3point, indata.ShadowTex + texel);
	
	vec4 staticSamples;
	staticSamples.x = tex2D(sampler2, indata.ShadowTex + vec2(-texel.x*1, -texel.y*2)).b;
	staticSamples.y = tex2D(sampler2, indata.ShadowTex + vec2( texel.x*1, -texel.y*2)).b;
	staticSamples.z = tex2D(sampler2, indata.ShadowTex + vec2(-texel.x*1,  texel.y*2)).b;
	staticSamples.w = tex2D(sampler2, indata.ShadowTex + vec2( texel.x*1,  texel.y*2)).b;
	staticSamples.x = dot(staticSamples.xyzw, 0.25);
	
	vec4 cmpbits = samples > saturate(indata.ShadowTex.z/indata.ShadowTex.w);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));

	scalar totShadow = avgShadowValue.x*staticSamples.x;

	vec4 totalcolor = vec4(suncol, specular*totShadow*totShadow);	// Do something with spec-alpha later on
	totalcolor.rgb *= totShadow;
	totalcolor.rgb += ambientColor*hemicolor;
	
	return totalcolor;
}


vec4 PShader_HemiAndSunAndColorPP(VS2PS_PP indata) : COLOR
{
	vec4 groundcolor = tex2D(sampler0, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, skyColor, indata.GroundUVAndLerp.z);
	vec4 normal = tex2D(sampler1, indata.Tex0);
		vec3 expnormal = normalize((normal * 2) - 1);
	vec3 suncol = saturate(dot(expnormal.rgb, indata.SkinnedLVec)) * sunColor;
	scalar specular = pow(dot(expnormal.rgb, indata.HalfVec), 36)*normal.a;

	vec4 totalcolor = saturate(vec4(suncol*groundcolor.a*groundcolor.a+ambientColor*hemicolor, specular));	// Do something with spec-alpha later on
	
	vec4 color = tex2D(sampler2, indata.Tex0);
	totalcolor.rgb *= color.rgb;

	totalcolor.rgb += specular;	
	totalcolor.a = color.a;
	
	return totalcolor;
}

vec4 PShader_HemiAndSunAndShadowAndColorPP(VS2PS_PP_Shadow indata) : COLOR
{
	vec4 groundcolor = tex2D(sampler0, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, skyColor, indata.GroundUVAndLerp.z);
	vec4 normal = tex2D(sampler1, indata.Tex0);
	vec3 expnormal = normalize((normal * 2) - 1);
	vec3 suncol = saturate(dot(expnormal.rgb, indata.SkinnedLVec)) * sunColor;
	scalar specular = pow(dot(expnormal.rgb, indata.HalfVec), 36)*normal.a;

	vec4 texel = vec4(0.5/1024.0, 0.5/1024.0, 0, 0);
	vec4 samples;
	//indata.ShadowTex.xy = clamp(indata.ShadowTex.xy, vViewportMap.xy, vViewportMap.zw);
	samples.x = tex2Dproj(sampler4point, indata.ShadowTex);
	samples.y = tex2Dproj(sampler4point, indata.ShadowTex + vec4(texel.x, 0, 0, 0));
	samples.z = tex2Dproj(sampler4point, indata.ShadowTex + vec4(0, texel.y, 0, 0));
	samples.w = tex2Dproj(sampler4point, indata.ShadowTex + texel);
	
	vec4 staticSamples;
	staticSamples.x = tex2D(sampler3, indata.ShadowTex + vec2(-texel.x*1, -texel.y*2)).b;
	staticSamples.y = tex2D(sampler3, indata.ShadowTex + vec2( texel.x*1, -texel.y*2)).b;
	staticSamples.z = tex2D(sampler3, indata.ShadowTex + vec2(-texel.x*1,  texel.y*2)).b;
	staticSamples.w = tex2D(sampler3, indata.ShadowTex + vec2( texel.x*1,  texel.y*2)).b;
	staticSamples.x = dot(staticSamples.xyzw, 0.25);
	
	vec4 cmpbits = samples > saturate(indata.ShadowTex.z/indata.ShadowTex.w);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));

	scalar totShadow = avgShadowValue.x*staticSamples.x;
//return avgShadowValue;
	vec4 color = tex2D(sampler2, indata.Tex0);
	vec4 totalcolor = saturate(vec4(suncol*totShadow+ambientColor*hemicolor, specular));	// Do something with spec-alpha later on
	totalcolor.rgb *= color.rgb;
	totalcolor.rgb += specular*totShadow*totShadow;
	totalcolor.a = color.a;
	
	return totalcolor;
}


// Max 2 bones skinning supported!
VertexShader vsArray_HemiAndSunPP[2] = { compile vs_1_1 VShader_HemiAndSunPP(1), compile vs_1_1 VShader_HemiAndSunPP(2) };
VertexShader vsArray_HemiAndSunAndShadowPP[2] = { compile vs_1_1 VShader_HemiAndSunAndShadowPP(1), compile vs_1_1 VShader_HemiAndSunAndShadowPP(2) };


#if !_FORCE_1_4_SHADERS_
technique t0_HemiAndSunPP
{
	pass p0
	{
		CullMode = CCW;
		ZEnable = TRUE;	
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		//AlphaBlendEnable = TRUE;
		
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
	
		VertexShader = (vsArray_HemiAndSunPP[1]);
		PixelShader = compile PS2_EXT PShader_HemiAndSunPP();
	}

	pass p0
	{
		CullMode = CCW;
		ZEnable = TRUE;	
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		//AlphaBlendEnable = TRUE;
		
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
	
		VertexShader = (vsArray_HemiAndSunAndShadowPP[1]);
		PixelShader = compile PS2_EXT PShader_HemiAndSunPP();
	}
}
#endif

#if !_FORCE_1_4_SHADERS_
technique t0_HemiAndSunAndColorPP
{
	pass p0
	{
		CullMode = CCW;
		ZEnable = TRUE;	
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		//AlphaBlendEnable = TRUE;
		
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
	
		VertexShader = (vsArray_HemiAndSunPP[1]);
		PixelShader = compile PS2_EXT PShader_HemiAndSunAndColorPP();
	}
	
	pass p1
	{
		CullMode = CCW;
		ZEnable = TRUE;	
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		//AlphaBlendEnable = TRUE;
		
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		VertexShader = (vsArray_HemiAndSunAndShadowPP[1]);
		PixelShader = compile PS2_EXT PShader_HemiAndSunAndShadowAndColorPP();
	}
}
#endif

//----------- pp tangent based lighting

VS2PS_PP VShader_HemiAndSunPPtangent(APP2VStangent indata, uniform int NumBones)
{
	VS2PS_PP outdata;
	vec3 Pos, Normal, SkinnedLVec;
	vec4 wPos;
	
	skinSoldierForPPtangent(NumBones, indata, -sunLightDir, Pos, Normal, SkinnedLVec, wPos, outdata.HalfVec);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 

 	// Hemi lookup values
 	outdata.GroundUVAndLerp.xy = ((wPos +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy)/ hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;
	
	outdata.SkinnedLVec = normalize(SkinnedLVec);
	 	
	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

VS2PS_PP_Shadow VShader_HemiAndSunAndShadowPPtangent(APP2VStangent indata, uniform int NumBones)
{
	VS2PS_PP_Shadow outdata;
	vec3 Pos, Normal, SkinnedLVec;
	vec4 wPos;
	
	skinSoldierForPPtangent(NumBones, indata, -sunLightDir, Pos, Normal, SkinnedLVec, wPos, outdata.HalfVec);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 

 	// Hemi lookup values
 	outdata.GroundUVAndLerp.xy = ((wPos +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy)/ hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;

	// Shadow
	outdata.ShadowTex =  mul(vec4(Pos, 1), vpLightTrapezMat);
	vec2 TexShadow2 = mul(vec4(Pos, 1), vpLightMat).zw;
	TexShadow2.x -= 0.007;
	outdata.ShadowTex.z = (TexShadow2.x*outdata.ShadowTex.w)/TexShadow2.y; 	// (zL*wT)/wL == zL/wL post homo

	
	outdata.SkinnedLVec = normalize(SkinnedLVec);
	 	
	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

VertexShader vsArray_HemiAndSunPPtangent[2] = { compile vs_1_1 VShader_HemiAndSunPPtangent(1), compile vs_1_1 VShader_HemiAndSunPPtangent(2) };
VertexShader vsArray_HemiAndSunAndShadowPPtangent[2] = { compile vs_1_1 VShader_HemiAndSunAndShadowPPtangent(1), compile vs_1_1 VShader_HemiAndSunAndShadowPPtangent(2) };

#if !_FORCE_1_4_SHADERS_
technique t0_HemiAndSunPPtangent
{
	pass p0
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		ZEnable = TRUE;	
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
	
		VertexShader = (vsArray_HemiAndSunPPtangent[1]);
		PixelShader = compile PS2_EXT PShader_HemiAndSunPP();
	}

	pass p1
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		ZEnable = TRUE;	
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
	
		VertexShader = (vsArray_HemiAndSunAndShadowPPtangent[1]);
		PixelShader = compile PS2_EXT PShader_HemiAndSunPP();
	}
}
#endif

#if !_FORCE_1_4_SHADERS_
technique t0_HemiAndSunAndColorPPtangent
{
	pass p0
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		ZEnable = TRUE;	
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
	
		VertexShader = (vsArray_HemiAndSunPPtangent[1]);
		PixelShader = compile PS2_EXT PShader_HemiAndSunPP();
	}

	pass p1
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		ZEnable = TRUE;	
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
	
		VertexShader = (vsArray_HemiAndSunAndShadowPPtangent[1]);
		PixelShader = compile PS2_EXT PShader_HemiAndSunPP();
	}
}
#endif

struct VS2PS_PV
{
	vec4	Pos		: POSITION;
	vec2	GroundUV	: TEXCOORD0;
	vec4	DiffAndSpec	: COLOR0;
	scalar  Lerp : COLOR1;
};

VS2PS_PV VShader_HemiAndSunPV(APP2VS indata, uniform int NumBones)
{
	VS2PS_PV outdata;
	vec3 Pos, Normal;
	
	skinSoldierForPV(NumBones, indata, Pos, Normal);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 

 	// Hemi lookup values
	vec4 wPos = mul(vec4(Pos.xyz, 1.0), mWorld); 
 	outdata.GroundUV.xy = ((wPos +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy) / hemiMapInfo.z;
	outdata.GroundUV.y = 1-outdata.GroundUV.y;
	outdata.Lerp = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.Lerp -= hemiMapInfo.w;
	
	scalar diff = dot(Normal, -sunLightDir);
	vec3 objEyeVec = normalize(objectEyePos-Pos);
	vec3 halfVec = (-sunLightDir + objEyeVec) * 0.5;
	scalar spec = dot(Normal, halfVec);
	vec4 light = lit(diff, spec, 32);
	outdata.DiffAndSpec.rgb = light.y * sunColor;
	outdata.DiffAndSpec.a = light.z;
	
	return outdata;
}

vec4 PShader_HemiAndSunPV(VS2PS_PV indata) : COLOR
{
	vec4 groundcolor = tex2D(sampler0, indata.GroundUV.xy);
	vec4 hemicolor = lerp(groundcolor, skyColor, indata.Lerp);

	vec4 totalcolor = vec4(indata.DiffAndSpec.rgb*groundcolor.a*groundcolor.a+ambientColor*hemicolor, indata.DiffAndSpec.a);

#if _FORCE_1_3_SHADERS_
	return( totalcolor );
#else
	return saturate(totalcolor);
#endif
}

// Max 2 bones skinning supported!
VertexShader vsArray_HemiAndSunPV[2] = { compile vs_1_1 VShader_HemiAndSunPV(1),  compile vs_1_1 VShader_HemiAndSunPV(2) };


technique t0_HemiAndSunPV
{
	pass p0
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
	
		VertexShader = (vsArray_HemiAndSunPV[1]);
		PixelShader = compile LOWPSMODEL PShader_HemiAndSunPV();
	}

	pass p1
	{
		CullMode = CCW;
		ZEnable = TRUE;	
		AlphaBlendEnable = FALSE;
		AlphaTestEnable = FALSE;
		
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
			
		VertexShader = (vsArray_HemiAndSunPV[1]);
		PixelShader = compile LOWPSMODEL PShader_HemiAndSunPV();
	}
}

struct VS2PS_PVCOLOR
{
	vec4	Pos		: POSITION;
	vec2	Tex0		: TEXCOORD0;	
	vec3	GroundUVAndLerp	: TEXCOORD1;
	vec4	DiffAndSpec	: COLOR;
};

VS2PS_PVCOLOR VShader_HemiAndSunAndColorPV(APP2VS indata, uniform int NumBones)
{
	VS2PS_PVCOLOR outdata;
	vec3 Pos, Normal;
	
	skinSoldierForPV(NumBones, indata, Pos, Normal);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 

 	// Hemi lookup values
	vec4 wPos = mul(vec4(Pos.xyz, 1.0), mWorld); 
 	outdata.GroundUVAndLerp.xy = ((wPos +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy) / hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;
	
	outdata.Tex0 = indata.TexCoord0;
	scalar diff = dot(Normal, -sunLightDir);
	vec3 objEyeVec = normalize(objectEyePos-Pos);
	vec3 halfVec = (-sunLightDir + objEyeVec) * 0.5;
	scalar spec = dot(Normal, halfVec);
	vec4 light = lit(diff, spec, 32);
	outdata.DiffAndSpec.rgb = light.y * sunColor;
	outdata.DiffAndSpec.a = light.z;
	
	return outdata;
}


vec4 PShader_HemiAndSunAndColorPV(VS2PS_PVCOLOR indata) : COLOR
{
	vec4 groundcolor = tex2D(sampler0, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, skyColor, indata.GroundUVAndLerp.z);

	vec4 totalcolor = saturate(vec4(indata.DiffAndSpec.rgb*groundcolor.a*groundcolor.a+ambientColor*hemicolor, indata.DiffAndSpec.a));	// Do something with spec-alpha later on
	vec4 color = tex2D(sampler1, indata.Tex0);
	totalcolor.rgb *= color.rgb;
	totalcolor.rgb += indata.DiffAndSpec.a; 
	
	totalcolor.a = color.a;
	
	return totalcolor;
}

struct VS2PS_PVCOLOR_SHADOW
{
	vec4	Pos		: POSITION;
	vec2	Tex0		: TEXCOORD0;	
	vec3	GroundUVAndLerp	: TEXCOORD1;
	vec4	ShadowTex		: TEXCOORD2;
	vec4	DiffAndSpec	: COLOR;
};


VS2PS_PVCOLOR_SHADOW VShader_HemiAndSunAndShadowAndColorPV(APP2VS indata, uniform int NumBones)
{
	VS2PS_PVCOLOR_SHADOW outdata = (VS2PS_PVCOLOR_SHADOW)0;
	vec3 Pos, Normal;
	
	skinSoldierForPV(NumBones, indata, Pos, Normal);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 
	//outdata.Pos = mul(vec4(indata.Pos.xyz, 1.0), mWorldViewProj); 
	//Pos = outdata.Pos;
	//Normal = vec3(0,0,1);


	// Shadow
	outdata.ShadowTex =  mul(vec4(Pos, 1), vpLightTrapezMat);
	vec2 TexShadow2 = mul(vec4(Pos, 1), vpLightMat).zw;
	TexShadow2.x -= 0.007;
	outdata.ShadowTex.z = (TexShadow2.x*outdata.ShadowTex.w)/TexShadow2.y; 	// (zL*wT)/wL == zL/wL post homo

 	// Hemi lookup values
	vec4 wPos = mul(vec4(Pos.xyz, 1.0), mWorld); 
 	outdata.GroundUVAndLerp.xy = ((wPos +(hemiMapInfo.z/2) + Normal*1).xz - hemiMapInfo.xy) / hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;
	
	outdata.Tex0 = indata.TexCoord0;
	scalar diff = dot(Normal, -sunLightDir);
	vec3 objEyeVec = normalize(objectEyePos-Pos);
	vec3 halfVec = (-sunLightDir + objEyeVec) * 0.5;
	scalar spec = dot(Normal, halfVec);
	vec4 light = lit(diff, spec, 32);
	outdata.DiffAndSpec.rgb = sunColor * light.y;
	outdata.DiffAndSpec.a = light.z;
	
	//outdata.DiffAndSpec.rgb = dot(Normal, -sunLightDir) * sunColor;
	//outdata.DiffAndSpec.a = dot(Normal, normalize(normalize(objectEyePos-Pos) - sunLightDir));


	return outdata;
}


vec4 PShader_HemiAndSunAndShadowAndColorPV(VS2PS_PVCOLOR_SHADOW indata) : COLOR
{
	vec4 groundcolor = tex2D(sampler0, indata.GroundUVAndLerp.xy);
	vec4 hemicolor = lerp(groundcolor, skyColor, indata.GroundUVAndLerp.z);

	vec4 texel = vec4(1.0/1024.0, 1.0/1024.0, 0, 0);
	vec4 samples;
	//indata.ShadowTex.xy = clamp(indata.ShadowTex.xy, vViewportMap.xy, vViewportMap.zw);

	samples.x = tex2Dproj(sampler4point, indata.ShadowTex);
	samples.y = tex2Dproj(sampler4point, indata.ShadowTex + vec4(texel.x, 0, 0, 0));
	samples.z = tex2Dproj(sampler4point, indata.ShadowTex + vec4(0, texel.y, 0, 0));
	samples.w = tex2Dproj(sampler4point, indata.ShadowTex + texel);
	
	vec4 staticSamples;
	staticSamples.x = tex2D(sampler3, indata.ShadowTex + vec2(-texel.x*1, -texel.y*2)).b;
	staticSamples.y = tex2D(sampler3, indata.ShadowTex + vec2( texel.x*1, -texel.y*2)).b;
	staticSamples.z = tex2D(sampler3, indata.ShadowTex + vec2(-texel.x*1,  texel.y*2)).b;
	staticSamples.w = tex2D(sampler3, indata.ShadowTex + vec2( texel.x*1,  texel.y*2)).b;
	staticSamples.x = dot(staticSamples.xyzw, 0.25);
	
	vec4 cmpbits = samples > saturate(indata.ShadowTex.z);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));

	scalar totShadow = avgShadowValue.x*staticSamples.x;

	vec4 totalcolor = saturate(vec4(indata.DiffAndSpec.rgb*totShadow+ambientColor*hemicolor, indata.DiffAndSpec.a));	// Do something with spec-alpha later on
	vec4 color = tex2D(sampler1, indata.Tex0);
	totalcolor.rgb *= color.rgb;
	totalcolor.rgb += indata.DiffAndSpec.a *totShadow*totShadow; 

	totalcolor.a = color.a;
	
	return totalcolor;
}

// Max 2 bones skinning supported!
VertexShader vsArray_HemiAndSunAndColorPV[2] = { compile vs_1_1 VShader_HemiAndSunAndColorPV(1),  compile vs_1_1 VShader_HemiAndSunAndColorPV(2) };
VertexShader vsArray_HemiAndSunAndShadowAndColorPV[2] = { compile vs_1_1 VShader_HemiAndSunAndShadowAndColorPV(1),  compile vs_1_1 VShader_HemiAndSunAndShadowAndColorPV(2) };


technique t0_HemiAndSunAndColorPV
{

	pass p0
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
	
		VertexShader = (vsArray_HemiAndSunAndColorPV[1]);
		PixelShader = compile LOWPSMODEL PShader_HemiAndSunPV();
	}
	pass p1
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		VertexShader = (vsArray_HemiAndSunAndShadowAndColorPV[1]);
		PixelShader = compile LOWPSMODEL PShader_HemiAndSunPV();
	}
}


struct VS2PS_PointLight_PV
{
	vec4	Pos		: POSITION;
	vec3	Diffuse	 	: COLOR;
	vec2	Tex0		: TEXCOORD0;
};

VS2PS_PointLight_PV VShader_PointLightPV(APP2VS indata, uniform int NumBones)
{
	VS2PS_PointLight_PV outdata;
	vec3 Pos, Normal;
	
	skinSoldierForPV(NumBones, indata, Pos, Normal);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 

	// Lighting. Shade (Ambient + etc.)
	//vec4 wPos = mul(vec4(Pos.xyz, 1.0), mWorld); 	
	vec3 lvec = lightPos - Pos.xyz;
	vec3 lvecNormalized = normalize(lvec);
	
	scalar radialAtt = 1-saturate(dot(lvec,lvec)*attenuationSqrInv);

	outdata.Diffuse = dot(lvecNormalized, Normal);
	outdata.Diffuse *= lightColor * radialAtt;

	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

vec4 PShader_PointLightPV(VS2PS_PointLight_PV indata) : COLOR
{
	return vec4(indata.Diffuse,0);
}

//
// Max 2 bones skinning supported!
//
VertexShader vsArray_PointLightPV[2] = { compile vs_1_1 VShader_PointLightPV(1), 
                            compile vs_1_1 VShader_PointLightPV(2) };


technique t0_PointLightPV
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

		ZWriteEnable = FALSE;
		ZFunc = EQUAL;
	
		VertexShader = (vsArray_PointLightPV[1]);
		PixelShader = compile ps_1_1 PShader_PointLightPV();
	}
}

//----------- pp object based lighting

struct VS2PS_PointLight_PP
{
	vec4	Pos		: POSITION;
	vec2	Tex0		: TEXCOORD0;
	vec4	SkinnedLVec		: TEXCOORD1;
	vec3	HalfVec			: TEXCOORD2;
};

VS2PS_PointLight_PP VShader_PointLightPP(APP2VS indata, uniform int NumBones)
{
	VS2PS_PointLight_PP outdata;
	vec3 Pos, Normal, SkinnedLVec;
	
	skinSoldierForPointPP(NumBones, indata, lightPos, Pos, Normal, SkinnedLVec);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 
	vec4 wPos = mul(vec4(Pos.xyz, 1.0), mWorld); 
	
	//[TS:040201] Please note that "normalize(worldEyePos-wPos") is in worldspace while "SkinnedLVec" is in SkinnedSpace/ObjectSpace can this be correct??
	//outdata.HalfVec = normalize(normalize(worldEyePos-wPos) + SkinnedLVec);
	outdata.HalfVec = normalize(normalize(objectEyePos-Pos) + SkinnedLVec);
	vec3 nrmSkinnedLVec = normalize(SkinnedLVec);
	outdata.SkinnedLVec.xyz = nrmSkinnedLVec;
	
	// Skinnedmeshes are highly tesselated, so..
	scalar radialAtt = 1-saturate(dot(SkinnedLVec,SkinnedLVec)*attenuationSqrInv);
	outdata.SkinnedLVec.w = radialAtt;
 	
	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

vec4 PShader_PointLightPP(VS2PS_PointLight_PP indata) : COLOR
{
//	vec3 normalizedLVec = normalize(indata.SkinnedLVec);
//	scalar radialAtt = 1-saturate(dot(indata.SkinnedLVec,indata.SkinnedLVec)*attenuationSqrInv);

	vec4 expandedNormal = tex2D(sampler1, indata.Tex0);
	expandedNormal.xyz = ((expandedNormal.xyz * 2) - 1);
	vec2 intensityuv = vec2(dot(indata.SkinnedLVec.xyz,expandedNormal.xyz), dot(indata.HalfVec,expandedNormal));
	vec4 realintensity = vec4(intensityuv.rrr,pow(intensityuv.g,36)*expandedNormal.a);
	realintensity *= lightColor * indata.SkinnedLVec.w;//radialAtt;
	return realintensity;
}

//
// Max 2 bones skinning supported!
//
VertexShader vsArray_PointLightPP[2] = { compile vs_1_1 VShader_PointLightPP(1), 
                            compile vs_1_1 VShader_PointLightPP(2) };


#if !_FORCE_1_4_SHADERS_
technique t0_PointLightPP
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

		ZWriteEnable = FALSE;
		ZFunc = EQUAL;
	
		VertexShader = (vsArray_PointLightPP[1]);
		PixelShader = compile PS2_EXT PShader_PointLightPP();
	}
}
#endif

//----------- pp tangent based lighting

VS2PS_PointLight_PP VShader_PointLightPPtangent(APP2VStangent indata, uniform int NumBones)
{
	VS2PS_PointLight_PP outdata;
	vec3 Pos, Normal, SkinnedLVec;
	
	skinSoldierForPointPPtangent(NumBones, indata, lightPos, Pos, Normal, SkinnedLVec,outdata.HalfVec);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 
	
	vec3 nrmSkinnedLVec = normalize(SkinnedLVec);
	outdata.SkinnedLVec.xyz = nrmSkinnedLVec;
	
	// Skinnedmeshes are highly tesselated, so..
	scalar radialAtt = 1-saturate(dot(SkinnedLVec,SkinnedLVec)*attenuationSqrInv);
	outdata.SkinnedLVec.w = radialAtt;
 	
	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

//
// Max 2 bones skinning supported!
//
VertexShader vsArray_PointLightPPtangent[2] = { compile vs_1_1 VShader_PointLightPPtangent(1), 
                            compile vs_1_1 VShader_PointLightPPtangent(2) };


#if !_FORCE_1_4_SHADERS_
technique t0_PointLightPPtangent
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

		ZWriteEnable = FALSE;
		ZFunc = EQUAL;
	
		VertexShader = (vsArray_PointLightPPtangent[1]);
		PixelShader = compile PS2_EXT PShader_PointLightPP();
	}
}
#endif

struct VS2PS_SpotLight_PV
{
	vec4	Pos		: POSITION;
	vec3	Diffuse	 	: COLOR;
	vec2	Tex0		: TEXCOORD0;
};

VS2PS_SpotLight_PV VShader_SpotLightPV(APP2VS indata, uniform int NumBones)
{
	VS2PS_SpotLight_PV outdata;
	vec3 Pos, Normal;
	
	skinSoldierForPV(NumBones, indata, Pos, Normal);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0f), mWorldViewProj); 

	vec3 lvec = lightPos - Pos.xyz;
	vec3 lvecnorm = normalize(lvec);
	
	scalar radialAtt = 1-saturate(dot(lvec,lvec)*attenuationSqrInv);
	scalar offCenter = dot(lvecnorm, lightDir);
	scalar conicalAtt = saturate(offCenter-(1-coneAngle))/coneAngle;

	outdata.Diffuse = dot(lvecnorm,Normal) * lightColor;
	outdata.Diffuse *= conicalAtt*radialAtt;
	 	
	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

vec4 PShader_SpotLightPV(VS2PS_SpotLight_PV indata) : COLOR
{
	return vec4(indata.Diffuse,0);
}

//
// Max 2 bones skinning supported!
//
VertexShader vsArray_SpotLightPV[2] = { compile vs_1_1 VShader_SpotLightPV(1), 
                            compile vs_1_1 VShader_SpotLightPV(2)
                           };


technique t0_SpotLightPV
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

		ZWriteEnable = FALSE;
		ZFunc = EQUAL;
	
		VertexShader = (vsArray_SpotLightPV[1]);
		PixelShader = compile ps_1_1 PShader_SpotLightPV();
	}
}

struct VS2PS_SpotLight_PP
{
	vec4	Pos				: POSITION;
	vec2	Tex0			: TEXCOORD0;
	vec4	SkinnedLVec		: TEXCOORD1;
	//vec3	SkinnedLDir	: TEXCOORD2;
	vec3	HalfVec			: TEXCOORD3;
};

VS2PS_SpotLight_PP VShader_SpotLightPP(APP2VS indata, uniform int NumBones)
{
	VS2PS_SpotLight_PP outdata;
	vec3 Pos, Normal, SkinnedLVec, SkinnedLDir;
	
	skinSoldierForSpotPP(NumBones, indata, lightPos, lightDir, Pos, Normal, SkinnedLVec, SkinnedLDir);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 
	vec4 wPos = mul(vec4(Pos.xyz, 1.0), mWorld); 
	
	//[TS:040201] Please note that "normalize(worldEyePos-wPos") is in worldspace while "SkinnedLVec" is in SkinnedSpace/ObjectSpace can this be correct??
	//outdata.HalfVec = normalize(normalize(worldEyePos-wPos) + SkinnedLVec);
	outdata.HalfVec = normalize(normalize(objectEyePos-Pos) + SkinnedLVec);
	vec3 nrmSkinnedLVec = normalize(SkinnedLVec);
	outdata.SkinnedLVec.xyz = nrmSkinnedLVec;
	//outdata.SkinnedLDir = SkinnedLDir;
	
	// Skinnedmeshes are highly tesselated, so..
	scalar radialAtt = 1-saturate(dot(SkinnedLVec,SkinnedLVec)*attenuationSqrInv);
	scalar offCenter = dot(nrmSkinnedLVec, SkinnedLDir);
	scalar conicalAtt = saturate(offCenter-(1-coneAngle))/coneAngle;
	outdata.SkinnedLVec.w = radialAtt * conicalAtt;
	
	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

vec4 PShader_SpotLightPP(VS2PS_SpotLight_PP indata) : COLOR
{	
	//vec3 normalizedLVec = normalize(indata.SkinnedLVec);	
	//scalar radialAtt = 1-saturate(dot(indata.SkinnedLVec,indata.SkinnedLVec)*attenuationSqrInv);
	//scalar offCenter = dot(normalizedLVec, normalize(indata.SkinnedLDir));
	//scalar conicalAtt = saturate(offCenter-(1-coneAngle))/coneAngle;

	vec4 expandedNormal = tex2D(sampler1, indata.Tex0);
	expandedNormal.xyz = (expandedNormal.xyz * 2) - 1;
	vec2 intensityuv = vec2(dot(indata.SkinnedLVec,expandedNormal), dot(indata.HalfVec,expandedNormal));
	vec4 realintensity = vec4(intensityuv.rrr,pow(intensityuv.g,36)*expandedNormal.a);
	realintensity.rgb *= lightColor;
	return realintensity * indata.SkinnedLVec.w;//* conicalAtt * radialAtt;
}

//
// Max 2 bones skinning supported!
//
VertexShader vsArray_SpotLightPP[2] = { compile vs_1_1 VShader_SpotLightPP(1), 
                            compile vs_1_1 VShader_SpotLightPP(2)
                           };


#if !_FORCE_1_4_SHADERS_
technique t0_SpotLightPP
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

		ZWriteEnable = FALSE;
		ZFunc = EQUAL;
	
		VertexShader = (vsArray_SpotLightPP[1]);
		PixelShader = compile PS2_EXT PShader_SpotLightPP();
	}
}
#endif

// pp tangent based lighting

VS2PS_SpotLight_PP VShader_SpotLightPPtangent(APP2VStangent indata, uniform int NumBones)
{
	VS2PS_SpotLight_PP outdata;
	vec3 Pos, Normal, SkinnedLVec, SkinnedLDir;
	
	skinSoldierForSpotPPtangent(NumBones, indata, lightPos, lightDir, Pos, Normal, SkinnedLVec, SkinnedLDir,outdata.HalfVec);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 
	vec4 wPos = mul(vec4(Pos.xyz, 1.0), mWorld); 
	
	//[TS:040201] Please note that "normalize(worldEyePos-wPos") is in worldspace while "SkinnedLVec" is in SkinnedSpace/ObjectSpace can this be correct??
	//outdata.HalfVec = normalize(normalize(worldEyePos-wPos) + SkinnedLVec);
	outdata.HalfVec = normalize(normalize(objectEyePos-Pos) + SkinnedLVec);
	vec3 nrmSkinnedLVec = normalize(SkinnedLVec);
	outdata.SkinnedLVec.xyz = nrmSkinnedLVec;
	//outdata.SkinnedLDir = SkinnedLDir;
	
	// Skinnedmeshes are highly tesselated, so..
	scalar radialAtt = 1-saturate(dot(SkinnedLVec,SkinnedLVec)*attenuationSqrInv);
	scalar offCenter = dot(nrmSkinnedLVec, SkinnedLDir);
	scalar conicalAtt = saturate(offCenter-(1-coneAngle))/coneAngle;
	outdata.SkinnedLVec.w = radialAtt * conicalAtt;
	
	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

//
// Max 2 bones skinning supported!
//
VertexShader vsArray_SpotLightPPtangent[2] = { compile vs_1_1 VShader_SpotLightPPtangent(1), 
                            compile vs_1_1 VShader_SpotLightPPtangent(2)
                           };


#if !_FORCE_1_4_SHADERS_
technique t0_SpotLightPPtangent
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = ONE;
		DestBlend = ONE;

		ZWriteEnable = FALSE;
		ZFunc = EQUAL;
	
		VertexShader = (vsArray_SpotLightPPtangent[1]);
		PixelShader = compile PS2_EXT PShader_SpotLightPP();
	}
}
#endif

struct VS2PS_MulDiffuse
{
	vec4	Pos		: POSITION;
	vec2	Tex0		: TEXCOORD0;
};

VS2PS_MulDiffuse VShader_MulDiffuse(APP2VS indata, uniform int NumBones)
{
	VS2PS_MulDiffuse outdata;
	vec3 Pos, Normal;
	
	skinSoldierForPV(NumBones, indata, Pos, Normal);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0f), mWorldViewProj); 

	outdata.Tex0 = indata.TexCoord0;
	
	return outdata;
}

vec4 PShader_MulDiffuse(VS2PS_MulDiffuse indata) : COLOR
{
	return tex2D(sampler0, indata.Tex0);
}

//
// Max 2 bones skinning supported!
//
VertexShader vsArray_MulDiffuse[2] = { compile vs_1_1 VShader_MulDiffuse(1), 
                            compile vs_1_1 VShader_MulDiffuse(2)
                           };


technique t0_MulDiffuse
{
	pass p0
	{
		AlphaBlendEnable = TRUE;
		SrcBlend = DESTCOLOR;
		DestBlend = ZERO;
		//DestBlend = ONE;

		ZWriteEnable = FALSE;
		ZFunc = EQUAL;

		VertexShader = (vsArray_MulDiffuse[1]);
		PixelShader = compile ps_1_1 PShader_MulDiffuse();
	}
}

//----------------
// humanskin
//----------------

struct VS2PS_Skinpre
{
	vec4	Pos				: POSITION;
	vec2	Tex0			: TEXCOORD0;
	vec3	SkinnedLVec		: TEXCOORD1;
	vec3	ObjEyeVec		: TEXCOORD2;
	vec3	GroundUVAndLerp : TEXCOORD3;
};

VS2PS_Skinpre vsSkinpre(APP2VS indata, uniform int NumBones)
{
	VS2PS_Skinpre outdata;
	vec3 Pos, Normal;
	
	skinSoldierForPP(NumBones, indata, -sunLightDir, Pos, Normal, outdata.SkinnedLVec);

	outdata.ObjEyeVec = normalize(objectEyePos-Pos);

	outdata.Pos.xy = indata.TexCoord0 * vec2(2,-2) - vec2(1, -1);
	outdata.Pos.zw = vec2(0, 1);

 	// Hemi lookup values
	vec4 wPos = mul(Pos, mWorld); 
 	outdata.GroundUVAndLerp.xy = ((wPos +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy)/ hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;
	
	outdata.Tex0 = indata.TexCoord0;
	outdata.SkinnedLVec = normalize(outdata.SkinnedLVec);
	
	return outdata;
}

vec4 psSkinpre(VS2PS_Skinpre indata) : COLOR
{
	//return vec4(indata.ObjEyeVec,0);
	vec4 expnormal = tex2D(sampler0, indata.Tex0);
	vec4 groundcolor = tex2D(sampler1, indata.GroundUVAndLerp.xy);
	
	expnormal.rgb = (expnormal * 2) - 1;
	scalar wrapDiff = dot(expnormal, indata.SkinnedLVec) + 0.5;
	wrapDiff = saturate(wrapDiff / 1.5);

	scalar rimDiff = 1-dot(expnormal, indata.ObjEyeVec);
	rimDiff = pow(rimDiff,3);

	rimDiff *= saturate(0.75-saturate(dot(indata.ObjEyeVec, indata.SkinnedLVec)));
	//rimDiff *= saturate(0.1-saturate(dot(indata.ObjEyeVec, normalize(indata.SkinnedLVec))));
	
	return vec4((wrapDiff.rrr + rimDiff)*groundcolor.a*groundcolor.a, expnormal.a);
}

struct VS2PS_Skinpreshadowed
{
	vec4	Pos				: POSITION;
	vec4	Tex0AndHZW		: TEXCOORD0;
	vec3	SkinnedLVec		: TEXCOORD1;
	vec4	ShadowTex		: TEXCOORD2;
	vec3	ObjEyeVec		: TEXCOORD3;
};

VS2PS_Skinpreshadowed vsSkinpreshadowed(APP2VS indata, uniform int NumBones)
{
	VS2PS_Skinpreshadowed outdata;
	vec3 Pos, Normal;
	
	// don't need as much code for this case.. will rewrite later
	skinSoldierForPP(NumBones, indata, -sunLightDir, Pos, Normal, outdata.SkinnedLVec);

	outdata.ObjEyeVec = normalize(objectEyePos-Pos);

	outdata.ShadowTex = mul(vec4(Pos, 1), mLightVP);
	outdata.ShadowTex.z -= 0.007;

	outdata.Pos.xy = indata.TexCoord0 * vec2(2,-2) - vec2(1, -1);
	outdata.Pos.zw = vec2(0, 1);
	outdata.Tex0AndHZW/*.xy*/ = indata.TexCoord0.xyyy;
	
	return outdata;
}

vec4 psSkinpreshadowed(VS2PS_Skinpreshadowed indata) : COLOR
{
	vec4 expnormal = tex2D(sampler0, indata.Tex0AndHZW);
	expnormal.rgb = (expnormal * 2) - 1;

	scalar wrapDiff = dot(expnormal, indata.SkinnedLVec) + 0.5;
	wrapDiff = saturate(wrapDiff / 1.5);

	scalar rimDiff = 1-dot(expnormal, indata.ObjEyeVec);
	rimDiff = pow(rimDiff,3);
	rimDiff *= saturate(0.75-saturate(dot(indata.ObjEyeVec, indata.SkinnedLVec)));

	vec2 texel = vec2(1.0/1024.0, 1.0/1024.0);
	vec4 samples;
	//indata.ShadowTex.xy = clamp(indata.ShadowTex.xy, vViewportMap.xy, vViewportMap.zw);
	samples.x = tex2D(sampler2point, indata.ShadowTex);
	samples.y = tex2D(sampler2point, indata.ShadowTex + vec2(texel.x, 0));
	samples.z = tex2D(sampler2point, indata.ShadowTex + vec2(0, texel.y));
	samples.w = tex2D(sampler2point, indata.ShadowTex + texel);
	
	vec4 staticSamples;
	staticSamples.x = tex2D(sampler1, indata.ShadowTex + vec2(-texel.x*1, -texel.y*2)).b;
	staticSamples.y = tex2D(sampler1, indata.ShadowTex + vec2( texel.x*1, -texel.y*2)).b;
	staticSamples.z = tex2D(sampler1, indata.ShadowTex + vec2(-texel.x*1,  texel.y*2)).b;
	staticSamples.w = tex2D(sampler1, indata.ShadowTex + vec2( texel.x*1,  texel.y*2)).b;
	staticSamples.x = dot(staticSamples.xyzw, 0.25);
	
	vec4 cmpbits = samples > saturate(indata.ShadowTex.z);
	scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));

	scalar totShadow = avgShadowValue.x*staticSamples.x;
	scalar totDiff = wrapDiff + rimDiff;
	return vec4(totDiff, totShadow, saturate(totShadow+0.35), expnormal.a);
}

vec4 psSkinpreshadowedNV(VS2PS_Skinpreshadowed indata) : COLOR
{
	vec4 expnormal = tex2D(sampler0, indata.Tex0AndHZW);
	expnormal.rgb = (expnormal * 2) - 1;

	scalar wrapDiff = dot(expnormal, indata.SkinnedLVec) + 0.5;
	wrapDiff = saturate(wrapDiff / 1.5);

	scalar rimDiff = 1-dot(expnormal, indata.ObjEyeVec);
	rimDiff = pow(rimDiff,3);
	rimDiff *= saturate(0.75-saturate(dot(indata.ObjEyeVec, indata.SkinnedLVec)));

	vec2 texel = vec2(1.0/1024.0, 1.0/1024.0);
	scalar avgShadowValue = tex2Dproj(sampler2, indata.ShadowTex); // HW percentage closer filtering.
	
	vec4 staticSamples;
	//indata.ShadowTex.xy = clamp(indata.ShadowTex.xy, vViewportMap.xy, vViewportMap.zw);
	staticSamples.x = tex2D(sampler1, indata.ShadowTex + vec2(-texel.x*1, -texel.y*2)).b;
	staticSamples.y = tex2D(sampler1, indata.ShadowTex + vec2( texel.x*1, -texel.y*2)).b;
	staticSamples.z = tex2D(sampler1, indata.ShadowTex + vec2(-texel.x*1,  texel.y*2)).b;
	staticSamples.w = tex2D(sampler1, indata.ShadowTex + vec2( texel.x*1,  texel.y*2)).b;
	staticSamples.x = dot(staticSamples.xyzw, 0.25);
	
	//vec4 cmpbits = samples > saturate(indata.ShadowTex.z);
	//scalar avgShadowValue = dot(cmpbits, vec4(0.25, 0.25, 0.25, 0.25));

	scalar totShadow = avgShadowValue.x*staticSamples.x;
	scalar totDiff = wrapDiff + rimDiff;
	return vec4(totDiff, totShadow, saturate(totShadow+0.35), expnormal.a);
}

VS2PS_PP vsSkinapply(APP2VS indata, uniform int NumBones)
{
	VS2PS_PP outdata;
	
	vec3 Pos,Normal;
	
	skinSoldierForPP(NumBones, indata, -sunLightDir, Pos, Normal, outdata.SkinnedLVec);
	
	// Transform position into view and then projection space
	outdata.Pos = mul(vec4(Pos.xyz, 1.0f), mWorldViewProj); 

 	// Hemi lookup values
	vec4 wPos = mul(Pos, mWorld); 
 	outdata.GroundUVAndLerp.xy = ((wPos +(hemiMapInfo.z/2) + Normal*1/*normalOffsetScale*/).xz - hemiMapInfo.xy)/ hemiMapInfo.z;
	outdata.GroundUVAndLerp.y = 1-outdata.GroundUVAndLerp.y;
	outdata.GroundUVAndLerp.z = (Normal.y+1/*normalOffsetScale*/)/2;
	outdata.GroundUVAndLerp.z -= hemiMapInfo.w;

	outdata.Tex0 = indata.TexCoord0;
	outdata.HalfVec = normalize(normalize(objectEyePos-Pos) + outdata.SkinnedLVec);
	outdata.SkinnedLVec = normalize(outdata.SkinnedLVec);

	
	return outdata;
}

vec4 psSkinapply(VS2PS_PP indata) : COLOR
{
	//return vec4(1,1,1,1);
	vec4 groundcolor = tex2D(sampler0, indata.GroundUVAndLerp.xy);
	//return groundcolor;
	vec4 hemicolor = lerp(groundcolor, skyColor, indata.GroundUVAndLerp.z);
	vec4 expnormal = tex2D(sampler1, indata.Tex0);
	expnormal.rgb = (expnormal * 2) - 1;
	vec4 diffuse = tex2D(sampler2, indata.Tex0);
	vec4 diffuseLight = tex2D(sampler3, indata.Tex0);
//return diffuseLight;
	// glossmap is in the diffuse alpha channel.
	scalar specular = pow(dot(expnormal.rgb, indata.HalfVec), 16)*diffuse.a;

	vec4 totalcolor = saturate(ambientColor*hemicolor + diffuseLight.r*diffuseLight.b*sunColor);
	//return totalcolor;
	totalcolor *= diffuse;//+specular;

	// what to do what the shadow???
	scalar shadowIntensity = saturate(diffuseLight.g/*+ShadowIntensityBias*/);
	totalcolor.rgb += specular* shadowIntensity*shadowIntensity;

	return totalcolor;
}


#if !_FORCE_1_4_SHADERS_
technique humanskinNV
{
	pass pre
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_1_1 vsSkinpre(2);
		PixelShader = compile PS2_EXT psSkinpre();
	}
	pass preshadowed
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_1_1 vsSkinpreshadowed(2);
		PixelShader = compile PS2_EXT psSkinpreshadowedNV();
	}
	pass apply
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		StencilEnable = TRUE;
		StencilRef = (dwStencilRef);
		StencilFunc = ALWAYS;
		StencilZFail = KEEP;
		StencilPass = REPLACE;

		VertexShader = compile vs_1_1 vsSkinapply(2);
		PixelShader = compile PS2_EXT psSkinapply();
	}
}
#endif

#if !_FORCE_1_4_SHADERS_
technique humanskin
{
	pass pre
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_1_1 vsSkinpre(2);
		PixelShader = compile PS2_EXT psSkinpre();
	}
	pass preshadowed
	{
		CullMode = NONE;
		AlphaBlendEnable = FALSE;
		ZEnable = FALSE;
		ZWriteEnable = FALSE;
		ZFunc = LESSEQUAL;

		StencilEnable = FALSE;

		VertexShader = compile vs_1_1 vsSkinpreshadowed(2);
		PixelShader = compile PS2_EXT psSkinpreshadowed();
	}
	pass apply
	{
		CullMode = CCW;
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		//FillMode = WIREFRAME;

		VertexShader = compile vs_1_1 vsSkinapply(2);
		PixelShader = compile PS2_EXT psSkinapply();
	}
}
#endif


struct VS2PS_ShadowMap
{
	vec4	Pos		: POSITION;
	vec2	PosZW	: TEXCOORD0;
};

VS2PS_ShadowMap vsShadowMap(APP2VS indata)
{
	VS2PS_ShadowMap outdata;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	vec3 Pos = mul(indata.Pos, mBoneArray[IndexArray[0]]) * BlendWeightsArray[0];
	Pos += mul(indata.Pos, mBoneArray[IndexArray[1]]) * (1-BlendWeightsArray[0]);
	
 	outdata.Pos = mul(vec4(Pos.xyz, 1.0), vpLightTrapezMat);
 	vec2 lightZW = mul(vec4(Pos.xyz, 1.0), vpLightMat).zw;
	outdata.Pos.z = (lightZW.x*outdata.Pos.w)/lightZW.y;			// (zL*wT)/wL == zL/wL post homo
 	outdata.PosZW = outdata.Pos.zw;

 	return outdata;

//SHADOW
// TBD: mul matrices on CPU	
/*	matrix m = mul( vpLightMat, vpLightTrapezMat );
	outdata.Pos = mul( vec4(Pos.xyz, 1.0), m );
*/	outdata.Pos = mul( vec4(Pos.xyz, 1.0), vpLightMat );
 	outdata.PosZW = outdata.Pos.zw;	
//\SHADOW	
	return outdata;
}

vec4 psShadowMap(VS2PS_ShadowMap indata) : COLOR
{
#if NVIDIA
	return 0;
#else
	return indata.PosZW.x / indata.PosZW.y;
#endif
}


struct VS2PS_ShadowMapAlpha
{
	vec4	Pos		: POSITION;
	vec4	Tex0PosZW	: TEXCOORD0;
};

VS2PS_ShadowMapAlpha vsShadowMapAlpha(APP2VS indata)
{
	VS2PS_ShadowMapAlpha outdata;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	vec3 Pos = mul(indata.Pos, mBoneArray[IndexArray[0]]) * BlendWeightsArray[0];
	Pos += mul(indata.Pos, mBoneArray[IndexArray[1]]) * (1-BlendWeightsArray[0]);
	

 	outdata.Pos = mul(vec4(Pos.xyz, 1.0), vpLightTrapezMat);
 	vec2 lightZW = mul(vec4(Pos.xyz, 1.0), vpLightMat).zw;
	outdata.Pos.z = (lightZW.x*outdata.Pos.w)/lightZW.y;			// (zL*wT)/wL == zL/wL post homo
 	outdata.Tex0PosZW.xy = indata.TexCoord0;
 	outdata.Tex0PosZW.zw = outdata.Pos.zw;

 	return outdata;

//SHADOW
/*	matrix m = mul( vpLightMat, vpLightTrapezMat );
	outdata.Pos = mul( vec4(Pos.xyz, 1.0), m );
	outdata.Pos = mul( vec4(Pos.xyz, 1.0), vpLightMat );
 	outdata.Tex0PosZW.zw = outdata.Pos.zw;
*/	
//\SHADOW

	return outdata;
}

vec4 psShadowMapAlpha(VS2PS_ShadowMapAlpha indata) : COLOR
{
	scalar alpha = tex2D(sampler0, indata.Tex0PosZW.xy).a-shadowAlphaThreshold;

#if NVIDIA
	return alpha;
#else
	clip( alpha );
	return indata.Tex0PosZW.z / indata.Tex0PosZW.w;
#endif
}

vec4 psShadowMapAlphaNV(VS2PS_ShadowMapAlpha indata) : COLOR
{
// spot-shadows
	clip(tex2D(sampler0, indata.Tex0PosZW.xy).a-shadowAlphaThreshold);
//SHADOW
;;	return indata.Tex0PosZW.z / indata.Tex0PosZW.w;
//\SHADOW
	return tex2D(sampler0, indata.Tex0PosZW.xy).a-shadowAlphaThreshold;
}

VS2PS_ShadowMap vsShadowMapPoint(APP2VS indata)
{
	VS2PS_ShadowMap outdata;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	vec3 Pos = mul(indata.Pos, mBoneArray[IndexArray[0]]) * BlendWeightsArray[0];
	Pos += mul(indata.Pos, mBoneArray[IndexArray[1]]) * (1-BlendWeightsArray[0]);
	
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 
	
 	outdata.Pos.z *= paraboloidValues.x;
 	scalar d = length(outdata.Pos.xyz);
 	
 	outdata.Pos.xyz /= d;
	outdata.Pos.z += 1;
 	outdata.Pos.x /= outdata.Pos.z;
 	outdata.Pos.y /= outdata.Pos.z;
 	
	outdata.Pos.z = (d*paraboloidZValues.x) + paraboloidZValues.y;
	outdata.Pos.w = 1;
	
	outdata.PosZW = outdata.Pos.zw;

 	return outdata;

//SHADOW
// TBD: mul matrices on CPU
/*	matrix m = mul( vpLightMat, vpLightTrapezMat );
	outdata.Pos = mul( vec4(Pos.xyz, 1.0), m );
*/	outdata.Pos = mul( vec4(Pos.xyz, 1.0), vpLightMat );
 	outdata.PosZW = outdata.Pos.zw;
	
//\SHADOW

	return outdata;
}

VS2PS_ShadowMap vsShadowMapPointNV(APP2VS indata)
{
	VS2PS_ShadowMap outdata;
	
	// Compensate for lack of UBYTE4 on Geforce3
	int4 IndexVector = D3DCOLORtoUBYTE4(indata.BlendIndices);
	
	// Cast the vectors to arrays for use in the for loop below
	scalar BlendWeightsArray[1] = (scalar[1])indata.BlendWeights;
	int IndexArray[4] = (int[4])IndexVector;    
	
	vec3 Pos = mul(indata.Pos, mBoneArray[IndexArray[0]]) * BlendWeightsArray[0];
	Pos += mul(indata.Pos, mBoneArray[IndexArray[1]]) * (1-BlendWeightsArray[0]);
	
	outdata.Pos = mul(vec4(Pos.xyz, 1.0), mWorldViewProj); 
 	
	outdata.Pos.z *= paraboloidValues.x;
//outdata.PosZ = outdata.Pos.z/10.0 + 0.5;
//	outdata.PosZ = outdata.Pos.z/paraboloidZValues.z;
	
 	scalar d = length(outdata.Pos.xyz);
 	outdata.Pos.xyz /= d;
	outdata.Pos.z += 1;
 	outdata.Pos.x /= outdata.Pos.z;
 	outdata.Pos.y /= outdata.Pos.z;
	outdata.Pos.z = (d*paraboloidZValues.x) + paraboloidZValues.y;
	outdata.Pos.w = 1;
	
	outdata.PosZW = outdata.Pos.zw;

 	return outdata;

//SHADOW
/*	matrix m = mul( vpLightMat, vpLightTrapezMat );
 	outdata.Pos = mul( vec4(Pos.xyz, 1.0), m );
*/	outdata.Pos = mul( vec4(Pos.xyz, 1.0), vpLightMat );
	outdata.PosZW = outdata.Pos.zw;	
//\SHADOW

	return outdata;
}
/*
vec4 psShadowMapPoint(VS2PS_ShadowMap indata) : COLOR
{
	//clip(indata.PosZW.x-0.5);
	clip(indata.PosZW.x);
	return indata.PosZW.xxxx;// - 0.5;
}

vec4 psShadowMapPointNV(VS2PS_ShadowMap indata) : COLOR
{
//SHADOW
;;	return indata.PosZW.x / indata.PosZW.y;
//\SHADOW

// TBD: add clip to shadows
	clip(indata.PosZW.x);
	return indata.PosZW.xxxx;
}*/

vec4 psShadowMapNV(VS2PS_ShadowMap indata) : COLOR
{
	// directional-shadows

//SHADOW
;;	return indata.PosZW.x / indata.PosZW.y;
//\SHADOW

//	return indata.PosZW.x / indata.PosZW.y;
	return 0;
}

// Please find a better way under ps1.4 shaders !
// #if !_FORCE_1_4_SHADERS_
#if NVIDIA
	PixelShader psShadowMap_Compiled = compile ps_1_1 psShadowMap();
	PixelShader psShadowMapAlpha_Compiled = compile ps_1_1 psShadowMapAlpha();
#else
	PixelShader psShadowMap_Compiled = compile ps_2_0 psShadowMap();
	PixelShader psShadowMapAlpha_Compiled = compile ps_2_0 psShadowMapAlpha();
#endif


technique DrawShadowMap
{
	pass directionalspot
	{
#if NVIDIA
		ColorWriteEnable = 0;//0x0000000F;
#endif
	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		CullMode = CW;

		ScissorTestEnable = TRUE;

		VertexShader = compile vs_1_1 vsShadowMap();
		PixelShader = (psShadowMap_Compiled);

		CullMode = None;
	}

	pass directionalspotalpha
	{
#if NVIDIA
		ColorWriteEnable = 0;//0x0000000F;
#endif

#if NVIDIA
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
#endif
		
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		
		ScissorTestEnable = TRUE;

		VertexShader = compile vs_1_1 vsShadowMapAlpha();
		PixelShader = (psShadowMapAlpha_Compiled);
		
		CullMode = CCW;
		CullMode = None;
	}

	pass point
	{
#if NVIDIA
		ColorWriteEnable = 0;//0x0000000F;
#endif
		
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		ScissorTestEnable = TRUE;

		VertexShader = compile vs_1_1 vsShadowMap();
		PixelShader = (psShadowMap_Compiled);

		CullMode = None;
	}
}
//#endif

// Please find a better way under ps1.4 shaders !
// #if !_FORCE_1_4_SHADERS_

// We actually don't need to have 2 techniques here
// but it is kept for back-compatibility with original BF2
technique DrawShadowMapNV
{
	pass directionalspot
	{
#if NVIDIA
		ColorWriteEnable = 0;//0x0000000F;
#endif
	
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		CullMode = CW;

		ScissorTestEnable = TRUE;

		VertexShader = compile vs_1_1 vsShadowMap();
		PixelShader = (psShadowMap_Compiled);

		CullMode = None;
	}

	pass directionalspotalpha
	{	
#if NVIDIA
		ColorWriteEnable = 0;//0x0000000F;
#endif

#if NVIDIA
		AlphaTestEnable = TRUE;
		AlphaRef = 0;
#endif
		
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;
		
		ScissorTestEnable = TRUE;

		VertexShader = compile vs_1_1 vsShadowMapAlpha();
		PixelShader = (psShadowMapAlpha_Compiled);
		
		CullMode = CCW;
		CullMode = None;
	}

	pass point
	{
#if NVIDIA
		ColorWriteEnable = 0;//0x0000000F;
#endif
		
		AlphaBlendEnable = FALSE;
		ZEnable = TRUE;
		ZWriteEnable = TRUE;
		ZFunc = LESSEQUAL;

		ScissorTestEnable = TRUE;

		VertexShader = compile vs_1_1 vsShadowMap();
		PixelShader = (psShadowMap_Compiled);

		CullMode = None;
	}
}
//#endif

#include "shaders/SkinnedMesh_r3x0.fx"
