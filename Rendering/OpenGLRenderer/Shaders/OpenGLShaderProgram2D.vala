using GL;

namespace Engine
{
    class OpenGLShaderProgram2D
    {
        private uint program;
        private OpenGLShader vertex_shader;
        private OpenGLShader fragment_shader;

        private uint vertice_handle;
        private uint array_handle;

        private int vert_position_attribute;
        private int model_transform_attrib = -1;
        private int use_texture_attrib = -1;
        private int diffuse_color_attrib = -1;

        public OpenGLShaderProgram2D()
        {
            vert_position_attribute = 0;

            OpenGLShaderBuilder builder = new OpenGL2DShaderBuilder();
            string vert = builder.create_vertex_shader();
            string frag = builder.create_fragment_shader();

            vertex_shader = new OpenGLShader(FileLoader.split_string(vert, true), OpenGLShader.ShaderType.VERTEX_SHADER);
            fragment_shader = new OpenGLShader(FileLoader.split_string(frag, true), OpenGLShader.ShaderType.FRAGMENT_SHADER);
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

            glLinkProgram(program);

            float[] vertices =
            {
                -1, -1,
                1, -1,
                -1,  1,
                1,  1
            };

            uint vert[1];
            glGenBuffers(1, vert);
            vertice_handle = vert[0];

            glBindBuffer(GL_ARRAY_BUFFER, vertice_handle);
            glBufferData(GL_ARRAY_BUFFER, 8 * sizeof(float), (GLvoid[])vertices, GL_STATIC_DRAW);

            uint vao[1];
            OpenGLFunctions.glGenVertexArrays(1, vao);
            array_handle = vao[0];

            OpenGLFunctions.glBindVertexArray(array_handle);
            glEnableVertexAttribArray(vert_position_attribute);
            glBindBuffer(GL_ARRAY_BUFFER, vertice_handle);
            glVertexAttribPointer(vert_position_attribute, 2, GL_FLOAT, false, 0, 0);

            model_transform_attrib = glGetUniformLocation(program, "model_transform");
            use_texture_attrib = glGetUniformLocation(program, "use_texture");
            diffuse_color_attrib = glGetUniformLocation(program, "diffuse_color");

            uint err = glGetError();
            if (err != 0 && err != 0x500)
            {
                EngineLog.log(EngineLogType.RENDERING, "OpenGLShaderProgram2D", "GL shader program linkage failure (" + err.to_string() + ")");
                return false;
            }

            return true;
        }

        public void apply_scene()
        {
            glUseProgram(program);
            OpenGLFunctions.glBindVertexArray(array_handle);
        }

        public void render_object(Mat3 model_transform, Color diffuse_color, bool use_texture)
        {
            glUniformMatrix3fv(model_transform_attrib, 1, false, model_transform.get_data());
            glUniform1i(use_texture_attrib, use_texture ? 1 : 0);
            glUniform4f(diffuse_color_attrib, diffuse_color.r, diffuse_color.g, diffuse_color.b, diffuse_color.a);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        }
    }
}