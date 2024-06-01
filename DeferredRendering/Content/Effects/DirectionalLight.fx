#if OPENGL
#define SV_POSITION POSITION
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_3
#endif

float3 LightPosition;
float3 LightColor;

// This is used to compute the world position
float4x4 InverseViewProjection;

// Diffuse color, and specularIntensity in the alpha channel
texture ColorMap; 
sampler colorSampler = sampler_state
{
    Texture = (ColorMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};

// Normals, and specularPower in the alpha channel
texture NormalMap; 
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

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output;
    output.Position = float4(input.Position, 1);
    output.TexCoord = input.TexCoord;
    output.ViewDir = normalize(mul(output.Position, InverseViewProjection).xyz);
    return output;
}

float4 PixelShaderFunction(VertexShaderOutput input) : COLOR0
{
    float4 normalData = tex2D(normalSampler, input.TexCoord);
    float3 normal = normalize(2.0f * normalData.xyz - 1.0f); // Get normal into [-1,1] range
    float specularPower = normalData.a * 255; // Get specular power, and get it into [0,255] range
    float specularIntensity = tex2D(colorSampler, input.TexCoord).a; // Get specular intensity from the colorMap
    float depth = tex2D(depthSampler, input.TexCoord).r; // Read depth
    
    // Compute world position
    float4 position = 1.0f;
    position.x = input.TexCoord.x * 2.0f - 1.0f;
    position.y = -(input.TexCoord.x * 2.0f - 1.0f);
    position.z = depth;
    position = mul(position, InverseViewProjection);
    position /= position.w;
    
    // Base vectors
    float3 lightDirection = normalize(LightPosition - position.xyz);
    float3 viewDirection = normalize(input.ViewDir);
    float3 halfVector = normalize(lightDirection + viewDirection);
    
    // Compute diffuse light
    float NdotL = saturate(dot(normal, lightDirection));
    float3 diffuseLight = LightColor * NdotL;
    
    // Compute specular light
    float NdotH = saturate(dot(normal, halfVector));
    float specularLight = specularIntensity * pow(NdotH, specularPower);
    
    // Output diffuse and specular
    return float4(diffuseLight, specularLight);
}

technique Technique1
{
    pass Pass0
    {
        VertexShader = compile VS_SHADERMODEL VertexShaderFunction();
        PixelShader = compile PS_SHADERMODEL PixelShaderFunction();
    }
}