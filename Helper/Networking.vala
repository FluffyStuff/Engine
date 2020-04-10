using Gee;

// Out of namespace due to vala compiler error
public errordomain DataLengthError { OUT_OF_RANGE, NEGATIVE_LENGTH }

namespace Engine
{
    // Asynchronous networking class
    public class Networking : Object
    {
        public signal void connected(Connection connection);
        public signal void message_received(Connection connection, Message message);

        private SocketListener server;
        private bool listening = false;
        private Cancellable server_cancel;

        private ArrayList<Connection> connections;
        private Mutex mutex;

        public Networking()
        {
            connections = new ArrayList<Connection>();
            mutex = Mutex();
        }

        ~Networking()
        {
            close();
        }

        public void close()
        {
            mutex.lock();

            if (listening)
            {
                listening = false;
                server_cancel.cancel();
            }

            // Need to explicitly cancel all connections, or we will leak memory (have zombie threads)
            while (connections.size > 0)
            {
                Connection c = connections[0];
                remove_connection(c);
                c.close();
            }

            mutex.unlock();
        }

        public void stop_listening()
        {
            mutex.lock();

            if (listening)
            {
                listening = false;
                server_cancel.cancel();
            }

            mutex.unlock();
        }

        private void message_received_handler(Connection connection, Message message)
        {
            message_received(connection, message);
        }

        private void remove_connection(Connection connection)
        {
            connection.message_received.disconnect(message_received_handler);
            connection.closed.disconnect(connection_closed);
            connections.remove(connection);
        }

        private void connection_closed(Connection connection)
        {
            mutex.lock();

            remove_connection(connection);

            mutex.unlock();
        }

        private void add_connection(SocketConnection connection)
        {
            mutex.lock();

            Connection c = new Connection(connection);
            connections.add(c);
            c.message_received.connect(message_received_handler);
            c.closed.connect(connection_closed);

            mutex.unlock();

            connected(c);
            c.start();
        }

        private void host_worker()
        {
            try
            {
                while (true)
                {
                    SocketConnection? connection = server.accept(null, server_cancel);

                    mutex.lock();
                    if (!listening)
                    {
                        mutex.unlock();
                        break;
                    }
                    mutex.unlock();

                    add_connection(connection);
                }
            }
            catch { }

            server.close();
            listening = false;
            unref();
        }

        public bool host(uint16 port)
        {
            if (listening)
                return false;

            try
            {
                server_cancel = new Cancellable();
                server = new SocketListener();
                server.add_inet_port(port, null);
                listening = true;

                Threading.start0(host_worker);
            }
            catch
            {
                return false;
            }

            ref();
            return true;
        }

        public static Connection? join(string addr, uint16 port)
        {
            try
            {
                Resolver resolver = Resolver.get_default();
                GLib.List<InetAddress> addresses = resolver.lookup_by_name(addr, null);
                InetAddress address = addresses.nth_data(0);

                var socket_address = new InetSocketAddress(address, port);
                var client = new SocketClient();
                var conn = client.connect(socket_address);

                Connection connection = new Connection(conn);
                connection.start();

                return connection;
            }
            catch
            {
                return null;
            }
        }

        public static uint8[] int_to_data(uint32 n)
        {
            // Don't do this, so we maintain consistency over network
            //int bytes = (int)sizeof(int);
            int bytes = 4;

            uint8[] buffer = new uint8[bytes];
            for (int i = 0; i < bytes; i++)
                buffer[i] = (uint8)(n >> ((bytes - i - 1) * 8));
            return buffer;
        }

        public static uint8[] float_to_data(float f)
        {
            int bytes = 4;

            uint8[] buffer = new uint8[bytes];
            uint8 *p = (uint8*)(&f);
            for (int i = 0; i < bytes; i++)
                buffer[i] = p[i];

            return buffer;
        }
    }

    public class MessageSignal
    {
        public signal void message(Connection connection, Message message);
    }

    public class Connection : Object
    {
        private const uint32 MAX_MESSAGE_LEN = 10 * 1024 * 1024; // 10 MiB

        public signal void message_received(Connection connection, Message message);
        public signal void closed(Connection connection);

        private SocketConnection connection;
        private bool run = true;
        private Cancellable cancel = new Cancellable();
        private Mutex mutex = Mutex();

        public Connection(SocketConnection connection)
        {
            this.connection = connection;
        }

        ~Connection()
        {
            close();
        }

        public void send(Message message)
        {
            try
            {
                uint8[] data = message.get_message();
                connection.output_stream.write(Networking.int_to_data(data.length));
                connection.output_stream.write(data);
            }
            catch { } // Won't close here, because the thread will do it for us
        }

        public void start()
        {
            ref();
            Threading.start0(reading_worker);
        }

        public void close()
        {
            mutex.lock();
            try
            {
                run = false;
                cancel.cancel();
                connection.close();
            }
            catch {}
            mutex.unlock();
        }

        private void reading_worker()
        {
            connection.socket.set_blocking(false);
            var input = new DataInputStream(connection.input_stream);

            try
            {
                while (true)
                {
                    mutex.lock();
                    if (!run)
                    {
                        mutex.unlock();
                        break;
                    }
                    mutex.unlock();

                    uint32 length = input.read_uint32();
                    if (length > MAX_MESSAGE_LEN)
                    {
                        EngineLog.log(EngineLogType.NETWORK, "Networking", "Message length exceeds maximum, dropping connection");
                        break;
                    }

                    uint8[] buffer = new uint8[length];
                    size_t read;

                    if (!connection.input_stream.read_all(buffer, out read, cancel) || buffer == null)
                        break;

                    message_received(this, new Message(buffer));
                }
            }
            catch {}

            try
            {
                connection.close();
            }
            catch {}

            closed(this);

            unref();
        }
    }

    public class Message : Object
    {
        private uint8[] data;

        protected Message.empty() {}

        public Message(uint8[] data)
        {
            this.data = data;
        }

        public uint8[] get_message()
        {
            return data;
        }
    }

    class UIntData
    {
        private ArrayList<UInt> data = new ArrayList<UInt>();
        private int length = 0;

        public void add_data(uint8[] data)
        {
            this.data.add(new UInt(data));
            length += data.length;
        }

        public void add_int(int i)
        {
            add_data(serialize_int(i));
        }

        public void add_float(float f)
        {
            add_data(serialize_float(f));
        }

        public void add_bool(bool b)
        {
            add_byte((uint8)b);
        }

        public void add_byte(uint8 b)
        {
            add_data(serialize_byte(b));
        }

        public void add_string(string s)
        {
            uint8[] str_data = serialize_string(s);
            add_int(str_data.length);
            add_data(str_data);
        }

        public uint8[] get_data()
        {
            uint8[] ret = new uint8[length];

            int a = 0;
            for (int i = 0; i < data.size; i++)
            {
                UInt u = data[i];
                uint8[] d = u.data; // Can't inline due to bug in vala

                for (int j = 0; j < d.length; j++)
                    ret[a++] = d[j];
            }

            return ret;
        }

        public static uint8[] serialize_string(string str)
        {
            return str.data;
        }

        public static uint8[] serialize_byte(uint8 b)
        {
            return new uint8[]{b};
        }

        public static uint8[] serialize_int(int i)
        {
            return Networking.int_to_data(i);
        }

        public static uint8[] serialize_float(float f)
        {
            return Networking.float_to_data(f);
        }

        private class UInt
        {
            public UInt(uint8[] data) { this.data = data; }
            public uint8[] data;
        }
    }

    public class DataUInt
    {
        // (int)sizeof(int); Don't do this, so we maintain consistency over network
        private const int INT_LENGTH = 4;
        private const int FLOAT_LENGTH = 4;
        private const int MAX_STRING_LENGTH = 1024 * 1024;

        private uint8[] data;
        private int index = 0;

        public DataUInt(uint8[] data)
        {
            this.data = data;
        }

        public uint8 get_byte() throws DataLengthError
        {
            if (index >= data.length)
                throw new DataLengthError.OUT_OF_RANGE("DataUInt: get_byte doesn't have enough bytes left");

            return data[index++];
        }

        public int get_int() throws DataLengthError
        {
            if (index + INT_LENGTH > data.length)
                throw new DataLengthError.OUT_OF_RANGE("DataUInt: get_int doesn't have enough bytes left");

            int ret = 0;
            for (int i = 0; i < INT_LENGTH; i++)
                ret += (int)data[index++] << ((INT_LENGTH - i - 1) * 8);

            return ret;
        }

        public float get_float() throws DataLengthError
        {
            if (index + FLOAT_LENGTH > data.length)
                throw new DataLengthError.OUT_OF_RANGE("DataUInt: get_float doesn't have enough bytes left");

            float *f = &data[index];
            index += FLOAT_LENGTH;

            return *f;
        }

        public bool get_bool() throws DataLengthError
        {
            return get_byte() != 0;
        }

        public string get_string() throws DataLengthError
        {
            return get_string_length(get_int());
        }

        public string get_string_length(int length) throws DataLengthError
        {
            if (index + length > data.length)
                throw new DataLengthError.OUT_OF_RANGE("DataUInt: get_string doesn't have enough bytes left");
            else if (length < 0)
                throw new DataLengthError.NEGATIVE_LENGTH("DataUInt: get_string length is negative");
            else if (length > MAX_STRING_LENGTH)
                throw new DataLengthError.NEGATIVE_LENGTH("DataUInt: get_string length exceeds maximum");

            uint8[] str = new uint8[length + 1];
            str[length] = 0;
            for (int i = 0; i < length; i++)
                str[i] = data[index++];
            string ret = (string)str;

            return ret;
        }

        public uint8[] get_data(int length) throws DataLengthError
        {
            if (index + length > data.length)
                throw new DataLengthError.OUT_OF_RANGE("DataUInt: get_data doesn't have enough bytes left");
            else if (length < 0)
                throw new DataLengthError.NEGATIVE_LENGTH("DataUInt: get_data length is negative");

            uint8[] new_data = new uint8[length];
            for (int i = 0; i < length; i++)
                new_data[i] = data[index++];

            return new_data;
        }
    }

    public abstract class Serializable : Object
    {
        private const uint8 NULL_BYTE = 0xAA;
        private const uint8 NON_NULL_BYTE = 0x55;
        private const int MAX_PARAMS = 128;
        private const int MAX_LIST_LENGTH = 128 * 1024;

        private static string to_string_tabs(int count)
        {
            string text = "";
            for (int i = 0; i < count; i++)
                text += "\t";
            return text;
        }

        public string to_string()
        {
            return get_type().name() + " " + to_string_rec(0);
        }

        protected virtual string to_string_rec(int level)
        {
            var obj = this;

            if (obj is SerializableList)
            {
                Serializable[] objs = (Serializable[])((SerializableList)obj).to_array();

                if (objs.length == 0)
                    return "[0]";
                
                string text = "[" + objs.length.to_string() + "]\n" + to_string_tabs(level) + "[";

                for (int i = 0; i < objs.length; i++)
                {
                    var o = objs[i];
                    text += "\n" + to_string_tabs(level + 1) + "[" + i.to_string() + "] = " + o.get_type().name() + o.to_string_rec(level + 1);
                }
                
                return text + "\n" + to_string_tabs(level) + "]";
            }

            string text = "";
            var specs = get_params(obj.get_type());

            if (specs.length == 0)
                return text + "{}";

            text += "\n" + to_string_tabs(level) + "{";

            for (int i = 0; i < specs.length; i++)
            {
                ParamSpec p = specs[i];

                text += "\n" + to_string_tabs(level + 1);
                string name = p.get_name();

                if (p.value_type == typeof(int) || p.value_type.is_enum())
                {
                    Value val = Value(typeof(int));
                    obj.get_property(p.get_name(), ref val);
                    int v = val.get_int();
                    text += "int " + name + " = " + v.to_string();
                }
                else if (p.value_type == typeof(float))
                {
                    Value val = Value(typeof(float));
                    obj.get_property(p.get_name(), ref val);
                    float v = val.get_float();
                    text += "float " + name + " = " + v.to_string();
                }
                else if (p.value_type == typeof(bool))
                {
                    Value val = Value(typeof(bool));
                    obj.get_property(p.get_name(), ref val);
                    bool b = val.get_boolean();
                    text += "bool " + name + " = " + (b ? "true" : "false");
                }
                else if (p.value_type == typeof(string))
                {
                    Value val = Value(typeof(string));
                    obj.get_property(p.get_name(), ref val);
                    string? str = val.get_string();
                    text += "string " + name + " = \"" + str + "\"";
                }
                else if (p.value_type.is_a(typeof(Serializable)))
                {
                    Value val = Value(typeof(Serializable));
                    obj.get_property(p.get_name(), ref val);
                    Serializable? o = (Serializable?)val.get_object();

                    text += o.get_type().name() + " " + name + " = " + o.to_string_rec(level + 1);
                }
            }

            return text + "\n" + to_string_tabs(level) + "}";
        }

        public static Serializable? deserialize_string(string str)
        {
            return deserialize(str.data);
        }

        private static Serializable? get_object(DeserializationContext context) throws DataLengthError
        {
            if (context.get_byte() != NON_NULL_BYTE)
                return null;

            string? type_name = context.get_string();
            Type? type = Type.from_name(type_name);

            if (type_name != null && type_name != "" && type_name != type.name())
            {
                EngineLog.log(EngineLogType.NETWORK, "Serializable", "Type (" + type_name + ") has not been class initialized");
                return null;
            }

            if (!type.is_a(typeof(Serializable)))
            {
                EngineLog.log(EngineLogType.NETWORK, "Serializable", "Not serializable type (" + type.name() + ")");
                return null;
            }

            if (type.is_a(typeof(SerializableList)))
            {
                int item_count = context.get_int();
                if (item_count > MAX_LIST_LENGTH)
                {
                    EngineLog.log(EngineLogType.NETWORK, "Serializable", "List length exceeds maximum, dropping message");
                    return null;
                }

                if (item_count < 0)
                {
                    EngineLog.log(EngineLogType.NETWORK, "Serializable", "List length is negative, dropping message");
                    return null;
                }

                Serializable[] items = new Serializable[item_count];

                for (int i = 0; i < item_count; i++)
                    items[i] = get_object(context);

                return new SerializableList<Serializable>(items);
            }

            ParamSpec[] specs = get_params(type);

            string[] names = new string[specs.length];
            Value[] values = new Value[specs.length];

            for (int i = 0; i < specs.length; i++)
            {
                ParamSpec p = specs[i];

                bool has_value = true;
                Value val = Value(typeof(int));

                if (p.value_type == typeof(int) || p.value_type.is_enum())
                    val.set_int(context.get_int());
                else if (p.value_type == typeof(float))
                {
                    val = Value(typeof(float));
                    val.set_float(context.get_float());
                }
                else if (p.value_type == typeof(bool))
                {
                    val = Value(typeof(bool));
                    val.set_boolean(context.get_bool());
                }
                else if (p.value_type == typeof(string))
                {
                    val = Value(typeof(string));
                    val.set_string(context.get_string());
                }
                else if (p.value_type.is_a(typeof(Serializable)))
                {
                    val = Value(typeof(Serializable));
                    val.set_object(get_object(context));
                }
                else
                    has_value = false;

                if (has_value)
                {
                    names[i] = p.get_name();
                    values[i] = val;
                }
                else
                    names[i] = null;
            }

            Object obj = Object.new_with_properties(type, names, values);

            return (Serializable)obj;
        }

        public static Serializable? deserialize(uint8[]? bytes_raw)
        {
            try
            {
                if (bytes_raw == null || bytes_raw.length == 0)
                    return null;

                uint8[] bytes = FileLoader.uncompress(bytes_raw);

                DataUInt data = new DataUInt(bytes);

                int count = data.get_int();
                if (count == 0)
                {
                    EngineLog.log(EngineLogType.NETWORK, "Serializable", "No root name, dropping message");
                    return null;
                }

                if (count > MAX_LIST_LENGTH)
                {
                    EngineLog.log(EngineLogType.NETWORK, "Serializable", "String table length exceeds maximum, dropping message");
                    return null;
                }

                if (count < 0)
                {
                    EngineLog.log(EngineLogType.NETWORK, "Serializable", "String table length is negative, dropping message");
                    return null;
                }

                string[] strings = new string[count];

                for (int i = 0; i < count; i++)
                    strings[i] = data.get_string();

                DeserializationContext context = new DeserializationContext(strings, data);

                return get_object(context);
            }
            catch (Error e)
            {
                EngineLog.log(EngineLogType.NETWORK, "Serializable", "Error parsing message: " + e.message);
                return null;
            }
        }

        public uint8[] serialize()
        {
            SerializationContext context = new SerializationContext();

            serialize_sub(this, context);

            return FileLoader.compress(context.serialize());
        }

        private static void serialize_sub(Serializable? obj, SerializationContext context)
        {
            context.add_byte(obj == null ? NULL_BYTE : NON_NULL_BYTE);

            if (obj == null)
                return;

            context.add_string(obj.get_type().name());

            if (obj is SerializableList)
            {
                Serializable[] objs = (Serializable[])((SerializableList)obj).to_array();

                context.add_int(objs.length);

                for (int i = 0; i < objs.length; i++)
                    serialize_sub(objs[i], context);

                return;
            }

            var specs = get_params(obj.get_type());

            for (int i = 0; i < specs.length; i++)
            {
                ParamSpec p = specs[i];

                if (p.value_type == typeof(int) || p.value_type.is_enum())
                {
                    Value val = Value(typeof(int));
                    obj.get_property(p.get_name(), ref val);
                    int v = val.get_int();

                    context.add_int(v);
                }
                else if (p.value_type == typeof(float))
                {
                    Value val = Value(typeof(float));
                    obj.get_property(p.get_name(), ref val);
                    float v = val.get_float();

                    context.add_float(v);
                }
                else if (p.value_type == typeof(bool))
                {
                    Value val = Value(typeof(bool));
                    obj.get_property(p.get_name(), ref val);
                    bool b = val.get_boolean();

                    context.add_bool(b);
                }
                else if (p.value_type == typeof(string))
                {
                    Value val = Value(typeof(string));
                    obj.get_property(p.get_name(), ref val);
                    string? str = val.get_string();

                    context.add_string(str);
                }
                else if (p.value_type.is_a(typeof(Serializable)))
                {
                    Value val = Value(typeof(Serializable));
                    obj.get_property(p.get_name(), ref val);
                    Serializable? o = (Serializable?)val.get_object();

                    serialize_sub(o, context);
                }
            }
        }

        public class SerializationContext
        {
            private UIntData data = new UIntData();
            private int string_count = 0;
            private Tree<string, ObjInt> tree = new Tree<string, ObjInt>.full((a, b) => { return strcmp (a, b); }, free, unref);

            /*public void add_data(uint8[] d)
            {
                data.add_data(d);
            }*/

            public void add_int(int i)
            {
                data.add_int(i);
            }

            public void add_float(float f)
            {
                data.add_float(f);
            }

            public void add_byte(uint8 b)
            {
                data.add_byte(b);
            }

            public void add_bool(bool b)
            {
                data.add_bool(b);
            }

            // Adds a string to the string table and serializes the index
            public void add_string(string? str)
            {
                if (str == null)
                {
                    add_int(-1);
                    return;
                }

                ObjInt? o = tree.lookup(str);

                if (o != null)
                {
                    add_int(o.value);
                    return;
                }

                int index = string_count++;
                tree.insert(str, new ObjInt(index));
                add_int(index);
            }

            public uint8[] serialize()
            {
                UIntData out_data = new UIntData();
                string[] strings = new string[string_count];
                tree.@foreach((_key, _val) =>
                {
                    unowned string key = (string) _key;
                    unowned ObjInt val = (ObjInt) _val;
                    strings[val.value] = key;
                    return false;
                });

                out_data.add_int(strings.length);

                for (int i = 0; i < strings.length; i++)
                    out_data.add_string(strings[i]);

                out_data.add_data(data.get_data());

                return out_data.get_data();
            }
        }

        class DeserializationContext
        {
            private string[] strings;
            private DataUInt data;

            public DeserializationContext(string[] strings, DataUInt data)
            {
                this.strings = strings;
                this.data = data;
            }

            public int get_int() throws DataLengthError
            {
                return data.get_int();
            }

            public bool get_bool() throws DataLengthError
            {
                return data.get_bool();
            }

            public uint8 get_byte() throws DataLengthError
            {
                return data.get_byte();
            }

            public float get_float() throws DataLengthError
            {
                return data.get_float();
            }

            public string? get_string() throws DataLengthError
            {
                int index = get_int();
                if (index == -1)
                    return null;

                if (index < 0 || index >= strings.length)
                    throw new DataLengthError.OUT_OF_RANGE("DeserializationContext: get_string index is out of range");

                return strings[index];
            }
        }

        private static ParamSpec[] get_params(Type type)
        {
            string name = type.name();
            ParamList? p = tree.lookup(name);

            if (p != null)
                return p.params;
            ObjectClass cls = (ObjectClass)type.class_ref();
            var props = cls.list_properties();
            tree.insert(name, new ParamList(props));

            return props;
        }

        private static Tree<string, ParamList> tree = new Tree<string, ParamList>((a, b) => { return strcmp (a, b); });
        private class ParamList
        {
            public ParamList(ParamSpec[] params)
            {
                this.params = params;
            }

            public ParamSpec[] params { get; private set; }
        }
    }

    public class SerializableList<T> : Serializable
    {
        public T[] items;

        public SerializableList(T[] items)
        {
            this.items = items;
        }

        public SerializableList.empty()
        {
            this.items = new T[0];
        }

        public T[] to_array()
        {
            return items;
        }
    }

    public class ObjInt : Serializable
    {
        public ObjInt(int value)
        {
            this.value = value;
        }

        public int value { get; protected set; }
    }
}