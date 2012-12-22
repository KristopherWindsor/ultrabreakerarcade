
sub xfx_gfxchange_threadable (Byval nothing As Any Ptr = 0)
  xfx.gfxchange()
end sub

Sub xfx_type.start ()
  graphic.start()
End Sub

Sub xfx_type.screenchange ()
  graphic.screenchange()
End Sub

Sub xfx_type.gfxchange ()
  graphic.gfxchange()
End Sub

Sub xfx_type.reset ()
  camshake.reset()
  flyingbrick.reset()
  nuke.reset()
  particle.reset()
End Sub

Sub xfx_type.move ()
  camshake.move()
  flyingbrick.move()
  nuke.move()
  particle.move()
End Sub

Sub xfx_type.finish ()
  graphic.finish()
End Sub

Sub xfx_camshake_type.reset ()
  shake = 0
  angle = 0
End Sub

Sub xfx_camshake_type.add (Byval effect As double)
  shake += effect * sizefactor
End Sub

Sub xfx_camshake_type.move ()
  angle += pi / 6
  shake *= .96
  x = Cos(angle) * shake
  y = Sin(angle) * shake
End Sub

Sub xfx_flyingbrick_type.reset ()
  total = 0
  total_previous = 0
End Sub

Sub xfx_flyingbrick_type.add (Byref brick As brick_object_type)
  
  If setting.flyingbricks = false Then Exit Sub
  If total = max Then Exit Sub
  
  total += 1
  With flyingbrick_object(total)
    .x = brick.x
    .y = brick.y
    
    .angle = 0
    .xv = brick.hit_shadow_xv
    .yv = brick.hit_shadow_yv
    .anglev = brick.hit_shadow_spin
    
    .graphic_mini = brick.graphic_mini
    .killme = false
  End With
End Sub

Sub xfx_flyingbrick_type.move ()
  
  Dim As Integer a, s1, s2
  
  If setting.flyingbricks = false Then Exit Sub
  
  If total_previous + 1 < total Then
    s1 = total_previous + 1
    s2 = total
    While s2 - s1 > 0
      Swap flyingbrick_object(s1), flyingbrick_object(s2)
      s1 += 1
      s2 -= 1
    Wend
  End If
  
  For i As Integer = 1 To total
    With flyingbrick_object(i)
      .yv += game.gravityfactor
      .x += .xv
      .y += .yv
      .angle += .anglev * .01
      If .y > screen.default_sy * 1.2 Then .killme = true
    End With
  Next i
  
  a = 1
  While a <= total
    If flyingbrick_object(a).killme Then
      total -= 1
      For i As Integer = a To total
        flyingbrick_object(i) = flyingbrick_object(i + 1)
      Next i
    Else
      a += 1
    End If
  Wend
  
  total_previous = total
End Sub

Sub xfx_flyingbrick_type.display ()
  #ifndef server_validator
  
  Static As Integer x, y, x1, x2, x3, x4, y1, y2, y3, y4
  Static As Double bx, by
  
  Dim As Integer f
  
  If setting.flyingbricks = false Then Exit Sub
  
  With game.framerate
    f = ((.t - .t_start) * brick_graphic_type.frame_ratefactor) Mod 6 + 1
  End With
  
  For i As Integer = total To 1 Step -1
    With flyingbrick_object(i)
      x = screen.scale_x(.x + xfx.camshake.x)
      y = screen.scale_y(.y + xfx.camshake.y)
      
      Select Case setting.flyingbricks
      Case 1
        bx = (brick.graphic.mini(.graphic_mini).b.g(1) -> Width)
        by = (brick.graphic.mini(.graphic_mini).b.g(1) -> height)
        
        x1 = x + (bx * Cos(.angle) + by * Sin(.angle)) * .5
        y1 = y + (bx * Sin(.angle) - by * Cos(.angle)) * .5
        x2 = x + (bx * Cos(.angle) - by * Sin(.angle)) * .5
        y2 = y + (bx * Sin(.angle) + by * Cos(.angle)) * .5
        x3 = x - (bx * Cos(.angle) + by * Sin(.angle)) * .5
        y3 = y - (bx * Sin(.angle) - by * Cos(.angle)) * .5
        x4 = x - (bx * Cos(.angle) - by * Sin(.angle)) * .5
        y4 = y - (bx * Sin(.angle) + by * Cos(.angle)) * .5
        
        Line (x1, y1) - (x2, y2), color_enum.black
        Line (x2, y2) - (x3, y3), color_enum.black
        Line (x3, y3) - (x4, y4), color_enum.black
        Line (x4, y4) - (x1, y1), color_enum.black
      Case 2
        multiput(, x, y, brick.graphic.mini(.graphic_mini).b.g(f),,, .angle)
      End Select
    End With
  Next i
  #Endif
End Sub

Sub xfx_graphic_type.start ()
  #ifndef server_validator
  nuke = utility.createimage(nuke_sd, nuke_sd mop("nuke"))
  #Endif
End Sub

Sub xfx_graphic_type.screenchange ()
  #ifndef server_validator
  Dim As Integer sr = glow_sr * screen.scale, sd = glow_sd * screen.scale
  
  If glow > 0 Then utility.deleteimage(glow mop("glow"))
  glow = utility.createimage(sd, sd mop("glow"), 0)
  
  'glow
  For d As Double = sr To 1 Step -1
    Circle glow, (sr, sr), d, Rgba(255, 255, 255, 200 * (sr - d) / sr),,, 1, F
  Next d
  #Endif
End Sub

Sub xfx_graphic_type.gfxchange ()
  #ifndef server_validator
  utility.loadimage(main.levelpack.gfxset & "/nuke", nuke)
  #Endif
End Sub

Sub xfx_graphic_type.finish ()
  #ifndef server_validator
  utility.deleteimage(glow mop("glow"))
  utility.deleteimage(nuke mop("nuke"))
  #Endif
End Sub

Sub xfx_graphic_type.effect_grayscale ()
  #ifndef server_validator
  
  Static As Ulongint MAXALPHA = &hFF000000FF000000ull
  Static As Ulongint MAXCOMP =  &h000000FF000000FFull
  
  Dim As Uinteger c, pt, weight
  Dim As Uinteger Ptr dataptr
  
  dataptr = Screenptr()
  pt = screen.screen_sx * screen.screen_sy
  Asm
    mov edi,[dataptr]       'buffer ptr
    mov ecx,[pt]            'pixel counter
    Shr ecx,1
    movq mm6,[MAXCOMP]
    movq mm7,[MAXALPHA]
    _xgtem_next_pixelm2_:   'go next pixel
    movq mm0,[edi]           'load org pixel
    movq mm1,mm0             'add get blue
    pand mm1,mm6            '
    psrld mm0,8             '\
    movq mm2,mm0            'add green
    pand mm2,mm6            '
    paddd mm1,mm2           '/
    psrld mm1,1             'bg average
    psrld mm0,8             '\
    pand mm0,mm6            'add blue
    paddd mm1,mm0           '
    psrld mm1,1               'bg average (BW/METAL)
    movq mm0,mm1            ' \
    pslld mm1,8             ' |
    paddd mm0,mm1           ' |
    pslld mm1,8             ' |
    paddd mm0,mm1           ' |
    por mm0, mm7            ' /
    movq [edi],mm0          ' \
    add edi,8               ' |
    dec ecx                 ' / save pixel
    jnz _xgtem_next_pixelm2_
    emms
  End Asm
'  For i As Integer = 1 To pt
'    c = *dataptr
'    weight = ((c And &HFF) + ((c And &HFF00) Shr 8) + ((c And &HFF0000) Shr 16)) \ 3
'    *dataptr = &H010101 * weight
'    dataptr += 1
'  Next i
  #Endif
End Sub

Sub xfx_graphic_type.effect_inverse ()
  #ifndef server_validator
  
  Dim As Uinteger c, pt, weight
  Dim As Uinteger Ptr dataptr
  
  dataptr = Screenptr()
  pt = screen.screen_sx * screen.screen_sy
  For i As Integer = 1 To pt
    *dataptr Xor= &HFFFFFF
    dataptr += 1
  Next i
  #Endif
End Sub

Sub xfx_graphic_type.effect_metal ()
  #ifndef server_validator
  
  Static As Ulongint MAXALPHA = &hFF000000FF000000ull
  Static As Ulongint MAXCOMP =  &h000000FF000000FF
  
  Dim As Uinteger c, pt, weight
  Dim As Uinteger Ptr dataptr
  
  dataptr = Screenptr()
  pt = screen.screen_sx * screen.screen_sy
  Asm
    mov edi,[dataptr]       'buffer ptr
    mov ecx,[pt]            'pixel counter
    Shr ecx,1
    movq mm6,[MAXCOMP]
    movq mm7,[MAXALPHA]
    _xgtem_next_pixelm_:   'go next pixel
    movq mm0,[edi]           'load org pixel
    movq mm1,mm0             'add get blue
    pand mm1,mm6            '
    psrld mm0,8             '\
    movq mm2,mm0            'add green
    pand mm2,mm6            '
    paddd mm1,mm2           '/
    psrld mm1,1             'bg average
    psrld mm0,8             '\
    pand mm0,mm6            'add blue
    paddd mm1,mm0           '
    'psrld mm1,1               'bg average (BW/METAL)
    movq mm0,mm1            ' \
    pslld mm1,8             ' |
    paddd mm0,mm1           ' |
    pslld mm1,8             ' |
    paddd mm0,mm1           ' |
    por mm0, mm7            ' /
    movq [edi],mm0          ' \
    add edi,8               ' |
    dec ecx                 ' / save pixel
    jnz _xgtem_next_pixelm_
    emms
  End Asm
'  For i As Integer = 1 To pt
'    c = *dataptr
'    weight = ((c And &HFF) + ((c And &HFF00) Shr 8) + ((c And &HFF0000) Shr 16)) \ 3
'    *dataptr = &H020202 * weight
'    dataptr += 1
'  Next i
  #Endif
End Sub

'Function palettecolor (Byval c As Integer) As Uinteger
'  Const pmax = 16
'  
'  Static As Uinteger pc(1 To pmax) = {&HFF000000, &HFF0000AA, &HFF00AA00, &HFF00AAAA, _
'    &HFFAA0000, &HFFAA00AA, &HFFAA5500, &HFFAAAAAA, &HFF555555, &HFF5555FF, _
'    &HFF55FF55, &HFF55FFFF, &HFFFF5555, &HFFFF55FF, &HFFFFFF55, &HFFFFFFFF}, pc_one
'  Static As Uinteger diff(1 To pmax)
'  Dim As Uinteger diff_closest = 1, diff_amount = 768
'  
'  For i As Integer = 1 To pmax
'    pc_one = pc(i)
'    diff(i) = _
'      Abs(((pc_one Shr 16) And &HFF) - ((c Shr 16) And &HFF)) + _
'      Abs(((pc_one Shr 8) And &HFF) - ((c Shr 8) And &HFF)) + _
'      Abs((pc_one And &HFF) - (c And &HFF))
'  Next i
'  
'  For i As Integer = 1 To pmax
'    If diff(i) < diff_amount Then
'      diff_amount = diff(i)
'      diff_closest = i
'    End If
'  Next i
'  
'  Return pc(diff_closest)
'End Function

Sub xfx_graphic_type.effect_pixelation ()
  #ifndef server_validator
  Dim As Integer mx, my, p
  Dim As Uinteger c, cr, cg, cb, ix, iy, x, y
  Dim As Uinteger Ptr s = Screenptr, s2
  
  Screeninfo(mx, my,,, p)
  p Shr= 2
  
  For x = 0 To mx - 8 Step 8
    For y = 0 To my - 8 Step 8
      cr = 0
      cg = 0
      cb = 0
      
      s2 = s + y * p
      For iy = 0 To 7
        For ix = x To x + 7
          c = *(s2 + ix)
          cr += (c Shr 16) And &HFF
          cg += (c Shr 8) And &HFF
          cb += c And &HFF
        Next ix
        s2 += p
      Next iy
      
      cr Shr= 6
      cg Shr= 6
      cb Shr= 6
      c = Rgb(cr, cg, cb)
      'c = palettecolor(c)
      
      s2 = s + y * p
      For iy = 0 To 7
        For ix = x To x + 7
          *(s2 + ix) = c
        Next ix
        s2 += p
      Next iy
    Next y
  Next x
  #Endif
End Sub

Sub xfx_graphic_type.glow_show (Byval x As Integer, Byval y As Integer)
  #ifndef server_validator
  If setting.ballglow = false Then Exit Sub
  Put (screen.scale_x(x) - (glow -> Width) Shr 1, screen.scale_y(y) - (glow -> height) Shr 1), glow, alpha
  #Endif
End Sub

Sub xfx_nuke_type.reset ()
  total = 0
End Sub

Sub xfx_nuke_type.add (Byval x As Integer, Byval y As Integer)
  If setting.extras = false Then Return
  
  If total = max Then Exit Sub
  total += 1
  
  With object(total)
    .x = x
    .y = y
    .s = 0
    .rotation = 0
    .ttl = ttl_max
  End With
End Sub

Sub xfx_nuke_type.move ()
  Dim As Integer a
  
  For i As Integer = 1 To total
    With object(i)
      .s += scalefactor
      .rotation += rotationfactor
      .ttl -= 1
    End With
  Next i
  
  a = 1
  While a <= total
    If object(a).ttl <= 0 Then
      total -= 1
      For i As Integer = a To total
        object(i) = object(i + 1)
      Next i
    Else
      a += 1
    End If
  Wend
End Sub

Sub xfx_nuke_type.display ()
  #ifndef server_validator
  For i As Integer = total To 1 Step -1
    With object(i)
      multiput(, screen.scale_x(.x), screen.scale_y(.y), _
        xfx.graphic.nuke, .s * screen.scale,, .rotation, .ttl * 2)
    End With
  Next i
  #Endif
End Sub

Sub xfx_particle_type.reset ()
  total = 0
End Sub

Sub xfx_particle_type.add (Byval x As Integer, Byval y As Integer)
  If total = max Or setting.particles = false Then Exit Sub
  
  total += 1
  With particle_object(total)
    .x = x
    .y = y
    .d = 0
  End With
End Sub

Sub xfx_particle_type.move ()
  Dim As Integer a = 1
  
  While a <= total
    If particle_object(a).d > maxdist Then
      particle_object(a) = particle_object(total)
      total -= 1
    Else
      particle_object(a).d += velocity
      a += 1
    End If
  Wend
End Sub

Sub xfx_particle_type.display (Byval c As Uinteger = color_enum.black)
  #ifndef server_validator
  Dim As Integer s
  
  s = Int(size * screen.scale + .5)
  If s > 2 Then s = 2
  If s < 1 Then s = 1
  
  For a As Integer = total To 1 Step -1
    For d As Double = 0 To pi * 2 Step pi / 12
      Circle ( _
        screen.scale_x(particle_object(a).x + Cos(d) * particle_object(a).d + xfx.camshake.x), _
        screen.scale_y(particle_object(a).y + Sin(d) * particle_object(a).d + xfx.camshake.y) _
        ), s, c,,, 1, F
    Next d
  Next a
  #Endif
End Sub

property xfx_camshake_type.x () as integer
  static as integer ft', total
  
'  if ft <> game.frametotal then
'    open "camshake.txt" for append as #33
'    print #33, requestotal
'    close #33
'    requestotal = 0
'    ft = game.frametotal
'  end if
  
  requestotal += 1
  
  return _x
end property

property xfx_camshake_type.x (xx as integer)
  _x = xx
end property
