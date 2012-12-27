
sub paddle_gfxchange_threadable (Byval nothing As Any Ptr = 0)
  paddle.gfxchange()
end sub

Sub paddle_type.start ()
  graphic.start()
End Sub

Sub paddle_type.reset ()
  data_defaultstyle = paddle_enum.normal
  data_sticky = false
  data_scale_original = scale_factor
  data_scale = data_scale_original
  For i As Integer = 1 To paddle_side_enum.max
    quantities(i) = 0
  Next i
  total = 0
End Sub

Sub paddle_type.gfxchange ()
  graphic.gfxchange()
End Sub

Sub paddle_type.reset2 ()
  graphic.gfxreset()
  addgroup()
End Sub

Sub paddle_type.add (Byval side As paddle_side_enum, Byval whichplayer As Integer = -1)
  
  Dim As Integer player1, player2
  
  If whichplayer > 0 Then
    player1 = whichplayer
    player2 = whichplayer
  Else
    player1 = 1
    player2 = setting.players
  End If
  
  For i As Integer = player1 To player2
    If total = max Then Exit Sub
    total += 1
    
    With object(total)
      Select Case side
      Case paddle_side_enum.top
        .xt = -paddle.data_scale * paddle.graphic.paddle_sx * .5
        .yt = paddle.data_scale * paddle.graphic.paddle_sy * .5
      Case paddle_side_enum.bottom
        .xt = -paddle.data_scale * paddle.graphic.paddle_sx * .5
        .yt = screen.default_sy - paddle.data_scale * paddle.graphic.paddle_sy * .5 - 1
      Case paddle_side_enum.left
        .xt = paddle.data_scale * paddle.graphic.paddle_sy * .5
        .yt = -paddle.data_scale * paddle.graphic.paddle_sx * .5
      Case paddle_side_enum.right
        .xt = screen.default_sx - paddle.data_scale * paddle.graphic.paddle_sy * .5 - 1
        .yt = -paddle.data_scale * paddle.graphic.paddle_sx * .5
      Case paddle_side_enum.center
        .xt = screen.default_sx * .5
        .yt = -paddle.data_scale * paddle.graphic.paddle_sx * .5
      End Select
      
      .side = side
      .style = data_defaultstyle
      
      .owner = i
      .lives = lives_max 'for laser attacks
      
      .x = .xt
      .y = .yt
      .xp = .xt
      .yp = .yt
      .xv = 0
      .yv = 0
      .offset = 0
      .killme = false
    End With
  Next i
End Sub

Sub paddle_type.move ()
  'move paddles, recreate gfx if the paddles change size
  
  Dim As Integer a
  Dim As Double scale
  
  'calculate the total paddles on each side, twice
  'because in the third nested loop here, we need the totals (s0) and the totals so far (s1)
  Dim As Integer s0(1 To paddle_side_enum.max), s1(1 To paddle_side_enum.max)
  
  For p As Integer = 1 To setting.players
    'part 1 - calculate the offset
    
    For i As Integer = 1 To paddle_side_enum.max
      s0(i) = 0
      s1(i) = 0
    Next i
    
    For i As Integer = 1 To paddle.total
      With object(i)
        If .owner = p Then s0(.side) += 1
      End With
    Next i
    
    scale = graphic.paddle_sx * data_scale
    For i As Integer = 1 To total
      With object(i)
        If .owner = p Then
          s1(.side) += 1
          .offset = Int(s1(.side) * .5) * scale
          if (s1(.side) and 1) = 0 then .offset *= -1
          if (s0(.side) and 1) = 0 then .offset += scale * .5
        End If
      End With
    Next i
  Next p
  
  'part 2 - move paddles
  'note: control and target coords move instantly; position gradually approaches them
  
  For i As Integer = 1 To total
    object(i).move()
  Next i
  
  'part 3 - delete some paddles
  
  a = 1
  While a <= total
    If object(a).killme Then
      if orb.total = 0 then sound.add(sound_enum.paddle_destroy)
      
      'release stuck balls
      For i As Integer = 1 To ball.total
        With ball.object(i)
          If .stuck = a Then
            .stuck = 0
            .instantrelease = false
          Elseif .stuck > a Then
            .stuck -= 1
          End If
        End With
      Next i
      
      explodepaddle.add(a)
      
      total -= 1
      For i As Integer = a To total
        object(i) = object(i + 1)
      Next i
    Else
      a += 1
    End If
  Wend
End Sub

Sub paddle_type.display ()
  #ifndef server_validator
  For i As Integer = total To 1 Step -1
    object(i).display()
  Next i
  #Endif
End Sub

Sub paddle_type.finish ()
  graphic.finish()
End Sub

Sub paddle_type.addgroup ()
  'guarantee that the player has at least as many paddles as when he started
  '(where quantities() defines the start total)
  'if he has more, he keeps them; all get full health
  'used for game start, and lifelost
  
  Dim As Integer current(1 To paddle_side_enum.max, 1 To setting.players), addtotal
  
  set_scale(data_scale_original)
  
  For i As Integer = 1 To total
    With object(i)
      current(.side, .owner) += 1
      .lives = lives_max
    End With
  Next i
  
  For i As Integer = 1 To setting.players
    For j As Integer = 1 To paddle_side_enum.max
      addtotal = quantities(j) - current(j, i)
      For k As Integer = 1 To addtotal
        add(j, i)
      Next k
    Next j
  Next i
End Sub

Sub paddle_type.set_scale (Byval scale As Double)
  'called by bonus collecting; will adjust gfx and paddle distance from edge of screen
  
  'scale = 1 for a paddle that appears at the original size (defined by png) at the default size
  
  If scale < scale_min Then scale = scale_min
  If scale > scale_max Then scale = scale_max
  
  If Abs(scale - data_scale) < 1E-9 And game.frametotal > 0 Then Exit Sub
  data_scale = scale
  
  For i As Integer = 1 To total
    With object(i)
      'the center paddle stays in the center regardless of size
      Select Case .side
      Case paddle_side_enum.top
        .yt = data_scale * paddle.graphic.paddle_sy * .5
      Case paddle_side_enum.bottom
        .yt = screen.default_sy - data_scale * paddle.graphic.paddle_sy * .5 - 1
      Case paddle_side_enum.left
        .xt = data_scale * paddle.graphic.paddle_sy * .5
      Case paddle_side_enum.right
        .xt = screen.default_sx - data_scale * paddle.graphic.paddle_sy * .5 - 1
      End Select
    End With
  Next i
  
  For i As Integer = 1 To ball.total
    ball.object(i).fixstuckposition()
  Next i
  
  If game.frametotal > 0 Then graphic.gfxreset()
End Sub

Sub paddle_type.set_defaultstyle (Byval style As paddle_enum)
  data_defaultstyle = style
  For i As Integer = 1 To total
    object(i).style = style
  Next i
End Sub

Sub paddle_graphic_type.start()
  'create images for bloading
  #ifndef server_validator
  For i As Integer = 1 To paddle_enum.max
    For i2 As Integer = -1 To 0
      paddle(i, i2) = utility.createimage(paddle_sx, paddle_sy mop("paddle"), 0)
    Next i2
  Next i
  #Endif
End Sub

Sub paddle_graphic_type.gfxchange()
  #ifndef server_validator
  #define g laser.graphic.laser
  
  'load new images
  utility.loadimage(main.levelpack.gfxset + "/paddles/normal", paddle(paddle_enum.normal, false))
  utility.loadimage(main.levelpack.gfxset + "/paddles/super", paddle(paddle_enum.super, false))
  
  For i As Integer = 1 To paddle_enum.max
    fadepaddle(paddle(i, false))
    
    'now create the version with lasers
    Put paddle(i, true), (0, 0), paddle(i, false), Pset
    Put paddle(i, true), (paddle_sx * .2 - (g -> Width) Shr 1, 0), g, alpha, 255
    Put paddle(i, true), (paddle_sx * .8 - (g -> Width) Shr 1, 0), g, alpha, 255
  Next i
  #Endif
End Sub

Sub paddle_graphic_type.gfxreset ()
  #ifndef server_validator
  'initialize the minis (but they will change in the game; this may also be called in-game)
  Dim As Integer sx, sy, mx, my
  Dim As Uinteger c, lx, ly, lx_max, ly_max
  Dim As Double angle, scale
  
  Dim As Uinteger Ptr g1, g2
  
  scale = ..paddle.data_scale * screen.scale
  sx = paddle_sx * scale
  sy = paddle_sy * scale
  mx = sx Shr 1
  my = sy Shr 1
  
  For x As Integer = 1 To paddle_enum.max
    For y As Integer = 1 To paddle_side_enum.max
      'load normal paddle for player 1, then invert colors for player 2
      
      If minis(1, x, y) > 0 Then utility.deleteimage(minis(1, x, y) mop("paddle mini"))
      
      If y >= paddle_side_enum.horizontal_first And y <= paddle_side_enum.horizontal_last Then
        minis(1, x, y) = utility.createimage(sx, sy mop("paddle mini"), color_enum.none)
      Else
        minis(1, x, y) = utility.createimage(sy, sx mop("paddle mini"), color_enum.none)
      End If
      
      Select Case y
      Case paddle_side_enum.top
        angle = pi
        multiput(minis(1, x, y), mx, my, paddle(x, laser.power > 0), scale,, angle)
      Case paddle_side_enum.bottom
        angle = 0
        multiput(minis(1, x, y), mx, my, paddle(x, laser.power > 0), scale,, angle)
      Case paddle_side_enum.left
        angle = pi * .5
        multiput(minis(1, x, y), my, mx, paddle(x, laser.power > 0), scale,, angle)
      Case paddle_side_enum.right
        angle = pi * 1.5
        multiput(minis(1, x, y), my, mx, paddle(x, laser.power > 0), scale,, angle)
      Case paddle_side_enum.center
        Put minis(1, x, y), (0, 0), minis(1, x, paddle_side_enum.left), Pset
        Put minis(1, x, y), (0, 0), minis(1, x, paddle_side_enum.right), (0, 0) - (my, sx), Pset
      End Select
      
      If setting.players = 2 Then
        If minis(2, x, y) > 0 Then utility.deleteimage(minis(2, x, y) mop("paddle mini"))
        
        If y >= paddle_side_enum.horizontal_first And y <= paddle_side_enum.horizontal_last Then
          minis(2, x, y) = utility.createimage(sx, sy mop("paddle mini"), color_enum.none)
        Else
          minis(2, x, y) = utility.createimage(sy, sx mop("paddle mini"), color_enum.none)
        End If
        
        g1 = cast(Uinteger Ptr, minis(1, x, y) + 1)
        g2 = cast(Uinteger Ptr, minis(2, x, y) + 1)
        lx_max = minis(1, x, y) -> Width - 1
        ly_max = minis(1, x, y) -> height - 1
        For ly = 0 To ly_max
          For lx = 0 To lx_max
            c = *(g1 + lx)
            *(g2 + lx) = (c And &HFF000000) Or ((c And &HF00000) Shr 2) Or ((c And &HF000) Shr 2) Or &HFF
          Next lx
          g1 += (minis(1, x, y) -> pitch) Shr 2
          g2 += (minis(2, x, y) -> pitch) Shr 2
        Next ly
      End If
    Next y
  Next x
  #Endif
End Sub

Sub paddle_graphic_type.finish ()
  #ifndef server_validator
  For i As Integer = 1 To paddle_enum.max
    For i2 As Integer = true To false
      utility.deleteimage(paddle(i, i2) mop("paddle"))
    Next i2
  Next i
  
  For i As Integer = 1 To 2
    For x As Integer = 1 To paddle_enum.max
      For y As Integer = 1 To paddle_side_enum.max
        If minis(i, x, y) > 0 Then utility.deleteimage(minis(i, x, y) mop("paddle mini"))
      Next y
    Next x
  Next i
  #Endif
End Sub

#ifndef server_validator
Sub paddle_graphic_type.fadepaddle (Byval thepaddlegraphic As fb.image Ptr)
  'set the alpha value to round the edges of the paddles
  
  Dim As Integer a, b, c', cr, cg, cb
  Dim As Double d
  
  Dim As Ubyte Ptr gp
  
  gp = cast(Ubyte Ptr, thepaddlegraphic + 1)
  
  For b = 0 To paddle_sy - 1
    For a = 0 To paddle_sx - 1
      If (*cast(Uinteger Ptr, gp + a Shl 2) And &HFFFFFF) = &HFF00FF Then Continue For
      
      Select Case a
      Case Is < .05 * paddle_sx
        d = (30 - Sqr((a - paddle_sx * .05) * _
          (a - paddle_sx * .05) + (b - 30) * (b - 30)))
      Case Is > .95 * paddle_sx
        d = (30 - Sqr((a - paddle_sx * .95) * _
          (a - paddle_sx * .95) + (b - 30) * (b - 30)))
      Case Else
        d = 30 - Abs(b - 30)
      End Select
      c = Int((d * setting.alphavalue * .5) ^ .8)
      If c < 0 Then
        'c = 0
        *cast(Uinteger Ptr, gp + a Shl 2) = &HFFFF00FF
      Else
        If c > 255 Then c = 255
        *(gp + a Shl 2 + 3) = c ' +3 to get to the alpha byte
      End If
    Next a
    
    gp += (thepaddlegraphic -> pitch)
  Next b
End Sub
#endif

sub paddle_object_type.move ()
  If side >= paddle_side_enum.horizontal_first And side <= paddle_side_enum.horizontal_last Then
    xt = game.control(owner).x + offset
  Else
    yt = game.control(owner).y + offset
  End If
  
  x += (xt - x) * paddle.slidefactor
  y += (yt - y) * paddle.slidefactor
  xv = x - xp
  yv = y - yp
  xp = x
  yp = y
  
  'calculate bounding box for collision detection
  x2 = paddle.graphic.paddle_sx * paddle.data_scale * .5
  y2 = paddle.graphic.paddle_sy * paddle.data_scale * .5
  If side >= paddle_side_enum.vertical_first And side <= paddle_side_enum.vertical_last Then
    Swap x2, y2
  End If
  x1 = x - x2
  y1 = y - y2
  x2 += x
  y2 += y
  
  'termination
  If lives <= 0 Then killme = true
end sub

sub paddle_object_type.display ()
  #ifndef server_validator
  var g = paddle.graphic.minis(owner, style, side)
  Put (screen.scale_x(x + xfx.camshake.x) - (g->Width Shr 1), _
    screen.scale_y(y + xfx.camshake.y) - (g->height Shr 1)), g, alpha
  #endif
end sub

function paddle_object_type.get_totalInstantReleaseBalls() as integer
  dim as integer index, r
  
  index = cast(integer, @this - @paddle.object(1)) + 1
  
  for i as integer = 1 to ball.total
    with ball.object(i)
      if .stuck = index and .instantrelease then r += 1
    end with
  next i
  
  return r
end function
