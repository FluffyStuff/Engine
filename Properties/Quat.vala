namespace Engine
{
    public struct Quat
    {
        public Quat()
        {
            w = 1;
        }

        public Quat.from_euler(float yaw, float pitch, float roll)
        {
            init_values(yaw, pitch, roll);
        }

        public Quat.from_euler_vec(Vec3 vec)
        {
            init_values(vec.x, vec.y, vec.z);
        }

        public Quat.from_direction(Vec3 from, Vec3 to)
        {
            Vec3 h = from.plus(to).normalize();

            w = from.dot(h);
            x = from.y * h.z - from.z * h.y;
            y = from.z * h.x - from.x * h.z;
            z = from.x * h.y - from.y * h.x;
        }
        
        private void init_values(float yaw, float pitch, float roll)
        {
            // Multiply with pi to simplify use
            float tau = (float)Math.PI / 2;
            yaw   *= tau;
            pitch *= tau;
            roll  *= tau;
            
            float t0 = (float)Math.cos(roll);
            float t1 = (float)Math.sin(roll);
            float t2 = (float)Math.cos(pitch);
            float t3 = (float)Math.sin(pitch);
            float t4 = (float)Math.cos(yaw);
            float t5 = (float)Math.sin(yaw);

            w = t0 * t2 * t4 + t1 * t3 * t5;
            x = t0 * t3 * t4 - t1 * t2 * t5;
            y = t0 * t2 * t5 + t1 * t3 * t4;
            z = t1 * t2 * t4 - t0 * t3 * t5;
        }

        public Quat.vals(float w, float x, float y, float z)
        {
            this.w = w;
            this.x = x;
            this.y = y;
            this.z = z;
        }

        public bool equals(Quat other)
        {
            return
                w == other.w &&
                x == other.x &&
                y == other.y &&
                z == other.z;
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

            return Quat.vals
            (
                B + (-E - F + G + H) / 2,
                A - ( E + F + G + H) / 2,
                C + ( E - F + G - H) / 2,
                D + ( E - F - G + H) / 2
            );
        }

        public Quat mul_scalar(float scalar)
        {
            return Quat.vals(w * scalar, x * scalar, y * scalar, z * scalar);
        }

        public Quat div_scalar(float scalar)
        {
            return Quat.vals(w / scalar, x / scalar, y / scalar, z / scalar);
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
            return Quat.vals(-w, -x, -y, -z);
        }

        public Quat conjugate()
        {
            return Quat.vals(w, -x, -y, -z);
        }

        public Vec3 to_euler()
        {
            float ysqr = y * y;

            // pitch (x-axis rotation)
            float t0 = 2 * (w * x + y * z);
            float t1 = 1 - 2 * (x * x + ysqr);
            float pitch = Math.atan2f(t0, t1);

            // yaw (y-axis rotation)
            float t2 = 2 * (w * y - z * x);
            t2 = t2 > 1 ? 1 : t2;
            t2 = t2 < -1 ? -1 : t2;
            float yaw = Math.asinf(t2);

            // roll (z-axis rotation)
            float t3 = 2 * (w * z + x * y);
            float t4 = 1 - 2 * (ysqr + z * z);
            float roll = Math.atan2f(t3, t4);

            // Divide by pi to simplify use
            return Vec3(yaw, pitch, roll).div_scalar((float)Math.PI);
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
            return Quat.vals
            (
                scale0 * from.w + scale1 * nto.w,
                scale0 * from.x + scale1 * nto.x,
                scale0 * from.y + scale1 * nto.y,
                scale0 * from.z + scale1 * nto.z
            );
        }

        public float w { get; private set; }
        public float x { get; private set; }
        public float y { get; private set; }
        public float z { get; private set; }
    }
}