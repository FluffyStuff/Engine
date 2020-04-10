namespace Engine
{
    public class WorldCamera : WorldObject
    {
        public WorldCamera()
        {
            camera = new Camera();
        }
        
        protected override void process(DeltaArgs args)
        {   
            camera.position = transform.position;

            Vec3 rot = transform.rotation.to_euler();
            camera.roll = rot.x;
            camera.pitch = rot.y;
            camera.yaw = rot.z;
        }

        public Camera camera { get; private set; }

        public float view_angle
        {
            get { return camera.view_angle; }
            set { camera.view_angle = value; }
        }
    }

    public class TargetWorldCamera : WorldCamera
    {
        public TargetWorldCamera(WorldObject viewing_target)
        {
            this.viewing_target = viewing_target;
        }
        
        protected override void process(DeltaArgs args)
        {
            camera.position = transform.get_full_matrix().get_position();
            camera.roll = roll;

            Vec3 target_pos = viewing_target.transform.get_full_matrix().get_position();
            Vec3 dir = target_pos.minus(camera.position).normalize();
            camera.pitch = (float)(Math.asin(dir.y) / Math.PI);
            camera.yaw = (float)(Math.atan2f(-dir.x, -dir.z) / Math.PI);
        }

        public float roll { get; set; }
        public WorldObject viewing_target { get; set; }
    }
}