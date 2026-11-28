;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - one-time startup checklist (no ini file yet, or firstRunDone=0).
; PureBasic 6.41

CompilerIf Defined(Ide_FirstRun, #PB_Constant) = #False
  #Ide_FirstRun = #True

  ; <summary>
  ; Build localized first-run checklist text.
  ; </summary>
  ; <returns>string</returns>
  Procedure.s Ide_FirstRun_Message()
    Protected s.s
    If Vyrn_IsReady()
      s = Ide_I18n_Pick("Runtime: Vyrn.dll is loaded.", "firstrun.dll_ok") + Chr(10)
    Else
      s = Ide_I18n_Pick("Runtime: Vyrn.dll is missing  -  use Sync or place the DLL beside VyrnIDE.exe.", "firstrun.dll_missing") + Chr(10)
      s + Ide_I18n_Pick("Portable copy: unzip vyrnide-*.zip from pack_ide.ps1 (VyrnIDE.exe + Vyrn.dll together), or run .\\scripts\\sync_ide_runtime.ps1 from a source tree.", "firstrun.portable") + Chr(10)
      s + Ide_I18n_Pick("See docs/PackRelease.md for download / NuGet Vyrn.Native.", "firstrun.pack_doc") + Chr(10)
      s + Ide_I18n_Fmt1("Expected pack: vyrnide-{ver}-windows-x64.zip (see VERSION / pack_ide.ps1).", "firstrun.pack_ver", "{ver}", Ide_App_ReadVersion()) + Chr(10)
    EndIf
    s + Ide_I18n_Pick("Language: Tools -> Language (English / Chinese).", "firstrun.lang") + Chr(10)
    s + Ide_I18n_Pick("Shortcuts: F5 Run, F8 syntax, Help -> Keyboard Shortcuts.", "firstrun.keys") + Chr(10)
    s + Ide_I18n_Pick("Console: View -> Error List; drag the bar between errors and output to resize.", "firstrun.errors") + Chr(10)
    s + Ide_I18n_Pick("Live check: Tools -> Live syntax check (optional; toggles in Tools menu).", "firstrun.live") + Chr(10)
    s + Ide_I18n_Pick("File assoc (optional): .\\scripts\\register_vyrnide_file_assoc.ps1", "firstrun.assoc") + Chr(10)
    s + Ide_I18n_Pick("Extensions: ide\\extensions\\*.ps1 (see README.md).", "firstrun.ext")
    ProcedureReturn s
  EndProcedure

  ; <summary>
  ; Show checklist once, then set firstRunDone in vyrnide.ini.
  ; </summary>
  Procedure Ide_FirstRun_MaybeShow()
    If Ide_FirstRunDone
      ProcedureReturn
    EndIf
    MessageRequester(Ide_I18n_Pick("Welcome to Vyrn IDE", "firstrun.title"), Ide_FirstRun_Message(), #PB_MessageRequester_Info)
    Ide_FirstRunDone = #True
    Ide_Editor_SavePrefs()
  EndProcedure

CompilerEndIf
; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 14
; Folding = -
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)