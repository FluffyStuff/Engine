using Gee;

namespace Engine
{
    public class Mat4// : Object
    {
        //private static ArrayList<Mat4> unused = new ArrayList<Mat4>();

        private Vec4 v1;
        private Vec4 v2;
        private Vec4 v3;
        private Vec4 v4;
        
        // Caching for Optimization
        private Mat4? inverse_matrix;
        private float data[16];
        private float data_t[16];
        private bool has_data;
        private bool has_data_t;

        private Mat4()
        {
            //add_toggle_ref(toggle_ref);
        }

        /*private void toggle_ref(Object object, bool is_last_ref)
        {
            if (is_last_ref)
            {
                unused.add(this);
                has_data = false;
                has_data_t = false;
                inverse_matrix = null;
            }
        }*/

        private static Mat4 get_mat()
        {
            return new Mat4();
            //(unused.size == 0) ? new Mat4() : unused.remove_at(0);
        }

        public static Mat4 get_new()
        {
            Mat4 mat = get_mat();
            mat.v1 = Vec4(1, 0, 0, 0);
            mat.v2 = Vec4(0, 1, 0, 0);
            mat.v3 = Vec4(0, 0, 1, 0);
            mat.v4 = Vec4(0, 0, 0, 1);
            mat.identity = true;

            return mat;
        }

        public static Mat4 new_with_array(float *a)
        {
            Mat4 mat = get_mat();

            mat.v1 = Vec4(a[ 0], a[ 1], a[ 2], a[ 3]);
            mat.v2 = Vec4(a[ 4], a[ 5], a[ 6], a[ 7]);
            mat.v3 = Vec4(a[ 8], a[ 9], a[10], a[11]);
            mat.v4 = Vec4(a[12], a[13], a[14], a[15]);
            mat.check_is_identity();

            return mat;
        }

        public static Mat4 new_with_vecs(Vec4 v1, Vec4 v2, Vec4 v3, Vec4 v4)
        {
            Mat4 mat = get_mat();

            mat.v1 = v1;
            mat.v2 = v2;
            mat.v3 = v3;
            mat.v4 = v4;
            mat.check_is_identity();

            return mat;
        }

        public static Mat4 new_empty()
        {
            Mat4 mat = get_mat();

            mat.v1 = {};
            mat.v2 = {};
            mat.v3 = {};
            mat.v4 = {};
            mat.identity = false;

            return mat;
        }
        
        public bool equals(Mat4 other)
        {
            return
                this == other ||
                (v1 == other.v1 &&
                v2 == other.v2 &&
                v3 == other.v3 &&
                v4 == other.v4);
        }

        private void check_is_identity()
        {
            identity =
            (
                v1.x == 1 &&
                v1.y == 0 &&
                v1.z == 0 &&
                v1.w == 0 &&
                v2.x == 0 &&
                v2.y == 1 &&
                v2.z == 0 &&
                v2.w == 0 &&
                v3.x == 0 &&
                v3.y == 0 &&
                v3.z == 1 &&
                v3.w == 0 &&
                v4.x == 0 &&
                v4.y == 0 &&
                v4.z == 0 &&
                v4.w == 1
            );
        }

        public Mat4? inverse()
        {
            if (inverse_matrix != null)
                return inverse_matrix;
            
            if (identity)
                return this;

            float mat[16], inv[16];

            Vec4 *v = (Vec4*)mat;
            v[0] = v1;
            v[1] = v2;
            v[2] = v3;
            v[3] = v4;

            return inverse_matrix = (gluInvertMatrix(mat, inv) ? Mat4.new_with_array(inv) : Mat4.new_empty());
        }

        public Mat4 transpose()
        {
            if (identity)
                return this;
            
            Vec4 v1 = col(0);
            Vec4 v2 = col(1);
            Vec4 v3 = col(2);
            Vec4 v4 = col(3);

            return Mat4.new_with_vecs(v1, v2, v3, v4);
        }

        // this*mat
        public Mat4 mul_mat(Mat4 mat)
        {
            if (identity)
                return mat;
            if (mat.identity)
                return this;
            if (inverse_matrix == mat || this == mat.inverse_matrix)
                return get_new();
            
            Vec4 vec1 =
            {
                v1.dot(mat.col(0)),
                v1.dot(mat.col(1)),
                v1.dot(mat.col(2)),
                v1.dot(mat.col(3))
            };

            Vec4 vec2 =
            {
                v2.dot(mat.col(0)),
                v2.dot(mat.col(1)),
                v2.dot(mat.col(2)),
                v2.dot(mat.col(3))
            };

            Vec4 vec3 =
            {
                v3.dot(mat.col(0)),
                v3.dot(mat.col(1)),
                v3.dot(mat.col(2)),
                v3.dot(mat.col(3))
            };

            Vec4 vec4 =
            {
                v4.dot(mat.col(0)),
                v4.dot(mat.col(1)),
                v4.dot(mat.col(2)),
                v4.dot(mat.col(3))
            };

            return Mat4.new_with_vecs(vec1, vec2, vec3, vec4);
        }

        public Vec4 mul_vec(Vec4 vec)
        {
            return
            {
                v1.dot(vec),
                v2.dot(vec),
                v3.dot(vec),
                v4.dot(vec)
            };
        }

        public Vec4 col(int c)
        {
            return
            {
                ((float*)(&v1))[c],
                ((float*)(&v2))[c],
                ((float*)(&v3))[c],
                ((float*)(&v4))[c]
            };
        }

        public Vec4 row(int i)
        {
                if (i == 0) return v1;
            else if (i == 1) return v2;
            else if (i == 2) return v3;
            else             return v4;
        }

        public Vec3 get_position()
        {
            return Vec3(v1.w, v2.w, v3.w);
        }

        public Vec3 get_scale()
        {
            return Vec3
            (
                Vec3(v1.x, v1.y, v1.z).length(),
                Vec3(v2.x, v2.y, v2.z).length(),
                Vec3(v3.x, v3.y, v3.z).length()
            );
        }

        public Quat get_rotation()
        {
            Vec3 s = get_scale();
            float v1x = v1.x / s.x, v2y = v2.y / s.y, v3z = v3.z / s.z;

            float w = Math.sqrtf(Math.fmaxf(0, 1 + v1x + v2y + v3z)) / 2;
            float x = Math.sqrtf(Math.fmaxf(0, 1 + v1x - v2y - v3z)) / 2;
            float y = Math.sqrtf(Math.fmaxf(0, 1 - v1x + v2y - v3z)) / 2;
            float z = Math.sqrtf(Math.fmaxf(0, 1 - v1x - v2y + v3z)) / 2;
            x *= Calculations.sign(x * (v3.y - v2.z));
            y *= Calculations.sign(y * (v1.z - v3.x));
            z *= Calculations.sign(z * (v2.x - v1.y));

            return Quat.vals(w, x, y, z);
        }

        public new float[] get_data()
        {
            if (has_data)
                return data;

            Vec4 *v = (Vec4*)data;
            v[0] = v1;
            v[1] = v2;
            v[2] = v3;
            v[3] = v4;

            has_data = true;

            return data;
        }

        public float[] get_transpose_data()
        {
            if (has_data_t)
                return data_t;

            Vec4 *v = (Vec4*)data_t;
            v[0] = col(0);
            v[1] = col(1);
            v[2] = col(2);
            v[3] = col(3);

            has_data_t = true;

            return data_t;
        }

        public new float get(int i)
        {
            Vec4 v = {};
            int a = i / 4;
                if (a == 0) v = v1;
            else if (a == 1) v = v2;
            else if (a == 2) v = v3;
            else if (a == 3) v = v4;
            return v[i % 4];
        }

        // From Mesa 3D Graphics Library
        private static bool gluInvertMatrix(float *m, float *invOut)
        {
            float inv[16], det;
            int i;

            inv[0] = m[5]  * m[10] * m[15] -
                    m[5]  * m[11] * m[14] -
                    m[9]  * m[6]  * m[15] +
                    m[9]  * m[7]  * m[14] +
                    m[13] * m[6]  * m[11] -
                    m[13] * m[7]  * m[10];

            inv[1] = -m[1]  * m[10] * m[15] +
                    m[1]  * m[11] * m[14] +
                    m[9]  * m[2] * m[15] -
                    m[9]  * m[3] * m[14] -
                    m[13] * m[2] * m[11] +
                    m[13] * m[3] * m[10];

            inv[2] = m[1]  * m[6] * m[15] -
                    m[1]  * m[7] * m[14] -
                    m[5]  * m[2] * m[15] +
                    m[5]  * m[3] * m[14] +
                    m[13] * m[2] * m[7] -
                    m[13] * m[3] * m[6];

            inv[3] = -m[1] * m[6] * m[11] +
                    m[1] * m[7] * m[10] +
                    m[5] * m[2] * m[11] -
                    m[5] * m[3] * m[10] -
                    m[9] * m[2] * m[7] +
                    m[9] * m[3] * m[6];

            inv[4] = -m[4]  * m[10] * m[15] +
                    m[4]  * m[11] * m[14] +
                    m[8]  * m[6]  * m[15] -
                    m[8]  * m[7]  * m[14] -
                    m[12] * m[6]  * m[11] +
                    m[12] * m[7]  * m[10];

            inv[5] = m[0]  * m[10] * m[15] -
                    m[0]  * m[11] * m[14] -
                    m[8]  * m[2] * m[15] +
                    m[8]  * m[3] * m[14] +
                    m[12] * m[2] * m[11] -
                    m[12] * m[3] * m[10];

            inv[6] = -m[0]  * m[6] * m[15] +
                    m[0]  * m[7] * m[14] +
                    m[4]  * m[2] * m[15] -
                    m[4]  * m[3] * m[14] -
                    m[12] * m[2] * m[7] +
                    m[12] * m[3] * m[6];

            inv[7] = m[0] * m[6] * m[11] -
                    m[0] * m[7] * m[10] -
                    m[4] * m[2] * m[11] +
                    m[4] * m[3] * m[10] +
                    m[8] * m[2] * m[7] -
                    m[8] * m[3] * m[6];

            inv[8] = m[4]  * m[9] * m[15] -
                    m[4]  * m[11] * m[13] -
                    m[8]  * m[5] * m[15] +
                    m[8]  * m[7] * m[13] +
                    m[12] * m[5] * m[11] -
                    m[12] * m[7] * m[9];

            inv[9] = -m[0]  * m[9] * m[15] +
                    m[0]  * m[11] * m[13] +
                    m[8]  * m[1] * m[15] -
                    m[8]  * m[3] * m[13] -
                    m[12] * m[1] * m[11] +
                    m[12] * m[3] * m[9];

            inv[10] = m[0]  * m[5] * m[15] -
                    m[0]  * m[7] * m[13] -
                    m[4]  * m[1] * m[15] +
                    m[4]  * m[3] * m[13] +
                    m[12] * m[1] * m[7] -
                    m[12] * m[3] * m[5];

            inv[11] = -m[0] * m[5] * m[11] +
                    m[0] * m[7] * m[9] +
                    m[4] * m[1] * m[11] -
                    m[4] * m[3] * m[9] -
                    m[8] * m[1] * m[7] +
                    m[8] * m[3] * m[5];

            inv[12] = -m[4]  * m[9] * m[14] +
                    m[4]  * m[10] * m[13] +
                    m[8]  * m[5] * m[14] -
                    m[8]  * m[6] * m[13] -
                    m[12] * m[5] * m[10] +
                    m[12] * m[6] * m[9];

            inv[13] = m[0]  * m[9] * m[14] -
                    m[0]  * m[10] * m[13] -
                    m[8]  * m[1] * m[14] +
                    m[8]  * m[2] * m[13] +
                    m[12] * m[1] * m[10] -
                    m[12] * m[2] * m[9];

            inv[14] = -m[0]  * m[5] * m[14] +
                    m[0]  * m[6] * m[13] +
                    m[4]  * m[1] * m[14] -
                    m[4]  * m[2] * m[13] -
                    m[12] * m[1] * m[6] +
                    m[12] * m[2] * m[5];

            inv[15] = m[0] * m[5] * m[10] -
                    m[0] * m[6] * m[9] -
                    m[4] * m[1] * m[10] +
                    m[4] * m[2] * m[9] +
                    m[8] * m[1] * m[6] -
                    m[8] * m[2] * m[5];

            det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12];

            if (det == 0)
                return false;

            det = 1 / det;

            for (i = 0; i < 16; i++)
                invOut[i] = inv[i] * det;

            return true;
        }

        public bool identity { get; private set; }
    }
}