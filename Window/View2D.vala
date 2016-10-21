public class View2D : Container {} // For future use

public class ResetContainer : Container
{
    public override void render(RenderState state, RenderScene2D scene)
    {
        if (!visible)
            return;

        RenderScene2D new_scene = new RenderScene2D(state.screen_size, rect);

        do_render(state, scene);

        foreach (Container child in children)
            child.render(state, new_scene);

        state.add_scene(new_scene);
    }
}
