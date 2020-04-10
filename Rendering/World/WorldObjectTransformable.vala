namespace Engine
{
	public class WorldObjectTransformable : WorldObject
	{
		protected void set_object(Transformable3D obj)
		{
			transformable = obj;
			transformable.transform.change_parent(transform);

			if (obj is RenderObject3D)
			{
				var o = obj as RenderObject3D;
				obb = o.obb;
			}
		}

		protected override void do_add_to_scene(RenderScene3D scene)
		{
			if (transformable != null)
				scene.add_object(transformable);
		}

		public Transformable3D? transformable { get; private set; }
	}

	public class SimpleWorldObject : WorldObject
	{
		public SimpleWorldObject(RenderObject3D obj)
		{
			object = obj;
			obb = object.obb;
		}

		protected override void do_add_to_scene(RenderScene3D scene)
		{
			scene.add_object(object);
		}

		public RenderObject3D object { get; private set; }
		public RenderMaterial material { get { return object.material; } }
	}
}