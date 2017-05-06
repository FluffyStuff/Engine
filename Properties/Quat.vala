public class Quat
{
    public Quat()
    {
        w = 1;
    }

    public Quat.from_euler(float roll, float pitch, float yaw)
    {
		init(roll, pitch, yaw);
    }

    public Quat.from_euler_vec(Vec3 vec)
    {
        init(vec.x, vec.y, vec.z);
    }
	
	private void init(float roll, float pitch, float yaw)
	{
        // Multiply with pi to simplify use
        float pi = (float)Math.PI;
        roll  *= pi;
        pitch *= pi;
        yaw   *= pi;

        float cr = (float)Math.cos(roll  / 2);
        float cp = (float)Math.cos(pitch / 2);
        float cy = (float)Math.cos(yaw   / 2);
        float sr = (float)Math.sin(roll  / 2);
        float sp = (float)Math.sin(pitch / 2);
        float sy = (float)Math.sin(yaw   / 2);
        float cpcy = cp * cy;
        float spsy = sp * sy;

        w = cr * cpcy + sr * spsy;
        x = sr * cpcy - cr * spsy;
        y = cr * sp * cy + sr * cp * sy;
        z = cr * cp * sy - sr * sp * cy;
	}

    public Quat.vals(float w, float x, float y, float z)
    {
        this.w = w;
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public float len()
    {
        return (float)Math.sqrt(w*w + x*x + y*y + z*z);
    }

    public Quat mul(Quat other)
    {
        float A = (w + x) * (other.w + other.x);
        float B = (z - y) * (other.y - other.z);
        float C = (w - x) * (other.y + other.z);
        float D = (y + z) * (other.w - other.x);
        float E = (x + z) * (other.x + other.y);
        float F = (x - z) * (other.x - other.y);
        float G = (w + y) * (other.w - other.z);
        float H = (w - y) * (other.w + other.z);

        return new Quat.vals
        (
            B + (-E - F + G + H) / 2,
            A - ( E + F + G + H) / 2,
            C + ( E - F + G - H) / 2,
            D + ( E - F - G + H) / 2
        );
    }

    public Quat mul_scalar(float scalar)
    {
        return new Quat.vals(w * scalar, x * scalar, y * scalar, z * scalar);
    }

    public Quat div_scalar(float scalar)
    {
        return new Quat.vals(w / scalar, x / scalar, y / scalar, z / scalar);
    }

    public float dot(Quat other)
    {
        return w * other.w + x * other.x + y * other.y + z * other.z;
    }

    public Quat inv()
    {
        float l = w * w + x * x + y * y + z * z;
        return conjugate().div_scalar(l);
    }

    public Quat norm()
    {
        float l = len();
        return div_scalar(l);
    }

    public Quat neg()
    {
        return new Quat.vals(-w, -x, -y, -z);
    }

    public Quat conjugate()
    {
        return new Quat.vals(w, -x, -y, -z);
    }

    private const float SLERP_THRESHOLD = 0.9995f;
    public static Quat slerp(Quat from, Quat to, float t)
    {
        // calc cosine
        float cosom = from.dot(to);

        Quat nto = to;
        // adjust signs (if necessary)
        if (cosom < 0.0)
        {
            cosom  = -cosom;
            nto = to.neg();
        }

        // calculate coefficients
        float scale0, scale1;
        if (cosom < SLERP_THRESHOLD)
        {
            // standard case (slerp)
            float omega = (float)Math.acos(cosom);
            float sinom = (float)Math.sin(omega);
            scale0 = (float)Math.sin((1.0 - t) * omega) / sinom;
            scale1 = (float)Math.sin(t * omega) / sinom;
        }
        else
        {
            // "from" and "to" quaternions are very close
            //  ... so we can do a linear interpolation
            scale0 = 1 - t;
            scale1 = t;
        }

        // calculate final values
        return new Quat.vals
        (
            scale0 * from.w + scale1 * nto.w,
            scale0 * from.x + scale1 * nto.x,
            scale0 * from.y + scale1 * nto.y,
            scale0 * from.z + scale1 * nto.z
        );
    }

    public Vec3 vec()
    {
        return Vec3(x, y, z);
    }

    public float w { get; private set; }
    public float x { get; private set; }
    public float y { get; private set; }
    public float z { get; private set; }
}
