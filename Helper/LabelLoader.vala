using GLib;
using Pango;

struct FT_Bitmap
{
    public uint   rows;
    public uint   width;
    public int    pitch;
    public uchar *buffer;
    public uint   num_grays;
    public uchar  pixel_mode;
    public uchar  palette_mode;
    public void  *palette;

    public FT_Bitmap()
    {
        rows = 0;
        width = 0;
        pitch = 0;
        buffer = null;
        num_grays = 0;
        pixel_mode = 0;
        palette_mode = 0;
        palette = null;
    }
}

extern void*   FcConfigCreate();
extern void    FcConfigSetCurrent(void *config);
extern bool    FcConfigAppFontAddDir(void *config, char *dir);
extern FontMap pango_ft2_font_map_new();
extern Context pango_ft2_font_map_create_context(FontMap map);
extern void    pango_ft2_render_layout(FT_Bitmap bitmap, Layout layout, int x, int y);

namespace Engine
{
    public class LabelLoader
    {
        private const int PANGO_SCALE = 64 * 16;
        private const float DPI_FACTOR = 96 / 72.0f;

        private static Mutex mutex = Mutex();
        private static FontMap map;
        private static bool initialized = false;

        public LabelLoader()
        {
            initialize();
        }

        public static void initialize()
        {
            mutex.lock();
            if (!initialized)
            {
                void *config = FcConfigCreate();
                FcConfigAppFontAddDir(config, "./Data/Fonts");
                FcConfigSetCurrent(config);
                map = pango_ft2_font_map_new();
                initialized = true;
            }
            mutex.unlock();
        }

        public LabelInfo get_label_info(string font_type, float font_size, string text)
        {
            return get_label_info_static(font_type, font_size, text);
        }

        public LabelBitmap generate_label_bitmap(string font_type, float font_size, string text)
        {
            return generate_label_bitmap_static(font_type, font_size, text);
        }

        public static LabelInfo get_label_info_static(string font_type, float font_size, string text)
        {
            initialize();

            font_size = font_size / DPI_FACTOR;
            return get_text_size(text, font_type + " " + font_size.to_string());
        }

        public static LabelBitmap generate_label_bitmap_static(string font_type, float font_size, string text)
        {
            initialize();

            font_size = font_size / DPI_FACTOR;
            return render_text(text, font_type + " " + font_size.to_string());
        }

        private static LabelInfo get_text_size(string text, string font)
        {
            mutex.lock();

            // Create a PangoLayout, set the font and text
            Context context = pango_ft2_font_map_create_context(map);
            Layout layout = new Layout(context);
            layout.set_text(text, -1);

            // Load the font
            FontDescription desc = FontDescription.from_string(font);
            layout.set_font_description(desc);

            // Get text dimensions and create a context to render to
            int text_width, text_height;
            layout.get_size(out text_width, out text_height);
            text_width /= PANGO_SCALE;
            text_height /= (int)(PANGO_SCALE * 1.25f);

            // Avoids alignment issues
            if (text_width % 2 != 0)
                text_width++;
            if (text_height % 2 != 0)
                text_height++;

            mutex.unlock();

            return new LabelInfo(Size2i(text_width, text_height));
        }

        private static LabelBitmap render_text(string text, string font)
        {
            mutex.lock();

            // Create a PangoLayout, set the font and text
            Context context = pango_ft2_font_map_create_context(map);
            Layout layout = new Layout(context);
            layout.set_text(text, -1);

            // Load the font
            FontDescription desc = FontDescription.from_string(font);
            layout.set_font_description(desc);

            // Get text dimensions and create a context to render to
            int text_width, text_height, channels = 4;
            layout.get_size(out text_width, out text_height);
            text_width /= PANGO_SCALE;
            text_height /= (int)(PANGO_SCALE * 1.25f);

            // Avoids alignment issues
            if (text_width % 2 != 0)
                text_width++;
            if (text_height % 2 != 0)
                text_height++;

            // Create a rendering bitmap
            uchar[] buffer = new uchar[text_width * text_height];
            FT_Bitmap bitmap = FT_Bitmap();
            bitmap.width = text_width;
            bitmap.rows = text_height;
            bitmap.buffer = buffer;
            bitmap.pitch = text_width;

            // Render
            pango_ft2_render_layout(bitmap, layout, 0, -text_height / 5);

            uchar[] surface_data = new uchar[channels * text_width * text_height];
            for (int i = 0; i < surface_data.length / 4; i++)
            {
                uchar u = buffer[i];
                surface_data[4 * i + 0] = u;
                surface_data[4 * i + 1] = u;
                surface_data[4 * i + 2] = u;
                surface_data[4 * i + 3] = u;
            }

            LabelBitmap bitmp = new LabelBitmap(surface_data, Size2i(text_width, text_height));

            mutex.unlock();

            return bitmp;
        }
    }

    public class LabelInfo
    {
        public LabelInfo(Size2i size)
        {
            this.size = size;
        }

        public Size2i size { get; private set; }
    }

    public class LabelBitmap
    {
        public LabelBitmap(uchar[] data, Size2i size)
        {
            this.data = data;
            this.size = size;
        }

        public uchar[] data { get; private set; }
        public Size2i size { get; private set; }
    }
}