Shader "Hidden/Shader/Depth"
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
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/NormalBuffer.hlsl"
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


    float3 GetNormalWorldSpace(float2 uv, float depth)
    {
        float3 normalWS = 0.0f;
        NormalData normalData;
        const float4 normalBuffer = LOAD_TEXTURE2D_X(_NormalBufferTexture, uv);
        DecodeFromNormalBuffer(normalBuffer, uv, normalData);
        normalWS = normalData.normalWS;
        return normalWS;
    }
    // List of properties to control your post process effect
    float _Intensity;
    TEXTURE2D_X(_MainTex);
    TEXTURE2D(_DepthTexture);

    float4 CustomPostProcess(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        uint2 positionSS = input.texcoord * _ScreenSize.xy;

        float3 inColor = LOAD_TEXTURE2D_X(_MainTex, positionSS).xyz;

        // Depth
        float depth = LoadCameraDepth(positionSS);
        float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);
        float coc = saturate(linearEyeDepth/30);
        if (coc == 1) return 0;
        
        float3 n = 0.5f*(GetNormalWorldSpace(input.texcoord * _ScreenSize.xy, depth) + 1);
        //return float4(n.x, n.y, n.z, 1);
        return coc;
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "Depth"

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