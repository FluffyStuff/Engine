public struct Vec4
{
    float x;
    float y;
    float z;
    float w;

    public Vec4.empty()
    {
        x = 0;
        y = 0;
        z = 0;
        w = 0;
    }

    public Vec4(float x, float y, float z, float w)
    {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    public float dot(Vec4 other)
    {
        return x * other.x + y * other.y + z * other.z + w * other.w;
    }

    public Vec4 minus(Vec4 other)
    {
        return Vec4(x - other.x, y - other.y, z - other.z, w - other.w);
    }

    public float get(int i)
    {
        if (i == 0) return x;
        if (i == 1) return y;
        if (i == 2) return z;
        if (i == 3) return w;
        return 0;
    }
}
