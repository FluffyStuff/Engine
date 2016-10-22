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

    public static Vec3 get_ray(Mat4 projection_matrix, Mat4 view_matrix, Vec2i point, Size2i size)
    {
        float aspect = (float)size.width / size.height;
        float x = -(1 - (float)point.x / size.width  * 2) * aspect;
        float y = -(1 - (float)point.y / size.height * 2) * aspect;

        // TODO: Why is this the unview matrix?
        Mat4 unview_matrix = view_matrix.mul_mat(projection_matrix.inverse());
        Vec4 vec = Vec4(x, y, 0, 1);
        Vec4 ray_dir = unview_matrix.mul_vec(vec);

        return Vec3(ray_dir.x, ray_dir.y, ray_dir.z).normalize();
    }

    /*public static float get_collision_distance(RenderBody3D obj, Vec3 origin, Vec3 ray)
    {
        float x_size = obj.model.size.x / 2 * obj.scale.x;
        float y_size = obj.model.size.y / 2 * obj.scale.y;
        float z_size = obj.model.size.z / 2 * obj.scale.z;

        Vec3 rot = obj.rotation.negate();
        Vec3 xy_dir = rotate(Vec3.empty(), rot, Vec3(0, 0, 1));
        Vec3 xz_dir = rotate(Vec3.empty(), rot, Vec3(0, 1, 0));
        Vec3 yz_dir = rotate(Vec3.empty(), rot, Vec3(1, 0, 0));

        Vec3 xy = xy_dir.mul_scalar(z_size);
        Vec3 xz = xz_dir.mul_scalar(y_size);
        Vec3 yz = yz_dir.mul_scalar(x_size);

        Vec3 xy_pos = obj.position.plus (xy);
        Vec3 xy_neg = obj.position.minus(xy);
        Vec3 xz_pos = obj.position.plus (xz);
        Vec3 xz_neg = obj.position.minus(xz);
        Vec3 yz_pos = obj.position.plus (yz);
        Vec3 yz_neg = obj.position.minus(yz);

        float dist = -1;

        dist = calc_dist(dist, collision_surface_distance(origin, ray, xy_pos, xy_dir, yz_dir, xz_dir, x_size, y_size));
        dist = calc_dist(dist, collision_surface_distance(origin, ray, xy_neg, xy_dir, yz_dir, xz_dir, x_size, y_size));
        dist = calc_dist(dist, collision_surface_distance(origin, ray, xz_pos, xz_dir, yz_dir, xy_dir, x_size, z_size));
        dist = calc_dist(dist, collision_surface_distance(origin, ray, xz_neg, xz_dir, yz_dir, xy_dir, x_size, z_size));
        dist = calc_dist(dist, collision_surface_distance(origin, ray, yz_pos, yz_dir, xy_dir, xz_dir, z_size, y_size));
        dist = calc_dist(dist, collision_surface_distance(origin, ray, yz_neg, yz_dir, xy_dir, xz_dir, z_size, y_size));

        return dist;

        return -1;
    }*/

    public static float get_collision_distance
    (
        Vec3 ray_origin,
        Vec3 ray_direction,
        Vec3 model_obb,
        Mat4 model_matrix
    )
    {
        return get_collision_distance_box(ray_origin, ray_direction, model_obb.mul_scalar(-0.5f), model_obb.mul_scalar(0.5f), model_matrix);
    }

    public static float get_collision_distance_box
    (
        Vec3 ray_origin,        // Ray origin, in world space
        Vec3 ray_direction,     // Ray direction (NOT target position!), in world space. Must be normalize()'d.
        Vec3 aabb_min,          // Minimum X,Y,Z coords of the mesh when not transformed at all.
        Vec3 aabb_max,          // Maximum X,Y,Z coords. Often aabb_min*-1 if your mesh is centered, but it's not always the case.
        Mat4 model_matrix       // Transformation applied to the mesh (which will thus be also applied to its bounding box)
    )
    {
        // Intersection method from Real-Time Rendering and Essential Mathematics for Games
        // Licensed under WTF public license (the best license)

        float tMin = 0.0f;
        float tMax = 100000.0f;

        Vec3 OBBposition_worldspace = Vec3(model_matrix[12], model_matrix[13], model_matrix[14]);
        Vec3 delta = OBBposition_worldspace.minus(ray_origin);

        // Test intersection with the 2 planes perpendicular to the OBB's X axis
        {
            Vec3 xaxis = Vec3(model_matrix[0], model_matrix[1], model_matrix[2]);
            float e = xaxis.dot(delta);
            float f = ray_direction.dot(xaxis);
            float l = xaxis.length();
            l *= l;

            if (Math.fabsf(f) > 0.001f)
            {
                // Standard case
                float t1 = (e + aabb_min.x * l) / f; // Intersection with the "left" plane
                float t2 = (e + aabb_max.x * l) / f; // Intersection with the "right" plane
                // t1 and t2 now contain distances betwen ray origin and ray-plane intersections

                // We want t1 to represent the nearest intersection,
                // so if it's not the case, invert t1 and t2
                if (t1 > t2)
                {
                    // swap t1 and t2
                    float w = t1;
                    t1 = t2;
                    t2 = w;
                }

                // tMax is the nearest "far" intersection (amongst the X,Y and Z planes pairs)
                if (t2 < tMax)
                    tMax = t2;
                // tMin is the farthest "near" intersection (amongst the X,Y and Z planes pairs)
                if (t1 > tMin)
                    tMin = t1;

                // And here's the trick :
                // If "far" is closer than "near", then there is NO intersection.
                // See the images in the tutorials for the visual explanation.
                if (tMax < tMin)
                    return -1;
            }
            else
            {
                // Rare case : the ray is almost parallel to the planes, so they don't have any "intersection"
                if (-e + aabb_min.x > 0.0f || -e + aabb_max.x < 0.0f)
                    return -1;
            }
        }

        // Test intersection with the 2 planes perpendicular to the OBB's Y axis
        // Exactly the same thing as above.
        {
            Vec3 yaxis = Vec3(model_matrix[4], model_matrix[5], model_matrix[6]);
            float e = yaxis.dot(delta);
            float f = ray_direction.dot(yaxis);
            float l = yaxis.length();
            l *= l;

            if (Math.fabsf(f) > 0.001f)
            {
                float t1 = (e + aabb_min.y * l) / f;
                float t2 = (e + aabb_max.y * l) / f;

                if (t1 > t2)
                {
                    float w = t1;
                    t1 = t2;
                    t2 = w;
                }

                if (t2 < tMax)
                    tMax = t2;
                if (t1 > tMin)
                    tMin = t1;

                if (tMax < tMin)
                    return -1;

            }
            else
            {
                if (-e + aabb_min.y > 0.0f || -e + aabb_max.y < 0.0f)
                    return -1;
            }
        }

        // Test intersection with the 2 planes perpendicular to the OBB's Z axis
        // Exactly the same thing as above.
        {
            Vec3 zaxis = Vec3(model_matrix[8], model_matrix[9], model_matrix[10]);
            float e = zaxis.dot(delta);
            float f = ray_direction.dot(zaxis);
            float l = zaxis.length();
            l *= l;

            if (Math.fabsf(f) > 0.001f)
            {
                float t1 = (e + aabb_min.z * l) / f;
                float t2 = (e + aabb_max.z * l) / f;

                if (t1 > t2)
                {
                    float w = t1;
                    t1 = t2;
                    t2 = w;
                }

                if (t2 < tMax)
                    tMax = t2;
                if (t1 > tMin)
                    tMin = t1;

                if (tMax < tMin)
                    return -1;

            }
            else
            {
                if (-e + aabb_min.z > 0.0f || -e + aabb_max.z < 0.0f)
                    return -1;
            }
        }

        return tMin;
    }

    public static Mat4 rotation_matrix_quat(Quat quat)
    {
        float x2 = quat.x + quat.x;
        float y2 = quat.y + quat.y;
        float z2 = quat.z + quat.z;
        float xx = quat.x * x2;
        float xy = quat.x * y2;
        float xz = quat.x * z2;
        float yy = quat.y * y2;
        float yz = quat.y * z2;
        float zz = quat.z * z2;
        float wx = quat.w * x2;
        float wy = quat.w * y2;
        float wz = quat.w * z2;

        float m[16];
        m[ 0] = 1 - (yy + zz);
        m[ 1] = xy - wz;
        m[ 2] = xz + wy;
        m[ 3] = 0;

        m[ 4] = xy + wz;
        m[ 5] = 1 - (xx + zz);
        m[ 6] = yz - wx;
        m[ 7] = 0;

        m[ 8] = xz - wy;
        m[ 9] = yz + wx;
        m[10] = 1 - (xx + yy);
        m[11] = 0;

        m[12] = 0;
        m[13] = 0;
        m[14] = 0;
        m[15] = 1;

        return new Mat4.with_array(m);
    }

    public static Mat4 translation_matrix(Vec3 vec)
    {
        float[] vals =
        {
            1,     0,     0,     0,
            0,     1,     0,     0,
            0,     0,     1,     0,
            vec.x, vec.y, vec.z, 1
        };

        return new Mat4.with_array(vals);
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

        return new Mat4.with_array(vals);
    }

    /*public static Mat4 get_model_matrix(Vec3 position, Vec3 rotation, Vec3 scale)
    {
        float pi = (float)Math.PI;
        Mat4 x = rotation_matrix(Vec3(1, 0, 0), pi * rotation.x);
        Mat4 y = rotation_matrix(Vec3(0, 1, 0), pi * rotation.y);

        Vec3 rot = {0, 1, 0};
        rot = rotate_x(Vec3.empty(), -rotation.x, rot);
        rot = rotate_y(Vec3.empty(), -rotation.y, rot);

        Mat4 z = rotation_matrix(rot, pi * rotation.z);
        Mat4 rotate = x.mul_mat(y).mul_mat(z);

        return scale_matrix(scale).mul_mat(rotate).mul_mat(translation_matrix(position));
    }*/

    public static Mat3 rotation_matrix_3(float angle)
    {
        float s = (float)Math.sin(angle);
        float c = (float)Math.cos(angle);

        //print("S: %f C: %f\n", s, c);

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

    public static Vec3 rotation_mod(Vec3 rotation)
    {
        float x = rotation.x % 2;
        float y = rotation.y % 2;
        float z = rotation.z % 2;

        if (x < 0)
            x += 2;
        if (y < 0)
            y += 2;
        if (z < 0)
            z += 2;

        return Vec3(x, y, z);
    }

    public static Vec3 rotation_ease(Vec3 rotation, Vec3 target)
    {
        rotation = rotation_mod(rotation);
        target = rotation_mod(target);

        float x = rotation.x;
        float y = rotation.y;
        float z = rotation.z;

        float dist_x = rotation.x - target.x;
        float dist_y = rotation.y - target.y;
        float dist_z = rotation.z - target.z;

        if (dist_x > 1)
            x -= 2;
        else if (dist_x < -1)
            x += 2;

        if (dist_y > 1)
            y -= 2;
        else if (dist_y < -1)
            y += 2;

        if (dist_z > 1)
            z -= 2;
        else if (dist_z < -1)
            z += 2;

        return Vec3(x, y, z);
    }
}
