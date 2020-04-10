namespace Engine
{
    public class Animation
    {
        private AnimationTime times;
        private DeltaTimer timer = new DeltaTimer();
        private bool animation_started;
        private bool animation_done;
        private bool done;

        public signal void animate(float times, Animation animation);
        public signal void animate_start(Animation animation);
        public signal void animate_finish(Animation animation);
        public signal void finished(Animation animation);
        public signal void post_finished(Animation animation);

        public delegate void animation_delegate(float time);

        public Animation(AnimationTime times)
        {
            this.times = times;
            curve = new LinearCurve();
        }

        public Animation.delay(float delay)
        {
            times = new AnimationTime(delay, 0, 0);
            curve = new LinearCurve();
        }

        public void process(DeltaArgs delta)
        {
            if (done)
                return;

            float elapsed = timer.elapsed(delta);

            if (elapsed > times.pre)
            {
                if (!animation_started)
                {
                    animation_started = true;
                    animate_start(this);
                }

                if (!animation_done)
                {
                    float time = (elapsed - times.pre) / times.time;

                    if (time >= 1 || times.time <= 0)
                    {
                        time = 1;
                        animation_done = true;
                    }

                    time = curve.map(time);

                    animate(time, this);

                    if (animation_done)
                        animate_finish(this);
                }

                if (elapsed >= times.total())
                {
                    finished(this);
                    done = true;
                    post_finished(this);
                }
            }
        }

        public Curve curve { get; set; }
    }

    public class AnimationTime : Serializable
    {
        public AnimationTime(float pre, float time, float post)
        {
            this.pre = pre;
            this.time = time;
            this.post = post;
        }
        
        public AnimationTime.preset(float time)
        {
            this.time = time;
        }
        
        public AnimationTime.zero() {}

        public float total()
        {
            return pre + time + post;
        }

        public float pre { get; protected set; }
        public float time { get; protected set; }
        public float post { get; protected set; }
    }
}