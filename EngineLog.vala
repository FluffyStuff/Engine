public class EngineLog
{
    private static LogCallback? log_callback;

    private EngineLog() {}

    public static void set_log_callback(LogCallback? callback)
    {
        log_callback = callback;
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
    ENGINE,
    NETWORK,
    RENDERING,
    DEBUG
}
