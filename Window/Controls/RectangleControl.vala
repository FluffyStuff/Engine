public class RectangleControl : EndControl
{
    private RenderRectangle2D rectangle;

    public RectangleControl()
    {
        rectangle = new RenderRectangle2D();
    }

    protected override RenderObject2D get_obj()
    {
        return rectangle;
    }

    public Color color
    {
        get { return rectangle.diffuse_color; }
        set { rectangle.diffuse_color = value; }
    }

    public override Size2 end_size { get { return Size2(100, 100); } }
    public float rotation
    {
        get { return rectangle.rotation; }
        set { rectangle.rotation = value; }
    }
}
