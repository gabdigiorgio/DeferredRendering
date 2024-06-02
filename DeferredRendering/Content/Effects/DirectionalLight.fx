#include "ShaderUtilities.fx"

//color of the light 
float3 LightColor;

//position of the camera, for specular light
float3 cameraPosition = float3(0, 0, 0);

//this is used to compute the world-position
float4x4 InvertViewProjection;

float3 LightVector;
//control the brightness of the light
float lightIntensity = 11.0f;

// Diffuse color, and specularIntensity in the alpha channel
Texture2D AlbedoMap;
sampler colorSampler = sampler_state
{
    Texture = (AlbedoMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};

// Normals, and specularPower in the alpha channel
Texture2D NormalMap;
sampler normalSampler = sampler_state
{
    Texture = (NormalMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
};

// Depth
texture DepthMap; 
sampler depthSampler = sampler_state
{
    Texture = (DepthMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
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
    float3 ViewDir : TEXCOORD1;
};

struct PixelShaderOutput
{
    float4 Diffuse : COLOR0;
    float4 Specular : COLOR1;
};

VertexShaderOutput MainVS(VertexShaderInput input)
{
    VertexShaderOutput output;
    
    output.Position = float4(input.Position, 1);
    output.TexCoord = input.TexCoord;
    output.ViewDir = normalize(mul(output.Position, InvertViewProjection).xyz);
    
    return output;
}

PixelShaderOutput MainPS(VertexShaderOutput input) : COLOR0
{
    PixelShaderOutput output;
    float2 texCoord = float2(input.TexCoord);
    
    // get normal data from the NormalMap
    float4 normalData = NormalMap.Sample(normalSampler, texCoord);
    
    // tranform normal back into [-1,1] range
    float3 normal = decode(normalData.xyz); //2.0f * normalData.xyz - 1.0f;

    [branch]
    if (normalData.x + normalData.y <= 0.001f) //Out of range
    {
        output.Diffuse = float4(0, 0, 0, 0);
        output.Specular = float4(0, 0, 0, 0);
        return output;
    }
    else
    {
        //get metalness
        float roughness = normalData.a;
        
        //get specular intensity from the AlbedoMap
        float4 color = AlbedoMap.Sample(colorSampler, texCoord);

        float metalness = decodeMetalness(color.a);
    
        float f0 = lerp(0.04f, color.g * 0.25 + 0.75, metalness);

        float3 cameraDirection = -normalize(input.ViewDir);

        float NdotL = saturate(dot(normal, -LightVector));

        //float3 diffuse = DiffuseLambert(NdotL, LightColor, lightIntensity);
        float3 diffuse = DiffuseOrenNayar(NdotL, normal, -LightVector, cameraDirection, lightIntensity, LightColor, roughness);
    
        float3 specular = SpecularCookTorrance(NdotL, normal, -LightVector, cameraDirection, lightIntensity, LightColor, f0, roughness);

        output.Diffuse = float4(diffuse, 0) * (1 - f0) * 0.01f;
        output.Specular = float4(specular, 0) * 0.01f;

        return output;
    }
}

technique Default
{
    pass P0
    {
        VertexShader = compile vs_5_0 MainVS();
        PixelShader = compile ps_5_0 MainPS();
    }
}