using UnityEngine;

public class StereoCompute : MonoBehaviour {
    public ComputeShader computeShader;
    public RenderTexture leftImage;
    public RenderTexture rightImage;
    public RenderTexture resultTexture;
    private int kernelHandle;

    void Start() {
        // Create the result RenderTexture
        resultTexture.Create();

        kernelHandle = computeShader.FindKernel("CSMain");
        computeShader.SetTexture(kernelHandle, "Left", leftImage);
        computeShader.SetTexture(kernelHandle, "Right", rightImage);
        computeShader.SetTexture(kernelHandle, "Result", resultTexture);

        computeShader.Dispatch(kernelHandle, resultTexture.width / 8, resultTexture.height / 8, 1);
    }

    void Update(){
        computeShader.SetTexture(kernelHandle, "Left", leftImage);
        computeShader.SetTexture(kernelHandle, "Right", rightImage);
        computeShader.SetTexture(kernelHandle, "Result", resultTexture);

        // Dispatch the compute shader
        computeShader.Dispatch(kernelHandle, resultTexture.width / 8, resultTexture.height / 8, 1);
    }
}
