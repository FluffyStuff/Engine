using Gee;

namespace Engine
{
    public class DebugInfo
    {
        public DebugInfo()
        {
            this.strings = new ArrayList<string>();
        }

        public void add_string(string str)
        {
            strings.add(str);
        }

        public void add_strings(string[] strings)
        {
            foreach (string s in strings)
                add_string(s);
        }

        public ArrayList<string> strings { get; private set; }
    }
}