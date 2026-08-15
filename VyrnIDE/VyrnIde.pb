;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - editor with tabs, find/replace, highlight + Run (via Vyrn.dll)
; PureBasic 6.40 (Windows x64)
;
; Build:
;   .\scripts\build_ide.ps1
;   — or open ide\VyrnIde.pbp in PureBasic —

EnableExplicit

CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
CompilerElse
  MessageRequester("Vyrn IDE", "Vyrn IDE requires Windows x64 PureBasic.", #PB_MessageRequester_Error)
  End
CompilerEndIf

XIncludeFile "..\Vyrn\Native\include\vyrn.pbi"
XIncludeFile ".\Core\Ide_Ui.pbi"
XIncludeFile ".\Core\Ide_Highlight.pbi"
XIncludeFile ".\Core\Ide_Editor.pbi"
XIncludeFile ".\Core\Ide_Diag.pbi"
XIncludeFile ".\Core\Ide_Runner.pbi"
XIncludeFile ".\Core\Ide_Commands.pbi"

Procedure Ide_ErrorHandler()
  MessageRequester("Vyrn IDE", "Unexpected runtime error:" + Chr(10) + ErrorMessage(), #PB_MessageRequester_Error)
EndProcedure

OnErrorCall(@Ide_ErrorHandler())

If Ide_Ui_CreateWindow() = 0
  MessageRequester("Vyrn IDE", "Failed to open main window.", #PB_MessageRequester_Error)
  End 1
EndIf

Ide_Editor_Create()
Ide_Ui_Layout()
Ide_Runner_Init()

If Vyrn_IsReady() = 0 And Vyrn_LastError <> ""
  Ide_Ui_OutputAppend("[warn] " + ReplaceString(Vyrn_LastError, Chr(10), " | "))
EndIf

Define.s bootPath = ""
If CountProgramParameters() > 0
  bootPath = ProgramParameter(0)
  If FileSize(bootPath) >= 0
    Ide_Editor_LoadFile(bootPath)
  Else
    Ide_Editor_New()
  EndIf
Else
  Ide_Editor_New()
EndIf

Ide_Editor_ResizeEditors()

Define event.i
Define quit.i = #False

Repeat
  event = WaitWindowEvent(50)
  Ide_Editor_PollRestyle()
  Ide_Runner_Poll()

  Select event
    Case #PB_Event_Menu
      Ide_Cmd_Dispatch(EventMenu())

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
        Case #GAD_TABS
          Ide_Editor_SyncActive()
        Case #GAD_FIND_NEXT
          Ide_Editor_FindNext()
        Case #GAD_REPLACE
          Ide_Editor_ReplaceOnce()
        Case #GAD_REPLACE_ALL
          Ide_Editor_ReplaceAll()
        Case #GAD_OUTPUT
          If EventType() = #PB_EventType_LeftDoubleClick
            Ide_Runner_JumpFromOutput()
          EndIf
      EndSelect

    Case #PB_Event_SizeWindow
      Ide_Ui_Layout()
      Ide_Editor_ResizeEditors()

    Case #PB_Event_CloseWindow
      If Ide_Runner_IsBusy()
        Ide_Runner_Stop()
      EndIf
      If Ide_Editor_ConfirmSaveAll()
        quit = #True
      EndIf
  EndSelect

Until quit

Ide_Runner_Shutdown()
End

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 20
; Folding = -
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; DllProtection
; EnableOnError
; DisableDebugger
; CompileSourceDirectory
; Compiler = PureBasic 6.41 - C Backend (Windows - x64)