
' Alpha (Bitmap) Font
' By Leonheart
' OOP and enhancements by Kristopher Windsor

#Include once "abfont.bi"
'#Include once "abfont_defaultfont.bas"

namespace abfont

Constructor alpha_font ()
  Dim buffer As Ubyte Ptr
  
  'precalculate some alpha blending
  For i As Integer = 0 To 255
    ALPHA_MULTIPLIER_255(i) = i / &hFF
    IALPHA_MULTIPLIER_255(i) = (&hFF - i) / &hFF
  Next i
End Constructor

Destructor alpha_font ()
  Dim As Ushort i, n 'fixed 0.1.1
  For i = 0 To font_slot_max
    If alpha_font(i).loaded = false Then Continue For
    
    For n = 0 To 255
      If ALPHA_FONT(i).DataSequence(n).Width > 0 Then 
        Deallocate(ALPHA_FONT(i).DataSequence(n).Data)
      End If
    Next n
  Next i
End Destructor

Sub alpha_font.draw Overload (ALPHA_ACTIVE_FONT As Integer = 0, x As Short, y As Short, s As String, _
  Byval tcolor As Uinteger = &HFF000000, Byval bcolor As Uinteger = 0)
  
  'default target is 0 (which means to use screenptr)
  Draw(0, ALPHA_ACTIVE_FONT, x, y, s, tcolor, bcolor)
End Sub

Sub alpha_font.draw Overload (Byval target As fb.image Ptr, ALPHA_ACTIVE_FONT As Integer = 0, x As Short, y As Short, s As String, _
  Byval tcolor As Uinteger = &HFF000000, Byval bcolor As Uinteger = 0)
  
  Dim ALPHA_SCREEN_WIDTH As Integer
  Dim ALPHA_SCREEN_HEIGHT As Integer
  
  Dim ALPHA_FONT_FORECOLOR As ALPHA_FONT_COLOR
  Dim ALPHA_FONT_BACKCOLOR As ALPHA_FONT_COLOR
  
  Dim StartPitch  As Short
  Dim CharCount   As Ushort
  Dim CharSelect  As Ubyte
  Dim As Ubyte    R,G,B
  Dim As Single   R1,G1,B1
  Dim As Uinteger Col
  Dim As Uinteger i,n,m,bx,by
  Dim As Uinteger yp,xp,pp
  Dim As Uinteger yfp
  Dim As Uinteger fontptr
  Dim As Ubyte    AlphaVal
  Dim As Single   Alpha1,Alpha2,Alpha3,Alpha4
  Dim As Uinteger ColorTemp
  Dim As Short    xtmp,ytmp
  Dim As Uinteger Ptr buffer
  Dim As Integer pitch
  
  If ALPHA_FONT(ALPHA_ACTIVE_FONT).loaded = false Then Exit Sub
  If ALPHA_FONT(ALPHA_ACTIVE_FONT).Header.FontHeight = false Then Exit Sub
  
  If target = 0 Then
    buffer = Screenptr()
    If buffer = 0 Then Exit Sub
    Screeninfo(ALPHA_SCREEN_WIDTH, ALPHA_SCREEN_HEIGHT,,, pitch)
  Else
    ALPHA_SCREEN_WIDTH = target -> Width
    ALPHA_SCREEN_HEIGHT = target -> height
    pitch = target -> pitch
    buffer = cast(Uinteger Ptr, target + 1)
  End If
  pitch Shr= 2
  
  With ALPHA_FONT_FORECOLOR
    .Red   = (tcolor Shr 16) And &HFF
    .Green = (tcolor Shr 8) And &HFF
    .Blue  = tcolor And &HFF
    .Alpha = (tcolor Shr 24) And &HFF
    .AlphaMultiplierA = ALPHA_MULTIPLIER_255(.alpha)  
    .AlphaMultiplierB = ALPHA_MULTIPLIER_255(&HFF - .Alpha) 
  End With
  With ALPHA_FONT_BACKCOLOR
    .Red   = (bcolor Shr 16) And &HFF
    .Green = (bcolor Shr 8) And &HFF
    .Blue  = bcolor And &HFF
    .Alpha = (bcolor Shr 24) And &HFF
    .AlphaMultiplierA = ALPHA_MULTIPLIER_255(.alpha)  
    .AlphaMultiplierB = ALPHA_MULTIPLIER_255(&HFF - .Alpha) 
  End With
  
  'blend
  If ALPHA_FONT_BACKCOLOR.Alpha=&hFF Then'opaque
    m=GetTextWidth(ALPHA_ACTIVE_FONT, s)
    'note: this line added by Kristopher Windsor
    If x + m >= ALPHA_SCREEN_WIDTH Then m = ALPHA_SCREEN_WIDTH - x - 1
    xtmp=x-1
    ytmp=y-1
    With ALPHA_FONT_BACKCOLOR
      ColorTemp=Rgb(.Red,.Green,.Blue)
    End With
    For i = 1 To ALPHA_FONT(ALPHA_ACTIVE_FONT).Header.FontHeight  'yloop
      yp=(i+ytmp)*pitch'ALPHA_SCREEN_WIDTH
      For n= 1 To m
        pp = n + xtmp + yp
        buffer[pp]=ColorTemp                
      Next n
    Next i 
  Elseif ALPHA_FONT_BACKCOLOR.Alpha>&h0 Then'blend
    m=GetTextWidth(ALPHA_ACTIVE_FONT, s)
    'note: this line added by Kristopher Windsor
    If x + m >= ALPHA_SCREEN_WIDTH Then m = ALPHA_SCREEN_WIDTH - x - 1
    xtmp=x-1
    ytmp=y-1
    With ALPHA_FONT_BACKCOLOR
      R1=.AlphaMultiplierA*.Red    
      G1=.AlphaMultiplierA*.Green
      B1=.AlphaMultiplierA*.Blue
    End With
    For i = 1 To ALPHA_FONT(ALPHA_ACTIVE_FONT).Header.FontHeight  'yloop
      yp=(i+ytmp)*pitch'ALPHA_SCREEN_WIDTH
      For n= 1 To m
        pp = n + xtmp + yp
        Col = buffer[pp] And &HFFFFFF 'Xor &hFF000000
        With ALPHA_FONT_BACKCOLOR
          R = ((Col Shr 16)*.AlphaMultiplierB)                + R1  
          G = (((Col And &HFF00) Shr 8)*.AlphaMultiplierB)      + G1
          B = ((Col Shl 24 Shr 24)*.AlphaMultiplierB)    + B1              
        End With
        buffer[pp]=Rgb(R,G,B)                
      Next n
    Next i
  End If
  
  StartPitch = x
  For CharCount=1 To Len(s)
    CharSelect=Asc(s,CharCount)
    StartPitch+=ALPHA_FONT(ALPHA_ACTIVE_FONT).DataSequence(CharSelect).Start
    With ALPHA_FONT(ALPHA_ACTIVE_FONT).DataSequence(CharSelect)
      For i = .Top To .Top +.Height -1'y
        If .Height =0 Then Exit For
        yp= y+i
        If yp>=ALPHA_SCREEN_HEIGHT Or yp< 0 Then Exit For 'fixed in version 0.0.2
        yp*=pitch'ALPHA_SCREEN_WIDTH
        yfp=(i-.top) * .Width 
        For n = 0 To .Width -1 'x
          xp=StartPitch + n
          If xp>=ALPHA_SCREEN_WIDTH Then Exit For 'fixed in version 0.0.2
          pp=xp+yp                        
          fontptr=n+yfp
          If ALPHA_FONT_FORECOLOR.Alpha > 0 Then
            If ALPHA_FONT_FORECOLOR.Alpha = &hFF Then 
              'opaque
              AlphaVal=ALPHA_FONT(ALPHA_ACTIVE_FONT).DataSequence(CharSelect).Data[fontptr]
              If AlphaVal<&hFF Then
                If AlphaVal=0 Then
                  '100% opaque
                  With ALPHA_FONT_FORECOLOR
                    buffer[pp]=Rgb(.Red,.Green,.Blue)
                  End With 
                Else
                  'blend
                  Col = buffer[pp] And &HFFFFFF 'Xor &hFF000000
                  With ALPHA_FONT_FORECOLOR
                    R = ((Col Shr 16) * ALPHA_MULTIPLIER_255(AlphaVal)) + (IALPHA_MULTIPLIER_255(AlphaVal)*.Red)  
                    G = (((Col And &HFF00) Shr 8) * ALPHA_MULTIPLIER_255(AlphaVal)) + (IALPHA_MULTIPLIER_255(AlphaVal)*.Green)
                    B = ((Col Shl 24 Shr 24) * ALPHA_MULTIPLIER_255(AlphaVal)) + (IALPHA_MULTIPLIER_255(AlphaVal)*.Blue)              
                  End With
                  buffer[pp]=Rgb(R,G,B)
                End If
              End If
            Else
              'blending method
              AlphaVal=ALPHA_FONT(ALPHA_ACTIVE_FONT).DataSequence(CharSelect).Data[fontptr]
              If AlphaVal<&hff Then
                If AlphaVal=0 Then
                  Col = buffer[pp] And &HFFFFFF 'Xor &hFF000000
                  With ALPHA_FONT_FORECOLOR
                    R = ((Col Shr 16) * IALPHA_MULTIPLIER_255(.Alpha)) + (ALPHA_MULTIPLIER_255(.Alpha)*.Red)  
                    G = (((Col And &HFF00) Shr 8) * IALPHA_MULTIPLIER_255(.Alpha)) + (ALPHA_MULTIPLIER_255(.Alpha)*.Green)
                    B = ((Col Shl 24 Shr 24) * IALPHA_MULTIPLIER_255(.Alpha)) + (ALPHA_MULTIPLIER_255(.Alpha)*.Blue)              
                  End With
                  buffer[pp] = Rgb(R, G, B)    
                Else
                  Col = buffer[pp] And &HFFFFFF 'Xor &hFF000000
                  Alpha1=IALPHA_MULTIPLIER_255(AlphaVal)*ALPHA_MULTIPLIER_255(ALPHA_FONT_FORECOLOR.Alpha)
                  Alpha2=1-Alpha1
                  With ALPHA_FONT_FORECOLOR
                    R = ((Col Shr 16  )*Alpha2)   + (Alpha1*.Red)
                    G = (((Col And &HFF00) Shr 8)*Alpha2)      + (Alpha1*.Green)     
                    B = ((Col Shl 24 Shr 24)*Alpha2)                + (Alpha1*.Blue)               
                  End With
                  buffer[pp] = Rgb(R, G, B)  
                End If
              End If
            End If
          End If
        Next n
      Next i
    End With 
    StartPitch+=ALPHA_FONT(ALPHA_ACTIVE_FONT).DataSequence(CharSelect).Pitch    
    If StartPitch > ALPHA_SCREEN_WIDTH Then Exit For
  Next CharCount
End Sub

Function alpha_font.LoadFont Overload (Byref DataPtr As Ubyte Ptr, FontIndex As Ubyte) As Integer
  Dim As Ushort i
  Dim ALPHA_FONT_HEADER_TEMP(alpha_font_header.size) As Ubyte
  
  For i = 0 To alpha_font_header.size
    ALPHA_FONT_HEADER_TEMP(i)=DataPtr[i]
  Next i
  
  If backend_loadfont_header(ALPHA_FONT_HEADER_TEMP(), FontIndex) Then Return true
  Return backend_loadfont_body(DataPtr,FontIndex)
End Function

Function alpha_font.LoadFont Overload (Byval Filename As String, Byval FontIndex As Ubyte) As Integer
  '0 = success, 1 = File not found, 2 = File Corrupted
  
  Dim As Longint FL
  Dim As Integer FF
  Dim As Ubyte Ptr MyPtr 
  
  Dim ALPHA_FONT_HEADER_TEMP(alpha_font_header.size) As Ubyte
  
  '&h01 Or &h02 Or &h04 = 7
  If Dir(Filename, 7) = "" Then
    errorlog("Font file: not found")
    Return true
  End If
  
  FL = FileLen(Filename)
  If FL <= alpha_font_header.size Then
    errorlog("Font file: corrupted (file is too small)")
    Return true
  End If
  
  'read header
  FF = Freefile
  Open filename For Binary As #FF Len=Len(Ubyte)
  Get #FF,1,ALPHA_FONT_HEADER_TEMP()
  If backend_loadfont_header(ALPHA_FONT_HEADER_TEMP(), FontIndex) Then
    Close #FF
    errorlog("Font file: corrupted (cannot read the font header)")
    Return true
  End If
  
  If (ALPHA_FONT(FontIndex).Header.Checksum + alpha_font_header.size + 1) = FL Then
    'load file
    MyPtr=Allocate(FL*Len(Ubyte))
    Get #FF,1,*MyPtr,FL
    Close #1
    backend_loadfont_body(MyPtr,FontIndex)
    Deallocate(MyPtr)
    Return false            
  Else
    Close #FF
    errorlog("Font file: corrupted (file size mismatch)" & fl & ":" & (ALPHA_FONT(FontIndex).Header.Checksum + alpha_font_header.size + 1))
    Return true
  End If
  
  Return false
End Function

Sub alpha_font.UnloadFont(Byval FontIndex As Ubyte)
  Dim As Ushort n
  
  If ALPHA_FONT(FontIndex).loaded = false Then Exit Sub
  
  For n = 0 To 255
    If ALPHA_FONT(FontIndex).DataSequence(n).Data > 0 Then
      If ALPHA_FONT(FontIndex).DataSequence(n).Width > 0 Then 
        Deallocate (ALPHA_FONT(FontIndex).DataSequence(n).Data)
      End If
    End If
  Next n
  
  ALPHA_FONT(FontIndex).loaded = false 'use of EMPTY_FONT is expensive
End Sub

Sub alpha_font.errorlog (Byref e As String)
  errormessage = e
End Sub

Function alpha_font.errorcheck () As String
  Function = errormessage
  errormessage = "" 'return each error only once
End Function

Function alpha_font.GetTextHeight (font_index As Integer) As Ushort
  Return ALPHA_FONT(font_index).Header.FontHeight
End Function

Function alpha_font.GetTextWidth(font_index As Integer, Byref s As String) As Ushort
  Dim As Ushort i, n, l
  
  n=Len(s)
  For i = 1 To n
    With ALPHA_FONT(font_index).DataSequence(Asc(s,i))
      If i<n Then
        l+=.Start + .Pitch
      Else
        If .pitch < (.Width-.start) Then
          l += .Width-.start
        Else
          l += .Start + .Pitch
        End If
      End If
    End With        
  Next i
  
  Return l
End Function

Function alpha_font.GetFontName (font_index As Integer) As String
  Return ALPHA_FONT(font_index).Header.FontName
End Function

Function alpha_font.GetFontSize (font_index As Integer) As Ushort
  Return ALPHA_FONT(font_index).Header.FontSize
End Function

Function alpha_font.GetFontBoldFlag (font_index As Integer) As Integer
  Return ALPHA_FONT(font_index).Header.FontFlag And 1
End Function

Function alpha_font.GetFontItalicFlag (font_index As Integer) As Integer 'v0.1.1
  If (ALPHA_FONT(font_index).Header.FontFlag And 2) > 0 Then
    Return 1
  Else
    Return 0
  End If
End Function

Function alpha_font.GetFontUnderlineFlag (font_index As Integer) As Integer
  If (ALPHA_FONT(font_index).Header.FontFlag And 4) > 0 Then
    Return 1
  Else
    Return 0
  End If
End Function

Function alpha_font.GetFontStrikeOutFlag (font_index As Integer) As Integer
  If (ALPHA_FONT(font_index).Header.FontFlag And 8) > 0 Then
    Return 1
  Else
    Return 0
  End If
End Function

Sub alpha_font.GetAlphaBitmapFontLibVer(Byref Major As Uinteger, Byref Minor As Uinteger, _
  Byref Build As Uinteger, Byref Message As String)
  Major = ALPHA_FONT_BITMAP_VERSION_MAYOR
  Minor = ALPHA_FONT_BITMAP_VERSION_MINOR
  Build = ALPHA_FONT_BITMAP_VERSION_BUILD
  Message = ALPHA_FONT_BITMAP_VERSION_MSG
End Sub

Function alpha_font.GetFontDevMsg (font_index As Integer) As String
  Return ALPHA_FONT(font_index).Header.DeveloperMessage
End Function

Private Function alpha_font.backend_loadfont_body (Byref DataPtr As Ubyte Ptr, FontIndex As Ubyte) As Integer
  Dim As Ushort w, h, p, t, s
  Dim i As Uinteger
  Dim n As Ushort
  Dim posisi As Uinteger
  
  If ALPHA_FONT(FontIndex).Loaded = true Then
    errorlog("Create font: slot already used")
    Return true
  End If
  
  posisi = alpha_font_header.size + 1
  While n < 256
    p=Cvshort(Chr(DataPtr[posisi])  & Chr$(DataPtr[posisi+1]))
    s=Cvshort(Chr(DataPtr[posisi+2])  & Chr$(DataPtr[posisi+3]))
    t=Cvshort(Chr(DataPtr[posisi+4])  & Chr$(DataPtr[posisi+5]))
    w=Cvshort(Chr(DataPtr[posisi+6])  & Chr$(DataPtr[posisi+7]))
    h=Cvshort(Chr(DataPtr[posisi+8])  & Chr$(DataPtr[posisi+9]))
    posisi += 10
    'prepare memory (don't do this; if a font is already in this slot, then the code would have exited earlier)
    'If ALPHA_FONT(FontIndex).DataSequence(n).Width > 0 Then 'improve safe thread [v0.1.1]
    '  Deallocate (ALPHA_FONT(FontIndex).DataSequence(n).Data)
    'End If
    If (w>0) Or (h>0) Then
      ALPHA_FONT(FontIndex).DataSequence(n).Data = Allocate(w * h * Len(Ubyte))
      For i = 0 To (w*h)-1
        ALPHA_FONT(FontIndex).DataSequence(n).Data[i]=DataPtr[posisi]
        posisi=posisi+1  
      Next i
    End If
    'copy pitch,start,top,width,height
    With ALPHA_FONT(FontIndex).DataSequence(n)
      .pitch=p
      .Start=s
      .Top=t
      .Width=w
      .Height=h
    End With 
    n += 1
  Wend
  
  ALPHA_FONT(FontIndex).Loaded = true
  Return false
End Function

Private Function alpha_font.backend_loadfont_header(ALPHA_FONT_HEADER_TEMP() As Ubyte, _
  Byval FontIndex As Ubyte) As Integer
  
  'puts the font header from a temporary array into a font slot
  
  Dim i As Ushort
  Dim tmp As ALPHA_FONT_HEADER
  
  If ALPHA_FONT(FontIndex).Loaded = true Then
    errorlog("Create font: slot already used")
    Return true
  End If
  
  For i=0 To 2
    tmp.Signature[i]=ALPHA_FONT_HEADER_TEMP(i)
  Next i
  
  If tmp.signature <> "ABF" Then
    errorlog("Font: wrong signature")
    Return true
  End If
  
  For i=0 To 2
    tmp.FileVersion[i]=ALPHA_FONT_HEADER_TEMP(i+3)
  Next i
  
  If tmp.FileVersion <> "0.2" Then 'file supported
    errorlog("Font: wrong version")
    Return true   
  End If
  
  tmp.CRC = *cast(Uinteger Ptr, @ALPHA_FONT_HEADER_TEMP(6))
  tmp.checksum = *cast(Uinteger Ptr, @ALPHA_FONT_HEADER_TEMP(10))
  
  For i=0 To 254
    tmp.DeveloperMessage[i]=ALPHA_FONT_HEADER_TEMP(i+14)
    tmp.FontName[i]=ALPHA_FONT_HEADER_TEMP(i+269)
  Next i
  
  tmp.FontSize=Cvshort(Chr(ALPHA_FONT_HEADER_TEMP(524)) & Chr$(ALPHA_FONT_HEADER_TEMP(525)))
  tmp.FontHeight=Cvshort(Chr(ALPHA_FONT_HEADER_TEMP(526)) & Chr$(ALPHA_FONT_HEADER_TEMP(527)))
  tmp.FontWeight=Cvshort(Chr(ALPHA_FONT_HEADER_TEMP(528)) & Chr$(ALPHA_FONT_HEADER_TEMP(529)))
  tmp.FontFlag=ALPHA_FONT_HEADER_TEMP(530)
  
  ALPHA_FONT(FontIndex).Header = tmp
  
  Return false
End Function

End namespace
