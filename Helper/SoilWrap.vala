// libSOIL is not thread safe, so let's use this thread safe wrapper
public class SoilWrap : Object
{
    private static Mutex mutex = Mutex();

    private SoilWrap() {}

    public static ImageData load_image(string name)
    {
        int width, height;

        mutex.lock();
        uchar *image = SOIL.load_image(name, out width, out height, null, SOIL.LoadFlags.RGBA);
        mutex.unlock();

        uchar[] data = new uchar[width * height * 4];
        Memory.copy(data, image, sizeof(uchar) * data.length);
        delete image;

        return new ImageData(data, Size2i(width, height));
    }
}
