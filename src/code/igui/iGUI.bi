
' iGUI: The Innova Graphical User Interface! v1.1
' (C) 2008 Innova and Kristopher Windsor

'if you undefine this, iGUI will compile on Linux, but the clipboard will not work
#ifdef __FB_WIN32__
  #define igui_use_clipboard
#endif

#ifdef igui_use_clipboard
  #include once "windows.bi"
#endif

#include once "fbgfx.bi"

#ifndef true
  const true = -1
#Endif
#ifndef false
  const false = 0
#Endif

namespace igui
  #define parent_core (*cast(form_type Ptr, core.parent)).core
  #macro igui_mousedown_color_blend(newc, oldc)
    Scope
      Dim As Integer r, g, b
      r = (((oldc And &HFF0000) Shr 16) * 4 + ((newc And &HFF0000) Shr 16)) / 5
      g = (((oldc And &HFF00) Shr 8) * 4 + ((newc And &HFF00) Shr 8)) / 5
      b = ((oldc And &HFF) * 4 + (newc And &HFF)) / 5
      oldc = Rgb(r, g, b)
    End Scope
  #endmacro
  
  namespace consts
    namespace mice
      Const mouse_left = 1, mouse_right = 2
    End namespace
    
    namespace keys
      Const key_tab = Chr(9), key_enter = Chr(13), key_escape = Chr(27)
      Const key_up = Chr(255, 72), key_down = Chr(255, 80), key_pageup = Chr(255, 73), key_pagedown = Chr(255, 81)
      Const key_left = Chr(255, 75), key_right = Chr(255, 77)
    End namespace
    
    namespace misc
      'Const form_max = 8, form_object_max = 32
      Const option_max = 512, textbox_history_max = 64
      Const time_doubleclick_max = .5
    End namespace
  End namespace
  
  Enum alignment_enum
    Left = 1
    center = 2
    Right = 3
    default = Left 'right
  End Enum
  
  Enum form_displaymode_enum
    none = 0    'display buttons but not form itself
    outline = 1 'display B line and label
    solid = 2   'display BF line and label
    'button = 3  'changes color on hover and click
  End Enum
  
  Enum textbox_history_change_enum
    none = 0
    external = 1 'an external procedure modified the text in the textbox
    copypaste = 2 'actually just cut and paste (copy does not change text)
    navigationkeys = 3
    typing = 4
    cursormove = 5
    'undoredo = 5
  End Enum
  
  Type object_core_type
    Declare Sub register (Byref label As String, Byref shortcut As String = "", Byref tip As String = "", _
      Byval position_x As Integer, Byval position_y As Integer, Byval size_x As Integer, Byval size_y As Integer, _
      Byval target As Sub (), Byval text_alignment As alignment_enum, Byval ivisible As Integer = true)
    Declare Sub process
    Declare Sub process_click
    Declare Sub process_color
    
    As String label
    As String tooltip
    
    As Integer position_x, position_y, size_x, size_y
    
    As Sub () target
    As Sub () target_doubleclick
    As Sub () target_mousedown
    As Double target_timer 'time of single click, or negative timer of double click
    
    As Integer color_back
    As String shortcut
    As alignment_enum text_alignment
    
    As fb.image Ptr background_image
    As Integer background_image_alpha
    
    As Any Ptr parent 'points to parent form
    
    As Integer visible 'can turn any object (forms, buttons, etc.) off (disables for process and display)
    
    As object_core_type Ptr next_core
  End Type
  
  Type option_type
    As String options(1 To consts.misc.option_max)
    As Integer enabled(1 To consts.misc.option_max)
    As Integer selected, total
  End Type
  
  Type button_type
    Declare Sub register (Byref label As String, Byref shortcut As String = "", Byref tip As String = "", _
      Byval position_x As Integer, Byval position_y As Integer, _
      Byval size_x As Integer, Byval size_y As Integer, _
      Byval target As Sub (), Byval ivisible As Integer = true)
    Declare Sub process
    Declare Sub display
    Declare Sub destroy
    
    Declare Sub focus
    Declare Sub set_background_image (Byval image As fb.image Ptr, Byval alpha As Integer = 255)
    Declare Sub set_position (Byval x As Integer, Byval y As Integer)
    Declare Sub set_size (Byval x As Integer, Byval y As Integer)
    Declare Sub set_label (Byref label As String)
    Declare Sub set_shortcut (Byref shortcut As String)
    Declare Sub set_target (Byval target As Sub ())
    Declare Sub set_target_doubleclick (Byval target As Sub ())
    Declare Sub set_target_mousedown (Byval target As Sub ())
    Declare Sub set_text_alignment (Byval alignment As alignment_enum)
    Declare Sub set_tooltip (Byref tip As String)
    Declare Sub set_visible (Byval visible As Integer)
    Declare Function get_label As String
    Declare Function get_object_pointer As object_core_type Ptr
    
    As object_core_type core
    
    As button_type Ptr next_button
  End Type
  
  Type checkbox_type
    Declare Sub register (Byref label As String, Byref shortcut As String = "", Byref tip As String = "", _
      Byval position_x As Integer, Byval position_y As Integer, _
      Byval size_x As Integer, Byval size_y As Integer, _
      Byval target As Sub (), Byval ivisible As Integer = true, _
      Byval checked As Integer = false, Byval radio As Integer = 0)
    Declare Sub process
    Declare Sub display
    Declare Sub destroy
    
    Declare Sub focus
    Declare Sub set_background_image (Byval image As fb.image Ptr, Byval alpha As Integer = 255)
    Declare Sub set_check_alignment (Byval alignment As alignment_enum)
    Declare Sub set_checked (Byval checked As Integer)
    Declare Sub set_label (Byref label As String)
    Declare Sub set_position (Byval x As Integer, Byval y As Integer)
    Declare Sub set_size (Byval x As Integer, Byval y As Integer)
    Declare Sub set_shortcut (Byref shortcut As String)
    Declare Sub set_target (Byval target As Sub ())
    Declare Sub set_target_doubleclick (Byval target As Sub ())
    Declare Sub set_target_mousedown (Byval target As Sub ())
    Declare Sub set_text_alignment (Byval alignment As alignment_enum)
    Declare Sub set_tooltip (Byref tip As String)
    Declare Sub set_visible (Byval visible As Integer)
    Declare Function get_label As String
    Declare Function get_checked As Integer
    Declare Function get_object_pointer As object_core_type Ptr
    
    As object_core_type core
    As Integer checked
    As Integer radio
    As alignment_enum check_alignment
    
    As checkbox_type Ptr next_checkbox
  End Type
  
  Type selector_type
    Declare Sub register (Byref label As String, Byref shortcut As String = "", Byref tip As String = "", _
      Byval position_x As Integer, Byval position_y As Integer, _
      Byval size_x As Integer, Byval size_y As Integer, _
      Byval target As Sub (), Byval ivisible As Integer = true)
    Declare Sub process
    Declare Sub display
    Declare Sub destroy
    
    Declare Sub add_option (Byref text As String, Byval enabled As Integer = true)
    Declare Sub add_options (Byref _text As String)
    Declare Sub Clear
    Declare Sub focus
    Declare Sub remove_option Overload (Byval index As Integer)
    Declare Sub remove_option Overload (Byref itext As String)
    Declare Sub set_background_image (Byval image As fb.image Ptr, Byval alpha As Integer = 255)
    Declare Sub set_field_length (Byval position As Integer)
    Declare Sub set_label (Byref label As String)
    Declare Sub set_options_text_alignment (Byval alignment As alignment_enum)
    Declare Sub set_position (Byval x As Integer, Byval y As Integer)
    Declare Sub set_selected Overload (Byval index As Integer)
    Declare Sub set_selected Overload (Byref text As String)
    Declare Sub set_size (Byval x As Integer, Byval y As Integer)
    Declare Sub set_shortcut (Byref shortcut As String)
    Declare Sub set_target (Byval target As Sub ())
    Declare Sub set_target_mousedown (Byval target As Sub ())
    Declare Sub set_text_alignment (Byval alignment As alignment_enum)
    Declare Sub set_tooltip (Byref tip As String)
    Declare Sub set_visible (Byval visible As Integer)
    Declare Function get_label As String
    Declare Function get_object_pointer As object_core_type Ptr
    Declare Function get_option (Byval index As Integer) As String
    Declare Function get_option_total As Integer
    Declare Function get_selected_index As Integer
    Declare Function get_selected_label As String
    
    As object_core_type core
    As option_type options
    As alignment_enum options_text_alignment
    
    As Integer separator_position
    
    As selector_type Ptr next_selector
  End Type
  
  Type textbox_type
    Declare Sub register (Byref label As String, Byref shortcut As String = "", Byref tip As String = "", _
      Byval position_x As Integer, Byval position_y As Integer, _
      Byval size_x As Integer, Byval size_y As Integer, _
      Byval target As Sub (), Byval ivisible As Integer = true, _
      Byref text As String = "", Byval ienabled As Integer = true, Byval text_max As Integer = 512)
    Declare Sub process
    Declare Sub display
    Declare Sub destroy
    
    Declare Sub add_text (Byref text As String, Byval selected As Integer = false)
    Declare Sub copy
    Declare Sub cut
    Declare Sub focus
    Declare Sub manually_validate (Byref text As String)
    Declare Sub paste
    Declare Sub set_background_image (Byval image As fb.image Ptr, Byval alpha As Integer = 255)
    Declare Sub set_cursor (Byval position As Integer)
    Declare Sub set_enabled (Byval ienabled As Integer)
    Declare Sub set_field_alignment (Byval alignment As alignment_enum)
    Declare Sub set_field_length (Byval length As Integer)
    Declare Sub set_label (Byref label As String)
    Declare Sub set_position (Byval x As Integer, Byval y As Integer)
    Declare Sub set_selected (Byval position As Integer)
    Declare Sub set_shortcut (Byref shortcut As String)
    Declare Sub set_size (Byval x As Integer, Byval y As Integer)
    Declare Sub set_target (Byval target As Sub ())
    Declare Sub set_target_doubleclick (Byval target As Sub ())
    Declare Sub set_target_mousedown (Byval target As Sub ())
    Declare Sub set_text (Byref text As String)
    Declare Sub set_text_alignment (Byval alignment As alignment_enum)
    Declare Sub set_tooltip (Byref tip As String)
    Declare Sub set_valid_text (Byref itext As String)
    Declare Sub set_visible (Byval visible As Integer)
    Declare Function get_label As String
    Declare Function get_object_pointer As object_core_type Ptr
    Declare Function get_text As String
    Declare Function get_text_selected As String
    
    As object_core_type core
    
    As String text
    As Integer text_max
    As Integer text_display_offset
    As Integer text_display_length 'max characters displayed at once
    
    As Integer cursor
    As Integer position_select 'one end of the selection (where the mouse pressed down); other end is cursor; -1 is deselect; if equal to cursor, then deselect
    As Integer insertmode 'boolean insert mode
    
    As Integer enabled
    As String text_valid
    
    'used for extra features
    As Integer mousedownontext 'boolean
    As Double time_click, time_doubleclick
    
    As Integer history_current, history_total
    As Integer history_cursor
    As textbox_history_change_enum history_change
    As String history(1 To consts.misc.textbox_history_max)
    As String history_text
    
    As alignment_enum field_alignment
    As Integer field_length
    As Integer field_x
    
    As textbox_type Ptr next_textbox
  End Type
  
  Type form_type
    Declare Sub register (Byref label As String, Byref shortcut As String = "", Byref tip As String = "", _
      Byval position_x As Integer, Byval position_y As Integer, _
      Byval size_x As Integer, Byval size_y As Integer, _
      Byval visible As Integer = true, _
      Byval displaymode As form_displaymode_enum = solid)
    Declare Sub process
    Declare Sub display
    Declare Sub destroy
    
    Declare Sub focus
    Declare Sub set_background_image (Byval image As fb.image Ptr, Byval alpha As Integer = 255)
    Declare Sub set_label (Byref label As String)
    Declare Sub set_position (Byval x As Integer, Byval y As Integer)
    Declare Sub set_shortcut (Byref shortcut As String)
    Declare Sub set_size (Byval x As Integer, Byval y As Integer)
    Declare Sub set_target (Byval target As Sub ())
    Declare Sub set_target_doubleclick (Byval target As Sub ())
    Declare Sub set_target_mousedown (Byval target As Sub ())
    Declare Sub set_text_alignment (Byval alignment As alignment_enum)
    Declare Sub set_tooltip (Byref tip As String)
    Declare Sub set_visible (Byval visible As Integer)
    Declare Function get_label As String
    Declare Function get_object_pointer As object_core_type Ptr
    
    As object_core_type core
    As Integer button_total, checkbox_total, selector_total, textbox_total
    As Integer object_current, object_total
    As form_displaymode_enum displaymode
    
    As button_type Ptr next_button
    As checkbox_type Ptr next_checkbox
    As selector_type Ptr next_selector
    As textbox_type Ptr next_textbox
    
    As form_type Ptr next_form
  End Type
  
  Type colorscheme_type
    Declare Sub set (Byval iform_back As Integer, Byval iobject_back As Integer, _
      Byval iobject_disabled As Integer, Byval iobject_hover As Integer, Byval iobject_mousedown As Integer, _
      Byval itext As Integer, Byval itext_disabled As Integer, Byval itext_selected As Integer, Byval itooltip As Integer)
    Declare Sub set_form_back (Byval back As Integer)
    Declare Sub set_object_back (Byval back As Integer)
    Declare Sub set_object_disabled (Byval disabled As Integer)
    Declare Sub set_object_hover (Byval hover As Integer)
    Declare Sub set_object_mousedown (Byval mousedown As Integer)
    Declare Sub set_text (Byval itext As Integer)
    Declare Sub set_text_disabled (Byval disabled As Integer)
    Declare Sub set_text_selected (Byval selected As Integer)
    Declare Sub set_tooltip (Byval itooltip As Integer)
    
    As Integer form_back =        &HFF999999 'form background for solid forms
    As Integer object_back =      &HFFFFFFFF '&HFFFFFFFF '&HFFFF0000 '&HFFFFFFFF 'main object color (except not for forms)
    As Integer object_disabled =  &HFFDDDDDD 'new for disabled textbox
    As Integer object_hover =     &HFFBBBBFF '&HFFDDDDDD '&HFFBBBBBB '&HFF00FF00 '&HFFEEEEEE 'on hover or focus
    As Integer object_mousedown = &HFF8888FF '&HFF8888FF '&HFF0000FF '&HFFAAAAAA 'when pressing the mouse on the object
    As Integer text =             &HFF000000 '&HFF000000                         'most text
    As Integer text_disabled =    &HFF999999 '&HFFF00000 '&HFF888888                         'options that cannot be selected (not noticeable by default)
    As Integer text_selected =    &HFF88FF88 '&HFF88FF88                         'the box behind selected text
    As Integer tooltip =          &HFF88FF88 '&HFF88FF88 '&HFFFF88FF '&HFF884488 'the tooltip box
  End Type
  
  Type mouse_type
    Declare Sub Get (Byref inx As Integer = 0, Byref iny As Integer = 0, Byref ins As Integer = 0, Byref inb As Integer = 0)
    
    As Integer x, y
    As Integer s, b
  End Type
  
  Type tooltip_type
    As Integer x, y
    As Integer started
    As Double time_start, time_finish
  End Type
  
  namespace vars
    namespace mice
      Extern As mouse_type mouse, mouse_previous, mouse_mousedown, mouse_mouseup
    End namespace
    
    namespace keys
      Extern As Integer key_menu, key_shift
      Extern As String key, key_shortcut
    End namespace
    
    namespace objects
      Extern As object_core_type Ptr object_hover, object_mousedown, object_keyboard, object_mouseup, object_hover_next, object_mousedown_next
    End namespace
    
    namespace menus
      Extern As option_type menu_rightmousedown_default, menu_rightmousedown_selector, menu_rightmousedown_textbox
      Extern As option_type menu_ok, menu_yesno, menu_yesnocancel
    End namespace
    
    namespace misc
      Extern As Integer frame_total
      Extern As Integer screen_size_x, screen_size_y
      Extern As colorscheme_type colorscheme
      Extern As alignment_enum menu_text_alignment
      Extern As tooltip_type tooltip
      Extern As object_core_type Ptr next_core
      Extern As form_type Ptr next_form
    End namespace
  End namespace
  
  Declare Sub start
  Declare Sub process (Byref k As String)
  Declare Sub process_tab
  Declare Sub display
  Declare Sub utility_display_text _
    (Byref _t As String, Byval x1 As Integer, Byval x2 As Integer, Byval y As Integer, Byval alignment As alignment_enum, _
    Byval strikethrough As Integer = false, Byval c As Integer = vars.misc.colorscheme.text)
  Declare Sub utility_mouse_update
  Declare Function utility_alert (Byref title As String, Byref options As option_type, Byval x As Integer = vars.mice.mouse.x, Byval y As Integer = vars.mice.mouse.y, Byval w As Integer = 128) As Integer
  Declare Function utility_menu (Byref options As option_type, Byval x As Integer = vars.mice.mouse.x, Byval y As Integer = vars.mice.mouse.y, Byval w As Integer = 128) As Integer
  
  namespace functions
    Declare Sub set_clipboard (Byref x As String)
    Declare Sub set_menu_text_alignment (Byval alignment As alignment_enum)
    Declare Function get_object_mousedown_label () As String
    Declare Function get_object_mousedown_pointer () As object_core_type Ptr
    Declare Function get_object_mouseup_label () As String
    Declare Function get_object_mouseup_pointer () As object_core_type Ptr
    Declare Function get_object_hover_label () As String
    Declare Function get_object_hover_pointer () As object_core_type Ptr
    Declare Function get_object_focus_label () As String
    Declare Function get_object_focus_pointer () As object_core_type Ptr
    Declare Function get_object_pressing_label () As String
    Declare Function get_object_pressing_pointer () As object_core_type Ptr
    Declare Function get_clipboard () As String
  End namespace
End namespace
