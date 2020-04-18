using Gee;

namespace Engine
{
	public class WorldObject
	{
		private ArrayList<WorldObjectAnimation> buffered_animations = new ArrayList<WorldObjectAnimation>();
		private ArrayList<WorldObjectAnimation> unbuffered_animations = new ArrayList<WorldObjectAnimation>();
		private ArrayList<WorldObject> objects = new ArrayList<WorldObject>();
		private WorldObject? parent;
		private bool loaded;

		public signal void animation_finished(WorldObject object, WorldObjectAnimation animation);
		public signal void on_click(WorldObject object);
		public signal void on_mouse_down(WorldObject object);
		public signal void on_mouse_up(WorldObject object);
		public signal void on_mouse_over(WorldObject object);
		public signal void on_focus_lost(WorldObject object);

		public WorldObject()
		{
			transform = new Transform();
			visible = true;
		}

		protected void add(ResourceStore store, WorldObject parent)
		{
			this.store = store;
			added();
		}

		protected void do_process(DeltaArgs args)
		{
			foreach (var animation in unbuffered_animations)
				animation.process(args);

			if (buffered_animations.size > 0)
				buffered_animations[0].process(args);
			
			process(args);

			foreach (WorldObject object in objects)
				object.do_process(args);
		}

		public void animate(WorldObjectAnimation animation, bool buffered = true)
		{
			if (buffered)
				buffered_animations.add(animation);
			else
				unbuffered_animations.add(animation);
			
			animation.start.connect(start_animation);
			animation.animate.connect(process_animation);
			animation.finish.connect(finish_animation);
		}

		public void finish_animations()
		{
			foreach (var animation in unbuffered_animations)
				animation.do_finish();
			foreach (var animation in buffered_animations)
				animation.do_finish();
			unbuffered_animations.clear();
			buffered_animations.clear();
		}

		public void cancel_animations()
		{
			cancel_buffered_animations();
			cancel_unbuffered_animations();
		}

		public void cancel_buffered_animations()
		{
			buffered_animations.clear();
		}

		public void cancel_unbuffered_animations()
		{
			unbuffered_animations.clear();
		}

		public void remove_animation(WorldObjectAnimation animation)
		{
			buffered_animations.remove(animation);
			unbuffered_animations.remove(animation);
		}
		
		private void start_animation(WorldObjectAnimation animation)
		{
			if (animation.position_path != null)
				animation.start_position = transform.position;
			if (animation.scale_path != null)
				animation.start_scale = transform.scale;
			if (animation.rotation_path != null)
				animation.start_rotation = transform.rotation;
			
			start_custom_animation(animation);
		}

		private void process_animation(WorldObjectAnimation animation, float time)
		{
			if (animation.position_path != null)
				transform.position = animation.position_path.map(time);
			if (animation.scale_path != null)
				transform.scale = animation.scale_path.map(time);
			if (animation.rotation_path != null)
				transform.rotation = animation.rotation_path.map(time);

			process_custom_animation(animation, time);
			apply_transform(transform);
		}

		private void finish_animation(WorldObjectAnimation animation)
		{
			remove_animation(animation);
			animation_finished(this, animation);
		}

		public virtual void get_picking(PickingResult result)
		{
			foreach (WorldObject obj in objects)
				obj.get_picking(result);

			if (!selectable)
				return;

			float dist = Calculations.get_collision_distance(result.ray, obb, transform.get_full_matrix());
			if (dist < 0)
				return;

			if (result.distance < 0 || dist < result.distance)
			{
				result.obj = this;
				result.distance = dist;
			}
		}

		public void add_object(WorldObject object)
		{
			objects.add(object);

			object.store = store;
			object.transform.change_parent(transform);

			if (!object.loaded)
			{
				object.parent = this;
				object.added();
			}
			else
			{
				object.parent.objects.remove(object);
				object.parent = this;
			}

			object.loaded = true;
		}

		public void remove_object(WorldObject object)
		{
			objects.remove(object);
			object.transform.change_parent(null);
			object.parent = null;
		}

		public void convert_object(WorldObject object)
		{
			objects.add(object);

			object.store = store;
			object.transform.convert_to_parent(transform);

			if (!object.loaded)
			{
				object.parent = this;
				object.added();
			}
			else
			{
				object.parent.objects.remove(object);
				object.parent = this;
			}
		}

		public void unconvert_object(WorldObject object)
		{
			objects.remove(object);
			object.transform.convert_to_parent(null);
			object.parent = null;
		}

		public void add_to_scene(RenderScene3D scene)
		{
			if (!visible)
				return;
			
			foreach (WorldObject object in objects)
				object.add_to_scene(scene);
			
			do_add_to_scene(scene);
		}

		public WorldObject? get_parent()
		{
			return parent;
		}

		protected virtual void added() {}
		protected virtual void start_custom_animation(WorldObjectAnimation animation) {}
		protected virtual void process_custom_animation(WorldObjectAnimation animation, float time) {}

		protected virtual void process(DeltaArgs args) {}
		protected virtual void apply_transform(Transform transform) {}
		protected virtual void do_add_to_scene(RenderScene3D scene) {}

		public Vec3 position
		{
			get { return transform.position; }
			set { transform.position = value; }
		}

		public Vec3 scale
		{
			get { return transform.scale; }
			set { transform.scale = value; }
		}

		public Quat rotation
		{
			get { return transform.rotation; }
			set { transform.rotation = value; }
		}

		public Transform transform { get; protected set; }
		public bool selectable { get; set; }
		public bool visible { get; set; }
		public Vec3 obb { get; protected set; }
		protected weak ResourceStore store { get; protected set; }
	}
}