public class ScrollBarControl : Control
{
    private bool vertical;

    private int _minimum = 0;
    private int _maximum = 10;
    private int _current_value = 10;
    private int _scroll_amount = 1;

    private GameMenuButton up_button;
    private GameMenuButton down_button;
    private ScrollRectangle scroll_rect;

    public signal void value_changed(ScrollBarControl scroll_bar);

    public ScrollBarControl(bool vertical)
    {
        this.vertical = vertical;
    }

    protected override void added()
    {
        RectangleControl background = new RectangleControl();
        add_child(background);
        background.color = Color(0.5f, 0, 0, 1);
        background.resize_style = ResizeStyle.RELATIVE;

        up_button = new GameMenuButton(vertical ? "UpButton" : "Next");
        add_child(up_button);
        up_button.inner_anchor = Vec2(vertical ? 0.5f : 1, vertical ? 1 : 0.5f);
        up_button.outer_anchor = Vec2(vertical ? 0.5f : 1, vertical ? 1 : 0.5f);
        up_button.clicked.connect(up_pressed);

        down_button = new GameMenuButton(vertical ? "DownButton" : "Prev");
        add_child(down_button);
        down_button.inner_anchor = Vec2(vertical ? 0.5f : 0, vertical ? 0 : 0.5f);
        down_button.outer_anchor = Vec2(vertical ? 0.5f : 0, vertical ? 0 : 0.5f);
        down_button.clicked.connect(down_pressed);

        scroll_rect = new ScrollRectangle(vertical);
        add_child(scroll_rect);
        scroll_rect.color = Color(1, 0, 0, 1);
        scroll_rect.selectable = true;
        scroll_rect.scrolled.connect(scrolled);

        resize_style = ResizeStyle.ABSOLUTE;
    }

    protected override void resized()
    {
        up_button.size = Size2(size.height, size.height);
        down_button.size = Size2(size.height, size.height);

        adjust_scroll();
    }

    private void up_pressed()
    {
        current_value += scroll_amount;
    }

    private void down_pressed()
    {
        current_value -= scroll_amount;
    }

    private void scrolled()
    {
        float f;
        if (vertical)
            f = (scroll_rect.position.y / (size.height / 2 - up_button.size.height - scroll_rect.size.height / 2) + 1) / 2;
        else
            f = (scroll_rect.position.x / (size.width / 2 - up_button.size.width - scroll_rect.size.width / 2) + 1) / 2;

        current_value = minimum + (int)Math.round(range * f);
    }

    private void adjust_scroll()
    {
        if (vertical)
        {
            float h = size.height - up_button.size.height - down_button.size.height;
            float s = float.max(h / (range + 1), size.width);
            scroll_rect.size = Size2(size.width, s);

            float start = -size.height / 2 + down_button.size.height + scroll_rect.size.height / 2;
            float end   =  size.height / 2 -   up_button.size.height - scroll_rect.size.height / 2;
            float height = start + (end - start) * fval;

            scroll_rect.position = Vec2(0, height);
        }
        else
        {
            float w = size.width - up_button.size.width - down_button.size.width;
            float s = float.max(w / (range + 1), size.height);
            scroll_rect.size = Size2(s, size.height);

            float start = -size.width / 2 + down_button.size.width + scroll_rect.size.width / 2;
            float end   =  size.width / 2 -   up_button.size.width - scroll_rect.size.width / 2;
            float width = start + (end - start) * fval;

            scroll_rect.position = Vec2(width, 0);
        }
    }

    public int minimum
    {
        get { return _minimum; }
        set
        {
            _minimum = int.min(value, maximum);
            _current_value = int.max(_minimum, value);

            adjust_scroll();
            value_changed(this);
        }
    }

    public int maximum
    {
        get { return _maximum; }
        set
        {
            _maximum = int.max(value, minimum);
            _current_value = int.min(_maximum, value);

            adjust_scroll();
            value_changed(this);
        }
    }

    public int current_value
    {
        get { return _current_value; }
        set
        {
            _current_value = int.min(int.max(value, minimum), maximum);

            adjust_scroll();
            value_changed(this);
        }
    }

    public int scroll_amount
    {
        get { return _scroll_amount; }
        set
        {
            _scroll_amount = int.max(value, 1);
        }
    }

    public int range { get { return maximum - minimum; } }
    public float fval { get { return (current_value - minimum) / float.max(range, 1); } }

    private class ScrollRectangle : RectangleControl
    {
        private bool vertical;

        private Vec2 last_position;
        private Vec2 mouse_down_position;

        public signal void scrolled();

        public ScrollRectangle(bool vertical)
        {
            this.vertical = vertical;
        }

        protected override void on_mouse_down(Vec2 position)
        {
            mouse_down_position = position;
        }

        protected override void on_mouse_move(Vec2 position)
        {
            if (mouse_down && position != last_position)
            {
                last_position = position;
                if (vertical)
                    this.position = Vec2(this.position.x, this.position.y + position.y - mouse_down_position.y);
                else
                    this.position = Vec2(this.position.x + position.x - mouse_down_position.x, this.position.y);
                scrolled();
            }
        }
    }
}
