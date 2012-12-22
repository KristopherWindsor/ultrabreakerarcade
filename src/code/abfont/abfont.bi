
' Alpha (Bitmap) Font: header file

#include once "fbgfx.bi"
#Include once "file.bi"

namespace abfont

Const true = -1, false = 0

Type ALPHA_FONT_SEQUENCE
  'one character in a font
  Pitch               As Ushort
  Start               As Ushort
  Top                 As Ushort
  Width               As Ushort
  Height              As Ushort
  Data                As Ubyte Ptr  
End Type

Type ALPHA_FONT_HEADER Field = 1
  'needed because this is slightly different from the real sizeof()
  'note that using lbound = 0 gives an extra byte
  Const size = 530
  
  Signature           As String * 3
  FileVersion         As String * 3
  CRC                 As Uinteger
  Checksum            As Uinteger
  DeveloperMessage    As String * 255
  FontName            As String * 255
  FontSize            As Ushort
  FontHeight          As Ushort
  FontWeight          As Ushort
  FontFlag            As Ubyte    
End Type

Type ALPHA_FONT_BITMAP
  'one font slot
  Header              As ALPHA_FONT_HEADER
  DataSequence(255)   As ALPHA_FONT_SEQUENCE
  Loaded              As Integer
End Type

Type ALPHA_FONT_COLOR
  Red                 As Ubyte
  Green               As Ubyte
  Blue                As Ubyte
  Alpha               As Ubyte
  AlphaMultiplierA    As Single
  AlphaMultiplierB    As Single
End Type

Type alpha_font
  Const font_slot_max = 31
  
  Const ALPHA_FONT_BITMAP_VERSION_MAYOR = 1
  Const ALPHA_FONT_BITMAP_VERSION_MINOR = 1
  Const ALPHA_FONT_BITMAP_VERSION_BUILD = 4
  Const ALPHA_FONT_BITMAP_VERSION_MSG = "Kristopher's OOP Special Edition"
  
  Declare Constructor ()
  Declare Destructor ()
  
  'main
  Declare Sub draw Overload (ALPHA_ACTIVE_FONT As Integer = 0, x As Short, y As Short, s As String, _
    Byval tcolor As Uinteger = &HFF000000, Byval bcolor As Uinteger = 0)
  Declare Sub draw(Byval target As fb.image Ptr, ALPHA_ACTIVE_FONT As Integer = 0, x As Short, y As Short, s As String, _
    Byval tcolor As Uinteger = &HFF000000, Byval bcolor As Uinteger = 0)
  
  'font management
  Declare Function LoadFont Overload (Byval Filename As String, Byval FontIndex As Ubyte) As Integer
  Declare Function LoadFont Overload (Byref DataPtr As Ubyte Ptr, FontIndex As Ubyte) As Integer '[v0.1.0]
  Declare Sub UnloadFont(Byval FontIndex As Ubyte)
  
  'errors
  Declare Sub errorlog (Byref e As String)
  Declare Function errorcheck () As String
  
  'properties
  Declare Function GetFontName (font_index As Integer) As String
  Declare Function GetFontSize (font_index As Integer) As Ushort
  Declare Function GetFontBoldFlag (font_index As Integer) As Integer
  Declare Function GetFontItalicFlag (font_index As Integer) As Integer
  Declare Function GetFontUnderlineFlag (font_index As Integer) As Integer
  Declare Function GetFontStrikeOutFlag (font_index As Integer) As Integer
  Declare Function GetFontDevMsg (font_index As Integer) As String
  Declare Function GetTextHeight (font_index As Integer) As Ushort
  Declare Function GetTextWidth (font_index As Integer, Byref s As String) As Ushort
  Declare Sub GetAlphaBitmapFontLibVer (Byref Major As Uinteger, Byref Minor As Uinteger, _
    Byref Build As Uinteger, Byref Message As String)
  
  'private
  Declare Function backend_loadfont_body (Byref DataPtr As Ubyte Ptr, FontIndex As Ubyte) As Integer
  Declare Function backend_loadfont_header (ALPHA_FONT_HEADER_TEMP() As Ubyte, Byval FontIndex As Ubyte) As Integer
  
  As Single ALPHA_MULTIPLIER_255(255), IALPHA_MULTIPLIER_255(255)
  As String errormessage
  As ALPHA_FONT_BITMAP ALPHA_FONT(font_slot_max)
End Type

End namespace
