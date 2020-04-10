namespace Engine
{
    public class Camera
    {
        private bool dirty_rotation = true;
        private float _roll;
        private float _pitch;
        private float _yaw;
        private Vec3 _position;
        private Transform view_transform;

        public Camera()
        {
            view_angle = 90;
            view_transform = new CameraTransform();
        }

        public Transform get_view_transform()
        {
            if (dirty_rotation)
            {
                view_transform.rotation = Quat.from_euler(yaw, pitch, 0).mul(Quat.from_euler(0, 0, roll)); // Apply roll last
                dirty_rotation = false;
            }

            return new Transform.with_mat(view_transform.copy_full_parentless().matrix.inverse());
        }

        public float roll
        {
            get { return _roll; }
            set
            {
                if (_roll != value)
                {
                    _roll = value;
                    dirty_rotation = true;
                }
            }
        }

        public float pitch
        {
            get { return _pitch; }
            set
            {
                if (_pitch != value)
                {
                    _pitch = value;
                    dirty_rotation = true;
                }
            }
        }

        public float yaw
        {
            get { return _yaw; }
            set
            {
                if (_yaw != value)
                {
                    _yaw = value;
                    dirty_rotation = true;
                }
            }
        }

        public Vec3 position
        {
            get { return _position; }
            set
            {
                _position = value;
                view_transform.position = value;
            }
        }

        public float view_angle { get; set; }
    }
}