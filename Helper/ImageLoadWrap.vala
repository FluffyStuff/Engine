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

            string? file = FileLoader.find_file(name);
            if (file == null)
            {
                EngineLog.log(EngineLogType.ERROR, "ImageLoadWrap.load_image", "Could not find file: " + name);
                return null;
            }

            mutex.lock();
            uchar* image = stb.load(file, out width, out height);
            mutex.unlock();
            
            if (image == null)
            {
                EngineLog.log(EngineLogType.ERROR, "ImageLoadWrap.load_image", "Error while loading: " + file);
                return null;
            }

            uchar[] data = new uchar[width * height * 4];
            Memory.copy(data, image, sizeof(uchar) * data.length);
            delete image;

            return new ImageData(data, Size2i(width, height));
        }
    }
}