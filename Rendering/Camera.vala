public class Camera
{
    public Camera()
    {
        focal_length = 1;
    }

    public Mat4 get_view_transform()
    {
        Quat rot = new Quat.from_euler(pitch, yaw, 0).mul(new Quat.from_euler(0, 0, roll)); // Apply roll last
        Mat4 r = Calculations.rotation_matrix_quat(rot);
        Mat4 p = Calculations.translation_matrix(position.negate());

        return p.mul_mat(r);
    }

    public float roll { get; set; }
    public float pitch { get; set; }
    public float yaw { get; set; }

    public Vec3 position { get; set; }
    public float focal_length { get; set; }
}
