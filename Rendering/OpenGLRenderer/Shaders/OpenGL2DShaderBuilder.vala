namespace Engine
{
    public class OpenGL2DShaderBuilder : OpenGLShaderBuilder
    {
        public OpenGL2DShaderBuilder()
        {
            OpenGLShaderUniform model_transform_uniform = new OpenGLShaderUniform("model_transform", OpenGLShaderPrimitiveType.MAT3);
            OpenGLShaderUniform texture_uniform = new OpenGLShaderUniform("texture", OpenGLShaderPrimitiveType.CUSTOM)
            { custom_type = "sampler2D" };
            OpenGLShaderUniform use_texture_uniform = new OpenGLShaderUniform("use_texture", OpenGLShaderPrimitiveType.BOOL);
            OpenGLShaderUniform diffuse_color_uniform = new OpenGLShaderUniform("diffuse_color", OpenGLShaderPrimitiveType.VEC4);

            OpenGLShaderVarying frag_texture_coord_varying = new OpenGLShaderVarying("frag_texture_coord", OpenGLShaderPrimitiveType.VEC2);
            OpenGLShaderAttribute position_attribute = new OpenGLShaderAttribute("position", OpenGLShaderPrimitiveType.VEC2);

            OpenGLShaderCodeBlock vertex_main_code = new OpenGLShaderCodeBlock(vertex_main_code_string)
            { dependencies = { model_transform_uniform, position_attribute, frag_texture_coord_varying } };

            OpenGLShaderCodeBlock fragment_main_code = new OpenGLShaderCodeBlock(fragment_main_code_string)
            { dependencies = { texture_uniform, use_texture_uniform, diffuse_color_uniform, frag_texture_coord_varying } };

            add_vertex_block(vertex_main_code);
            add_fragment_block(fragment_main_code);
        }

        private string vertex_main_code_string = """
            frag_texture_coord = (position + 1.0) / 2.0;
            frag_texture_coord.y = 1.0 - frag_texture_coord.y;
            
            gl_Position = vec4((model_transform * vec3(position, 1.0)).xy, 0.0, 1.0);
        """;

        private string fragment_main_code_string = """
            vec4 color;
            if (use_texture)
                color = texture2D(texture, frag_texture_coord);
            else
                color = vec4(0.0, 0.0, 0.0, 1.0);
            color.xyz += diffuse_color.xyz;
            color.a *= diffuse_color.a;
            
            gl_FragColor = color;
        """;
    }
}