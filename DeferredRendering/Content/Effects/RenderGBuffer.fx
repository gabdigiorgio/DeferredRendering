#include "ShaderUtilities.fx"

float4x4 World;
float4x4 View;
float4x4 WorldViewProjection;

float Roughness = 0.3f; // 0 : smooth, 1: rough
float Metallic = 0;

int MaterialType = 0;

float4 DiffuseColor = float4(0.8f, 0.8f, 0.8f, 1);

struct VertexShaderInput
{
    float4 Position : SV_POSITION0;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
};

struct VertexShaderOutput
{
    float4 Position : SV_POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : TEXCOORD1;
    float2 Depth : TEXCOORD2;
};

struct RenderIn
{
    float4 Position : SV_POSITION0;
    float4 Color : COLOR0;
    float3 Normal : TEXCOORD0;
    float2 Depth : TEXCOORD1;
    float Metallic : TEXCOORD2;
    float Roughness : TEXCOORD3;
};

struct PixelShaderOutput
{
    float4 Color : COLOR0;
    float4 Normal : COLOR1;
    float4 Depth : COLOR2;
};

VertexShaderOutput MainVS(VertexShaderInput input)
{
    VertexShaderOutput output;

    output.Position = mul(input.Position, WorldViewProjection);
    output.Normal = mul(float4(input.Normal, 0), World).xyz;
    output.TexCoord = input.TexCoord;
    output.Depth = float2(output.Position.z, output.Position.w);
    
    return output;
}

PixelShaderOutput Lighting(RenderIn input)
{               
    PixelShaderOutput Out;

    Out.Color = input.Color;
    Out.Color.a = encodeMetallicMattype(input.Metallic, MaterialType);
    Out.Normal.rgb = encode(input.Normal);
    Out.Normal.a = input.Roughness;
    Out.Depth = 1 - input.Depth.x / input.Depth.y;

    return Out;
}

PixelShaderOutput MainPS(VertexShaderOutput input)
{
    RenderIn renderParams;
    
    renderParams.Position = input.Position;
    renderParams.Color = DiffuseColor;
    renderParams.Normal = normalize(input.Normal);
    renderParams.Depth = input.Depth;
    renderParams.Metallic = Metallic;
    renderParams.Roughness = Roughness;
    
    return Lighting(renderParams);
}

technique Default
{
    pass P0
    {
        VertexShader = compile vs_5_0 MainVS();
        PixelShader = compile ps_5_0 MainPS();
    }
}