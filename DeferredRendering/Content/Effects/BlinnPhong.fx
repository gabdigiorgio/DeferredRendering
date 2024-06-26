﻿#if OPENGL
#define SV_POSITION POSITION
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_3
#endif

// Matrices
float4x4 World;
float4x4 View;
float4x4 Projection;
float4x4 InverseTransposeWorld;
 
// Light related
float3 Color;

float3 LightPosition;
float3 EyePosition;

float3 AmbientColor;
float KAmbient;
 
float3 DiffuseColor;
float KDiffuse;

float3 SpecularColor;
float KSpecular;
float Shininess;

float2 Tiling;

texture BaseTexture;
sampler2D textureSampler = sampler_state
{
    Texture = (BaseTexture);
    MagFilter = Linear;
    MinFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};
 
struct VertexShaderInput
{
    float4 Position : POSITION0;
    float4 Normal : NORMAL;
    float2 TextureCoordinates : TEXCOORD0;
};
 
struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float3 WorldPosition : TEXCOORD0;
    float3 Normal : TEXCOORD1;
    float2 TextureCoordinates : TEXCOORD2;
};
 
VertexShaderOutput MainVS(VertexShaderInput input)
{
    VertexShaderOutput output = (VertexShaderOutput) 0;
 
    float4 worldPosition = mul(input.Position, World);
    float4 viewPosition = mul(worldPosition, View);
    output.Position = mul(viewPosition, Projection);
    output.WorldPosition = worldPosition;
    output.Normal = input.Normal;
    output.TextureCoordinates = input.TextureCoordinates * Tiling;
    
    return output;
}
 
float4 MainColorPS(VertexShaderOutput input) : COLOR0
{
    float3 lightDirection = normalize(LightPosition - input.WorldPosition);
    float3 viewDirection = normalize(EyePosition - input.WorldPosition);
    float3 halfVector = normalize(lightDirection + viewDirection); 
    
    float3 ambientLight = KAmbient * AmbientColor;
    
    float NdotL = saturate(dot(input.Normal, lightDirection));
    float3 diffuseLight = KDiffuse * DiffuseColor * NdotL;
    
    float NdotH = saturate(dot(input.Normal, halfVector));
    float3 specularLight = sign(NdotL) * KSpecular * SpecularColor * pow(NdotH, Shininess);

    float4 finalColor = float4((ambientLight + diffuseLight) * Color + specularLight, 1.0);
    
    return finalColor;
}

float4 MainTexturePS(VertexShaderOutput input) : COLOR0
{
    float4 texelColor = tex2D(textureSampler, input.TextureCoordinates);
    
    float3 lightDirection = normalize(LightPosition - input.WorldPosition);
    float3 viewDirection = normalize(EyePosition - input.WorldPosition);
    float3 halfVector = normalize(lightDirection + viewDirection);
    
    float3 ambientLight = KAmbient * AmbientColor;
    
    float NdotL = saturate(dot(input.Normal, lightDirection));
    float3 diffuseLight = KDiffuse * DiffuseColor * NdotL;
    
    float NdotH = saturate(dot(input.Normal, halfVector));
    float3 specularLight = sign(NdotL) * KSpecular * SpecularColor * pow(NdotH, Shininess);

    float4 finalColor = float4((ambientLight + diffuseLight) * texelColor.rgb + specularLight, 1.0);
    
    return finalColor;
}

 
technique BasicColorDrawing
{
    pass Pass0
    {
        VertexShader = compile VS_SHADERMODEL MainVS();
        PixelShader = compile PS_SHADERMODEL MainColorPS();
    }
}

technique BasicTextureDrawing
{
    pass Pass0
    {
        VertexShader = compile VS_SHADERMODEL MainVS();
        PixelShader = compile PS_SHADERMODEL MainTexturePS();
    }
}