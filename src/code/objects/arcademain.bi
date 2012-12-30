
type main_controls_type
  declare sub load ()
  declare function ink(multikey_code as integer) as string
  
  as integer p1_up, p1_down, p1_left, p1_right
  as integer p1_start, p1_fire, p1_alt
  as integer p2_up, p2_down, p2_left, p2_right
  as integer p2_start, p2_fire, p2_alt
  as integer forcequit
end type

type main_levelpack_onepack_type
  
  declare property showname () as string
  
  as string title
  as integer iscompleted
end type

Type main_levelpack_type
  'contains info for the current levelpack, set and sent by main_levelpack()
  
  Const level_max = 256
  Const list_max = 1024
  Const highscore_max = 6
  
  as any ptr threadmutex
  
  'data is for the currently loaded levelpack
  
  Declare Sub load overload (index as integer)
  Declare Sub load overload (t as string)
  Declare Sub save ()
  Declare function addscore (score as integer) as integer 'return new score rank or 0
  
  Declare property gfxset () As String
  Declare property gfxset (Byref igfxset As String)
  
  declare property showname () as string
  declare property title () as string
  
  As String _gfxset 'read by properties to be threadsafe
  
  as integer indexOf 'title is list(indexOf).title
  
  As Integer level_total
  As String level(1 To level_max) 'level names
  
  As String highscore_name(1 to highscore_max)
  As Integer highscore_value(1 to highscore_max)
  
  'data is for all the levelpacks
  
  Declare Sub start ()
  Declare Sub finish ()
  Declare Sub addlp (Byref t As String)
  
  As Integer list_total
  As main_levelpack_onepack_type list(1 To list_max)
End Type

type main_type
  const gallery_thumb_sx = 320, gallery_thumb_sy = 240
  const arcadelives = 5, arcadespeedfactor = sqr(2)
  
  declare sub run ()
  declare sub start ()
  declare sub screenchange ()
  declare sub finish ()
  declare function choose_world () as integer
  declare sub gameover (score as integer)
  declare function intro () as integer
  declare function play () as integer
  
  as main_controls_type controls
  as main_levelpack_type levelpack
  
  as integer programstarted
end type

dim shared as main_type main
