namespace Engine
{
    public class RenderObject3D : Transformable3D
    {
        public RenderObject3D(RenderModel model, RenderMaterial material)
        {
            this.model = model;
            this.material = material;
        }

        protected override Transformable3D copy_transformable(Transform transform)
        {
            RenderObject3D obj = copy_object();
            
            obj.transform = transform;
            obj.model = model;
            obj.material = material.copy();

            return obj;
        }
        
        protected virtual RenderObject3D copy_object()
        {
            return new RenderObject3D(model, material.copy());
        }

        public virtual Transform get_full_transform()
        {
            return transform;
        }

        public Vec3 obb { get { return model.size; } }
        public RenderModel model { get; set; }
        public RenderMaterial material { get; set; }
    }

    public class RenderLabel3D : RenderObject3D
    {
        private string _font_type;
        private float _font_size;
        private string _text;
        private bool _bold;
        private float _size = FONT_SIZE_MULTIPLIER;

        public RenderLabel3D(LabelResourceReference reference, RenderModel model, RenderMaterial material)
        {
            base(model, material);

            this.reference = reference;

            // TODO: Abstractify font
            _font_type = "Noto Sans CJK JP";
            _font_size = 40;
            _text = "";
            _bold = false;

            color = Color.white();
            update();
        }

        protected override RenderObject3D copy_object()
        {
            RenderLabel3D img = new RenderLabel3D(reference, model, material);
            img.material = material.copy();
            img.info = info;
            img._font_type = _font_type;
            img._font_size = _font_size;
            img._text = _text;
            img._bold = _bold;

            return img;
        }

        private void update()
        {
            info = reference.update(get_full_font_type(), font_size, text);
        }

        private string get_full_font_type()
        {
            string font = font_type;
            if (bold)
                font += " Bold";
            return font;
        }

        public LabelInfo? info { get; private set; }
        public LabelResourceReference reference { get; private set; }

        public string font_type
        {
            get { return _font_type; }
            set
            {
                if (_font_type == value)
                    return;

                _font_type = value;
                update();
            }
        }

        public float font_size
        {
            get { return _font_size; }
            set
            {
                if (_font_size == value)
                    return;

                _font_size = value;
                update();
            }
        }

        public string text
        {
            get { return _text; }
            set
            {
                if (_text == value)
                    return;

                _text = value;
                update();
            }
        }

        public bool bold
        {
            get { return _bold; }
            set
            {
                if (_bold == value)
                    return;

                _bold = value;
                update();
            }
        }

        public Color color
        {
            get { return material.diffuse_color; } //Color(material.diffuse_color.r, material.diffuse_color.g, material.diffuse_color.b, material.diffuse_color.a); }
            set
            {
                material.diffuse_color = value;//Color(value.r, value.g, value.b, value.a);
                material.ambient_color = value;//material.diffuse_color;
            }
        }

        public override Transform get_full_transform()
        {
            Transform t = transform.copy_full_parentless();

            Vec3 s = font_sizing();
            var mat = t.get_full_matrix();
            mat = mat.mul_mat(Calculations.scale_matrix(s));

            return new Transform.with_mat(mat);
        }

        public Vec3 font_sizing()
        {
            return Vec3(info.size.width / font_size * _size, 1, info.size.height / font_size * _size);
        }

        public Vec3 end_size
        {
            get
            {
                Vec3 font_scale = font_sizing();
                Vec3 trans_scale = transform.scale;
                return Vec3(model.size.x * font_scale.x * trans_scale.x, 0, model.size.z * font_scale.z * trans_scale.z);
            }
        }

        private const float FONT_SIZE_MULTIPLIER = 0.2f;
    }
}