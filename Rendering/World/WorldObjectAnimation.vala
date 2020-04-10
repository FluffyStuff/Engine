namespace Engine
{
	public class WorldObjectAnimation
	{
		public signal void start(WorldObjectAnimation animation);
		public signal void animate(WorldObjectAnimation animation, float time);
		public signal void finish(WorldObjectAnimation animation);
		
		private Animation animation;

		public WorldObjectAnimation(AnimationTime time)
		{
			animation = new Animation(time);
			animation.animate_start.connect(animation_start);
			animation.animate.connect(animation_animate);
			animation.post_finished.connect(animation_finished);
		}

		public void process(DeltaArgs args)
		{
			animation.process(args);
		}

		public void do_relative_position(Path3D path)
		{
			position_path = path;
			position_path.relative = true;
		}

		public void do_absolute_position(Path3D path)
		{
			position_path = path;
		}

		public void do_relative_scale(Path3D path)
		{
			scale_path = path;
			scale_path.relative = true;
		}

		public void do_absolute_scale(Path3D path)
		{
			scale_path = path;
		}

		public void do_relative_rotation(PathQuat path)
		{
			rotation_path = path;
			rotation_path.relative = true;
		}

		public void do_absolute_rotation(PathQuat path)
		{
			rotation_path = path;
		}

		public void do_finish()
		{
			animation_animate(1);
			animation_finished();
		}

		private void animation_start()
		{
			start(this);
			
			if (position_path != null) position_path.init(start_position);
			if (scale_path != null) scale_path.init(start_scale);
			if (rotation_path != null) rotation_path.init(start_rotation);
		}

		private void animation_animate(float time)
		{
			animate(this, time);
		}

		private void animation_finished()
		{
			finish(this);
		}
		
		public Vec3 start_position { get; set; }
		public Vec3 start_scale { get; set; }
		public Quat start_rotation { get; set; }

		public Path3D? position_path { get; private set; }
		public Path3D? scale_path { get; private set; }
		public PathQuat? rotation_path { get; private set; }
		
		public Curve curve { get { return animation.curve; } set { animation.curve = value; } }
	}
}