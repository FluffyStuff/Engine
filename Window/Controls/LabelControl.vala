namespace Engine
{
    public class LabelControl : EndControl
    {
        private RenderLabel2D label;

        public override void pre_added()
        {
            label = store.create_label();
            label.text = "";
            label.font_size = 30;
            label.font_type = "Noto Sans CJK JP";
            color = Color.white();
        }

        protected override RenderObject2D get_obj()
        {
            return label;
        }

        public Color color
        {
            get
            {
                Color d = label.diffuse_color;
                return Color(d.r + 1, d.g + 1, d.b + 1, d.a);
            }
            set
            {
                label.diffuse_color = Color(value.r - 1, value.g - 1, value.b - 1, value.a);
            }
        }

        public float alpha
        {
            get { return color.a; }
            set { color = Color(color.r, color.g, color.b, value); }
        }

        public string font_type
        {
            get { return label.font_type; }
            set
            {
                label.font_type = value;
                size = end_size;
                //resize();
            }
        }

        public float font_size
        {
            get { return label.font_size; } // Pixels
            set
            {
                label.font_size = value; // Pixels
                size = end_size;
                //resize();
            }
        }

        public string text
        {
            get { return label.text; }
            set
            {
                label.text = value;
                size = end_size;
                //resize();
            }
        }

        public override Size2 end_size { get { return label.info.size.to_size2(); } }
    }
}