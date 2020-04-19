namespace Engine
{
    // stb is not thread safe, so let's use this thread safe wrapper
    public class ImageLoadWrap : Object
    {
        private static Mutex mutex = Mutex();

        private ImageLoadWrap() {}

        public static ImageData? load_image(string name)
        {
            int width, height;

            mutex.lock();
            uchar* image = stb.load(name, out width, out height);
            mutex.unlock();
            
            if (image == null)
            {
                EngineLog.log(EngineLogType.ERROR, "ImageLoadWarp.load_image", "Error while loading: " + name);
                return null;
            }

            uchar[] data = new uchar[width * height * 4];
            Memory.copy(data, image, sizeof(uchar) * data.length);
            delete image;

            return new ImageData(data, Size2i(width, height));
        }
    }
}