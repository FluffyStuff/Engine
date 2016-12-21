using SDL;
using GL;

public abstract class Engine : Object
{
    public Engine(bool multithread_rendering)
    {
        this.multithread_rendering = multithread_rendering;
    }

    public abstract bool init(string window_name, int window_width, int window_height, int multisampling, bool fullscreen);
    public abstract void stop();

    // For global deinitialization
    public abstract void quit();

    public bool multithread_rendering { get; private set; }
    public IWindowTarget window { get; protected set; }
    public RenderTarget renderer { get; protected set; }
}

public class SDLGLEngine : Engine
{
    private static bool initialized = false;

    private Window gl_window;
    private GLContext context;

    private GLib.Mutex init_mutex = GLib.Mutex();
    private GLib.Mutex stop_mutex = GLib.Mutex();
    private bool init_status;
    private string _window_name;
    private int _window_width;
    private int _window_height;
    private int _multisamples;
    private bool _fullscreen;

    public SDLGLEngine(bool multithread_rendering)
    {
        base(multithread_rendering);
    }

    private bool global_init()
    {
        if (initialized)
            return true;
        initialized = true;

        if (SDL.init(SDL.InitFlag.EVERYTHING) < 0)
        {
            EngineLog.log(EngineLogType.ENGINE, "SDLGLEngine", "Could not init SDL");
            initialized = false;
            return false;
        }

        return true;
    }

    public override bool init(string window_name, int window_width, int window_height, int multisamples, bool fullscreen)
    {
        if (!global_init())
            return false;

        if (!multithread_rendering)
            return internal_init(window_name, window_width, window_height, multisamples, fullscreen);

        _window_name = window_name;
        _window_width = window_width;
        _window_height = window_height;
        _multisamples = multisamples;
        _fullscreen = fullscreen;

        ref();
        init_mutex.lock();
        Threading.start0(init_thread);
        init_mutex.lock();
        init_mutex.unlock();

        return init_status;
    }

    private void init_thread()
    {
        init_status = internal_init(_window_name, _window_width, _window_height, _multisamples, _fullscreen);
        init_mutex.unlock();

        if (init_status)
            renderer.cycle();
        stop_mutex.unlock();
        unref();
    }

    private bool internal_init(string window_name, int window_width, int window_height, int multisamples, bool fullscreen)
    {
        gl_window = create_window(window_name, window_width, window_height, fullscreen, multisamples);
        if (gl_window == null)
        {
            Environment.log(LogType.ERROR, "SDLGLEngine", "Could not create window");
            return false;
        }

        context = create_context(gl_window);
        if (context == null)
        {
            Environment.log(LogType.ERROR, "SDLGLEngine", "Could not create graphics context");
            return false;
        }

        GLEW.experimental = true;

        if (GLEW.init())
        {
            EngineLog.log(EngineLogType.ENGINE, "SDLGLEngine", "Could not init GLEW");
            return false;
        }

        window = new SDLWindowTarget(gl_window, fullscreen);
        renderer = new OpenGLRenderer(window, multithread_rendering);

        return renderer.init();
    }

    private Window? create_window(string name, int width, int height, bool fullscreen, int multisamples)
    {
        int s = (int)Math.pow(2, multisamples);
        SDL.GL.set_attribute(GLattr.MULTISAMPLEBUFFERS, 1);
        SDL.GL.set_attribute(GLattr.MULTISAMPLESAMPLES, s);
        SDL.GL.set_attribute(GLattr.CONTEXT_MAJOR_VERSION, 2);
        SDL.GL.set_attribute(GLattr.CONTEXT_MINOR_VERSION, 1);
        SDL.GL.set_attribute(GLattr.CONTEXT_PROFILE_MASK, 1); // Core Profile

        var flags = WindowFlags.OPENGL | WindowFlags.RESIZABLE;
        if (fullscreen)
            flags |= WindowFlags.FULLSCREEN;

        return new Window(name, Window.POS_CENTERED, Window.POS_CENTERED, width, height, flags);
    }

    private GLContext? create_context(Window window)
    {
        GLContext? context = SDL.GL.create_context(window);
        if (context == null)
            return null;

        return context;
    }

    public override void stop()
    {
        stop_mutex.lock();
        renderer.stop();
        stop_mutex.lock();
        stop_mutex.unlock();
    }

    public override void quit()
    {
        if (initialized)
        {
            SDL.quit();
            initialized = false;
        }
    }
}
