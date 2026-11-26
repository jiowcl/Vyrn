;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - debounced background syntax check for saved files (triggers Ide_Runner job).
; PureBasic 6.41

CompilerIf Defined(Ide_LiveCheck, #PB_Constant) = #False
  #Ide_LiveCheck = #True

  ; Debounce interval after the last edit to a saved file before firing CLI compile check.
  #Ide_LiveCheckDelayMs = 1500
  #Ide_LiveCheckLargeDelayMs = 4500
  #Ide_LiveCheckLargeLines = 2500
  ; ElapsedMilliseconds() deadline for the next check (0 = idle).
  Global Ide_LiveCheckDue.i = 0
  ; Path scheduled for live check (must match Ide_FilePath when the timer fires).
  Global Ide_LiveCheckPath.s = ""

  ; <summary>
  ; Schedule a syntax check after edits to a saved on-disk path.
  ; </summary>
  ; <param name="path">string</param>
  Procedure Ide_LiveCheck_Schedule(path.s)
    If Ide_LiveCheckEnabled = #False Or path = ""
      ProcedureReturn
    EndIf
    If Ide_Runner_IsBusy()
      ProcedureReturn
    EndIf
    Ide_LiveCheckPath = path
    Protected delay.i = #Ide_LiveCheckDelayMs
    If CountString(Ide_Editor_GetText(), Chr(10)) + 1 > #Ide_LiveCheckLargeLines
      delay = #Ide_LiveCheckLargeDelayMs
    EndIf
    Ide_LiveCheckDue = ElapsedMilliseconds() + delay
    Ide_LintHints_Schedule(path)
  EndProcedure

  ; <summary>
  ; Main-loop poll: fire check when delay elapsed and path still matches active file.
  ; </summary>
  Procedure Ide_LiveCheck_Poll()
    If Ide_LiveCheckDue = 0
      ProcedureReturn
    EndIf
    If ElapsedMilliseconds() < Ide_LiveCheckDue
      ProcedureReturn
    EndIf
    Ide_LiveCheckDue = 0
    If Ide_LiveCheckPath = "" Or Ide_FilePath = "" Or LCase(Ide_LiveCheckPath) <> LCase(Ide_FilePath)
      ProcedureReturn
    EndIf
    If Ide_Runner_IsBusy()
      ProcedureReturn
    EndIf
    Ide_Runner_CheckSyntaxLive()
  EndProcedure

CompilerEndIf
; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 23
; Folding = -
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)