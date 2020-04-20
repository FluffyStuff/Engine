using Gee;
using SFML.Audio;

namespace Engine
{
    public class AudioPlayer
    {
        private ArrayList<Sound> sounds = new ArrayList<Sound>();
        private Mutex mutex = Mutex();
        private bool _muted = false;

        public Sound load_sound(string name)
        {
            mutex.lock();

            string n = FileLoader.find_file(GLib.Path.build_filename("Data", "Audio", "Sounds", name + ".wav"));

            foreach (Sound sound in sounds)
                if (sound.name == n)
                {
                    mutex.unlock();
                    return sound;
                }

            Sound sound = new Sound(n);
            sound.muted = muted;
            sounds.add(sound);

            mutex.unlock();

            return sound;
        }

        public Music load_music(string name)
        {
            return new Music(FileLoader.find_file(GLib.Path.build_filename("Data", "Audio", "Music", name)));
        }

        public bool muted
        {
            get
            {
                return _muted;
            }
            set
            {
                _muted = value;

                mutex.lock();
                foreach (Sound sound in sounds)
                    sound.muted = value;
                mutex.unlock();
            }
        }
    }

    public class Sound
    {
        private SFML.Audio.Sound sound;
        private SoundBuffer buffer;

        ~Sound()
        {
            stop();
            sound = null;
            buffer = null;
        }

        public Sound(string name)
        {
            this.name = name;

            buffer = new SoundBuffer(name);
            sound = new SFML.Audio.Sound();
            sound.set_buffer(buffer);
        }

        public void play(bool loop = false)
        {
            sound.set_loop(loop);
            if (!muted)
                sound.play();
        }

        public void stop()
        {
            sound.stop();
        }

        public string name { get; private set; }
        public bool muted { get; set; }
    }

    public class Music : Object
    {
        public signal void music_finished(Music music);

        private SFML.Audio.Music music;
        private bool stopped = false;

        public Music(string name)
        {
            music = new SFML.Audio.Music(name);
        }

        ~Music()
        {
            stop();
            music = null;
        }

        public void play()
        {
            ref();
            Threading.start0(worker);
        }

        public void stop()
        {
            music.stop();
            stopped = true;
        }

        private void worker()
        {
            music.play();
            Thread.usleep((ulong)music.get_duration().microseconds);

            if (!stopped)
                music_finished(this);
            unref();
        }
    }
}