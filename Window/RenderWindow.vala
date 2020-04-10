using SDL;

namespace Engine
{
    public abstract class RenderWindow
    {
        private IWindowTarget window;
        private bool running;
        private GLib.Timer timer;
        private float last_time = 0;
        private Vec2i _cursor_position;

        protected RenderWindow(IWindowTarget window, RenderTarget renderer)
        {
            this.window = window;
            this.renderer = renderer;
            store = renderer.resource_store;
        }

        public void show()
        {
            main_view = new MainView(this);
            running = true;
            timer = new GLib.Timer();

            shown();

            while (running)
            {
                var delta = get_delta();
                process(delta);
                renderer.set_state(render(delta), this);
            }
        }

        public void finish()
        {
            running = false;
        }

        private RenderState render(DeltaArgs delta)
        {
            RenderState state = new RenderState(size, renderer.multithread_rendering, delta);
            state.back_color = back_color;
            main_view.start_render(state);
            return state;
        }

        // Returns the delta time in seconds
        private DeltaArgs get_delta()
        {
            float time = (float)timer.elapsed();
            float dt = time - last_time;
            last_time = time;

            return new DeltaArgs(time, dt);
        }

        private void process(DeltaArgs delta)
        {
            process_events();
            do_process(delta);
            main_view.start_process(delta);
        }

        // TODO: Make this non-SDL specific
        private void process_events()
        {
            Event e;

            while (Event.poll(out e) != 0)
            {
                if (e.type == EventType.QUIT)
                    finish();
                else if (e.type == EventType.KEYDOWN || e.type == EventType.KEYUP)
                {
                    KeyArgs key = new KeyArgs
                    (
                        (ScanCode)e.key.keysym.scancode,
                        (KeyCode)e.key.keysym.sym,
                        (Modifier)e.key.keysym.mod,
                        e.key.repeat != 0,
                        e.key.state != 0
                    );

                    if (!key_press(key))
                        main_view.do_key_press(key);
                }
                else if(e.type == EventType.TEXTINPUT)
                {
                    main_view.do_text_input(new TextInputArgs(e.text.text));
                }
                else if(e.type == EventType.TEXTEDITING)
                {
                    main_view.do_text_edit(new TextEditArgs(e.edit.text, e.edit.start, e.edit.length));
                }
                else if (e.type == EventType.MOUSEMOTION)
                {
                }
                else if (e.type == EventType.MOUSEBUTTONDOWN || e.type == EventType.MOUSEBUTTONUP)
                {
                    MouseButtonEvent ev = e.button;

                    MouseEventArgs.Button button = 0;
                    bool unknown = false;

                    switch (ev.button)
                    {
                    case 1:
                        button = MouseEventArgs.Button.LEFT;
                        break;
                    case 2:
                        button = MouseEventArgs.Button.CENTER;
                        break;
                    case 3:
                        button = MouseEventArgs.Button.RIGHT;
                        break;
                    default:
                        unknown = true;
                        break;
                    }

                    if (unknown)
                        break;

                    int ax = 0, ay = 0;
                    Cursor.get_state(ref ax, ref ay);
                    MouseEventArgs mouse = new MouseEventArgs(button, null, ev.state == 1, Vec2i(ax, size.height - ay), size);
                    main_view.do_mouse_event(mouse);
                }
                else if (e.type == EventType.MOUSEWHEEL)
                {

                }
                else if (e.type == EventType.WINDOWEVENT)
                {
                    WindowEvent win = e.window;
                    if (win.event == WindowEventID.RESIZED)
                        main_view.resize();
                }
            }

            mouse_move_event();
        }

        private void mouse_move_event()
        {
            int rx = 0, ry = 0, ax = 0, ay = 0;
            Cursor.get_relative_state(ref rx, ref ry);
            Cursor.get_state(ref ax, ref ay);

            _cursor_position = Vec2i(ax, size.height - ay);

            MouseMoveArgs mouse = new MouseMoveArgs(cursor_position, Vec2i(rx, -ry), size);
            main_view.do_mouse_move(mouse);

            if (mouse.cursor_type != CursorType.UNDEFINED)
                set_cursor_type(mouse.cursor_type);
        }

        public void set_icon(string icon)
        {
            window.set_icon(icon);
        }

        public void set_cursor_type(CursorType type)
        {
            window.set_cursor_type(type);
        }

        public void set_cursor_hidden(bool hidden)
        {
            window.set_cursor_hidden(hidden);
        }

        public void start_text_input()
        {
            window.start_text_input();
        }

        public void stop_text_input()
        {
            window.stop_text_input();
        }

        public string get_clipboard_text()
        {
            return window.get_clipboard_text();
        }

        public void set_clipboard_text(string text)
        {
            window.set_clipboard_text(text);
        }

        protected virtual void do_process(DeltaArgs delta) {}

        protected virtual bool key_press(KeyArgs key)
        {
            return false;
        }

        protected virtual void shown() {}
        public RenderTarget renderer { get; private set; }
        public ResourceStore store { get; private set; }
        public MainView main_view { get; private set; }
        public bool fullscreen { get { return window.fullscreen; } set { window.fullscreen = value; } }
        public Color back_color { get; set; }
        public Size2i size { get { return window.size; } }
        public Vec2i cursor_position
        {
            get { return _cursor_position; }
            set
            {
                _cursor_position = value;
                window.set_cursor_position(value.x, value.y);
            }
        }
    }
}