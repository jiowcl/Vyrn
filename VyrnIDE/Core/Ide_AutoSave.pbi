;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - optional debounced auto-save for on-disk tabs
; PureBasic 6.41

CompilerIf Defined(Ide_AutoSave, #PB_Constant) = #False
  #Ide_AutoSave = #True

  Global Ide_AutoSaveDue.i = 0
  #Ide_AutoSaveDelayMs = 30000

  ; <summary>
  ; Mark the active saved file dirty For auto-save timing.
  ; </summary>
  Procedure Ide_AutoSave_Touch()
    If Ide_AutoSaveEnabled = #False Or Ide_FilePath = ""
      ProcedureReturn
    EndIf
    If Ide_Runner_IsBusy()
      ProcedureReturn
    EndIf
    Ide_AutoSaveDue = ElapsedMilliseconds() + #Ide_AutoSaveDelayMs
  EndProcedure

  ; <summary>
  ; Timer from main loop: save active on-disk tab when due.
  ; </summary>
  Procedure Ide_AutoSave_Poll()
    Protected idx.i
    If Ide_AutoSaveDue = 0 Or Ide_AutoSaveEnabled = #False
      ProcedureReturn
    EndIf
    If ElapsedMilliseconds() < Ide_AutoSaveDue
      ProcedureReturn
    EndIf
    Ide_AutoSaveDue = 0
    If Ide_FilePath = "" Or Ide_Runner_IsBusy()
      ProcedureReturn
    EndIf
    idx = Ide_Editor_ActiveIndex()
    If idx < 0
      ProcedureReturn
    EndIf
    If ScintillaSendMessage(Ide_Tabs(idx)\gadget, #SCI_GETMODIFY) = 0
      ProcedureReturn
    EndIf
    If Ide_Editor_SaveTo(Ide_FilePath)
      Ide_Ui_SetStatus(Ide_I18n_Pick("Auto-saved ", "autosave.done") + Ide_FilePath)
    EndIf
  EndProcedure

  ; <summary>
  ; Flip auto-save menu checkmark And persist pref.
  ; </summary>
  Procedure Ide_AutoSave_Toggle()
    Ide_AutoSaveEnabled = Bool(Ide_AutoSaveEnabled = 0)
    SetMenuItemState(#MENU_MAIN, #MNU_AUTOSAVE, Ide_AutoSaveEnabled)
    Ide_AutoSaveDue = 0
    Ide_Editor_SavePrefs()
    If Ide_AutoSaveEnabled
      Ide_Ui_SetStatus(Ide_I18n_Pick("Auto-save on (30s)", "autosave.on"))
    Else
      Ide_Ui_SetStatus(Ide_I18n_Pick("Auto-save off", "autosave.off"))
    EndIf
  EndProcedure

CompilerEndIf
; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 56
; FirstLine = 19
; Folding = -
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)