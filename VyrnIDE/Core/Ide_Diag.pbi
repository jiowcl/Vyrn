;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - parse compiler/runtime diagnostics and jump to source lines
; PureBasic 6.41

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
  ; <summary>
  ; Also accept path(line): msg and (line N) forms used by some host/tooling paths.
  ; </summary>
  Procedure.i Ide_Diag_ParseLineExtra(msg.s)
    Protected s.s = Ide_Diag_StripPrefix(msg)
    Protected i.i, j.i, n.i, c.i
    ; "path(12): ..." or "name.vyrn(12):"
    For i = 1 To Len(s) - 2
      If Mid(s, i, 1) <> "("
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
      If n > 0 And j <= Len(s) And Mid(s, j, 1) = ")"
        ProcedureReturn n
      EndIf
    Next
    ProcedureReturn 0
  EndProcedure

  ; <summary>
  ; Parse line from CLI-like diagnostics; tries primary then extra forms.
  ; </summary>
  ; <param name="msg">Diagnostic or output line containing a source location.</param>
  Procedure.i Ide_Diag_ParseLineAny(msg.s)
    Protected line.i = Ide_Diag_ParseLine(msg)
    If line > 0
      ProcedureReturn line
    EndIf
    ProcedureReturn Ide_Diag_ParseLineExtra(msg)
  EndProcedure

  ; <summary>
  ; Append one diagnostic to the output pane in CLI-like form and jump when possible.
  ; Mirrors `path:line: message` / `line N: message` from Vyrn_FormatError.
  ; </summary>
  ; <param name="msg">Diagnostic or output line containing a source location.</param>
  ; <param name="isWarn">#True to mark as warning; #False for error markers.</param>
  Procedure Ide_Diag_EmitCliLike(msg.s, isWarn.i = #False)
    Protected body.s = Ide_Diag_StripPrefix(msg)
    Protected prefix.s
    Protected line.i
    If body = ""
      ProcedureReturn
    EndIf
    If isWarn
      prefix = "[warn] "
    Else
      prefix = "[error] "
    EndIf
    Ide_Ui_OutputAppend(prefix + body)
    line = Ide_Diag_ParseLineAny(body)
    If line > 0
      Ide_Editor_GotoDiagnostic(line, isWarn)
    EndIf
  EndProcedure

  ; <summary>
  ; Ide_Diag_JumpFromMessage
  ; Mirrors `path:line: message` / `line N: message` from Vyrn_FormatError.
  ; </summary>
  ; <param name="msg">Diagnostic or output line containing a source location.</param>
  ; <param name="isWarn">#True to mark as warning; #False for error markers.</param>
  Procedure Ide_Diag_JumpFromMessage(msg.s, isWarn.i = #False)
    Protected line.i = Ide_Diag_ParseLineAny(msg)
    
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