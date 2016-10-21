public class RenderMaterial
{
    public RenderMaterial()
    {
        ambient_color = Color.none();
        diffuse_color = Color.none();
        specular_color = Color.white();
        ambient_material_strength = 0.05f;
        diffuse_material_strength = 1;
        specular_material_strength = 0;

        /*ambient_blend = BlendType.HYBRID;
        diffuse_blend = BlendType.BLEND;
        specular_blend = BlendType.COLOR;*/
        specular_exponent = 1;
        alpha = 1;
    }

    public RenderMaterial copy()
    {
        RenderMaterial mat = new RenderMaterial();

        mat.ambient_color = ambient_color;
        mat.diffuse_color = diffuse_color;
        mat.specular_color = specular_color;
        mat.ambient_material_strength = ambient_material_strength;
        mat.diffuse_material_strength = diffuse_material_strength;
        mat.specular_material_strength = specular_material_strength;
        mat.specular_exponent = specular_exponent;
        mat.alpha = alpha;

        return mat;
    }

    public Color ambient_color { get; set; }
    public Color diffuse_color { get; set; }
    public Color specular_color { get; set; }
    public float ambient_material_strength { get; set; }
    public float diffuse_material_strength { get; set; }
    public float specular_material_strength { get; set; }
    public float specular_exponent { get; set; }
    public float alpha { get; set; }
}

public enum BlendType
{
    COLOR = 0,
    MATERIAL = 1,
    BLEND = 2,
    HYBRID = 3
}
