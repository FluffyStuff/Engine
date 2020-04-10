namespace Engine
{
    public abstract class IResource
    {
        public virtual bool equals(IResource? other) { return false; }
    }

    public interface IModelResourceHandle : Object {}
    public interface ITextureResourceHandle : Object {}
    public interface IMaterialResourceHandle : Object {}
    public interface ILabelResourceHandle : Object {}
}