using Gee;

public class FileLoader
{
    private FileLoader() {}

    public static string[]? load(string name)
    {
        var file = File.new_for_path(name);

        if (!file.query_exists())
            return null;

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

            FileOutputStream stream = file.create (FileCreateFlags.REPLACE_DESTINATION);

            return new FileWriter(stream);
        }
        catch
        {
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

    public static bool exists(string name)
    {
        return File.new_for_path(name).query_exists();
    }

    public static string[] get_files_in_dir(string name)
    {
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
        catch {}

        return files.to_array();
    }

    public static string array_to_string(string[] lines)
    {
        return string.joinv("\n", lines);
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

    public bool write(string text)
    {
        try
        {
            stream.write(text.data);
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

    public void close()
    {
        try
        {
            stream.close();
        }
        catch {}
    }
}
