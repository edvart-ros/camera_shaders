Shader "Unlit/StereoVisualize"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RightTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float2 screenpos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _RightTex;
            float4 _RightTex_ST;
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenpos = ComputeScreenPos(v.vertex)
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 colLeft = tex2D(_MainTex, i.uv);
                fixed4 colRight = tex2D(_RightTex, i.uv);
                UNITY_APPLY_FOG(i.fogCoord, col);
                float gLeft = (colLeft.x + colLeft.y + colLeft.z)/3.0;                
                float gRight = (colRight.x + colRight.y + colRight.z)/3.0;
                
                return 0.5*(gLeft+gRight);           
            }
            ENDCG
        }
    }
}
