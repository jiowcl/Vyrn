;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - runtime DLL freshness vs native\Vyrn.dll (size/date parity with ide_run_smoke.ps1)
; PureBasic 6.41

CompilerIf Defined(Ide_RuntimeHealth, #PB_Constant) = #False
  #Ide_RuntimeHealth = #True

  ; <summary>
  ; Path To Vyrn.dll Next To the IDE exe.
  ; </summary>
  ; <returns>string</returns>
  Procedure.s Ide_RuntimeHealth_IdeDllPath()
    Protected dir.s = GetPathPart(ProgramFilename())
    Protected p.s = dir + "Vyrn.dll"
    If FileSize(p) >= 0
      ProcedureReturn p
    EndIf
    p = dir + "Runtime\Vyrn.dll"
    If FileSize(p) >= 0
      ProcedureReturn p
    EndIf
    ProcedureReturn ""
  EndProcedure

  ; <summary>
  ; Canonical native\Vyrn.dll under repo root when developing from source.
  ; </summary>
  ; <returns>string</returns>
  Procedure.s Ide_RuntimeHealth_NativeDllPath()
    Protected root.s = Ide_Runner_FindRepoRoot()
    Protected p.s
    If root = ""
      ProcedureReturn ""
    EndIf
    p = root + "native\Vyrn.dll"
    If FileSize(p) >= 0
      ProcedureReturn p
    EndIf
    ProcedureReturn ""
  EndProcedure

  ; <summary>
  ; Human-readable size + modification stamp For About / output.
  ; </summary>
  ; <param name="path">string</param>
  ; <returns>string</returns>
  Procedure.s Ide_RuntimeHealth_FormatStamp(path.s)
    Protected sz.q
    If path = "" Or FileSize(path) < 0
      ProcedureReturn "(missing)"
    EndIf
    sz = FileSize(path)
    ProcedureReturn Str(sz) + " B @ " + FormatDate("%yyyy-%mm-%dd %hh:%ii", GetFileDate(path, #PB_Date_Modified))
  EndProcedure

  ; <summary>
  ; #True when ide\Output Vyrn.dll differs from native\Vyrn.dll (size).
  ; </summary>
  ; <returns>integer</returns>
  Procedure.i Ide_RuntimeHealth_NeedsSync()
    Protected ide.s = Ide_RuntimeHealth_IdeDllPath()
    Protected nat.s = Ide_RuntimeHealth_NativeDllPath()
    Protected sIde.q, sNat.q
    If ide = "" Or nat = ""
      ProcedureReturn #False
    EndIf
    sIde = FileSize(ide)
    sNat = FileSize(nat)
    If sIde <> sNat
      ProcedureReturn #True
    EndIf
  ProcedureReturn #False
  EndProcedure

  ; <summary>
  ; One-line status For About dialog.
  ; </summary>
  ; <returns>string</returns>
  Procedure.s Ide_RuntimeHealth_AboutLine()
    Protected ide.s = Ide_RuntimeHealth_IdeDllPath()
    Protected nat.s = Ide_RuntimeHealth_NativeDllPath()
    Protected line.s
    If ide <> ""
      line = "DLL: " + ide + " (" + Ide_RuntimeHealth_FormatStamp(ide) + ")"
    Else
      line = "DLL: (not loaded)"
    EndIf
    If nat <> ""
      line = line + Chr(10) + "native: " + nat + " (" + Ide_RuntimeHealth_FormatStamp(nat) + ")"
      If Ide_RuntimeHealth_NeedsSync()
        line = line + Chr(10) + Ide_I18n_Pick("DLL out of sync with native  -  Tools -> Sync Runtime (Ctrl+Shift+R) or run sync_ide_runtime.ps1", "runtime.sync_hint")
      Else
        line = line + Chr(10) + Ide_I18n_Pick("DLL matches native\\Vyrn.dll size", "runtime.sync_ok")
      EndIf
    EndIf
    ProcedureReturn line
  EndProcedure

  ; <summary>
  ; Append startup warning To output when DLLs diverge.
  ; </summary>
  Procedure Ide_RuntimeHealth_AppendStartupNote()
    If Ide_RuntimeHealth_NeedsSync() = #False
      ProcedureReturn
    EndIf
    Ide_Ui_OutputAppend("[warn] " + Ide_I18n_Pick("ide\\Output\\Vyrn.dll differs from native\\Vyrn.dll  -  run .\\scripts\\sync_ide_runtime.ps1 or Ctrl+Shift+R", "runtime.startup_warn"))
  EndProcedure

CompilerEndIf
; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 14
; Folding = --
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)