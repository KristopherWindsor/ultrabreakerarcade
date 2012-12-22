
' Image Scaler! v1.1b
' (C) 2008 Innova and Kristopher Windsor

#define float double
#define cfloat Cdbl

Sub image_scaler Overload (Byval itarget As fb.image Ptr = 0, Byval x As Integer = 0, Byval y As Integer = 0, Byval isource As fb.image Ptr, Byval scale As float)
  Dim As Integer dest_size_x, dest_size_y, dest_realsize_x, dest_realsize_y
  Dim As Integer dest_loop_x, dest_loop_y
  Dim As Integer srce_size_x, srce_size_y
  Dim As Integer srce_loop_x, srce_loop_y
  Dim As Integer dest_pitch, srce_pitch
  Dim As Integer srce_color
  Dim As Integer dest_loop_x1, dest_loop_y1, dest_loop_x2, dest_loop_y2
  Dim As float red, green, blue
  Dim As float x1, y1, x2, y2, overlap_factor, total_pixels
  Dim As float overlap_1, overlap_2, overlap_3, overlap_4, overlap_5, overlap_6 'temp variables to see how much of a certain source pixel overlaps a destination pixel
  Dim As Uinteger Ptr dest_ptr, srce_ptr
  
  If isource = 0 Then
    Screeninfo(srce_size_x, srce_size_y,,, srce_pitch)
    srce_ptr = Screenptr
  Else
    srce_size_x = isource -> Width
    srce_size_y = isource -> height
    srce_pitch = isource -> pitch
    srce_ptr = cast(Uinteger Ptr, isource + 1)
  End If
  srce_pitch Shr= 2
  
  If itarget = 0 Then
    Screeninfo(dest_realsize_x, dest_realsize_y,,, dest_pitch)
    dest_ptr = Screenptr
  Else
    dest_realsize_x = itarget -> Width
    dest_realsize_y = itarget -> height
    dest_pitch = itarget -> pitch
    dest_ptr = cast(Uinteger Ptr, itarget + 1)
  End If
  dest_pitch Shr= 2
  dest_ptr += x + y * dest_pitch
  
  'real size was used for clipping; now use this for other things
  dest_size_x = srce_size_x * scale
  dest_size_y = srce_size_y * scale
  
  'clipping
  dest_loop_x1 = 0
  dest_loop_x2 = dest_size_x - 1
  If dest_loop_x1 + x < 0 Then dest_loop_x1 = -x
  If dest_loop_x1 + x > dest_realsize_x - 1 Then dest_loop_x1 = dest_realsize_x - x - 1
  If dest_loop_x2 + x < 0 Then dest_loop_x2 = -x
  If dest_loop_x2 + x > dest_realsize_x - 1 Then dest_loop_x2 = dest_realsize_x - x - 1
  
  dest_loop_y1 = 0
  dest_loop_y2 = dest_size_y - 1
  If dest_loop_y1 + y < 0 Then dest_loop_y1 = -y
  If dest_loop_y1 + y > dest_realsize_y - 1 Then dest_loop_y1 = dest_realsize_y - y - 1
  If dest_loop_y2 + y < 0 Then dest_loop_y2 = -y
  If dest_loop_y2 + y > dest_realsize_y - 1 Then dest_loop_y2 = dest_realsize_y - y - 1
  
  'loop for each destination pixel
  For dest_loop_x = dest_loop_x1 To dest_loop_x2
    For dest_loop_y = dest_loop_y1 To dest_loop_y2
      'find the source pixels under this destination pixel
      x1 = cfloat(dest_loop_x) / dest_size_x * srce_size_x - .5
      x2 = cfloat(dest_loop_x + 1) / dest_size_x * srce_size_x - .5
      y1 = cfloat(dest_loop_y) / dest_size_y * srce_size_y - .5
      y2 = cfloat(dest_loop_y + 1) / dest_size_y * srce_size_y - .5
     
      'loop through all of the source pixels under this destination pixel to get the average color
      red = 0: green = 0: blue = 0: total_pixels = 0
      For srce_loop_x = x1 To x2
        For srce_loop_y = y1 To y2
          'the following can be replaced with 'overlap_factor = 1,' but it will be slightly less accurate (especially in the last row and column)
          'overlaps 1, 2: location of destination pixel; 3, 4: part of source pixel under destination pixel; 5, 6: location of source pixel
          'x overlap factor
          overlap_1 = cfloat(dest_loop_x) / dest_size_x
          overlap_2 = cfloat(dest_loop_x + 1) / dest_size_x
          overlap_3 = cfloat(srce_loop_x) / srce_size_x
          overlap_4 = cfloat(srce_loop_x + 1) / srce_size_x
          overlap_5 = overlap_3
          overlap_6 = overlap_4
          If overlap_3 < overlap_1 Or overlap_3 > overlap_2 Then overlap_3 = Iif(Abs(overlap_3 - overlap_1) < Abs(overlap_3 - overlap_2), overlap_1, overlap_2)
          If overlap_4 < overlap_1 Or overlap_4 > overlap_2 Then overlap_4 = Iif(Abs(overlap_4 - overlap_1) < Abs(overlap_4 - overlap_2), overlap_1, overlap_2)
          overlap_factor = Abs((overlap_3 - overlap_4) / (overlap_5 - overlap_6))
          'y overlap factor
          overlap_1 = cfloat(dest_loop_y) / dest_size_y
          overlap_2 = cfloat(dest_loop_y + 1) / dest_size_y
          overlap_3 = cfloat(srce_loop_y) / srce_size_y
          overlap_4 = cfloat(srce_loop_y + 1) / srce_size_y
          overlap_5 = overlap_3
          overlap_6 = overlap_4
          If overlap_3 < overlap_1 Or overlap_3 > overlap_2 Then overlap_3 = Iif(Abs(overlap_3 - overlap_1) < Abs(overlap_3 - overlap_2), overlap_1, overlap_2)
          If overlap_4 < overlap_1 Or overlap_4 > overlap_2 Then overlap_4 = Iif(Abs(overlap_4 - overlap_1) < Abs(overlap_4 - overlap_2), overlap_1, overlap_2)
          overlap_factor *= Abs((overlap_3 - overlap_4) / (overlap_5 - overlap_6))
         
          'overlap_factor = 1
          If overlap_factor > 1E-10 Then
            'point()
            srce_color = *(srce_ptr + srce_loop_x + srce_loop_y * srce_pitch)
            if srce_color <> &HFFFF00FF then
              total_pixels += overlap_factor 'if all of the source pixel is under the destination pixel, then a whole pixel is added
              red += ((srce_color And &H00FF0000) Shr 16) * overlap_factor
              green += ((srce_color And &H0000FF00) Shr 8) * overlap_factor
              blue += (srce_color And &H000000FF) * overlap_factor
            end if
          End If
        Next srce_loop_y
      Next srce_loop_x
      red /= total_pixels: green /= total_pixels: blue /= total_pixels
     
      'draw (pset())
      If total_pixels > 0 Then
        *(dest_ptr + dest_loop_x + dest_loop_y * dest_pitch) = (&HFF000000) Or (red Shl 16) Or (green Shl 8) Or blue
      End If
    Next dest_loop_y
  Next dest_loop_x
End Sub

Sub image_scaler Overload (Byval x As Integer = 0, Byval y As Integer = 0, Byval source As fb.image Ptr, Byval scale As float)
  image_scaler 0, x, y, source, scale
End Sub
