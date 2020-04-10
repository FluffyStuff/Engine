namespace Engine
{
    public class Helper
    {
        private Helper() {}

        public static string sanitize_string(string input)
        {
            return input.replace("\r", "").replace("\n", "").replace("\t", "").replace("\0", "");
        }
    }
}