using SDL;
using GL;

public class Engine : Object
{
    private static bool initialized = false;

    ~Engine()
    {
        exit();
    }

    public bool init()
    {
        if (initialized)
            return true;

        if (SDL.init(SDL.InitFlag.EVERYTHING) < 0)
        {
            print("Engine: Could not init SDL!\n");
            return false;
        }

        initialized = true;
        return true;
    }

    public void set_multisampling(int multisampling)
    {
        if (!initialized)
            return;

        int s = (int)Math.pow(2, multisampling);
        SDL.GL.set_attribute(SDL.GLattr.MULTISAMPLEBUFFERS, 1);
        SDL.GL.set_attribute(SDL.GLattr.MULTISAMPLESAMPLES, s);
    }

    public Window? create_window(string name, int width, int height, bool fullscreen)
    {
        if (!initialized)
            return null;
        var flags = WindowFlags.RESIZABLE | WindowFlags.OPENGL;
        if (fullscreen)
            flags |= WindowFlags.FULLSCREEN_DESKTOP;
        return new Window(name, Window.POS_CENTERED, Window.POS_CENTERED, width, height, flags);
    }

    public GLContext? create_context(Window window)
    {
        GLContext? context = SDL.GL.create_context(window);
        if (context == null)
            return null;

        SDL.GL.set_attribute(GLattr.CONTEXT_MAJOR_VERSION, 2);
        SDL.GL.set_attribute(GLattr.CONTEXT_MINOR_VERSION, 1);
        SDL.GL.set_attribute(GLattr.CONTEXT_PROFILE_MASK, 1); // Core Profile
        GLEW.experimental = true;

        if (GLEW.init())
        {
            print("Engine: Could not init GLEW!\n");
            return null;
        }

        return context;
    }

    public void exit()
    {
        if (initialized)
        {
            SDL.quit();
            initialized = false;
        }
    }
}
