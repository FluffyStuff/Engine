namespace Engine
{
    public abstract class Control : Container
    {
        //protected virtual void on_added() {}
        //public abstract void do_resize(Vec2 new_position, Size2 new_scale);

        protected virtual void on_mouse_move(Vec2 position) {}
        protected virtual void on_click(Vec2 position) {}
        protected virtual void on_mouse_down(Vec2 position) {}
        protected virtual void on_mouse_up(Vec2 position) {}
        protected virtual void on_mouse_over() {}
        protected virtual void on_focus_lost() {}
        protected virtual void on_child_focus_lost() {}
        protected virtual void on_key_press(KeyArgs key) {}
        protected virtual void on_text_input(TextInputArgs text) {}
        protected virtual void on_text_edit(TextEditArgs text) {}
        public signal void clicked(Control control, Vec2 position);

        protected Control()
        {
            enabled = true;
            cursor_type = CursorType.HOVER;
        }

        public override void mouse_move(MouseMoveArgs mouse)
        {
            if (mouse.handled || !visible || !selectable)
            {
                hovering = false;

                if (!mouse_pressed)
                    return;
            }

            if (!hover_check(mouse.position) && !mouse_pressed)
            {
                hovering = false;

                if (!mouse_pressed)
                    return;
            }

            if (mouse_pressed && !hovering)
            {
                on_mouse_move(Vec2(mouse.position.x - rect.x, mouse.position.y - rect.y));
                return;
            }

            mouse.handled = true;

            if (!enabled)
            {
                hovering = false;
                return;
            }

            mouse.cursor_type = cursor_type;

            if (!hovering)
                on_mouse_over();
            hovering = true;

            on_mouse_move(Vec2(mouse.position.x - rect.x, mouse.position.y - rect.y));
        }

        public override void mouse_event(MouseEventArgs mouse)
        {
            if (!mouse.down && mouse_pressed)
                on_mouse_up(Vec2(mouse.position.x - rect.x, mouse.position.y - rect.y));

            if (mouse.handled || !visible || !selectable)
            {
                mouse_pressed = false;
                if (focused && mouse.down)
                    focus_lost();
                return;
            }

            if (!hover_check(mouse.position))
            {
                mouse_pressed = false;
                if (focused && mouse.down)
                    focus_lost();
                return;
            }

            mouse.handled = true;

            if (!enabled)
            {
                mouse_pressed = false;
                return;
            }

            if (mouse.down)
            {
                mouse_pressed = true;
                mouse_down(Vec2(mouse.position.x - rect.x, mouse.position.y - rect.y));
                return;
            }
            
            if (mouse_pressed)
            {
                mouse_pressed = false;
                click(Vec2(mouse.position.x - rect.x, mouse.position.y - rect.y));
            }
        }

        public override void key_press(KeyArgs key)
        {
            if (key.handled || !visible || !focused)
                return;

            on_key_press(key);
        }

        public override void text_input(TextInputArgs text)
        {
            if (text.handled || !visible || !focused)
                return;

            text.handled = true;

            on_text_input(text);
        }

        public override void text_edit(TextEditArgs text)
        {
            if (text.handled || !visible || !focused)
                return;

            text.handled = true;

            on_text_edit(text);
        }

        private void click(Vec2 position)
        {
            on_click(position);
            clicked(this, position);
        }

        private void mouse_down(Vec2 position)
        {
            focused = true;
            on_mouse_down(position);
        }

        private void focus_lost()
        {
            focused = false;
            on_focus_lost();
        }

        protected bool hover_check(Vec2i point)
        {
            if (!enabled || !visible || !selectable)
                return false;

            if (!rect.contains_vec2i(point))
                return false;

            if (scissor)
                return scissor_box.contains_vec2i(point);

            return true;
        }

        public bool enabled { get; set; }
        public bool hovering { get; private set; }
        public bool focused { get; private set; }
        public bool mouse_pressed { get; private set; }
        public bool selectable { get; set; }
        public CursorType cursor_type { get; public set; }
    }

    public abstract class EndControl : Control
    {
        private RenderObject2D obj;

        public override void added()
        {
            on_added();

            obj = get_obj();
            resize_style = ResizeStyle.ABSOLUTE;
            size = end_size;
        }

        public override void render(RenderState state, RenderScene2D scene)
        {
            obj.scissor = scissor;
            obj.scissor_box = scissor_box;
            scene.add_object(obj);
        }

        public override void resized()
        {
            Vec2 new_pos = Vec2((rect.x + rect.width / 2) / window_size.width * 2 - 1, (rect.y + rect.height / 2) / window_size.height * 2 - 1);
            Size2 new_scale = Size2(rect.width / window_size.width, rect.height / window_size.width);

            set_end_rect(Rectangle.vec(new_pos, new_scale));
        }

        private void set_end_rect(Rectangle rect)
        {
            obj.position = rect.position;
            obj.scale = rect.size;
        }

        protected virtual void on_added() {}
        //protected abstract void set_end_rect(Rectangle rect);
        //protected abstract void render_end(RenderScene2D scene);
        protected abstract RenderObject2D get_obj();
        public abstract Size2 end_size { get; }
    }
}