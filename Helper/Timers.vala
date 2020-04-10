using GLib;

namespace Engine
{
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

    public class DelayTimer
    {
        private bool time_set;
        private float time;
        private float _delay;

        public bool active(float time)
        {
            if (!is_active)
                return false;

            if (!time_set)
            {
                this.time = time + delay;
                time_set = true;
            }

            if (time >= this.time)
            {
                is_active = false;
                return true;
            }

            return false;
        }

        public void set_time(float delay, bool add = false)
        {
            if (add && is_active)
            {
                _delay += delay;
                time += delay;
                return;
            }

            _delay = delay;
            time_set = false;
            is_active = true;
        }

        public float delay
        {
            get { return _delay; }
            set
            {
                set_time(delay);
            }
        }

        public bool is_active { get; private set; }
    }
}