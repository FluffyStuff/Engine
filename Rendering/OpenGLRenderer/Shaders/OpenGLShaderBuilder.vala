using Gee;

namespace Engine
{
    public enum OpenGLShaderPrimitiveType
    {
        CUSTOM,
        VOID,
        BOOL,
        INT,
        FLOAT,
        VEC2,
        VEC3,
        VEC4,
        MAT3,
        MAT4,
        SAMPLER2D
    }

    private static void primitive_to_string(StringBuilder str, OpenGLShaderPrimitiveType type)
    {
        if (type == OpenGLShaderPrimitiveType.CUSTOM)
            return;

        string s;
        if (type == OpenGLShaderPrimitiveType.SAMPLER2D)
            s = "sampler2D";
        else
        {
            s = type.to_string();
            s = s.substring(37, s.length - 37).down();
        }

        str.append(s);
        str.append(" ");
    }

    public enum OpenGLShaderPropertyDirection
    {
        NONE,
        IN,
        OUT
    }

    private static void direction_to_string(StringBuilder str, OpenGLShaderPropertyDirection type)
    {
        if (type == OpenGLShaderPropertyDirection.NONE)
            return;

        string s = type.to_string();

        str.append(s.substring(41, s.length - 41).down());
        str.append(" ");
    }

    public abstract class OpenGLShaderUnit
    {
        public void add_dependency(OpenGLShaderUnit dependency)
        {
            if (dependencies == null)
                dependencies = {dependency};
            else
            {
                OpenGLShaderUnit[] deps = new OpenGLShaderUnit[dependencies.length + 1];
                for (int i = 0; i < dependencies.length; i++)
                    deps[i] = dependencies[i];
                deps[deps.length - 1] = dependency;

                dependencies = deps;
            }
        }

        public abstract void to_string(StringBuilder str);
        public OpenGLShaderUnit[]? dependencies { get; set; }
    }

    public class OpenGLShaderDefine : OpenGLShaderUnit
    {
        public OpenGLShaderDefine(string name, string value)
        {
            this.name = name;
            this.value = value;
        }

        public override void to_string(StringBuilder str)
        {
            str.append("#define ");
            str.append(name);
            str.append(" ");
            str.append(value);
            str.append("\n");
        }

        public string name { get; set; }
        public string value { get; set; }
    }

    public class OpenGLShaderAttribute : OpenGLShaderProperty
    {
        public OpenGLShaderAttribute(string name, OpenGLShaderPrimitiveType primitive)
        {
            base(name, primitive);
        }

        public override void to_string(StringBuilder str)
        {
            str.append("attribute ");
            base.to_string(str);
            str.append(";\n");
        }
    }

    public class OpenGLShaderVarying : OpenGLShaderProperty
    {
        public OpenGLShaderVarying(string name, OpenGLShaderPrimitiveType primitive)
        {
            base(name, primitive);
        }

        public override void to_string(StringBuilder str)
        {
            str.append("varying ");
            base.to_string(str);
            str.append(";\n");
        }
    }

    public class OpenGLShaderUniform : OpenGLShaderProperty
    {
        public OpenGLShaderUniform(string name, OpenGLShaderPrimitiveType primitive)
        {
            base(name, primitive);
        }

        public override void to_string(StringBuilder str)
        {
            str.append("uniform ");
            base.to_string(str);
            str.append(";\n");
        }
    }

    public class OpenGLShaderProperty : OpenGLShaderUnit
    {
        public OpenGLShaderProperty(string name, OpenGLShaderPrimitiveType primitive)
        {
            this.name = name;
            this.primitive = primitive;
            direction = OpenGLShaderPropertyDirection.NONE;
        }

        public override void to_string(StringBuilder str)
        {
            if (direction != OpenGLShaderPropertyDirection.NONE)
                direction_to_string(str, direction);

            if (custom_type != null)
            {
                str.append(custom_type);
                str.append(" ");
            }
            else
                primitive_to_string(str, primitive);

            str.append(name);

            if (array != null)
            {
                str.append("[");
                str.append(array);
                str.append("]");
            }
        }

        public string name { get; set; }
        public OpenGLShaderPrimitiveType primitive { get; set; }
        public string? custom_type { get; set; }
        public string? array { get; set; }
        public OpenGLShaderPropertyDirection direction { get; set; }
    }

    public class OpenGLShaderStruct : OpenGLShaderUnit
    {
        public OpenGLShaderStruct(string name, OpenGLShaderProperty[] properties)
        {
            this.name = name;
            this.properties = properties;
        }

        public override void to_string(StringBuilder str)
        {
            str.append("struct ");
            str.append(name);
            str.append("\n{\n");

            if (properties != null)
            {
                foreach (var property in properties)
                {
                    str.append("\t");
                    property.to_string(str);
                    str.append(";\n");
                }
            }

            str.append("\n};\n");
        }

        public string name { get; set; }
        public OpenGLShaderProperty[] properties { get; set; }
    }

    public class OpenGLShaderCodeBlock : OpenGLShaderUnit
    {
        public OpenGLShaderCodeBlock(string code)
        {
            this.code = code;
        }

        public override void to_string(StringBuilder str)
        {
            str.append(code);
        }

        public string code { get; set; }
    }

    public class OpenGLShaderFunction : OpenGLShaderUnit
    {
        private OpenGLShaderCodeDependencyTree tree = new OpenGLShaderCodeDependencyTree();

        public OpenGLShaderFunction(string name, OpenGLShaderPrimitiveType return_type)
        {
            this.name = name;
            this.return_type = return_type;
        }

        public override void to_string(StringBuilder str)
        {
            primitive_to_string(str, return_type);
            str.append(name);
            str.append("(");

            if (parameters != null)
            {
                bool first = true;
                foreach (var parameter in parameters)
                {
                    if (!first)
                        str.append(", ");
                    first = false;

                    parameter.to_string(str);
                }
            }

            str.append(")\n{\n");

            foreach (var code in tree.get_list())
                code.to_string(str);

            str.append("}\n");
        }

        public void add_code(OpenGLShaderCodeBlock code)
        {
            tree.add(code);
            add_dependency(code);
        }

        public void add_codes(OpenGLShaderCodeBlock[] codes)
        {
            foreach (OpenGLShaderCodeBlock code in codes)
                add_code(code);
        }

        public void add_codes_list(ArrayList<OpenGLShaderCodeBlock> codes)
        {
            foreach (OpenGLShaderCodeBlock code in codes)
                add_code(code);
        }

        public string name { get; set; }
        public OpenGLShaderPrimitiveType return_type { get; set; }
        public OpenGLShaderProperty[]? parameters { get; set; }
    }

    protected class OpenGLShaderCodeDependencyTree
    {
        private ArrayList<Node> nodes = new ArrayList<Node>();

        public void add(OpenGLShaderCodeBlock code)
        {
            add_code(code);
        }

        private Node add_code(OpenGLShaderCodeBlock code)
        {
            foreach (Node n in nodes)
                if (n.code == code)
                    return n;
            
            Node n = new Node(code);
            nodes.add(n);

            if (code.dependencies != null)
                foreach (var dep in code.dependencies)
                {
                    if (!(dep is OpenGLShaderCodeBlock))
                        continue;

                    Node parent = add_code(dep as OpenGLShaderCodeBlock);
                    parent.children.add(n);
                    n.parents.add(parent);
                }

            return n;
        }

        public ArrayList<OpenGLShaderCodeBlock> get_list()
        {
            foreach (Node node in nodes)
                node.added = false;
            
            ArrayList<OpenGLShaderCodeBlock> codes = new ArrayList<OpenGLShaderCodeBlock>();
            while (nodes.size != 0)
            {
                for (int i = 0; i < nodes.size; i++)
                {
                    if (nodes[i].added)
                    {
                        nodes.remove_at(i);
                        break;
                    }
                    
                    if (nodes[i].children.size == 0)
                    {
                        iterate(nodes[i], codes);
                        nodes.remove_at(i);
                        break;
                    }
                }
            }

            return codes;
        }

        private static void iterate(Node node, ArrayList<OpenGLShaderCodeBlock> codes)
        {
            while (node.parents.size != 0)
                iterate(node.parents[0], codes);
            codes.add(node.code);
            node.added = true;

            foreach (Node n in node.children)
                n.parents.remove(node);
            node.children.clear();
        }

        class Node
        {
            public Node(OpenGLShaderCodeBlock code)
            {
                this.code = code;
            }

            public bool added { get; set; }
            public OpenGLShaderCodeBlock code { get; private set; }
            public ArrayList<Node> parents = new ArrayList<Node>();
            public ArrayList<Node> children = new ArrayList<Node>();
        }
    }

    protected class OpenGLShaderDependencyTree
    {
        private ArrayList<Node> nodes = new ArrayList<Node>();

        public void add(OpenGLShaderUnit unit)
        {
            add_unit(unit);
        }

        private Node add_unit(OpenGLShaderUnit unit)
        {
            foreach (Node n in nodes)
                if (n.unit == unit)
                    return n;
            
            Node n = new Node(unit);
            nodes.add(n);

            if (unit.dependencies != null)
                foreach (var dep in unit.dependencies)
                {
                    Node parent = add_unit(dep);
                    parent.children.add(n);
                    n.parents.add(parent);
                }

            return n;
        }

        public ArrayList<OpenGLShaderUnit> get_list()
        {
            foreach (Node node in nodes)
                node.added = false;
            
            ArrayList<OpenGLShaderUnit> units = new ArrayList<OpenGLShaderUnit>();
            while (nodes.size != 0)
            {
                for (int i = 0; i < nodes.size; i++)
                {
                    if (nodes[i].added)
                    {
                        nodes.remove_at(i);
                        break;
                    }
                    
                    if (nodes[i].children.size == 0)
                    {
                        iterate(nodes[i], units);
                        nodes.remove_at(i);
                        break;
                    }
                }
            }

            return units;
        }

        private static void iterate(Node node, ArrayList<OpenGLShaderUnit> units)
        {
            while (node.parents.size != 0)
                iterate(node.parents[0], units);
            units.add(node.unit);
            node.added = true;

            foreach (Node n in node.children)
                n.parents.remove(node);
            node.children.clear();
        }

        class Node
        {
            public Node(OpenGLShaderUnit unit)
            {
                this.unit = unit;
            }

            public bool added { get; set; }
            public OpenGLShaderUnit unit { get; private set; }
            public ArrayList<Node> parents = new ArrayList<Node>();
            public ArrayList<Node> children = new ArrayList<Node>();
        }
    }

    public abstract class OpenGLShaderBuilder
    {
        protected const int VERSION = 100;

        protected OpenGLShaderBuilder()
        {
            uniforms = new ArrayList<OpenGLShaderUniform>();
        }

        protected OpenGLShaderDependencyTree vertex_tree = new OpenGLShaderDependencyTree();
        protected OpenGLShaderDependencyTree fragment_tree = new OpenGLShaderDependencyTree();
        protected OpenGLShaderFunction vertex_main = new OpenGLShaderFunction("main", OpenGLShaderPrimitiveType.VOID);
        protected OpenGLShaderFunction fragment_main = new OpenGLShaderFunction("main", OpenGLShaderPrimitiveType.VOID);

        private void add_uniforms(OpenGLShaderUnit unit)
        {
            if (unit is OpenGLShaderUniform && !uniforms.contains(unit as OpenGLShaderUniform))
                uniforms.add(unit as OpenGLShaderUniform);

            foreach (OpenGLShaderUnit u in unit.dependencies)
                add_uniforms(u);
        }

        protected void add_vertex_block(OpenGLShaderCodeBlock block)
        {
            vertex_tree.add(block);
            vertex_main.add_code(block);

            add_uniforms(block);
        }

        protected void add_fragment_block(OpenGLShaderCodeBlock block)
        {
            fragment_tree.add(block);
            fragment_main.add_code(block);
            
            add_uniforms(block);
        }

        private static string write_shader
        (
            int version,
            OpenGLShaderDependencyTree tree,
            OpenGLShaderFunction main
        )
        {
            tree.add(main);

            StringBuilder str = new StringBuilder();
            str.append("#version ");
            str.append(version.to_string());
            str.append("\n");
            str.append("precision mediump float;\n");

            foreach (var unit in tree.get_list())
                if (!(unit is OpenGLShaderCodeBlock))
                    unit.to_string(str);

            return str.str;
        }

        public string create_vertex_shader()
        {
            add_uniforms(vertex_main);
            return write_shader(VERSION, vertex_tree, vertex_main);
        }

        public string create_fragment_shader()
        {
            add_uniforms(fragment_main);
            return write_shader(VERSION, fragment_tree, fragment_main);
        }

        public ArrayList<OpenGLShaderUniform> uniforms { get; private set; }
    }
}