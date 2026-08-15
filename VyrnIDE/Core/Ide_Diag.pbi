;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - parse compiler/runtime diagnostics and jump to source lines
; PureBasic 6.40

CompilerIf Defined(Ide_Diag, #PB_Constant) = #False
  #Ide_Diag = #True

  ; <summary>
  ; Remove leading [error]/[warn]/>>> prefixes before line parsing.
  ; </summary>
  ; <param name="msg">Raw diagnostic or output line.</param>
  ; <returns>Trimmed message body without the known prefix.</returns>
  Procedure.s Ide_Diag_StripPrefix(msg.s)
    Protected s.s = Trim(msg)
    
    If Left(LCase(s), 8) = "[error] "
      ProcedureReturn Trim(Mid(s, 9))
    EndIf
    
    If Left(LCase(s), 7) = "[warn] "
      ProcedureReturn Trim(Mid(s, 8))
    EndIf
    
    ProcedureReturn s
  EndProcedure

  ; <summary>
  ; Extract a 1-based source line from a Vyrn diagnostic message.
  ; Supports: path:line: msg | line N: msg | &lt;eval&gt;:N: msg (skips Windows drive letters).
  ; </summary>
  ; <param name="msg">Diagnostic text (with or without [error]/[warn] prefix).</param>
  ; <returns>1-based line number, or 0 if none found.</returns>
  Procedure.i Ide_Diag_ParseLine(msg.s)
    Protected s.s = Ide_Diag_StripPrefix(msg)
    Protected i.i, j.i, n.i, c.i, best.i, drive.i

    If s = ""
      ProcedureReturn 0
    EndIf

    ; "line 12: ..."
    If LCase(Left(s, 5)) = "line "
      i = 6
      n = 0
      
      While i <= Len(s)
        c = Asc(Mid(s, i, 1))
        
        If c >= '0' And c <= '9'
          n = n * 10 + (c - '0')
          i = i + 1
        Else
          Break
        EndIf
      Wend
      
      If n > 0 And i <= Len(s) And Mid(s, i, 1) = ":"
        ProcedureReturn n
      EndIf
    EndIf

    ; Find ":NNN:" (skip Windows drive "C:")
    best = 0
    
    For i = 1 To Len(s) - 2
      If Mid(s, i, 1) <> ":"
        Continue
      EndIf
      
      drive = #False
      
      If i = 2
        c = Asc(Left(s, 1))
        
        If (c >= 'A' And c <= 'Z') Or (c >= 'a' And c <= 'z')
          drive = #True
        EndIf
      EndIf
      
      If drive
        Continue
      EndIf
      
      j = i + 1
      n = 0
      
      While j <= Len(s)
        c = Asc(Mid(s, j, 1))
        
        If c >= '0' And c <= '9'
          n = n * 10 + (c - '0')
          j = j + 1
        Else
          Break
        EndIf
      Wend
      
      If n > 0 And j <= Len(s) And Mid(s, j, 1) = ":"
        best = n
      EndIf
    Next

    ProcedureReturn best
  EndProcedure

  ; <summary>
  ; Jump the editor to the line encoded in a diagnostic message, if parseable.
  ; </summary>
  ; <param name="msg">Diagnostic or output line containing a source location.</param>
  ; <param name="isWarn">#True to mark as warning; #False for error markers.</param>
  Procedure Ide_Diag_JumpFromMessage(msg.s, isWarn.i = #False)
    Protected line.i = Ide_Diag_ParseLine(msg)
    
    If line > 0
      Ide_Editor_GotoDiagnostic(line, isWarn)
    EndIf
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 116
; FirstLine = 73
; Folding = -
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; EnableOnError
; DisableDebugger
; CompileSourceDirectory