;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - window layout, gadget IDs, menus
; PureBasic 6.40

CompilerIf Defined(Ide_Ui, #PB_Constant) = #False
  #Ide_Ui = #True

  Enumeration
    #WIN_IDE = 0
  EndEnumeration

  Enumeration
    #GAD_TOOL_OPEN = 0
    #GAD_TOOL_SAVE
    #GAD_TOOL_RUN
    #GAD_TOOL_STOP
    #GAD_TABS
    #GAD_FIND_STR
    #GAD_FIND_NEXT
    #GAD_REPLACE_STR
    #GAD_REPLACE
    #GAD_REPLACE_ALL
    #GAD_FIND_CASE
    #GAD_OUTPUT
    #GAD_STATUS
    #GAD_SPLIT
  EndEnumeration

  #Ide_MarkError = 1
  #Ide_MarkWarn = 2
  #Ide_MarkErrorBack = 3
  #Ide_MarkWarnBack = 4
  #Ide_MarginSymbol = 1

  Enumeration
    #MENU_MAIN = 0
  EndEnumeration

  Enumeration
    #MNU_NEW = 0
    #MNU_OPEN
    #MNU_SAVE
    #MNU_SAVEAS
    #MNU_CLOSE
    #MNU_EXIT
    #MNU_UNDO
    #MNU_REDO
    #MNU_CUT
    #MNU_COPY
    #MNU_PASTE
    #MNU_FIND
    #MNU_FINDNEXT
    #MNU_REPLACE
    #MNU_ZOOMIN
    #MNU_ZOOMOUT
    #MNU_ZOOMRESET
    #MNU_THEME
    #MNU_RUN
    #MNU_STOP
    #MNU_ABOUT
  EndEnumeration

  #Ide_ToolbarH = 36
  #Ide_FindH = 30
  #Ide_StatusH = 22
  #Ide_SplitH = 6
  #Ide_DefaultOutH = 160
  #Ide_MinEditorH = 120
  #Ide_MinOutH = 80

  Global Ide_OutputHeight.i = #Ide_DefaultOutH
  Global Ide_FindVisible.i = #False
  Global Ide_Theme_Dark.i = #False
  Global Ide_EditorW.i = 100
  Global Ide_EditorH.i = 100

  ; <summary>
  ; Build the main menu bar (File / Edit / View / Run / Help) and accelerators labels.
  ; </summary>
  Procedure Ide_Ui_CreateMenus()
    CreateMenu(#MENU_MAIN, WindowID(#WIN_IDE))
    MenuTitle("File")
    MenuItem(#MNU_NEW, "New" + Chr(9) + "Ctrl+N")
    MenuItem(#MNU_OPEN, "Open..." + Chr(9) + "Ctrl+O")
    MenuItem(#MNU_SAVE, "Save" + Chr(9) + "Ctrl+S")
    MenuItem(#MNU_SAVEAS, "Save As...")
    MenuItem(#MNU_CLOSE, "Close Tab" + Chr(9) + "Ctrl+W")
    MenuBar()
    MenuItem(#MNU_EXIT, "Exit")
    MenuTitle("Edit")
    MenuItem(#MNU_UNDO, "Undo" + Chr(9) + "Ctrl+Z")
    MenuItem(#MNU_REDO, "Redo" + Chr(9) + "Ctrl+Y")
    MenuBar()
    MenuItem(#MNU_CUT, "Cut" + Chr(9) + "Ctrl+X")
    MenuItem(#MNU_COPY, "Copy" + Chr(9) + "Ctrl+C")
    MenuItem(#MNU_PASTE, "Paste" + Chr(9) + "Ctrl+V")
    MenuBar()
    MenuItem(#MNU_FIND, "Find..." + Chr(9) + "Ctrl+F")
    MenuItem(#MNU_FINDNEXT, "Find Next" + Chr(9) + "F3")
    MenuItem(#MNU_REPLACE, "Replace..." + Chr(9) + "Ctrl+H")
    MenuTitle("View")
    MenuItem(#MNU_ZOOMIN, "Zoom In" + Chr(9) + "Ctrl++")
    MenuItem(#MNU_ZOOMOUT, "Zoom Out" + Chr(9) + "Ctrl+-")
    MenuItem(#MNU_ZOOMRESET, "Reset Zoom" + Chr(9) + "Ctrl+0")
    MenuBar()
    MenuItem(#MNU_THEME, "Dark Theme")
    MenuTitle("Run")
    MenuItem(#MNU_RUN, "Run" + Chr(9) + "F5")
    MenuItem(#MNU_STOP, "Stop" + Chr(9) + "Shift+F5")
    MenuTitle("Help")
    MenuItem(#MNU_ABOUT, "About Vyrn IDE")
  EndProcedure

  ; <summary>
  ; Height reserved for the find/replace bar when it is visible.
  ; </summary>
  ; <returns>#Ide_FindH when visible; otherwise 0.</returns>
  Procedure.i Ide_Ui_FindBarH()
    If Ide_FindVisible
      ProcedureReturn #Ide_FindH
    EndIf
    ProcedureReturn 0
  EndProcedure

  ; <summary>
  ; Relayout toolbar, find bar, tab panel, splitter, output, and status for the window size.
  ; </summary>
  Procedure Ide_Ui_Layout()
    Protected ww.i = WindowWidth(#WIN_IDE)
    Protected wh.i = WindowHeight(#WIN_IDE)
    Protected top.i = #Ide_ToolbarH
    Protected findH.i = Ide_Ui_FindBarH()
    Protected outH.i = Ide_OutputHeight
    Protected editorH.i
    Protected maxOut.i

    If IsWindow(#WIN_IDE) = 0
      ProcedureReturn
    EndIf

    If ww < 200 : ww = 200 : EndIf
    If wh < 240 : wh = 240 : EndIf

    maxOut = wh - top - findH - #Ide_StatusH - #Ide_SplitH - #Ide_MinEditorH
    If maxOut < #Ide_MinOutH
      maxOut = #Ide_MinOutH
    EndIf
    If outH > maxOut
      outH = maxOut
    EndIf
    If outH < #Ide_MinOutH
      outH = #Ide_MinOutH
    EndIf
    Ide_OutputHeight = outH

    editorH = wh - top - findH - #Ide_SplitH - outH - #Ide_StatusH
    
    If editorH < #Ide_MinEditorH
      editorH = #Ide_MinEditorH
    EndIf

    If IsGadget(#GAD_TOOL_OPEN) : ResizeGadget(#GAD_TOOL_OPEN, 8, 6, 70, 24) : EndIf
    If IsGadget(#GAD_TOOL_SAVE) : ResizeGadget(#GAD_TOOL_SAVE, 86, 6, 70, 24) : EndIf
    If IsGadget(#GAD_TOOL_RUN) : ResizeGadget(#GAD_TOOL_RUN, 164, 6, 70, 24) : EndIf
    If IsGadget(#GAD_TOOL_STOP) : ResizeGadget(#GAD_TOOL_STOP, 242, 6, 70, 24) : EndIf

    If IsGadget(#GAD_FIND_STR)
      HideGadget(#GAD_FIND_STR, Bool(Ide_FindVisible = 0))
      HideGadget(#GAD_FIND_NEXT, Bool(Ide_FindVisible = 0))
      HideGadget(#GAD_REPLACE_STR, Bool(Ide_FindVisible = 0))
      HideGadget(#GAD_REPLACE, Bool(Ide_FindVisible = 0))
      HideGadget(#GAD_REPLACE_ALL, Bool(Ide_FindVisible = 0))
      HideGadget(#GAD_FIND_CASE, Bool(Ide_FindVisible = 0))
      ResizeGadget(#GAD_FIND_STR, 8, top + 3, 180, 22)
      ResizeGadget(#GAD_FIND_NEXT, 192, top + 3, 70, 22)
      ResizeGadget(#GAD_REPLACE_STR, 270, top + 3, 160, 22)
      ResizeGadget(#GAD_REPLACE, 434, top + 3, 70, 22)
      ResizeGadget(#GAD_REPLACE_ALL, 508, top + 3, 90, 22)
      ResizeGadget(#GAD_FIND_CASE, 604, top + 3, 90, 22)
    EndIf

    If IsGadget(#GAD_TABS) : ResizeGadget(#GAD_TABS, 0, top + findH, ww, editorH) : EndIf
    If IsGadget(#GAD_SPLIT) : ResizeGadget(#GAD_SPLIT, 0, top + findH + editorH, ww, #Ide_SplitH) : EndIf
    If IsGadget(#GAD_OUTPUT) : ResizeGadget(#GAD_OUTPUT, 0, top + findH + editorH + #Ide_SplitH, ww, outH) : EndIf
    If IsGadget(#GAD_STATUS) : ResizeGadget(#GAD_STATUS, 0, wh - #Ide_StatusH, ww, #Ide_StatusH) : EndIf

    Ide_EditorW = ww
    Ide_EditorH = editorH
  EndProcedure

  ; <summary>
  ; Apply light/dark chrome colors to window, splitter, output, status, and theme menu check.
  ; </summary>
  Procedure Ide_Ui_ApplyChrome()
    Protected bg.i, fg.i, split.i, outBg.i, outFg.i
    
    If Ide_Theme_Dark
      bg = RGB(32, 32, 32)
      fg = RGB(220, 220, 220)
      split = RGB(70, 70, 70)
      outBg = RGB(24, 24, 24)
      outFg = RGB(210, 210, 210)
    Else
      bg = RGB(240, 240, 240)
      fg = RGB(30, 30, 30)
      split = RGB(200, 200, 200)
      outBg = RGB(252, 252, 252)
      outFg = RGB(30, 30, 30)
    EndIf
    
    If IsWindow(#WIN_IDE)
      SetWindowColor(#WIN_IDE, bg)
    EndIf
    
    If IsGadget(#GAD_SPLIT)
      SetGadgetColor(#GAD_SPLIT, #PB_Gadget_BackColor, split)
    EndIf
    
    If IsGadget(#GAD_OUTPUT)
      SetGadgetColor(#GAD_OUTPUT, #PB_Gadget_BackColor, outBg)
      SetGadgetColor(#GAD_OUTPUT, #PB_Gadget_FrontColor, outFg)
    EndIf
    
    If IsGadget(#GAD_STATUS)
      SetGadgetColor(#GAD_STATUS, #PB_Gadget_BackColor, bg)
      SetGadgetColor(#GAD_STATUS, #PB_Gadget_FrontColor, fg)
    EndIf
    
    SetMenuItemState(#MENU_MAIN, #MNU_THEME, Ide_Theme_Dark)
  EndProcedure

  ; <summary>
  ; Create the main IDE window, gadgets, menus, and keyboard shortcuts.
  ; </summary>
  ; <returns>#True on success; #False if OpenWindow fails.</returns>
  Procedure.i Ide_Ui_CreateWindow()
    Protected flags.i = #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget | #PB_Window_ScreenCentered

    If OpenWindow(#WIN_IDE, 0, 0, 960, 640, "Vyrn IDE", flags) = 0
      ProcedureReturn #False
    EndIf

    Ide_Ui_CreateMenus()

    ButtonGadget(#GAD_TOOL_OPEN, 8, 6, 70, 24, "Open")
    ButtonGadget(#GAD_TOOL_SAVE, 86, 6, 70, 24, "Save")
    ButtonGadget(#GAD_TOOL_RUN, 164, 6, 70, 24, "Run")
    ButtonGadget(#GAD_TOOL_STOP, 242, 6, 70, 24, "Stop")
    DisableGadget(#GAD_TOOL_STOP, #True)

    StringGadget(#GAD_FIND_STR, 8, 40, 180, 22, "")
    ButtonGadget(#GAD_FIND_NEXT, 192, 40, 70, 22, "Find")
    StringGadget(#GAD_REPLACE_STR, 270, 40, 160, 22, "")
    ButtonGadget(#GAD_REPLACE, 434, 40, 70, 22, "Replace")
    ButtonGadget(#GAD_REPLACE_ALL, 508, 40, 90, 22, "Replace All")
    CheckBoxGadget(#GAD_FIND_CASE, 604, 40, 90, 22, "Match case")
    HideGadget(#GAD_FIND_STR, #True)
    HideGadget(#GAD_FIND_NEXT, #True)
    HideGadget(#GAD_REPLACE_STR, #True)
    HideGadget(#GAD_REPLACE, #True)
    HideGadget(#GAD_REPLACE_ALL, #True)
    HideGadget(#GAD_FIND_CASE, #True)

    PanelGadget(#GAD_TABS, 0, #Ide_ToolbarH, 100, 100)
    CloseGadgetList()

    TextGadget(#GAD_SPLIT, 0, 0, 10, #Ide_SplitH, "", #PB_Text_Border)
    EditorGadget(#GAD_OUTPUT, 0, 0, 10, 10, #PB_Editor_ReadOnly)
    TextGadget(#GAD_STATUS, 0, 0, 10, #Ide_StatusH, "Ready", #PB_Text_Border)

    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_F5, #MNU_RUN)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Shift | #PB_Shortcut_F5, #MNU_STOP)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_N, #MNU_NEW)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_O, #MNU_OPEN)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_S, #MNU_SAVE)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_W, #MNU_CLOSE)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Z, #MNU_UNDO)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Y, #MNU_REDO)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_F, #MNU_FIND)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_F3, #MNU_FINDNEXT)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_H, #MNU_REPLACE)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Add, #MNU_ZOOMIN)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Subtract, #MNU_ZOOMOUT)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_0, #MNU_ZOOMRESET)

    DisableMenuItem(#MENU_MAIN, #MNU_STOP, #True)
    Ide_Ui_ApplyChrome()
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Set the status bar text.
  ; </summary>
  ; <param name="msg">Status message to display.</param>
  Procedure Ide_Ui_SetStatus(msg.s)
    SetGadgetText(#GAD_STATUS, msg)
  EndProcedure

  ; <summary>
  ; Clear the read-only output pane.
  ; </summary>
  Procedure Ide_Ui_OutputClear()
    SetGadgetText(#GAD_OUTPUT, "")
  EndProcedure

  ; <summary>
  ; Append a line to the output pane and scroll to the end (Windows).
  ; </summary>
  ; <param name="line">Text to append (a newline is added).</param>
  Procedure Ide_Ui_OutputAppend(line.s)
    Protected cur.s = GetGadgetText(#GAD_OUTPUT)
    
    If cur <> "" And Right(cur, 1) <> Chr(10)
      cur = cur + Chr(10)
    EndIf
    
    SetGadgetText(#GAD_OUTPUT, cur + line + Chr(10))
    
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      SendMessage_(GadgetID(#GAD_OUTPUT), #EM_SETSEL, -1, -1)
      SendMessage_(GadgetID(#GAD_OUTPUT), #EM_SCROLLCARET, 0, 0)
    CompilerEndIf
  EndProcedure

  ; <summary>
  ; Show the find bar and focus find or replace field.
  ; </summary>
  ; <param name="showReplace">#True to focus replace; #False to focus find.</param>
  Procedure Ide_Ui_ShowFind(showReplace.i = #False)
    Ide_FindVisible = #True
    Ide_Ui_Layout()
    
    If showReplace And IsGadget(#GAD_REPLACE_STR)
      SetActiveGadget(#GAD_REPLACE_STR)
    ElseIf IsGadget(#GAD_FIND_STR)
      SetActiveGadget(#GAD_FIND_STR)
    EndIf
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 341
; FirstLine = 295
; Folding = --
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; DllProtection
; EnableOnError
; DisableDebugger
; CompileSourceDirectory
; Compiler = PureBasic 6.41 - C Backend (Windows - x64)