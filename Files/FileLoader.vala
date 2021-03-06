using Gee;

namespace Engine
{
    public class FileLoader
    {
        private const int MAX_SIZE = 10 * 1024 * 1024; // 10 MiB

        private static ArrayList<string>? search_paths;

        private FileLoader() {}

        public static void init()
        {
            if (search_paths == null)
                search_paths = new ArrayList<string>();
        }

        public static string? find_file(string? name)
        {
            if (name == null)
                return null;

            if (File.new_for_path(name).query_exists())
                return name;
            
            foreach (string path in search_paths)
            {
                string p = GLib.Path.build_filename(path, name);
                if (File.new_for_path(p).query_exists())
                    return p;
            }

            return null;
        }

        public static string? find_directory(string? name)
        {
            if (name == null)
                return null;

            foreach (string path in search_paths)
            {
                string p = GLib.Path.build_filename(path, name);
                if (GLib.FileUtils.test(p, GLib.FileTest.IS_DIR))
                    return p;
            }

            return null;
        }

        public static void add_search_path(string? path)
        {
            if (path == null || path.strip().length == 0 || search_paths.contains(path))
                return;
            
            search_paths.add(path);
            EngineLog.log(EngineLogType.DEBUG, "FileLoader.add_search_path", "Adding path: " + path);
        }

        public static string[]? load(string name)
        {
            string? path = find_file(name);
            if (path == null)
            {
                EngineLog.log(EngineLogType.DEBUG, "FileLoader.load", "File does not exist: " + name);
                return null;
            }

            var file = File.new_for_path(path);

            ArrayList<string> lines = new ArrayList<string>();

            try
            {
                var dis = new DataInputStream(file.read());
                string line;
                while ((line = dis.read_line (null)) != null)
                    lines.add(line.replace("\r", "")); // Remove windows line ending part
            }
            catch {}

            string[] l = new string[lines.size];
            for (int i = 0; i < lines.size; i++)
                l[i] = lines[i];

            return l;
        }

        public static uint8[]? load_data(string name)
        {
            string? path = find_file(name);
            if (path == null)
            {
                EngineLog.log(EngineLogType.DEBUG, "FileLoader.load", "File does not exist: " + name);
                return null;
            }

            var file = File.new_for_path(path);

            try
            {
                int64 size = file.query_info(FileAttribute.STANDARD_SIZE, 0).get_size();
                if (size == 0)
                    return new uint8[0];
                FileInputStream fis = file.read();
                uint8[] data = new uint8[size];
                fis.read(data);

                return data;
            }
            catch
            {
                EngineLog.log(EngineLogType.ERROR, "FileLoader.load_data", "Error loading data for: " + name);
            }

            return null;
        }

        public static FileWriter? open(string name)
        {
            try
            {
                var file = File.new_for_path(name);

                if (file.query_exists())
                    file.delete();
                else
                {
                    try
                    {
                        file.get_parent().make_directory_with_parents();
                    }
                    catch {} // Directory might already exist
                }

                FileOutputStream stream = file.create(FileCreateFlags.REPLACE_DESTINATION);

                return new FileWriter(stream);
            }
            catch
            {
                EngineLog.log(EngineLogType.DEBUG, "FileLoader.open", "Error opening file: " + name);
                return null;
            }
        }

        public static bool save(string name, string[] lines)
        {
            FileWriter? writer = open(name);
            if (writer == null)
                return false;

            foreach (string line in lines)
                writer.write_line(line);

            return true;
        }

        public static bool exists(string? name)
        {
            return name != null && name.length != 0 && name != "." && find_file(name) != null;
        }

        public static string[] split_string(string str, bool retain_newline = false)
        {
            string[] ret = str.split("\n");

            for (int i = 0; i < ret.length; i++)
            {
                string s = ret[i];
                if (s.length > 0 && s[s.length - 1] == '\r')
                    s = s.substring(0, s.length - 1);
                if (retain_newline)
                    s += "\n";
                ret[i] = s;
            }

            return ret;
        }

        public static string[] get_files_in_dir(string? name)
        {
            if (name == null)
                return new string[0];

            ArrayList<string> files = new ArrayList<string>();

            try
            {
                FileEnumerator enumerator = File.new_for_path(name).enumerate_children
                (
                    "standard::*",
                    FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                    null
                );

                FileInfo info = null;
                while ((info = enumerator.next_file(null)) != null)
                {
                    if (info.get_file_type() == FileType.REGULAR)
                        files.add(info.get_name());
                }
            }
            catch
            {
                EngineLog.log(EngineLogType.DEBUG, "FileLoader.get_files_in_dir", "Could not get files in: " + name);
            }

            return files.to_array();
        }

        public static string array_to_string(string[] lines)
        {
            return string.joinv("\n", lines);
        }

        public static uint8[]? compress(uint8[]? data)
        {
            return compress_work(data, true);
        }

        public static uint8[]? uncompress(uint8[]? data)
        {
            return compress_work(data, false);
        }

        private static uint8[]? compress_work(uint8[] data, bool compress)
        {
            if (data == null)
                return null;

            int size = 1;
            while (true)
            {
                if (data.length * size > MAX_SIZE) // Prevent compression bomb
                    return null;

                size *= 2;

                uint8[] dest = new uint8[data.length * size];
                ulong dest_len = dest.length;
                int ret;
                if (compress)
                    ret = ZLib.Utility.  compress(dest, ref dest_len, data);
                else
                    ret = ZLib.Utility.uncompress(dest, ref dest_len, data);

                if (ret == ZLib.Status.OK)
                {
                    uint8[] output = new uint8[dest_len];
                    for (int i = 0; i < dest_len; i++)
                        output[i] = dest[i];
                    return output;
                }
                else if (ret != ZLib.Status.BUF_ERROR)
                    return null;
            }
        }
    }

    public class FileWriter
    {
        private FileOutputStream stream;

        public FileWriter(FileOutputStream stream)
        {
            this.stream = stream;
        }

        ~FileWriter()
        {
            close();
        }

        public bool write_data(uint8[] data)
        {
            try
            {
                stream.write(data);
            }
            catch
            {
                return false;
            }

            return true;
        }

        public bool write_line(string line)
        {
            return write(line + "\n");
        }

        public bool write(string text)
        {
            return write_data(text.data);
        }

        public void close()
        {
            try
            {
                stream.flush();
                stream.close();
            }
            catch {}
        }
    }
}