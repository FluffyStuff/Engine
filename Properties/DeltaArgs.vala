namespace Engine
{
    public class DeltaArgs
    {
        public DeltaArgs(float time, float delta)
        {
            this.time = time;
            this.delta = delta;
        }

        public float time { get; private set; }
        public float delta { get; private set; }
    }
}