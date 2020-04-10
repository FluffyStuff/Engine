namespace Engine
{
    public struct Ray
    {
        Vec3 origin;
        Vec3 direction;

        public Ray(Vec3 origin, Vec3 direction)
        {
            this.origin = origin;
            this.direction = direction;
        }
    }
}