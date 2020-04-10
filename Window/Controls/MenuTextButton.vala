namespace Engine
{
    public class MenuTextButton : Control
    {
        private ImageControl button;
        private LabelControl label;
        private string name;
        private string text;

        private Sound click_sound;
        private Sound hover_sound;

        public MenuTextButton(string name, string text)
        {
            this.name = name;
            this.text = text;
        }

        public override void pre_added()
        {
            click_sound = store.audio_player.load_sound("click");
            hover_sound = store.audio_player.load_sound("mouse_over");

            button = new ImageControl("Buttons/" + name);
            add_child(button);
            button.resize_style = ResizeStyle.RELATIVE;

            label = new LabelControl();
            add_child(label);
            label.text = text;

            selectable = true;
            resize_style = ResizeStyle.ABSOLUTE;
            size = button.end_size;
        }

        public override void pre_render(RenderState state, RenderScene2D scene)
        {
            if (!enabled)
            {
                button.diffuse_color = Color.with_alpha(0.1f);
                label.color = Color(0, 0, 0, 0.1f);
            }
            else
            {
                if (hovering)
                {
                    if (mouse_pressed)
                    {
                        button.diffuse_color = Color(0.2f, 0.2f, 0.05f, 1);
                        label.color = Color(0.2f, 0.2f, 0.05f, 1);
                    }
                    else
                    {
                        button.diffuse_color = Color(0.4f, 0.4f, 0.2f, 1);
                        label.color = Color(0.4f, 0.4f, 0.2f, 1);
                    }
                }
                else
                {
                    button.diffuse_color = Color.with_alpha(1);
                    label.color = Color(0, 0, 0, 1);
                }
            }
        }

        protected override void on_mouse_over()
        {
            hover_sound.play();
        }

        protected override void on_click(Vec2 position)
        {
            click_sound.play();
        }

        public float font_size
        {
            get { return label.font_size; }
            set { label.font_size = value; }
        }
    }
}