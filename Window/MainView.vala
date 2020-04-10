namespace Engine
{
    public class MainView : Container
    {
        public MainView(RenderWindow? window)
        {
            base();
            set_window(window);
        }

        public void start_render(RenderState state)
        {
            RenderScene2D scene = new RenderScene2D(parent_window.size, rect);
            scene = do_render(state, scene);
            state.add_scene(scene);
        }

        public void start_process(DeltaArgs args)
        {
            do_process(args);
        }

        public void set_window(RenderWindow? window)
        {
            if (parent_window == window)
                return;
            
            parent_window = window;
            resize();
        }
    }

    public class MouseEventArgs
    {
        public MouseEventArgs(Button button, MouseReference? reference, bool down, Vec2i position, Size2i size)
        {
            this.button = button;
            this.down = down;
            this.position = position;
            this.size = size;
        }

        public bool handled { get; set; }
        public MouseReference? reference { get; set; }
        public Button button { get; private set; }
        public bool down { get; private set; }
        public Vec2i position { get; private set; }
        public Size2i size { get; private set; }

        public enum Button
        {
            LEFT,
            CENTER,
            RIGHT,
        }
    }

    public class MouseMoveArgs
    {
        public MouseMoveArgs(Vec2i position, Vec2i delta, Size2i size)
        {
            this.position = position;
            this.delta = delta;
            this.size = size;
            cursor_type = CursorType.NORMAL;
        }

        public bool handled { get; set; }
        public CursorType cursor_type { get; set; }
        public Vec2i position { get; private set; }
        public Vec2i delta { get; private set; }
        public Size2i size { get; private set; }
    }

    public class MouseReference {}

    public enum CursorType
    {
        UNDEFINED,
        NORMAL,
        HOVER,
        CARET
    }

    public class KeyArgs
    {
        public KeyArgs(ScanCode scancode, KeyCode keycode, Modifier modifiers, bool repeat, bool down)
        {
            this.scancode = scancode;
            this.keycode = keycode;
            this.modifiers = modifiers;
            this.repeat = repeat;
            this.down = down;

            this.key = (char)keycode;
        }

        public bool handled { get; set; }
        public ScanCode scancode { get; private set; }
        public KeyCode keycode { get; private set; }
        public Modifier modifiers { get; private set; }
        public bool repeat { get; private set; }
        public bool down { get; private set; }
        public char key { get; private set; }
    }

    public class TextInputArgs
    {
        public TextInputArgs(string text)
        {
            this.text = text;
        }

        public bool handled { get; set; }
        public string text { get; private set; }
    }

    public class TextEditArgs
    {
        public TextEditArgs(string text, int start, int length)
        {
            this.text = text;
            this.start = start;
            this.length = length;
        }

        public bool handled { get; set; }
        public string text { get; private set; }
        public int start { get; private set; }
        public int length { get; private set; }
    }
}