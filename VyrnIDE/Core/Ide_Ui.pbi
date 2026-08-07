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
    #GAD_EDITOR
    #GAD_OUTPUT
    #GAD_STATUS
    #GAD_SPLIT
  EndEnumeration

  Enumeration
    #MENU_MAIN = 0
  EndEnumeration

  Enumeration
    #MNU_NEW = 0
    #MNU_OPEN
    #MNU_SAVE
    #MNU_SAVEAS
    #MNU_EXIT
    #MNU_UNDO
    #MNU_REDO
    #MNU_CUT
    #MNU_COPY
    #MNU_PASTE
    #MNU_RUN
    #MNU_STOP
    #MNU_ABOUT
  EndEnumeration

  #Ide_ToolbarH = 36
  #Ide_StatusH = 22
  #Ide_SplitH = 6
  #Ide_DefaultOutH = 160
  #Ide_MinEditorH = 120
  #Ide_MinOutH = 80

  Global Ide_OutputHeight.i = #Ide_DefaultOutH
  
  ; <summary>
  ; Ide_Ui_CreateMenus
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Ui_CreateMenus()
    CreateMenu(#MENU_MAIN, WindowID(#WIN_IDE))
    MenuTitle("File")
    MenuItem(#MNU_NEW, "New" + Chr(9) + "Ctrl+N")
    MenuItem(#MNU_OPEN, "Open..." + Chr(9) + "Ctrl+O")
    MenuItem(#MNU_SAVE, "Save" + Chr(9) + "Ctrl+S")
    MenuItem(#MNU_SAVEAS, "Save As...")
    MenuBar()
    MenuItem(#MNU_EXIT, "Exit")
    MenuTitle("Edit")
    MenuItem(#MNU_UNDO, "Undo" + Chr(9) + "Ctrl+Z")
    MenuItem(#MNU_REDO, "Redo" + Chr(9) + "Ctrl+Y")
    MenuBar()
    MenuItem(#MNU_CUT, "Cut" + Chr(9) + "Ctrl+X")
    MenuItem(#MNU_COPY, "Copy" + Chr(9) + "Ctrl+C")
    MenuItem(#MNU_PASTE, "Paste" + Chr(9) + "Ctrl+V")
    MenuTitle("Run")
    MenuItem(#MNU_RUN, "Run" + Chr(9) + "F5")
    MenuItem(#MNU_STOP, "Stop" + Chr(9) + "Shift+F5")
    MenuTitle("Help")
    MenuItem(#MNU_ABOUT, "About Vyrn IDE")
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_Layout
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Ui_Layout()
    Protected ww.i = WindowWidth(#WIN_IDE)
    Protected wh.i = WindowHeight(#WIN_IDE)
    Protected top.i = #Ide_ToolbarH
    Protected outH.i = Ide_OutputHeight
    Protected editorH.i
    Protected maxOut.i

    If IsWindow(#WIN_IDE) = 0
      ProcedureReturn
    EndIf

    If ww < 200 : ww = 200 : EndIf
    If wh < 240 : wh = 240 : EndIf

    maxOut = wh - top - #Ide_StatusH - #Ide_SplitH - #Ide_MinEditorH
    
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

    editorH = wh - top - #Ide_SplitH - outH - #Ide_StatusH
    
    If editorH < #Ide_MinEditorH
      editorH = #Ide_MinEditorH
    EndIf

    If IsGadget(#GAD_TOOL_OPEN) : ResizeGadget(#GAD_TOOL_OPEN, 8, 6, 70, 24) : EndIf
    If IsGadget(#GAD_TOOL_SAVE) : ResizeGadget(#GAD_TOOL_SAVE, 86, 6, 70, 24) : EndIf
    If IsGadget(#GAD_TOOL_RUN) : ResizeGadget(#GAD_TOOL_RUN, 164, 6, 70, 24) : EndIf
    If IsGadget(#GAD_TOOL_STOP) : ResizeGadget(#GAD_TOOL_STOP, 242, 6, 70, 24) : EndIf
    If IsGadget(#GAD_EDITOR) : ResizeGadget(#GAD_EDITOR, 0, top, ww, editorH) : EndIf
    If IsGadget(#GAD_SPLIT) : ResizeGadget(#GAD_SPLIT, 0, top + editorH, ww, #Ide_SplitH) : EndIf
    If IsGadget(#GAD_OUTPUT) : ResizeGadget(#GAD_OUTPUT, 0, top + editorH + #Ide_SplitH, ww, outH) : EndIf
    If IsGadget(#GAD_STATUS) : ResizeGadget(#GAD_STATUS, 0, wh - #Ide_StatusH, ww, #Ide_StatusH) : EndIf
  EndProcedure

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

    TextGadget(#GAD_SPLIT, 0, 0, 10, #Ide_SplitH, "", #PB_Text_Border)
    SetGadgetColor(#GAD_SPLIT, #PB_Gadget_BackColor, RGB(200, 200, 200))

    EditorGadget(#GAD_OUTPUT, 0, 0, 10, 10, #PB_Editor_ReadOnly)
    TextGadget(#GAD_STATUS, 0, 0, 10, #Ide_StatusH, "Ready", #PB_Text_Border)

    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_F5, #MNU_RUN)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Shift | #PB_Shortcut_F5, #MNU_STOP)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_N, #MNU_NEW)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_O, #MNU_OPEN)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_S, #MNU_SAVE)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Z, #MNU_UNDO)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Y, #MNU_REDO)

    DisableMenuItem(#MENU_MAIN, #MNU_STOP, #True)
    
    ProcedureReturn #True
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_SetStatus
  ; </summary>
  ; <param name="msg">string</param>
  ; <returns>Returns void.</returns>
  Procedure Ide_Ui_SetStatus(msg.s)
    SetGadgetText(#GAD_STATUS, msg)
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_OutputClear
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Ui_OutputClear()
    SetGadgetText(#GAD_OUTPUT, "")
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_OutputAppend
  ; </summary>
  ; <param name="line">string</param>
  ; <returns>Returns void.</returns>
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

CompilerEndIf

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 58
; Folding = --
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; EnableOnError
; DisableDebugger
; CompileSourceDirectory