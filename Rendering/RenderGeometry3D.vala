using Gee;

public abstract class Transformable3D : Object
{
    protected bool dirty = false;
    protected Vec3 _position = Vec3.empty();
    protected Vec3 _scale = Vec3(1, 1, 1);
    protected Quat _rotation = new Quat();
    protected Mat4 _transform = new Mat4();

    protected virtual void calculate_transform()
    {
        if (!dirty)
            return;

        Mat4 t = Calculations.translation_matrix(get_internal_position());
        Mat4 s = Calculations.scale_matrix(get_internal_scale());
        Mat4 r = Calculations.rotation_matrix_quat(get_internal_rotation());

        _transform = s.mul_mat(r).mul_mat(t);
        dirty = false;
    }

    public Transformable3D copy()
    {
        Transformable3D t = copy_transformable();
        calculate_transform();
        t._transform = _transform.copy();
        t._position = _position;
        t._scale = _scale;
        t._rotation = _rotation;

        return t;
    }

    protected abstract Transformable3D copy_transformable();
    protected virtual Vec3 get_internal_position() { return _position; }
    protected virtual Vec3 get_internal_scale() { return _scale; }
    protected virtual Quat get_internal_rotation() { return _rotation; }

    public virtual Vec3 position
    {
        get { return _position; }
        set
        {
            _position = value;
            dirty = true;
        }
    }

    public virtual Vec3 scale
    {
        get { return _scale; }
        set
        {
            _scale = value;
            dirty = true;
        }
    }

    public virtual Quat rotation
    {
        get { return _rotation; }
        set
        {
            _rotation = value;
            dirty = true;
        }
    }

    public virtual Mat4 transform
    {
        get
        {
            calculate_transform();
            return _transform;
        }
    }
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
    }

    public RenderGeometry3D.with_transformables(ArrayList<Transformable3D> geometry)
    {
        this.geometry = geometry;
    }

    public override Transformable3D copy_transformable()
    {
        RenderGeometry3D geo = new RenderGeometry3D();

        foreach (Transformable3D transformable in geometry)
            geo.geometry.add(transformable.copy());

        return geo;
    }

    public ArrayList<Transformable3D> geometry { get; private set; }
}
