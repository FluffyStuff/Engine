using Gee;

namespace Engine
{
    public class ObjParser
    {
        // TODO: Add curve parsing
        public static GeometryData? parse(string path, string filename)
        {
            string p = path + filename + ".obj";
            string[]? file = FileLoader.load(p);
            if (file == null)
            {
                EngineLog.log(EngineLogType.DEBUG, "ObjParser.parse", "Could not load file: " + p);
                return null;
            }
            
            ObjInfo info = parse_data(file);

            ArrayList<MaterialData> mats = new ArrayList<MaterialData>();

            foreach (string mat in info.materials)
                mats.add_all(load_material(path + mat));

            return new GeometryData(info.models, mats);
        }

        public static ArrayList<ModelData> parse_string(string str)
        {
            ObjInfo info = parse_data(FileLoader.split_string(str));
            return info.models;
        }

        public static ArrayList<ModelData> parse_strings(string[] str)
        {
            ObjInfo info = parse_data(str);
            return info.models;
        }

        private static ObjInfo parse_data(string[] data)
        {
            ArrayList<ModelData> models = new ArrayList<ModelData>();

            string? name = null;
            string? material = null;
            ArrayList<string> mtl = new ArrayList<string>();
            ArrayList<string> v = new ArrayList<string>();
            ArrayList<string> vt = new ArrayList<string>();
            ArrayList<string> vn = new ArrayList<string>();
            ArrayList<string> f = new ArrayList<string>();

            foreach (string line in data)
            {
                string[] lines = line.strip().split(" ", 2);
                if (lines.length < 2)
                    continue;

                if (lines[0] == "o")
                {
                    if (name != null)
                    {
                        ModelData? model = process_model_data(name, material, v, vt, vn, f);
                        if (model != null)
                            models.add(model);
                        f.clear();

                        material = null;
                    }

                    name = lines[1];
                }
                else if (lines[0] == "usemtl")
                    material = lines[1];
                else if (lines[0] == "mtllib")
                    mtl.add(lines[1]);
                else if (lines[0] == "v")
                    v.add(lines[1]);
                else if (lines[0] == "vt")
                    vt.add(lines[1]);
                else if (lines[0] == "vn")
                    vn.add(lines[1]);
                else if (lines[0] == "f")
                    f.add(lines[1]);
            }

            if (name != null)
            {
                ModelData? model = process_model_data(name, material, v, vt, vn, f);
                if (model != null)
                    models.add(model);
            }

            return new ObjInfo(models, mtl);
        }

        private static ModelData? process_model_data
        (
            string? name,
            string? material,
            ArrayList<string> v,
            ArrayList<string> vt,
            ArrayList<string> vn,
            ArrayList<string> f
        )
        {
            try
            {
                ModelVertex[] vertices = new ModelVertex[v.size];
                ModelUV[] uvs = new ModelUV[vt.size];
                ModelNormal[] normals = new ModelNormal[vn.size];

                for (int i = 0; i < v.size; i++)
                    vertices[i] = parse_vertex(v[i]);
                for (int i = 0; i < vt.size; i++)
                    uvs[i] = parse_uv(vt[i]);
                for (int i = 0; i < vn.size; i++)
                    normals[i] = parse_normal(vn[i]);

                Triangles[] data = new Triangles[f.size];

                for (int n = 0; n < f.size; n++)
                {
                    ModelDataIndex[] indices = parse_face(f[n]);
                    ModelTriangle[] triangles = new ModelTriangle[indices.length - 2];

                    for (int i = 2; i < indices.length; i++)
                    {
                        bool has_uv = indices[0].has_uv;
                        bool has_normal = indices[0].has_normal;

                        // Can't declare this inline due to a bug in vala
                        ModelUV empty_uv = {};
                        ModelNormal empty_normal = {};
                        ModelUV uv_a = has_uv ? uvs[indices[  0].uv - 1] : empty_uv;
                        ModelUV uv_b = has_uv ? uvs[indices[i-1].uv - 1] : empty_uv;
                        ModelUV uv_c = has_uv ? uvs[indices[  i].uv - 1] : empty_uv;
                        ModelNormal normal_a = has_normal ? normals[indices[  0].normal - 1] : empty_normal;
                        ModelNormal normal_b = has_normal ? normals[indices[i-1].normal - 1] : empty_normal;
                        ModelNormal normal_c = has_normal ? normals[indices[  i].normal - 1] : empty_normal;

                        triangles[i-2] = ModelTriangle()
                        {
                            vertex_a = vertices[indices[  0].vertex - 1],
                            vertex_b = vertices[indices[i-1].vertex - 1],
                            vertex_c = vertices[indices[  i].vertex - 1],
                            uv_a = uv_a,
                            uv_b = uv_b,
                            uv_c = uv_c,
                            normal_a = normal_a,
                            normal_b = normal_b,
                            normal_c = normal_c,
                            has_uv = has_uv,
                            has_normal = has_normal
                        };
                    }

                    data[n] = new Triangles(triangles);
                }

                int count = 0;
                foreach (Triangles d in data)
                    count += d.triangles.length;

                ModelTriangle[] triangles = new ModelTriangle[count];

                for (int i = 0, a = 0; i < data.length; i++)
                    for (int t = 0; t < data[i].triangles.length; t++)
                        triangles[a++] = data[i].triangles[t];

                return new ModelData(name, material, triangles);
            }
            catch (ParsingError e)
            {
                EngineLog.log(EngineLogType.ERROR, "ObjParser.process_model_data", "Error while parsing " + name + ": " + e.message);
                return null;
            }
        }

        private static ModelVertex parse_vertex(string line) throws ParsingError
        {
            string[] parts = line.split(" ");

            if (parts.length != 3 && parts.length != 4)
                throw new ParsingError.PARSING("Invalid number of vertex line args.");

            double x, y, z, w = 1;
            bool parsed = double.try_parse(parts[0], out x);
            parsed &= double.try_parse(parts[1], out y);
            parsed &= double.try_parse(parts[2], out z);

            if (parts.length >= 4)
                parsed &= double.try_parse(parts[3], out w);

            if (!parsed)
                throw new ParsingError.PARSING("Invalid double value in vertex line.");

            return ModelVertex() { x = (float)x, y = (float)y, z = (float)z, w = (float)w };
        }

        private static ModelUV parse_uv(string line) throws ParsingError
        {
            string[] parts = line.split(" ");

            if (parts.length < 1 && parts.length > 3)
                throw new ParsingError.PARSING("Invalid number of UV line args.");

            double u, v = 0, w = 0;
            bool parsed = double.try_parse(parts[0], out u);

            if (parts.length >= 2)
                parsed &= double.try_parse(parts[1], out v);

            if (parts.length >= 3)
                parsed &= double.try_parse(parts[2], out w);

            parsed = true;
            if (!parsed)
                throw new ParsingError.PARSING("Invalid double value in UV line.");

            v = 1-v;

            return ModelUV() { u = (float)u, v = (float)v, w = (float)w };
        }

        private static ModelNormal parse_normal(string line) throws ParsingError
        {
            string[] parts = line.split(" ");

            if (parts.length != 3)
                throw new ParsingError.PARSING("Invalid number of normal line args.");

            double i, j, k;
            bool parsed = double.try_parse(parts[0], out i);
            parsed &= double.try_parse(parts[1], out j);
            parsed &= double.try_parse(parts[2], out k);

            if (!parsed)
                throw new ParsingError.PARSING("Invalid double value in normal line.");

            return ModelNormal() { i = (float)i, j = (float)j, k = (float)k };
        }

        private static ModelDataIndex[] parse_face(string line) throws ParsingError
        {
            string[] parts = line.split(" ");

            if (parts.length < 3)
                throw new ParsingError.PARSING("Too few vertices in face.");

            ModelDataIndex[] index = new ModelDataIndex[parts.length];

            bool normal_only = parts[0].contains("//");
            bool has_uv = false, has_normal = false;

            for (int i = 0; i < parts.length; i++)
            {
                int64 v, t = -1, n = -1;

                string[] indices = parts[i].split(normal_only ? "//" : "/");
                if (indices.length < 1)
                    throw new ParsingError.PARSING("Invalid number of face part args.");

                bool parsed = int64.try_parse(indices[0], out v);

                if (normal_only)
                {
                    if (indices.length != 2)
                        throw new ParsingError.PARSING("Invalid number of face part args.");

                    parsed &= int64.try_parse(indices[1], out n);
                    has_normal = true;
                }
                else
                {
                    if (indices.length > 3)
                        throw new ParsingError.PARSING("Invalid number of face part args.");

                    if (indices.length >= 2)
                    {
                        parsed &= int64.try_parse(indices[1], out t);
                        has_uv = true;
                    }

                    if (indices.length >= 3)
                    {
                        parsed &= int64.try_parse(indices[2], out n);
                        has_normal = true;
                    }
                }

                if (!parsed)
                    throw new ParsingError.PARSING("Invalid double value in face line part.");

                index[i] = ModelDataIndex() { vertex = (int)v, uv = (int)t, normal = (int)n, has_uv = has_uv, has_normal = has_normal };
            }

            return index;
        }

        private static ArrayList<MaterialData> load_material(string name)
        {
            string[] data = FileLoader.load(name);
            return parse_material(data);
        }

        private static ArrayList<MaterialData> parse_material(string[] data)
        {
            ArrayList<MaterialData> materials = new ArrayList<MaterialData>();

            try
            {
                string? name = null;
                string? Ns = null;
                string? Ka = null;
                string? Kd = null;
                string? Ks = null;
                string? d = null;
                string? illum = null;
                bool newmat = false;

                for (int i = 0; i < data.length; i++)
                {
                    string[] lines = data[i].split(" ", 2);

                    if (lines.length < 2)
                    {
                        if (!newmat)
                            continue;

                        materials.add(
                        new MaterialData
                        (
                            name,
                            parse_float(Ns),
                            parse_vec3(Ka),
                            parse_vec3(Kd),
                            parse_vec3(Ks),
                            parse_float(d),
                            parse_int(illum)
                        ));

                        newmat = false;
                        continue;
                    }

                    if (lines[0] == "newmtl")
                    {
                        name = lines[1];
                        Ns = "0.0";
                        Ka = "0.0 0.0 0.0";
                        Kd = "0.0 0.0 0.0";
                        Ks = "0.0 0.0 0.0";
                        d = "0.0";
                        illum = "0";

                        newmat = true;
                    }
                    else if (!newmat)
                        continue;
                    else if (lines[0] == "Ns")
                        Ns = lines[1];
                    else if (lines[0] == "Ka")
                        Ka = lines[1];
                    else if (lines[0] == "Kd")
                        Kd = lines[1];
                    else if (lines[0] == "Ks")
                        Ks = lines[1];
                    else if (lines[0] == "d")
                        d = lines[1];
                    else if (lines[0] == "illum")
                        illum = lines[1];
                }

                if (newmat)
                {
                    materials.add(
                    new MaterialData
                    (
                        name,
                        parse_float(Ns),
                        parse_vec3(Ka),
                        parse_vec3(Kd),
                        parse_vec3(Ks),
                        parse_float(d),
                        parse_int(illum)
                    ));
                }
            }
            catch {}

            return materials;
        }

        private static Vec3 parse_vec3(string v) throws ParsingError
        {
            string[] parts = v.split(" ");

            if (parts.length != 3)
                throw new ParsingError.PARSING("Invalid number of material Vec3 line args.");

            double x, y, z;
            bool parsed = double.try_parse(parts[0], out x);
            parsed &= double.try_parse(parts[1], out y);
            parsed &= double.try_parse(parts[2], out z);

            if (!parsed)
                throw new ParsingError.PARSING("Invalid double value in material Vec3 line.");

            return Vec3((float)x, (float)y, (float)z);
        }

        private static float parse_float(string f) throws ParsingError
        {
            string[] parts = f.split(" ");

            if (parts.length != 1)
                throw new ParsingError.PARSING("Invalid number of material float line args.");

            double x;
            bool parsed = double.try_parse(parts[0], out x);

            if (!parsed)
                throw new ParsingError.PARSING("Invalid float value in material float line.");

            return (float)x;
        }

        private static int parse_int(string i) throws ParsingError
        {
            string[] parts = i.split(" ");

            if (parts.length != 1)
                throw new ParsingError.PARSING("Invalid number of material int line args.");

            int x;
            //bool parsed = int32.try_parse(parts[0], out x); Has been removed for some reason...
            x = int.parse(parts[0]);

            //if (!parsed)
            //    throw new ParsingError.PARSING("Invalid int value in material int line.");

            return x;
        }

        private struct ModelDataIndex
        {
            public int vertex;
            public int uv;
            public int normal;
            public bool has_uv;
            public bool has_normal;
        }

        private class ObjInfo
        {
            public ObjInfo(ArrayList<ModelData> models, ArrayList<string> materials)
            {
                this.models = models;
                this.materials = materials;
            }

            public ArrayList<ModelData> models { get; private set; }
            public ArrayList<string> materials { get; private set; }
        }
    }

    public struct ModelVertex
    {
        float x;
        float y;
        float z;
        float w;
    }

    public struct ModelUV
    {
        float u;
        float v;
        float w;
    }

    public struct ModelNormal
    {
        float i;
        float j;
        float k;
    }

    class Triangles
    {
        public Triangles(ModelTriangle[] triangles)
        {
            this.triangles = triangles;
        }

        public ModelTriangle[] triangles { get; private set; }
    }

    public class GeometryData
    {
        public GeometryData(ArrayList<ModelData> models, ArrayList<MaterialData> materials)
        {
            this.models = models;
            this.materials = materials;
        }

        public ArrayList<ModelData> models { get; private set; }
        public ArrayList<MaterialData> materials { get; private set; }
    }

    public class ModelData
    {
        public ModelData(string? name, string? material_name, ModelTriangle[] triangles)
        {
            this.name = name;
            this.material_name = material_name;

            points = calc_points(triangles);
            Vec3 s, c;
            calc(points, out s, out c);
            size = s;
            center = c;
        }

        public void center_points()
        {
            for (int i = 0; i < points.length; i++)
            {
                ModelVertex v = points[i].vertex;
                v.x -= center.x;
                v.y -= center.y;
                v.z -= center.z;
                points[i].vertex = v;
            }

            center = {};
        }

        private static ModelPoint[] calc_points(ModelTriangle[] triangles)
        {
            ModelPoint[] points = new ModelPoint[triangles.length * 3];

            for (int i = 0; i < triangles.length; i++)
            {
                points[3*i+0] = ModelPoint() { vertex = triangles[i].vertex_a, uv = triangles[i].uv_a, normal = triangles[i].normal_a };
                points[3*i+1] = ModelPoint() { vertex = triangles[i].vertex_b, uv = triangles[i].uv_b, normal = triangles[i].normal_b };
                points[3*i+2] = ModelPoint() { vertex = triangles[i].vertex_c, uv = triangles[i].uv_c, normal = triangles[i].normal_c };
            }

            return points;
        }

        /*private static Vec3 calc_median(ModelPoint[] points)
        {
            Vec3 sum = {};

            foreach (ModelPoint p in points)
            {
                sum.x += p.vertex.x;
                sum.y += p.vertex.y;
                sum.z += p.vertex.z;
            }

            return Vec3() { x = sum.x / points.length, y = sum.y / points.length, z = sum.z / points.length };
        }*/

        private static void calc(ModelPoint[] points, out Vec3 size, out Vec3 center)
        {
            size = center = {};
            Vec3 min = Vec3.empty(), max = Vec3.empty();

            if (points.length > 0)
            {
                min = Vec3(points[0].vertex.x, points[0].vertex.y, points[0].vertex.z);
                max = min;
            }

            for (int i = 1; i < points.length; i++)
            {
                ModelVertex p = points[i].vertex;
                min.x = Math.fminf(min.x, p.x);
                min.y = Math.fminf(min.y, p.y);
                min.z = Math.fminf(min.z, p.z);
                max.x = Math.fmaxf(max.x, p.x);
                max.y = Math.fmaxf(max.y, p.y);
                max.z = Math.fmaxf(max.z, p.z);
            }

            size = Vec3(max.x - min.x, max.y - min.y, max.z - min.z);
            center = Vec3((max.x + min.x) / 2, (max.y + min.y) / 2, (max.z + min.z) / 2);
        }

        public string? name { get; private set; }
        public string? material_name { get; private set; }
        public ModelPoint[] points { get; private set; }
        public Vec3 center { get; private set; }
        public Vec3 size { get; private set; }
    }

    public class MaterialData
    {
        public MaterialData
        (
            string name,
            float ns,
            Vec3 Ka,
            Vec3 Kd,
            Vec3 Ks,
            float d,
            float illum
        )
        {
            this.name = name;
            specular_exponent = ns;
            ambient_color = Ka;
            diffuse_color = Kd;
            specular_color = Ks;
            alpha = 1 - d;
            illumination_model = (IlluminationModel)illum;
        }

        public string name { get; set; }
        public Vec3 ambient_color { get; set; }
        public Vec3 diffuse_color { get; set; }
        public Vec3 specular_color { get; set; }
        public float specular_exponent { get; set; }
        public float alpha { get; set; }
        public IlluminationModel illumination_model { get; set; }
    }

    public enum IlluminationModel
    {
        COLOR_ON_AMBIENT_OFF = 0,
        COLOR_ON_AMBIENT_ON = 1,
        HIGHLIGHT_ON = 2,
    }

    public struct ModelPoint
    {
        ModelVertex vertex;
        ModelUV uv;
        ModelNormal normal;
    }

    public struct ModelTriangle
    {
        ModelVertex vertex_a;
        ModelVertex vertex_b;
        ModelVertex vertex_c;
        ModelUV uv_a;
        ModelUV uv_b;
        ModelUV uv_c;
        ModelNormal normal_a;
        ModelNormal normal_b;
        ModelNormal normal_c;
        bool has_uv;
        bool has_normal;
    }

    errordomain ParsingError { PARSING }
}