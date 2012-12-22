
' Audio wrapper for FMOD, BASS, and FBSound! v1.0
' (C) 2008 Innova and Kristopher Windsor

'need to compile to a library to get this working right
'#include once "audio.bi"

namespace audio

sub object.start ()
  #if audio_backend = "fmod"
    If fsound_init(44100, 64, 0) = false Then disabledmode = true
  #endif
  
  effect_volume = 255
  music_volume = 255
end sub

sub object.update ()
  if disabledmode then return
  
  'set stalls for effect repeating
  for i as integer = 1 to effect_total
    with effect(i)
      if .repeat_stall > 0 then .repeat_stall -= 1
    end with
  next i
  
  'loop music
  if music_total > 0 and music_volume > 0 then
    if music_current = 0 then
      'start music
      fire_music()
    else
      #if audio_backend = "fmod"
        if fmusic_isfinished(music(music_current).sample) then fire_music()
      #endif
    end if
  end if
end sub

sub object.stopeffects ()
  if disabledmode then return
  
  'turn a repeating sound off
  'it won't actually turn off until the current loop is finished
  for i as integer = 1 to effect_total
    with effect(i)
      if .nowplaying > 0 then
        #if audio_backend = "fmod"
          if FSOUND_IsPlaying(.nowplaying) then fsound_stopsound(.nowplaying)
        #endif
        .nowplaying = 0
      end if
    end with
  next i
end sub

sub object.finish ()
  if disabledmode then return
  
  #if audio_backend = "fmod"
    fmusic_stopallsongs()
    fsound_close()
  #endif
end sub

function object.register_effect (byref filename as string, byval repeatrate as integer = 8, _
  byval shouldloop as integer = false) as integer
  
  if disabledmode then return effect_total
  
  if effect_total = effect_max then
    audio_error("too many effects")
    return false
  end if
  
  effect_total += 1
  
  with effect(effect_total)
    #if audio_backend = "fmod"
      .sample = fsound_sample_load(fsound_free, filename, 0, 0, 0)
    #endif
    .nowplaying = 0
    
    .loop_mode = shouldloop
    
    .repeat_rate = repeatrate
    .repeat_stall = 0
  end with
  
  return effect_total
end function

function object.register_music (byref filename as string) as integer
  if disabledmode then return music_total
  
  if music_total = music_max then
    audio_error("too much music")
    return false
  end if
  
  music_total += 1
  
  with music(music_total)
    #if audio_backend = "fmod"
      .sample = fmusic_loadsong(filename)
      fmusic_setmastervolume(.sample, music_volume)
    #endif
  end with
  
  return music_total
end function

sub object.fire_effect (byval index as integer)
  if disabledmode then return
  
  if index < 1 or index > effect_total then
    audio_error("invalid effect id (" & index & ")")
    exit sub
  end if
  
  if effect_volume = 0 then exit sub
  
  with effect(index)
    'only start the loop once
    if .loop_mode and .nowplaying > 0 then exit sub
    
    if .repeat_stall > 0 then exit sub
    .repeat_stall = .repeat_rate
    
    #if audio_backend = "fmod"
      .nowplaying = fsound_playsound(fsound_free, .sample)
      if .loop_mode and .nowplaying > 0 then fsound_setloopmode(.nowplaying, FSOUND_LOOP_NORMAL)
    #endif
  end with
end sub

sub object.fire_music (byval index as integer = -1)
  'jump to track
  
  if disabledmode then return
  if music_volume = 0 then return
  
  if index < 1 or index > music_total then
    do
      var d = timer()
      index = int((d - int(d)) * music_total) + 1
    loop until index <> music_current or music_total = 1
  end if
  
  music_current = index
  
  #if audio_backend = "fmod"
    fmusic_stopallsongs()
    fmusic_playsong(music(index).sample)
  #endif
end sub

function object.set_volume_effect (byval v as integer = -1) as integer
  if disabledmode then return effect_volume
  
  if v >= 0 and v <= 255 then
    effect_volume = v
    #if audio_backend = "fmod"
      FSOUND_SetSFXMasterVolume(v)
    #endif
  end if
  
  return effect_volume
end function

function object.set_volume_music (byval v as integer = -1) as integer
  if disabledmode then return music_volume
  
  if v >= 0 and v <= 255 then
    'set master (ie in case more music is registered later)
    music_volume = v
    
    'set for each music track
    #if audio_backend = "fmod"
      for i as integer = 1 to music_total
        fmusic_setmastervolume(music(i).sample, v)
      next i
    #endif
  end if
  
  'music turned off -> stop songs, and don't firemusic anymore
  if music_volume = 0 then
    fmusic_stopallsongs()
    music_current = 0
  end if
  
  return music_volume
end function

end namespace
'
'
'
''test
'
'using audio
'
'dim as object q
'
'q.start
'q.register_effect("s.mp3",4,true)
'q.register_music("c.mod")
'q.register_music("c4b.mod")
'
'do
'  
'  q.update
'  
'  select case inkey
'  case " ": q.fire_effect(1)
'  case "1": q.fire_music(1)
'  case "2": q.fire_music(2)
'  case "x": q.stopeffects()
'  case chr(255, 72): print q.set_volume_music(q.music_volume + 10)
'  case chr(255, 80): print q.set_volume_music(q.music_volume - 10)
'  case chr(27): exit do
'  end select
'  
'  sleep 50,1
'loop
'
'q.finish
'print "!"
'sleep 1000,1
'