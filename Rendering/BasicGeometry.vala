namespace Engine
{
    public class BasicGeometry
    {
        private BasicGeometry() {}

        private static ModelData? plane;

        public static ModelData get_plane()
        {
            if (plane == null)
                plane = ObjParser.parse_string(PLANE)[0];
        
            return plane;
        }

        private const string PLANE =
            """
            o Plane
            v -1.000000 0.000000 -1.000000
            v -1.000000 0.000000 1.000000
            v 1.000000 0.000000 1.000000
            v 1.000000 0.000000 -1.000000
            vt 0.000000 1.000000
            vt 0.00000 0 1.000000
            vt 1.000000 0.000000
            vt 1.000000 1.000000
            vn 0.000000 1.000000 0.000000
            f 1/1/1 2/2/1 3/3/1 4/4/1
            """;
    }
}