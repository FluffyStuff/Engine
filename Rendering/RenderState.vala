using Gee;

namespace Engine
{
    public class RenderState
    {
        public RenderState(Size2i screen_size, bool copy_state, DeltaArgs delta)
        {
            this.screen_size = screen_size;
            this.copy_state = copy_state;
            this.delta = delta;

            scenes = new ArrayList<RenderScene>();
        }

        public void add_scene(RenderScene scene)
        {
            scenes.add(scene);
        }

        public Color back_color { get; set; }
        public Size2i screen_size { get; private set; }
        public bool copy_state { get; private set; }
        public DeltaArgs delta { get; private set; }

        public ArrayList<RenderScene> scenes { get; private set; }
    }
}