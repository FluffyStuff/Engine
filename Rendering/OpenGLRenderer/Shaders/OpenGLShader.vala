using GL;

namespace Engine
{
    class OpenGLShader
    {
        private string[] source;
        private ShaderType shader_type;

        public OpenGLShader(string[] source, ShaderType type)
        {
            this.source = source;
            shader_type = type;
        }

        public bool init()
        {
            uint type;

            switch (shader_type)
            {
            case ShaderType.VERTEX_SHADER:
                type = GL_VERTEX_SHADER;
                break;
            case ShaderType.FRAGMENT_SHADER:
                type = GL_FRAGMENT_SHADER;
                break;
            default:
                return false;
            }

            handle = glCreateShader(type);

            glShaderSource(handle, source.length, source, null);
            glCompileShader(handle);

            int success[1];
            glGetShaderiv(handle, GL_COMPILE_STATUS, success);

            if (success[0] != 1)
            {
                int log_size[1];
                glGetShaderiv(handle, GL_INFO_LOG_LENGTH, log_size);
                uint8[] error_log = new uint8[log_size[0]];

                int actual_size[1];
                glGetShaderInfoLog(handle, log_size[0], actual_size, error_log);

                string text = (string)error_log;
                EngineLog.log(EngineLogType.RENDERING, "OpenGLShader", shader_type.to_string() + " shader compilation failure: " + text);

                return false;
            }

            return true;
        }

        public void delete()
        {
            glDeleteShader(handle);
        }

        public uint handle { get; private set; }

        public enum ShaderType
        {
            VERTEX_SHADER,
            FRAGMENT_SHADER
        }
    }
}