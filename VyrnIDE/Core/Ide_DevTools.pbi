;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - developer menu actions (paths, ship debug, shortcuts)
; Invoked from Tools -> Developer and Help -> Keyboard Shortcuts.
; PureBasic 6.41

CompilerIf Defined(Ide_DevTools, #PB_Constant) = #False
  #Ide_DevTools = #True

  ; <summary>Open vyrnide.ini in the default editor (create empty file if missing).</summary>
  ; <summary>Reveal the folder that holds vyrnide.ini (portable config dir).</summary>
  Procedure Ide_Dev_OpenConfigFolder()
    Protected dir.s = GetPathPart(Ide_Editor_PrefPath())
    RunProgram("explorer.exe", dir, dir)
    Ide_Ui_SetStatus(Ide_I18n_Pick("Opened IDE config folder", "dev.config_dir_opened"))
  EndProcedure
  
  ; <summary>
  ; Ide_Dev_OpenSettings
  ; </summary>
  Procedure Ide_Dev_OpenSettings()
    Protected path.s = Ide_Editor_PrefPath()
    Protected fn.i
    If FileSize(path) < 0
      fn = CreateFile(#PB_Any, path)
      If fn
        CloseFile(fn)
      EndIf
    EndIf
    RunProgram("notepad.exe", path, GetPathPart(ProgramFilename()))
    Ide_Ui_SetStatus(Ide_I18n_Pick("Opened settings", "dev.settings_opened"))
  EndProcedure

  ; <summary>
  ; Reveal ide\extensions (Or exe folder) in Explorer.
  ; </summary>
  Procedure Ide_Dev_OpenExtFolder()
    Protected folder.s = GetPathPart(ProgramFilename()) + "extensions"
    If FileSize(folder) < 0
      folder = GetPathPart(ProgramFilename()) + "..\extensions"
    EndIf
    If FileSize(folder) < 0
      folder = GetPathPart(ProgramFilename())
    EndIf
    RunProgram("explorer.exe", folder, GetPathPart(ProgramFilename()))
    Ide_Ui_SetStatus(Ide_I18n_Pick("Opened extensions folder", "dev.ext_opened"))
  EndProcedure

  ; <summary>
  ; Open last Standalone Or Compile ship output directory from prefs.
  ; </summary>
  Procedure Ide_Dev_OpenLastShipOut()
    Protected dir.s = Ide_StatusShipDir
    If dir = ""
      dir = Ide_ShipLastStandalone
    EndIf
    If dir = ""
      dir = Ide_ShipLastCompile
    EndIf
    If dir = ""
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("No ship output folder saved yet.", "dev.no_ship_out"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    RunProgram("explorer.exe", dir, GetPathPart(ProgramFilename()))
    Ide_Ui_SetStatus(Ide_I18n_Pick("Opened ship output", "dev.ship_out_opened"))
  EndProcedure

  ; <summary>
  ; Copy the last recorded powershell.exe ship command line To the clipboard.
  ; </summary>
  Procedure Ide_Dev_CopyLastShipCmd()
    If Ide_LastShipPsCmd = ""
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("No ship command yet (run Ship first).", "dev.no_ship_cmd"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    SetClipboardText(Ide_LastShipPsCmd)
    Ide_Ui_SetStatus(Ide_I18n_Pick("Ship command copied", "dev.ship_cmd_copied"))
  EndProcedure

  ; <summary>
  ; Run CLI --dump on the saved active script; stream to output pane.
  ; </summary>
  Procedure Ide_Dev_DumpBytecode()
    Protected path.s, cli.s, args.s, prog.i
    If Ide_Runner_IsBusy()
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Stop the running script first.", "repl.stop_first"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    path = Ide_Runner_EnsureSavedPath()
    If path = ""
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Save the script before dumping bytecode.", "dev.save_before_dump"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    cli = Ide_Runner_FindCli()
    If cli = ""
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Vyrn.exe not found (sync_ide_runtime.ps1).", "dev.no_cli"), #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
    args = Chr(34) + path + Chr(34) + " --dump --batch"
    Ide_Ui_OutputClear()
    Ide_Ui_OutputAppend(">>> --dump " + path)
    prog = RunProgram(cli, args, GetPathPart(path), #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_Hide)
    If prog = 0
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("could not start CLI for --dump", "dev.dump_fail"))
      ProcedureReturn
    EndIf
    Ide_Runner_StreamProgramLines(prog)
    If ProgramExitCode(prog) <> 0
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("dump failed", "dev.dump_failed"))
    Else
      Ide_Ui_OutputAppend("[ok] " + Ide_I18n_Pick("dump finished", "dev.dump_ok"))
    EndIf
    CloseProgram(prog)
    Ide_Ui_SetStatus(Ide_I18n_Pick("Bytecode dump in output", "status.dump_ok"))
  EndProcedure

  ; <summary>
  ; Run CLI `vyrn format file --write` on the saved active script.
  ; </summary>
  Procedure Ide_Dev_FormatDocument()
    Protected path.s, cli.s, args.s, prog.i, code.i, q.s = Chr(34)
    If Ide_Runner_IsBusy()
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Stop the running script first.", "repl.stop_first"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    path = Ide_Runner_EnsureSavedPath()
    If path = ""
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Save the script before formatting.", "dev.save_before_format"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    cli = Ide_Runner_FindCli()
    If cli = ""
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Vyrn.exe not found (sync_ide_runtime.ps1).", "dev.no_cli"), #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
    args = "format " + q + path + q + " --write --batch"
    Ide_Ui_OutputAppend(">>> format --write " + path)
    prog = RunProgram(cli, args, GetPathPart(path), #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_Hide)
    If prog = 0
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("could not start CLI for format", "dev.format_fail"))
      ProcedureReturn
    EndIf
    Ide_Runner_StreamProgramLines(prog)
    code = ProgramExitCode(prog)
    CloseProgram(prog)
    If code <> 0
      Ide_Ui_OutputAppend("[error] " + Ide_I18n_Pick("format failed", "dev.format_failed"))
      Ide_Ui_SetStatus(Ide_I18n_Pick("Format failed", "status.format_fail"))
      ProcedureReturn
    EndIf
    If Ide_Editor_LoadFile(path)
      Ide_Ui_OutputAppend("[ok] " + Ide_I18n_Pick("format applied", "dev.format_ok"))
      Ide_Ui_SetStatus(Ide_I18n_Fmt1("Formatted {path}", "status.formatted", "{path}", GetFilePart(path)))
    Else
      Ide_Ui_OutputAppend("[warn] " + Ide_I18n_Pick("formatted on disk but could not reload tab", "dev.format_reload_warn"))
    EndIf
  EndProcedure

  ; <summary>
  ; Modal cheat sheet For common editor / run shortcuts (i18n).
  ; </summary>
  Procedure Ide_Dev_ShowShortcuts()
    Protected msg.s
    msg = Ide_I18n_Pick("F5 - Run current", "help.sc_f5") + Chr(10)
    msg + Ide_I18n_Pick("Shift+F5 - Stop", "help.sc_stop") + Chr(10)
    msg + Ide_I18n_Pick("F7 - Compile .vyrnc", "help.sc_f7") + Chr(10)
    msg + Ide_I18n_Pick("Ctrl+F5 - Compile and run .vyrnc", "help.sc_cf5") + Chr(10)
    msg + Ide_I18n_Pick("F8 - Check syntax", "help.sc_f8") + Chr(10)
    msg + Chr(10)
    msg + Ide_I18n_Pick("Ctrl+S - Save | Ctrl+Shift+S - Save all", "help.sc_save") + Chr(10)
    msg + Ide_I18n_Pick("Ctrl+F - Find | F3 - Find next", "help.sc_find") + Chr(10)
    msg + Ide_I18n_Pick("Ctrl+G - Go to line | Ctrl+/ - Toggle comment", "help.sc_edit") + Chr(10)
    msg + Ide_I18n_Pick("Ctrl+Shift+I - Format document", "help.sc_format") + Chr(10)
    msg + Ide_I18n_Pick("Ctrl+Shift+R - Sync runtime", "help.sc_sync") + Chr(10)
    msg + Ide_I18n_Pick("Ctrl+Enter - REPL eval (lines; save file for full enum/struct)", "help.sc_repl") + Chr(10)
    MessageRequester(Ide_I18n_Pick("Keyboard Shortcuts", "help.shortcuts_title"), msg, #PB_MessageRequester_Info)
  EndProcedure

  ; <summary>
  ; Set VYRN_IDE_FILE / VYRN_IDE_ROOT before extension Or custom tool processes run.
  ; </summary>
  Procedure Ide_Dev_SetExtensionEnv()
    Protected file.s = Ide_FilePath
    Protected root.s = Ide_Runner_FindRepoRoot()
    If file = ""
      file = ""
    EndIf
    SetEnvironmentVariable("VYRN_IDE_FILE", file)
    If root <> ""
      SetEnvironmentVariable("VYRN_IDE_ROOT", root)
    Else
      SetEnvironmentVariable("VYRN_IDE_ROOT", GetPathPart(ProgramFilename()))
    EndIf
    If Vyrn_IsReady() And Vyrn_DllPath <> ""
      SetEnvironmentVariable("VYRN_DLL", Vyrn_DllPath)
    Else
      RemoveEnvironmentVariable("VYRN_DLL")
    EndIf
  EndProcedure

CompilerEndIf
; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 180
; FirstLine = 151
; Folding = --
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)