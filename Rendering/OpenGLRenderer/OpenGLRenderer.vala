using GL;
using Gee;

namespace Engine
{
    public class OpenGLRenderer : RenderTarget
    {
        private const int MAX_LIGHTS = 3;

        private const int POSITION_ATTRIBUTE = 0;
        private const int TEXTURE_ATTRIBUTE = 1;
        private const int NORMAL_ATTRIBUTE = 2;

        private float anisotropic = 0;

        private OpenGLShaderProgram2D program_2D;

        private Size2i view_size;

        private int debug_2D_draws;
        private int debug_3D_draws;
        private int debug_3D_texture_switches;
        private int debug_3D_model_switches;
        private int debug_scene_switches;

        public OpenGLRenderer(IWindowTarget window, bool multithread_rendering, bool debug)
        {
            base(window, multithread_rendering, debug);
            store = new ResourceStore(this);
        }

        protected override bool renderer_init()
        {
            if (glEnable == null)
            {
                EngineLog.log(EngineLogType.RENDERING, "OpenGLRenderer", "Invalid GL context");
                return false;
            }

            if (glCreateShader == null)
            {
                EngineLog.log(EngineLogType.RENDERING, "OpenGLRenderer", "Invalid GL 2.1 context");
                return false;
            }

            glEnable(GL_CULL_FACE);
            glEnable(GL_DEPTH_TEST);
            glDepthFunc(GL_LEQUAL);

            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_FRAMEBUFFER_SRGB);
            glEnable(GL_MULTISAMPLE);

            change_v_sync(v_sync);

            program_2D = new OpenGLShaderProgram2D();
            if (!program_2D.init())
                return false;

            float aniso[1];
            glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, aniso);
            anisotropic = aniso[0];

            return true;
        }

        public override void render(RenderState state)
        {
            debug_2D_draws = 0;
            debug_3D_draws = 0;
            debug_3D_texture_switches = 0;
            debug_3D_model_switches = 0;
            debug_scene_switches = 0;

            setup_projection(state.screen_size);
            glClearColor(state.back_color.r, state.back_color.g, state.back_color.b, state.back_color.a);
            glClear(GL_COLOR_BUFFER_BIT);

            OpenGLShaderProgram3D? last_program = null;

            foreach (RenderScene scene in state.scenes)
            {
                glClear(GL_DEPTH_BUFFER_BIT);

                if (scene is RenderScene2D)
                {
                    render_scene_2D(scene as RenderScene2D);
                    last_program = null;
                }
                else if (scene is RenderScene3D)
                    render_scene_3D(scene as RenderScene3D, ref last_program);
                
                debug_scene_switches++;
            }

            if (debug)
                get_debug_messages();
        }

        private void render_scene_3D(RenderScene3D scene, ref OpenGLShaderProgram3D? last_program)
        {
            Mat4 projection_matrix = get_projection_matrix(scene.view_angle, Size2(scene.rect.width, scene.rect.height));
            Mat4 view_matrix = scene.view_matrix;
            Mat4 scene_matrix = scene.scene_matrix;

            glEnable(GL_SCISSOR_TEST);

            float x = scene.rect.x;
            float y = scene.rect.y;
            float w = scene.rect.width;
            float h = scene.rect.height;

            if (scene.scissor)
            {
                if (x + w > scene.scissor_box.x + scene.scissor_box.width)
                    w = scene.scissor_box.width;
                if (y + h > scene.scissor_box.y + scene.scissor_box.height)
                    h = scene.scissor_box.height;
                
                x = Math.fmaxf(x, scene.scissor_box.x);
                y = Math.fmaxf(y, scene.scissor_box.y);
            }

            glScissor((int)Math.round(x),
                        (int)Math.round(y),
                        (int)Math.round(w),
                        (int)Math.round(h));

            render_queue_3D(scene.queue, ref last_program, scene_matrix.mul_mat(projection_matrix), view_matrix, scene.camera_position, scene.lights);

            glDisable(GL_SCISSOR_TEST);
        }

        private void render_queue_3D(RenderQueue3D queue, ref OpenGLShaderProgram3D? last_program,
            Mat4 proj, Mat4 view, Vec3 cam_pos, ArrayList<LightSource>? lights)
        {
            foreach (RenderQueue3D sub in queue.sub_queues)
                render_queue_3D(sub, ref last_program, proj, view, cam_pos, lights);

            foreach (RenderObject3D obj in queue.objects)
            {
                //if (obj is RenderLabel3D)
                //    render_label_3D(obj as RenderLabel3D, ref last_program, proj, view, cam_pos, lights);
                //else
                    render_object_3D(obj as RenderObject3D, ref last_program, proj, view, cam_pos, lights);
            }
        }

        private void render_object_3D(RenderObject3D obj, ref OpenGLShaderProgram3D? last_program,
            Mat4 proj, Mat4 view, Vec3 cam_pos, ArrayList<LightSource>? lights)
        {
            if (obj.material == null)
                return;
            
            var res = obj.material.handle as OpenGLMaterialResourceHandle;
            OpenGLShaderProgram3D program = res.program;
            if (program != last_program)
            {
                program.apply_scene(proj, view, cam_pos, lights);
                last_program = program;
            }

            /*if (obj.texture != null)
            {
                OpenGLTextureResourceHandle texture_handle = obj.texture.handle as OpenGLTextureResourceHandle;
                use_texture = true;

                if (last_texture_handle != texture_handle.handle)
                {
                    last_texture_handle = (int)texture_handle.handle;
                    glBindTexture(GL_TEXTURE_2D, texture_handle.handle);
                    debug_3D_texture_switches++;
                }
            }*/

            OpenGLModelResourceHandle model_handle = obj.model.handle as OpenGLModelResourceHandle;

            Mat4 model_matrix = obj.get_full_transform().get_full_matrix();
            program.render_object(model_handle, model_matrix, obj.material);
            debug_3D_draws++;
        }

        /*private void render_label_3D(RenderLabel3D label, ref OpenGLShaderProgram3D? last_program,
            Mat4 proj, Mat4 view, Vec3 cam_pos, ArrayList<LightSource>? lights)
        {
            OpenGLModelResourceHandle model_handle = label.model.handle as OpenGLModelResourceHandle;
            
            OpenGLShaderProgram3D program = (label.material.handle as OpenGLMaterialResourceHandle).program;
            if (program != last_program)
                program.apply_scene(proj, view, cam_pos, lights);

            /*if (last_texture_handle != label_handle.handle)
            {
                last_texture_handle = (int)label_handle.handle;
                glBindTexture(GL_TEXTURE_2D, label_handle.handle);
                debug_3D_texture_switches++;
            }

            if (last_array_handle != model_handle.array_handle)
            {
                last_array_handle = (int)model_handle.array_handle;
                OpenGLFunctions.glBindVertexArray(model_handle.array_handle);
                debug_3D_model_switches++;
            }* /

            Mat4 model_matrix = label.get_label_transform().get_full_matrix();
            program.render_object(model_handle, model_matrix, label.material);
            debug_3D_draws++;
        }*/

        private void render_scene_2D(RenderScene2D scene)
        {
            OpenGLShaderProgram2D program = program_2D;

            program.apply_scene();
            bool scissors = false;
            float aspect = (float)scene.screen_size.width / scene.screen_size.height;

            foreach (RenderObject2D obj in scene.objects)
            {
                if (obj.scissor != scissors)
                {
                    if (obj.scissor)
                    {
                        glEnable(GL_SCISSOR_TEST);
                        glScissor((int)Math.round(obj.scissor_box.x),
                                (int)Math.round(obj.scissor_box.y),
                                (int)Math.round(obj.scissor_box.width),
                                (int)Math.round(obj.scissor_box.height));
                    }
                    else
                        glDisable(GL_SCISSOR_TEST);

                    scissors = obj.scissor;
                }

                if (obj is RenderImage2D)
                    render_image_2D(obj as RenderImage2D, program, aspect);
                else if (obj is RenderLabel2D)
                    render_label_2D(obj as RenderLabel2D, program, scene.screen_size, aspect);
                else if (obj is RenderRectangle2D)
                    render_rectangle_2D(obj as RenderRectangle2D, program, aspect);
                debug_2D_draws++;
            }

            if (scissors)
                glDisable(GL_SCISSOR_TEST);
        }

        private void render_image_2D(RenderImage2D obj, OpenGLShaderProgram2D program, float aspect)
        {
            OpenGLTextureResourceHandle texture_handle = obj.texture.handle as OpenGLTextureResourceHandle;
            glBindTexture(GL_TEXTURE_2D, (GLuint)texture_handle.handle);

            Mat3 model_transform = Calculations.get_model_matrix_3(obj.position, obj.rotation, obj.scale, aspect);

            program.render_object(model_transform, obj.diffuse_color, true);
        }

        private void render_label_2D(RenderLabel2D label, OpenGLShaderProgram2D program, Size2i screen_size, float aspect)
        {
            OpenGLLabelResourceHandle label_handle = label.reference.handle as OpenGLLabelResourceHandle;
            glBindTexture(GL_TEXTURE_2D, label_handle.handle);

            Vec2 p = label.position;

            // Round position to nearest pixel
            p = Vec2(Math.rintf(p.x * (float)screen_size.width  / 2) / (float)screen_size.width  * 2,
                    Math.rintf(p.y * (float)screen_size.height / 2) / (float)screen_size.height * 2);

            // If the label and screen size don't have the same mod 2, we are misaligned by exactly half a pixel
            if (label.info.size.width  % 2 != screen_size.width  % 2)
                p.x += 1.0f / screen_size.width;
            if (label.info.size.height % 2 != screen_size.height % 2)
                p.y += 1.0f / screen_size.height;

            Mat3 model_transform = Calculations.get_model_matrix_3(p, label.rotation, label.scale, aspect);

            program.render_object(model_transform, label.diffuse_color, true);
        }

        private void render_rectangle_2D(RenderRectangle2D rectangle, OpenGLShaderProgram2D program, float aspect)
        {
            Mat3 model_transform = Calculations.get_model_matrix_3(rectangle.position, rectangle.rotation, rectangle.scale, aspect);
            program.render_object(model_transform, rectangle.diffuse_color, false);
        }

        ///////////////////////////

        protected override IModelResourceHandle init_model(InputResourceModel model)
        {
            return new OpenGLModelResourceHandle(model);
        }

        protected override ITextureResourceHandle init_texture(InputResourceTexture texture)
        {
            return new OpenGLTextureResourceHandle(texture);
        }

        protected override IMaterialResourceHandle init_material(InputResourceMaterial material)
        {
            OpenGLShaderProgram3D? program = new OpenGLShaderProgram3D(material.spec, MAX_LIGHTS, POSITION_ATTRIBUTE, TEXTURE_ATTRIBUTE, NORMAL_ATTRIBUTE);
            OpenGLMaterialResourceHandle handle = new OpenGLMaterialResourceHandle(program);

            material.uniforms = new ShaderUniform[program.uniforms.length];
            for (int i = 0; i < material.uniforms.length; i++)
                material.uniforms[i] = new ShaderUniform(program.uniforms[i].name);
            
            return handle;
        }

        protected override RenderTarget.LabelResourceHandle init_label()
        {
            return new OpenGLLabelResourceHandle();
        }

        protected override void do_load_model(IModelResourceHandle model)
        {
            OpenGLModelResourceHandle handle = model as OpenGLModelResourceHandle;
            InputResourceModel resource = handle.model;

            int len = 10 * (int)sizeof(float);
            uint triangles[1];

            glGenBuffers(1, triangles);
            glBindBuffer(GL_ARRAY_BUFFER, triangles[0]);
            glBufferData(GL_ARRAY_BUFFER, len * resource.points.length, (GLvoid[])resource.points, GL_STATIC_DRAW);

            uint vao[1];
            OpenGLFunctions.glGenVertexArrays(1, vao);
            OpenGLFunctions.glBindVertexArray(vao[0]);

            glEnableVertexAttribArray(POSITION_ATTRIBUTE);
            glVertexAttribPointer(POSITION_ATTRIBUTE, 4, GL_FLOAT, false, len, 0);
            glEnableVertexAttribArray(TEXTURE_ATTRIBUTE);
            glVertexAttribPointer(TEXTURE_ATTRIBUTE, 3, GL_FLOAT, false, len, 4 * (int)sizeof(float));
            glEnableVertexAttribArray(NORMAL_ATTRIBUTE);
            glVertexAttribPointer(NORMAL_ATTRIBUTE, 3, GL_FLOAT, false, len, 7 * (int)sizeof(float));

            handle.handle = triangles[0];
            handle.triangle_count = resource.points.length;
            handle.array_handle = vao[0];
            handle.model = null;
        }

        protected override void do_load_texture(ITextureResourceHandle texture)
        {
            OpenGLTextureResourceHandle handle = texture as OpenGLTextureResourceHandle;
            InputResourceTexture resource = handle.texture;

            int width = resource.size.width;
            int height = resource.size.height;

            uint tex[1];
            glGenTextures(1, tex);

            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, tex[0]);

            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

            if (anisotropic_filtering && anisotropic > 0)
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, anisotropic);
            
            glTexImage2D(GL_TEXTURE_2D, 0, GL_SRGB_ALPHA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid[])resource.data);
            glEnable(GL_TEXTURE_2D); // Avoid ATI driver bug
            glGenerateMipmap(GL_TEXTURE_2D);

            handle.handle = tex[0];
            handle.texture = null;
        }

        protected override void do_load_material(IMaterialResourceHandle material)
        {
            OpenGLMaterialResourceHandle handle = material as OpenGLMaterialResourceHandle;
            //InputResourceMaterial resource = handle.material;

            //OpenGLShaderProgram3D? program = new OpenGLShaderProgram3D(resource.spec, MAX_LIGHTS, POSITION_ATTRIBUTE, TEXTURE_ATTRIBUTE, NORMAL_ATTRIBUTE);
            if (!handle.program.init())
            {
                // TODO: Handle error
            }
        }

        protected override ITextureResourceHandle do_load_label(ILabelResourceHandle label_handle, LabelBitmap label)
        {
            OpenGLLabelResourceHandle handle = label_handle as OpenGLLabelResourceHandle;

            uint tex[1] = { handle.handle };
            if (handle.created)
                glDeleteTextures(1, tex);

            int width = label.size.width;
            int height = label.size.height;

            glGenTextures(1, tex);

            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, tex[0]);
            
            //glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

            if (anisotropic_filtering && anisotropic > 0)
                glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, anisotropic);

            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid[])label.data);
            glEnable(GL_TEXTURE_2D); // Avoid ATI driver bug
            //glGenerateMipmap(GL_TEXTURE_2D);

            handle.handle = tex[0];

            return new OpenGLTextureResourceHandle(null) { handle = handle.handle };
        }

        protected override void do_unload_model(IModelResourceHandle model)
        {
            OpenGLModelResourceHandle handle = model as OpenGLModelResourceHandle;

            uint[] triangles = { handle.handle };
            uint[] vao = { handle.array_handle };

            glDeleteBuffers(1, triangles);
            OpenGLFunctions.glDeleteVertexArrays(1, vao);
        }

        protected override void do_unload_texture(ITextureResourceHandle label_handle)
        {
            OpenGLTextureResourceHandle handle = label_handle as OpenGLTextureResourceHandle;

            uint[] tex = { handle.handle };
            glDeleteTextures(1, tex);
        }

        protected override void do_unload_material(IMaterialResourceHandle material_handle)
        {
            OpenGLMaterialResourceHandle handle = material_handle as OpenGLMaterialResourceHandle;
            handle.program.delete();
        }

        protected override void do_unload_label(ILabelResourceHandle label_handle)
        {
            OpenGLLabelResourceHandle handle = label_handle as OpenGLLabelResourceHandle;

            if (handle.created)
            {
                uint[] tex = { handle.handle };
                glDeleteTextures(1, tex);
            }
        }

        protected override void change_v_sync(bool v_sync)
        {
            SDL.GL.set_swapinterval(v_sync ? 1 : 0);
        }

        private void setup_projection(Size2i size)
        {
            if (view_size.width == size.width && view_size.height == size.height)
                return;
            view_size = size;

            glViewport(0, 0, view_size.width, view_size.height);
        }

        private void get_debug_messages()
        {
            uint8 buffer[8192];

            uint sources[1];
            uint types[1];
            uint ids[1];
            uint severities[1];
            int lengths[1];

            while (true)
            {
                uint ret = glGetDebugMessageLog
                (
                    1,
                    buffer.length,
                    sources,
                    types,
                    ids,
                    severities,
                    lengths,
                    buffer
                );

                if (ret == 0)
                    break;

                string msg = (string)buffer;
                DebugMessage message = new DebugMessage(sources[0], types[0], ids[0], severities[0], msg);

                log_debug_message(message);
            }
        }

        private void log_debug_message(DebugMessage message)
        {
            if (message.source == 33350 && message.message_type == 33361 && message.id == 131185)
                return;

            string msg = "Source(%u) Type(%u) ID(%u) - %s".printf(message.source, message.message_type, message.id, message.message);
            EngineLog.log(EngineLogType.DEBUG, "OpenGLRenderer", msg);
        }

        protected override string[] get_debug_strings()
        {
            return
            {
                "3D draws: " + debug_3D_draws.to_string(),
                "2D draws: " + debug_2D_draws.to_string(),
                "3D texture switches: " + debug_3D_texture_switches.to_string(),
                "3D model switches: " + debug_3D_model_switches.to_string(),
                "Scene switches: " + debug_scene_switches.to_string()
            };
        }

        // Private classes

        class DebugMessage
        {
            public DebugMessage(uint source, uint message_type, uint id, uint severity, string message)
            {
                this.source = source;
                this.message_type = message_type;
                this.id = id;
                this.severity = severity;
                this.message = message;
            }

            public uint source { get; private set; }
            public uint message_type { get; private set; }
            public uint id { get; private set; }
            public uint severity { get; private set; }
            public string message { get; private set; }
        }

        public class OpenGLModelResourceHandle : IModelResourceHandle, Object
        {
            public OpenGLModelResourceHandle(InputResourceModel model)
            {
                this.model = model;
            }

            public InputResourceModel? model { get; set; }
            public uint handle { get; set; }
            public int triangle_count { get; set; }
            public uint array_handle { get; set; }
        }

        public class OpenGLTextureResourceHandle : ITextureResourceHandle, Object
        {
            public OpenGLTextureResourceHandle(InputResourceTexture? texture)
            {
                this.texture = texture;
            }

            public InputResourceTexture? texture { get; set; }
            public uint handle { get; set; }
        }

        public class OpenGLMaterialResourceHandle : IMaterialResourceHandle, Object
        {
            public OpenGLMaterialResourceHandle(OpenGLShaderProgram3D program)
            {
                this.program = program;
            }

            public OpenGLShaderProgram3D? program { get; set; }
        }

        public class OpenGLLabelResourceHandle : RenderTarget.LabelResourceHandle
        {
            public OpenGLLabelResourceHandle()
            {
                created = false;
            }

            public uint handle { get; set; }
        }
    }
}