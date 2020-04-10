namespace Engine
{
	public class WorldLight : WorldObject
	{
		private LightSource light = new LightSource();

		public WorldLight()
		{
			light.transform = transform;
		}

		protected override void do_add_to_scene(RenderScene3D scene)
		{
			scene.add_light_source(light);
		}

		public override void start_custom_animation(WorldObjectAnimation animation)
		{
			if (!(animation is WorldLightAnimation))
				return;
			
			WorldLightAnimation ani = animation as WorldLightAnimation;

			if (ani.relative_intensity)
				ani.start_intensity = intensity;
		}

		public override void process_custom_animation(WorldObjectAnimation animation, float time)
		{
			if (!(animation is WorldLightAnimation))
				return;
			
			WorldLightAnimation ani = animation as WorldLightAnimation;

			if (ani.use_intensity)
				intensity = ani.intensity_curve.map(time);
		}

		public float intensity { get { return light.intensity; } set { light.intensity = value; } }
		public Color color { get { return light.color; } set { light.color = value; } }
	}

	public class WorldLightAnimation : WorldObjectAnimation
	{
		public WorldLightAnimation(AnimationTime time)
		{
			base(time);
		}

		public void do_relative_intensity(Curve curve)
		{
			intensity_curve = curve;
			use_intensity = true;
			relative_intensity = true;
		}

		public void do_absolute_intensity(Curve curve, float start_intensity)
		{
			intensity_curve = curve;
			use_intensity = true;
			relative_intensity = false;
			this.start_intensity = start_intensity;
		}

		public bool use_intensity { get; private set; }
		public bool relative_intensity { get; private set; }
		public float start_intensity { get; set; }
		public Curve intensity_curve { get; private set; }
	}
}