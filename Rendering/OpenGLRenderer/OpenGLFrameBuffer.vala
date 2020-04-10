using GL;

namespace Engine
{
    // TODO: Error checking
    public class OpenGLFrameBuffer
    {
        private uint texture;

        public OpenGLFrameBuffer(int width, int height)
        {
            render_buffer = new OpenGLRenderBuffer(width, height);
            this.width = width;
            this.height = height;

            uint tex[1];
            glGenTextures(1, tex);
            texture = tex[0];

            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, texture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_SRGB_ALPHA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);

            uint buf[1];
            glGenFramebuffers(1, buf);
            handle = buf[0];

            bind();
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, render_buffer.handle);

            bind_default();
            glBindTexture(GL_TEXTURE_2D, 0);
        }

        ~OpenGLFrameBuffer()
        {
            uint list[1];
            list[0] = texture;
            glDeleteTextures(1, list);
            list[0] = handle;
            glDeleteFramebuffers(1, list);
        }

        /*public void resize(int width, int height)
        {
            if (this.width == width && this.height == height)
                return;

            this.width = width;
            this.height = height;

            glBindTexture(GL_TEXTURE_2D, texture);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_SRGB_ALPHA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);

            render_buffer.resize(width, height);
        }*/

        public void bind()
        {
            glBindFramebuffer(GL_FRAMEBUFFER, handle);
        }

        public static void bind_default()
        {
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
        }

        public OpenGLRenderBuffer render_buffer { get; private set; }
        public uint handle { get; private set; }
        public int width { get; private set; }
        public int height { get; private set; }
    }
}