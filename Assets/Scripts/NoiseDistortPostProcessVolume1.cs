using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/NoiseDistort")]
public sealed class NoiseDistortPostProcessVolume : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    public BoolParameter activate = new BoolParameter(false);

    public ClampedFloatParameter k1 = new ClampedFloatParameter(0f, -1f, 1f);
    public ClampedFloatParameter k2 = new ClampedFloatParameter(0f, -1f, 1f);
    public ClampedFloatParameter k3 = new ClampedFloatParameter(0f, -1f, 1f);
    public ClampedFloatParameter t1 = new ClampedFloatParameter(0f, -1f, 1f);
    public ClampedFloatParameter t2 = new ClampedFloatParameter(0f, -1f, 1f);
    public ClampedFloatParameter noiseIntensity = new ClampedFloatParameter(0f, 0f, 1f);

    Material m_Material;

    public bool IsActive() => m_Material != null && activate.value;

    // Do not forget to add this post process in the Custom Post Process Orders list (Project Settings > Graphics > HDRP Global Settings).
    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    const string kShaderName = "Hidden/Shader/NoiseDistort";

    public override void Setup()
    {
        if (Shader.Find(kShaderName) != null)
            m_Material = new Material(Shader.Find(kShaderName));
        else
            Debug.LogError($"Unable to find shader '{kShaderName}'. Post Process Volume is unable to load.");
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m_Material == null)
            return;

        m_Material.SetFloat("_K1", k1.value);
        m_Material.SetFloat("_K2", k2.value);
        m_Material.SetFloat("_K3", k3.value);
        m_Material.SetFloat("_T1", t1.value);
        m_Material.SetFloat("_T2", t2.value);
        m_Material.SetFloat("_noise_intensity", noiseIntensity.value);
        m_Material.SetTexture("_MainTex", source);
        HDUtils.DrawFullScreen(cmd, m_Material, destination, shaderPassId: 0);
    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(m_Material);
    }
}
