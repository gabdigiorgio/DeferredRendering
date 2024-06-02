#if OPENGL
#define SV_POSITION POSITION
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_3
#endif

#include "ShaderUtilities.fx"

Texture2D ColorMap;
sampler colorSampler = sampler_state
{
    Texture = (ColorMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};

Texture2D DiffuseLightMap;
sampler diffuseLightSampler = sampler_state
{
    Texture = (DiffuseLightMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};

Texture2D SpecularLightMap;
sampler specularLightSampler = sampler_state
{
    Texture = (SpecularLightMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};

struct VertexShaderInput
{
    float3 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct VertexShaderOutput
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output;
    output.Position = float4(input.Position, 1.0f);
    output.TexCoord = input.TexCoord;
    return output;
}

float4 PixelShaderFunction(VertexShaderOutput input) : COLOR0
{
    float4 diffuseColor = ColorMap.Sample(colorSampler, input.TexCoord);
    float albedoColorProp = diffuseColor.a;
    float materialType = decodeMattype(albedoColorProp);
    float metalness = decodeMetalness(albedoColorProp);
    
    float f0 = lerp(0.44f, diffuseColor.g * 0.25f + 0.75f, metalness);
    
    float3 diffuseLight = DiffuseLightMap.Sample(diffuseLightSampler, input.TexCoord);
    float3 specularLight = SpecularLightMap.Sample(specularLightSampler, input.TexCoord);

    float3 plasticFinal = diffuseColor.rgb * (diffuseLight) + specularLight;
                  
    float3 metalFinal = specularLight * diffuseColor.rgb;

    float3 finalValue = lerp(plasticFinal, metalFinal, metalness);
    
    float exposure = 20.0f;

    return float4(finalValue, 1.0f) * exposure;
}

technique Default
{
    pass P0
    {
        VertexShader = compile vs_5_0 VertexShaderFunction();
        PixelShader = compile ps_5_0 PixelShaderFunction();
    }
}