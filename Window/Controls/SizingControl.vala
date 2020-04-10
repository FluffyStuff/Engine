using Gee;

namespace Engine
{
    public class SizingControl : Container
    {
        private SizingStyle _sizing_style = SizingStyle.EVEN;
        private Orientation _orientation = Orientation.HORIZONTAL;
        private float _padding = 0;
        private Size2 _default_size = Size2(100, 100);
        private bool doing_layout = false;
        private ArrayList<SizingContainer> containers = new ArrayList<SizingContainer>();

        public void add_control(Container container)
        {
            foreach (SizingContainer c in containers)
                if (c.child == container)
                    return;

            SizingContainer c = new SizingContainer(container);
            containers.add(c);
            add_child(c);
            c.resize_style = ResizeStyle.ABSOLUTE;
            c.size = default_size;
            c.inner_anchor = Vec2(0, 1);
            c.outer_anchor = Vec2(0, 1);
            c.child.visible_changed.connect(resized);
            c.child.size_changed.connect(resized);

            do_layout();
        }

        public void remove_control(Container container)
        {
            foreach (SizingContainer c in containers)
                if (c.child == container)
                {
                    c.child.visible_changed.disconnect(resized);
                    c.child.size_changed.disconnect(resized);
                    remove_child(c.child);
                    containers.remove(c);

                    do_layout();
                    return;
                }
        }

        protected override void resized()
        {
            if (!doing_layout)
                do_layout();
        }

        private void do_layout()
        {
            if (containers.size == 0)
                return;

            doing_layout = true;

            if (sizing_style == SizingStyle.EVEN)
                do_even_layout();
            else if (sizing_style == SizingStyle.AUTOSIZE)
                do_autosize_layout();

            doing_layout = false;
        }

        private void do_even_layout()
        {
            int count = 0;
            foreach (SizingContainer c in containers)
                if (c.child.visible)
                    count++;

            float pad = padding * (count - 1);

            Size2 size;
            if (orientation == Orientation.VERTICAL)
                size = Size2(this.size.width, (this.size.height - pad) / count);
            else
                size = Size2((this.size.width - pad) / count, this.size.height);

            Vec2 pos = Vec2(0, 0);
            foreach (SizingContainer c in containers)
            {
                if (!c.child.visible)
                    continue;

                c.size = size;
                c.position = pos;

                if (orientation == Orientation.VERTICAL)
                    pos = pos.plus(Vec2(0, -(size.height + padding)));
                else
                    pos = pos.plus(Vec2(size.width + padding, 0));
            }
        }

        private void do_autosize_layout()
        {
            int count = 0;
            foreach (SizingContainer c in containers)
                if (c.child.visible)
                    count++;

            Size2 size = orientation == Orientation.VERTICAL ? Size2(0, padding * (count - 1)) : Size2(padding * (count - 1), 0);

            foreach (SizingContainer c in containers)
            {
                if (!c.child.visible)
                    continue;

                Size2 s = c.child.resize_style == ResizeStyle.RELATIVE ? default_size : c.child.size;

                if (orientation == Orientation.VERTICAL)
                    size = Size2(Math.fmaxf(size.width, s.width), size.height + s.height);
                else
                    size = Size2(size.width + s.width, Math.fmaxf(size.height, s.height));

                c.size = s;
            }

            this.size = size;

            float pos = 0;
            foreach (SizingContainer c in containers)
            {
                if (!c.child.visible)
                    continue;

                Size2 s = c.child.resize_style == ResizeStyle.RELATIVE ? default_size : c.child.size;

                if (orientation == Orientation.VERTICAL)
                {
                    c.position = Vec2((size.width - s.width) / 2, -pos);
                    pos += s.height + padding;
                }
                else
                {
                    c.position = Vec2(pos, -(size.height - s.height) / 2);
                    pos += s.width + padding;
                }
            }
        }

        public SizingStyle sizing_style
        {
            get { return _sizing_style; }
            set
            {
                _sizing_style = value;

                if (value == SizingStyle.AUTOSIZE)
                    resize_style = ResizeStyle.ABSOLUTE;

                do_layout();
            }
        }

        public Orientation orientation
        {
            get { return _orientation; }
            set
            {
                _orientation = value;
                do_layout();
            }
        }

        public float padding
        {
            get { return _padding; }
            set
            {
                _padding = value;
                do_layout();
            }
        }

        public Size2 default_size
        {
            get { return _default_size; }
            set
            {
                _default_size = value;
                do_layout();
            }
        }

        private class SizingContainer : Container
        {
            public SizingContainer(Container child)
            {
                this.child = child;
            }

            public override void pre_added()
            {
                add_child(child);
            }

            public Container child { get; private set; }
        }
    }

    public enum SizingStyle
    {
        EVEN,
        AUTOSIZE
    }
}