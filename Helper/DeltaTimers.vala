public class DeltaTimer
{
    private float start_time;
    private bool started;

    public float elapsed(DeltaArgs args)
    {
        if (!started)
        {
            started = true;
            start_time = args.time;
        }

        return args.time - start_time;
    }

    public void reset()
    {
        started = false;
    }
}

public class EventTimer
{
    private bool active;
    private bool started;
    private float start_time;

    public signal void elapsed(EventTimer timer);

    public EventTimer(float delay, bool active = false)
    {
        this.delay = delay;
        this.active = active;
    }

    public void process(DeltaArgs args)
    {
        if (!active)
            return;

        if (!started)
        {
            start_time = args.time;
            started = true;
        }

        if (args.time - start_time < delay)
            return;

        active = false;

        elapsed(this);
    }

    public void activate()
    {
        active = true;
        started = false;
    }

    public float delay { get; set; }
}
