
' Multiput by Joshy (D. J. Peters)
' Alpha Blending by Counting_Pine
' Above said functions combined by Kristopher Windsor

'multiput(target, x, y, source, scale,, rotate, alpha)
'Sub _MultiPut(Byval lpTarget As Any Ptr = 0, _
'             Byval xMidPos  As Integer, _
'             Byval yMidPos  As Integer, _
'             Byval lpSource As Any Ptr, _
'             Byval xScale   As Single = 1, _
'             Byval yScale   As Single = 0, _ 'set to xScale value if not set
'             Byval Rotate   As Single = 0, _
'             Byval alphavalue As Integer = 255)



type sse_t field = 1
	s(0 to 3) as single
end type

type mmx_t field = 1
	i(0 to 1) as integer
end type

sub _multiput _
	( _
    byval dst as FB.IMAGE ptr = 0, _
    byval positx as integer, _
    byval posity as integer, _
    byval src as FB.IMAGE ptr, _
    byval zoomx as single = 1, _
    byval zoomy as single = 0, _
    byval angle as double = 0, _
    byval alphalvl as integer = 255 _
	)
    
	'Rotozoom for 32-bit FB.Image by Dr_D(Dave Stanley) and yetifoot(Simon Nash)
	'No warranty implied... use at your own risk ;) 
	dim as sse_t sse0, sse1, sse2, sse3, sse4, sse5
	dim as integer nx = any, ny = any, transcol = &hffff00ff
	dim as single tcdzx = any, tcdzy = any, tsdzx = any, tsdzy = any
	dim as integer sw2 = any, sh2 = any, dw = any, dh = any
	dim as single tc = any, ts = any
	dim as uinteger ptr dstptr = any, srcptr = any
	dim as integer startx = any, endx = any, starty = any, endy = any
	dim as integer x(3), y(3)
	dim as integer xa = any, xb = any, ya = any, yb = any
	dim as integer dstpitch = any
	dim as integer srcpitch = any, srcwidth = any, srcheight = any
	dim as ulongint mask1 = &H00FF00FF00FF00FFULL'&H000000FF00FF00FFULL mask change copies src alpha
	dim as integer x_draw_len = any, y_draw_len = any
	dim as short alphalevel(3) = {alphalvl, alphalvl, alphalvl, alphalvl}
    
	if zoomx <= .0001 or alphalvl <= 0 or alphalvl > 255 then exit sub
  if zoomy <= .0001 then zoomy = zoomx
  
	if dst = 0 then
		dstptr = screenptr
		screeninfo dw,dh,,,dstpitch
  else
		dstptr = cast( uinteger ptr, dst + 1 )
		dw = dst->width
		dh = dst->height
		dstpitch = dst->pitch
  end if
    
	srcptr = cast( uinteger ptr, src + 1 )
    
	sw2 = src->width\2
	sh2 = src->height\2
	srcpitch = src->pitch
	srcwidth = src->width
	srcheight = src->height
    
	tc = cos( -angle )
	ts = sin( -angle )
	tcdzx = tc/zoomx
	tcdzy = tc/zoomy
	tsdzx = ts/zoomx
	tsdzy = ts/zoomy
    
	xa = sw2 * tc * zoomx + sh2  * ts * zoomx
	ya = sh2 * tc * zoomy - sw2  * ts * zoomy
    
	xb = sh2 * ts * zoomx - sw2  * tc * zoomx
	yb = sw2 * ts * zoomy + sh2  * tc * zoomy
    
	x(0) = sw2-xa
	x(1) = sw2+xa
	x(2) = sw2-xb
	x(3) = sw2+xb
	y(0) = sh2-ya
	y(1) = sh2+ya
	y(2) = sh2-yb
	y(3) = sh2+yb
    
	for i as integer = 0 to 3
		for j as integer = i to 3
			if x(i)>=x(j) then
				swap x(i), x(j)
            end if
        next
    next
	startx = x(0)
	endx = x(3)
    
	for i as integer = 0 to 3
		for j as integer = i to 3
			if y(i)>=y(j) then
				swap y(i), y(j)
            end if
        next
    next
	starty = y(0)
	endy = y(3)
    
	positx-=sw2
	posity-=sh2
	if posity+starty<0 then starty = -posity
	if positx+startx<0 then startx = -positx
	if posity+endy<0 then endy = -posity
	if positx+endx<0 then endx = -positx
    
	if positx+startx>(dw-1) then startx = (dw-1)-positx
	if posity+starty>(dh-1) then starty = (dh-1)-posity
	if positx+endx>(dw-1) then endx = (dw-1)-positx
	if posity+endy>(dh-1) then endy = (dh-1)-posity
	if startx = endx or starty = endy then exit sub
    
	ny = starty - sh2
	nx = startx - sw2
    
	dstptr += dstpitch * (starty + posity) \ 4
    
	x_draw_len = (endx - startx)' + 1
	y_draw_len = (endy - starty)' + 1
    
	sse1.s(0) = tcdzx
	sse1.s(1) = tsdzx
    
	sse2.s(0) = -(ny * tsdzy)
	sse2.s(1) = (ny * tcdzy)
    
	sse3.s(0) = -tsdzy
	sse3.s(1) = tcdzy
    
	sse4.s(0) = (nx * tcdzx) + sw2
	sse4.s(1) = (nx * tsdzx) + sh2
    
	if x_draw_len = 0 then exit sub
	if y_draw_len = 0 then exit sub
    
	cptr( any ptr, dstptr ) += (startx + positx) * 4
    
	dim as any ptr ptr row_table = callocate( srcheight * sizeof( any ptr ) )
	dim as any ptr p = srcptr
    
	for i as integer = 0 to srcheight - 1
		row_table[i] = p
		p += srcpitch
    next i
    
	asm
		.balign 4
        
        movups xmm1, [sse1]
        movups xmm2, [sse2]
        movups xmm3, [sse3]
        movups xmm4, [sse4]
        
		.balign 4
		y_inner4:
        
        ' _mx = nxtc + sw2
        ' _my = nxts + sh2
        movaps xmm0, xmm4
        
        ' _dstptr = cptr( any ptr, dstptr )
        mov edi, dword ptr [dstptr]
        
        ' _x_draw_len = x_draw_len
        mov ecx, dword ptr [x_draw_len]
        
        ' _mx += -nyts
        ' _my += nytc
        addps xmm0, xmm2
        
		.balign 4
		x_inner4:
        
        ' get _mx and _my out of sse reg
        cvtps2pi mm0, xmm0
        
        ' mx = mmx0.i(0)
        movd esi, mm0
        
        ' shift mm0 so my is ready
        psrlq mm0, 32
        
        ' if (mx >= srcwidth) or (mx < 0) then goto no_draw3
        cmp esi, dword ptr [srcwidth]
        jae no_draw4
        
        ' my = mmx0.i(1)
        movd edx, mm0
        
        ' if (my >= srcheight) or (my < 0) then goto no_draw3
        cmp edx, dword ptr [srcheight]
        jae no_draw4
        
        ' _srcptr = srcbyteptr + (my * srcpitch) + (mx shl 2)
        shl esi, 2
        mov eax, dword ptr [row_table]
        add esi, dword ptr [eax+edx*4]
        
        '_srccol = *cptr( uinteger ptr, _srcptr )
        mov eax, dword ptr [esi]
        
'        ' if (_srccol and &HFF000000) = 0 then goto no_draw3
'        test eax, &HFF000000
'        jz no_draw4
        
        ' if _srccol = transcol then goto no_draw3
        cmp eax, dword ptr [transcol]
        je no_draw4
        
        ' blend
        
        ' load src pixel and dst pixel mmx, with unpacking
        punpcklbw mm0, dword ptr [esi]
        punpcklbw mm1, dword ptr [edi]
        
        ' shift them to the right place
        psrlw mm0, 8                ' mm0 = 00sa00sr00sg00sb
        psrlw mm1, 8                ' mm1 = 00da00dr00dg00db
        
        ' Prepare alpha
	
  
  
        'changed by mysoft
        movq mm2, [alphalevel]      ' mm2 = 00sa00xx00xx00xx
        'punpckhwd mm2, mm2          ' mm2 = 00sa00sa00xx00xx
        'punpckhdq mm2, mm2          ' mm2 = 00sa00sa00sa00sa
        
        
        
        
        ' Perform blend
        psubw mm0, mm1              ' (sX - dX)
        pmullw mm0, mm2             ' (sX - dX) * sa
        psrlq mm0, 8                ' mm0 = 00aa00rr00gg00bb
        paddw mm0, mm1              ' ((sX - dX) * sa) + dX
        pand mm0, qword ptr [mask1] ' mask off alpha and high parts
        
        ' repack to 32 bit
        packuswb mm0, mm0
        
        ' store in destination
        movd dword ptr [edi], mm0
        
		.balign 4
		no_draw4:
        
        ' _mx += tcdzx
        ' _my += tsdzx
        addps xmm0, xmm1
        
        ' _dstptr += 4
        add edi, 4
        
        ' _x_draw_len -= 1
        sub ecx, 1
        
        jnz x_inner4
        
		x_end4:
        
        ' nyts += tsdzy
        ' nytc += tcdzy
        addps xmm2, xmm3
        
        ' cptr( any ptr, dstptr ) += dstpitch
        mov eax, dword ptr [dstpitch]
        add dword ptr [dstptr], eax
        
        ' y_draw_len -= 1
        sub dword ptr [y_draw_len], 1
        
        jnz y_inner4
        
		y_end4:
        
        emms
    end asm
    
	deallocate( row_table )
    
end sub

'Sub _MultiPut(Byval lpTarget As Any Ptr = 0, _
'             Byval xMidPos  As Integer, _
'             Byval yMidPos  As Integer, _
'             Byval lpSource As Any Ptr, _
'             Byval xScale   As Single = 1, _
'             Byval yScale   As Single = 0, _ 'set to xScale value if not set
'             Byval Rotate   As Single = 0, _
'             Byval alphavalue As Integer = 255)
'
'  If alphavalue < -1 Or alphavalue > 255 Then Exit Sub
'  If xScale < 0.001 Then xScale = 0.001
'  If yScale = 0 Then yScale = xScale
'  If yScale < 0.001 Then yScale = 0.001
'
'  if abs(xscale - 1) < 1E-9 and abs(yscale - 1) < 1E-9 and abs(rotate) < 1E-9 then
'    'print xmidpos - (cptr(fb.image ptr, lpsource) -> width) shr 1
'    'sleep 1000
'    'cls
'    
'    put lpTarget, (xmidpos - (cptr(fb.image ptr, lpsource) -> width) shr 1, _
'      ymidpos - (cptr(fb.image ptr, lpsource) -> height) shr 1), _
'      lpsource, alpha, alphavalue
'    '  print rnd
'    'sleep 3000
'    exit sub
'  end if
'
'  Dim As Integer MustRotate, MustLock
'
'  'variables for the alpha blending
'  Dim As Uinteger srb = Any
'  Dim As Uinteger drb = Any
'  Dim As Uinteger rb = Any
'  Dim As Uinteger sr = Any, sg = Any, sb = Any, sa = Any, sa2 = Any
'  Dim As Uinteger dr = Any, dg = Any, db = Any, da = Any, da2 = Any
'  Dim As Uinteger r = Any,  g = Any,  b = Any,  a = Any
'
'  If lpTarget= 0 Then MustLock = 1
'  If Rotate <> 0 Then MustRotate = 1
'
'  Dim As Integer  TargetWidth,TargetHeight,TargetPitch
'
'  If MustLock Then
'    Screeninfo    _
'    TargetWidth , _
'    TargetHeight,,, _
'    TargetPitch
'    lpTarget=Screenptr
'  Else
'    TargetWidth  = Cptr(Uinteger Ptr,lpTarget)[2]
'    TargetHeight = Cptr(Uinteger Ptr,lpTarget)[3]
'    TargetPitch  = Cptr(Uinteger Ptr,lpTarget)[4]
'    lpTarget    += 32
'  End If
'
'  Dim As Integer   SourceWidth,SourceHeight,SourcePitch
'  If Cptr(Integer Ptr,lpSource)[0] = 7 Then
'    SourceWidth  = Cptr(Uinteger Ptr,lpSource)[2]
'    SourceHeight = Cptr(Uinteger Ptr,lpSource)[3]
'    SourcePitch  = Cptr(Uinteger Ptr,lpSource)[4]
'    lpSource    += 32
'  Else
'    SourceWidth  = Cptr(Ushort Ptr,lpSource)[0] Shr 3
'    SourceHeight = Cptr(Ushort Ptr,lpSource)[1]
'    SourcePitch  = SourceWidth
'    lpSource    += 2
'  End If
'#define xs 0 'screen
'#define ys 1
'#define xt 2 'texture
'#define yt 3
'  Dim As Single Points(3,3)
'  points(0,xs)=-SourceWidth/2 * xScale
'  points(1,xs)= SourceWidth/2 * xScale
'  points(2,xs)= points(1,xs)
'  points(3,xs)= points(0,xs)
'
'  points(0,ys)=-SourceHeight/2 * yScale
'  points(1,ys)= points(0,ys)
'  points(2,ys)= SourceHeight/2 * yScale
'  points(3,ys)= points(2,ys)
'
'  points(1,xt)= SourceWidth-1
'  points(2,xt)= points(1,xt)
'  points(2,yt)= SourceHeight-1
'  points(3,yt)= points(2,yt)
'
'  Dim As Uinteger i
'  Dim As Single x,y
'  If MustRotate Then
'    For i=0 To 3
'      x=points(i,xs)*Cos(Rotate) - points(i,ys)*Sin(Rotate)
'      y=points(i,xs)*Sin(Rotate) + points(i,ys)*Cos(Rotate)
'      points(i,xs)=x:points(i,ys)=y
'    Next
'  End If
'
'  Dim As Integer yStart,yEnd,xStart,xEnd
'  yStart=100000:yEnd=-yStart:xStart=yStart:xEnd=yEnd
'
'#define LI 0   'LeftIndex
'#define RI 1   'RightIndex
'#define  IND 0 'Index
'#define NIND 1 'NextIndex
'  Dim As Integer CNS(1,1) 'Counters
'
'  For i=0 To 3
'    points(i,xs)=Int(points(i,xs)+xMidPos)
'    points(i,ys)=Int(points(i,ys)+yMidPos)
'    If points(i,ys)<yStart Then yStart=points(i,ys):CNS(LI,IND)=i
'    If points(i,ys)>yEnd   Then yEnd  =points(i,ys)
'    If points(i,xs)<xStart Then xStart=points(i,xs)
'    If points(i,xs)>xEnd   Then xEnd  =points(i,xs)
'  Next
'  If yStart =yEnd         Then Exit Sub
'  If yStart>=TargetHeight Then Exit Sub
'  If yEnd   <0            Then Exit Sub
'  If xStart = xEnd        Then Exit Sub
'  If xStart>=TargetWidth  Then Exit Sub
'  If xEnd   <0            Then Exit Sub
'
'  Dim As Ubyte    Ptr t1,s1
'  Dim As Ushort   Ptr t2,s2
'  Dim As Uinteger Ptr t4,s4
'
'
'#define ADD 0
'#define CMP 1
'#define SET 2
'  Dim As Integer ACS(1,2) 'add compare and set
'  ACS(LI,ADD)=-1:ACS(LI,CMP)=-1:ACS(LI,SET)=3
'  ACS(RI,ADD)= 1:ACS(RI,CMP)= 4:ACS(RI,SET)=0
'
'#define EX  0
'#define EU  1
'#define EV  2
'#define EXS 3
'#define EUS 4
'#define EVS 5
'  Dim As Single E(2,6),S(6),Length,uSlope,vSlope
'  Dim As Integer U,UV,UA,UN,V,VV,VA,VN
'  
'  ' share the same highest point
'  CNS(RI,IND)=CNS(LI,IND)
'
'  ' loop from Top to Bottom
'  While yStart<yEnd
'    'Scan Left and Right sides together
'    For i=LI To RI
'      ' bad to read but fast and short ;-)
'      If yStart=points(CNS(i,IND),ys) Then
'        CNS(i,NIND)=CNS(i,IND)+ACS(i,Add)
'        If CNS(i,NIND)=ACS(i,CMP) Then CNS(i,NIND)=ACS(i,SET)
'        While points(CNS(i,IND),ys) = points(CNS(i,NIND),ys)
'          CNS(i, IND)=CNS(i,NIND)
'          CNS(i,NIND)=CNS(i, IND)+ACS(i,Add)
'          If CNS(i,NIND)=ACS(i,CMP) Then CNS(i,NIND)=ACS(i,SET)
'        Wend
'        E(i,EX) = points(CNS(i, IND),xs)
'        E(i,EU) = points(CNS(i, IND),xt)
'        E(i,EV) = points(CNS(i, IND),yt)
'        Length  = points(CNS(i,NIND),ys)
'        Length -= points(CNS(i, IND),ys)
'        If Length <> 0.0 Then
'          E(i,EXS) = points(CNS(i, NIND),xs)-E(i,EX):E(i,EXS)/=Length
'          E(i,EUS) = points(CNS(i, NIND),xt)-E(i,EU):E(i,EUS)/=Length
'          E(i,EVS) = points(CNS(i, NIND),yt)-E(i,EV):E(i,EVS)/=Length
'        End If
'        CNS(i,IND)=CNS(i,NIND)
'      End If
'    Next
'
'    If (yStart<0)                              Then Goto SkipScanLine
'    xStart=E(LI,EX)+0.5:If xStart>=TargetWidth Then Goto SkipScanLine
'    xEnd  =E(RI,EX)-0.5:If xEnd  < 0           Then Goto SkipScanLine
'    If (xStart=xEnd)                           Then Goto SkipScanLine
'
'    Length=xEnd-xStart
'    uSlope=E(RI,EU)-E(LI,EU):uSlope/=Length
'    vSlope=E(RI,EV)-E(LI,EV):vSlope/=Length
'    If xstart<0 Then
'      Length=Abs(xStart)
'      U=Int(E(LI,EU)+uSlope*Length)
'      V=Int(E(LI,EV)+vSlope*Length)
'      xStart = 0
'    Else
'      U=Int(E(LI,EU)):V=Int(E(LI,EV))
'    End If
'    If xEnd>=TargetWidth Then xEnd=TargetWidth-1
'    UV=Int(uSlope):UA=(uSlope-UV)*10000:UN=0
'    VV=Int(vSlope):VA=(vSlope-VV)*10000:VN=0
'    xEnd-=xStart
'
'    t4=Cptr(Integer Ptr,lpTarget)+yStart*(TargetPitch Shr 2)+xStart:xStart=0
'    select case alphavalue
'    case 255
'      While xStart<xEnd
'        s4=Cptr(Integer Ptr,lpSource)+V*(SourcePitch Shr 2)+U
'        If (*s4 And &HFFFFFF) <> &HFF00FF Then *t4 = *s4
'        U+=UV:UN+=UA:If UN>=10000 Then U+=1:UN-=10000
'        V+=VV:VN+=VA:If VN>=10000 Then V+=1:VN-=10000
'        If u<0 Then u=0
'        If v<0 Then v=0
'        xStart+=1:t4+=1
'      Wend
'    case -1
'      While xStart<xEnd
'        s4=Cptr(Integer Ptr,lpSource)+V*(SourcePitch Shr 2)+U
'        If (*s4 And &HFFFFFF) <> &HFF00FF Then
'          '***** start alpha blending
'          sa = *s4 shr 24
'          da = 256 - sa
'          
'          srb = *s4 And &h00ff00ff
'          sg  = *s4 Xor srb
'
'          drb = *t4 And &h00ff00ff
'          dg  = *t4 Xor drb
'
'          rb = (drb * da + srb * sa) And &hff00ff00
'          g  = (dg  * da + sg  * sa) And &h00ff0000
'
'          *t4 = (rb Or g) Shr 8 Or &hff000000
'          '***** end alpha blending
'        End If
'        U+=UV:UN+=UA:If UN>=10000 Then U+=1:UN-=10000
'        V+=VV:VN+=VA:If VN>=10000 Then V+=1:VN-=10000
'        If u<0 Then u=0
'        If v<0 Then v=0
'        xStart+=1:t4+=1
'      Wend
'    case else
'      sa  = alphavalue
'      da  = 256 - sa
'      
'      While xStart<xEnd
'        s4=Cptr(Integer Ptr,lpSource)+V*(SourcePitch Shr 2)+U
'        If (*s4 And &HFFFFFF) <> &HFF00FF Then
'          '***** start alpha blending
'          srb = *s4 And &h00ff00ff
'          sg  = *s4 Xor srb
'
'          drb = *t4 And &h00ff00ff
'          dg  = *t4 Xor drb
'
'          rb = (drb * da + srb * sa) And &hff00ff00
'          g  = (dg  * da + sg  * sa) And &h00ff0000
'
'          *t4 = (rb Or g) Shr 8 Or &hff000000
'          '***** end alpha blending
'        End If
'        U+=UV:UN+=UA:If UN>=10000 Then U+=1:UN-=10000
'        V+=VV:VN+=VA:If VN>=10000 Then V+=1:VN-=10000
'        If u<0 Then u=0
'        If v<0 Then v=0
'        xStart+=1:t4+=1
'      Wend
'    end select
'    
'    SkipScanLine:
'    E(LI,EX)+=E(LI,EXS):E(LI,EU)+=E(LI,EUS):E(LI,EV)+=E(LI,EVS)
'    E(RI,EX)+=E(RI,EXS):E(RI,EU)+=E(RI,EUS):E(RI,EV)+=E(RI,EVS)
'    yStart+=1:If yStart=TargetHeight Then yStart=yEnd 'exit loop
'  Wend
'End Sub
