
Type menu_setting_type
  Const option_max = 1024
  
  As String title
  As Integer option_total, option_preselected
  As Integer disablecancel, readonly, returnvalue, xoption
  As Integer screenshot_ison, screenshot_disable_intro 'screenshot shouldn't be turned on by callback
  As String Option(1 To option_max)
  
  'preview image is shown like screenshot, but not zoomed out at the beginning (and can be any size)
  'clicking preview image returns currently selected option (doesn't cancel)
  'screenshot_ison takes priority
  'can be updated to match selected item by callback
  superfluous as fb.image ptr previewimage
  
  as integer scrolloffset 'static; can be reset between menu calls
  
  As Function (Byref As menu_setting_type, oselected as integer) As Integer callback
End Type

type menu_type
  const bigball_x = 364 * dsfactor, bigball_y = 384 * dsfactor
  
  declare function show (menu as menu_setting_type) as integer
  declare sub showclosing (setprogress as double = -1)
  declare sub notify (Byref title As String, Byval getscreenshot As Integer = false)
  declare function confirm (Byref title As String, Byval getscreenshot As Integer = false) As Integer
  
  as integer __
end type

declare Function menu_callback_info (Byref menu As menu_setting_type, oselected as integer) As Integer
declare Function menu_callback_selectlevel (Byref menu As menu_setting_type, oselected as integer) As Integer
declare Function menu_callback_play (Byref menu As menu_setting_type, oselected as integer) As Integer
declare Function menu_callback_postgame (Byref menu As menu_setting_type, oselected as integer) As Integer
declare Function menu_callback_test (Byref menu As menu_setting_type, oselected as integer) As Integer
  
dim shared as menu_type menu
