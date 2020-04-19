namespace Engine
{
    public void EngineLogDebug(string text)
    {
        EngineLog.log(EngineLogType.DEBUG, "-", text);
    }

    public class EngineLog
    {
        private static LogCallback? log_callback;

        private EngineLog() {}

        public static void set_log_callback(LogCallback? callback)
        {
            log_callback = callback;

            log(EngineLogType.DEBUG, "EngineLog", "Engine log installed");
        }

        public static void log(EngineLogType log_type, string origin, string message)
        {
            if (log_callback != null)
                log_callback.log(log_type, origin, message);
        }
    }

    public class LogCallback
    {
        public signal void log(EngineLogType log_type, string origin, string message);
    }

    public enum EngineLogType
    {
        ERROR,
        ENGINE,
        NETWORK,
        RENDERING,
        DEBUG
    }
}