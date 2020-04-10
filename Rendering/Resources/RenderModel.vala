namespace Engine
{
    public class RenderModel : IResource
    {
        public RenderModel(IModelResourceHandle handle, string name, Vec3 size)
        {
            this.handle = handle;
            this.name = name;
            this.size = size;
        }

        public override bool equals(IResource? other)
        {
            var ret = other as RenderModel?;
            return ret != null && handle == ret.handle;
        }

        public IModelResourceHandle handle { get; private set; }
        public string name { get; private set; }
        public Vec3 size { get; private set; }
    }
}