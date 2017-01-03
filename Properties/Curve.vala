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
