namespace Engine
{
    public abstract class Curve
    {
        public abstract float map(float x);
    }

    public class LinearCurve : Curve
    {
        public override float map(float x)
        {
            return x;
        }
    }

    public class SCurve : Curve
    {
        private float exp;

        public SCurve(float exp)
        {
            this.exp = exp;
        }

        public override float map(float x)
        {
            if (x <= 0.5f)
                return f(2 * x, exp) * 0.5f;
            return 0.5f * f(2 * (x - 0.5f), -exp) + 0.5f;
        }

        private static float f(float x, float k)
        {
            float t = k * x;
            return (t - x) / (2 * t - k - 1);
        }
    }

    public class ExponentCurve : Curve
    {
        private float exp;

        public ExponentCurve(float exp)
        {
            this.exp = exp;
        }

        public override float map(float x)
        {
            return (float)Math.pow(x, exp);
        }
    }

    public class SmoothApproachCurve : Curve
    {
        private float exp;

        public SmoothApproachCurve()
        {
            this.exp = 0.01f;
        }

        public override float map(float x)
        {
            float mul = (float)Math.pow(x, 0.5f);
            return (1 - mul) * x + (float)Math.pow(x, exp) * mul;
        }
    }

    public class SmoothDepartCurve : Curve
    {
        private SmoothApproachCurve curve;

        public SmoothDepartCurve()
        {
            curve = new SmoothApproachCurve();
        }

        public override float map(float x)
        {
            return 1 - curve.map(1 - x);
        }
    }
}