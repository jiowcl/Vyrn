;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - menu / toolbar command handlers
; PureBasic 6.40

CompilerIf Defined(Ide_Commands, #PB_Constant) = #False
  #Ide_Commands = #True
  
  ; <summary>
  ; Save the active tab to its path, or prompt for a path when untitled.
  ; </summary>
  ; <returns>#True on success; #False on cancel or write failure.</returns>
  Procedure.i Ide_Cmd_Save()
    Protected path.s
    
    If Ide_FilePath <> ""
      If Ide_Editor_SaveTo(Ide_FilePath)
        Ide_Ui_SetStatus("Saved " + Ide_FilePath)
        ProcedureReturn #True
      EndIf
      
      MessageRequester("Vyrn IDE", "Failed to save:" + Chr(10) + Ide_FilePath, #PB_MessageRequester_Error)
      
      ProcedureReturn #False
    EndIf
    
    path = SaveFileRequester("Save Vyrn script", "untitled.vyrn", "Vyrn (*.vyrn)|*.vyrn|LuaLite (*.lua)|*.lua|All (*.*)|*.*", 0)
    
    If path = ""
      ProcedureReturn #False
    EndIf
    
    If GetExtensionPart(path) = ""
      path = path + ".vyrn"
    EndIf
    
    If Ide_Editor_SaveTo(path)
      Ide_Ui_SetStatus("Saved " + path)
      
      ProcedureReturn #True
    EndIf
    
    MessageRequester("Vyrn IDE", "Failed to save:" + Chr(10) + path, #PB_MessageRequester_Error)
    
    ProcedureReturn #False
  EndProcedure
  
  ; <summary>
  ; Prompt for a new path and save the active tab (Save As).
  ; </summary>
  ; <returns>#True on success; #False on cancel or write failure.</returns>
  Procedure.i Ide_Cmd_SaveAs()
    Protected path.s
    Protected start.s = Ide_FilePath
    
    If start = ""
      start = "untitled.vyrn"
    EndIf
    
    path = SaveFileRequester("Save Vyrn script as", start, "Vyrn (*.vyrn)|*.vyrn|LuaLite (*.lua)|*.lua|All (*.*)|*.*", 0)
    
    If path = ""
      ProcedureReturn #False
    EndIf
    
    If GetExtensionPart(path) = ""
      path = path + ".vyrn"
    EndIf
    
    If Ide_Editor_SaveTo(path)
      Ide_Ui_SetStatus("Saved " + path)
      
      ProcedureReturn #True
    EndIf
    
    MessageRequester("Vyrn IDE", "Failed to save:" + Chr(10) + path, #PB_MessageRequester_Error)
    
    ProcedureReturn #False
  EndProcedure
  
  ; <summary>
  ; Open a new untitled buffer; blocked while a script is running.
  ; </summary>
  Procedure Ide_Cmd_New()
    If Ide_Runner_IsBusy()
      MessageRequester("Vyrn IDE", "Stop the running script before creating a new file.", #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    Ide_Editor_New()
    Ide_Ui_SetStatus("New file")
  EndProcedure

  ; <summary>
  ; Open a .vyrn/.lua file via requester; blocked while a script is running.
  ; </summary>
  Procedure Ide_Cmd_Open()
    Protected path.s
    If Ide_Runner_IsBusy()
      MessageRequester("Vyrn IDE", "Stop the running script before opening another file.", #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    path = OpenFileRequester("Open Vyrn script", "", "Vyrn (*.vyrn)|*.vyrn|LuaLite (*.lua)|*.lua|All (*.*)|*.*", 0)
    If path = ""
      ProcedureReturn
    EndIf
    If Ide_Editor_LoadFile(path)
      Ide_Ui_SetStatus("Opened " + path)
    Else
      MessageRequester("Vyrn IDE", "Failed to open:" + Chr(10) + path, #PB_MessageRequester_Error)
    EndIf
  EndProcedure

  ; <summary>
  ; Close the active tab after optional save prompt; blocked while running.
  ; </summary>
  Procedure Ide_Cmd_CloseTab()
    If Ide_Runner_IsBusy()
      MessageRequester("Vyrn IDE", "Stop the running script before closing a tab.", #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    Ide_Editor_CloseTab()
  EndProcedure

  ; <summary>
  ; Show the find bar (and focus replace field when requested).
  ; </summary>
  ; <param name="showReplace">#True to focus the replace string gadget.</param>
  Procedure Ide_Cmd_ShowFind(showReplace.i = #False)
    Ide_Ui_ShowFind(showReplace)
    Ide_Editor_ResizeEditors()
  EndProcedure
  
  ; <summary>
  ; Show About dialog with author, runtime version, ABI, and DLL path.
  ; </summary>
  Procedure Ide_Cmd_About()
    Protected msg.s
    Protected dllHint.s

    If Vyrn_DllPath <> ""
      dllHint = Vyrn_DllPath
    Else
      dllHint = "(not loaded)"
    EndIf

    msg = "Vyrn IDE" + Chr(10) + Chr(10)
    msg = msg + "Author: Jiowcl - Ji-Feng Tsai (jiowcl@gmail.com)" + Chr(10)
    msg = msg + "Runtime: Vyrn " + Vyrn_ProductVersion() + " (ABI " + Str(Vyrn_Abi) + ")" + Chr(10)
    msg = msg + "DLL: " + dllHint + Chr(10) + Chr(10)
    msg = msg + "Edit .vyrn scripts with tabs, find/replace, and run them via Vyrn.dll."

    MessageRequester("About Vyrn IDE", msg, #PB_MessageRequester_Info)
  EndProcedure
  
  ; <summary>
  ; Route a menu/toolbar/shortcut id (#MNU_*) to the matching command.
  ; </summary>
  ; <param name="menuId">Menu constant such as #MNU_SAVE or #MNU_RUN.</param>
  Procedure Ide_Cmd_Dispatch(menuId.i)
    Select menuId
      Case #MNU_NEW
        Ide_Cmd_New()
      Case #MNU_OPEN
        Ide_Cmd_Open()
      Case #MNU_SAVE
        Ide_Cmd_Save()
      Case #MNU_SAVEAS
        Ide_Cmd_SaveAs()
      Case #MNU_CLOSE
        Ide_Cmd_CloseTab()
      Case #MNU_EXIT
        If Ide_Runner_IsBusy()
          Ide_Runner_Stop()
        EndIf
        If Ide_Editor_ConfirmSaveAll()
          End
        EndIf
      Case #MNU_UNDO
        Ide_Editor_Undo()
      Case #MNU_REDO
        Ide_Editor_Redo()
      Case #MNU_CUT
        Ide_Editor_Cut()
      Case #MNU_COPY
        Ide_Editor_Copy()
      Case #MNU_PASTE
        Ide_Editor_Paste()
      Case #MNU_FIND
        Ide_Cmd_ShowFind(#False)
      Case #MNU_FINDNEXT
        If Ide_FindVisible = 0
          Ide_Cmd_ShowFind(#False)
        EndIf
        Ide_Editor_FindNext()
      Case #MNU_REPLACE
        Ide_Cmd_ShowFind(#True)
      Case #MNU_ZOOMIN
        Ide_Editor_ZoomIn()
      Case #MNU_ZOOMOUT
        Ide_Editor_ZoomOut()
      Case #MNU_ZOOMRESET
        Ide_Editor_ZoomReset()
      Case #MNU_THEME
        Ide_Editor_ToggleTheme()
      Case #MNU_RUN
        Ide_Runner_Run()
      Case #MNU_SYNC_RUNTIME
        Ide_Runner_SyncRuntime()
      Case #MNU_STOP
        Ide_Runner_Stop()
      Case #MNU_ABOUT
        Ide_Cmd_About()
    EndSelect
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 92
; Folding = --
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; EnableOnError
; DisableDebugger
; CompileSourceDirectory
