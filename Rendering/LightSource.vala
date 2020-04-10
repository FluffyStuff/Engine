namespace Engine
{
    public class LightSource
    {
        public LightSource()
        {
            transform = new Transform();
            color = Color.white();
            intensity = 1;
        }

        private LightSource.empty() {}

        public LightSource copy()
        {
            LightSource light = new LightSource.empty();
            light.transform = transform.copy_full_parentless();
            light.color = color;
            light.intensity = intensity;

            return light;
        }

        public Transform transform { get; set; }
        public Color color { get; set; }
        public float intensity { get; set; }
    }
}