
Type server_type
  'stores all global data that may be needed for server communication
  'ie. the list of leaderboard levelpacks is used for adding to the submission queue
  
  Const lbpack_max = 64, submit_max = 2048
  
  Declare Sub start ()
  Declare Sub finish ()
  
  Declare Sub addrecording (Byref filename As String)
  Declare Sub getlevels ()
  Declare Function islbpack (Byref lp As String) As Integer
  Declare Function processcommands (Byref c As String) As Integer
  Declare Sub sync (Byval theend As Integer = true)
  
  'update.txt
  As Double update
  
  'levels/leaderboard.txt
  'note: do not save this on finish() because the file will be updated by the update process
  As Integer lbpack_total
  As String lbpack(1 To lbpack_max)
  
  'submissions.txt
  As Integer submit_total
  As String submit(1 To submit_max)
End Type

Dim Shared As server_type server
