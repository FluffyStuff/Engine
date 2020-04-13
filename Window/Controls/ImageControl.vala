namespace Engine
{
    public class ImageControl : EndControl
    {
        private RenderImage2D image;
        private string? name;
        private RenderTexture? texture;

        public ImageControl(string name)
        {
            this.name = name;
        }

        public ImageControl.empty(){}

        public override void pre_added()
        {
            if (name != null)
                texture = store.load_texture(name);
            image = new RenderImage2D(texture);
        }

        public void set_texture(RenderTexture? texture)
        {
            image.texture = texture;
        }

        protected override RenderObject2D? get_obj()
        {
            return image;
        }

        public Color diffuse_color
        {
            get { return image.diffuse_color; }
            set { image.diffuse_color = value; }
        }

        public float rotation
        {
            get { return image.rotation; }
            set { image.rotation = value; }
        }

        public override Size2 end_size
        {
            get
            {
                if (image.texture == null) return Size2(0, 0);
                return Size2(image.texture.size.width, image.texture.size.height);
            }
        }
    }
}