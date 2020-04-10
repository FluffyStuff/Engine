namespace Engine
{
    public class EngineMutex
    {
        public virtual void lock() {}
        public virtual void unlock() {}
    }

    public class RegularEngineMutex : EngineMutex
    {
        private Mutex mutex = Mutex();

        public override void lock()
        {
            mutex.lock();
        }

        public override void unlock()
        {
            mutex.unlock();
        }
    }
}