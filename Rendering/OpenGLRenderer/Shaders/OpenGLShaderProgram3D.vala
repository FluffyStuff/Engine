using GL;
using Gee;

namespace Engine
{
    public enum ApplyUniformType
    {
        INT,
        FLOAT,
        VEC3,
        VEC4,
        COLOR,
        MATRIX
    }

    public class OpenGLShaderProgram3D
    {
        private uint program;
        private OpenGLShader vertex_shader;
        private OpenGLShader fragment_shader;

        private OpenGLLightSource[] lights;

        private int current_model;
        private int[] textures;
        private int active_texture;

        private OpenGLShaderBuilder builder;

        private int vert_position_attribute;
        private int vert_texture_attribute;
        private int vert_normal_attribute;

        public OpenGLShaderProgram3D(MaterialSpecification spec, int max_lights,
            int vert_position_attribute, int vert_texture_attribute, int vert_normal_attribute)
        {
            this.spec = spec;
            this.max_lights = max_lights;
            this.vert_position_attribute = vert_position_attribute;
            this.vert_texture_attribute = vert_texture_attribute;
            this.vert_normal_attribute = vert_normal_attribute;

            builder = new OpenGLStandardShaderBuilder(spec, max_lights);
            string vert = builder.create_vertex_shader();
            string frag = builder.create_fragment_shader();

            // For debugging
            //FileLoader.save("vert.shader", FileLoader.split_string(vert));
            //FileLoader.save("frag.shader", FileLoader.split_string(frag));

            vertex_shader = new OpenGLShader(FileLoader.split_string(vert, true), OpenGLShader.ShaderType.VERTEX_SHADER);
            fragment_shader = new OpenGLShader(FileLoader.split_string(frag, true), OpenGLShader.ShaderType.FRAGMENT_SHADER);

            uniforms = new ProgramShaderUniform[builder.uniforms.size];
            for (int i = 0; i < uniforms.length; i++)
            {
                string name = builder.uniforms[i].name;
                uniforms[i] = new ProgramShaderUniform(name);
            }
        }

        public bool init()
        {
            if (!vertex_shader.init())
                return false;
            if (!fragment_shader.init())
                return false;

            program = glCreateProgram();

            glAttachShader(program, vertex_shader.handle);
            glAttachShader(program, fragment_shader.handle);

            glBindAttribLocation(program, vert_position_attribute, "position");
            glBindAttribLocation(program, vert_texture_attribute, "texture_coord");
            glBindAttribLocation(program, vert_normal_attribute, "normal");

            glLinkProgram(program);

            for (int i = 0; i < uniforms.length; i++)
            {
                string name = builder.uniforms[i].name;
                int handle = glGetUniformLocation(program, name);
                uniforms[i].handle = handle;
            }

            if (spec.lighting_calculation != LightingCalculationType.NONE)
            {
                lights = new OpenGLLightSource[max_lights];

                for (int i = 0; i < lights.length; i++)
                {
                    lights[i] = new OpenGLLightSource(i);
                    lights[i].init(program);
                }
            }

            textures = new int[spec.textures];

            uint err = glGetError();
            if (err != 0 && err != 0x500)
            {
                EngineLog.log(EngineLogType.RENDERING, "OpenGLShaderProgram3D", "GL shader program linkage failure (" + err.to_string() + ")");
                return false;
            }

            return true;
        }

        public void delete()
        {
            vertex_shader.delete();
            fragment_shader.delete();
            glDeleteProgram(program);
        }

        private void use_program()
        {
            glUseProgram(program);
        }

        private void apply_uniform(string name, void *data, ApplyUniformType type)
        {
            //if (data == null)
            //    return;

            foreach (ProgramShaderUniform uniform in uniforms)
            {
                if (uniform.name == name)
                {
                    switch (type)
                    {
                    case ApplyUniformType.MATRIX:
                        var m = data as Mat4;
                        glUniformMatrix4fv(uniform.handle, 1, true, m.get_data());
                        break;
                    case ApplyUniformType.COLOR:
                        Color col = *(Color*)data;
                        glUniform4f(uniform.handle, col.r, col.g, col.b, col.a);
                        break;
                    case ApplyUniformType.VEC4:
                        Vec4 vec = *(Vec4*)data;
                        glUniform4f(uniform.handle, vec.x, vec.y, vec.z, vec.w);
                        break;
                    case ApplyUniformType.VEC3:
                        Vec3 vec = *(Vec3*)data;
                        glUniform3f(uniform.handle, vec.x, vec.y, vec.z);
                        break;
                    case ApplyUniformType.FLOAT:
                        float f = *(float*)data;
                        glUniform1f(uniform.handle, f);
                        break;
                    case ApplyUniformType.INT:
                        int i = *(int*)data;
                        glUniform1i(uniform.handle, i);
                        break;
                    }


                    /*if (uniform.data != null && uniform.data.equals(data))
                        break;
                    
                    uniform.data = data;
                    
                    if (data is MatrixUniformData)
                        glUniformMatrix4fv(uniform.handle, 1, true, (data as MatrixUniformData).matrix.get_data());
                    else if (data is Vec3UniformData)
                    {
                        Vec3 vec = (data as Vec3UniformData).value;
                        glUniform3f(uniform.handle, vec.x, vec.y, vec.z);
                    }
                    else if (data is ColorUniformData)
                    {
                        Color color = (data as ColorUniformData).value;
                        glUniform4f(uniform.handle, color.r, color.g, color.b, color.a);
                    }
                    else if (data is FloatUniformData)
                        glUniform1f(uniform.handle, (data as FloatUniformData).value);
                    else if (data is IntUniformData)
                        glUniform1i(uniform.handle, (data as IntUniformData).value);
                    else if (data is BoolUniformData)
                        glUniform1i(uniform.handle, (int)(data as BoolUniformData).value);
                    break;*/
                }
            }
        }
        
        public void apply_scene(Mat4 proj_mat, Mat4 view_mat, Vec3 camera_position, ArrayList<LightSource>? lights)
        {
            use_program();

            active_texture = -1;
            current_model = -1;
            for (int i = 0; i < textures.length; i++)
                textures[i] = -1;
            foreach (ProgramShaderUniform uniform in uniforms)
                uniform.data = null;

            apply_uniform("projection_transform", proj_mat.mul_mat(view_mat), ApplyUniformType.MATRIX);
            apply_uniform("camera_position", &camera_position, ApplyUniformType.VEC3);
            //apply_uniform("view_transform", new MatrixUniformData(view_mat));
            //apply_uniform("un_projection_transform", new MatrixUniformData(proj_mat.inverse()));
            //apply_uniform("un_view_transform", new MatrixUniformData(view_mat.inverse()));

            if (spec.lighting_calculation != LightingCalculationType.NONE)
            {
                int s = lights.size;
                float f = lights.size;
                apply_uniform("light_count", &s, ApplyUniformType.INT);
                apply_uniform("light_count_float", &f, ApplyUniformType.FLOAT);

                for (int i = 0; i < s && i < this.lights.length; i++)
                    this.lights[i].apply(lights[i].transform, lights[i].color, lights[i].intensity);
            }
        }

        public void render_object(OpenGLRenderer.OpenGLModelResourceHandle model, Mat4 model_mat, RenderMaterial material)
        {
            /*foreach (var uniform in material.get_uniforms())
                apply_uniform(uniform.name, uniform.data);*/

            apply_uniform("model_transform", model_mat, ApplyUniformType.MATRIX);

            if (material.spec.ambient_color == UniformType.DYNAMIC)
                apply_uniform("ambient_color", &material.ambient_color, ApplyUniformType.COLOR);
            if (material.spec.diffuse_color == UniformType.DYNAMIC)
                apply_uniform("diffuse_color", &material.diffuse_color, ApplyUniformType.COLOR);
            if (material.spec.specular_color == UniformType.DYNAMIC)
                apply_uniform("specular_color", &material.specular_color, ApplyUniformType.COLOR);
            if (material.spec.target_color == UniformType.DYNAMIC)
            {
                apply_uniform("target_color", &material.target_color, ApplyUniformType.COLOR);
                apply_uniform("target_color_strength", &material.target_color_strength, ApplyUniformType.FLOAT);
            }
            if (material.spec.alpha == UniformType.DYNAMIC)
                apply_uniform("alpha", &material.alpha, ApplyUniformType.FLOAT);

            for (int i = 0; i < textures.length; i++)
            {
                OpenGLRenderer.OpenGLTextureResourceHandle texture_handle = material.textures[i].handle as OpenGLRenderer.OpenGLTextureResourceHandle;

                if (textures[i] != texture_handle.handle)
                {
                    textures[i] = (int)texture_handle.handle;
                    if (active_texture != i)
                        glActiveTexture(GL_TEXTURE0 + i);
                    glBindTexture(GL_TEXTURE_2D, texture_handle.handle);
                }
            }

            if (current_model != model.array_handle)
            {
                current_model = (int)model.array_handle;
                OpenGLFunctions.glBindVertexArray(model.array_handle);
                //debug_3D_model_switches++;
            }

            glDrawArrays(GL_TRIANGLES, 0, model.triangle_count);
        }

        public MaterialSpecification spec { get; private set; }
        public int max_lights { get; private set; }
        public ProgramShaderUniform[] uniforms { get; private set; }

        public class ProgramShaderUniform
        {
            public ProgramShaderUniform(string name)
            {
                this.name = name;
            }

            public string name { get; private set; }
            //public UniformType uniform_type { get; private set; }
            public int handle { get; set; }
            public UniformData? data { get; set; }
        }
    }

    private class OpenGLLightSource
    {
        private int position_attrib;
        private int color_attrib;
        private int intensity_attrib;

        public OpenGLLightSource(int index)
        {
            this.index = index;
        }

        public void init(uint program)
        {
            position_attrib = glGetUniformLocation(program, "light_source[" + index.to_string() + "].position");
            color_attrib = glGetUniformLocation(program, "light_source[" + index.to_string() + "].color");
            intensity_attrib = glGetUniformLocation(program, "light_source[" + index.to_string() + "].intensity");
        }

        public void apply(Transform transform, Color color, float intensity)
        {
            Vec3 position = transform.get_full_matrix().get_position();
            glUniform3f(position_attrib, position.x, position.y, position.z);
            glUniform3f(color_attrib, color.r, color.g, color.b);
            glUniform1f(intensity_attrib, intensity);
        }

        public int index { get; private set; }
    }
}