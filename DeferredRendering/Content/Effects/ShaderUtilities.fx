float3 encode(float3 n)
{
    return 0.5f * (n + 1.0f);
}

float3 decode(float3 n)
{
    return 2.0f * n.xyz - 1.0f;
}

float encodeMetallicMattype(float metalness, float mattype)
{
    return metalness * 0.1f * 0.5f + mattype * 0.1f;
}

float decodeMetalness(float input)
{
    input *= 10;
    return frac(input) * 2;
}

float decodeMattype(float input)
{
    input *= 10;
    return trunc(input);
}

float3 DiffuseLambert(float NdotL, float3 lightColor, float lightIntensity)
{
    float diffuse = max(0.0, NdotL);
    
    return diffuse * lightColor * lightIntensity;
}

float3 DiffuseOrenNayar(float NdotL, float3 normal, float3 lightDirection, float3 cameraDirection, float lightIntensity, float3 lightColor, float roughness)
{
    const float PI = 3.14159;
    
    // calculate intermediary values
    float NdotV = dot(normal, cameraDirection);

    float angleVN = acos(NdotV);
    float angleLN = acos(NdotL);
    
    float alpha = max(angleVN, angleLN);
    float beta = min(angleVN, angleLN);
    float gamma = dot(cameraDirection - normal * NdotV, lightDirection - normal * NdotL);
    
    float roughnessSquared = roughness * roughness;
    
    // calculate A and B
    float A = 1.0 - 0.5 * (roughnessSquared / (roughnessSquared + 0.57));

    float B = 0.45 * (roughnessSquared / (roughnessSquared + 0.09));
 
    float C = sin(alpha) * tan(beta);
    
    // put it all together
    float L1 = max(0.0, NdotL) * (A + B * max(0.0, gamma) * C);
    
    // get the final color 
    return L1 * lightColor * lightIntensity / 4;
}

float3 SpecularCookTorrance(float NdotL, float3 normal, float3 negativeLightDirection, float3 cameraDirectionP, float diffuseIntensity, float3 diffuseColor, float f0, float roughness)
{
    float3 specular = float3(0, 0, 0);

    [branch]
    if (NdotL > 0.0f)
    {
        float3 halfVector = normalize(negativeLightDirection + cameraDirectionP);

        float NdotH = saturate(dot(normal, halfVector));
        float NdotV = saturate(dot(normal, cameraDirectionP));
        float VdotH = saturate(dot(cameraDirectionP, halfVector));
        float mSquared = roughness * roughness;


        // Trowbridge-Reitz
        float D_lowerTerm = (NdotH * NdotH * (mSquared * mSquared - 1) + 1);
        float D = mSquared * mSquared / (3.14 * D_lowerTerm * D_lowerTerm);

        // Fresnel (Schlick)
        float F = pow(1.0 - VdotH, 5.0);
        F *= (1.0 - f0);
        F += f0;

        // Schlick Smith
        float k = (roughness + 1) * (roughness + 1) / 8;
        float g_v = NdotV / (NdotV * (1 - k) + k);
        float g_l = NdotL / (NdotL * (1 - k) + k);

        float G = g_l * g_v;

        specular = max(0, (D * F * G) / (4 * NdotV * NdotL)) * diffuseIntensity * diffuseColor * NdotL;
    }
    return specular;
}