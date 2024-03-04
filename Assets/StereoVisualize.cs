using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StereoVisualize : MonoBehaviour
{
    public RenderTexture leftRenderTexture;
    public RenderTexture rightRenderTexture;
    public RenderTexture resultRenderTexture;
    private Material mat;
    public Shader shader;
    // Start is called before the first frame update
    void Start()
    {
        mat = new Material(shader);
    }

    // Update is called once per frame
    void Update()
    {
        mat.SetTexture("_MainTex", leftRenderTexture);
        mat.SetTexture("_RightTex", rightRenderTexture);
        Graphics.Blit(leftRenderTexture, resultRenderTexture, mat);
    }
}
