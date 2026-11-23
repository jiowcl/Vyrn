;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - run optional tools from ide\extensions\ (*.ps1) and tools.ini custom commands.
; Output/status for tool start/finish uses Ide_I18n keys ext.* / out.tool_prefix.
; PureBasic 6.41

CompilerIf Defined(Ide_Extensions, #PB_Constant) = #False
  #Ide_Extensions = #True

  #Ide_ExtMax = 8
  #Ide_CustomMax = 4

  Global Ide_ExtCount.i = 0
  Global Dim Ide_ExtPath.s(#Ide_ExtMax - 1)
  Global Dim Ide_ExtCaption.s(#Ide_ExtMax - 1)
  Global Ide_CustomCount.i = 0
  Global Dim Ide_CustomCmd.s(#Ide_CustomMax - 1)
  Global Dim Ide_CustomLabel.s(#Ide_CustomMax - 1)

  ; <summary>
  ; Folder scanned for extension scripts (exe-dir\extensions or repo\ide\extensions).
  ; </summary>
  Procedure.s Ide_Extensions_Folder()
    Protected dir.s = GetPathPart(ProgramFilename())
    Protected root.s, cand.s
    cand = dir + "extensions"
    If ExamineDirectory(1, cand, "*.ps1")
      FinishDirectory(1)
      ProcedureReturn cand + "\"
    EndIf
    root = Ide_Runner_FindRepoRoot()
    If root <> ""
      cand = root + "ide\extensions"
      If ExamineDirectory(1, cand, "*.ps1")
        FinishDirectory(1)
        ProcedureReturn cand + "\"
      EndIf
    EndIf
    ProcedureReturn dir + "extensions\"
  EndProcedure

  ; <summary>
  ; Enumerate *.ps1 under the extensions folder into menu slots.
  ; </summary>
  Procedure Ide_Extensions_LoadToolsIni()
    Protected ini.s, fn.i, line.s, key.s, val.s, eq.i, sect.s
    Protected i.i, root.s
    Ide_CustomCount = 0
    ini = GetPathPart(ProgramFilename()) + "tools.ini"
    If FileSize(ini) < 0
      ini = Ide_Extensions_Folder() + "..\tools.ini"
      If FileSize(ini) < 0
        root = Ide_Runner_FindRepoRoot()
        If root <> ""
          ini = root + "ide\tools.ini"
        EndIf
      EndIf
    EndIf
    If FileSize(ini) < 0
      ProcedureReturn
    EndIf
    fn = ReadFile(#PB_Any, ini)
    If fn = 0
      ProcedureReturn
    EndIf
    sect = ""
    While Eof(fn) = #False
      line = Trim(ReadString(fn, #PB_UTF8))
      If line = "" Or Left(line, 1) = "#" Or Left(line, 1) = ";"
        Continue
      EndIf
      If Left(line, 1) = "[" And Right(line, 1) = "]"
        sect = LCase(Mid(line, 2, Len(line) - 2))
        If Left(sect, 5) = "tool:"
          i = Ide_CustomCount
          If i < #Ide_CustomMax
            Ide_CustomLabel(i) = Mid(sect, 6)
            Ide_CustomCmd(i) = ""
            Ide_CustomCount + 1
          EndIf
        EndIf
        Continue
      EndIf
      eq = FindString(line, "=", 1)
      If eq <= 1 Or Ide_CustomCount = 0
        Continue
      EndIf
      key = Trim(Left(line, eq - 1))
      val = Trim(Mid(line, eq + 1))
      i = Ide_CustomCount - 1
      If LCase(key) = "label" And val <> ""
        Ide_CustomLabel(i) = val
      ElseIf LCase(key) = "command"
        Ide_CustomCmd(i) = val
      EndIf
    Wend
    CloseFile(fn)
  EndProcedure

  ; <summary>
  ; IDE: Extensions RefreshCustomMenu.
  ; </summary>
  Procedure Ide_Extensions_RefreshCustomMenu()
    Protected i.i
    For i = 0 To #Ide_CustomMax - 1
      If i < Ide_CustomCount And Ide_CustomCmd(i) <> ""
        SetMenuItemText(#MENU_MAIN, #MNU_CUSTOM_0 + i, Ide_CustomLabel(i))
        DisableMenuItem(#MENU_MAIN, #MNU_CUSTOM_0 + i, #False)
      Else
        SetMenuItemText(#MENU_MAIN, #MNU_CUSTOM_0 + i, Ide_I18n_Pick("(none)", "custom.none"))
        DisableMenuItem(#MENU_MAIN, #MNU_CUSTOM_0 + i, #True)
      EndIf
    Next
  EndProcedure

  ; <summary>
  ; IDE: Extensions RunCustom.
  ; </summary>
  ; <param name="idxi">see signature</param>
  Procedure Ide_Extensions_RunCustom(idx.i)
    Protected cmd.s, file.s, prog.i, line.s
    If idx < 0 Or idx >= Ide_CustomCount
      ProcedureReturn
    EndIf
    cmd = Ide_CustomCmd(idx)
    If cmd = ""
      ProcedureReturn
    EndIf
    file = Ide_FilePath
    If file = ""
      file = "<untitled>"
    EndIf
    cmd = ReplaceString(cmd, "{file}", file)
    cmd = ReplaceString(cmd, "{dir}", GetPathPart(file))
    Ide_Dev_SetExtensionEnv()
    Ide_Ui_OutputAppend(Ide_I18n_Pick("[tool] ", "out.tool_prefix") + Ide_CustomLabel(idx), #Ide_OutColor_Info)
    prog = RunProgram("cmd.exe", "/c " + cmd, GetPathPart(ProgramFilename()), #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide | #PB_Program_Wait)
    If prog = 0
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("custom tool failed to start", "ext.custom_fail"))
      ProcedureReturn
    EndIf
    While AvailableProgramOutput(prog)
      line = ReadProgramString(prog)
      If line <> ""
        Ide_Ui_OutputAppend(Trim(line))
      EndIf
    Wend
    CloseProgram(prog)
  EndProcedure

  ; <summary>
  ; IDE: Extensions LoadList.
  ; </summary>
  Procedure Ide_Extensions_LoadList()
    Protected folder.s, name.s, root.s
    Ide_ExtCount = 0
    folder = Ide_Extensions_Folder()
    If ExamineDirectory(0, folder, "*.ps1") = 0
      ProcedureReturn
    EndIf
    While NextDirectoryEntry(0)
      If DirectoryEntryType(0) <> #PB_DirectoryEntry_File
        Continue
      EndIf
      name = DirectoryEntryName(0)
      Ide_ExtCaption(Ide_ExtCount) = name
      Ide_ExtPath(Ide_ExtCount) = folder + name
      Ide_ExtCount + 1
      If Ide_ExtCount >= #Ide_ExtMax
        Break
      EndIf
    Wend
    FinishDirectory(0)
  EndProcedure

  ; <summary>
  ; Sync extension menu enable/text with Ide_ExtCount.
  ; </summary>
  Procedure Ide_Extensions_RefreshMenuLabels()
    Protected i.i
    For i = 0 To #Ide_ExtMax - 1
      If i < Ide_ExtCount
        SetMenuItemText(#MENU_MAIN, #MNU_EXT_0 + i, Ide_ExtCaption(i))
        DisableMenuItem(#MENU_MAIN, #MNU_EXT_0 + i, #False)
      Else
        SetMenuItemText(#MENU_MAIN, #MNU_EXT_0 + i, Ide_I18n_Pick("(none)", "ext.none"))
        DisableMenuItem(#MENU_MAIN, #MNU_EXT_0 + i, #True)
      EndIf
    Next
  EndProcedure

  ; <summary>
  ; Populate extension menu slots (call after CreateMenu).
  ; </summary>
  Procedure Ide_Extensions_InitMenu()
    Ide_Extensions_LoadList()
    Ide_Extensions_LoadToolsIni()
    Ide_Extensions_RefreshMenuLabels()
    Ide_Extensions_RefreshCustomMenu()
  EndProcedure

  ; <summary>
  ; Run extension PowerShell with CWD = repo root when known; stream output to the pane.
  ; </summary>
  ; <param name="idx">integer</param>
  Procedure Ide_Extensions_RunIndex(idx.i)
    Protected cwd.s, args.s, prog.i, q.s = Chr(34), line.s, code.i
    If idx < 0 Or idx >= Ide_ExtCount
      ProcedureReturn
    EndIf
    cwd = Ide_Runner_FindRepoRoot()
    If cwd = ""
      cwd = GetPathPart(ProgramFilename())
    EndIf
    args = "-NoProfile -ExecutionPolicy Bypass -File " + q + Ide_ExtPath(idx) + q
    Ide_Dev_SetExtensionEnv()
    Ide_Ui_OutputAppend("[ext] " + Ide_ExtCaption(idx), #Ide_OutColor_Info)
    prog = RunProgram("powershell.exe", args, cwd, #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_Wait | #PB_Program_Hide)
    If prog = 0
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("extension: failed to start", "ext.fail"))
      ProcedureReturn
    EndIf
    While AvailableProgramOutput(prog)
      line = ReadProgramString(prog)
      If line <> ""
        Ide_Ui_OutputAppend(Trim(line))
      EndIf
    Wend
    code = ProgramExitCode(prog)
    CloseProgram(prog)
    If code = 0
      Ide_Ui_SetStatus(Ide_I18n_Pick("Extension finished", "ext.done"))
    Else
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Fmt1("extension exit {code}", "ext.exit", "{code}", Str(code)))
    EndIf
  EndProcedure

  ; <summary>
  ; Optional hook: extensions\on_run_finish.ps1 after each F5 completes.
  ; </summary>
  ; <param name="ok">integer</param>
  Procedure Ide_Extensions_OnCheckFinish(ok.i)
    Protected hook.s, prog.i, line.s
    hook = Ide_Extensions_Folder() + "on_check_finish.ps1"
    If FileSize(hook) < 0
      ProcedureReturn
    EndIf
    SetEnvironmentVariable("VYRN_IDE_CHECK_OK", Str(Bool(ok <> 0)))
    Ide_Dev_SetExtensionEnv()
    prog = RunProgram("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -File " + Chr(34) + hook + Chr(34), GetPathPart(ProgramFilename()), #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide | #PB_Program_Wait)
    If prog
      While AvailableProgramOutput(prog)
        line = ReadProgramString(prog)
        If line <> ""
          Ide_Ui_OutputAppend(Trim(line))
        EndIf
      Wend
      CloseProgram(prog)
    EndIf
  EndProcedure

  ; <summary>
  ; Optional hook: extensions\on_ship_finish.ps1 after Ship jobs.
  ; </summary>
  ; <param name="ok">integer</param>
  Procedure Ide_Extensions_OnShipFinish(ok.i)
    Protected hook.s, prog.i, line.s
    hook = Ide_Extensions_Folder() + "on_ship_finish.ps1"
    If FileSize(hook) < 0
      ProcedureReturn
    EndIf
    SetEnvironmentVariable("VYRN_IDE_SHIP_OK", Str(Bool(ok <> 0)))
    Ide_Dev_SetExtensionEnv()
    prog = RunProgram("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -File " + Chr(34) + hook + Chr(34), GetPathPart(ProgramFilename()), #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide | #PB_Program_Wait)
    If prog
      While AvailableProgramOutput(prog)
        line = ReadProgramString(prog)
        If line <> ""
          Ide_Ui_OutputAppend(Trim(line))
        EndIf
      Wend
      CloseProgram(prog)
    EndIf
  EndProcedure
  
  ; <summary>
  ; Ide_Extensions_OnRunFinish
  ; </summary>
  ; <param name="ok">integer</param>
  Procedure Ide_Extensions_OnRunFinish(ok.i)
    Protected hook.s, prog.i, line.s
    If Ide_Runner_IsBusy()
      ProcedureReturn
    EndIf
    hook = Ide_Extensions_Folder() + "on_run_finish.ps1"
    If FileSize(hook) < 0
      ProcedureReturn
    EndIf
    SetEnvironmentVariable("VYRN_IDE_RUN_OK", Str(ok))
    SetEnvironmentVariable("VYRN_IDE_RUN_EXIT", Str(Bool(ok = 0)))
    Ide_Dev_SetExtensionEnv()
    prog = RunProgram("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -File " + Chr(34) + hook + Chr(34), GetPathPart(ProgramFilename()), #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide | #PB_Program_Wait)
    If prog
      While AvailableProgramOutput(prog)
        line = ReadProgramString(prog)
        If line <> ""
          Ide_Ui_OutputAppend(Trim(line))
        EndIf
      Wend
      CloseProgram(prog)
    EndIf
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 207
; FirstLine = 189
; Folding = ---
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)