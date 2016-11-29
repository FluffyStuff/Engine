using Gee;

public class ResourceStore : Object
{
    private unowned RenderTarget renderer;
    private AudioPlayer audio = new AudioPlayer();
    private LabelLoader label_loader = new LabelLoader();

    private ArrayList<ResourceCacheObject> cache = new ArrayList<ResourceCacheObject>();

    public ResourceStore(RenderTarget renderer)
    {
        this.renderer = renderer;
    }

    public RenderGeometry3D? load_geometry_3D(string filename, bool do_load_texture)
    {
        return load_geometry_3D_dir(MODEL_DIR, filename, do_load_texture);
    }

    public RenderGeometry3D? load_geometry_3D_dir(string dir, string filename, bool do_load_texture)
    {
        ResourceCacheObject? cache = get_cache_object(dir + filename, CacheObjectType.GEOMETRY);
        if (cache != null)
            return (RenderGeometry3D)((RenderGeometry3D)cache.obj).copy();

        GeometryData? data = ObjParser.parse(dir, filename);
        if (data == null)
            return null;

        ArrayList<RenderBody3D> objects = new ArrayList<RenderBody3D>();
        foreach (ModelData model in data.models)
        {
            RenderTexture? texture = null;
            if (do_load_texture)
                texture = load_texture(filename);

            RenderMaterial? mat = null;

            if (model.material_name != null)
            {
                foreach (MaterialData material in data.materials)
                {
                    if (material.name == model.material_name)
                    {
                        mat = new RenderMaterial();
                        mat.ambient_color = Color(material.ambient_color.x, material.ambient_color.y, material.ambient_color.z, 1);
                        mat.diffuse_color = Color(material.diffuse_color.x, material.diffuse_color.y, material.diffuse_color.z, 1);
                        mat.specular_color = Color(material.specular_color.x, material.specular_color.y, material.specular_color.z, 1);
                        mat.specular_exponent = material.specular_exponent;
                        mat.alpha = material.alpha;
                        break;
                    }
                }
            }

            if (mat == null)
                mat = new RenderMaterial();

            InputResourceModel mod = new InputResourceModel(model.points);
            var handle = renderer.load_model(mod);

            RenderModel m = new RenderModel(handle, model.name, model.size);

            RenderBody3D body = new RenderBody3D(m, mat);
            body.texture = texture;

            objects.add(body);
        }

        RenderGeometry3D geometry = new RenderGeometry3D.with_objects(objects);
        cache_object(dir + filename, CacheObjectType.GEOMETRY, geometry.copy());

        return geometry;
    }

    public RenderBody3D? load_body_3D(string filename, string modelname)
    {
        RenderGeometry3D geometry = load_geometry_3D(filename, true);

        foreach (Transformable3D o in geometry.geometry)
        {
            RenderBody3D obj = (RenderBody3D)o;
            if (obj.model.name == modelname)
                return obj;
        }

        return null;
    }

    public RenderModel? load_model(string filename, string modelname)
    {
        return load_model_dir(MODEL_DIR, filename, modelname);
    }

    public RenderTexture? load_texture(string filename)
    {
        return load_texture_dir(TEXTURE_DIR, filename);
    }

    public RenderModel? load_model_dir(string dir, string filename, string modelname)
    {
        RenderGeometry3D? geometry = load_geometry_3D_dir(dir, filename, false);

        foreach (Transformable3D o in geometry.geometry)
        {
            RenderBody3D obj = (RenderBody3D)o;
            if (obj.model.name == modelname)
                return obj.model;
        }

        return null;
    }

    public RenderTexture? load_texture_dir(string dir, string filename)
    {
        ResourceCacheObject? cache = get_cache_object(dir + filename, CacheObjectType.TEXTURE);
        if (cache != null)
            return (RenderTexture)cache.obj;

        string str = dir + filename + ".png";
        if (!FileLoader.exists(str))
            return null;

        ImageData img = ImageLoader.load_image(str);

        InputResourceTexture tex = new InputResourceTexture(img.data, img.size);
        var handle = renderer.load_texture(tex);

        RenderTexture texture = new RenderTexture(handle, img.size);
        cache_object(dir + filename, CacheObjectType.TEXTURE, texture);

        return texture;
    }

    public RenderLabel2D? create_label()
    {
        var handle = renderer.load_label();
        LabelResourceReference reference = new LabelResourceReference(handle, this);
        RenderLabel2D label = new RenderLabel2D(reference);

        return label;
    }

    public RenderLabel3D? create_label_3D()
    {
        var handle = renderer.load_label();
        LabelResourceReference reference = new LabelResourceReference(handle, this);
        RenderLabel3D label = new RenderLabel3D(reference, load_model("field", "Plane"));

        return label;
    }

    public void delete_label(LabelResourceReference reference)
    {
        renderer.unload_label(reference.handle);
    }

    private void cache_object(string name, CacheObjectType type, Object obj)
    {
        cache.add(new ResourceCacheObject(name, type, obj));
    }

    private ResourceCacheObject? get_cache_object(string name, CacheObjectType type)
    {
        foreach (ResourceCacheObject obj in cache)
            if (obj.obj_type == type && obj.name == name)
                return obj;
        return null;
    }

    public LabelInfo update_label(string font_type, float font_size, string text)
    {
        return label_loader.get_label_info(font_type, font_size, text);
    }

    public LabelBitmap generate_label_bitmap(RenderLabel2D label)
    {
        return label_loader.generate_label_bitmap(label.font_type, label.font_size, label.text);
    }

    public LabelBitmap generate_label_bitmap_3D(RenderLabel3D label)
    {
        return label_loader.generate_label_bitmap(label.font_type, label.font_size, label.text);
    }

    public AudioPlayer audio_player { get { return audio; } }

    /*public abstract RenderModel? load_model_dir(string dir, string name, bool center);
    public abstract RenderTexture? load_texture_dir(string dir, string name, bool tile);
    public abstract RenderLabel2D? create_label();
    public abstract RenderLabel3D? create_label_3D();
    public abstract void delete_label(LabelResourceReference reference);*/

    private const string DATA_DIR = "./Data/";
    protected const string MODEL_DIR = DATA_DIR + "Models/";
    protected const string TEXTURE_DIR = DATA_DIR + "Textures/";

    private class ResourceCacheObject
    {
        public ResourceCacheObject(string name, CacheObjectType type, Object obj)
        {
            this.name = name;
            this.obj_type = type;
            this.obj = obj;
        }

        public string name { get; private set; }
        public CacheObjectType obj_type { get; private set; }
        public Object obj { get; private set; }
    }

    private enum CacheObjectType
    {
        MODEL, // Not used anymore
        TEXTURE,
        MATERIAL, // Not used at all
        GEOMETRY
    }
}

public class InputResourceModel
{
    public InputResourceModel(ModelPoint[] points)
    {
        this.points = points;
    }

    public ModelPoint[] points { get; private set; }
}

public class InputResourceTexture
{
    public InputResourceTexture(uchar[] data, Size2i size)
    {
        this.data = data;
        this.size = size;
    }

    public uchar[] data { get; private set; }
    public Size2i size { get; private set; }
}

public class LabelResourceReference
{
    weak ResourceStore store;

    ~LabelResourceReference()
    {
        delete_label();
    }

    public LabelResourceReference(ILabelResourceHandle handle, ResourceStore store)
    {
        this.handle = handle;
        this.store = store;
    }

    public LabelInfo update(string font_type, float font_size, string text)
    {
        return store.update_label(font_type, font_size, text);
    }

    public void delete_label()
    {
        store.delete_label(this);

        handle = null;
        deleted = true;
    }

    public ILabelResourceHandle? handle { get; private set; }
    public bool deleted { get; private set; }
}

public class RenderModel : Object
{
    public RenderModel(IModelResourceHandle handle, string name, Vec3 size)
    {
        this.handle = handle;
        this.name = name;
        this.size = size;
    }

    public IModelResourceHandle handle { get; private set; }
    public string name { get; private set; }
    public Vec3 size { get; private set; }
}

public class RenderTexture : Object
{
    public RenderTexture(ITextureResourceHandle handle, Size2i size)
    {
        this.handle = handle;
        this.size = size;
    }

    public ITextureResourceHandle handle { get; private set; }
    public Size2i size { get; private set; }
}
