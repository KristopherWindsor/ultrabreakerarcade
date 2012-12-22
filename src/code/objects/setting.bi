
enum setting_featurelock_enum
  locked      = 0
  progressing = 1 'unlocked gallery and level downloader
  unlocked    = 2 'unlocked editor
end enum

enum setting_sync_enum
  disabled        = 0
  ask             = 1
  autosync        = 2
  autosyncandopen = 3
end enum

Type setting_type
  const keyboardspeedstep = 8 * dsfactor
  const maxplayers = 2
  
  Declare Sub finish ()
  Declare Sub set_controls ()
  Declare Sub set_graphics ()
  Declare Sub set_multiplayer ()
  Declare Sub set_performance ()
  Declare Sub set_recordings ()
  Declare Sub set_tips ()
  declare sub set_web ()
  Declare Sub start ()
  
  As Integer alphavalue    '255, 191, 127, 63
  As Integer ballglow      'extra option because it uses so much CPU (when there are many balls)
  As Integer bullettextures 'turn off if the bullets are too hard to see (scaling issues)
  As Integer cpuhog        'will not sleep at all
  As Integer extras        'exploded paddles and nuke explosions
  As Integer flyingbricks  'flying bricks; 0 = off, 1 = shadows, 2 = textured
  As Integer hicontrast    'gray-out the background, for wierd people
  As Integer mouseclipping 'clip mouse while playing
  As Integer particles     'on / off
  As Integer players       'total number of players
  As Integer tips          'show tip when level starts
  As Integer vsync         'fix shearing
  as integer autosave      'save every recording, coz i said so!
  as integer keyboardspeed 'keyboard control movement
  
  as setting_sync_enum serversync          'do you want to open the web site after submitting?
  as setting_featurelock_enum unlockedmode 'means you haven't unlocked some certain pack that enables the store + editor
  
  as integer areyounotnew  'one-time use variable for opening an intro web page
End Type

dim shared as setting_type setting
