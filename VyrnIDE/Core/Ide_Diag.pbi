;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - parse compiler/runtime diagnostics; emit to output and jump editor caret.
; PureBasic 6.41

CompilerIf Defined(Ide_Diag, #PB_Constant) = #False
  #Ide_Diag = #True

  Declare Ide_Nav_ErrorsPush(line.s)
  Declare Ide_Nav_ErrorsPushMeta(body.s, path.s, ln.i, col.i, code.s, isHint.i)

  ; <summary>
  ; Extract a JSON string field (no escape handling; CLI diagnostics only).
  ; </summary>
  Procedure.s Ide_Diag_JsonStringField(json.s, key.s)
    Protected needle.s = Chr(34) + key + Chr(34) + ":"
    Protected p.i, q.i, ch.i
    p = FindString(json, needle, 1)
    If p = 0
      ProcedureReturn ""
    EndIf
    p = p + Len(needle)
    While p <= Len(json) And Mid(json, p, 1) = " "
      p + 1
    Wend
    If p > Len(json) Or Mid(json, p, 1) <> Chr(34)
      ProcedureReturn ""
    EndIf
    p + 1
    q = p
    While q <= Len(json)
      ch = Asc(Mid(json, q, 1))
      If ch = 34 And Mid(json, q - 1, 1) <> "\"
        ProcedureReturn Mid(json, p, q - p)
      EndIf
      q + 1
    Wend
    ProcedureReturn ""
  EndProcedure

  ; <summary>
  ; Turn one NDJSON diagnostics line INTO a human error line For the error List.
  ; </summary>
  Procedure.i Ide_Diag_JsonNumberField(json.s, key.s)
    Protected needle.s = Chr(34) + key + Chr(34) + ":"
    Protected p.i, digits.s = "", ch.i, c.s
    p = FindString(json, needle, 1)
    If p = 0
      ProcedureReturn 0
    EndIf
    p = p + Len(needle)
    While p <= Len(json)
      c = Mid(json, p, 1)
      If c = " " Or c = Chr(9)
        p + 1
        Continue
      EndIf
      Break
    Wend
    For p = p To Len(json)
      c = Mid(json, p, 1)
      ch = Asc(c)
      If ch >= Asc("0") And ch <= Asc("9")
        digits + c
      Else
        Break
      EndIf
    Next
    If digits = ""
      ProcedureReturn 0
    EndIf
    ProcedureReturn Val(digits)
  EndProcedure

  ; <summary>
  ; Parse NDJSON diagnostics line INTO error List + output.
  ; </summary>
  ; <param name="line">string</param>
  Procedure Ide_Diag_PushNdjson(line.s)
    Protected text.s, file.s, code.s, ln.i, col.i, body.s
    If FindString(line, "vyrn.diagnostics.v1", 1) = 0
      ProcedureReturn
    EndIf
    text = Ide_Diag_JsonStringField(line, "text")
    file = Ide_Diag_JsonStringField(line, "file")
    code = Ide_Diag_JsonStringField(line, "code")
    ln = Ide_Diag_JsonNumberField(line, "line")
    col = Ide_Diag_JsonNumberField(line, "column")
    If text <> ""
      body = text
    Else
      body = file
      If ln > 0
        body = body + ":" + Str(ln) + ": " + Ide_Diag_JsonStringField(line, "message")
      EndIf
    EndIf
    If body <> ""
      Ide_Ui_OutputAppend("[error] " + body)
      Ide_Nav_ErrorsPushMeta(body, file, ln, col, code, #False)
    EndIf
  EndProcedure
  
  ; <summary>
  ; Ide_Diag_FromNdjson
  ; </summary>
  ; <param name="line">string</param>
  ; <returns>string</returns>
  Procedure.s Ide_Diag_FromNdjson(line.s)
    If FindString(line, "vyrn.diagnostics.v1", 1) = 0
      ProcedureReturn ""
    EndIf
    Protected text.s = Ide_Diag_JsonStringField(line, "text")
    If text <> ""
      ProcedureReturn text
    EndIf
    Protected file.s = Ide_Diag_JsonStringField(line, "file")
    Protected msg.s = Ide_Diag_JsonStringField(line, "message")
    If file <> "" And msg <> ""
      ProcedureReturn file + ": " + msg
    EndIf
  ProcedureReturn msg
  EndProcedure

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
  ; Best-effort source path from path:line: diagnostics (empty For line N: only).
  ; </summary>
  ; <param name="msg">string</param>
  ; <returns>string</returns>
  Procedure.s Ide_Diag_ParseSourcePath(msg.s)
    Protected s.s = Ide_Diag_StripPrefix(msg)
    Protected ln.i = Ide_Diag_ParseLine(s)
    Protected i.i, j.i, n.i, c.i, drive.i
    If ln = 0 Or s = ""
      ProcedureReturn ""
    EndIf
    If LCase(Left(s, 5)) = "line "
      ProcedureReturn ""
    EndIf
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
      If n = ln And j <= Len(s) And Mid(s, j, 1) = ":"
        ProcedureReturn Trim(Left(s, i - 1))
      EndIf
    Next
    ProcedureReturn ""
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
    Protected path.s
    Protected ln.i
    If body = ""
      ProcedureReturn
    EndIf
    If isWarn
      prefix = "[warn] "
    Else
      prefix = "[error] "
    EndIf
    Ide_Ui_OutputAppend(prefix + body)
    If isWarn = #False
      path = Ide_Diag_ParseSourcePath(body)
      ln = Ide_Diag_ParseLineAny(body)
      If path = ""
        path = Ide_FilePath
      EndIf
      Ide_Nav_ErrorsPushMeta(body, path, ln, 0, "", #False)
    EndIf
    line = Ide_Diag_ParseLineAny(body)
    If line > 0
      Ide_Editor_GotoDiagnosticPath(Ide_Diag_ParseSourcePath(body), line, isWarn)
    EndIf
  EndProcedure

  ; <summary>
  ; Ide_Diag_JumpFromMessage
  ; </summary>
  ; <param name="msg">Diagnostic or output line containing a source location.</param>
  ; <param name="isWarn">#True to mark as warning; #False for error markers.</param>
  Procedure Ide_Diag_JumpFromMessage(msg.s, isWarn.i = #False)
    Protected body.s = Ide_Diag_StripPrefix(msg)
    Protected path.s = Ide_Diag_ParseSourcePath(body)
    Protected line.i = Ide_Diag_ParseLineAny(body)
    If line > 0
      Ide_Editor_GotoDiagnosticPath(path, line, isWarn)
    EndIf
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 274
; FirstLine = 318
; Folding = ---
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; EnableOnError
; DisableDebugger
; CompileSourceDirectory