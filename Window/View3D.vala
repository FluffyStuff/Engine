namespace Engine
{
    public abstract class View3D : Container
    {
        protected View3D()
        {
            reset_depth = true;
            world_scale_width = 1;
        }

        protected override void pre_added()
        {
            world = new World(this, store);
        }

        protected override void pre_render(RenderState state, RenderScene2D scene_2d)
        {
            RenderScene3D scene = new RenderScene3D(state.copy_state, state.screen_size, world_scale_width, rect);
            scene.scissor = scissor;
            scene.scissor_box = scissor_box;
            
            world.add_to_scene(scene);
            state.add_scene(scene);
        }

        protected override void pre_process(DeltaArgs args)
        {
            world.process(args);
        }

        protected override void mouse_event(MouseEventArgs mouse)
        {
            world.mouse_event(mouse);
        }

        protected override void mouse_move(MouseMoveArgs mouse)
        {
            world.mouse_move(mouse);
        }

        protected float world_scale_width { get; protected set; }
        protected World world { get; private set; }
    }
}