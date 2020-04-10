namespace Engine
{
    public class RenderTexture : IResource
    {
        public RenderTexture(ITextureResourceHandle handle, Size2i size)
        {
            this.handle = handle;
            this.size = size;
        }

        public override bool equals(IResource? other)
        {
            var ret = other as RenderTexture?;
            return ret != null && handle == ret.handle;
        }

        public ITextureResourceHandle handle { get; private set; }
        public Size2i size { get; private set; }
    }
}