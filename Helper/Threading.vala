namespace Engine
{
    public class Threading
    {
        public delegate void Del0Arg();
        public delegate void Del1Arg(Object arg1);
        public delegate void Del2Arg(Object arg1, Object arg2);
        public delegate void Del3Arg(Object arg1, Object arg2, Object arg3);
        public delegate void Del4Arg(Object arg1, Object arg2, Object arg3, Object arg4);

        private Threading() {} // Instead of static class

        private static void start_thread(Thread thread)
        {
            new GLib.Thread<Object?>(null, thread.start);
        }

        public static void start0(Del0Arg function)
        {
            start_thread(new Thread0(function));
        }

        public static void start1(Del1Arg function, Object arg1)
        {
            start_thread(new Thread1(function, arg1));
        }

        public static void start2(Del2Arg function, Object arg1, Object arg2)
        {
            start_thread(new Thread2(function, arg1, arg2));
        }

        public static void start3(Del3Arg function, Object arg1, Object arg2, Object arg3)
        {
            start_thread(new Thread3(function, arg1, arg2, arg3));
        }

        public static void start4(Del4Arg function, Object arg1, Object arg2, Object arg3, Object arg4)
        {
            start_thread(new Thread4(function, arg1, arg2, arg3, arg4));
        }

        private abstract class Thread
        {
            public abstract Object? start();
        }

        private class Thread0 : Thread
        {
            private Thread? self;
            private unowned Threading.Del0Arg func;

            public Thread0(Del0Arg func)
            {
                self = this;
                this.func = func;
            }

            public override Object? start()
            {
                func();
                self = null;
                return null;
            }
        }

        private class Thread1 : Thread
        {
            private Thread? self;
            private unowned Threading.Del1Arg func;
            private Object arg1;

            public Thread1(Del1Arg func, Object arg1)
            {
                self = this;
                this.func = func;
                this.arg1 = arg1;
            }

            public override Object? start()
            {
                func(arg1);
                self = null;
                return null;
            }
        }

        private class Thread2 : Thread
        {
            private Thread? self;
            private unowned Threading.Del2Arg func;
            private Object arg1;
            private Object arg2;

            public Thread2(Del2Arg func, Object arg1, Object arg2)
            {
                self = this;
                this.func = func;
                this.arg1 = arg1;
                this.arg2 = arg2;
            }

            public override Object? start()
            {
                func(arg1, arg2);
                self = null;
                return null;
            }
        }

        private class Thread3 : Thread
        {
            private Thread? self;
            private unowned Threading.Del3Arg func;
            private Object arg1;
            private Object arg2;
            private Object arg3;

            public Thread3(Del3Arg func, Object arg1, Object arg2, Object arg3)
            {
                self = this;
                this.func = func;
                this.arg1 = arg1;
                this.arg2 = arg2;
                this.arg3 = arg3;
            }

            public override Object? start()
            {
                func(arg1, arg2, arg3);
                self = null;
                return null;
            }
        }

        private class Thread4 : Thread
        {
            private Thread? self;
            private unowned Threading.Del4Arg func;
            private Object arg1;
            private Object arg2;
            private Object arg3;
            private Object arg4;

            public Thread4(Del4Arg func, Object arg1, Object arg2, Object arg3, Object arg4)
            {
                self = this;
                this.func = func;
                this.arg1 = arg1;
                this.arg2 = arg2;
                this.arg3 = arg3;
                this.arg4 = arg4;
            }

            public override Object? start()
            {
                func(arg1, arg2, arg3, arg4);
                self = null;
                return null;
            }
        }

        public static bool threading { get { return GLib.Thread.supported(); } }
    }

    // A class for storing primitives/structs as objects
    public class Obj<T> : Serializable
    {
        //Can't create property due to a bug in vala
        public T obj;
        public Obj(T t) { obj = (T)t; }
    }
}