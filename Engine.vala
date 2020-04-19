using SDL;
using GL;

namespace Engine
{
    public abstract class Engine : Object
    {
        Engine(bool multithread_rendering, string version_string, bool debug)
        {
            this.multithread_rendering = multithread_rendering;
            this.debug = debug;
            this.version_string = version_string;
        }

        public abstract bool init(string window_name, Size2i window_size, Vec2i window_position, ScreenTypeEnum screen_type, int multisampling);
        public abstract void stop();

        // For global deinitialization
        public abstract void quit();

        public bool multithread_rendering { get; private set; }
        public bool debug { get; private set; }
        public string version_string { get; private set; }
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
        private Size2i _window_size;
        private Vec2i _window_position;
        private int _multisamples;
        private ScreenTypeEnum _screen_type;

        public SDLGLEngine(bool multithread_rendering, string version_string, bool debug)
        {
            base(multithread_rendering, version_string, debug);
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

        public override bool init(string window_name, Size2i window_size, Vec2i window_position, ScreenTypeEnum screen_type, int multisamples)
        {
            if (!global_init())
                return false;

            if (!multithread_rendering)
                return internal_init(window_name, window_size, window_position, screen_type, multisamples);

            _window_name = window_name;
            _window_size = window_size;
            _window_position = window_position;
            _multisamples = multisamples;
            _screen_type = screen_type;

            ref();
            init_mutex.lock();
            Threading.start0(init_thread);
            init_mutex.lock();
            init_mutex.unlock();

            return init_status;
        }

        private void init_thread()
        {
            init_status = internal_init(_window_name, _window_size, _window_position, _screen_type, _multisamples);
            init_mutex.unlock();

            if (init_status)
                renderer.cycle();
            stop_mutex.unlock();
            unref();
        }

        private bool internal_init(string window_name, Size2i window_size, Vec2i window_position, ScreenTypeEnum screen_type, int multisamples)
        {
            gl_window = create_window(window_name, window_size, window_position, screen_type, multisamples);
            if (gl_window == null)
            {
                EngineLog.log(EngineLogType.ENGINE, "SDLGLEngine", "Could not create window");
                return false;
            }

            context = create_context(gl_window);
            if (context == null)
            {
                EngineLog.log(EngineLogType.ENGINE, "SDLGLEngine", "Could not create graphics context");
                return false;
            }

            GLEW.experimental = true;

            if (GLEW.init())
            {
                EngineLog.log(EngineLogType.ENGINE, "SDLGLEngine", "Could not init GLEW");
                return false;
            }

            window = new SDLWindowTarget(gl_window, screen_type);
            renderer = new OpenGLRenderer(window, multithread_rendering, version_string, debug);

            return renderer.init();
        }

        private Window? create_window(string name, Size2i size, Vec2i position, ScreenTypeEnum screen_type, int multisamples)
        {
            int s = (int)Math.pow(2, multisamples);
            SDL.GL.set_attribute(GLattr.MULTISAMPLEBUFFERS, 1);
            SDL.GL.set_attribute(GLattr.MULTISAMPLESAMPLES, s);
            SDL.GL.set_attribute(GLattr.CONTEXT_MAJOR_VERSION, 2);
            SDL.GL.set_attribute(GLattr.CONTEXT_MINOR_VERSION, 1);
            SDL.GL.set_attribute(GLattr.CONTEXT_PROFILE_MASK, 1); // Core Profile

            if (debug)
                SDL.GL.set_attribute(GLattr.CONTEXT_FLAGS, GLcontext.DEBUG_FLAG);

            var flags = WindowFlags.OPENGL | WindowFlags.RESIZABLE;
            if (screen_type == ScreenTypeEnum.FULLSCREEN)
                flags |= WindowFlags.FULLSCREEN_DESKTOP;
            else if(screen_type == ScreenTypeEnum.MAXIMIZED)
                flags |= WindowFlags.MAXIMIZED;
            
            if (position.x == -1 && position.y == -1)
                position = Vec2i(Window.POS_UNDEFINED, Window.POS_UNDEFINED);

            return new Window(name, position.x, position.y, size.width, size.height, flags);
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

            if (multithread_rendering)
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

    public enum ScreenTypeEnum
    {
        FULLSCREEN,
        MAXIMIZED,
        WINDOWED
    }
}