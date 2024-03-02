Shader "Hidden/Shader/NoiseDistort"
{
    Properties
    {
        // This property is necessary to make the CommandBuffer.Blit bind the source texture to _MainTex
        _MainTex("Main Texture", 2DArray) = "grey" {}
    }

    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/FXAA.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/RTUpscale.hlsl"

    struct Attributes
    {
        uint vertexID : SV_VertexID;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float2 texcoord   : TEXCOORD0;
        UNITY_VERTEX_OUTPUT_STEREO
    };

    Varyings Vert(Attributes input)
    {
        Varyings output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
        return output;
    }

    float _K1;
    float _K2;
    float _K3;
    float _T1;
    float _T2;
    float _noise_intensity = 0;
    float4 _OutOfBoundColour = float4(0.0, 0.0, 0.0, 1.0);

    
    TEXTURE2D_X(_MainTex);

    float Rand(float2 co) {
        float time = _Time.y;
        return frac(sin(dot(co.xy, float2(12.9898 + time, 78.233 + time))) * 43758.5453);
    }

    float2 GaussianRandom(float2 uv) {
        float u1 = Rand(uv);
        float u2 = Rand(uv + 1.0);

        float z0 = sqrt(-2.0 * log(u1)) * sin(2.0 * PI * u2);
        float z1 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2);

        return float2(z0, z1);
    }

    float2 getUndistorted(float2 p, float3 K, float2 P){
        const float2 c = float2(0.5, 0.5);
        const float x_d = p.x; const float y_d = p.y;
        const float x_c = c.y; const float y_c = c.y;
        const float r = sqrt(pow(p.x-c.x, 2) + pow(p.y-c.y, 2));

        const float x_u = x_d + (x_d-x_c)*(K[0]*r*r + K[1]*pow(r, 4) + K[2]*pow(r, 6)) + (P[0]*(r*r + 2*pow(x_d-x_c, 2)) 
                              + 2*P[1]*(x_d-x_c)*(y_d-y_c));

        const float y_u = y_d + (y_d-y_c)*(K[0]*r*r + K[1]*pow(r, 4) + K[2]*pow(r, 6)) + (2*P[0]*(x_d-x_c)*(y_d-y_c)
                              + P[1]*(r*r+2*pow(y_d-y_c, 2)));

        return float2(x_u, y_u);
    }


    bool outOfBounds(float2 uv){
        return (uv.x <= 0 || uv.x >= 1 || uv.y <= 0 || uv.y >= 1);
    }

    float4 AddNoise(float4 color, float2 uv){
        float2 sample = GaussianRandom(uv);
        float noise = clamp(sample.x, -1.0, 1.0)*_noise_intensity;
        return color*(1-noise);
    }


    float4 CustomPostProcess(Varyings i) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

        //apply distortion
        const float2 xy_d = float2(i.texcoord[0], i.texcoord[1]);
        const float2 xy_u = getUndistorted(xy_d, float3(_K1, _K2, _K3), float2(_T1, _T2));
        if (outOfBounds(xy_u)) return 0.0;
        
        
        uint2 positionSS = xy_u * _ScreenSize.xy;
        float4 color = LOAD_TEXTURE2D_X(_MainTex, positionSS);
        color = AddNoise(color, i.texcoord);
        return float4(color.xyz, 1.0);
    }

    ENDHLSL

    SubShader
    {
        Tags{ "RenderPipeline" = "HDRenderPipeline" }
        Pass
        {
            Name "Noise and Distort"

            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            HLSLPROGRAM
                #pragma fragment CustomPostProcess
                #pragma vertex Vert
            ENDHLSL
        }
    }
    Fallback Off
}
