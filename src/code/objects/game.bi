
Enum game_text_enum
  leveltitle = 1
  orblife    = 2
  lives      = 3
  timeleft   = 4
  shields    = 5
  bonus      = 6
  score      = 7
  
  max        = 7
End Enum

'formerly data_game.mode_*
Type game_mode_type
  'contains info sent to game() to affect game play
  'does not keep a running tally of a players score in mission or arcade modes (that data is kept by main_gamemode which calls game())
  
  'set by game modes / menus
  As Integer level
  As Integer lives
  As Integer orbtokens
  As Double speed 'ball speed
  as integer instantrestart
End Type

'formerly data_game.data_*
type game_setting_type
  As Integer requiredscore
  As Integer timelimit
  As String tip, tiplose, tipwin
  
  As Uinteger gfx_background_color
  As String gfx_background_image
  As Integer gfx_background_tile
  
  As Integer special_noballlose, special_nobrickwin, special_shooter
end type

'formerly data_game.result_*
type game_result_type
  'contains info returned by game() to report player progress
  
  declare property scoregained () as integer
  declare property scoregained (byval newscore as integer)
  
  'set by game() after level is complete / failed
  As Integer didcheat 'no points for you!
  As Integer didforfeit 'if forfeit, possibly let user restart level, or check didwin for win / loss
  As Integer didwin
  As Integer liveslost, livesgained
  As Integer orbtokens 'total left remaining (will be mode_orbtokens if no bonuses collected)
  as integer instantrestart 'restart level after this is closed?
  
  'As Integer result_scoregained is replaced by property
  as integer _scoregained 'data for property
  as integer scoregained_master 'set by the property; only read for master score in master / arcade mode
end type

Type game_control_type
  As Integer x, y, click, launchdelay
End Type

Type game_text_object_type
  As String text
  As Double x, xt
  As Integer ison 'if ison -> display; move on or off screen (depends if selected)
End Type

Type game_text_type
  Declare Sub Reset ()
  Declare Sub move ()
  Declare Sub display ()
  
  As Integer selected, changedelay
  As game_text_object_type text(1 To game_text_enum.max)
End Type

Type game_type
  'game keeps all variables for gameplay, and the input (settings) and output (results); it loads the levels from file
  
  Const fps = 120, timemax = 600
  
  Const gravityfactor = .05 * dsfactor
  const gravitymax = 10 * dsfactor
  
  const shootermodecoinmax = 12
  const shootermodecoinrate = 30
  const shootermodeenemymax = 3
  const shootermodeenemyrate = 10
  const shootermodeenemyvalue = 150
  const shootermoderockrate = 50
  
  const timebonusmax = 1000
  const timebonusexponent = 3
  
  const defaultrequiredscore = 1E6
  const ballbumpfactor = 12 * dsfactor
  const rapidfirerate = 5
  const orbprice = 3
  
  declare sub start ()
  declare sub reset ()
  declare sub gfxchange ()
  declare sub reset2 ()
  declare sub run ()
  declare sub move ()
  declare sub display ()
  declare sub finish ()
  declare sub load ()
  declare sub summary ()
  
  Declare Function get_levelname () As String
  Declare Function get_score () As String
  Declare Function get_time () As String
  Declare Function get_winloss () As Integer
  
  'input / output to use this type
  as game_mode_type mode
  as game_result_type result
  
  'some settings based on the level
  as game_setting_type setting
  
  as any ptr threadmutex
  As utility_framerate_type framerate = utility_framerate_type()
  
  'everything below changes throughout the level
  
  'the mouse coords, or coords adjusted by keyboard; the mouse button / enter key
  As game_control_type control(1 To 2)
  
  'input values (except mouse)
  As Integer input_key_x 'arrow keys
  As Integer input_key_y
  As Integer input_usemouse 'only for coords; click is set by both mouse and keyboard; not used for multiplayer
  
  'for things that happen every few frames
  As Integer frametotal
  
  'data
  As Integer data_collected_levelup, data_isgameover
  As Integer data_rapidfire, data_rapidfire_launchload 'range: 0 - 5+; works like missile launchload
  as integer data_getpreview 'is the preview for this level missing? if so, capture frame #120
  as integer data_masterdone 'if true then don't update scoregained_master anymore; updated by the winloss sub
  
  'mode (changes in-game)
  As Integer mode_shooter
  As Integer mode_balltrail 'turned on by cheat
  As Integer mode_invertedcolors
  As Integer mode_pixelation
  As Integer mode_speedfactor
  as integer mode_windfactor
  
  'track (log) certain things for various reasons
  As Integer tracker_lifelost, tracker_bonuscollect
  as string tracker_bonustitle
  
  'countdown the time between loss and ball respawning / game over notice
  As Integer delay_win, delay_lose
  
  'text for displaying on the screen
  As game_text_type text
End Type

Dim Shared As game_type game
