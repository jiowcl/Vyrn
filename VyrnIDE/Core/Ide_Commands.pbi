;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - menu / toolbar command handlers
; PureBasic 6.40

CompilerIf Defined(Ide_Commands, #PB_Constant) = #False
  #Ide_Commands = #True
  
  ; <summary>
  ; Ide_Cmd_Save
  ; </summary>
  ; <returns>Returns integer.</returns>
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
  ; Ide_Cmd_SaveAs
  ; </summary>
  ; <returns>Returns integer.</returns>
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
  
  Procedure Ide_Cmd_New()
    If Ide_Runner_IsBusy()
      MessageRequester("Vyrn IDE", "Stop the running script before creating a new file.", #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    Ide_Editor_New()
    Ide_Ui_SetStatus("New file")
  EndProcedure

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

  Procedure Ide_Cmd_CloseTab()
    If Ide_Runner_IsBusy()
      MessageRequester("Vyrn IDE", "Stop the running script before closing a tab.", #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    Ide_Editor_CloseTab()
  EndProcedure

  Procedure Ide_Cmd_ShowFind(showReplace.i = #False)
    Ide_Ui_ShowFind(showReplace)
    Ide_Editor_ResizeEditors()
  EndProcedure
  
  ; <summary>
  ; Ide_Cmd_About
  ; </summary>
  ; <returns>Returns void.</returns>
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
  ; Ide_Cmd_Dispatch
  ; </summary>
  ; <param name="menuId">integer</param>
  ; <returns>Returns void.</returns>
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