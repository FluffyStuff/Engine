namespace Engine
{
    public class ImageControl : EndControl
    {
        private RenderImage2D image;
        private string name;

        public ImageControl(string name)
        {
            this.name = name;
        }

        public override void pre_added()
        {
            RenderTexture texture = store.load_texture(name);
            image = new RenderImage2D(texture);
        }

        protected override RenderObject2D get_obj()
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

        public override Size2 end_size { get { return Size2(image.texture.size.width, image.texture.size.height); } }
    }
}