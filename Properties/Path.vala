namespace Engine
{
	public abstract class Path3D
	{
		public abstract Vec3 map(float time);

		public void init(Vec3 start)
		{
			this.start = start;
			do_init();
		}

		protected virtual void do_init() {}

		public Vec3 start { get; private set; }
		public bool relative { get; set; }
	}

	public class LinearPath3D : Path3D
	{
		public LinearPath3D(Vec3 end)
		{
			this.end = end;
		}

		protected override void do_init()
		{
			if (relative)
				end = start.plus(end);
		}

		public override Vec3 map(float time)
		{
			return Vec3.lerp(start, end, time);
		}

		public Vec3 end { get; private set; }
	}

	public class LinearizedPath3D : Path3D
	{
		private float[] lengths;
		private Vec3[] points;
		private float total_length;

		public LinearizedPath3D(Vec3[] points)
		{
			this.points = points;
		}

		protected override void do_init()
		{
			lengths = new float[points.length];

			for (int i = 0; i < points.length; i++)
			{
				if (relative)
					points[i] = start.plus(points[i]);

				Vec3 s = i == 0 ? start : points[i - 1];
				Vec3 e = points[i];

				total_length += lengths[i] = e.minus(s).length();
			}
		}

		public override Vec3 map(float time)
		{
			float prev_len = 0;
			float len = 0;

			for (int i = 0; i < points.length; i++)
			{
				len += lengths[i];

				if (time <= len / total_length)
				{
					Vec3 s = i == 0 ? start : points[i - 1];
					Vec3 e = points[i];

					float t = (time * total_length - prev_len) / (len - prev_len);

					return Vec3.lerp(s, e, t);
				}

				prev_len = len;
			}

			return start;
		}
	}

	public abstract class PathQuat
	{
		public void init(Quat start)
		{
			this.start = start;
			do_init();
		}

		public abstract Quat map(float time);

		protected virtual void do_init() {}

		public bool relative { get; set; }
		public Quat start { get; private set; }
	}

	public class LinearPathQuat : PathQuat
	{
		public LinearPathQuat(Quat end)
		{
			this.end = end;
		}

		protected override void do_init()
		{
			if (relative)
				end = start.mul(end);
		}

		public override Quat map(float time)
		{
			return Quat.slerp(start, end, time);
		}

		public Quat end { get; private set; }
	}
}