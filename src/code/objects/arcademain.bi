
type main_controls_type
  declare sub load ()
  
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
  
  as any ptr threadmutex
  
  'data is for the currently loaded levelpack
  
  Declare Sub load overload (index as integer)
  Declare Sub load overload (t as string)
  Declare Sub save ()
  Declare Sub unlock ()
  
  Declare property gfxset () As String
  Declare property gfxset (Byref igfxset As String)
  
  declare property showname () as string
  declare property title () as string
  
  As String _gfxset 'read by properties to be threadsafe
  
  as integer indexOf 'title is list(indexOf).title
  
  As Integer level_total, unlockedtotal
  As String level(1 To level_max) 'level names
  As String unlocks 'name of levelpack this pack will unlock / undelete
  
  'data is for all the levelpacks
  
  Declare Sub start ()
  Declare Sub finish ()
  Declare Sub addlp (Byref t As String)
  
  As Integer list_total
  As main_levelpack_onepack_type list(1 To list_max)
End Type

Type main_player_type
  Const name_max = 128
  const anonymous = "Guest"
  
  Declare Sub start ()
  Declare Sub finish ()
  
  Declare sub selectname ()
  'Declare Function get_password (Byref pname As String) As String
  
  declare property lastplayer() as string
  declare property lastplayer(value as string)
  
  As Integer name_total
  As String Name(1 To name_max)
End Type

type main_type
  const gallery_thumb_sx = 320, gallery_thumb_sy = 240
  const arcadelives = 5, arcadespeedfactor = sqr(2)
  
  declare sub run ()
  declare sub start ()
  declare sub screenchange ()
  declare sub finish ()
  declare sub choose_world ()
  declare sub gameover ()
  declare function intro () as integer
  declare function play () as integer
  
  as main_controls_type controls
  as main_levelpack_type levelpack
  as main_player_type player
  
  as integer programstarted
end type

dim shared as main_type main
