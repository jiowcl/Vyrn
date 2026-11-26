;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - editor with tabs, find/replace, highlight + Run (via Vyrn.dll)
; Entry: builds window, dispatches menu/gadget events, polls runner/live-check/auto-save.
; PureBasic 6.41 (Windows x64 only)
;
; Build:
;   .\scripts\build_ide.ps1
;    -  or open ide\VyrnIde.pbp in PureBasic  - 

EnableExplicit

CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
CompilerElse
  MessageRequester("Vyrn IDE", "Vyrn IDE requires Windows x64 PureBasic.", #PB_MessageRequester_Error)
  End
CompilerEndIf

XIncludeFile "..\Vyrn\Native\include\vyrn.pbi"
XIncludeFile ".\Core\Ide_I18n.pbi"
XIncludeFile ".\Core\Ide_Ui.pbi"
XIncludeFile ".\Core\Ide_Highlight.pbi"
XIncludeFile ".\Core\Ide_Project.pbi"
XIncludeFile ".\Core\Ide_RunConfig.pbi"
XIncludeFile ".\Core\Ide_EditorPrefs.pbi"
XIncludeFile ".\Core\Ide_Editor.pbi"
XIncludeFile ".\Core\Ide_EditorAssist.pbi"
XIncludeFile ".\Core\Ide_Search.pbi"
XIncludeFile ".\Core\Ide_Diag.pbi"
XIncludeFile ".\Core\Ide_NavPanels.pbi"
XIncludeFile ".\Core\Ide_Runner.pbi"
XIncludeFile ".\Core\Ide_Version.pbi"
XIncludeFile ".\Core\Ide_RuntimeHealth.pbi"
XIncludeFile ".\Core\Ide_Samples.pbi"
XIncludeFile ".\Core\Ide_DevTools.pbi"
XIncludeFile ".\Core\Ide_Extensions.pbi"
XIncludeFile ".\Core\Ide_Snippets.pbi"
XIncludeFile ".\Core\Ide_Repl.pbi"
XIncludeFile ".\Core\Ide_LintHints.pbi"
XIncludeFile ".\Core\Ide_LiveCheck.pbi"
XIncludeFile ".\Core\Ide_AutoSave.pbi"
XIncludeFile ".\Core\Ide_Welcome.pbi"
XIncludeFile ".\Core\Ide_FirstRun.pbi"
XIncludeFile ".\Core\Ide_Commands.pbi"

; <summary>
; Global OnError handler (1.6.176): never MessageRequester from a Run/Job worker
; thread  -  that closes the IDE. Recover busy flags and defer UI to Poll.
; </summary>
Procedure Ide_ErrorHandler()
  Protected msg.s = ErrorMessage()
  Ide_Runner_NoteUnexpectedError(msg)
  ; On the UI thread, Poll will show the dialog; avoid a second modal here.
  If Ide_Runner_InBackgroundThread() = #False And Ide_OnErrorPending
    Ide_Runner_PollUnexpectedError()
  EndIf
EndProcedure

OnErrorCall(@Ide_ErrorHandler())

Ide_Editor_LoadPrefs()

If Ide_Ui_CreateWindow() = 0
  MessageRequester("Vyrn IDE", "Failed to open main window.", #PB_MessageRequester_Error)
  End 1
EndIf

Ide_Editor_Create()
Ide_Ui_Layout()
Ide_LastLayoutW = WindowWidth(#WIN_IDE)
Ide_LastLayoutH = Ide_Ui_ClientHeight()
Ide_Runner_Init()

; Show DLL load hints in the output pane (e.g. portable copy with only VyrnIDE.exe).
If Vyrn_IsReady() = 0 And Vyrn_LastError <> ""
  Ide_Ui_OutputAppend("[warn] " + ReplaceString(Vyrn_LastError, Chr(10), " | "))
  Ide_Ui_SetStatus(Ide_I18n_Pick("Runtime not loaded  -  place Vyrn.dll next to the IDE or use Sync", "status.runtime_missing"))
ElseIf Vyrn_IsReady() = 0
  Ide_Ui_SetStatus(Ide_I18n_Pick("Runtime not loaded  -  place Vyrn.dll next to the IDE or use Sync", "status.runtime_missing"))
Else
  Ide_RuntimeHealth_AppendStartupNote()
EndIf
Ide_Ui_MaybeOutputLegend()
Ide_Ui_RefreshRuntimeStatus()
Ide_Ui_Layout()
Ide_Ui_OutputClipClient()
Ide_Ui_EnsureStatusOnTop()
Ide_Editor_UpdateCaretStatus()

Define.i argc = CountProgramParameters()
Define.i pi
Define.i opened.i = 0
Define.s bootPath.s = ""

If argc > 0
  For pi = 0 To argc - 1
    bootPath = ProgramParameter(pi)
    If FileSize(bootPath) >= 0
      If Ide_Editor_LoadFile(bootPath)
        opened = opened + 1
      EndIf
    EndIf
  Next
  If opened = 0
    Ide_Editor_New()
  EndIf
Else
  Ide_Editor_New()
EndIf

Ide_Editor_ResizeEditors()
Ide_FirstRun_MaybeShow()
Ide_Ui_MaybeSyncPrompt()

;--- Main event loop: UI, background run/ship jobs, debounced live syntax check ---
Define event.i
Define quit.i = #False
Define dropFiles.s
Define statusRefreshDue.i = 0

Repeat
  event = WaitWindowEvent(50)
  Ide_Editor_PollRestyle()
  Ide_Runner_Poll()
  Ide_LiveCheck_Poll()
  Ide_LintHints_Poll()
  If ElapsedMilliseconds() >= statusRefreshDue
    statusRefreshDue = ElapsedMilliseconds() + 2000
    Ide_Ui_RefreshRuntimeStatus()
  EndIf
  Ide_AutoSave_Poll()
  Ide_Ui_PollWindowSize()

  If Ide_SplitDragging
    If MouseButton(#PB_MouseButton_Left)
      Ide_Ui_SplitDragTo(WindowMouseY(#WIN_IDE))
    Else
      Ide_Ui_EndSplitDrag()
    EndIf
  EndIf

  Select event
    Case #PB_Event_Menu
      Ide_Cmd_Dispatch(EventMenu())

    Case #PB_Event_WindowDrop
      dropFiles = EventDropFiles()
      Ide_Editor_OpenDroppedFiles(dropFiles)

    Case #PB_Event_GadgetDrop
      dropFiles = EventDropFiles()
      Select EventGadget()
        Case #GAD_TABS, #GAD_PROJECT
          Ide_Editor_OpenDroppedFiles(dropFiles)
        Default
          If IsGadget(EventGadget())
            Ide_Editor_OpenDroppedFiles(dropFiles)
          EndIf
      EndSelect

    Case #PB_Event_Gadget
      Select EventGadget()
        Case #GAD_TOOL_OPEN
          Ide_Cmd_Open()
        Case #GAD_TOOL_SAVE
          Ide_Cmd_Save()
        Case #GAD_TOOL_RUN
          Ide_Runner_Run()
        Case #GAD_TOOL_STOP
          Ide_Runner_Stop()
        Case #GAD_TOOL_SYNC
          Ide_Runner_SyncRuntime()
        Case #GAD_TOOL_RUN_ENTRY
          Ide_Project_RunEntry()
        Case #GAD_PROJECT
          If EventType() = #PB_EventType_LeftDoubleClick
            Ide_Project_OnListActivate()
          ElseIf EventType() = #PB_EventType_RightClick
            Ide_Project_PopupAtRow(GetGadgetState(#GAD_PROJECT))
          EndIf
        Case #GAD_OUTLINE
          If EventType() = #PB_EventType_LeftDoubleClick
            Ide_Nav_OutlineActivate()
          EndIf
        Case #GAD_ERRLIST
          If EventType() = #PB_EventType_LeftDoubleClick
            Ide_Nav_ErrorsActivate()
          ElseIf EventType() = #PB_EventType_RightClick
            Ide_Ui_ErrorsPopupShow()
          EndIf
        Case #GAD_TABS
          Ide_Editor_SyncActive()
        Case #GAD_FIND_NEXT
          Ide_Editor_FindNext()
        Case #GAD_REPLACE
          Ide_Editor_ReplaceOnce()
        Case #GAD_REPLACE_ALL
          Ide_Editor_ReplaceAll()
        Case #GAD_REPL_RUN
          Ide_Repl_EvalLine()
        Case #GAD_OUTPUT
          If EventType() = #PB_EventType_RightClick
            Ide_Ui_OutputPopupShow()
          ElseIf EventType() = #PB_EventType_LeftDoubleClick
            Ide_Runner_JumpFromOutput()
          EndIf
        Case #GAD_STATUS
          If EventType() = #PB_EventType_LeftClick
            Ide_Ui_StatusClick()
          EndIf
        Case #GAD_SPLIT
          If EventType() = #PB_EventType_LeftClick
            Ide_Ui_BeginSplitDrag(WindowMouseY(#WIN_IDE))
          EndIf
      EndSelect

    Case #PB_Event_SizeWindow
      Ide_LastLayoutW = WindowWidth(#WIN_IDE)
      Ide_LastLayoutH = Ide_Ui_ClientHeight()
      Ide_Ui_Layout()
      Ide_Editor_ResizeEditors()

    Case #PB_Event_CloseWindow
      If Ide_Runner_IsBusy()
        Ide_Runner_Stop()
      EndIf
      If Ide_Editor_ConfirmSaveAll()
        Ide_Editor_SavePrefs()
        quit = #True
      EndIf
  EndSelect

Until quit

Ide_Runner_Shutdown()
End
; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 21
; Folding = -
; Optimizer
; EnableAsm
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; EnableOnError
; UseIcon = vyrn.ico
; DisableDebugger
; CompileSourceDirectory
; Compiler = PureBasic 6.41 - C Backend (Windows - x64)
; IncludeVersionInfo
; VersionField0 = 1.0.0.0
; VersionField1 = 1.0.0.0
; VersionField2 = Inwazy Technology
; VersionField3 = Vyrn IDE
; VersionField4 = 1.0
; VersionField5 = 1.0
; VersionField6 = Vyrn IDE for Vyrn Bytecode VM Compiler
; VersionField7 = VyrnIDE
; VersionField8 = VyrnIDE
; VersionField9 = Ji-Feng Tsai
; VersionField10 = Inwazy Technology
; VersionField13 = jiowcl@gmail.com
; VersionField14 = https://inwazy.com