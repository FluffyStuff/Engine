namespace Engine
{
    public abstract class RenderObject2D : Object
    {
        public RenderObject2D copy()
        {
            RenderObject2D obj = copy_new();

            obj.rotation = rotation;
            obj.position = position;
            obj.scale = scale;
            obj.diffuse_color = diffuse_color;
            obj.scissor = scissor;
            obj.scissor_box = scissor_box;

            return obj;
        }

        protected abstract RenderObject2D copy_new();

        public float rotation { get; set; }
        public Vec2 position { get; set; }
        public Size2 scale { get; set; }
        public Color diffuse_color { get; set; }
        public bool scissor { get; set; }
        public Rectangle scissor_box { get; set; }
    }

    public class RenderImage2D : RenderObject2D
    {
        public RenderImage2D(RenderTexture? texture)
        {
            this.texture = texture;
            rotation = 0;
            position = Vec2.empty();
            scale = Size2(1, 1);
            diffuse_color = Color.with_alpha(1);
        }

        public override RenderObject2D copy_new()
        {
            return new RenderImage2D(texture);
        }

        public RenderTexture? texture { get; set; }
    }

    public class RenderLabel2D : RenderObject2D
    {
        private string _font_type;
        private float _font_size;
        private string _text;

        public RenderLabel2D(LabelResourceReference reference)
        {
            this.reference = reference;

            rotation = 0;
            position = Vec2.empty();
            scale = Size2(1, 1);

            _font_type = "Noto Sans CJK JP";
            _font_size = 40;
            _text = "";

            diffuse_color = Color.white();
        }

        public override RenderObject2D copy_new()
        {
            RenderLabel2D img = new RenderLabel2D(reference);
            img.info = info;
            img._font_type = _font_type;
            img._font_size = _font_size;
            img._text = _text;

            return img;
        }

        private void update()
        {
            info = reference.update(font_type, font_size, text);
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
    }

    public class RenderRectangle2D : RenderObject2D
    {
        public RenderRectangle2D()
        {
            rotation = 0;
            position = Vec2.empty();
            scale = Size2(1, 1);
            diffuse_color = Color.black();
        }

        public override RenderObject2D copy_new()
        {
            return new RenderRectangle2D();
        }
    }
}