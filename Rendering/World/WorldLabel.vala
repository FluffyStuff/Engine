namespace Engine
{
    public class WorldLabel : WorldObjectTransformable
    {
        private RenderLabel3D label;
        private bool _dynamic_color;

        ~WorldLabel()
        {
            EngineLog.log(EngineLogType.DEBUG, "WorldLabel.vala", "WorldLabel dealloc");
        }

        public override void added()
        {
            label = store.create_label_3D();
            set_object(label);
            load_material();
        }

        private void load_material()
        {
            MaterialSpecification spec = label.material.spec;
            spec.ambient_color = dynamic_color ? UniformType.DYNAMIC : UniformType.STATIC;
            spec.diffuse_color = dynamic_color ? UniformType.DYNAMIC : UniformType.STATIC;
            spec.specular_color = specular ? UniformType.STATIC : UniformType.NONE;
            spec.static_ambient_color = color;
            spec.static_diffuse_color = color;
            var texture = label.material.textures[0];
            label.material = store.load_material(spec);
            label.material.textures[0] = texture;
        }

        public bool specular { get; private set; }
        public string font_type { get { return label.font_type; } set { label.font_type = value; } }
        public float font_size { get { return label.font_size; } set { label.font_size = value; } }
        public string text { get { return label.text; } set { label.text = value; } }
        public bool bold { get { return label.bold; } set { label.bold = value; } }

        public bool dynamic_color // Use dynamic color if the color changes frequently
        {
            get { return _dynamic_color; }
            set
            {
                if (value == _dynamic_color)
                    return;
                _dynamic_color = value;
                load_material();
            }
        }

        public Color color
        {
            get { return label.color; }
            set
            {
                if (value == color)
                    return;
                
                if (!dynamic_color)
                {
                    label.color = value;
                    load_material();
                }
                
                label.color = value;
            }
        }

        public Vec3 end_size
        {
            get
            {
                Vec3 size = label.end_size;
                Vec3 trans_scale = transform.scale;
                return Vec3(size.x * trans_scale.x, 0, size.z * trans_scale.z);
            }
        }
    }
}