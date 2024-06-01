#if OPENGL
#define SV_POSITION POSITION
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_1
#endif

float3 EyePosition;
float3 LightPosition;
float3 LightColor;

float4x4 InvertViewProjection; // this is used to compute the world-position

texture ColorMap; // diffuse color, and specularIntensity in the alpha channel
sampler colorSampler = sampler_state
{
    Texture = (ColorMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    Mipfilter = LINEAR;
};

texture NormalMap; // normals, and specularPower in the alpha channel
sampler normalSampler = sampler_state
{
    Texture = (NormalMap);
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = POINT;
    MinFilter = POINT;
    Mipfilter = POINT;
};

texture DepthMap; // depth
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
};

VertexShaderOutput VertexShaderFunction(VertexShaderInput input)
{
    VertexShaderOutput output;
    output.Position = float4(input.Position, 1);
    output.TexCoord = input.TexCoord;
    return output;
}

float4 PixelShaderFunction(VertexShaderOutput input) : COLOR0
{
    float4 normalData = tex2D(normalSampler,input.TexCoord);
    float3 normal = 2.0f * normalData.xyz - 1.0f; // get normal into [-1,1] range
    float specularPower = normalData.a * 255; // get specular power, and get it into [0,255] range
    float specularIntensity = tex2D(colorSampler, input.TexCoord).a; // get specular intensity from the colorMap
    float depthVal = tex2D(depthSampler, input.TexCoord).r; // read depth
    
    // compute screen-space position
    float4 position;
    position.x = input.TexCoord.x * 2.0f - 1.0f;
    position.y = -(input.TexCoord.x * 2.0f - 1.0f);
    position.z = depthVal;
    position.w = 1.0f;
    
    //transform to world space
    position = mul(position, InvertViewProjection);
    position /= position.w;
    
    // Base vectors
    float3 lightDirection = normalize(LightPosition - position.xyz);
    float3 viewDirection = normalize(EyePosition - position.xyz);
    float3 halfVector = normalize(lightDirection + viewDirection);
    
    // compute diffuse light
    float NdotL = saturate(dot(normal, lightDirection));
    float3 diffuseLight = LightColor.rgb * NdotL;
    
    float NdotH = saturate(dot(normal, halfVector));
    
    //compute specular light
    float specularLight = specularIntensity * pow(NdotH, specularPower);
    
    //output the two lights
    return float4(diffuseLight.rgb, specularLight);
}

technique Technique1
{
    pass Pass0
    {
        VertexShader = compile VS_SHADERMODEL VertexShaderFunction();
        PixelShader = compile PS_SHADERMODEL PixelShaderFunction();
    }
}