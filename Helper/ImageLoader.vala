public class ImageLoader
{
    private ImageLoader() {}

    public static ImageData? load_image(string name)
    {
        return ImageLoadWrap.load_image(name);
    }
}

public class ImageData
{
    public ImageData(uchar[] data, Size2i size)
    {
        this.data = data;
        this.size = size;
    }

    public uchar[] data { get; private set; }
    public Size2i size { get; private set; }
}
