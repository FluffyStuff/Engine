namespace Engine
{
    public struct Rectangle
    {
        float x;
        float y;
        float width;
        float height;

        public Rectangle(float x, float y, float width, float height)
        {
            this.x = x;
            this.y = y;
            this.width = width;
            this.height = height;
        }

        public Rectangle.vec(Vec2 position, Size2 size)
        {
            x = position.x;
            y = position.y;
            width = size.width;
            height = size.height;
        }

        public bool contains_vec2i(Vec2i point)
        {
            return contains_vec2(Vec2(point.x, point.y));
        }

        public bool contains_vec2(Vec2 point)
        {
            return
            (
                point.x >= x &&
                point.x <= x + width &&
                point.y >= y &&
                point.y <= y + height
            );
        }

        public Vec2 position { get { return Vec2(x, y); } }
        public Size2 size { get { return Size2(width, height); } }
    }
}