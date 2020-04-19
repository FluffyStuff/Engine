using Gee;

namespace Engine
{
	public class PickingResult
	{
		public PickingResult(Ray ray)
		{
			this.ray = ray;
			distance = -1;
		}

		public Ray ray { get; private set; }
		public WorldObject? obj { get; set; }
		public float distance { get; set; }
	}

	public class World
	{
		private MainWorldObject world_transform;
		private unowned View3D parent;
		private WorldObject? hovered_object;
		private WorldObject? mouse_down_object;

		public World(View3D parent, ResourceStore store)
		{
			EngineLog.log(EngineLogType.DEBUG, "World", "Creating world object");
			
			this.parent = parent;
			world_transform = new MainWorldObject(store);
		}

		~World()
		{
			EngineLog.log(EngineLogType.DEBUG, "World", "Destroying world object");
		}

		public void process(DeltaArgs args)
		{
			world_transform.start_process(args);
		}

		public void add_to_scene(RenderScene3D scene)
		{
			world_transform.add_to_scene(scene);

			if (active_camera != null)
				scene.set_camera(active_camera.camera);
		}

		public void add_object(WorldObject object)
		{
			world_transform.add_object(object);
		}

		public void remove_object(WorldObject object)
		{
			world_transform.remove_object(object);
		}

		public void mouse_event(MouseEventArgs mouse)
		{
			if (!do_picking || mouse.handled || hovered_object == null)
			{
				mouse_down_object = null;
				return;
			}

			if (mouse.down)
			{
				mouse_down_object = hovered_object;
				mouse_down_object.on_mouse_down(mouse_down_object);
			}
			else if (mouse_down_object != null)
			{
				mouse_down_object.on_mouse_up(mouse_down_object);
				mouse_down_object.on_click(mouse_down_object);
				mouse_down_object = null;
			}
		}

		public void mouse_move(MouseMoveArgs mouse)
		{
			WorldObject? prev = hovered_object;

			if (do_picking && active_camera != null && !mouse.handled && parent.rect.contains_vec2i(mouse.position)
			&& (!parent.scissor || parent.scissor_box.contains_vec2i(mouse.position)))
			{
				Vec2 pos = Vec2(mouse.position.x - parent.rect.x, mouse.position.y - parent.rect.y);
				Ray ray = Calculations.get_ray(projection_matrix, view_matrix, pos, parent.size);
				PickingResult pick = new PickingResult(ray);
				world_transform.get_picking(pick);

				hovered_object = pick.obj;
			}
			else
				hovered_object = null;
			
			if (prev != hovered_object)
			{
				mouse_down_object = null;
				if (prev != null)
					prev.on_focus_lost(prev);
				if (hovered_object != null)
					hovered_object.on_mouse_over(hovered_object);
			}
		}

		public Vec2 position_to_point(Vec3 position)
		{
			Vec4 p = Vec4(position.x, position.y, position.z, 1);
			p = projection_matrix.mul_vec(view_matrix.mul_vec(p));
			Vec2 point = p.vec2();
			point = Vec2((point.x + 1) / 2 * parent.size.width, (point.y + 1) / 2 * parent.size.height);

			return point;
		}

		public WorldCamera? active_camera { get; set; }
		public bool do_picking { get; set; }

		public Mat4? projection_matrix
		{
			owned get
			{
				if (parent != null && active_camera != null)
					return parent.window.renderer.get_projection_matrix(active_camera.view_angle, parent.size);
				else
					return null;
			}
		}

		public Mat4? view_matrix
		{
			get
			{
				if (active_camera != null)
					return active_camera.camera.get_view_transform().matrix;
				else
					return null;
			}
		}
	}

	public class MainWorldObject : WorldObject
	{
		public MainWorldObject(ResourceStore store)
		{
			this.store = store;
		}

		public void start_process(DeltaArgs args)
		{
			do_process(args);
		}
	}
}