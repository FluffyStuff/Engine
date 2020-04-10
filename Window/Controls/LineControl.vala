namespace Engine
{
    public class LineControl : Control
    {
        private RectangleControl line;
        private Vec2 _distance;

        public LineControl()
        {
            line = new RectangleControl();
        }

        public override void pre_added()
        {
            add_child(line);
            resize_style = ResizeStyle.ABSOLUTE;
            size = Size2(0, 0);
            line.resize_style = ResizeStyle.ABSOLUTE;
            line.size = Size2(0, 0);
        }

        private void reposition()
        {
            line.position = Vec2(distance.x / 2, distance.y / 2);
            line.rotation = (float)Math.atan2(distance.y, distance.x) / (float)Math.PI + 0.5f;
            line.size = Size2(line.size.width, (float)Math.sqrt(distance.x * distance.x + distance.y * distance.y));
            set_line_end_pos(distance);
        }

        protected virtual void set_line_end_pos(Vec2 position) {}

        public Vec2 distance
        {
            get { return _distance; }
            set
            {
                _distance = value;
                reposition();
            }
        }

        public float width
        {
            get { return line.size.width; }
            set { line.size = Size2(value, line.size.height); }
        }

        public Color color
        {
            get { return line.color; }
            set { line.color = value; }
        }
    }
}