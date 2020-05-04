using Gee;

namespace Engine
{
    public abstract class RenderTarget
    {
        private RenderState? current_state = null;
        private RenderState? buffer_state = null;
        private bool running = false;
        private StepTimer timer;
        private EngineMutex state_mutex;

        private MainView debug_main_view;
        private DebugView debug_view;
        private DebugInfo? debug_info;
        private string debug_version_string;
        private int debug_external_fps = 1;
        private int debug_internal_fps = 1;
        private int debug_new_external_fps = 1;
        private int debug_new_internal_fps = 1;

        private EngineMutex resource_mutex;
        private ArrayList<IModelResourceHandle> to_load_models = new ArrayList<IModelResourceHandle>();
        private ArrayList<ITextureResourceHandle> to_load_textures = new ArrayList<ITextureResourceHandle>();
        private ArrayList<IMaterialResourceHandle> to_load_materials = new ArrayList<IMaterialResourceHandle>();

        private ArrayList<IModelResourceHandle> to_unload_models = new ArrayList<IModelResourceHandle>();
        private ArrayList<ITextureResourceHandle> to_unload_textures = new ArrayList<ITextureResourceHandle>();
        private ArrayList<IMaterialResourceHandle> to_unload_materials = new ArrayList<IMaterialResourceHandle>();
        private ArrayList<ILabelResourceHandle> to_unload_labels = new ArrayList<ILabelResourceHandle>();

        private ArrayList<IModelResourceHandle> handles_models = new ArrayList<IModelResourceHandle>();
        private ArrayList<ITextureResourceHandle> handles_textures = new ArrayList<ITextureResourceHandle>();
        private ArrayList<IMaterialResourceHandle> handles_materials = new ArrayList<IMaterialResourceHandle>();
        private ArrayList<ILabelResourceHandle> handles_labels = new ArrayList<ILabelResourceHandle>();

        private bool saved_v_sync = false;

        protected IWindowTarget window;
        protected ResourceStore store;

        protected RenderTarget(IWindowTarget window, bool multithread_rendering, string debug_version_string, bool debug)
        {
            this.window = window;
            this.multithread_rendering = multithread_rendering;
            this.debug_version_string = debug_version_string;
            this.debug = debug;
            anisotropic_filtering = true;
            v_sync = saved_v_sync;

            if (multithread_rendering)
            {
                state_mutex = new RegularEngineMutex();
                resource_mutex = new RegularEngineMutex();
            }
            else
            {
                state_mutex = new EngineMutex();
                resource_mutex = new EngineMutex();
            }
        }

        ~RenderTarget()
        {
            stop();
        }

        public void set_state(RenderState state, RenderWindow window)
        {
            debug_new_internal_fps++;

            if (debug)
                add_debug_info(state, window);
            
            if (multithread_rendering)
            {
                state_mutex.lock();
                buffer_state = state;
                state_mutex.unlock();
            }
            else
                render_cycle(state);
        }

        public bool init()
        {
            return internal_init();
        }

        public void cycle()
        {
            running = true;
            while (running)
            {
                state_mutex.lock();
                window.pump_events();
                
                if (current_state == buffer_state && current_state == null)
                {
                    state_mutex.unlock();
                    Thread.usleep(1000);
                    continue;
                }

                current_state = buffer_state;
                state_mutex.unlock();

                render_cycle(current_state);

                // TODO: Fix fullscreen v-sync issues
            }
        }

        private bool internal_init()
        {
            timer = new StepTimer();
            return renderer_init();
        }

        public void stop()
        {
			EngineLog.log(EngineLogType.DEBUG, "RenderTarget.stop", "Stopping render target");
            running = false;
        }

        public IModelResourceHandle load_model(InputResourceModel model)
        {
            resource_mutex.lock();
            IModelResourceHandle ret = init_model(model);
            to_load_models.add(ret);
            resource_mutex.unlock();

            return ret;
        }

        public ITextureResourceHandle load_texture(InputResourceTexture texture)
        {
            resource_mutex.lock();
            ITextureResourceHandle ret = init_texture(texture);
            to_load_textures.add(ret);
            resource_mutex.unlock();

            return ret;
        }

        public IMaterialResourceHandle load_material(InputResourceMaterial material)
        {
            resource_mutex.lock();
            IMaterialResourceHandle ret = init_material(material);
            to_load_materials.add(ret);
            resource_mutex.unlock();

            return ret;
        }

        public ILabelResourceHandle load_label()
        {
            resource_mutex.lock();
            ILabelResourceHandle ret = init_label();
            handles_labels.add(ret);
            resource_mutex.unlock();

            return ret;
        }

        public void unload_model(IModelResourceHandle model)
        {
            resource_mutex.lock();
            to_unload_models.add(model);
            resource_mutex.unlock();
        }

        public void unload_texture(ITextureResourceHandle texture)
        {
            resource_mutex.lock();
            to_unload_textures.add(texture);
            resource_mutex.unlock();
        }

        public void unload_material(IMaterialResourceHandle material)
        {
            resource_mutex.lock();
            to_unload_materials.add(material);
            resource_mutex.unlock();
        }

        public void unload_label(ILabelResourceHandle label)
        {
            resource_mutex.lock();
            to_unload_labels.add(label);
            resource_mutex.unlock();
        }

        private void render_cycle(RenderState state)
        {
            window.pump_events();
            debug_new_external_fps++;

            if (timer.elapsed())
                do_secondly();

            unload_resources();
            load_resources();
            check_settings();
            if (debug)
                update_debug(state);
            prepare_state_internal(state);
            render(state);
            window.swap();
        }

        private void unload_resources()
        {
            resource_mutex.lock();
            while (to_unload_models.size != 0)
            {
                IModelResourceHandle model = to_unload_models.remove_at(0);
                handles_models.remove(model);
                resource_mutex.unlock();
                do_unload_model(model);
                resource_mutex.lock();
            }

            while (to_unload_textures.size != 0)
            {
                ITextureResourceHandle texture = to_unload_textures.remove_at(0);
                handles_textures.remove(texture);
                resource_mutex.unlock();
                do_unload_texture(texture);
                resource_mutex.lock();
            }

            while (to_unload_labels.size != 0)
            {
                ILabelResourceHandle label = to_unload_labels.remove_at(0);
                handles_labels.remove(label);
                resource_mutex.unlock();
                do_unload_label(label);
                resource_mutex.lock();
            }
            resource_mutex.unlock();
        }

        private void load_resources()
        {
            resource_mutex.lock();
            while (to_load_models.size != 0)
            {
                IModelResourceHandle model = to_load_models.remove_at(0);
                handles_models.add(model);
                resource_mutex.unlock();
                do_load_model(model);
                resource_mutex.lock();
            }

            while (to_load_textures.size != 0)
            {
                ITextureResourceHandle texture = to_load_textures.remove_at(0);
                handles_textures.add(texture);
                resource_mutex.unlock();
                do_load_texture(texture);
                resource_mutex.lock();
            }

            while (to_load_materials.size != 0)
            {
                IMaterialResourceHandle material = to_load_materials.remove_at(0);
                handles_materials.add(material);
                resource_mutex.unlock();
                do_load_material(material);
                resource_mutex.lock();
            }
            resource_mutex.unlock();
        }

        private void check_settings()
        {
            bool new_v_sync = v_sync;

            if (new_v_sync != saved_v_sync)
            {
                saved_v_sync = new_v_sync;
                change_v_sync(saved_v_sync);
            }
        }

        private void prepare_state_internal(RenderState state)
        {
            foreach (RenderScene scene in state.scenes)
            {
                if (scene is RenderScene2D)
                {
                    RenderScene2D s = scene as RenderScene2D;
                    foreach (RenderObject2D obj in s.objects)
                    {
                        if (obj is RenderLabel2D)
                        {
                            RenderLabel2D label = obj as RenderLabel2D;
                            LabelResourceHandle handle = (LabelResourceHandle)label.reference.handle;

                            bool invalid = false;
                            if (!handle.created ||
                                label.font_type != handle.font_type ||
                                label.font_size != handle.font_size ||
                                label.text != handle.text)
                                invalid = true;

                            if (!invalid)
                                continue;

                            LabelBitmap bitmap = store.generate_label_bitmap(label);
                            do_load_label(handle, bitmap);

                            handle.created = true;
                            handle.font_type = label.font_type;
                            handle.font_size = label.font_size;
                            handle.text = label.text;
                        }
                    }
                }
                else if (scene is RenderScene3D)
                {
                    var s = scene as RenderScene3D;
                    update_labels_3D(s.queue);
                }
            }
        }

        private void update_labels_3D(RenderQueue3D queue)
        {
            foreach (RenderQueue3D sub in queue.sub_queues)
                update_labels_3D(sub);

            foreach (RenderObject3D obj in queue.objects)
            {
                if (obj is RenderLabel3D)
                {
                    RenderLabel3D label = obj as RenderLabel3D;
                    LabelResourceHandle handle = (LabelResourceHandle)label.reference.handle;

                    bool invalid = false;
                    if (!handle.created ||
                        label.font_type != handle.font_type ||
                        label.font_size != handle.font_size ||
                        label.text != handle.text)
                        invalid = true;

                    if (!invalid)
                        continue;

                    LabelBitmap bitmap = store.generate_label_bitmap_3D(label);
                    ITextureResourceHandle tex = do_load_label(handle, bitmap);
                    label.material.textures[0] = new RenderTexture(tex, bitmap.size);

                    handle.created = true;
                    handle.font_type = label.font_type;
                    handle.font_size = label.font_size;
                    handle.text = label.text;
                }
            }
        }

        private int get_queue_object_count(RenderQueue3D queue)
        {
            int total = queue.objects.size;
            foreach (RenderQueue3D sub in queue.sub_queues)
                total += get_queue_object_count(sub);
            return total;
        }

        private void add_debug_info(RenderState state, RenderWindow window)
        {
            if (debug_main_view == null)
            {
                debug_main_view = new MainView(window);
                debug_view = new DebugView();

                debug_main_view.add_child(debug_view);
            }

            debug_main_view.set_window(window);
            debug_main_view.resize();
            state_mutex.lock();
            DebugInfo info = debug_info;
            state_mutex.unlock();
            debug_view.info = info;
            debug_main_view.start_process(state.delta);
            debug_main_view.start_render(state);
        }

        private void update_debug(RenderState state)
        {
            string[] strings =
            {
                "Version: " + debug_version_string,
                "FPS: " + debug_external_fps.to_string(),
                "Frame time: " + (1000.0f / debug_external_fps).to_string() + "ms",
                "CPS: " + debug_internal_fps.to_string(),
                "Cycle time: " + (1000.0f / debug_internal_fps).to_string() + "ms",
                "Model handles: " + handles_models.size.to_string(),
                "Texture handles: " + handles_textures.size.to_string(),
                "Material handles: " + handles_materials.size.to_string(),
                "Label handles: " + handles_labels.size.to_string()
            };

            DebugInfo info = new DebugInfo();
            info.add_strings(strings);
            
            info.add_strings(get_debug_strings());

            foreach (RenderScene scene in state.scenes)
            {
                if (scene is RenderScene2D)
                {
                    var s = scene as RenderScene2D;
                    info.add_string("Scene 2D (" + s.objects.size.to_string() + ")");
                }
                else if (scene is RenderScene3D)
                {
                    var s = scene as RenderScene3D;
                    info.add_string("Scene 3D (" + get_queue_object_count(s.queue).to_string() + ")");
                }
            }

            state_mutex.lock();
            debug_info = info;
            state_mutex.unlock();
        }

        public Mat4 get_projection_matrix(float view_angle, Size2 size)
        {
            view_angle *= (float)Math.PI / 180 / 2;
            
            float z_near  = 1;
            float z_far   = 1000;
            float z_plus  = z_far + z_near;
            float z_minus = z_far - z_near;
            float z_mul   = z_far * z_near;
            
            float aspect = size.width / size.height;
            float xfov = Math.fminf(1,     aspect);
            float yfov = Math.fminf(1, 1 / aspect);
            float vtan = (float)Math.tan(view_angle);
            float vtanx = 1 / (vtan * xfov);
            float vtany = 1 / (vtan * yfov);

            Vec4 v1 = {vtanx,    0,               0,                 0                  };
            Vec4 v2 = {0,        vtany,           0,                 0                  };
            Vec4 v3 = {0,        0,              -z_plus / z_minus, -2 * z_mul / z_minus};
            Vec4 v4 = {0,        0,              -1,                 0                  };

            return Mat4.new_with_vecs(v1, v2, v3, v4);
        }

        public abstract void render(RenderState state);
        protected abstract bool renderer_init();

        protected abstract void do_load_model(IModelResourceHandle handle);
        protected abstract void do_load_texture(ITextureResourceHandle handle);
        protected abstract void do_load_material(IMaterialResourceHandle handle);
        protected abstract ITextureResourceHandle do_load_label(ILabelResourceHandle handle, LabelBitmap bitmap);

        protected abstract void do_unload_model(IModelResourceHandle handle);
        protected abstract void do_unload_texture(ITextureResourceHandle handle);
        protected abstract void do_unload_material(IMaterialResourceHandle handle);
        protected abstract void do_unload_label(ILabelResourceHandle handle);

        protected abstract IModelResourceHandle init_model(InputResourceModel model);
        protected abstract ITextureResourceHandle init_texture(InputResourceTexture texture);
        protected abstract IMaterialResourceHandle init_material(InputResourceMaterial material);
        protected abstract LabelResourceHandle init_label();

        protected abstract void change_v_sync(bool v_sync);
        protected virtual string[] get_debug_strings() { return new string[0]; }
        protected virtual void do_secondly()
        {
            debug_external_fps = debug_new_external_fps;
            debug_internal_fps = debug_new_internal_fps;
            debug_new_external_fps = 1;
            debug_new_internal_fps = 1;
        }

        public ResourceStore resource_store { get { return store; } }
        public bool v_sync { get; set; }
        public bool anisotropic_filtering { get; set; }
        public bool multithread_rendering { get; private set; }
        public bool debug { get; private set; }

        protected abstract class LabelResourceHandle : ILabelResourceHandle, Object
        {
            public bool created { get; set; }
            public string font_type { get; set; }
            public float font_size { get; set; }
            public string text { get; set; }
        }
    }
}