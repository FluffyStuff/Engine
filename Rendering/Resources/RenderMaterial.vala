namespace Engine
{
    public class RenderMaterial : IResource
    {
        private ShaderUniform[] uniforms;

        public RenderMaterial(IMaterialResourceHandle handle, MaterialSpecification spec, ShaderUniform[]? uniforms)
        {
            this.handle = handle;
            this.spec = spec;
            this.uniforms = uniforms;
            textures = new RenderTexture[spec.textures];

            specular_color = Color.white();
            alpha = 1;
        }

        public RenderMaterial copy()
        {
            /*ShaderUniform[] uniforms = new ShaderUniform[this.uniforms.length];
            for (int i = 0; i < uniforms.length; i++)
                uniforms[i] = this.uniforms[i].copy();*/

            RenderMaterial mat = new RenderMaterial(handle, spec, null);

            for (int i = 0; i < textures.length; i++)
                mat.textures[i] = textures[i];

            mat.ambient_color = ambient_color;
            mat.diffuse_color = diffuse_color;
            mat.specular_color = specular_color;
            mat.target_color = target_color;
            mat.target_color_strength = target_color_strength;
            mat.alpha = alpha;

            return mat;
        }

        public override bool equals(IResource? other)
        {
            var ret = other as RenderMaterial?;
            return ret != null && handle == ret.handle;
        }

        public void set_uniform(string name, UniformData data)
        {
            foreach (ShaderUniform uniform in uniforms)
            {
                if (name == uniform.name)
                {
                    uniform.data = data;
                    break;
                }
            }
        }

        public ShaderUniform[] get_uniforms()
        {
            return uniforms;
        }

        public IMaterialResourceHandle handle { get; private set; }
        public MaterialSpecification spec;
        public RenderTexture[] textures { get; private set; }

        public Color ambient_color;
        public Color diffuse_color;
        public Color specular_color;
        public Color target_color;
        public float target_color_strength;
        public float alpha;

    }

    public struct MaterialSpecification
    {
        public MaterialSpecification copy()
        {
            return this;
            /*MaterialSpecification spec = new MaterialSpecification();

            spec.lighting_calculation = lighting_calculation;
            spec.ambient_color = ambient_color;
            spec.diffuse_color = diffuse_color;
            spec.specular_color = specular_color;
            spec.target_color = target_color;
            spec.alpha = alpha;
            
            spec.static_ambient_color = static_ambient_color;
            spec.static_diffuse_color = static_diffuse_color;
            spec.static_specular_color = static_specular_color;
            spec.static_alpha = static_alpha;
            spec.static_target_color = static_target_color;
            spec.specular_exponent = specular_exponent;

            spec.ambient_strength = ambient_strength;
            spec.diffuse_strength = diffuse_strength;
            spec.specular_strength = specular_strength;
            spec.target_color_strength = target_color_strength;

            spec.ambient_blend_type = ambient_blend_type;
            spec.diffuse_blend_type = diffuse_blend_type;
            spec.specular_blend_type = specular_blend_type;

            spec.textures = textures;

            return spec;*/
        }

        public bool equals(MaterialSpecification other)
        {
            return other == this;
            /*return 
                lighting_calculation == other.lighting_calculation &&
                ambient_color == other.ambient_color &&
                diffuse_color == other.diffuse_color &&
                specular_color == other.specular_color &&
                alpha == other.alpha &&
                target_color == other.target_color &&

                static_ambient_color == other.static_ambient_color &&
                static_diffuse_color == other.static_diffuse_color &&
                static_specular_color == other.static_specular_color &&
                static_alpha == other.static_alpha &&
                static_target_color == other.static_target_color &&
                specular_exponent == other.specular_exponent &&

                ambient_strength == other.ambient_strength &&
                diffuse_strength == other.diffuse_strength &&
                specular_strength == other.specular_strength &&
                target_color_strength == other.target_color_strength &&

                ambient_blend_type == other.ambient_blend_type &&
                diffuse_blend_type == other.diffuse_blend_type &&
                specular_blend_type == other.specular_blend_type &&

                textures == other.textures;*/
        }

        public LightingCalculationType lighting_calculation;// { get; set; }
        public UniformType ambient_color;// { get; set; }
        public UniformType diffuse_color;// { get; set; }
        public UniformType specular_color;// { get; set; }
        public UniformType alpha;// { get; set; }
        public UniformType target_color;// { get; set; }

        public Color static_ambient_color;// { get; set; }
        public Color static_diffuse_color;// { get; set; }
        public Color static_specular_color;// { get; set; }
        public float static_alpha;// { get; set; }
        public Color static_target_color;// { get; set; }
        public float specular_exponent;// { get; set; }

        public float ambient_strength;// { get; set; }
        public float diffuse_strength;// { get; set; }
        public float specular_strength;// { get; set; }
        public Color target_color_strength;// { get; set; }

        public TextureBlendType ambient_blend_type;// { get; set; }
        public TextureBlendType diffuse_blend_type;// { get; set; }
        public TextureBlendType specular_blend_type;// { get; set; }

        public int textures;// { get; set; }
        public bool texture_map;
    }

    public enum TextureBlendType
    {
        ALPHA,
        MAP,
        COLOR,
        TEXTURE
    }

    public enum UniformType
    {
        NONE,
        STATIC,
        DYNAMIC
    }

    public enum LightingCalculationType
    {
        NONE,
        VERTEX,
        FRAGMENT
    }

    public class ShaderUniform
    {
        public ShaderUniform(string name)
        {
            this.name = name;
        }

        public ShaderUniform copy()
        {
            ShaderUniform uniform = new ShaderUniform(name);
            if (data != null)
                uniform.data = data.copy();
            
            return uniform;
        }

        public string name { get; private set; }
        public UniformData? data { get; set; }
    }

    public abstract class UniformData
    {
        public abstract bool equals(UniformData other);
        public abstract UniformData copy();
    }

    public class MatrixUniformData : UniformData
    {
        public MatrixUniformData(Mat4 matrix)
        {
            this.matrix = matrix;
        }

        public override bool equals(UniformData other)
        {
            var mat = other as MatrixUniformData;
            return mat.matrix.equals(matrix);
        }

        public override UniformData copy()
        {
            return new MatrixUniformData(matrix);
        }

        public Mat4 matrix { get; set; }
    }

    public class Vec3UniformData : UniformData
    {
        public Vec3UniformData(Vec3 value)
        {
            this.value = value;
        }

        public override bool equals(UniformData other)
        {
            var vec = other as Vec3UniformData;
            return vec.value == value;
        }

        public override UniformData copy()
        {
            return new Vec3UniformData(value);
        }

        public Vec3 value { get; set; }
    }

    public class ColorUniformData : UniformData
    {
        public ColorUniformData(Color value)
        {
            this.value = value;
        }

        public override bool equals(UniformData other)
        {
            var uni = other as ColorUniformData;
            return uni.value == value;
        }

        public override UniformData copy()
        {
            return new ColorUniformData(value);
        }

        public Color value { get; set; }
    }

    public class FloatUniformData : UniformData
    {
        public FloatUniformData(float value)
        {
            this.value = value;
        }

        public override bool equals(UniformData other)
        {
            var f = other as FloatUniformData;
            return f.value == value;
        }

        public override UniformData copy()
        {
            return new FloatUniformData(value);
        }

        public float value { get; set; }
    }

    public class IntUniformData : UniformData
    {
        public IntUniformData(int value)
        {
            this.value = value;
        }

        public override bool equals(UniformData other)
        {
            var i = other as IntUniformData;
            return i.value == value;
        }

        public override UniformData copy()
        {
            return new IntUniformData(value);
        }

        public int value { get; set; }
    }

    public class BoolUniformData : UniformData
    {
        public BoolUniformData(bool value)
        {
            this.value = value;
        }

        public override bool equals(UniformData other)
        {
            var b = other as BoolUniformData;
            return b.value == value;
        }

        public override UniformData copy()
        {
            return new BoolUniformData(value);
        }

        public bool value { get; set; }
    }
}