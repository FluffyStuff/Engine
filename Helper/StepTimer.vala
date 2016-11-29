using GLib;

public class StepTimer
{
    private Timer timer = new Timer();
    private double last_time;
    private double step;
    private bool skip_multiples;

    public StepTimer(float step_seconds = 1, bool skip_multiples = true)
    {
        step = step_seconds;
        this.skip_multiples = skip_multiples;
        last_time = timer.elapsed();
    }

    public bool elapsed()
    {
        double time = timer.elapsed();
        double diff = time - last_time;

        if (diff < step)
            return false;

        double s = step;
        if (skip_multiples)
            s *= (int)(diff / step);
        last_time += s;

        return true;
    }
}
