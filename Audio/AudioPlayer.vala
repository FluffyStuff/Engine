using Gee;
using SDLMixer;

namespace Engine
{
    public class AudioPlayer
    {
        public AudioPlayer()
        {
            // SDLMixer open/close have their own internal refcount
            if (SDLMixer.open(44100, SDLMixer.DEFAULT_FORMAT, 6, 128) == -1)
            {
                EngineLog.log(EngineLogType.ERROR, "AudioPlayer", "Could not init SDLMixer");
            }
        }

        ~AudioPlayer()
        {
            sounds = null; // Need to close sounds before we close the mixer
            SDLMixer.close();
        }

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
        SDLMixer.Chunk? chunk;
        SDLMixer.Channel channel = SDLMixer.DEFAULT_CHANNEL;

        ~Sound()
        {
            stop();
        }

        public Sound(string name)
        {
            this.name = name;
            
            chunk = new SDLMixer.Chunk.WAV(name);
            if (chunk == null)
                EngineLog.log(EngineLogType.ERROR, "AudioPlayer.Sound", "Could not create chunk for: " + name);
        }

        public void play(bool loop = false)
        {
            if (chunk == null)
                return;
            
            if (!muted)
            {
                if (loop && channel != SDLMixer.DEFAULT_CHANNEL)
                    return;
                
                // Provide new channel rather than reusing the current one (otherwise we will get choppy sounds)
                channel = SDLMixer.DEFAULT_CHANNEL.play(chunk, loop ? -1 : 0);
                if (channel == SDLMixer.DEFAULT_CHANNEL)
                    EngineLog.log(EngineLogType.ERROR, "AudioPlayer.Sound.play", "Could not play chunk for: " + name);
            }
        }

        public void stop()
        {
            if (channel != SDLMixer.DEFAULT_CHANNEL)
                channel.halt();
            channel = SDLMixer.DEFAULT_CHANNEL;
        }

        public string name { get; private set; }
        public bool muted { get; set; }
    }

    public class Music : Object
    {
        public signal void music_finished(Music music);

        private SDLMixer.Music music;
        private bool stopped = false;

        public Music(string name)
        {
            stop();
            music = new SDLMixer.Music(name);
        }

        ~Music()
        {
            stop();
        }

        public void play()
        {
            stopped = false;
            ref();
            Threading.start0(worker);
        }

        public void stop()
        {
            stopped = true;
            SDLMixer.Music.halt();
        }

        // TODO: Can we do callbacks without a new thread?
        private void worker()
        {
            music.play(0);

            while (SDLMixer.Music.is_playing())
                Thread.usleep(1000 * 1000);

            if (!stopped)
                music_finished(this);
            unref();
        }
    }
}