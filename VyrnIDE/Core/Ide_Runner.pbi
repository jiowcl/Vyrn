;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - background Run via Vyrn.dll + output queue + Stop
; PureBasic 6.40

CompilerIf Defined(Ide_Runner, #PB_Constant) = #False
  #Ide_Runner = #True

  #Ide_OutKind_Print = 0
  #Ide_OutKind_Warn = 1
  #Ide_OutKind_Error = 2
  #Ide_OutKind_Info = 3

  Structure Ide_OutItem
    kind.i
    text.s
  EndStructure

  Global Ide_RunnerReady.i = #False
  Global Ide_RunBusy.i = #False
  Global Ide_RunDone.i = #False
  Global Ide_RunOk.i = #False
  Global Ide_RunStopped.i = #False
  Global Ide_RunThread.i = 0
  Global Ide_RunMutex.i = 0
  Global Ide_RunUseEval.i = #False
  Global Ide_RunPath.s = ""
  Global Ide_RunSource.s = ""
  Global Ide_RunT0.i = 0
  Global Ide_RunElapsed.i = 0
  Global Ide_RunErr.s = ""
  Global NewList Ide_OutQueue.Ide_OutItem()

  Declare Ide_Runner_SetUiRunning(running.i)
  Declare Ide_Runner_Enqueue(kind.i, text.s)

  ProcedureC Ide_Runner_PrintLog(*userdata, *msg)
    Protected line.s
    If *msg = 0
      ProcedureReturn
    EndIf
    line = PeekS(*msg, -1, #PB_UTF8)
    Ide_Runner_Enqueue(#Ide_OutKind_Print, line)
  EndProcedure

  Procedure Ide_Runner_Enqueue(kind.i, text.s)
    If Ide_RunMutex = 0
      ProcedureReturn
    EndIf
    LockMutex(Ide_RunMutex)
    LastElement(Ide_OutQueue())
    AddElement(Ide_OutQueue())
    Ide_OutQueue()\kind = kind
    Ide_OutQueue()\text = text
    UnlockMutex(Ide_RunMutex)
  EndProcedure

  Procedure Ide_Runner_ClearQueue()
    If Ide_RunMutex = 0
      ProcedureReturn
    EndIf
    LockMutex(Ide_RunMutex)
    ClearList(Ide_OutQueue())
    UnlockMutex(Ide_RunMutex)
  EndProcedure

  Procedure Ide_Runner_SetUiRunning(running.i)
    If IsGadget(#GAD_TOOL_RUN)
      DisableGadget(#GAD_TOOL_RUN, running)
    EndIf
    If IsGadget(#GAD_TOOL_STOP)
      DisableGadget(#GAD_TOOL_STOP, Bool(running = 0))
    EndIf
    DisableMenuItem(#MENU_MAIN, #MNU_RUN, running)
    DisableMenuItem(#MENU_MAIN, #MNU_STOP, Bool(running = 0))
  EndProcedure

  Procedure.i Ide_Runner_IsBusy()
    ProcedureReturn Ide_RunBusy
  EndProcedure

  Procedure Ide_Runner_Init()
    If Ide_RunnerReady
      ProcedureReturn
    EndIf
    If Ide_RunMutex = 0
      Ide_RunMutex = CreateMutex()
    EndIf
    Ide_Runner_SetUiRunning(#False)
    If Ide_Vyrn_Ensure()
      Ide_Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
      Ide_Ui_SetStatus("Ready | Vyrn " + Ide_Vyrn_ProductVersion() + " (ABI " + Str(Ide_Vyrn_Abi) + ")")
    Else
      Ide_Ui_SetStatus("Ready | Vyrn.dll not loaded — editing only")
    EndIf
    Ide_RunnerReady = #True
  EndProcedure

  Procedure Ide_Runner_Shutdown()
    If Ide_RunBusy And Ide_RunThread
      If IsThread(Ide_RunThread)
        KillThread(Ide_RunThread)
      EndIf
      Ide_RunBusy = #False
      Ide_RunThread = 0
      Ide_Vyrn_ForceReload()
    EndIf
    Ide_Vyrn_Unload()
    Ide_RunnerReady = #False
  EndProcedure

  Procedure Ide_Runner_ShowDllError()
    Protected msg.s = Ide_Vyrn_LastError
    If msg = ""
      msg = "Vyrn.dll is not available."
    EndIf
    Ide_Ui_OutputAppend("[error] " + ReplaceString(msg, Chr(10), " | "))
    MessageRequester("Vyrn IDE", msg, #PB_MessageRequester_Error)
    Ide_Ui_SetStatus("Ready | Vyrn.dll not loaded")
  EndProcedure

  Procedure Ide_Runner_Thread(*unused)
    Protected ok.i, i.i, n.i, w.s
    Ide_Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
    If Ide_RunUseEval
      ok = Ide_Vyrn_Eval(Ide_RunSource)
    Else
      ok = Ide_Vyrn_RunFile(Ide_RunPath)
    EndIf
    Ide_RunElapsed = ElapsedMilliseconds() - Ide_RunT0
    Ide_RunOk = ok
    If ok = 0
      Ide_RunErr = Ide_Vyrn_LastError
    Else
      Ide_RunErr = ""
    EndIf
    n = Ide_Vyrn_WarningCount()
    For i = 0 To n - 1
      w = Ide_Vyrn_GetWarning(i)
      If w <> ""
        Ide_Runner_Enqueue(#Ide_OutKind_Warn, w)
      EndIf
    Next
    Ide_RunDone = #True
  EndProcedure

  Procedure Ide_Runner_Finish()
    Protected jumpMsg.s = "", jumpWarn.i = #False
    Ide_RunBusy = #False
    Ide_RunThread = 0
    Ide_Runner_SetUiRunning(#False)

    If Ide_RunStopped
      Ide_Ui_OutputAppend("[stopped] execution terminated")
      Ide_Ui_SetStatus("Ready | last run stopped")
      Ide_RunStopped = #False
      Ide_Editor_UpdateCaretStatus()
      ProcedureReturn
    EndIf

    If Ide_RunOk
      Ide_Ui_OutputAppend("[ok] finished in " + Str(Ide_RunElapsed) + " ms")
      Ide_Ui_SetStatus("Ready | last run ok (" + Str(Ide_RunElapsed) + " ms) | Vyrn " + Ide_Vyrn_ProductVersion())
    Else
      If Ide_RunErr <> ""
        Ide_Ui_OutputAppend("[error] " + Ide_RunErr)
        jumpMsg = Ide_RunErr
      Else
        Ide_Ui_OutputAppend("[error] run failed")
      EndIf
      Ide_Ui_SetStatus("Ready | last run failed")
    EndIf

    If jumpMsg <> ""
      Ide_Diag_JumpFromMessage(jumpMsg, #False)
    EndIf
    Ide_Editor_UpdateCaretStatus()
  EndProcedure

  Procedure Ide_Runner_DrainQueue()
    Protected kind.i, text.s
    Protected NewList localQ.Ide_OutItem()
    If Ide_RunMutex = 0
      ProcedureReturn
    EndIf
    LockMutex(Ide_RunMutex)
    ForEach Ide_OutQueue()
      AddElement(localQ())
      localQ()\kind = Ide_OutQueue()\kind
      localQ()\text = Ide_OutQueue()\text
    Next
    ClearList(Ide_OutQueue())
    UnlockMutex(Ide_RunMutex)

    ForEach localQ()
      kind = localQ()\kind
      text = localQ()\text
      Select kind
        Case #Ide_OutKind_Warn
          Ide_Ui_OutputAppend("[warn] " + text)
          If Ide_Diag_ParseLine(text) > 0
            Ide_Diag_JumpFromMessage(text, #True)
          EndIf
        Case #Ide_OutKind_Error
          Ide_Ui_OutputAppend("[error] " + text)
          Ide_Diag_JumpFromMessage(text, #False)
        Case #Ide_OutKind_Info
          Ide_Ui_OutputAppend(text)
        Default
          Ide_Ui_OutputAppend(text)
      EndSelect
    Next
  EndProcedure

  Procedure Ide_Runner_Poll()
    Ide_Runner_DrainQueue()
    If Ide_RunBusy And Ide_RunDone
      Ide_RunDone = #False
      Ide_Runner_DrainQueue()
      Ide_Runner_Finish()
    EndIf
  EndProcedure

  Procedure Ide_Runner_Stop()
    If Ide_RunBusy = 0
      ProcedureReturn
    EndIf
    Ide_RunStopped = #True
    Ide_RunDone = #False
    If Ide_RunThread And IsThread(Ide_RunThread)
      KillThread(Ide_RunThread)
    EndIf
    Ide_RunThread = 0
    Ide_RunBusy = #False
    Ide_Vyrn_ForceReload()
    Ide_Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
    Ide_Runner_ClearQueue()
    Ide_Runner_SetUiRunning(#False)
    Ide_Ui_OutputAppend("[stopped] execution terminated")
    Ide_Ui_SetStatus("Ready | last run stopped")
  EndProcedure

  Procedure Ide_Runner_JumpFromOutput()
    Protected hwnd.i, lineIdx.i, lineStart.i, lineLen.i, *buf, text.s
    If IsGadget(#GAD_OUTPUT) = 0
      ProcedureReturn
    EndIf
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      hwnd = GadgetID(#GAD_OUTPUT)
      lineIdx = SendMessage_(hwnd, #EM_LINEFROMCHAR, -1, 0)
      lineStart = SendMessage_(hwnd, #EM_LINEINDEX, lineIdx, 0)
      lineLen = SendMessage_(hwnd, #EM_LINELENGTH, lineStart, 0)
      If lineLen < 0
        ProcedureReturn
      EndIf
      *buf = AllocateMemory(lineLen + 4)
      If *buf = 0
        ProcedureReturn
      EndIf
      PokeW(*buf, lineLen + 1)
      SendMessage_(hwnd, #EM_GETLINE, lineIdx, *buf)
      text = PeekS(*buf, -1, #PB_Unicode)
      FreeMemory(*buf)
    CompilerElse
      text = ""
    CompilerEndIf
    If text = ""
      ProcedureReturn
    EndIf
    If FindString(LCase(text), "[warn]", 1)
      Ide_Diag_JumpFromMessage(text, #True)
    Else
      Ide_Diag_JumpFromMessage(text, #False)
    EndIf
  EndProcedure

  Procedure Ide_Runner_Run()
    Protected path.s, text.s, useEval.i

    Ide_Runner_Init()
    If Ide_RunBusy
      ProcedureReturn
    EndIf

    Ide_Ui_OutputClear()
    Ide_Editor_ClearDiagnostics()

    If Ide_Vyrn_Ensure() = 0
      Ide_Runner_ShowDllError()
      ProcedureReturn
    EndIf
    Ide_Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)

    text = Ide_Editor_GetText()
    useEval = #False

    If Ide_FilePath <> "" And Ide_Editor_IsModified() = 0
      path = Ide_FilePath
    ElseIf Ide_FilePath <> "" And Ide_Editor_IsModified()
      If Ide_Editor_SaveTo(Ide_FilePath) = 0
        Ide_Ui_OutputAppend("[error] could not save " + Ide_FilePath)
        Ide_Editor_UpdateCaretStatus()
        ProcedureReturn
      EndIf
      path = Ide_FilePath
    Else
      useEval = #True
      path = "<buffer>"
    EndIf

    Ide_Ui_OutputAppend(">>> " + path)
    Ide_Ui_SetStatus("Running...")
    Ide_Runner_ClearQueue()
    Ide_RunUseEval = useEval
    Ide_RunPath = path
    Ide_RunSource = text
    Ide_RunT0 = ElapsedMilliseconds()
    Ide_RunElapsed = 0
    Ide_RunOk = #False
    Ide_RunErr = ""
    Ide_RunDone = #False
    Ide_RunStopped = #False
    Ide_RunBusy = #True
    Ide_Runner_SetUiRunning(#True)

    Ide_RunThread = CreateThread(@Ide_Runner_Thread(), 0)
    If Ide_RunThread = 0
      Ide_RunBusy = #False
      Ide_Runner_SetUiRunning(#False)
      Ide_Ui_OutputAppend("[error] could not start run thread")
      Ide_Ui_SetStatus("Ready | run thread failed")
    EndIf
  EndProcedure

CompilerEndIf
