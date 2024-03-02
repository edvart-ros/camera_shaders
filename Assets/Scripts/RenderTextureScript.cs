using UnityEngine;

public class RenderTextureScripts : MonoBehaviour
{
    public RenderTexture inputRT;
    public RenderTexture outputDepthRT;
    public Material depthMat;

    void Start(){
        depthMat = new Material(Shader.Find("Unlit/EyeVsViewDepth"));
    }

    void Update()
    {
        Graphics.Blit(inputRT, outputDepthRT, depthMat);
    }
}