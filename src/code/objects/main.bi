
Type main_save_type
  'a game save
  As Integer level
  As Integer lives
  As Integer score
  As Integer orbtokens
End Type

Type main_score_type
  'a highscore entry
  As Integer score
  'level is how many levels you played on that game (only for arcade mode)
  'not used for sorting scores
  As Integer level
  As String player
End Type

type main_levelpack_onepack_type
  
  declare property showname () as string
  
  as string title
  as integer iscompleted
end type

Type main_levelpack_type
  'contains info for the current levelpack, set and sent by main_levelpack()
  
  Const scorespermode = 10 'save top 10 scores
  Const level_max = 256
  Const list_max = 1024
  
  as any ptr threadmutex
  
  'data is for the currently loaded levelpack
  
  Declare Sub load overload (index as integer)
  Declare Sub load overload (t as string)
  Declare Sub save ()
  Declare Sub resubmit ()
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
  
  'As String lastplayer
  
  'note: player name is entered in when added to the high score list; not saved in the progress variables
  As main_score_type mission_score(1 To scorespermode)
  'As data_save_type mission_save
  As main_score_type arcade_score(1 To scorespermode)
  As main_save_type arcade_save
  As main_score_type master_score(1 To level_max) 'one score per level; saved last so adding new levels doesn't ruin anything
  
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
  declare sub gallery ()
  declare sub play ()
  declare sub highscore ()
  declare sub playmaster ()
  declare sub playreplay ()
  declare sub playreplay_selectrecording (Byval levelnumber As Integer)
  declare sub selectlevelpack ()
  declare sub settings ()
  declare sub test ()
  declare sub validate ()
  
  as main_levelpack_type levelpack
  as main_player_type player
  
  as integer programstarted
end type

dim shared as main_type main
