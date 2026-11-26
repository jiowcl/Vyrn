;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - per-run VM limits, capabilities, working directory (via Vyrn.dll)
; Run Configuration dialog uses #PB_Any window/gadget IDs (short-lived modal; no fixed enum).
; PureBasic 6.41

CompilerIf Defined(Ide_RunConfig, #PB_Constant) = #False
  #Ide_RunConfig = #True

  ; Persisted run limits (0 = VM default); applied on each F5 / eval via Ide_RunConfig_ApplyToVm().
  Global Ide_RunCfg_MaxLoops.i = 0
  Global Ide_RunCfg_MaxCalls.i = 256
  Global Ide_RunCfg_MaxIns.i = 0
  Global Ide_RunCfg_CapNet.i = #True
  Global Ide_RunCfg_CapProcess.i = #True
  Global Ide_RunCfg_NetAllow.s = ""
  Global Ide_RunCfg_WorkDir.s = ""
  Global Ide_RunCfg_ScriptArgs.s = ""
  Global Ide_RunCfg_Strict.i = #False
  Global Ide_RunCfg_Bench.i = #False
  Global Ide_RunCfg_Unlimited.i = #False
  Global Ide_RunCfg_JsonDiag.i = #True
  Global Ide_RunCfg_TimeoutSecs.i = 0
  Global Ide_RunCfg_RunViaVyrnc.i = #False
  ; Ship / Compile toolchain (persisted; applied during Ship jobs only).
  Global Ide_RunCfg_VyrnHost.s = ""
  Global Ide_RunCfg_Cmake.s = ""
  Global Ide_RunCfg_ShipPathExtra.s = ""
  Global Ide_RunEnv_PathSave.s = ""
  Global Ide_RunEnv_VyrnHostSave.s = ""
  Global Ide_RunEnv_VyrnHostTouched.i = #False
  Global Ide_RunEnv_PathTouched.i = #False
  #Ide_RunBenchMax = 2000000000

  Declare Ide_Editor_SavePrefs()
  Declare Ide_RunConfig_BeginShipEnv()
  Declare Ide_RunConfig_EndShipEnv()

  ; <summary>
  ; Apply run configuration to the loaded VM (call after Vyrn_Ensure).
  ; </summary>
  Procedure Ide_RunConfig_ApplyToVm()
    Protected caps.l = 0
    Protected loops.i, calls.i, ins.i
    If Ide_RunCfg_CapNet
      caps | #VYRN_CAP_NET
    EndIf
    If Ide_RunCfg_CapProcess
      caps | #VYRN_CAP_PROCESS
    EndIf
    Vyrn_SetCapabilities(caps)
    If Ide_RunCfg_Unlimited
      loops = 0
      calls = 0
      ins = 0
    ElseIf Ide_RunCfg_Bench
      loops = #Ide_RunBenchMax
      ins = #Ide_RunBenchMax
      calls = Ide_RunCfg_MaxCalls
      If calls < 1
        calls = 256
      EndIf
    Else
      loops = Ide_RunCfg_MaxLoops
      calls = Ide_RunCfg_MaxCalls
      ins = Ide_RunCfg_MaxIns
    EndIf
    Vyrn_SetLimits(loops, calls, ins)
    If Ide_RunCfg_NetAllow <> ""
      Vyrn_SetNetAllowlist(Ide_RunCfg_NetAllow)
    EndIf
  EndProcedure

  ; <summary>
  ; Working directory for the run thread (script folder when unset).
  ; Snapshot PATH / VYRN_HOST and apply Run Configuration toolchain for Ship (cmake on PATH, host exe).
  ; </summary>
  Procedure Ide_RunConfig_BeginShipEnv()
    Protected cmake.s, pathExtra.s, p.s
    Ide_RunEnv_PathSave = GetEnvironmentVariable("PATH")
    Ide_RunEnv_VyrnHostSave = GetEnvironmentVariable("VYRN_HOST")
    Ide_RunEnv_VyrnHostTouched = #False
    Ide_RunEnv_PathTouched = #False
    pathExtra = Trim(Ide_RunCfg_ShipPathExtra)
    cmake = Trim(Ide_RunCfg_Cmake)
    If cmake <> ""
      If Right(LCase(cmake), 10) = "cmake.exe"
        p = GetPathPart(cmake)
      ElseIf FileSize(cmake + "cmake.exe") >= 0
        p = cmake
      ElseIf FileSize(cmake) >= 0
        p = GetPathPart(cmake)
      EndIf
      If p <> ""
        If Right(p, 1) <> "\" And Right(p, 1) <> "/"
          p = p + "\"
        EndIf
        If pathExtra <> ""
          pathExtra = p + ";" + pathExtra
        Else
          pathExtra = p
        EndIf
      EndIf
    EndIf
    If pathExtra <> ""
      SetEnvironmentVariable("PATH", pathExtra + ";" + Ide_RunEnv_PathSave)
      Ide_RunEnv_PathTouched = #True
    EndIf
    If Trim(Ide_RunCfg_VyrnHost) <> "" And FileSize(Ide_RunCfg_VyrnHost) >= 0
      SetEnvironmentVariable("VYRN_HOST", Ide_RunCfg_VyrnHost)
      Ide_RunEnv_VyrnHostTouched = #True
    EndIf
  EndProcedure

  ; <summary>
  ; Restore environment after Ship job.
  ; </summary>
  Procedure Ide_RunConfig_EndShipEnv()
    If Ide_RunEnv_PathTouched
      SetEnvironmentVariable("PATH", Ide_RunEnv_PathSave)
      Ide_RunEnv_PathTouched = #False
    EndIf
    If Ide_RunEnv_VyrnHostTouched
      If Ide_RunEnv_VyrnHostSave = ""
        RemoveEnvironmentVariable("VYRN_HOST")
      Else
        SetEnvironmentVariable("VYRN_HOST", Ide_RunEnv_VyrnHostSave)
      EndIf
      Ide_RunEnv_VyrnHostTouched = #False
    EndIf
  EndProcedure
  
  ; <summary>
  ; Ide_RunConfig_RunDirectory
  ; </summary>
  ; <param name="scriptPath">string</param>
  ; <returns>string</returns>
  Procedure.s Ide_RunConfig_RunDirectory(scriptPath.s)
    If Ide_RunCfg_WorkDir <> ""
      If ExamineDirectory(2, Ide_RunCfg_WorkDir, "*")
        FinishDirectory(2)
        ProcedureReturn Ide_RunCfg_WorkDir
      EndIf
    EndIf
    If Ide_ProjectRoot <> ""
      If ExamineDirectory(2, Ide_ProjectRoot, "*")
        FinishDirectory(2)
        ProcedureReturn Ide_ProjectRoot
      EndIf
    EndIf
    If scriptPath <> "" And scriptPath <> "<buffer>"
      ProcedureReturn GetPathPart(scriptPath)
    EndIf
    ProcedureReturn GetPathPart(ProgramFilename())
  EndProcedure

  ; <summary>
  ; Modal run configuration editor (values stored in globals and persisted on OK).
  ; </summary>
  Procedure Ide_RunConfig_ShowDialog()
    Protected ok.i = #False
    Protected done.i = #False
    Protected capNet.i = Bool(Ide_RunCfg_CapNet <> 0)
    Protected capProc.i = Bool(Ide_RunCfg_CapProcess <> 0)
    Protected win.i
    Protected gLoops.i, gCalls.i, gIns.i, gNet.i, gProc.i, gAllow.i, gCwd.i, gArgs.i, gOk.i, gCancel.i
    ; Wider layout for zh-Hant labels (e.g. runcfg.loops).
    Protected dlgW.i = 540
    Protected dlgH.i = 748
    Protected btnY.i = 698
    Protected capStrict.i = Bool(Ide_RunCfg_Strict <> 0)
    Protected capBench.i = Bool(Ide_RunCfg_Bench <> 0)
    Protected capUnlim.i = Bool(Ide_RunCfg_Unlimited <> 0)
    Protected gStrict.i, gBench.i, gUnlim.i, gJson.i, gVyrnc.i, gTimeout.i, gLintPanel.i
    Protected gVyrnHost.i, gCmake.i, gShipPath.i
    Protected capJson.i = Bool(Ide_RunCfg_JsonDiag <> 0)
    Protected capVyrnc.i = Bool(Ide_RunCfg_RunViaVyrnc <> 0)
    Protected m.i = 20
    Protected labelW.i = 248
    Protected fieldX.i = m + labelW + 8
    Protected fieldW.i = dlgW - fieldX - m
    Protected fullW.i = dlgW - m - m

    win = OpenWindow(#PB_Any, 0, 0, dlgW, dlgH, Ide_I18n_Pick("Run Configuration", "runcfg.title"), #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_TitleBar)
    If win
      TextGadget(#PB_Any, m, 16, labelW, 20, Ide_I18n_Pick("Max loops (0=off):", "runcfg.loops"))
      gLoops = StringGadget(#PB_Any, fieldX, 14, fieldW, 22, Str(Ide_RunCfg_MaxLoops))
      TextGadget(#PB_Any, m, 44, labelW, 20, Ide_I18n_Pick("Max calls:", "runcfg.calls"))
      gCalls = StringGadget(#PB_Any, fieldX, 42, fieldW, 22, Str(Ide_RunCfg_MaxCalls))
      TextGadget(#PB_Any, m, 72, labelW, 20, Ide_I18n_Pick("Max ins (0=off):", "runcfg.ins"))
      gIns = StringGadget(#PB_Any, fieldX, 70, fieldW, 22, Str(Ide_RunCfg_MaxIns))
      gNet = CheckBoxGadget(#PB_Any, m, 100, fullW, 22, Ide_I18n_Pick("Enable network (http)", "runcfg.net"))
      SetGadgetState(gNet, capNet)
      gProc = CheckBoxGadget(#PB_Any, m, 124, fullW, 22, Ide_I18n_Pick("Enable process.run", "runcfg.proc"))
      SetGadgetState(gProc, capProc)
      TextGadget(#PB_Any, m, 152, fullW, 32, Ide_I18n_Pick("HTTP allowlist (CSV, empty=all):", "runcfg.allow"))
      gAllow = StringGadget(#PB_Any, m, 186, fullW, 22, Ide_RunCfg_NetAllow)
      TextGadget(#PB_Any, m, 214, fullW, 32, Ide_I18n_Pick("Working directory (empty=script folder):", "runcfg.cwd"))
      gCwd = StringGadget(#PB_Any, m, 248, fullW, 22, Ide_RunCfg_WorkDir)
      TextGadget(#PB_Any, m, 276, fullW, 32, Ide_I18n_Pick("Script args (VYRN_IDE_SCRIPT_ARGS for os.getenv):", "runcfg.args"))
      gArgs = StringGadget(#PB_Any, m, 310, fullW, 22, Ide_RunCfg_ScriptArgs)
      gVyrnc = CheckBoxGadget(#PB_Any, m, 336, fullW, 22, Ide_I18n_Pick("F5: compile to .vyrnc then run (like Ctrl+F5)", "runcfg.vyrnc_run"))
      SetGadgetState(gVyrnc, capVyrnc)
      TextGadget(#PB_Any, m, 362, labelW, 20, Ide_I18n_Pick("CLI timeout sec (F8/check, 0=off):", "runcfg.timeout"))
      gTimeout = StringGadget(#PB_Any, fieldX, 360, fieldW, 22, Str(Ide_RunCfg_TimeoutSecs))
      gJson = CheckBoxGadget(#PB_Any, m, 388, fullW, 22, Ide_I18n_Pick("F8/check: --json-diagnostics (error list)", "runcfg.json_diag"))
      SetGadgetState(gJson, capJson)
      gStrict = CheckBoxGadget(#PB_Any, m, 416, fullW, 22, Ide_I18n_Pick("Strict type checks (-- strict when missing in file)", "runcfg.strict"))
      SetGadgetState(gStrict, capStrict)
      gBench = CheckBoxGadget(#PB_Any, m, 440, fullW, 22, Ide_I18n_Pick("Bench limits (high loop/ins caps)", "runcfg.bench"))
      SetGadgetState(gBench, capBench)
      gUnlim = CheckBoxGadget(#PB_Any, m, 464, fullW, 22, Ide_I18n_Pick("Unlimited execution (no VM caps)", "runcfg.unlimited"))
      SetGadgetState(gUnlim, capUnlim)
      gLintPanel = CheckBoxGadget(#PB_Any, m, 492, fullW, 22, Ide_I18n_Pick("Live lint only when Error List is open", "runcfg.lint_panel"))
      SetGadgetState(gLintPanel, Bool(Ide_LiveLintPanelOnly <> 0))
      TextGadget(#PB_Any, m, 520, fullW, 32, Ide_I18n_Pick("Ship: VYRN_HOST (empty=auto, Compile+Standalone EXE):", "runcfg.vyrn_host"))
      gVyrnHost = StringGadget(#PB_Any, m, 548, fullW, 22, Ide_RunCfg_VyrnHost)
      TextGadget(#PB_Any, m, 576, fullW, 32, Ide_I18n_Pick("Ship: cmake.exe or its folder (prepend PATH):", "runcfg.cmake"))
      gCmake = StringGadget(#PB_Any, m, 604, fullW, 22, Ide_RunCfg_Cmake)
      TextGadget(#PB_Any, m, 632, fullW, 32, Ide_I18n_Pick("Ship: extra PATH (semicolons, tools/clang/gcc):", "runcfg.ship_path"))
      gShipPath = StringGadget(#PB_Any, m, 660, fullW, 22, Ide_RunCfg_ShipPathExtra)
      gOk = ButtonGadget(#PB_Any, dlgW / 2 - 100, btnY, 88, 28, Ide_I18n_Pick("OK", "runcfg.ok"))
      gCancel = ButtonGadget(#PB_Any, dlgW / 2 + 12, btnY, 88, 28, Ide_I18n_Pick("Cancel", "runcfg.cancel"))
      Repeat
        Select WaitWindowEvent()
          Case #PB_Event_CloseWindow
            If EventWindow() = win
              done = #True
            EndIf
          Case #PB_Event_Gadget
            If EventWindow() <> win
              Continue
            EndIf
            Select EventGadget()
              Case gOk
                Ide_RunCfg_MaxLoops = Val(GetGadgetText(gLoops))
                Ide_RunCfg_MaxCalls = Val(GetGadgetText(gCalls))
                Ide_RunCfg_MaxIns = Val(GetGadgetText(gIns))
                Ide_RunCfg_CapNet = GetGadgetState(gNet)
                Ide_RunCfg_CapProcess = GetGadgetState(gProc)
                Ide_RunCfg_NetAllow = GetGadgetText(gAllow)
                Ide_RunCfg_WorkDir = GetGadgetText(gCwd)
                Ide_RunCfg_ScriptArgs = GetGadgetText(gArgs)
                Ide_RunCfg_RunViaVyrnc = GetGadgetState(gVyrnc)
                Ide_RunCfg_TimeoutSecs = Val(GetGadgetText(gTimeout))
                If Ide_RunCfg_TimeoutSecs < 0
                  Ide_RunCfg_TimeoutSecs = 0
                EndIf
                Ide_RunCfg_JsonDiag = GetGadgetState(gJson)
                Ide_RunCfg_Strict = GetGadgetState(gStrict)
                Ide_RunCfg_Bench = GetGadgetState(gBench)
                Ide_RunCfg_Unlimited = GetGadgetState(gUnlim)
                If Ide_RunCfg_Unlimited
                  Ide_RunCfg_Bench = #False
                EndIf
                Ide_LiveLintPanelOnly = GetGadgetState(gLintPanel)
                Ide_RunCfg_VyrnHost = Trim(GetGadgetText(gVyrnHost))
                Ide_RunCfg_Cmake = Trim(GetGadgetText(gCmake))
                Ide_RunCfg_ShipPathExtra = Trim(GetGadgetText(gShipPath))
                Ide_Editor_SavePrefs()
                ok = #True
                done = #True
              Case gCancel
                done = #True
            EndSelect
        EndSelect
      Until done
      CloseWindow(win)
    EndIf
    If ok
      Ide_Ui_SetStatus(Ide_I18n_Pick("Run configuration saved", "status.runcfg_saved"))
    EndIf
  EndProcedure

CompilerEndIf
; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 139
; FirstLine = 104
; Folding = --
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)