;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - run current buffer via Vyrn.dll
; PureBasic 6.40

CompilerIf Defined(Ide_Runner, #PB_Constant) = #False
  #Ide_Runner = #True

  Global Ide_RunnerReady.i = #False
  
  ; <summary>
  ; Ide_Runner_PrintLog
  ; </summary>
  ; <param name="*userdata">pointer</param>
  ; <param name="*msg">pointer</param>
  ; <returns>Returns void.</returns>
  ProcedureC Ide_Runner_PrintLog(*userdata, *msg)
    Protected line.s
    
    If *msg = 0
      ProcedureReturn
    EndIf
    
    line = PeekS(*msg, -1, #PB_UTF8)
    Ide_Ui_OutputAppend(line)
  EndProcedure
  
  ; <summary>
  ; Ide_Runner_Init
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Runner_Init()
    If Ide_RunnerReady
      ProcedureReturn
    EndIf
    
    If Ide_Vyrn_Ensure()
      Ide_Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)
      Ide_Ui_SetStatus("Ready | Vyrn " + Ide_Vyrn_ProductVersion() + " (ABI " + Str(Ide_Vyrn_Abi) + ")")
    Else
      Ide_Ui_SetStatus("Ready | LibVyrn.dll not loaded — editing only")
    EndIf
    
    Ide_RunnerReady = #True
  EndProcedure
  
  ; <summary>
  ; Ide_Runner_Shutdown
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Runner_Shutdown()
    Ide_Vyrn_Unload()
    Ide_RunnerReady = #False
  EndProcedure
  
  ; <summary>
  ; Ide_Runner_AppendWarnings
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Runner_AppendWarnings()
    Protected i.i, n.i, w.s
    
    n = Ide_Vyrn_WarningCount()
    
    For i = 0 To n - 1
      w = Ide_Vyrn_GetWarning(i)
      
      If w <> ""
        Ide_Ui_OutputAppend("[warn] " + w)
      EndIf
    Next
  EndProcedure
  
  ; <summary>
  ; Ide_Runner_ShowDllError
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Runner_ShowDllError()
    Protected msg.s = Ide_Vyrn_LastError
    
    If msg = ""
      msg = "LibVyrn.dll is not available."
    EndIf
    
    Ide_Ui_OutputAppend("[error] " + ReplaceString(msg, Chr(10), " | "))
    MessageRequester("Vyrn IDE", msg, #PB_MessageRequester_Error)
    Ide_Ui_SetStatus("Ready | LibVyrn.dll not loaded")
  EndProcedure
  
  ; <summary>
  ; Ide_Runner_Run
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Runner_Run()
    Protected path.s, text.s, ok.i, t0.i, elapsed.i, useEval.i

    Ide_Runner_Init()
    Ide_Ui_OutputClear()

    If Ide_Vyrn_Ensure() = 0
      Ide_Runner_ShowDllError()
      ProcedureReturn
    EndIf
    Ide_Vyrn_SetPrintLogger(@Ide_Runner_PrintLog(), 0)

    Ide_Ui_SetStatus("Running...")
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
      ; Untitled buffer: prefer eval (no temp file).
      useEval = #True
      path = "<buffer>"
    EndIf

    Ide_Ui_OutputAppend(">>> " + path)
    t0 = ElapsedMilliseconds()
    
    If useEval
      ok = Ide_Vyrn_Eval(text)
    Else
      ok = Ide_Vyrn_RunFile(path)
    EndIf
    
    elapsed = ElapsedMilliseconds() - t0
    Ide_Runner_AppendWarnings()

    If ok
      Ide_Ui_OutputAppend("[ok] finished in " + Str(elapsed) + " ms")
      Ide_Ui_SetStatus("Ready | last run ok (" + Str(elapsed) + " ms) | Vyrn " + Ide_Vyrn_ProductVersion())
    Else
      If Ide_Vyrn_LastError <> ""
        Ide_Ui_OutputAppend("[error] " + Ide_Vyrn_LastError)
      Else
        Ide_Ui_OutputAppend("[error] run failed")
      EndIf
      
      Ide_Ui_SetStatus("Ready | last run failed")
    EndIf
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 25
; Folding = --
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; EnableOnError
; DisableDebugger
; CompileSourceDirectory