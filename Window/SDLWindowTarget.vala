using SDL;

namespace Engine
{
    public class SDLWindowTarget : Object, IWindowTarget
    {
        private unowned Window window;

        private CursorType _cursor_type;
        private Cursor normal_cursor;
        private Cursor hover_cursor;
        private Cursor caret_cursor;

        public SDLWindowTarget(void *window, ScreenTypeEnum screen_type)
        {
            this.window = (Window)window;
            this.screen_type = screen_type;
            
            normal_cursor = new Cursor.from_system(SystemCursor.ARROW);
            hover_cursor = new Cursor.from_system(SystemCursor.HAND);
            caret_cursor = new Cursor.from_system(SystemCursor.IBEAM);
            current_cursor = CursorType.NORMAL;
            _cursor_type = current_cursor;
        }

        public void pump_events()
        {
            if (_cursor_type != current_cursor)
            {
                _cursor_type = current_cursor;
                int_set_cursor_type(_cursor_type);
            }

            Event.pump();
        }

        public void set_icon(string icon)
        {
            var img = SDLImage.load(icon);
            window.set_icon(img);
        }

        public ScreenTypeEnum screen_type
        {
            get
            {
                uint32 flags = window.get_flags();
                if ((flags & WindowFlags.FULLSCREEN_DESKTOP) == WindowFlags.FULLSCREEN_DESKTOP) return ScreenTypeEnum.FULLSCREEN;
                if ((flags & WindowFlags.MAXIMIZED) == WindowFlags.MAXIMIZED) return ScreenTypeEnum.MAXIMIZED;
                return ScreenTypeEnum.WINDOWED;
            }
            set
            {
                window.set_fullscreen(value == ScreenTypeEnum.FULLSCREEN ? WindowFlags.FULLSCREEN_DESKTOP : (value == ScreenTypeEnum.MAXIMIZED ? WindowFlags.MAXIMIZED : 0));
            }
        }

        public Size2i size
        {
            get
            {
                int width, height;
                window.get_size(out width, out height);
                return Size2i(width, height);
            }
            set
            {
                window.set_size(value.width, value.height);
            }
        }

        public Vec2i position
        {
            get
            {
                int x, y;
                window.get_position(out x, out y);
                return Vec2i(x, y);
            }
            set
            {
                window.set_position(value.x, value.y);
            }
        }

        public void swap()
        {
            SDL.GL.swap_window(window);
        }

        public void set_cursor_hidden(bool hidden)
        {
            Cursor.show(hidden ? 0 : 1);
        }

        public void set_cursor_relative_mode(bool relative)
        {
            Cursor.set_relative_mode(relative);
        }

        public void set_cursor_type(CursorType type)
        {
            current_cursor = type;
        }

        private void int_set_cursor_type(CursorType type)
        {
            switch (type)
            {
            case CursorType.NORMAL:
                Cursor.set(normal_cursor);
                break;
            case CursorType.HOVER:
                Cursor.set(hover_cursor);
                break;
            case CursorType.CARET:
                Cursor.set(caret_cursor);
                break;
            }

            current_cursor = type;
        }

        public void set_cursor_position(int x, int y)
        {
            Cursor.warp_mouse(window, x, y);
        }

        public void start_text_input()
        {
            TextInput.start();
        }

        public void stop_text_input()
        {
            TextInput.stop();
        }

        public string get_clipboard_text()
        {
            return Clipboard.get_text();
        }

        public void set_clipboard_text(string text)
        {
            Clipboard.set_text(text);
        }

        public void focus()
        {
            if (screen_type == ScreenTypeEnum.FULLSCREEN)
                window.restore();
            else
                window.raise();
        }

        public CursorType current_cursor { get; private set; }
    }
}