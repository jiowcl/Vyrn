;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - startup welcome hints (empty untitled buffer; text from welcome.* i18n keys).
; PureBasic 6.41

CompilerIf Defined(Ide_Welcome, #PB_Constant) = #False
  #Ide_Welcome = #True

  ; <summary>
  ; Vyrn IDE - startup welcome hints (empty untitled buffer; text from welcome.* i18n keys).
  ; </summary>
  ; <returns>string</returns>
  Procedure.s Ide_Welcome_Text()
    Protected s.s
    s = Ide_I18n_Pick("Welcome to Vyrn IDE", "welcome.title") + Chr(10) + Chr(10)
    s + Ide_I18n_Pick("- Drag .vyrn / .lua files onto the window or editor", "welcome.drop") + Chr(10)
    s + Ide_I18n_Pick("- Drop a folder to open as project", "welcome.folder") + Chr(10)
    s + Ide_I18n_Pick("- F5 Run | F8 Check syntax | Tools -> Samples", "welcome.keys") + Chr(10)
    s + Ide_I18n_Pick("- Edit this buffer or File -> Open", "welcome.edit")
    ProcedureReturn s
  EndProcedure

  ; <summary>
  ; IDE: Welcome ApplyToActiveIfEmpty.
  ; </summary>
  Procedure Ide_Welcome_ApplyToActiveIfEmpty()
    Protected g.i, idx.i
    If Ide_ShowWelcome = #False
      ProcedureReturn
    EndIf
    idx = Ide_Editor_ActiveIndex()
    If idx < 0
      ProcedureReturn
    EndIf
    If Ide_Tabs(idx)\path <> ""
      ProcedureReturn
    EndIf
    g = Ide_Tabs(idx)\gadget
    If g = 0
      ProcedureReturn
    EndIf
    If Len(Trim(Ide_Editor_GetTextFrom(g))) > 0
      ProcedureReturn
    EndIf
    ; Plain text only (no SCI readonly  -  avoids Scintilla re-entrancy crashes on some PB builds).
    Ide_Editor_SetTextOn(g, Ide_Welcome_Text())
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