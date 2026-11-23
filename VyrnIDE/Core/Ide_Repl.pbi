;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - interactive REPL (Vyrn_Eval) above the output pane
; PureBasic 6.41

CompilerIf Defined(Ide_Repl, #PB_Constant) = #False
  #Ide_Repl = #True

  ; <summary>
  ; Show/hide the REPL gadgets and relayout the bottom pane.
  ; </summary>
  Procedure Ide_Repl_TogglePanel()
    Ide_ReplVisible = Bool(Ide_ReplVisible = 0) ; global in Ide_Ui.pbi
    If IsGadget(#GAD_REPL_INPUT)
      HideGadget(#GAD_REPL_INPUT, Bool(Ide_ReplVisible = 0))
      HideGadget(#GAD_REPL_RUN, Bool(Ide_ReplVisible = 0))
    EndIf
    SetMenuItemState(#MENU_MAIN, #MNU_REPL_PANEL, Ide_ReplVisible)
    Ide_Ui_Layout()
    Ide_Editor_SavePrefs()
  EndProcedure

  ; <summary>
  ; Reset the shared VM without blocking on a full script run (clears globals for a fresh REPL).
  ; </summary>
  Procedure Ide_Repl_ResetVm()
    If Ide_Runner_IsBusy()
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Stop the running script first.", "repl.stop_first"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    Ide_Runner_Init()
    If Vyrn_Ensure() = 0
      Ide_Runner_ShowDllError()
      ProcedureReturn
    EndIf
    If Vyrn_Reset()
      Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
      Ide_RunConfig_ApplyToVm()
      Ide_Ui_OutputAppend("[ok] " + Ide_I18n_Pick("VM state reset", "repl.vm_reset"))
      Ide_Ui_SetStatus(Ide_I18n_Pick("REPL ready (VM reset)", "repl.vm_ready"))
    Else
      Ide_Ui_OutputAppend("[error] " + Vyrn_LastError)
    EndIf
  EndProcedure

  ; <summary>
  ; Evaluate the REPL input via Vyrn_Eval on the UI thread (prints route through the run queue).
  ; </summary>
  Procedure Ide_Repl_EvalLine()
    Protected expr.s, ok.i
    If Ide_Runner_IsBusy()
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Stop the running script before using REPL.", "repl.stop_before"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    If IsGadget(#GAD_REPL_INPUT) = #False
      ProcedureReturn
    EndIf
    expr = Trim(GetGadgetText(#GAD_REPL_INPUT))
    If expr = ""
      ProcedureReturn
    EndIf
    If FindString(LCase(expr), "enum ", 1) > 0 Or FindString(LCase(expr), "struct ", 1) > 0
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Full enum/struct scripts: save the file and press F5 (RunFile). REPL is for short lines.", "repl.save_for_full"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    Ide_Runner_Init()
    If Vyrn_Ensure() = 0
      Ide_Runner_ShowDllError()
      ProcedureReturn
    EndIf
    Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
    Ide_RunConfig_ApplyToVm()
    Ide_Ui_OutputAppend(">>> " + expr, #Ide_OutColor_Info)
    ok = Vyrn_Eval(expr)
    Ide_Runner_DrainQueue()
    If ok
      Ide_Ui_OutputAppend("[ok] " + Ide_I18n_Pick("repl ok", "repl.ok"), #Ide_OutColor_Ok)
      Ide_Ui_SetStatus(Ide_I18n_Pick("REPL eval ok", "repl.eval_ok"))
    Else
      Ide_Ui_OutputAppend("[error] " + ReplaceString(Vyrn_LastError, Chr(10), " | "))
      Ide_Ui_SetStatus(Ide_I18n_Pick("REPL eval failed", "repl.eval_fail"))
    EndIf
    SetGadgetText(#GAD_REPL_INPUT, "")
  EndProcedure

CompilerEndIf