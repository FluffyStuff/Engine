namespace Engine
{
    public class Calculations
    {
        private Calculations(){}

        public static Vec3 rotate(Vec3 origin, Vec3 rotation, Vec3 offset)
        {
            Vec3 point = offset;
            point = rotate_x(origin, rotation.x, point);
            point = rotate_y(origin, rotation.y, point);
            point = rotate_z(origin, rotation.z, point);
            return point;
        }

        public static Vec3 rotate_x(Vec3 origin, float rotation, Vec3 offset)
        {
            if (rotation == 0)
                return offset;

            float c = (float)Math.cos(rotation * Math.PI);
            float s = (float)Math.sin(rotation * Math.PI);

            Vec3 p = offset.minus(origin);

            p = Vec3
            (
                p.x,
                p.y * c - p.z * s,
                p.y * s + p.z * c
            );

            return p.plus(origin);
        }

        public static Vec3 rotate_y(Vec3 origin, float rotation, Vec3 offset)
        {
            if (rotation == 0)
                return offset;

            float c = (float)Math.cos(rotation * Math.PI);
            float s = (float)Math.sin(rotation * Math.PI);

            Vec3 p = offset.minus(origin);

            p = Vec3
            (
                p.z * s + p.x * c,
                p.y,
                p.z * c - p.x * s
            );

            return p.plus(origin);
        }

        public static Vec3 rotate_z(Vec3 origin, float rotation, Vec3 offset)
        {
            if (rotation == 0)
                return offset;

            float c = (float)Math.cos(rotation * Math.PI);
            float s = (float)Math.sin(rotation * Math.PI);

            Vec3 p = offset.minus(origin);

            p = Vec3
            (
                p.x * c - p.y * s,
                p.x * s + p.y * c,
                p.z
            );

            return p.plus(origin);
        }

        public static Ray get_ray(Mat4 projection_matrix, Mat4 view_matrix, Vec2 point, Size2 size)
        {
            float x = point.x / size.width  * 2 - 1;
            float y = point.y / size.height * 2 - 1;

            Mat4 unview_matrix = view_matrix.inverse();
            Mat4 unprojection_matrix = projection_matrix.inverse();
            Vec3 position = unview_matrix.get_position();

            Vec4 vec = unview_matrix.mul_vec(unprojection_matrix.mul_vec(Vec4(x, y, 0, 1)));
            Vec3 ray_dir = vec.vec3().minus(position).normalize();

            return Ray(position, ray_dir);
        }

        public static float get_collision_distance(Ray ray, Vec3 size, Mat4 model_matrix)
        {
            float tMin = 0.0f;
            float tMax = 100000.0f;
            Vec3 delta = model_matrix.get_position().minus(ray.origin);

            for (int i = 0; i < 3; i++)
            {
                Vec3 axis = Vec3(model_matrix[i], model_matrix[i + 4], model_matrix[i + 8]);
                float e = axis.dot(delta);
                float f = ray.direction.dot(axis);

                if (Math.fabsf(f) < 0.001f) return -1;
                
                float l = axis.length();
                l *= l * 0.5f;

                float t1 = (e - size[i] * l) / f;
                float t2 = (e + size[i] * l) / f;

                if (t1 > t2)
                {
                    float w = t1;
                    t1 = t2;
                    t2 = w;
                }

                if (t2 < tMax) tMax = t2;
                if (t1 > tMin) tMin = t1;
                if (tMax < tMin) return -1;
            }

            return tMin;
        }

        public static Mat4 rotation_matrix_quat(Quat quat)
        {
            float x = quat.x;
            float y = quat.y;
            float z = quat.z;
            float w = quat.w;

            float x2 = x + x;
            float y2 = y + y;
            float z2 = z + z;
            float xx = x * x2;
            float xy = x * y2;
            float xz = x * z2;
            float yy = y * y2;
            float yz = y * z2;
            float zz = z * z2;
            float wx = w * x2;
            float wy = w * y2;
            float wz = w * z2;

            float m[16] =
            {
                1 - (yy + zz),       xy - wz,       xz + wy, 0,
                    xy + wz, 1 - (xx + zz),       yz - wx, 0,
                    xz - wy,       yz + wx, 1 - (xx + yy), 0,
                            0,             0,             0, 1
            };

            return Mat4.new_with_array(m);
        }

        public static Mat4 translation_matrix(Vec3 vec)
        {
            float[] vals =
            {
                1,    0,    0, vec.x,
                0,    1,    0, vec.y,
                0,    0,    1, vec.z,
                0,    0,    0,     1
            };

            return Mat4.new_with_array(vals);
        }

        public static Mat4 scale_matrix(Vec3 vec)
        {
            float[] vals =
            {
                vec.x, 0, 0, 0,
                0, vec.y, 0, 0,
                0, 0, vec.z, 0,
                0, 0,     0, 1
            };

            return Mat4.new_with_array(vals);
        }

        public static Mat4 get_model_matrix(Vec3 translation, Vec3 scale, Quat rotation)
        {
            Mat4 t = translation_matrix(translation);
            Mat4 s = scale_matrix(scale);
            Mat4 r = rotation_matrix_quat(rotation);

            return t.mul_mat(r).mul_mat(s);
        }

        public static Mat3 rotation_matrix_3(float angle)
        {
            float s = (float)Math.sin(angle);
            float c = (float)Math.cos(angle);

            float[] vals =
            {
                c, s, 0,
                -s, c, 0,
                0, 0, 1
            };

            return new Mat3.with_array(vals);
        }

        public static Mat3 translation_matrix_3(Vec2 vec)
        {
            float[] vals =
            {
                1,     0,     0,
                0,     1,     0,
                vec.x, vec.y, 1
            };

            return new Mat3.with_array(vals);
        }

        public static Mat3 scale_matrix_3(Size2 vec)
        {
            float[] vals =
            {
                vec.width,  0, 0,
                0, vec.height, 0,
                0,          0, 1
            };

            return new Mat3.with_array(vals);
        }

        public static Mat3 get_model_matrix_3(Vec2 position, float rotation, Size2 scale, float aspect)
        {
            Mat3 s = scale_matrix_3(scale);
            Mat3 r = rotation_matrix_3(rotation * (float)Math.PI);
            Mat3 a = scale_matrix_3(Size2(1, aspect)); // Fix aspect after rotation
            Mat3 p = translation_matrix_3(position);

            return s.mul_mat(r).mul_mat(a).mul_mat(p);
        }

        public static int sign(float n)
        {
            if (n > 0) return 1;
            if (n < 0) return -1;
            return 0;
        }
    }
}