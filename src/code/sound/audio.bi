
#define audio_backend "fmod"

#define audio_error(e) Print audio_backend & " audio: " & e: Sleep(): System()

#if audio_backend = "fmod"
  #include once "fmod.bi"
  #define audio_effect_sample FSOUND_SAMPLE ptr
  #define audio_effect_nowplaying integer
  #define audio_music_sample FMUSIC_MODULE ptr
#endif

namespace audio

const true = -1, false = 0

type effect_type
  as audio_effect_sample sample
  as audio_effect_nowplaying nowplaying 'latest sound played (ie check if this is done playing, to repeat it)
  
  as integer loop_mode 'on / off
  
  'if loop mode is off, then let new sounds play every few frames (instead of just playing once at a time)
  as integer repeat_rate
  as integer repeat_stall
end type

type music_type
  as audio_music_sample sample
end type

type object
  const effect_max = 64, music_max = 32
  
  declare sub start ()
  declare sub update ()
  declare sub stopeffects ()
  declare sub finish ()
  
  declare function register_effect (byref filename as string, byval repeatrate as integer = 8, _
    byval shouldloop as integer = false) as integer
  declare function register_music (byref filename as string) as integer
  
  declare sub fire_effect (byval index as integer)
  declare sub fire_music (byval index as integer = -1)
  
  declare function set_volume_effect (byval v as integer = -1) as integer
  declare function set_volume_music (byval v as integer = -1) as integer
  
  as integer effect_total, effect_volume
  as effect_type effect(1 to effect_max)
  
  as integer music_total, music_current, music_volume
  as music_type music(1 to music_max)
  
  as integer disabledmode 'disable everything when no sound card is found
end type

end namespace
