using Gee;

namespace Engine
{
    public class RenderScene2D : RenderScene
    {
        ArrayList<RenderObject2D> objs = new ArrayList<RenderObject2D>();

        public RenderScene2D(Size2i screen_size, Rectangle rect)
        {
            this.screen_size = screen_size;
            this.rect = rect;
        }

        public void add_object(RenderObject2D object)
        {
            objs.add(object.copy());
        }

        public ArrayList<RenderObject2D> objects { get { return objs; } }
        public Size2i screen_size { get; private set; }
        public Rectangle rect { get; private set; }
    }
}