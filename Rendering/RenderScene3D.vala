using Gee;

namespace Engine
{
    public abstract class RenderScene {}

    public class RenderScene3D : RenderScene
    {
        private bool copy_state;

        public RenderScene3D(bool copy_state, Size2i screen_size, float scene_aspect_ratio, Rectangle rect)
        {
            this.copy_state = copy_state;
            this.rect = rect;
            this.screen_size = screen_size;

            queue = new RenderQueue3D();
            lights = new ArrayList<LightSource>();

            Vec3 scene_translation = Vec3
            (
                (rect.x * 2 + rect.width ) / screen_size.width  - 1,
                (rect.y * 2 + rect.height) / screen_size.height - 1,
                0
            );
            Vec3 scene_scale = Vec3
            (
                rect.width / screen_size.width,
                rect.height / screen_size.height,
                1
            );

            scene_matrix = Calculations.translation_matrix(scene_translation).mul_mat(Calculations.scale_matrix(scene_scale));
            set_camera(new Camera());
        }

        public void add_object(Transformable3D object)
        {
            arrange_transformable(copy_state ? object.copy() : object);
        }

        public void add_light_source(LightSource light)
        {
            _lights.add(copy_state ? light.copy() : light);
        }

        public void set_camera(Camera camera)
        {
            view_matrix = camera.get_view_transform().get_full_matrix();
            view_angle = camera.view_angle;
            camera_position = camera.position;
        }

        private void arrange_transformable(Transformable3D obj)
        {
            if (obj is RenderGeometry3D)
            {
                var o = obj as RenderGeometry3D;
                foreach (Transformable3D t in o.geometry)
                    arrange_transformable(t);
            }
            else if (obj is RenderObject3D)
                arrange_object(obj as RenderObject3D);
        }

        private void arrange_object(RenderObject3D obj)
        {
            foreach (RenderQueue3D sub in queue.sub_queues)
            {
                if (sub.reference_resource.equals(obj.material))
                {
                    arrange_object_model(obj, sub);
                    return;
                }
            }

            RenderQueue3D sub_queue = new RenderQueue3D();
            sub_queue.reference_resource = obj.material;
            queue.sub_queues.add(sub_queue);

            arrange_object_model(obj, sub_queue);
        }

        private void arrange_object_model(RenderObject3D obj, RenderQueue3D queue)
        {
            foreach (RenderQueue3D sub in queue.sub_queues)
            {
                if (sub.reference_resource.equals(obj.model))
                {
                    arrange_object_texture(obj, sub, 0);
                    return;
                }
            }

            RenderQueue3D sub_queue = new RenderQueue3D();
            sub_queue.reference_resource = obj.model;
            queue.sub_queues.add(sub_queue);

            arrange_object_texture(obj, sub_queue, 0);
        }

        private void arrange_object_texture(RenderObject3D obj, RenderQueue3D queue, int texture)
        {
            if (obj.material.textures.length <= texture || obj is RenderLabel3D)
            {
                queue.objects.add(obj);
                return;
            }

            RenderTexture tex = obj.material.textures[texture];

            foreach (RenderQueue3D sub in queue.sub_queues)
            {
                if (tex.equals(sub.reference_resource))
                {
                    arrange_object_texture(obj, sub, texture + 1);
                    return;
                }
            }

            RenderQueue3D sub_queue = new RenderQueue3D();
            sub_queue.reference_resource = tex;
            queue.sub_queues.add(sub_queue);

            arrange_object_texture(obj, sub_queue, texture + 1);
        }

        public RenderQueue3D queue { get; private set; }
        public ArrayList<LightSource> lights { get; private set; }
        public Mat4 scene_matrix { get; private set; }
        public Mat4 view_matrix { get; private set; }
        public float view_angle { get; private set; }
        public Vec3 camera_position { get; private set; }
        public Rectangle rect { get; private set; }
        public Size2i screen_size { get; private set; }
        public bool scissor { get; set; }
        public Rectangle scissor_box { get; set; }
    }

    public class RenderQueue3D
    {
        public RenderQueue3D()
        {
            sub_queues = new ArrayList<RenderQueue3D>();
            objects = new ArrayList<RenderObject3D>();
        }

        public IResource? reference_resource { get; set; }
        public ArrayList<RenderQueue3D>? sub_queues { get; private set; }
        public ArrayList<RenderObject3D>? objects { get; private set; }
    }
}