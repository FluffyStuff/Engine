using Gee;

namespace Engine
{
    public abstract class Transformable3D : IResource
    {
        protected Transformable3D()
        {
            transform = new Transform();
        }

        public Transformable3D copy()
        {
            return copy_transformable(transform.copy_full_parentless());
        }

        protected Transformable3D copy_internal()
        {
            return copy_transformable(transform.copy_shallow_parentless());
        }

        protected abstract Transformable3D copy_transformable(Transform transform);
        
        public Transform transform { get; set; }
    }

    public class RenderGeometry3D : Transformable3D
    {
        public RenderGeometry3D()
        {
            geometry = new ArrayList<Transformable3D>();
        }

        public RenderGeometry3D.with_objects(ArrayList<RenderObject3D> objects)
        {
            geometry = new ArrayList<Transformable3D>();
            geometry.add_all(objects);

            foreach (RenderObject3D obj in objects)
                obj.transform.change_parent(transform);
        }

        public RenderGeometry3D.with_transformables(ArrayList<Transformable3D> geometry)
        {
            this.geometry = geometry;
        }

        public override Transformable3D copy_transformable(Transform transform)
        {
            RenderGeometry3D geo = new RenderGeometry3D();
            geo.transform = transform;

            foreach (Transformable3D transformable in geometry)
            {
                var trans = transformable.copy_internal();
                geo.geometry.add(trans);
                trans.transform.change_parent(geo.transform);
            }

            return geo;
        }

        public ArrayList<Transformable3D> geometry { get; private set; }
    }
}