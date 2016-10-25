using GL;

// TODO: Error handling
public class OpenGLRenderBuffer
{
    public OpenGLRenderBuffer(int width, int height)
    {
        uint buffer[1];
        glGenRenderbuffers(1, buffer);
        handle = buffer[0];

        bind();
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
        bind_default();
    }

    ~OpenGLRenderBuffer()
    {
        uint buffer[1];
        buffer[0] = handle;
        glDeleteRenderbuffers(1, buffer);
    }

    /*public void resize(int width, int height)
    {
        if (this.width == width && this.height == height)
            return;

        this.width = width;
        this.height = height;

        glBindRenderbuffer(GL_RENDERBUFFER, handle);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
        glBindRenderbuffer(GL_RENDERBUFFER, 0);
    }*/

    public void bind()
    {
        glBindRenderbuffer(GL_RENDERBUFFER, handle);
    }

    public static void bind_default()
    {
        glBindRenderbuffer(GL_RENDERBUFFER, 0);
    }

    public uint handle { get; private set; }
    public int width { get; private set; }
    public int height { get; private set; }
}
