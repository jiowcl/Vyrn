;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - background Run via Vyrn.dll, ship/compile jobs, output queue, Stop.
; User-facing status/output strings use Ide_I18n_Pick/Fmt (see ide\i18n\zh-Hant.ini).
; PureBasic 6.41

CompilerIf Defined(Ide_Runner, #PB_Constant) = #False
  #Ide_Runner = #True

  #Ide_OutKind_Print = 0
  #Ide_OutKind_Warn = 1
  #Ide_OutKind_Error = 2
  #Ide_OutKind_Info = 3

  #Ide_Job_None = 0
  #Ide_Job_Ship = 1
  #Ide_Job_CompileVyrnc = 2
  #Ide_Job_CheckSyntax = 3
  #Ide_Job_CheckLive = 4

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
  Global Ide_RunStatusDue.i = 0
  Global Ide_RunLastStatusSec.i = -1
  Global Ide_RunErr.s = ""
  Global NewList Ide_OutQueue.Ide_OutItem()
  Global Ide_JobBusy.i = #False
  Global Ide_JobDone.i = #False
  Global Ide_JobOk.i = #False
  Global Ide_JobThread.i = 0
  Global Ide_JobKind.i = #Ide_Job_None
  Global Ide_JobRunAfter.i = #False
  Global Ide_JobShipScript.s = ""
  Global Ide_JobShipEntry.s = ""
  Global Ide_JobShipOutDir.s = ""
  Global Ide_JobShipBuildExe.i = #False
  Global Ide_JobCompilePath.s = ""
  Global Ide_JobCompileOut.s = ""
  Global Ide_JobCheckOut.s = ""
  Global Ide_JobStatusLabel.s = ""
  Global Ide_JobCheckSilent.i = #False
  Global Ide_JobForceJsonDiag.i = #False
  Global Ide_RunCfg_SavedArgs.s = ""
  ; 1.6.176: background Run/Job threads must not MessageRequester on OnError.
  Global Ide_InBackgroundThread.i = #False
  Global Ide_OnErrorPending.i = #False
  Global Ide_OnErrorMsg.s = ""
  ; Last run failure text for Output -> Copy Last Run Error (UI thread only).
  Global Ide_LastRunCopyDetail.s = ""
  Global Ide_RunStrictTemp.s = ""

  Declare Ide_Runner_CompileVyrnc(runAfter.i)
  Declare Ide_Extensions_OnRunFinish(ok.i)
  Declare Ide_Extensions_OnCheckFinish(ok.i)
  Declare Ide_Extensions_OnShipFinish(ok.i)
  Declare Ide_Runner_Stop()

  Procedure.s Ide_Runner_LastScriptPath()
    ProcedureReturn Ide_RunPath
  EndProcedure

  Declare Ide_Runner_SetUiRunning(running.i)
  Declare Ide_Runner_Enqueue(kind.i, text.s)
  Declare Ide_Runner_StartThread(path.s, useEval.i, text.s)
  Declare Ide_Runner_RefreshUiLocks()
  Declare Ide_Runner_JobFinish()
  Declare Ide_Runner_NoteUnexpectedError(msg.s)
  Declare Ide_Runner_PollUnexpectedError()
  Declare.i Ide_Runner_InBackgroundThread()
  Declare.s Ide_Runner_WriteTempScript(text.s)
  Declare.s Ide_Runner_FindRepoRoot()
  Declare.s Ide_Runner_FindCli()
  Declare.s Ide_Runner_FindVyrnHost(root.s)
  Declare.s Ide_Runner_QuoteCmdArg(path.s)
  Declare Ide_Runner_Ship(mode.i)
  Declare Ide_Runner_ShipForPath(path.s, mode.i)
  Declare Ide_Cmd_SaveAs()

  ; <summary>
  ; Quote a path for CreateProcess: strip a trailing "\" so closing "\"" is not escaped.
  ; </summary>
  Procedure.s Ide_Runner_QuoteCmdArg(path.s)
    Protected t.s = path
    Protected q.s = Chr(34)
    If Len(t) > 0 And Right(t, 1) = "\"
      t = Left(t, Len(t) - 1)
    EndIf
  ProcedureReturn q + t + q
  EndProcedure

  ; <summary>
  ; Vyrn.dll print logger callback; enqueues UTF-8 print lines for the UI thread.
  ; </summary>
  ; <param name="*userdata">Host userdata (unused).</param>
  ; <param name="*msg">Null-terminated UTF-8 message from the runtime.</param>
  ProcedureC Ide_Runner_PrintLog(*userdata, *msg)
    Protected line.s
    
    ; Worker-thread callback: only enqueue; never touch UI gadgets here.
    If *msg = 0
      ProcedureReturn
    EndIf
    If Ide_RunMutex = 0
      ProcedureReturn
    EndIf
    
    line = PeekS(*msg, -1, #PB_UTF8)
    If line = ""
      ProcedureReturn
    EndIf
    
    Ide_Runner_Enqueue(#Ide_OutKind_Print, line)
  EndProcedure
  
  ; <summary>
  ; Append one output item to the thread-safe run queue.
  ; </summary>
  ; <param name="kind">#Ide_OutKind_Print / Warn / Error / Info.</param>
  ; <param name="text">Line text to show in the output pane.</param>
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
  
  ; <summary>
  ; Clear all pending output queue items under the run mutex.
  ; </summary>
  Procedure Ide_Runner_ClearQueue()
    If Ide_RunMutex = 0
      ProcedureReturn
    EndIf
    
    LockMutex(Ide_RunMutex)
    ClearList(Ide_OutQueue())
    UnlockMutex(Ide_RunMutex)
  EndProcedure
  
  ; <summary>
  ; Enable/disable Run and Stop toolbar buttons and menu items.
  ; </summary>
  ; <param name="running">#True while a script thread is active.</param>
  Procedure Ide_Runner_SetUiRunning(running.i)
    If IsGadget(#GAD_TOOL_RUN)
      DisableGadget(#GAD_TOOL_RUN, running)
    EndIf
    
    If IsGadget(#GAD_TOOL_STOP)
      DisableGadget(#GAD_TOOL_STOP, Bool(running = 0))
    EndIf
    
    DisableMenuItem(#MENU_MAIN, #MNU_RUN, running)
    DisableMenuItem(#MENU_MAIN, #MNU_STOP, Bool(running = 0))
    DisableMenuItem(#MENU_MAIN, #MNU_COMPILE_VYRNC, running)
    DisableMenuItem(#MENU_MAIN, #MNU_RUN_VYRNC, running)
    Ide_Runner_RefreshUiLocks()
  EndProcedure

  ; <summary>
  ; Disable menus while a background CLI/ship job is running (separate from script Run).
  ; </summary>
  Procedure Ide_Runner_RefreshUiLocks()
    Protected block.i = Bool(Ide_JobBusy)
    DisableMenuItem(#MENU_MAIN, #MNU_CHECK_SYNTAX, block)
    DisableMenuItem(#MENU_MAIN, #MNU_SHIP_STANDALONE, block)
    DisableMenuItem(#MENU_MAIN, #MNU_SHIP_STANDALONE_EXE, block)
    DisableMenuItem(#MENU_MAIN, #MNU_SHIP_COMPILE, block)
    DisableMenuItem(#MENU_MAIN, #MNU_SHIP_COMPILE_EXE, block)
    If block
      If Ide_RunBusy = #False
        DisableGadget(#GAD_TOOL_RUN, #True)
        DisableMenuItem(#MENU_MAIN, #MNU_COMPILE_VYRNC, #True)
        DisableMenuItem(#MENU_MAIN, #MNU_RUN_VYRNC, #True)
      EndIf
    ElseIf Ide_RunBusy = #False
      DisableGadget(#GAD_TOOL_RUN, #False)
      DisableMenuItem(#MENU_MAIN, #MNU_COMPILE_VYRNC, #False)
      DisableMenuItem(#MENU_MAIN, #MNU_RUN_VYRNC, #False)
    EndIf
  EndProcedure
  
  ; <summary>
  ; Whether a background run thread is currently active.
  ; </summary>
  ; <returns>#True if busy; otherwise #False.</returns>
  Procedure.i Ide_Runner_IsBusy()
    ProcedureReturn Bool(Ide_RunBusy Or Ide_JobBusy)
  EndProcedure
  
  ; <summary>
  ; One-time runner setup: mutex, UI state, Vyrn.dll load, and print logger.
  ; </summary>
  Procedure Ide_Runner_Init()
    If Ide_RunnerReady
      ProcedureReturn
    EndIf
    
    If Ide_RunMutex = 0
      Ide_RunMutex = CreateMutex()
    EndIf
    
    Ide_Runner_SetUiRunning(#False)
    
    If Vyrn_Ensure()
      Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
      Ide_Ui_SetStatus(Ide_I18n_Fmt2("Ready | Vyrn {ver} (ABI {abi})", "status.ready_abi", "{ver}", Vyrn_ProductVersion(), "{abi}", Str(Vyrn_Abi)))
    Else
      Ide_Ui_SetStatus(Ide_I18n_Pick("Ready | Vyrn.dll not loaded  -  editing only", "status.ready_no_dll"))
    EndIf
    
    Ide_RunnerReady = #True
  EndProcedure
  
  ; <summary>
  ; Cancel any active run, wait briefly for the thread, then unload Vyrn.dll.
  ; </summary>
  Procedure Ide_Runner_Shutdown()
    If Ide_RunBusy And Ide_RunThread
      Vyrn_RequestCancel()
      
      If IsThread(Ide_RunThread)
        WaitThread(Ide_RunThread, 5000)
      EndIf
      
      Ide_RunBusy = #False
      Ide_RunThread = 0
    EndIf

    If Ide_JobBusy And Ide_JobThread
      If IsThread(Ide_JobThread)
        WaitThread(Ide_JobThread, 120000)
      EndIf
      Ide_JobBusy = #False
      Ide_JobThread = 0
    EndIf

    Vyrn_Unload()
    Ide_RunnerReady = #False
  EndProcedure
  
  ; <summary>
  ; Report that Vyrn.dll is unavailable: output line, dialog, and status bar.
  ; </summary>
  Procedure Ide_Runner_ShowDllError()
    Protected msg.s = Vyrn_LastError
    
    If msg = ""
      msg = "Vyrn.dll is not available."
    EndIf
    
    Ide_Ui_OutputAppend("[error] " + ReplaceString(msg, Chr(10), " | "))
    MessageRequester(Ide_I18n_AppTitle(), msg, #PB_MessageRequester_Error)
    Ide_Ui_SetStatus(Ide_I18n_Pick("Ready | Vyrn.dll not loaded", "status.ready_dll_missing"))
  EndProcedure
  
  ; <summary>
  ; True while Ide_Runner_Thread / Ide_Runner_JobThread is on the call stack.
  ; </summary>
  ; <returns>integer</returns>
  Procedure.i Ide_Runner_InBackgroundThread()
    ProcedureReturn Ide_InBackgroundThread
  EndProcedure

  ; <summary>
  ; Recover Run/Job busy flags after an unexpected PureBasic OnError (no UI here).
  ; Background threads enqueue the message; the UI thread shows it via Poll.
  ; </summary>
  ; <param name="msg">ErrorMessage() text from OnErrorCall.</param>
  Procedure Ide_Runner_NoteUnexpectedError(msg.s)
    Protected line.s
    If msg = ""
      msg = "(unknown)"
    EndIf
    line = Ide_I18n_Pick("Unexpected runtime error: ", "out.unexpected") + msg
    If Ide_RunBusy
      Ide_RunOk = #False
      Ide_RunErr = line
      Ide_RunElapsed = ElapsedMilliseconds() - Ide_RunT0
      Ide_Runner_Enqueue(#Ide_OutKind_Error, line)
      Ide_RunDone = #True
    EndIf
    If Ide_JobBusy
      Ide_JobOk = #False
      Ide_Runner_Enqueue(#Ide_OutKind_Error, line)
      Ide_JobDone = #True
    EndIf
    ; Always defer MessageRequester to the UI thread (never call it from a worker).
    Ide_OnErrorMsg = line
    Ide_OnErrorPending = #True
  EndProcedure

  ; <summary>
  ; UI-thread: surface a deferred OnError dialog once, without killing the IDE.
  ; </summary>
  Procedure Ide_Runner_PollUnexpectedError()
    Protected msg.s
    If Ide_OnErrorPending = #False
      ProcedureReturn
    EndIf
    Ide_OnErrorPending = #False
    msg = Ide_OnErrorMsg
    Ide_OnErrorMsg = ""
    If msg = ""
      ProcedureReturn
    EndIf
    ; Output pane already has the line when Run/Job was busy; still notify once.
    MessageRequester(Ide_I18n_AppTitle(), msg, #PB_MessageRequester_Error)
  EndProcedure

  ; <summary>
  ; Heuristic hint after a failed run (output [info] suggestion line).
  ; </summary>
  ; <param name="err">string</param>
  ; <returns>string</returns>
  Procedure.s Ide_Runner_RunSuggestion(err.s)
    Protected low.s = LCase(err)
    If low = ""
      ProcedureReturn ""
    EndIf
    If FindString(low, "match", 1) And (FindString(low, "literal", 1) Or FindString(low, "pattern", 1) Or FindString(low, "expected", 1))
      ProcedureReturn Ide_I18n_Pick("suggestion: use quoted literals in match arms (e.g. 'Status.OK')", "diag.suggest_match")
    EndIf
    If FindString(low, "enum", 1) Or FindString(low, " pop", 1) Or FindString(low, "undef", 1)
      ProcedureReturn Ide_I18n_Pick("suggestion: run full scripts with F5 (RunFile), not the REPL", "diag.suggest_enum")
    EndIf
    If FindString(low, "<eval>", 1) Or FindString(low, "repl", 1)
      ProcedureReturn Ide_I18n_Pick("suggestion: save the file and use F5 so enums/structs compile like the CLI", "diag.suggest_save")
    EndIf
    If FindString(low, "strict", 1)
      ProcedureReturn Ide_I18n_Pick("suggestion: enable Run Configuration -> Strict or add -- strict in the file header", "diag.suggest_strict")
    EndIf
    ProcedureReturn ""
  EndProcedure

  Declare.s Ide_Runner_WriteTempScript(text.s)

  ; <summary>
  ; When Run Configuration strict is on, prepend -- strict If the file lacks it.
  ; </summary>
  ; <param name="path">string</param>
  ; <returns>string</returns>
  Procedure.s Ide_Runner_StrictRunPath(path.s)
    Protected head.s, f.i, chunk.s, OUT.s, temp.s
    If Ide_RunCfg_Strict = 0 Or path = "" Or FileSize(path) < 0
      ProcedureReturn path
    EndIf
    f = ReadFile(#PB_Any, path)
    If f = 0
      ProcedureReturn path
    EndIf
    head = ""
    Repeat
      chunk = ReadString(f)
      If chunk = ""
        Break
      EndIf
      head + chunk + Chr(10)
      If Len(head) > 4096
        Break
      EndIf
    ForEver
    CloseFile(f)
    If FindString(LCase(head), "strict", 1)
      ProcedureReturn path
    EndIf
    f = ReadFile(#PB_Any, path)
    If f = 0
      ProcedureReturn path
    EndIf
    OUT = "-- strict" + Chr(10)
    Repeat
      chunk = ReadString(f)
      If chunk = ""
        Break
      EndIf
      OUT + chunk + Chr(10)
    ForEver
    CloseFile(f)
    temp = Ide_Runner_WriteTempScript(OUT)
    If temp <> ""
      Ide_RunStrictTemp = temp
      ProcedureReturn temp
    EndIf
    ProcedureReturn path
  EndProcedure

  ; <summary>
  ; Background thread body: RunFile or Eval, then enqueue warnings and mark done.
  ; </summary>
  ; <param name="*unused">CreateThread userdata (unused).</param>
  Procedure Ide_Runner_Thread(*unused)
    Protected ok.i, i.i, n.i, w.s

    Ide_InBackgroundThread = #True
    ; Fresh VM each Run so a prior Eval/REPL cannot leave poisoned globals/stack.
    If Vyrn_Reset()
      Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
    Else
      Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
    EndIf
    Ide_RunConfig_ApplyToVm()
    Ide_RunCfg_SavedArgs = GetEnvironmentVariable("VYRN_IDE_SCRIPT_ARGS")
    If Ide_RunCfg_ScriptArgs <> ""
      SetEnvironmentVariable("VYRN_IDE_SCRIPT_ARGS", Ide_RunCfg_ScriptArgs)
    Else
      RemoveEnvironmentVariable("VYRN_IDE_SCRIPT_ARGS")
    EndIf
    If Ide_RunUseEval = #False And Ide_RunPath <> ""
      SetCurrentDirectory(Ide_RunConfig_RunDirectory(Ide_RunPath))
    EndIf

    If Ide_RunUseEval
      ok = Vyrn_Eval(Ide_RunSource)
    Else
      ok = Vyrn_RunFile(Ide_RunPath)
    EndIf
    
    Ide_RunElapsed = ElapsedMilliseconds() - Ide_RunT0
    Ide_RunOk = ok
    
    If ok = 0
      Ide_RunErr = Vyrn_LastError
    Else
      Ide_RunErr = ""
    EndIf
    
    n = Vyrn_WarningCount()
    
    For i = 0 To n - 1
      w = Vyrn_GetWarning(i)
      
      If w <> ""
        Ide_Runner_Enqueue(#Ide_OutKind_Warn, w)
      EndIf
    Next
    If Ide_RunCfg_SavedArgs = ""
      RemoveEnvironmentVariable("VYRN_IDE_SCRIPT_ARGS")
    Else
      SetEnvironmentVariable("VYRN_IDE_SCRIPT_ARGS", Ide_RunCfg_SavedArgs)
    EndIf
    Ide_InBackgroundThread = #False
    Ide_RunDone = #True
  EndProcedure
  
  ; <summary>
  ; UI-thread completion: update output/status, jump to error line, restore Run UI.
  ; </summary>
  Procedure Ide_Runner_Finish()
    Protected jumpMsg.s = "", jumpWarn.i = #False
    Protected errCode.i = 0
    Protected chunk.s, pos.i, eol.i, stRun.s, sugg.s
    Ide_RunBusy = #False
    Ide_RunThread = 0
    Ide_Runner_SetUiRunning(#False)

    If Ide_RunStopped Or LCase(Ide_RunErr) = "cancelled"
      Ide_RunStopped = #True
      
      If Vyrn_Reset()
        Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
      EndIf
      
      Ide_Ui_OutputAppend("[stopped] " + Ide_I18n_Pick("execution cancelled", "out.stopped"))
      Ide_Ui_SetStatus(Ide_I18n_Pick("Ready | last run stopped", "status.run_stopped"))
      Ide_RunStopped = #False
      Ide_Editor_UpdateCaretStatus()
      ProcedureReturn
    EndIf

    Ide_LastRunCopyDetail = ""
    If Ide_RunOk
      Ide_Ui_OutputAppend("[ok] " + Ide_I18n_Fmt1("finished in {ms} ms", "out.finished_ms", "{ms}", Str(Ide_RunElapsed)))
      stRun = Ide_I18n_Fmt1("Ready | last run ok ({ms} ms) | Vyrn {ver}", "status.run_ok", "{ms}", Str(Ide_RunElapsed))
      stRun = ReplaceString(stRun, "{ver}", Vyrn_ProductVersion())
      Ide_Ui_SetStatus(stRun)
    Else
      If Ide_RunPath <> ""
        Ide_Ui_OutputAppend("[info] " + Ide_I18n_Pick("script:", "out.run_script") + " " + Ide_RunPath)
      EndIf
      If Ide_RunErr <> ""
        Ide_LastRunCopyDetail = "[error] " + Ide_RunErr
        If Ide_RunPath <> ""
          Ide_LastRunCopyDetail = Ide_LastRunCopyDetail + Chr(10) + "[info] script: " + Ide_RunPath
        EndIf
        pos = 1
        While pos <= Len(Ide_RunErr)
          eol = FindString(Ide_RunErr, Chr(10), pos)
          If eol = 0
            chunk = Mid(Ide_RunErr, pos)
            pos = Len(Ide_RunErr) + 1
          Else
            chunk = Mid(Ide_RunErr, pos, eol - pos)
            pos = eol + 1
          EndIf
          chunk = Trim(ReplaceString(chunk, Chr(13), ""))
          If chunk <> ""
            Ide_Diag_EmitCliLike(chunk, #False)
            If jumpMsg = ""
              jumpMsg = chunk
            EndIf
          EndIf
        Wend
        errCode = Vyrn_LastErrorCode()
        If errCode <> 0
          Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("code=", "out.run_code") + Str(errCode))
          If Ide_ErrCount > 0
            Ide_ErrCode(Ide_ErrCount - 1) = "runtime." + Str(errCode)
            Ide_Nav_ErrorsRefreshGadget()
          EndIf
        EndIf
      Else
        Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("run failed", "out.run_failed"))
      EndIf
      
      sugg = Ide_Runner_RunSuggestion(Ide_RunErr)
      If sugg <> ""
        Ide_Ui_OutputAppend("[info] " + sugg)
        If Ide_LastRunCopyDetail <> ""
          Ide_LastRunCopyDetail = Ide_LastRunCopyDetail + Chr(10) + "[info] " + sugg
        EndIf
      EndIf
      Ide_Nav_ErrorsPrepareRun()
      Ide_Nav_ErrorsOnSyntaxCheckDone(#False)
      stRun = Ide_I18n_Fmt1("Ready | last run failed ({ms} ms)", "status.run_failed_ms", "{ms}", Str(Ide_RunElapsed))
      Ide_Ui_SetStatus(stRun)
    EndIf
    Ide_RunStrictTemp = ""
    Ide_RunLastStatusSec = -1
    Ide_Extensions_OnRunFinish(Ide_RunOk)
    Ide_Editor_UpdateCaretStatus()
  EndProcedure
  
  ; <summary>
  ; Move queued run output to the output pane; jump on warn/error lines with locations.
  ; </summary>
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
          If Left(text, 8) = "[ndjson]"
            Ide_Diag_PushNdjson(Mid(text, 9))
          Else
            Ide_Ui_OutputAppend("[error] " + text)
            Ide_Nav_ErrorsPush("[error] " + text)
            Ide_Diag_JumpFromMessage(text, #False)
          EndIf
        Case #Ide_OutKind_Info
          Ide_Ui_OutputAppend(text)
        Default
          Ide_Ui_OutputAppend(text)
      EndSelect
    Next
  EndProcedure
  
  ; <summary>
  ; Poll from the main loop: drain output and finish when the run thread completes.
  ; </summary>
  Procedure Ide_Runner_Poll()
    Protected sec.i, runPath.s
    Ide_Runner_DrainQueue()
    
    If Ide_RunBusy
      sec = (ElapsedMilliseconds() - Ide_RunT0) / 1000
      If sec <> Ide_RunLastStatusSec And ElapsedMilliseconds() >= Ide_RunStatusDue
        Ide_RunStatusDue = ElapsedMilliseconds() + 500
        Ide_RunLastStatusSec = sec
        runPath = Ide_RunPath
        If runPath = ""
          runPath = GetFilePart(Ide_FilePath)
        EndIf
        If runPath = ""
          runPath = "<script>"
        EndIf
        Ide_Ui_SetStatus(Ide_I18n_Fmt2("Running ({s}s)... {path}", "status.running_elapsed", "{s}", Str(sec), "{path}", runPath))
      EndIf
    EndIf
    
    If Ide_RunBusy And Ide_RunCfg_TimeoutSecs > 0
      If ElapsedMilliseconds() - Ide_RunT0 >= Ide_RunCfg_TimeoutSecs * 1000
        Ide_Ui_OutputAppend("[warn] " + Ide_I18n_Fmt1("run timeout ({s}s)", "out.run_timeout", "{s}", Str(Ide_RunCfg_TimeoutSecs)))
        Ide_Runner_Stop()
      EndIf
    EndIf

    If Ide_RunBusy And Ide_RunDone
      Ide_RunDone = #False
      Ide_Runner_DrainQueue()
      Ide_Runner_Finish()
    EndIf

    If Ide_JobBusy And Ide_JobDone
      Ide_JobDone = #False
      Ide_Runner_DrainQueue()
      Ide_Runner_JobFinish()
    EndIf

    Ide_Runner_PollUnexpectedError()
  EndProcedure
  
  ; <summary>
  ; Request cancel of the active run via Vyrn_RequestCancel.
  ; </summary>
  Procedure Ide_Runner_Stop()
    If Ide_RunBusy = 0
      ProcedureReturn
    EndIf
    
    If Ide_RunStopped
      ProcedureReturn
    EndIf

    Ide_RunStopped = #True
    If Vyrn_RequestCancel() = 0
      Ide_Ui_SetStatus(Ide_I18n_Pick("Stopping... (cancel unavailable)", "status.stopping_no_cancel"))
    Else
      Ide_Ui_SetStatus(Ide_I18n_Pick("Stopping...", "status.stopping"))
    EndIf
  EndProcedure
  
  ; <summary>
  ; On double-click in the output pane, jump to the line referenced by that text.
  ; </summary>
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
  
  ; <summary>
  ; Write the current buffer to a temp .vyrn so Run can use RunFile (not vyrn_eval).
  ; </summary>
  ; <param name="text">Buffer source.</param>
  ; <returns>Temp path, or "" on failure.</returns>
  Procedure.s Ide_Runner_WriteTempScript(text.s)
    Protected dir.s, path.s, f.i
    dir = GetTemporaryDirectory()
    If dir = ""
      ProcedureReturn ""
    EndIf
    If Right(dir, 1) <> "\" And Right(dir, 1) <> "/"
      dir = dir + "\"
    EndIf
    dir = dir + "vyrn_ide_run\"
    If FileSize(dir) <> -2
      If CreateDirectory(dir) = 0 And FileSize(dir) <> -2
        ProcedureReturn ""
      EndIf
    EndIf
    path = dir + "buffer_" + Str(ElapsedMilliseconds()) + "_" + Str(Random(99999)) + ".vyrn"
    f = CreateFile(#PB_Any, path)
    If f = 0
      ProcedureReturn ""
    EndIf
    WriteStringFormat(f, #PB_UTF8)
    If Ide_RunCfg_Strict And FindString(LCase(text), "strict", 1) = 0
      text = "-- strict" + Chr(10) + text
    EndIf
    WriteString(f, text, #PB_UTF8)
    CloseFile(f)
    ProcedureReturn path
  EndProcedure

  ; <summary>
  ; Start a background run of the active buffer.
  ; Always prefers RunFile (saved path or a temp .vyrn). Avoids vyrn_eval / &lt;eval&gt;
  ; so IDE Run matches CLI file execution (1.6.176).
  ; </summary>
  Procedure Ide_Runner_Run()
    Protected path.s, text.s, useEval.i
    Protected tempPath.s

    Ide_Runner_Init()
    If Ide_RunBusy
      ProcedureReturn
    EndIf

    If Ide_RunCfg_RunViaVyrnc And Ide_FilePath <> ""
      If Ide_Editor_SaveTo(Ide_FilePath) = 0
        Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("could not save ", "out.save_fail") + Ide_FilePath)
        ProcedureReturn
      EndIf
      Ide_Runner_CompileVyrnc(#True)
      ProcedureReturn
    EndIf

    Ide_Ui_OutputClear()
    Ide_Editor_ClearDiagnostics()

    If Vyrn_Ensure() = 0
      Ide_Runner_ShowDllError()
      ProcedureReturn
    EndIf
    
    Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
    Ide_RunConfig_ApplyToVm()

    text = Ide_Editor_GetText()
    useEval = #False

    If Ide_FilePath <> "" And Ide_Editor_IsModified() = 0
      path = Ide_FilePath
    ElseIf Ide_FilePath <> "" And Ide_Editor_IsModified()
      If Ide_Editor_SaveTo(Ide_FilePath) = 0
        Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("could not save ", "out.save_fail") + Ide_FilePath)
        Ide_Editor_UpdateCaretStatus()
        
        ProcedureReturn
      EndIf
      
      path = Ide_FilePath
    Else
      ; Untitled: temp RunFile (optional save prompt when modified).
      Protected resp.i = #PB_MessageRequester_No
      If Ide_Editor_IsModified()
        resp = MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Untitled buffer is modified. Save before Run?", "dlg.untitled_run"), #PB_MessageRequester_YesNoCancel)
        If resp = #PB_MessageRequester_Cancel
          ProcedureReturn
        ElseIf resp = #PB_MessageRequester_Yes
          Ide_Cmd_SaveAs()
          If Ide_FilePath = ""
            ProcedureReturn
          EndIf
          path = Ide_FilePath
          Ide_Ui_OutputAppend(">>> " + path)
          Ide_Runner_StartThread(path, #False, text)
          ProcedureReturn
        EndIf
      EndIf
      tempPath = Ide_Runner_WriteTempScript(text)
      If tempPath = ""
        Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("could not write temp script for Run", "out.temp_fail"))
        Ide_Editor_UpdateCaretStatus()
        ProcedureReturn
      EndIf
      path = tempPath
      Ide_Ui_OutputAppend(">>> <buffer> " + Ide_I18n_Pick("(temp file RunFile)", "out.temp_run") + " " + path)
      Ide_Runner_StartThread(path, #False, text)
      ProcedureReturn
    EndIf

    path = Ide_Runner_StrictRunPath(path)
    Ide_Ui_OutputAppend(">>> " + path)
    Ide_Runner_StartThread(path, useEval, text)
  EndProcedure

  ; <summary>
  ; Run a specific on-disk script path (entry script / automation).
  ; </summary>
  ; <param name="path">string</param>
  Procedure Ide_Runner_RunPath(path.s)
    If path = "" Or Ide_RunBusy
      ProcedureReturn
    EndIf
    If FileSize(path) < 0
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("script not found:", "out.script_missing") + " " + path)
      ProcedureReturn
    EndIf
    Ide_Ui_OutputClear()
    Ide_Editor_ClearDiagnostics()
    If Vyrn_Ensure() = 0
      Ide_Runner_ShowDllError()
      ProcedureReturn
    EndIf
    Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
    Ide_RunConfig_ApplyToVm()
    path = Ide_Runner_StrictRunPath(path)
    Ide_Ui_OutputAppend(">>> " + path)
    Ide_Runner_StartThread(path, #False, "")
  EndProcedure

  ; <summary>
  ; Start the background run thread for a file path (or Eval text).
  ; </summary>
  ; <param name="path">Script or .vyrnc path ("<buffer>" for Eval).</param>
  ; <param name="useEval">#True to Eval text instead of RunFile(path).</param>
  ; <param name="text">Source text for Eval mode.</param>
  Procedure Ide_Runner_StartThread(path.s, useEval.i, text.s)
    Ide_Ui_SetStatus(Ide_I18n_Fmt1("Running {path} ...", "status.running", "{path}", path))
    Ide_Runner_ClearQueue()
    Ide_RunUseEval = useEval
    Ide_RunPath = path
    Ide_RunSource = text
    Ide_RunT0 = ElapsedMilliseconds()
    Ide_RunElapsed = 0
    Ide_RunStatusDue = 0
    Ide_RunLastStatusSec = -1
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
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("could not start run thread", "out.thread_fail"))
      Ide_Ui_SetStatus(Ide_I18n_Pick("Ready | run thread failed", "status.run_thread_fail"))
    EndIf
  EndProcedure

  ; <summary>
  ; Reload Vyrn.dll from the search path (exe dir / Runtime / VYRN_DLL).
  ; Use after scripts\sync_ide_runtime.ps1 or build_ide.ps1 updates the DLL beside the IDE.
  ; </summary>
  ; <returns>integer</returns>
  Procedure.i Ide_Runner_SyncRuntime()
    Protected ok.i, stSync.s
    If Ide_Runner_IsBusy()
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Stop the running script or wait for the current job before syncing the runtime.", "dlg.stop_before_sync"), #PB_MessageRequester_Info)
      ProcedureReturn #False
    EndIf
    Ide_Runner_Init()
    Vyrn_Unload()
    Ide_RunnerReady = #False
    ok = Vyrn_Load()
    If ok = 0
      ok = Vyrn_ForceReload()
    EndIf
    If ok
      Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
      Ide_RunnerReady = #True
      Ide_Ui_OutputAppend("[ok] " + Ide_I18n_Pick("runtime synced: ", "out.sync_line") + Vyrn_DllPath + " | Vyrn " + Vyrn_ProductVersion() + " (ABI " + Str(Vyrn_Abi) + ")")
      stSync = Ide_I18n_Fmt2("Ready | runtime synced | Vyrn {ver} (ABI {abi})", "status.synced", "{ver}", Vyrn_ProductVersion(), "{abi}", Str(Vyrn_Abi))
      Ide_Ui_SetStatus(stSync)
      ProcedureReturn #True
    EndIf
    Ide_Runner_ShowDllError()
    ProcedureReturn #False
  EndProcedure

  ; <summary>
  ; Read available stdout lines from a program into the output queue.
  ; </summary>
  ; <param name="prog">RunProgram handle.</param>
  Procedure Ide_Runner_StreamProgramLines(prog.i)
    Protected line.s, diag.s
    While AvailableProgramOutput(prog)
      line = ReadProgramString(prog)
      If line <> ""
        If Left(Trim(line), 1) = "{" And FindString(line, "vyrn.diagnostics.v1", 1)
          Ide_Runner_Enqueue(#Ide_OutKind_Error, "[ndjson]" + line)
        ElseIf FindString(LCase(line), "[error]", 1)
          Ide_Runner_Enqueue(#Ide_OutKind_Error, line)
        ElseIf FindString(LCase(line), "[warn]", 1)
          Ide_Runner_Enqueue(#Ide_OutKind_Warn, line)
        Else
          Ide_Runner_Enqueue(#Ide_OutKind_Info, line)
        EndIf
      EndIf
    Wend
    line = ReadProgramError(prog, #PB_UTF8)
    While line <> ""
      If FindString(LCase(line), "[error]", 1) Or FindString(LCase(line), "throw", 1)
        Ide_Runner_Enqueue(#Ide_OutKind_Error, line)
      ElseIf FindString(LCase(line), "[warn]", 1)
        Ide_Runner_Enqueue(#Ide_OutKind_Warn, line)
      Else
        Ide_Runner_Enqueue(#Ide_OutKind_Info, line)
      EndIf
      line = ReadProgramError(prog, #PB_UTF8)
    Wend
  EndProcedure

  ; <summary>
  ; Basename of a script path without extension (e.g. hello.vyrn -> hello).
  ; </summary>
  ; <param name="path">string</param>
  ; <returns>string</returns>
  Procedure.s Ide_Runner_ScriptBase(path.s)
    Protected base.s = GetFilePart(path)
    Protected dot.i = FindString(base, ".", 1, #PB_String_NoCase)
    If dot > 1
      ProcedureReturn Left(base, dot - 1)
    EndIf
    ProcedureReturn base
  EndProcedure

  ; <summary>
  ; Ship job body (PowerShell): stream lines to the queue and set Ide_JobOk.
  ; </summary>
  Procedure Ide_Runner_JobRunShip()
    Protected root.s = Ide_Runner_FindRepoRoot()
    Protected ps1.s, args.s, prog.i, code.i, q.s = Chr(34)
    Protected host.s, base.s, exePath.s, vySave.s, vySet.i = #False
    If root = ""
      Ide_Runner_Enqueue(#Ide_OutKind_Error, "[error] " + Ide_I18n_Pick("ship: cannot find repo root (scripts\\ship_standalone.ps1)", "out.ship_no_root"))
      Ide_Runner_Enqueue(#Ide_OutKind_Error, "[error] " + Ide_I18n_Pick("publish: run from publish root (VERSION + scripts\\) or dev repo", "out.ship_publish_root"))
      Ide_JobOk = #False
      ProcedureReturn
    EndIf
    If FileSize(root + "bin\vyrn_miniz.dll") < 0
      Ide_Runner_Enqueue(#Ide_OutKind_Warn, "[warn] ship: bin\vyrn_miniz.dll missing  -  run scripts\\build_vyrn_miniz.ps1 (Windows zlib)")
    EndIf
    ps1 = root + "scripts\" + Ide_JobShipScript
    If FileSize(ps1) < 0
      Ide_Runner_Enqueue(#Ide_OutKind_Error, "[error] " + Ide_I18n_Fmt1("ship: missing {path}", "out.ship_missing", "{path}", ps1))
      Ide_JobOk = #False
      ProcedureReturn
    EndIf
    Ide_RunConfig_BeginShipEnv()
    If Ide_JobShipScript = "ship_compile.ps1"
      Ide_Runner_Enqueue(#Ide_OutKind_Info, "[ship] " + Ide_I18n_Pick("Compile uses --target prebuilt in publish layout", "out.ship_compile_prebuilt"))
    EndIf
    If Ide_JobShipBuildExe And Ide_JobShipScript = "ship_standalone.ps1"
      host = Ide_Runner_FindVyrnHost(root)
      vySave = GetEnvironmentVariable("VYRN_HOST")
      If vySave <> ""
        Ide_Runner_Enqueue(#Ide_OutKind_Info, "[ship] VYRN_HOST=" + vySave)
      ElseIf host <> ""
        SetEnvironmentVariable("VYRN_HOST", host)
        vySet = #True
        Ide_Runner_Enqueue(#Ide_OutKind_Info, "[ship] VYRN_HOST=" + host)
      Else
        Ide_Runner_Enqueue(#Ide_OutKind_Warn, "[warn] " + Ide_I18n_Pick("ship: VyrnHost.exe not found; set Run Configuration VYRN_HOST or scripts\\build_vyrn_host.ps1", "out.ship_no_host"))
      EndIf
    EndIf
    args = "-NoProfile -ExecutionPolicy Bypass -File " + Ide_Runner_QuoteCmdArg(ps1) + " " + Ide_Runner_QuoteCmdArg(Ide_JobShipEntry)
    args + " -OutDir " + Ide_Runner_QuoteCmdArg(Ide_JobShipOutDir)
    If Ide_JobShipBuildExe
      args + " -BuildExe"
    EndIf
    Ide_LastShipPsCmd = "powershell.exe " + args
    Ide_Runner_Enqueue(#Ide_OutKind_Info, "[ship] " + Ide_JobShipScript + " " + Ide_JobShipEntry)
    Ide_Runner_Enqueue(#Ide_OutKind_Info, "[ship] out: " + Ide_JobShipOutDir)
    prog = RunProgram("powershell.exe", args, root, #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_Hide)
    If prog = 0
      Ide_RunConfig_EndShipEnv()
      Ide_Runner_Enqueue(#Ide_OutKind_Error, "[error] " + Ide_I18n_Pick("ship: failed to start powershell", "out.ship_ps_fail"))
      Ide_JobOk = #False
      ProcedureReturn
    EndIf
    While ProgramRunning(prog) Or AvailableProgramOutput(prog)
      Ide_Runner_StreamProgramLines(prog)
      If ProgramRunning(prog) = 0 And AvailableProgramOutput(prog) = 0
        Break
      EndIf
    Wend
    code = ProgramExitCode(prog)
    CloseProgram(prog)
    If vySet
      If vySave = ""
        RemoveEnvironmentVariable("VYRN_HOST")
      Else
        SetEnvironmentVariable("VYRN_HOST", vySave)
      EndIf
    EndIf
    Ide_RunConfig_EndShipEnv()
    If code <> 0
      Ide_Runner_Enqueue(#Ide_OutKind_Error, "[error] " + Ide_I18n_Fmt1("ship exited {code}", "out.ship_exit", "{code}", Str(code)))
      If Ide_JobShipScript = "ship_compile.ps1"
        Ide_Runner_Enqueue(#Ide_OutKind_Error, "[error] " + Ide_I18n_Pick("Compile: need cmake + MSVC on PATH (Run Configuration -> cmake folder)", "out.ship_compile_cmake"))
      EndIf
      Ide_JobOk = #False
      ProcedureReturn
    EndIf
    If Ide_JobShipBuildExe
      base = Ide_Runner_ScriptBase(Ide_JobShipEntry)
      exePath = Ide_JobShipOutDir
      If Right(exePath, 1) <> "\" And Right(exePath, 1) <> "/"
        exePath = exePath + "\"
      EndIf
      exePath = exePath + base + ".exe"
      If FileSize(exePath) < 0
        Ide_Runner_Enqueue(#Ide_OutKind_Error, "[error] ship: expected exe missing: " + exePath)
        If Ide_JobShipScript = "ship_compile.ps1"
          Ide_Runner_Enqueue(#Ide_OutKind_Error, "[error] " + Ide_I18n_Pick("Compile EXE: cmake did not produce <base>.exe (see output above)", "out.ship_compile_no_exe"))
          Ide_Runner_Enqueue(#Ide_OutKind_Error, "[error] " + Ide_I18n_Pick("Ensure cli\\native\\rt\\prebuilt exists (publish pack) and cmake/MSVC in Run Configuration", "out.ship_compile_cmake"))
        Else
          Ide_Runner_Enqueue(#Ide_OutKind_Error, "[error] " + Ide_I18n_Pick("Standalone EXE: set VYRN_HOST / cli\\VyrnHost.exe", "out.ship_no_host"))
        EndIf
        Ide_JobOk = #False
        ProcedureReturn
      EndIf
      Ide_Runner_Enqueue(#Ide_OutKind_Info, "[ok] exe: " + exePath)
    EndIf
    Ide_Runner_Enqueue(#Ide_OutKind_Info, "[ok] " + Ide_I18n_Pick("ship finished", "out.ship_finished"))
    Ide_JobOk = #True
  EndProcedure

  ; <summary>
  ; Compile or syntax-check via CLI --compile-vyrnc (compile-only, does not run the script).
  ; </summary>
  ; <param name="inPath">Source .vyrn path.</param>
  ; <param name="outPath">Target .vyrnc path.</param>
  ; <param name="logTag">[compile] or [check] prefix for the first log line.</param>
  Procedure Ide_Runner_JobRunCompileCli(inPath.s, outPath.s, logTag.s)
    Protected CLI.s = Ide_Runner_FindCli()
    Protected args.s, prog.i, code.i, q.s = Chr(34)
    If CLI = ""
      Ide_Runner_Enqueue(#Ide_OutKind_Error, logTag + ": Vyrn.exe not found (run scripts\sync_ide_runtime.ps1)")
      Ide_JobOk = #False
      ProcedureReturn
    EndIf
    args = "--compile-vyrnc " + q + inPath + q + " -o " + q + outPath + q
    If Ide_RunCfg_JsonDiag Or Ide_JobForceJsonDiag
      args + " --json-diagnostics"
    EndIf
    If Ide_RunCfg_TimeoutSecs > 0
      args + " --timeout " + Str(Ide_RunCfg_TimeoutSecs)
    EndIf
    Ide_Runner_Enqueue(#Ide_OutKind_Info, logTag + " " + inPath + " -> " + outPath)
    prog = RunProgram(CLI, args, GetPathPart(inPath), #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
    If prog = 0
      Ide_Runner_Enqueue(#Ide_OutKind_Error, logTag + ": failed to start " + CLI)
      Ide_JobOk = #False
      ProcedureReturn
    EndIf
    While ProgramRunning(prog) Or AvailableProgramOutput(prog)
      Ide_Runner_StreamProgramLines(prog)
      If ProgramRunning(prog) = 0 And AvailableProgramOutput(prog) = 0
        Break
      EndIf
    Wend
    code = ProgramExitCode(prog)
    CloseProgram(prog)
    If code <> 0 Or FileSize(outPath) < 24
      Ide_Runner_Enqueue(#Ide_OutKind_Error, logTag + " exited " + Str(code))
      Ide_JobOk = #False
      ProcedureReturn
    EndIf
    If logTag = "[check]"
      DeleteFile(outPath)
      Ide_Runner_Enqueue(#Ide_OutKind_Info, "[ok] " + Ide_I18n_Pick("syntax check passed", "out.syntax_ok"))
    Else
      Ide_Runner_Enqueue(#Ide_OutKind_Info, "[ok] " + Ide_I18n_Fmt2("wrote {path} ({bytes} bytes)", "out.wrote_fmt", "{path}", outPath, "{bytes}", Str(FileSize(outPath))))
    EndIf
    Ide_JobOk = #True
  EndProcedure

  ; <summary>
  ; Background worker for ship / compile / syntax-check jobs.
  ; </summary>
  ; <param name="*unused">pointer</param>
  Procedure Ide_Runner_JobThread(*unused)
    Ide_InBackgroundThread = #True
    Select Ide_JobKind
      Case #Ide_Job_Ship
        Ide_Runner_JobRunShip()
      Case #Ide_Job_CompileVyrnc
        Ide_Runner_JobRunCompileCli(Ide_JobCompilePath, Ide_JobCompileOut, "[compile]")
      Case #Ide_Job_CheckSyntax, #Ide_Job_CheckLive
        Ide_Runner_JobRunCompileCli(Ide_JobCompilePath, Ide_JobCheckOut, "[check]")
    EndSelect
    Ide_InBackgroundThread = #False
    Ide_JobDone = #True
  EndProcedure

  ; <summary>
  ; UI-thread completion for CLI/ship jobs: status, diagnostics, optional run-after-compile.
  ; </summary>
  Procedure Ide_Runner_JobFinish()
    Ide_JobBusy = #False
    Ide_JobThread = 0
    Ide_Runner_SetUiRunning(Ide_RunBusy)
    Ide_Runner_RefreshUiLocks()

    If Ide_JobKind = #Ide_Job_CheckSyntax Or Ide_JobKind = #Ide_Job_CheckLive
      If Ide_JobOk
        If Ide_JobKind = #Ide_Job_CheckSyntax
          Ide_Ui_SetStatus(Ide_I18n_Pick("Ready | syntax OK", "status.syntax_ok"))
        Else
          Ide_Ui_SetStatus(Ide_I18n_Pick("Ready | live check OK", "status.live_ok"))
        EndIf
        If Ide_JobKind = #Ide_Job_CheckSyntax
          Ide_Nav_ErrorsOnSyntaxCheckDone(#True)
        EndIf
      Else
        Ide_Ui_SetStatus(Ide_I18n_Pick("Ready | syntax check failed", "status.syntax_fail"))
        If Ide_JobKind = #Ide_Job_CheckSyntax
          Ide_Nav_ErrorsOnSyntaxCheckDone(#False)
        EndIf
      EndIf
      If Ide_JobKind = #Ide_Job_CheckSyntax
        Ide_Extensions_OnCheckFinish(Ide_JobOk)
      EndIf
      Ide_JobForceJsonDiag = #False
      Ide_Editor_UpdateCaretStatus()
      Ide_JobKind = #Ide_Job_None
      Ide_JobCheckSilent = #False
      ProcedureReturn
    EndIf

    If Ide_JobKind = #Ide_Job_Ship
      If Ide_JobShipScript = "ship_standalone.ps1"
        Ide_ShipLastStandalone = Ide_JobShipOutDir
      Else
        Ide_ShipLastCompile = Ide_JobShipOutDir
      EndIf
      Ide_StatusShipDir = Ide_JobShipOutDir
      Ide_Editor_SavePrefs()
      If Ide_JobOk
        Ide_Ui_OutputAppend("[info] " + Ide_I18n_Pick("ship output:", "out.ship_dir") + " " + Ide_JobShipOutDir)
        Ide_Ui_OutputAppend("[info] " + Ide_I18n_Pick("Click status bar to open ship output; Ship menu -> Open last ship output", "out.ship_click"))
        Ide_Ui_SetStatus(Ide_I18n_Fmt1("Ship OK  -  click status bar to open | {dir}", "status.ship_ok_click", "{dir}", Ide_JobShipOutDir))
      Else
        Ide_Ui_OutputAppend("[info] " + Ide_I18n_Pick("ship output (partial):", "out.ship_dir_partial") + " " + Ide_JobShipOutDir)
        Ide_Ui_OutputAppend("[info] " + Ide_I18n_Pick("Status bar: open folder / copy path / copy PowerShell command", "out.ship_fail_actions"))
        If Ide_LastShipPsCmd <> ""
          Ide_Ui_OutputAppend("[info] " + Ide_I18n_Pick("Ship menu or Developer -> Copy last ship command", "out.ship_copy_cmd_hint"))
        EndIf
        Ide_Ui_SetStatus(Ide_I18n_Fmt1("Ship failed  -  click status bar | {dir}", "status.ship_fail_click", "{dir}", Ide_JobShipOutDir))
        Ide_Ui_OutputScrollToLastError()
      EndIf
      Ide_Extensions_OnShipFinish(Ide_JobOk)
      Ide_JobKind = #Ide_Job_None
      ProcedureReturn
    EndIf

    If Ide_JobKind = #Ide_Job_CompileVyrnc
      If Ide_JobOk = #False
        Ide_Ui_SetStatus(Ide_I18n_Pick("Compile failed", "status.compile_fail"))
        Ide_Ui_OutputScrollToLastError()
        Ide_JobKind = #Ide_Job_None
        ProcedureReturn
      EndIf
      If Ide_JobRunAfter = #False
        Ide_Ui_SetStatus(Ide_I18n_Fmt1("Compile OK | {path}", "status.compile_ok", "{path}", Ide_JobCompileOut))
        Ide_JobKind = #Ide_Job_None
        ProcedureReturn
      EndIf
      If Vyrn_Ensure() = 0
        Ide_Runner_ShowDllError()
        Ide_JobKind = #Ide_Job_None
        ProcedureReturn
      EndIf
      Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
      Ide_Ui_OutputAppend(">>> " + Ide_JobCompileOut)
      Ide_Runner_StartThread(Ide_JobCompileOut, #False, "")
      Ide_JobKind = #Ide_Job_None
      ProcedureReturn
    EndIf
  EndProcedure

  ; <summary>
  ; Start a background ship/compile/check job when the runner is idle.
  ; </summary>
  ; <returns>#True when the worker thread started.</returns>
  Procedure.i Ide_Runner_StartJob()
    If Ide_JobBusy Or Ide_RunBusy
      ProcedureReturn #False
    EndIf
    Ide_Runner_ClearQueue()
    Ide_JobDone = #False
    Ide_JobOk = #False
    Ide_JobBusy = #True
    Ide_Runner_SetUiRunning(Ide_RunBusy)
    Ide_Runner_RefreshUiLocks()
    Ide_JobThread = CreateThread(@Ide_Runner_JobThread(), 0)
    If Ide_JobThread = 0
      Ide_JobBusy = #False
      Ide_Runner_RefreshUiLocks()
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("could not start background job", "out.job_fail"))
      ProcedureReturn #False
    EndIf
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Save the active file if needed for CLI jobs; returns usable script path or empty.
  ; </summary>
  ; <returns>string</returns>
  Procedure.s Ide_Runner_EnsureSavedPath()
    If Ide_FilePath = ""
      ProcedureReturn ""
    EndIf
    If Ide_Editor_IsModified()
      If Ide_Editor_SaveTo(Ide_FilePath) = 0
        ProcedureReturn ""
      EndIf
    EndIf
    ProcedureReturn Ide_FilePath
  EndProcedure

  ; <summary>
  ; Compile-only syntax check (F8): --compile-vyrnc to a temp .vyrnc, then delete on success.
  ; Debounced live syntax check (no output-pane clear).
  ; </summary>
  Procedure Ide_Runner_CheckSyntaxLive()
    Protected path.s, tmp.s
    If Ide_RunBusy Or Ide_JobBusy
      ProcedureReturn
    EndIf
    path = Ide_FilePath
    If path = "" Or Ide_Editor_IsModified()
      ProcedureReturn
    EndIf
    tmp = GetTemporaryDirectory() + "vyrn_ide_live_" + Str(ElapsedMilliseconds()) + ".vyrnc"
    Ide_JobKind = #Ide_Job_CheckLive
    Ide_JobCompilePath = path
    Ide_JobCheckOut = tmp
    Ide_JobCheckSilent = #True
    If Ide_Runner_StartJob() = #False
      Ide_JobCheckSilent = #False
    EndIf
  EndProcedure

  ; <summary>
  ; IDE: Runner CheckSyntax.
  ; </summary>
  Procedure Ide_Runner_CheckSyntax()
    Protected path.s, tmp.s
    Ide_Runner_Init()
    If Ide_RunBusy Or Ide_JobBusy
      ProcedureReturn
    EndIf
    path = Ide_Runner_EnsureSavedPath()
    If path = ""
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Save the script before checking syntax.", "dlg.save_before_syntax"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    tmp = GetTemporaryDirectory() + "vyrn_ide_check_" + Str(ElapsedMilliseconds()) + ".vyrnc"
    Ide_Ui_OutputClear()
    Ide_Editor_ClearDiagnostics()
    Ide_Nav_ErrorsPrepareF8()
    Ide_JobKind = #Ide_Job_CheckSyntax
    Ide_JobForceJsonDiag = #False
    Ide_JobCompilePath = path
    Ide_JobCheckOut = tmp
    Ide_Ui_SetStatus(Ide_I18n_Fmt1("Checking syntax {path} ...", "status.checking", "{path}", path))
    If Ide_Runner_StartJob() = #False
      Ide_Ui_SetStatus(Ide_I18n_Pick("Syntax check failed to start", "status.check_start_fail"))
    EndIf
  EndProcedure
  
  ; <summary>
  ; Ide_Runner_CheckSyntaxJsonRefresh
  ; </summary>
  Procedure Ide_Runner_CheckSyntaxJsonRefresh()
    Protected path.s, tmp.s
    Ide_Runner_Init()
    If Ide_RunBusy Or Ide_JobBusy
      ProcedureReturn
    EndIf
    path = Ide_Runner_EnsureSavedPath()
    If path = "" And Ide_RunPath <> "" And FileSize(Ide_RunPath) >= 0
      path = Ide_RunPath
    EndIf
    If path = ""
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Save the script before refreshing diagnostics.", "dlg.save_before_json"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    tmp = GetTemporaryDirectory() + "vyrn_ide_json_" + Str(ElapsedMilliseconds()) + ".vyrnc"
    Ide_Nav_ErrorsPrepareF8()
    Ide_JobKind = #Ide_Job_CheckSyntax
    Ide_JobForceJsonDiag = #True
    Ide_JobCompilePath = path
    Ide_JobCheckOut = tmp
    Ide_Ui_OutputAppend(">>> " + Ide_I18n_Pick("[check] JSON diagnostics refresh", "out.json_recheck"))
    Ide_Ui_SetStatus(Ide_I18n_Fmt1("JSON check {path} ...", "status.json_check", "{path}", path))
    If Ide_Runner_StartJob() = #False
      Ide_JobForceJsonDiag = #False
      Ide_Ui_SetStatus(Ide_I18n_Pick("JSON check failed to start", "status.json_check_fail"))
    EndIf
  EndProcedure

  ; <summary>
  ; Walk parents of the IDE exe looking for scripts\ship_standalone.ps1 (repo root).
  ; </summary>
  ; <returns>Absolute repo root, or empty when not found.</returns>
  Procedure.s Ide_Runner_FindRepoRoot()
    Protected dir.s = GetPathPart(ProgramFilename())
    Protected i.i
    For i = 1 To 8
      If FileSize(dir + "scripts\ship_standalone.ps1") >= 0 And FileSize(dir + "VERSION") >= 0
        ProcedureReturn dir
      EndIf
      If Len(dir) < 4
        Break
      EndIf
      dir = GetPathPart(Left(dir, Len(dir) - 1))
    Next
    ProcedureReturn ""
  EndProcedure

  ; <summary>
  ; Locate prebuilt VyrnHost.exe (env VYRN_HOST, repo bin, IDE folder, parent walk).
  ; </summary>
  ; <param name="root">string</param>
  ; <returns>string</returns>
  Procedure.s Ide_Runner_FindVyrnHost(root.s)
    Protected env.s = GetEnvironmentVariable("VYRN_HOST")
    Protected dir.s, cand.s, i.i
    If env <> "" And FileSize(env) >= 0
      ProcedureReturn env
    EndIf
    If root <> ""
      cand = root + "cli\VyrnHost.exe"
      If FileSize(cand) >= 0
        ProcedureReturn cand
      EndIf
      cand = root + "bin\VyrnHost.exe"
      If FileSize(cand) >= 0
        ProcedureReturn cand
      EndIf
      cand = root + "artifacts\host\VyrnHost.exe"
      If FileSize(cand) >= 0
        ProcedureReturn cand
      EndIf
    EndIf
    dir = GetPathPart(ProgramFilename())
    cand = dir + "VyrnHost.exe"
    If FileSize(cand) >= 0
      ProcedureReturn cand
    EndIf
    For i = 1 To 12
      If Right(dir, 1) <> "\" And Right(dir, 1) <> "/"
        dir = dir + "\"
      EndIf
      cand = dir + "bin\VyrnHost.exe"
      If FileSize(cand) >= 0
        ProcedureReturn cand
      EndIf
      cand = dir + "artifacts\host\VyrnHost.exe"
      If FileSize(cand) >= 0
        ProcedureReturn cand
      EndIf
      If root <> "" And FileSize(dir + "scripts\ship_standalone.ps1") >= 0
        Break
      EndIf
      If Len(dir) < 4
        Break
      EndIf
      dir = GetPathPart(Left(dir, Len(dir) - 1))
    Next
    ProcedureReturn ""
  EndProcedure

  ; <summary>
  ; Run a PowerShell ship script, streaming stdout/stderr into the IDE output pane.
  ; </summary>
  ; <param name="scriptName">Script basename under scripts\ (e.g. ship_standalone.ps1).</param>
  ; <param name="entryPath">Absolute path to the entry .vyrn script.</param>
  ; <param name="outDir">Ship output directory.</param>
  ; <param name="buildExe">#True to pass -BuildExe.</param>
  ; <returns>#True when the process exits 0.</returns>
  Procedure.i Ide_Runner_RunShipScript(scriptName.s, entryPath.s, outDir.s, buildExe.i)
    Protected root.s = Ide_Runner_FindRepoRoot()
    Protected ps1.s, args.s, prog.i, code.i, line.s, q.s = Chr(34)
    If root = ""
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("ship: cannot find repo root (scripts\\ship_standalone.ps1)", "out.ship_no_root"))
      ProcedureReturn #False
    EndIf
    ps1 = root + "scripts\" + scriptName
    If FileSize(ps1) < 0
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Fmt1("ship: missing {path}", "out.ship_missing", "{path}", ps1))
      ProcedureReturn #False
    EndIf
    args = "-NoProfile -ExecutionPolicy Bypass -File " + Ide_Runner_QuoteCmdArg(ps1) + " " + Ide_Runner_QuoteCmdArg(entryPath)
    args + " -OutDir " + Ide_Runner_QuoteCmdArg(outDir)
    If buildExe
      args + " -BuildExe"
    EndIf
    Ide_Ui_OutputAppend("[ship] " + scriptName + " " + entryPath)
    Ide_Ui_OutputAppend("[ship] out: " + outDir)
    prog = RunProgram("powershell.exe", args, root, #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_Wait | #PB_Program_Hide)
    If prog = 0
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("ship: failed to start powershell", "out.ship_ps_fail"))
      ProcedureReturn #False
    EndIf
    While ProgramRunning(prog) Or AvailableProgramOutput(prog)
      If AvailableProgramOutput(prog)
        line = ReadProgramString(prog)
        If line <> ""
          Ide_Ui_OutputAppend(line)
        EndIf
      ElseIf ProgramRunning(prog) = 0
        Break
      EndIf
    Wend
    code = ProgramExitCode(prog)
    CloseProgram(prog)
    If code <> 0
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Fmt1("ship exited {code}", "out.ship_exit", "{code}", Str(code)))
      ProcedureReturn #False
    EndIf
    Ide_Ui_OutputAppend("[ok] " + Ide_I18n_Pick("ship finished", "out.ship_finished"))
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Locate the Vyrn CLI used for --compile-vyrnc: Vyrn.exe beside the IDE
  ; (sync_ide_runtime copies it), Runtime\Vyrn.exe, then the repo build exe.
  ; </summary>
  ; <returns>Absolute CLI path, or empty when none is found.</returns>
  Procedure.s Ide_Runner_FindCli()
    Protected dir.s = GetPathPart(ProgramFilename())
    Protected root.s
    If FileSize(dir + "Vyrn.exe") >= 0
      ProcedureReturn dir + "Vyrn.exe"
    EndIf
    If FileSize(dir + "Runtime\Vyrn.exe") >= 0
      ProcedureReturn dir + "Runtime\Vyrn.exe"
    EndIf
    root = Ide_Runner_FindRepoRoot()
    If root <> ""
      If FileSize(root + "cli\Vyrn.exe") >= 0
        ProcedureReturn root + "cli\Vyrn.exe"
      EndIf
      If FileSize(root + "bin\LuaLiteVM_build.exe") >= 0
        ProcedureReturn root + "bin\LuaLiteVM_build.exe"
      EndIf
    EndIf
    ProcedureReturn ""
  EndProcedure

  ; <summary>
  ; Compile the active file to <base>.vyrnc beside it (VYBX, XOR-obfuscated) via
  ; the CLI, and optionally run the compiled artifact through Vyrn.dll.
  ; </summary>
  ; <param name="runAfter">#True to run the .vyrnc after a successful compile.</param>
  Procedure Ide_Runner_CompileVyrnc(runAfter.i)
    Protected path.s, base.s, outPath.s
    Ide_Runner_Init()
    If Ide_Runner_IsBusy()
      ProcedureReturn
    EndIf
    path = Ide_Runner_EnsureSavedPath()
    If path = ""
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Save the script before compiling to .vyrnc.", "dlg.save_before_compile"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    base = GetFilePart(path)
    If Right(LCase(base), 5) = ".vyrn"
      base = Left(base, Len(base) - 5)
    ElseIf Right(LCase(base), 4) = ".lua"
      base = Left(base, Len(base) - 4)
    EndIf
    outPath = GetPathPart(path) + base + ".vyrnc"
    Ide_Ui_OutputClear()
    Ide_Editor_ClearDiagnostics()
    Ide_JobKind = #Ide_Job_CompileVyrnc
    Ide_JobCompilePath = path
    Ide_JobCompileOut = outPath
    Ide_JobRunAfter = runAfter
    Ide_Ui_SetStatus(Ide_I18n_Fmt1("Compiling {path} ...", "status.compiling", "{path}", path))
    If Ide_Runner_StartJob() = #False
      Ide_Ui_SetStatus(Ide_I18n_Pick("Compile failed to start", "status.compile_start_fail"))
    EndIf
  EndProcedure

  ; <summary>
  ; Ship the active editor file via Standalone or Compile (optional Windows exe build).
  ; Saves a dirty on-disk buffer first; untitled buffers must be saved by the user.
  ; </summary>
  ; <param name="mode">0 = Standalone folder, 1 = Standalone+exe, 2 = Compile folder, 3 = Compile+exe.</param>
  Procedure Ide_Runner_ShipForPath(path.s, mode.i)
    Protected idx.i
    If path = "" Or FileSize(path) < 0
      ProcedureReturn
    EndIf
    idx = Ide_Editor_FindPath(path)
    If idx < 0
      If Ide_Editor_LoadFile(path) = #False
        ProcedureReturn
      EndIf
    Else
      SetGadgetState(#GAD_TABS, idx)
      Ide_Editor_SyncActive()
    EndIf
    Ide_Runner_Ship(mode)
  EndProcedure

  ; <summary>
  ; IDE: Runner Ship.
  ; </summary>
  ; <param name="modei">see signature</param>
  Procedure Ide_Runner_Ship(mode.i)
    Protected path.s, outDir.s, base.s, script.s, buildExe.i, label.s
    If Ide_Runner_IsBusy()
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Stop the running script or wait for the current job before shipping.", "dlg.stop_before_ship"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    path = Ide_Runner_EnsureSavedPath()
    If path = ""
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Save the script before shipping.", "dlg.save_before_ship"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    base = GetFilePart(path)
    If Right(LCase(base), 5) = ".vyrn"
      base = Left(base, Len(base) - 5)
    ElseIf Right(LCase(base), 4) = ".lua"
      base = Left(base, Len(base) - 4)
    EndIf
    Protected pick.s
    ; Default outDir always follows the active script basename (_ship / _compile).
    ; Ide_ShipLast* is only for "Open last ship output" / prefs, not the requester default.
    Select mode
      Case 0
        script = "ship_standalone.ps1" : buildExe = #False : label = "Standalone"
        outDir = GetPathPart(path) + base + "_ship"
      Case 1
        script = "ship_standalone.ps1" : buildExe = #True : label = "Standalone EXE"
        outDir = GetPathPart(path) + base + "_ship"
      Case 2
        script = "ship_compile.ps1" : buildExe = #False : label = "Compile"
        outDir = GetPathPart(path) + base + "_compile"
      Case 3
        script = "ship_compile.ps1" : buildExe = #True : label = "Compile EXE"
        outDir = GetPathPart(path) + base + "_compile"
      Default
        ProcedureReturn
    EndSelect
    pick = InputRequester("Ship output folder", "Edit output path (or keep default):", outDir, #PB_InputRequester_HandleCancel)
    If pick = #PB_InputRequester_Cancel
      Ide_Ui_SetStatus(Ide_I18n_Pick("Ship cancelled", "status.ship_cancelled"))
      ProcedureReturn
    EndIf
    If pick <> ""
      outDir = pick
    EndIf
    Ide_Ui_OutputClear()
    Ide_JobKind = #Ide_Job_Ship
    Ide_JobShipScript = script
    Ide_JobShipEntry = path
    Ide_JobShipOutDir = outDir
    Ide_JobShipBuildExe = buildExe
    Ide_Ui_SetStatus(Ide_I18n_Fmt1("Shipping ({label})...", "status.shipping", "{label}", label))
    If Ide_Runner_StartJob() = #False
      Ide_Ui_SetStatus(Ide_I18n_Pick("Ship failed to start", "status.ship_start_fail"))
    EndIf
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 283
; FirstLine = 232
; Folding = --------
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; EnableOnError
; DisableDebugger
; CompileSourceDirectory