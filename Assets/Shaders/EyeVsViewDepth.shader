Shader "Unlit/EyeVsViewDepth"
{
    Properties
    {
        [PowerSlider(2.0)] _DiffScale("Depth Difference Scale", Range(1,100000)) = 1
    }
    SubShader
    {
        Tags { "Queue"="Geometry" }
        LOD 100
 
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
 
            #include "UnityCG.cginc"
 
            struct appdata
            {
                float4 vertex : POSITION;
            };
 
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 projPos : TEXCOORD0;
            };
 
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            float _DiffScale;
 
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.projPos = ComputeScreenPos (o.vertex);
                COMPUTE_EYEDEPTH(o.projPos.z);
                return o;
            }
 
            fixed4 frag (v2f i) : SV_Target
            {
                // raw depth from the depth texture
                float depthZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos));
 
                // linear eye depth recovered from the depth texture
                float sceneZ = LinearEyeDepth(depthZ);
 
                // linear eye depth from the vertex shader
                float fragZ = i.projPos.z;
 
                // difference between sceneZ and fragZ
                float diff = sceneZ - fragZ;
                return float4(
                    saturate(-diff * _DiffScale), // red if fragZ is closer than sceneZ
                    saturate( diff * _DiffScale), // green if sceneZ is closer than fragZ
                    0.0, 1.0);
            }
            ENDCG
        }
    }
 
    FallBack "VertexLit"
}
