
' Ultrabreaker Leveler!
' (C) 2006 - 2008 Innova and Kristopher Windsor

#include once "code/leveler.bi"

#macro waitforbuttonrelease ()
  With mouse
    While .b > 0
      If Getmouse(.x, .y,, .b) Then mouse = mouse_previous
      Sleep(20, 1)
    Wend
  End With
#endmacro

Dim Shared As String universal_tooltip

Dim Shared As isettings_type isettings
Dim Shared As itoolbar_type itoolbar

Dim Shared As graphic_type graphic
Dim Shared As level_type level

Dim Shared As mouse_type mouse, mouse_previous

Function brick_object_type.displayscale () As Double
  Select Case scale
  Case 0: Return .1
  Case 1: Return .2
  Case 2: Return .4
  Case 3: Return .8
  Case 4: Return 1
  Case 5: Return 1.2
  Case 6: Return 1.5
  Case 7: Return 2
  Case 8: Return 3
  Case 9: Return 4
  End Select
  
  Return 0
End Function

Sub brick_object_type.set (Byref s As String)
  Dim As String b = s
  
  If Len(b) = 5 Then b = Mid(b, 2, 3)
  
  style = Instr(brick_type.codes, Mid(b, 1, 1))
  scale = Val(Mid(b, 2, 1))
  value = Val(Mid(b, 3, 1))
End Sub

Sub brick_type.matrix_set_size Overload (Byval hugeness As Integer) 'hugeness rating of 1 to 5
  Dim As Double x, y
  Dim As igui.option_type o
  
  If hugeness = 6 Then
    'custom size
    With o
      .total = 100
      .options(1) = "Select Columns"
      For i As Integer = 2 To .total
        .options(i) = Str(i)
        .enabled(i) = true
      Next i
      If matrix_sx > 0 And matrix_sx <= 100 Then .selected = matrix_sx
    End With
    x = igui.utility_menu(o)
    
    With o
      .total = 100
      .options(1) = "Select Rows"
      For i As Integer = 2 To .total
        .options(i) = Str(i)
        .enabled(i) = true
      Next i
      If matrix_sy > 0 And matrix_sy <= 100 Then .selected = matrix_sy
    End With
    y = igui.utility_menu(o)
  Else
    x = 12
    Select Case hugeness
    Case 1: x = 2
    Case 2: x = 6
    Case 3: x = 12
    Case 4: x = 24
    Case 5: x = 48
    End Select
    
    'trim for paddles, right here
    With level
      y = x * 2.5 * (3 / 4)
      If .paddlesides(3) > 0 And .paddlesides(4) > 0 Then
        x *= .6
      Elseif .paddlesides(3) > 0 Or .paddlesides(4) > 0 Then
        x *= .8
      End If
      If .paddlesides(1) > 0 And .paddlesides(2) > 0 Then
        y *= .6
      Elseif .paddlesides(1) > 0 Or .paddlesides(2) > 0 Then
        y *= .8
      End If
    End With
  End If
  
  matrix_sx = Int(x + .5)
  matrix_sy = Int(y + .5)
  
  matrix_set_scale()
End Sub

Sub brick_type.matrix_set_size Overload (Byval xlength As Integer, Byval ylength As Integer)
  If xlength > matrix_sx_max Then xlength = matrix_sx_max
  If ylength > matrix_sy_max Then ylength = matrix_sy_max
  
  matrix_sx = xlength
  matrix_sy = ylength
  
  matrix_set_scale()
End Sub

Sub brick_type.matrix_set_scale ()
  Dim As Double xs, ys
  
  xs = layer_type.workspace_sx / (matrix_sx * graphic_type.brick_sx)
  ys = layer_type.workspace_sy / (matrix_sy * graphic_type.brick_sy)
  
  matrix_scale = xs
  If ys < xs Then matrix_scale = ys
End Sub

Sub graphic_type.start ()
  Screenres screen_sx, screen_sy, 32
  
  For i As Integer = 1 To brick_type.style_max
    brick(i) = png_load("data/graphics/abstract/bricks/" & Right("0" & i, 2) & "/1.png", PNG_TARGET_FBNEW)
  Next i
  
  For i As Integer = 1 To item_enum.max - 1
    item(i) = png_load("data/graphics/abstract/items/" & i & "/1.png", PNG_TARGET_FBNEW)
  Next i
  item(item_enum.gravity) = png_load("data/graphics/abstract/gravityorb.png", PNG_TARGET_FBNEW)
End Sub

Sub graphic_type.finish ()
  For i As Integer = 1 To brick_type.style_max
    imagedestroy(brick(i))
  Next i
  For i As Integer = 1 To item_enum.max
    imagedestroy(item(i))
  Next i
End Sub

Sub layer_type.startover ()
  item.list_total = 0
  autoexplode = 0
  
  With brick
    .list_total = 0
    .matrix_set_size(3) 'medium matrix
    For x As Integer = 1 To .matrix_sx_max
      For y As Integer = 1 To .matrix_sy_max
        .matrix(x, y).style = 0
      Next y
    Next x
    .ycollapse = true
  End With
  
  backup() 'prevents user from undoing the loading
End Sub

function layer_type.isempty () as integer
  dim as integer e
  
  with brick
    e = false
    For y As Integer = 1 To .matrix_sy
      For x As Integer = 1 To .matrix_sx
        If .matrix(x, y).style > 0 Then
          e = true
          Exit For, For
        End If
      Next x
    Next y
    return (e = false And .list_total = 0 And this.item.list_total = 0)
  end with
end function

Sub layer_type.edit ()
  #macro setitemdata ()
  Select Case .style
  Case item_enum.bonusbutton: .d = 0
  Case item_enum.brickmachine: .d = 60
  Case item_enum.portal: .d = itoolbar.iobjectvalue.get_selected_index() - 1
  Case item_enum.portal_out: .d = itoolbar.iobjectvalue.get_selected_index() - 1
  Case item_enum.gravity: .d = itoolbar.iobjectvalue.get_selected_index() - 1
  End Select
  #endmacro
  
  Const yoffset = layer_type.workspace_sy - screen_sy
  
  Static As mouse_type mouse_down, mouse_down_real
  
  Dim As Integer e, ix, iy, dx, dy
  Dim As Double x, y
  
  With mouse_down
    'onclick triggers backup save, because clicking can change the level
    If mouse.b > 0 And mouse_previous.b = 0 Then backup()
    
    If mouse.b = 0 Then 'will be set when user presses button down
      mouse_down = mouse
      mouse_down_real = mouse 'md has matrix coords; mdr has mouse coords
      
      .x = Int(.x / (graphic_type.brick_sx * brick.matrix_scale) + 1)
      .y = Int((.y + yoffset) / (graphic_type.brick_sy * brick.matrix_scale) + 1)
    End If
    
    If .x < 1 Then .x = 1
    If .y < 1 Then .y = 1
    If .x > brick.matrix_sx Then .x = brick.matrix_sx
    If .y > brick.matrix_sy Then .y = brick.matrix_sy
  End With
  
  If isettings.up Or mouse.y < 0 Then Exit Sub
  
  x = mouse.x / (graphic_type.brick_sx * brick.matrix_scale) + 1
  y = (mouse.y + yoffset) / (graphic_type.brick_sy * brick.matrix_scale) + 1
  ix = Int(x)
  iy = Int(y)
  
  'set tooltip
  If ix >= 1 And iy >= 1 And ix <= brick.matrix_sx And iy <= brick.matrix_sy Then
    With brick.matrix(ix, iy)
      If .style > 0 Then
        universal_tooltip = itoolbar.style(.style) & " (Size: " & .scale & ") (Value: " & .value & ")"
      End If
    End With
  End If
  For i As Integer = 1 To brick.list_total
    With brick.list(i)
      If Abs(x - .x - .5) < .5 And Abs(y - .y - .5) < .5 Then
        universal_tooltip = itoolbar.style(.style) & " (Size: " & .scale & ") (Value: " & .value & ")"
      End If
    End With
  Next i
  For i As Integer = 1 To item.list_total
    With item.list(i)
      If Abs(x - .x - .5) < .5 And Abs(y - .y - .5) < .5 Then
        universal_tooltip = itoolbar.style(.style + brick_type.style_max) & " (Data: " & .d & ")"
      End If
    End With
  Next i
  
  If ix >= 1 And iy >= 1 And ix <= brick.matrix_sx And iy <= brick.matrix_sy Then
    If (mouse.b And 1) > 0 Then
      If itoolbar.pen <= brick_type.style_max Then
        If itoolbar.igridalign.get_checked() Then
          'grid bricks
          For lx As Integer = mouse_down.x To ix
            For ly As Integer = mouse_down.y To iy
              With brick.matrix(lx, ly)
                .style = itoolbar.pen
                .scale = itoolbar.iobjectscale.get_selected_index() - 1
                .value = itoolbar.iobjectvalue.get_selected_index() - 1
              End With
              
              'erase item
              e = false
              For i As Integer = 1 To item.list_total
                With item.list(i)
                  If .x = lx And .y = ly Then
                    e = i
                    Exit For
                  End If
                End With
              Next i
              If e > 0 Then
                Swap item.list(e), item.list(item.list_total)
                item.list_total -= 1
              End If
            Next ly
          Next lx
        Else
          'individual bricks
          If mouse_previous.b = 0 And brick.list_total < brick.list_max Then
            brick.list_total += 1
            
            With brick.list(brick.list_total)
              .style = itoolbar.pen
              .scale = itoolbar.iobjectscale.get_selected_index - 1
              .value = itoolbar.iobjectvalue.get_selected_index - 1
            End With
          End If
          
          'move brick even if not adding a new one
          With brick.list(brick.list_total)
            .x = x - .5
            .y = y - .5
          End With
        End If
      Else
        'draw item
        If itoolbar.igridalign.get_checked() Then
          e = false
          For i As Integer = 1 To item.list_total
            With item.list(i)
              If .x = ix And .y = iy Then
                e = true
                .style = itoolbar.pen - brick_type.style_max
                setitemdata()
              End If
            End With
          Next i
          
          If e = false And item.list_total < item.list_max Then
            item.list_total += 1
            With item.list(item.list_total)
              .x = ix
              .y = iy
              .style = itoolbar.pen - brick_type.style_max
              setitemdata()
            End With
            
            'erase brick under item
            brick.matrix(ix, iy).style = 0
          End If
        Else
          'individual items
          If mouse_previous.b = 0 And item.list_total < item.list_max Then
            item.list_total += 1
            
            With item.list(item.list_total)
              .x = ix
              .y = iy
              .style = itoolbar.pen - brick_type.style_max
              setitemdata()
            End With
          End If
          
          'move brick even if not adding a new one
          With item.list(item.list_total)
            .x = x - .5
            .y = y - .5
          End With
        End If
      End If
      
      redraw()
    Elseif (mouse.b And 2) > 0 And mouse_previous.b = 0 Then
      'remove object on right click
      
      e = false
      For i As Integer = item.list_total To 1 Step -1
        With item.list(i)
          If Abs(x - .x - .5) < .5 And Abs(y - .y - .5) < .5 Then e = i
        End With
      Next i
      If e > 0 Then
        Swap item.list(e), item.list(item.list_total)
        item.list_total -= 1
      End If
      
      If e = 0 Then
        For i As Integer = brick.list_total To 1 Step -1
          With brick.list(i)
            If Abs(x - .x - .5) < .5 And Abs(y - .y - .5) < .5 Then e = i
          End With
        Next i
        If e > 0 Then
          Swap brick.list(e), brick.list(brick.list_total)
          brick.list_total -= 1
        End If
      End If
      
      If e = 0 Then
        brick.matrix(ix, iy).style = 0
      End If
      
      redraw()
    Elseif (mouse.b And 2) > 0 And (mouse.x <> mouse_down_real.x Or mouse.y <> mouse_down_real.y) Then
      'erase everything on the grid, in range
      
      For lx As Integer = mouse_down.x To ix
        For ly As Integer = mouse_down.y To iy
          e = false
          For i As Integer = item.list_total To 1 Step -1
            With item.list(i)
              If .x = lx And .y = ly Then e = i
            End With
          Next i
          If e > 0 Then
            Swap item.list(e), item.list(item.list_total)
            item.list_total -= 1
          End If
          
          brick.matrix(lx, ly).style = 0
        Next ly
      Next lx
      
      redraw()
    End If
  End If
End Sub

Sub layer_type.redraw ()
  
  Dim As Integer a
  Dim As Double scale
  
  If workspace = 0 Then workspace = imagecreate(workspace_sx, workspace_sy)
  
  Line workspace, (0, 0) - (workspace_sx - 1, workspace_sy - 1), color_enum.transparent, BF
  
  With brick
    'grid
    For x As Integer = 1 To .matrix_sx
      Line workspace, (x * graphic_type.brick_sx * .matrix_scale, 0) - Step(0, .matrix_sy * graphic_type.brick_sy * .matrix_scale), color_enum.lightgray
    Next x
    For y As Integer = 1 To .matrix_sy
      Line workspace, (0, y * graphic_type.brick_sy * .matrix_scale) - Step(.matrix_sx * graphic_type.brick_sx * .matrix_scale, 0), color_enum.lightgray
    Next y
    
    'matrix
    For x As Integer = 1 To .matrix_sx
      For y As Integer = 1 To .matrix_sy
        If .matrix(x, y).style > 0 Then
          multiput(workspace, _
          (x - .5) * graphic_type.brick_sx * .matrix_scale, _
          (y - .5) * graphic_type.brick_sy * .matrix_scale, _
          graphic.brick(.matrix(x, y).style), .matrix_scale * .matrix(x, y).displayscale())
        End If
      Next y
    Next x
    
    'solo bricks
    For i As Integer = 1 To .list_total
      With .list(i)
        multiput(workspace, _
        (.x - .5) * graphic_type.brick_sx * brick.matrix_scale, _
        (.y - .5) * graphic_type.brick_sy * brick.matrix_scale, _
        graphic.brick(.style), brick.matrix_scale * .displayscale())
      End With
    Next i
  End With
  
  With item
    'items
    For i As Integer = 1 To .list_total
      scale = brick.matrix_scale
      With .list(i)
        If .style = item_enum.gravity Then scale *= 1 + (.d - 4) / 5
        multiput(workspace, _
        (.x - .5) * graphic_type.brick_sx * brick.matrix_scale, _
        (.y - .5) * graphic_type.brick_sy * brick.matrix_scale, _
        graphic.item(.style), scale)
      End With
    Next i
    
    'portal connectors
    For i As Integer = 0 To 9
      'looping for each portal code
      
      'find a portal target
      a = 0
      For i2 As Integer = 1 To .list_total
        With .list(i2)
          If .style = 4 And .d = i Then a = i2
        End With
      Next i2
      If a = 0 Then Continue For
      
      'draw for each portal
      
      For i2 As Integer = 1 To .list_total
        With .list(i2)
          If .style = 3 And .d = i Then
            Line workspace, (_
              (.x - .5) * graphic_type.brick_sx * brick.matrix_scale, _
              (.y - .5) * graphic_type.brick_sy * brick.matrix_scale) - (_
              (item.list(a).x - .5) * graphic_type.brick_sx * brick.matrix_scale, _
              (item.list(a).y - .5) * graphic_type.brick_sy * brick.matrix_scale), color_enum.black
          End If
        End With
      Next i2
    Next i
  End With
End Sub

Sub layer_type.backup ()
  backup_brick = brick
  backup_item = item
  redraw()
End Sub

Sub layer_type.restore ()
  Swap backup_brick, brick
  Swap backup_item, item
  redraw()
End Sub

Sub level_type.startover ()
  'defaults for new level
  
  '(no changes to levelpack)
  levelnumber = levelpack.leveltotal + 1
  levelname = "Entitle Me!"
  
  For i As Integer = 1 To 5
    paddlesides(i) = Iif(i = 2, 1, 0)
  Next i
  
  backgroundcolor = color_enum.white
  backgroundimage = "bluehole"
  backgroundimagetile = false
  
  ballmultiplier = 1
  ballmelee = false
  ballscale = 1
  ballspeed = 1
  bonuslives = 0
  minscore = 1000000 'out of reach
  mousegravity = 0
  paddlescale = 1
  paddlestyle = 2
  special_noballlose = false
  special_nobrickwin = false
  special_shooter = false
  time_minutes = 10
  time_seconds = 0
  tip = ""
  tipLose = ""
  tipWin = ""
  
  For i As Integer = 1 To layer_max
    layer(i).startover()
  Next i
  
  setupgui()
End Sub

Sub level_type.load (Byref lp As String, Byval ln As Integer, Byval temp As Integer = false)
  'parse level file to load level
  
  Const arg_max = 32
  
  Dim As Integer arg_total, currentlayer, f = Freefile, t1, t2
  Dim As String arg(0 To arg_max), file, l
  
  startover()
  
  levelpack.load(lp)
  levelnumber = ln
  
  If temp Then
    file = "test/1"
  Else
    file = lp & "/" & ln
  End If
  
  'change some variables if the defaults have to be changed
  '(ie need to add paddles to a default of 0, not 1)
  For i As Integer = 1 To 5
    paddlesides(i) = 0
  Next i
  
  Open "data/levelpacks/" & file & ".txt" For Input As #f
  Line Input #f, levelname
  
  While Not Eof(f)
    Line Input #f, l
    l = Trim(l)
    If Left(l, 2) = "//" Or Len(l) = 0 Then Continue While
    
    arg_total = -1
    t1 = 0
    Do
      t2 = t1
      t1 = Instr(t1 + 1, l, Any Chr(9, 32))
      If t1 = 0 Then t1 = Len(l) + 1
      If t1 - t2 > 1 Then
        If arg_total < arg_max Then arg_total += 1
        arg(arg_total) = Mid(l, t2 + 1, t1 - t2 - 1)
      End If
    Loop Until t1 = Len(l) + 1
    If arg_total < 0 Then Continue While
    
    Select Case Ucase(arg(0))
    Case "ABRICK"
      If arg_total = 3 Then
        With layer(currentlayer).brick
          If .list_total < .list_max Then .list_total += 1
          
          With .list(.list_total)
            .x = Val(arg(1))
            .y = Val(arg(2))
            .set(arg(3))
          End With
        End With
      End If
    Case "BACKGROUND"
      If arg_total >= 1 And arg_total <= 3 Then
        backgroundcolor = Val("&H" & arg(1))
        If arg_total >= 2 Then
          backgroundimage = arg(2)
          backgroundimagetile = false
          If arg_total = 3 And arg(3) = "tile" Then backgroundimagetile = true
        End If
      End If
    Case "BALLMULTIPLIER"
      If arg_total = 1 Or arg_total = 2 Then
        ballmultiplier = Val(arg(1))
        ballmelee = ((arg(2) = "melee") And arg_total = 2)
      End If
    Case "BALLSIZE"
      If arg_total = 1 Then ballscale = Val(arg(1))
    Case "BALLSPEED"
      If arg_total = 1 Then ballspeed = Val(arg(1))
    Case "BONUSLIVES"
      If arg_total = 1 Then bonuslives = Val(arg(1))
    Case "BRICKSET"
      If currentlayer < layer_max Then currentlayer += 1
      
      With layer(currentlayer).brick
        If arg_total >= 2 and arg_total <= 4 Then
          .matrix_set_size(Val(arg(1)), Val(arg(2)))
          If arg_total >= 3 Then .ycollapse = (arg(3) = "ycollapse")
          if arg_total = 4 then layer(currentlayer).autoexplode = val(arg(4))
          
          For y As Integer = 1 To .matrix_sy
            Line Input #f, l
            For x As Integer = 1 To .matrix_sx
              .matrix(x, y).set(Mid(l, x * 5 - 4, 5))
            Next x
          Next y
        End If
      End With
    Case "ITEM"
      If (arg_total = 3 Or arg_total = 4) And currentlayer > 0 Then
        With layer(currentlayer).item
          If .list_total < .list_max Then .list_total += 1
          
          With .list(.list_total)
            .x = Val(arg(1))
            .y = Val(arg(2))
            
            .d = 0
            Select Case arg(3)
            Case "bonusbutton"
              .style = item_enum.bonusbutton
            Case "brickmachine"
              .style = item_enum.brickmachine
              .d = 60
            Case "portal"
              .style = item_enum.portal
            Case "portal_out"
              .style = item_enum.portal_out
            Case "gravity"
              .style = item_enum.gravity
              .d = 5
            End Select
            
            If arg_total = 4 Then .d = Val(arg(4))
          End With
        End With
      End If
    Case "MINSCORE"
      If arg_total = 1 Then minscore = Val(arg(1))
    Case "MOUSEGRAVITY"
      If arg_total = 1 Then mousegravity = Val(arg(1))
    Case "PADDLESIDES"
      If arg_total >= 1 And arg_total <= 5 Then
        For i As Integer = 1 To arg_total
          Select Case arg(i)
          Case "top"
            paddlesides(1) += 1
          Case "bottom"
            paddlesides(2) += 1
          Case "left"
            paddlesides(3) += 1
          Case "right"
            paddlesides(4) += 1
          Case "center"
            paddlesides(5) += 1
          End Select
        Next i
      End If
    Case "PADDLESIZE"
      If arg_total = 1 Then paddlescale = Val(arg(1))
    Case "PADDLESTYLE"
      If arg_total = 1 Then
        Select Case arg(1)
        Case "normal"
          paddlestyle = 1
        Case "super"
          paddlestyle = 2
        End Select
      End If
    Case "SPECIAL"
      If arg_total >= 1 And arg_total <= 3 Then
        For i As Integer = 1 To arg_total
          Select Case arg(i)
          Case "noballlose"
            special_noballlose = true
          Case "nobrickwin"
            special_nobrickwin = true
          Case "shooter"
            special_shooter = true
          End Select
        Next i
      End If
    Case "TIMELIMIT"
      If arg_total = 1 Or arg_total = 2 Then
        time_minutes = Val(arg(1))
        time_seconds = 0
        If arg_total = 2 Then time_seconds = Val(arg(2))
      End If
    Case "TIP"
      If arg_total = 1 Then tip = arg(1)
    Case "TIPLOSE"
      If arg_total = 1 Then tiplose = arg(1)
    Case "TIPWIN"
      If arg_total = 1 Then tipwin = arg(1)
    Case "VERSION"
      If arg_total = 1 Then
        'will exit with error if wrong version detected
      End If
    End Select
  Wend
  Close #f
  
  setupgui()
End Sub

Sub level_type.load_temp ()
  'extract levelpack and number from the comments in the temp
  Dim As String t1
  Dim As Integer f = Freefile, t2
  
  Open "data/leveler.txt" For Input As #f
  Line Input #f, t1
  Input #f, t2
  Close #f
  
  load(t1, t2, true)
End Sub

Sub level_type.save (Byval istemp As Integer = false)
  'save level; if temp, then save to the temp level, and put levelpack and number in comments
  
  Dim As Integer e, f = Freefile
  Dim As String file, s
  
  If istemp Then
    file = "test/1"
    
    Open "data/leveler.txt" For Output As #f
    Print #f, levelpack.pack
    Print #f, levelnumber
    Close #f
  Else
    file = levelpack.pack & "/" & levelnumber
    
    With levelpack
      'done on setupgui() if levelnumber > .leveltotal + 1 then levelnumber = .leveltotal + 1
      .level(levelnumber) = levelname
      If levelnumber > .leveltotal Then
        .leveltotal += 1
        .save()
      End If
    End With
  End If
  
  If Open("data/levelpacks/" & file & ".txt" For Output As #f) Then
    igui.utility_alert("Cannot save level: " & file, igui.vars.menus.menu_ok,,, 256)
    System()
  End If
  
  If time_minutes = 10 And time_seconds > 0 Then
    time_seconds = 0
    igui.utility_alert("Time limit will be limited to 10 minutes.", igui.vars.menus.menu_ok,,, 256)
  End If
  
  Print #f, levelname
  Print #f,
  Print #f, "// Generated with UB Leveler " & ultrabreaker_version_major & _
    "." & ultrabreaker_version_minor & " (" & Time & " on " & Date & ")"
  Print #f,
  Print #f, "VERSION " & ultrabreaker_version_major & "." & ultrabreaker_version_minor
  
  If Len(tip) + len(tiplose) + len(tipwin) > 0 Then
    Print #f,
    Print #f, "// Tips: storyline, gameplay hints, etc."
    Print #f,
    if len(tip) > 0 then Print #f, "TIP " & tip
    if len(tiplose) > 0 then Print #f, "TIPLOSE " & tiplose
    if len(tipwin) > 0 then Print #f, "TIPWIN " & tipwin
  End If
  
  Print #f,
  Print #f, "// Settings, part I"
  Print #f,
  For i As Integer = 1 To 5
    s = ""
    If paddlesides(1) >= i Then s += " top"
    If paddlesides(2) >= i Then s += " bottom"
    If paddlesides(3) >= i Then s += " left"
    If paddlesides(4) >= i Then s += " right"
    If paddlesides(5) >= i Then s += " center"
    If Len(s) > 0 Then Print #f, "PADDLESIDES" & s
  Next i
  
  For i As Integer = 1 To layer_max
    if layer(i).isempty() then continue for
    
    With layer(i).brick
      Print #f,
      Print #f, "// Layer " & i
      Print #f,
      Print #f, "BRICKSET " & .matrix_sx & " " & .matrix_sy & " ycollapse";
      if layer(i).autoexplode <> 0 then print #f, " " & layer(i).autoexplode;
      Print #f,
      For y As Integer = 1 To .matrix_sy
        s = ""
        For x As Integer = 1 To .matrix_sx
          With .matrix(x, y)
            If .style = 0 Then
              s += Space(5)
            Else
              s += "[" & Mid(brick_type.codes, .style, 1) & .scale & .value & "]"
            End If
          End With
        Next x
        Print #f, s
      Next y
      
      If .list_total > 0 Then
        Print #f,
        For i2 As Integer = 1 To .list_total
          With .list(i2)
            If .x >= .5 And .y >= .5 And .x - .5 <= layer(i).brick.matrix_sx And .y - .5 <= layer(i).brick.matrix_sy Then
              Print #f, "ABRICK " & format(.x, "00.000") & " " & format(.y, "00.000") & _
                " [" & Mid(brick_type.codes, .style, 1) & .scale & .value & "]"
            End If
          End With
        Next i2
      End If
    End With
    
    With layer(i).item
      If .list_total > 0 Then
        Print #f,
        For i2 As Integer = 1 To .list_total
          With .list(i2)
            If .x >= .5 And .y >= .5 And .x - .5 <= layer(i).brick.matrix_sx And .y - .5 <= layer(i).brick.matrix_sy Then
              s = "ITEM " & format(.x, "00.000") & " " & format(.y, "00.000") & " "
              Select Case .style
              Case item_enum.bonusbutton: s += "bonusbutton"
              Case item_enum.brickmachine: s += "brickmachine"
              Case item_enum.portal: s += "portal"
              Case item_enum.portal_out: s += "portal_out"
              Case item_enum.gravity: s += "gravity"
              End Select
              s += " " & .d
              Print #f, s
            End If
          End With
        Next i2
      End If
    End With
  Next i
  
  Print #f,
  Print #f, "// Settings, part II"
  Print #f,
  
  s = "BACKGROUND " & Hex(backgroundcolor or &HFF000000)
  If Len(backgroundimage) > 0 Then
    s += " " & backgroundimage
    If backgroundimagetile Then s += " tile"
  End If
  Print #f, s
  
  s = "BALLMULTIPLIER " & ballmultiplier
  If ballmelee Then s += " melee"
  Print #f, s
  
  Print #f, "BALLSIZE " & ballscale
  
  Print #f, "BALLSPEED " & ballspeed
  
  If bonuslives <> 0 Then Print #f, "BONUSLIVES " & bonuslives
  
  Print #f, "MINSCORE " & minscore
  
  If mousegravity <> 0 Then Print #f, "MOUSEGRAVITY " & format(mousegravity, "00.000")
  
  Print #f, "PADDLESIZE " & paddlescale
  
  s = "" 'will prevent quirk on error (error should not be possible)
  Select Case paddlestyle
  Case 1: s = "normal"
  Case 2: s = "super"
  End Select
  Print #f, "PADDLESTYLE " & s
  
  s = ""
  If special_noballlose Then s += " noballlose"
  If special_nobrickwin Then s += " nobrickwin"
  If special_shooter Then s += " shooter"
  If Len(s) > 0 Then Print #f, "SPECIAL" & s
  
  Print #f, "TIMELIMIT " & time_minutes & " " & time_seconds
  Close #f
End Sub

Sub level_type.setupgui ()
  Dim As Integer f = Freefile
  Dim As String l
  
  'redraw the layers
  For i As Integer = 1 To layer_max
    layer(i).redraw()
  Next i
  
  'toolbars
  With itoolbar
    ilayer_set()
    ilayersize_set()
  End With
  
  'settings
  With isettings
    With .ilevelpack
      .options.total = 0
      .options.selected = 0
      Open "data/levelpacks/list.txt" For Input As #f
      While Not Eof(f)
        Line Input #f, l
        .add_option(l)
      Wend
      Close #f
      .set_selected(levelpack.pack)
    End With
    
    With .ilevelnumber
      .options.total = 0
      .options.selected = 0
      
      For i As Integer = 1 To levelpack.leveltotal
        .add_option(i & ") " & levelpack.level(i))
      Next i
      If levelpack.leveltotal < levelpack.level_max Then .add_option((levelpack.leveltotal + 1) & ") [New]")
      
      If levelnumber > levelpack.leveltotal + 1 Then levelnumber = levelpack.leveltotal + 1
      .set_selected(levelnumber)
    End With
    
    .iballmelee.set_checked(ballmelee)
    
    .ibackgroundimagetile.set_checked(backgroundimagetile)
    
    .ibackgroundcolor.set_selected(1)
    Select Case backgroundcolor and &HFFFFFF
    Case &H000000: .ibackgroundcolor.set_selected(2)
    Case &H888888: .ibackgroundcolor.set_selected(3)
    Case &HFFFFFF: .ibackgroundcolor.set_selected(4)
    Case &HFF0000: .ibackgroundcolor.set_selected(5)
    Case &H00FF00: .ibackgroundcolor.set_selected(6)
    Case &H0000FF: .ibackgroundcolor.set_selected(7)
    Case &H00FFFF: .ibackgroundcolor.set_selected(8)
    Case &HFF00FF: .ibackgroundcolor.set_selected(9)
    Case &HFFFF00: .ibackgroundcolor.set_selected(10)
    End Select
    
    With .ibackgroundimage '(use DIR); update when selected levelpack changes
      .options.total = 0
      .options.selected = 0
      .add_option("NC (no changes)", false)
      .add_option("(Browse...)")
      .add_option("(None)")
      
      l = Dir("data/graphics/" & levelpack.gfxset & "/backgrounds/*", &H21)
      While Len(l) > 0
        .add_option(Left(l, Len(l) - 4))
        l = Dir()
      Wend
      
      .set_selected(1)
      if backgroundimage = "" then
        .set_selected("(None)")
      else
        .set_selected(backgroundimage)
      end if
    End With
    
    .iballmultiplier.set_selected(1)
    .iballmultiplier.set_selected(Str(ballmultiplier))
    
    .iballscale.set_selected(1)
    Select Case ballscale
    Case .25: .iballscale.set_selected(2)
    Case .5:  .iballscale.set_selected(3)
    Case 1:   .iballscale.set_selected(4)
    Case 2:   .iballscale.set_selected(5)
    Case 4:   .iballscale.set_selected(6)
    End Select
    
    .iballspeed.set_selected(1)
    .iballspeed.set_selected(Str(ballspeed))
    
    .ibonuslives.set_selected(1)
    .ibonuslives.set_selected(Str(bonuslives))
    
    .ilevelname.set_text(levelname)
    
    .iminscore.set_text(Str(minscore))
    
    .imousegravity.set_selected(1)
    Select Case mousegravity
    Case 0: .imousegravity.set_selected(2)
    Case .5: .imousegravity.set_selected(3)
    Case 1: .imousegravity.set_selected(4)
    Case 2: .imousegravity.set_selected(5)
    Case 4: .imousegravity.set_selected(6)
    End Select
    
    .ipaddlescale.set_selected(1)
    Select Case paddlescale
    Case .25: .ipaddlescale.set_selected(2)
    Case .5: .ipaddlescale.set_selected(3)
    Case 1: .ipaddlescale.set_selected(4)
    Case 2: .ipaddlescale.set_selected(5)
    Case 4: .ipaddlescale.set_selected(6)
    End Select
    
    .ipaddlestyle.set_selected(paddlestyle)
    
    For i As Integer = 1 To 5
      .ipaddlesides(i).set_selected(1)
      .ipaddlesides(i).set_selected(Str(paddlesides(i)))
    Next i
    
    .ispecial_noballlose.set_checked(special_noballlose)
    .ispecial_nobrickwin.set_checked(special_nobrickwin)
    .ispecial_shooter.set_checked(special_shooter)
    
    .itime_minutes.set_selected(1)
    .itime_minutes.set_selected(Str(time_minutes))
    
    .itime_seconds.set_selected(1)
    .itime_seconds.set_selected(Str(time_seconds))
    
    .itip.set_text(tip)
    .itiplose.set_text(tiplose)
    .itipwin.set_text(tipwin)
    
    .imanage_deletelp.options = .ilevelpack.options
    With .imanage_deletelp
      .options.total = 0
      .options.selected = 0
      .add_option("- Select -", false)
      Open "data/levelpacks/list.txt" For Input As #f
      While Not Eof(f)
        Line Input #f, l
        .add_option(l)
      Wend
      Close #f
      .set_selected(1)
    End With
  End With
End Sub

Sub level_type.display ()
  Dim As double a = 255
  
  If Multikey(&H2A) Then
    'show all layers
    For i As Integer = 1 To layer_max
      Put (0, screen_sy - layer_type.workspace_sy), layer(i).workspace, alpha, cint(a)
      a *= .75
    Next i
  Else
    Put (0, screen_sy - layer_type.workspace_sy), layer(itoolbar.ilayer.get_selected_index).workspace, trans
  End If
End Sub

Sub levelpack_type.load (Byref lp As String)
  Dim As Integer f = Freefile
  
  pack = lp
  d_total = 0
  
  Open "data/levelpacks/" & pack & "/data.txt" For Input As #f
  Input #f, leveltotal
  Input #f, unlockedtotal
  Line Input #f, gfxset
  While Not Eof(f)
    If d_total < d_max Then d_total += 1
    Line Input #f, d(d_total)
  Wend
  Close #f
  
  For i As Integer = 1 To leveltotal
    Open "data/levelpacks/" & pack & "/" & i & ".txt" For Input As #f
    Line Input #f, level(i)
    Close #f
  Next i
End Sub

Sub levelpack_type.save ()
  Dim As Integer f = Freefile
  
  Open "data/levelpacks/" & pack & "/data.txt" For Output As #f
  Print #f, leveltotal
  Print #f, unlockedtotal
  Print #f, gfxset
  For i As Integer = 1 To d_total
    Print #f, d(i)
  Next i
  Close #f
End Sub

Sub main_start ()
  setenviron("fbgfx=GDI")
  If CreateMutex(NULL, TRUE, "_UltraBreakerLeveler") = 0 Then System()
  If GetLastError() = ERROR_ALREADY_EXISTS Then System()
  
  graphic.start()
  
  igui.start()
  isettings.register()
  itoolbar.register()
  
  level.load_temp()
End Sub

Sub main ()
  Dim As Integer fc, quit, x
  Dim As String key
  
  Do
    fc += 1
    
    mouse_previous = mouse
    With mouse
      If Getmouse(.x, .y,, .b) Then mouse = mouse_previous
    End With
    
    universal_tooltip = ""
    level.layer_selected = itoolbar.ilayer.get_selected_index()
    igui.process(key)
    If key = Chr(26) Then level.layer(level.layer_selected).restore()
    level.layer(level.layer_selected).edit()
    
    If fc Mod 2 = 0 Then
      Screenlock()
      Line (0, 0) - (screen_sx - 1, screen_sy - 1), color_enum.white, BF
      level.display()
      igui.display()
      
      If Len(universal_tooltip) > 0 Then
        x = mouse.x
        If x > screen_sx - Len(universal_tooltip) * 8 Then x = screen_sx - Len(universal_tooltip) * 8
        Line (x, mouse.y + 23) - Step(Len(universal_tooltip) * 8, 8), color_enum.white, BF
        Draw String (x, mouse.y + 24), universal_tooltip, color_enum.black
      End If
      Screenunlock()
    End If
    
    Sleep(20, 1)
    key = Inkey()
    If key = Chr(27) Or key = Chr(255, 107) Then quit = true
  Loop Until quit
End Sub

Sub main_finish ()
  level.save(true)
  graphic.finish()
End Sub

Sub isettings_type.register ()
  Const center = (1024 - (650 + 96)) \ 2
  Const validchars_base = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890-"
  Const validchars_extended = validchars_base & "() !?:$+_="
  
  Dim As String l
  
  iform.register("",,, 0, 0, 1024, 478)
  
  ihead_main.register("Main",, "Main settings", 2 + center, 2, 256, 32, 0)
  ilevelpack.register("Pack    ",, "Select levelpack to edit", 2 + center, 70, 256, 32, @ilevelpack_target)
  ilevelpack.set_target_mousedown(@ilevelpack_target)
  ilevelnumber.register("Number  ",, "Select a level to edit", 2 + center, 104, 256, 32, @ilevelnumber_target)
  ilevelname.register("Name    ",, "Name this level", 2 + center, 138, 256, 32, @ilevelname_target,,,, 32)
  ilevelname.set_valid_text(validchars_extended)
  itip.register("Tip     ",, "Message for the player, pre-game", 2 + center, 172, 256, 32, @itip_target)
  itiplose.register("Tip:Lose",, "Message if the player loses", 2 + center, 204, 256, 32, @itiplose_target)
  itipwin.register("Tip:Win ",, "Message if the player wins", 2 + center, 236, 256, 32, @itipwin_target)
  
  ihead_paddles.register("Paddles",, "Paddle settings", 260 + center, 2, 96, 32, 0)
  ipaddlesides(1).register("Top     ",, "Paddles on top", 260 + center, 70, 96, 32, @ipaddlesides_target)
  ipaddlesides(2).register("Bottom  ",, "Paddles on bottom", 260 + center, 104, 96, 32, @ipaddlesides_target)
  ipaddlesides(3).register("Left    ",, "Paddles on left", 260 + center, 138, 96, 32, @ipaddlesides_target)
  ipaddlesides(4).register("Right   ",, "Paddles on right", 260 + center, 172, 96, 32, @ipaddlesides_target)
  ipaddlesides(5).register("Center  ",, "Paddles on center", 260 + center, 206, 96, 32, @ipaddlesides_target)
  For i As Integer = 1 To 5
    ipaddlesides(i).add_option("NC (no changes)", false)
    ipaddlesides(i).add_options(!"0\n1\n2\n3")
  Next i
  ipaddlescale.register("Size    ",, "Paddle size", 260 + center, 240, 96, 32, @ipaddlescale_target)
  ipaddlescale.add_option("NC (no changes)", false)
  ipaddlescale.add_options(!"XS\nS\nM\nL\nXL")
  ipaddlestyle.register("Style   ",, "Paddle style", 260 + center, 274, 96, 32, @ipaddlestyle_target)
  ipaddlestyle.add_options(!"Normal\nSuper")
  
  ihead_balls.register("Balls",, "Ball settings", 358 + center, 2, 96, 32, 0)
  iballmultiplier.register("Multiple",, "No. of balls given per life", 358 + center, 70, 96, 32, @iballmultiplier_target)
  iballmultiplier.add_option("NC (no changes)", false)
  For i As Integer = 0 To 32
    iballmultiplier.add_option(Str(i))
  Next i
  iballmelee.register("Melee   ",, "Have balls start on all paddles", 358 + center, 104, 96, 32, @iballmelee_target)
  iballscale.register("Size    ",, "Various ball sizes", 358 + center, 138, 96, 32, @iballscale_target)
  iballscale.add_option("NC (no changes)", false)
  iballscale.add_options(!"XS\nS\nM\nL\nXL")
  iballspeed.register("Speed   ",, "Adjust the gameplay speed", 358 + center, 172, 96, 32, @iballspeed_target)
  iballspeed.add_option("NC (no changes)", false)
  iballspeed.add_options(!".5\n.75\n1\n1.4\n2\n2.5\n3")
  
  ihead_graphics.register("Graphics",, "Graphic settings", 456 + center, 2, 96, 32, 0)
  ibackgroundcolor.register("Color   ",, "Background color", 456 + center, 70, 96, 32, @ibackgroundcolor_target)
  ibackgroundcolor.add_option(!"NC (no changes)", false)
  ibackgroundcolor.add_options(!"Black\nGray\nWhite\nRed\nGreen\nBlue\nCyan\nMagenta\nYellow")
  ibackgroundimage.register("Pic     ",, "Background image", 456 + center, 104, 96, 32, @ibackgroundimage_target)
  ibackgroundimagetile.register("Tile",, "Tile background image (instead of stretching)", 456 + center, 138, 96, 32, @ibackgroundimagetile_target)
  
  ihead_more.register("More",, "More settings", 554 + center, 2, 96, 32, 0)
  ibonuslives.register("Lives   ",, "Give bonus lives when level starts", 554 + center, 70, 96, 32, @ibonuslives_target)
  ibonuslives.add_option("NC (no changes)", false)
  For i As Integer = 0 To 12
    ibonuslives.add_option(Str(i))
  Next i
  iminscore.register("Pts.",, "Score for level up (not required unless ""No win"" checked)", 554 + center, 104, 96, 32, @iminscore_target,,,, 7)
  iminscore.set_valid_text("0123456789")
  imousegravity.register("Gravity ",, "Give gravity to the mouse", 554 + center, 138, 96, 32, @imousegravity_target)
  imousegravity.add_option("NC (no changes)", false)
  imousegravity.add_options(!"None\nS\nM\nL\nXL")
  itime_minutes.register("Time",, "Time limit: minutes (be generous)", 554 + center, 172, 64, 32, @itime_minutes_target)
  itime_minutes.add_option(!"NC (no changes)", false)
  For i As Integer = 0 To 10
    itime_minutes.add_option(Str(i))
  Next i
  itime_seconds.register("",, "Time limit: seconds", 554 + 64 + center, 172, 32, 32, @itime_seconds_target)
  itime_seconds.add_option("NC (no changes)", false)
  For i As Integer = 0 To 55 Step 10
    itime_seconds.add_option(Str(i))
  Next i
  ihead_special.register("Special",, "Special mode settings", 652 + center, 2, 96, 32, 0)
  ispecial_noballlose.register("No loss ",, "No loss until paddles are destroyed", 652 + center, 70, 96, 32, @ispecial_noballlose_target)
  ispecial_nobrickwin.register("No win  ",, "No victory from clearing level; points are required", 652 + center, 104, 96, 32, @ispecial_nobrickwin_target)
  ispecial_shooter.register("Shooter ",, "Enable shooter mode", 652 + center, 138, 96, 32, @ispecial_shooter_target)
  
  ihead_manage.register("Manage Levelpacks",, "Create multiple levelpacks", 2 + center, 308, 256, 32, 0)
  imanage_levelpack.register("Pack    ",, "Name a new levelpack", 2 + center, 376, 160, 32, 0,,,, 16)
  imanage_levelpack.set_valid_text(validchars_base)
  imanage_newlp.register("Create",, "Create a new levelpack with this name", 162 + center, 376, 96, 32, @imanage_newlp_target)
  imanage_gfxset.register("GFX Set ",, "Select the graphics for the new levelpack", 2 + center, 410, 256, 32, 0)
  l = Dir("data/graphics/*", &H10)
  While Len(l) > 0
    If l <> "." And l <> ".." Then imanage_gfxset.add_option(l)
    l = Dir()
  Wend
  imanage_gfxset.set_selected(1)
  imanage_deletelp.register("Delete  ",, "Delete a levelpack", 2 + center, 444, 256, 32, @imanage_deletelp_target)
  
  iclose.register("Close",, "Close the settings form", 652 + center, 308, 96, 32, @iclose_target)
  
  iform.set_visible(false)
End Sub

Sub itoolbar_type.register ()
  'register form and set selected
  
  pen = 1
  
  iform.register("",,, 0, 0, 1024, 36)
  
  iopensettings.register("Settings", Chr(19), "Level properties", 2, 2, 96, 32, @iopensettings_target)
  itest.register("Test", Chr(20), "Test play level", 100, 2, 96, 32, @itest_target)
  idone.register("Done/save", Chr(4), "Save and close level", 198, 2, 96, 32, @idone_target)
  iload.register("Clear/load", Chr(4), "Reset or load a level", 296, 2, 96, 32, @iload_target)
  
  ilayer.register("Layer   ", Chr(10), "Select layer to edit", 415, 2, 96, 32, @ilayer_target)
  ilayer.add_options(!"A\nB\nC\nD\nE\n\nMove up\nMove down\nChange auto-explode")
  ilayer.set_selected(1)
  ilayer.options.enabled(6) = false
  ilayersize.register("Size    ",, "Make room for more bricks", 513, 2, 96, 32, @ilayersize_target)
  'ilayersize.add_option("NC (no changes)", false)
  ilayersize.add_options(!"XS\nS\nM\nL\nXL\nCustom")
  
  'iobject.register("Pen     ", "p", "Toggle brick / item drawing", 534, 2, 96, 32, @iobject_target)
  'iobject.add_options(!"Brick\nItem")
  iobjectstyle.register("", Chr(13), "Brick or item type", 632, 2, 96, 32, @iobjectstyle_target,, "Default", false)
  iobjectscale.register("Size    ", Chr(2), "Brick size", 730, 2, 96, 32, 0)
  iobjectvalue.register("Value   ", Chr(22), "Brick value", 828, 2, 96, 32, 0) 'change title when item selected
  For i As Integer = 0 To 9
    iobjectscale.add_option(Str(i))
    iobjectvalue.add_option(Str(i))
  Next i
  iobjectscale.set_selected("4")
  iobjectvalue.set_selected("5")
  
  igridalign.register("Grid", Chr(7), "Align to grid?", 926, 2, 96, 32, 0,, true)
End Sub

Sub ibackgroundcolor_target ()
  Dim As Uinteger c
  
  Select Case isettings.ibackgroundcolor.get_selected_label()
  Case "Black":   c = &HFF000000
  Case "Gray":    c = &HFF888888
  Case "White":   c = &HFFFFFFFF
  Case "Red":     c = &HFFFF0000
  Case "Green":   c = &HFF00FF00
  Case "Blue":    c = &HFF0000FF
  Case "Cyan":    c = &HFF00FFFF
  Case "Magenta": c = &HFFFF00FF
  Case "Yellow":  c = &HFFFFFF00
  End Select
  
  level.backgroundcolor = c
End Sub

Sub ibackgroundimage_target ()
  dim as string b = isettings.ibackgroundimage.get_selected_label()
  if b = "(Browse...)" then
    isettings.ibackgroundimage.set_selected(level.backgroundimage)
    shell "start explorer """ & curdir() & "\data\graphics\" & level.levelpack.gfxset & "\backgrounds"""
  else
    if b = "(None)" then b = ""
    level.backgroundimage = b
  end if
End Sub

Sub ibackgroundimagetile_target ()
  level.backgroundimagetile = isettings.ibackgroundimagetile.get_checked()
End Sub

Sub iballmelee_target ()
  level.ballmelee = isettings.iballmelee.get_checked()
End Sub

Sub iballmultiplier_target ()
 ' if isettings.iballmultiplier.get_selected_index() > 1 then
    level.ballmultiplier = Val(isettings.iballmultiplier.get_selected_label())
 ' end if
End Sub

Sub iballscale_target ()
  Dim As Double d
  
  Select Case isettings.iballscale.get_selected_index()
  Case 2: d = .25
  Case 3: d = .5
  Case 4: d = 1
  Case 5: d = 2
  Case 6: d = 4
  End Select
  
  level.ballscale = d
End Sub

Sub iballspeed_target ()
 ' if isettings.iballspeed.get_selected_index() > 1 then
    level.ballspeed = Val(isettings.iballspeed.get_selected_label)
 ' end if
End Sub

Sub ibonuslives_target ()
 ' if isettings.ibonuslives.get_selected_index() > 1 then
    level.bonuslives = Val(isettings.ibonuslives.get_selected_label())
 ' end if
End Sub

Sub iclose_target ()
  With isettings
    itoolbar.iform.set_visible(.up)
    .up = Not .up
    .iform.set_visible(.up)
  End With
End Sub

Sub idone_target ()
  'done -> confirm level save / close, clear, ask to load level (and provide level selection)
  
  Dim As String l
  
  l = "Save """ & level.levelname & """ to """ & level.levelpack.pack & "/" & level.levelnumber & """ ("
  If level.levelnumber <= level.levelpack.leveltotal Then
    l += level.levelpack.level(level.levelnumber)
  Else
    l += "NEW LEVEL"
  End If
  If igui.utility_alert(l & ") and close level?", igui.vars.menus.menu_yesno,,, 1024) <> 1 Then Exit Sub
  
  With level
    .save(false)
    .startover()
    .setupgui()
  End With
  
  igui.utility_alert("Level saved.", igui.vars.menus.menu_ok,,, 256)
End Sub

sub ilayer_set ()
  dim as integer min, sec
  dim as string s, s2
  
  with itoolbar.ilayer
    for i as integer = 1 to level.layer_max
      s = chr(64 + i) + " Layer"
      if level.layer(i).autoexplode < 0 then
        s += " (Explodes in 0:00)"
      end if
      if level.layer(i).autoexplode > 0 then
        sec = level.layer(i).autoexplode mod 60
        min = level.layer(i).autoexplode \ 60
        s2 = min & ":"
        if sec < 10 then s2 += "0"
        s2 &= sec
        s += " (Explodes in " & s2 & ")"
      end if
      .options.options(i) = s
    next i
    
    .options.enabled(level.layer_max + 2) = (level.layer_selected > 1)
    .options.enabled(level.layer_max + 3) = (level.layer_selected < level.layer_max)
  end with
end sub

Sub ilayer_target ()
  dim as integer current, x
  Dim As igui.option_type o
  
  select case itoolbar.ilayer.get_selected_index() - level.layer_max
  case 1
  case 2
    'move up
    if level.layer_selected > 1 then
      swap level.layer(level.layer_selected), level.layer(level.layer_selected - 1)
      level.layer(level.layer_selected).redraw()
      level.layer_selected -= 1
      level.layer(level.layer_selected).redraw()
    end if
  case 3
    'move down
    if level.layer_selected < level.layer_max then
      swap level.layer(level.layer_selected), level.layer(level.layer_selected + 1)
      level.layer(level.layer_selected).redraw()
      level.layer_selected += 1
      level.layer(level.layer_selected).redraw()
    end if
  case 4
    'select auto-explode settings
    current = level.layer(level.layer_selected).autoexplode
    
    With o
      .total = 32
      .options(1) = "Set Auto-explode Delay for This Layer"
      .options(2) = "Disable"
      .options(3) = "Instant"
      for i as integer = 4 to 27
        .options(i) = ((i - 3) * 5) & " seconds"
      next i
      for i as integer = 28 to 32
        .options(i) = (i - 25) & " minutes"
      next i
      For i As Integer = 2 To .total
        .enabled(i) = true
      Next i
      .selected = 2
      if current < 0 then .selected = 3
      if current > 0 then .selected = (current \ 5) + 3
      if current > 120 then .selected = (current \ 60) + 25
    End With
    x = igui.utility_menu(o)
    
    current = 0
    if x > 2 then current = -1
    if x > 3 then current = (x - 3) * 5
    if x > 27 then current = (x - 25) * 60
    
    level.layer(level.layer_selected).autoexplode = current
  case else
    level.layer_selected = itoolbar.ilayer.get_selected_index()
    ilayersize_set()
  end select
  
  itoolbar.ilayer.set_selected(level.layer_selected)
  ilayer_set()
End Sub

Sub ilayersize_set ()
  With itoolbar
    .ilayersize.set_selected(1)
    If level.layer(.ilayer.get_selected_index()).brick.matrix_sx >= 3 Then .ilayersize.set_selected(2) 'int(6 * .6) = 3
    If level.layer(.ilayer.get_selected_index()).brick.matrix_sx >= 7 Then .ilayersize.set_selected(3) 'int(12 * .6) = 7
    If level.layer(.ilayer.get_selected_index()).brick.matrix_sx >= 14 Then .ilayersize.set_selected(4) 'int(24 * .6) = 14
    If level.layer(.ilayer.get_selected_index()).brick.matrix_sx >= 28 Then .ilayersize.set_selected(5) 'int(48 * .6) = 28
  End With
End Sub

Sub ilayersize_target ()
  With level.layer(itoolbar.ilayer.get_selected_index())
    .brick.matrix_set_size(itoolbar.ilayersize.get_selected_index())
    .redraw()
  End With
End Sub

Sub ilevelpack_target ()
  if isettings.ilevelpack.get_selected_label() = "Test" then
    igui.utility_alert("Cannot edit the test pack", igui.vars.menus.menu_ok,,, 512)
  else
    level.levelpack.load(isettings.ilevelpack.get_selected_label())
  end if
  level.setupgui() 'change gfxset, level number selector here
End Sub

Sub ilevelnumber_target ()
  level.levelnumber = isettings.ilevelnumber.get_selected_index()
End Sub

Sub ilevelname_target ()
  level.levelname = isettings.ilevelname.get_text()
End Sub

Sub iload_target ()
  Dim As Integer f = Freefile, selected
  Dim As String l
  Dim As igui.option_type o
  
  If igui.utility_alert("Clear the level editor and discard this level?", igui.vars.menus.menu_yesno,,, 512) <> 1 Then Exit Sub
  
  level.startover()
  
  If igui.utility_alert("Load a level to edit?", igui.vars.menus.menu_yesno,,, 256) <> 1 Then Exit Sub
  
  'select levelpack to load
  
  With o
    .total = 0
    .selected = 0
    Open "data/levelpacks/list.txt" For Input As #f
    While Not Eof(f)
      Line Input #f, l
      .total += 1
      .options(.total) = l
      .enabled(.total) = true
    Wend
    Close #f
  End With
  
  Do
    selected = igui.utility_menu(o)
  Loop Until selected > 0
  
  'pack will be reloaded; this just gets the level names for the new pack into memory
  level.levelpack.load(o.options(selected))
  
  'select level number to load
  
  With o
    .total = level.levelpack.leveltotal
    .selected = 0
    
    For i As Integer = 1 To level.levelpack.leveltotal
      .options(i) = i & ": " & level.levelpack.level(i)
      .enabled(i) = true
    Next i
  End With
  
  Do
    selected = igui.utility_menu(o)
  Loop Until selected > 0
  
  'load level
  level.load(level.levelpack.pack, selected)
End Sub

Sub imanage_deletelp_target ()
  'delete pack (remove from list without deleting any files)
  
  Const lp_max = 512
  
  Dim As Integer f = Freefile, lp_total
  Dim As String l, pack, lp(1 To lp_max)
  
  If isettings.imanage_deletelp.get_selected_index() <= 1 Then Exit Sub
  
  If igui.utility_alert("Delete this levelpack?", igui.vars.menus.menu_yesno,,, 256) <> 1 Then Exit Sub
  
  pack = isettings.imanage_deletelp.get_selected_label()
  
  'save list without the deleted pack
  
  Open "data/levelpacks/list.txt" For Input As #f
  While Not Eof(f)
    Line Input #f, l
    If l <> pack Then
      If lp_total < lp_max Then lp_total += 1
      lp(lp_total) = l
    End If
  Wend
  Close #f
  
  Open "data/levelpacks/list.txt" For Output As #f
  For i As Integer = 1 To lp_total
    Print #f, lp(i)
  Next i
  Close #f
End Sub

Sub imanage_newlp_target ()
  'create new levelpack, add to list, save levelpack
  
  Dim As Integer f = Freefile()
  Dim As String l, pack
  
  pack = Trim(isettings.imanage_levelpack.get_text())
  
  'check for null name
  If pack = "" Or Ucase(pack) = "TEST" Then
    igui.utility_alert("No levelpack name given", igui.vars.menus.menu_ok,,, 256)
    Exit Sub
  End If
  
  'check for existing name
  Open "data/levelpacks/list.txt" For Input As #f
  While Not Eof(f)
    Line Input #f, l
    If Ucase(pack) = Ucase(l) Then
      igui.utility_alert("The levelpack already exists", igui.vars.menus.menu_ok,,, 256)
      Exit Sub
    End If
  Wend
  Close #f
  
  'see if files exist
  If Open("data/levelpacks/" & Lcase(pack) & "/data.txt" For Input As #f) Then
    'error opening, pack doesn't exist
    Mkdir("data/levelpacks/" & Lcase(pack))
    Open "data/levelpacks/" & Lcase(pack) & "/data.txt" For Output As #f
    Print #f, 0
    Print #f, 0
    Print #f, isettings.imanage_gfxset.get_selected_label()
    Close #f
    'make recordings folder
    Mkdir("data/levelpacks/" & Lcase(pack) & "/recordings")
    Open "data/levelpacks/" & Lcase(pack) & "/recordings/list.txt" For Output As #f
    Close #f
  Else
    'file exists, don't create new file
    Close #f
  End If
  
  'add to list of levelpacks
  Open "data/levelpacks/list.txt" For Append As #f
  Print #f, isettings.imanage_levelpack.get_text()
  Close #f
  
  'cleanup
  isettings.imanage_levelpack.set_text("")
  level.setupgui()
  igui.utility_alert("Levelpack created", igui.vars.menus.menu_ok,,, 256)
End Sub

Sub iminscore_target ()
  level.minscore = Val(isettings.iminscore.get_text())
End Sub

Sub imousegravity_target ()
  Dim As Double s
  
  Select Case isettings.imousegravity.get_selected_index()
  Case 2: s = 0
  Case 3: s = .5
  Case 4: s = 1
  Case 5: s = 2
  Case 6: s = 4
  End Select
  
  level.mousegravity = s
End Sub

Sub iobjectstyle_target ()
  'was 6 * 11.25, now 7 * 10
  
  Static As Integer pp
  Static As mouse_type mouse_down
  
  Dim As Integer x, y, sx, sy, selected, tipx
  Dim As String key
  
  'this is called twice when it should be called once, so quit the first time
  'pp <> pen -> is the first call, else -> is the second call
  If pp <> itoolbar.pen Then
    'change detected - this sub causes the change
    pp = itoolbar.pen
    itoolbar.iform.focus()
    Exit Sub
  End If
  
  Do
    mouse_previous = mouse
    
    With mouse
      If Getmouse(.x, .y,, .b) Then mouse = mouse_previous
    End With
    
    sx = Int(7 * mouse.x / screen_sx)
    sy = Int(10 * mouse.y / screen_sy)
    selected = sy * 7 + sx + 1
    If selected > brick_type.style_max + item_enum.max Then selected = 0
    
    Screenlock
    Line (0, 0) - (screen_sx - 1, screen_sy - 1), color_enum.white, BF
    
    For i As Integer = 1 To brick_type.style_max
      x = ((i - 1) Mod 7)
      y = Int((i - 1) / 7)
      multiput(, _
      (x + .5) * screen_sx / 7, _
      (y + .5) * screen_sy / 10, _
      graphic.brick(i), screen_sx / (7 * graphic_type.brick_sx),,, Iif(selected = i, 100, 255))
    Next i
    For i As Integer = 1 To item_enum.max
      x = ((i + brick_type.style_max - 1) Mod 7)
      y = Int((i + brick_type.style_max - 1) / 7)
      multiput(, _
      (x + .5) * screen_sx / 7, _
      (y + .5) * screen_sy / 10, _
      graphic.item(i), screen_sx / (10 * graphic_type.brick_sx),,, Iif(selected = i + brick_type.style_max, 100, 255))
    Next i
    
    If selected > 0 Then
      tipx = mouse.x
      If tipx > screen_sx - Len(itoolbar.style(selected)) * 8 Then tipx = screen_sx - Len(itoolbar.style(selected)) * 8
      Line (tipx, mouse.y + 23) - Step(Len(itoolbar.style(selected)) * 8, 8), color_enum.white, BF
      Draw String (tipx, mouse.y + 24), itoolbar.style(selected), color_enum.black
    End If
    Screenunlock
    
    Sleep(20, 1)
    key = Inkey()
  Loop Until (mouse.b > 0 And mouse_previous.b = 0) Or key = Chr(27) Or key = Chr(255, 107)
  
  if selected = 0 then
    pp = -1 'will prevent this dialog from reopening instantly
    exit sub
  end if
  
  With itoolbar
    .pen = selected
    If mouse.b > 0 And mouse_previous.b = 0 And .pen <= brick_type.style_max + item_enum.max Then
      .iobjectstyle.set_text(.style(.pen))
      
      If .pen <= brick_type.style_max Then
        .iobjectscale.set_visible(true)
        .iobjectvalue.set_visible(true)
        .iobjectvalue.set_label("Value")
        .iobjectvalue.set_tooltip("Brick value")
      Else
        .iobjectscale.set_visible(false)
        Select Case .pen - brick_type.style_max
        Case item_enum.bonusbutton
          .iobjectvalue.set_visible(false)
        Case item_enum.brickmachine
          .iobjectvalue.set_visible(false)
        Case item_enum.portal, item_enum.portal_out
          .iobjectvalue.set_visible(true)
          .iobjectvalue.set_label("Set")
          .iobjectvalue.set_tooltip("Connect portals with matching set values")
        Case item_enum.gravity
          .iobjectvalue.set_visible(true)
          .iobjectvalue.set_label("Size")
          .iobjectvalue.set_tooltip("Gravity size")
        End Select
      End If
    End If
  End With
  
  itoolbar.iform.focus()
  waitforbuttonrelease()
  
  pp = -1
End Sub
'
'sub iobjectscale_target ()
'  
'end sub
'
'sub iobjectvalue_target ()
'  
'end sub
'
Sub iopensettings_target ()
  With isettings
    itoolbar.iform.set_visible(.up)
    .up = Not .up
    .iform.set_visible(.up)
  End With
End Sub

Sub ipaddlesides_target ()
  For i As Integer = 1 To 5
    If isettings.ipaddlesides(i).get_selected_index() > 1 Then
      level.paddlesides(i) = isettings.ipaddlesides(i).get_selected_index() - 2
    End If
  Next i
End Sub

Sub ipaddlescale_target ()
  Dim As Double d
  
  Select Case isettings.ipaddlescale.get_selected_index()
  Case 2: d = .25
  Case 3: d = .5
  Case 4: d = 1
  Case 5: d = 2
  Case 6: d = 4
  End Select
  
  level.paddlescale = d
End Sub

Sub ipaddlestyle_target ()
  level.paddlestyle = isettings.ipaddlestyle.get_selected_index()
End Sub

Sub ispecial_noballlose_target ()
  level.special_noballlose = isettings.ispecial_noballlose.get_checked()
End Sub

Sub ispecial_nobrickwin_target ()
  level.special_nobrickwin = isettings.ispecial_nobrickwin.get_checked()
End Sub

Sub ispecial_shooter_target ()
  level.special_shooter = isettings.ispecial_shooter.get_checked()
End Sub

Sub itest_target ()
  'test game: save temp, go into idle mode
  
  Const draw_x = 512 - 4 * 43
  
  Dim As Integer a, stat_brick_total, stat_brick_value, draw_y
  Dim As handle mytex
  Dim As String key
  
  Dim As Integer portal_in(0 To 9), portal_out(0 To 9)
  
  'calc how many bricks / points are given, right here
  
  For i As Integer = 1 To level.layer_max
    With level.layer(i).brick
      For x As Integer = 1 To .matrix_sx
        For y As Integer = 1 To .matrix_sy
          With .matrix(x, y)
            If .style > 0 Then
              stat_brick_total += 1
              stat_brick_value += .value
            End If
          End With
        Next y
      Next x
      
      For i2 As Integer = 1 To .list_total
        With .list(i2)
          If .x >= .5 And .y >= .5 And .x - .5 <= level.layer(i).brick.matrix_sx And .y - .5 <= level.layer(i).brick.matrix_sy Then
            If .style > 0 Then
              stat_brick_total += 1
              stat_brick_value += .value
            End If
          End If
        End With
      Next i2
    End With
  Next i
  
  Screenlock
  Cls
  Draw String (draw_x, 220), "Saved for Testing. Press key to continue...", color_enum.white
  Draw String (draw_x, 240), "Brick total: " & stat_brick_total & " / 2048", color_enum.white
  Draw String (draw_x, 250), "Brick value: " & stat_brick_value, color_enum.white
  Draw String (draw_x, 270), "Press 1 to inspect the level file", color_enum.white
  draw_y = 280
  
  a = 0
  For i As Integer = 1 To 5
    a += level.paddlesides(i)
  Next i
  If a = 0 Then
    draw_y += 10
    Draw String (draw_x, draw_y), "! No paddles in this level", color_enum.white
  End If
  
  If stat_brick_total = 0 Then
    draw_y += 10
    Draw String (draw_x, draw_y), "! No bricks in this level", color_enum.white
  End If
  
  If Trim(level.levelname) = "" Or Trim(level.levelname) = "Entitle Me!" Then
    draw_y += 10
    Draw String (draw_x, draw_y), "! No level name", color_enum.white
  End If
  
  'count portals; error reporting is in the next step
  For i As Integer = 1 To level.layer_max
    With level.layer(i).item
      For i2 As Integer = 1 To .list_total
        With .list(i2)
          Select Case .style
          Case 3
            If .d >= 0 And .d <= 9 Then portal_in(.d) += 1
          Case 4
            If .d >= 0 And .d <= 9 Then portal_out(.d) += 1
          End Select
        End With
      Next i2
    End With
  Next i
  
  'check portals: at most one portal target per set, need a portal in if there is an out, vv
  For i As Integer = 0 To 9
    If portal_in(i) = 0 And portal_out(i) > 0 Then
      draw_y += 10
      Draw String (draw_x, draw_y), "! Portal mismatch on set " & i & ": no portals", color_enum.white
    End If
    If portal_out(i) = 0 And portal_in(i) > 0 Then
      draw_y += 10
      Draw String (draw_x, draw_y), "! Portal mismatch on set " & i & ": no destination", color_enum.white
    End If
    If portal_out(i) > 1 Then
      draw_y += 10
      Draw String (draw_x, draw_y), "! Portal mismatch on set " & i & ": multiple destinations", color_enum.white
    End If
  Next i
  Screenunlock
  
  level.save(true)
  
  Do
    mytex = CreateMutex(NULL, TRUE, "_UltraBreakerTest")
    If mytex > 0 Then
      If GetLastError() = ERROR_ALREADY_EXISTS Then
        CloseHandle(mytex)
        mytex = 0
      End If
    End If
    Sleep(1, 1)
  Loop Until mytex > 0
  
  Do
    mouse_previous = mouse
    With mouse
      If Getmouse(.x, .y,, .b) Then mouse = mouse_previous
    End With
    
    Sleep(20, 1)
    key = Inkey()
  Loop Until (mouse.b > 0 And mouse_previous.b = 0) Or key = Chr(13) Or key = Chr(27) Or key = Chr(255, 107) Or key = "1"
  
  waitforbuttonrelease()
  
  If key = "1" Then Shell("start notepad data/levelpacks/test/1.txt")
  
  CloseHandle(mytex)
End Sub

Sub itime_minutes_target ()
  level.time_minutes = Val(isettings.itime_minutes.get_selected_label())
End Sub

Sub itime_seconds_target ()
  level.time_seconds = Val(isettings.itime_seconds.get_selected_label())
End Sub

Sub itip_target ()
  level.tip = isettings.itip.get_text()
End Sub

Sub itiplose_target ()
  level.tiplose = isettings.itiplose.get_text()
End Sub

Sub itipwin_target ()
  level.tipwin = isettings.itipwin.get_text()
End Sub

main_start()
main()
main_finish()
