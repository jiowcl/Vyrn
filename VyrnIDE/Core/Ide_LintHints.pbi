;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - lightweight editor heuristics (not a full LSP).
; PureBasic 6.41

CompilerIf Defined(Ide_LintHints, #PB_Constant) = #False
  #Ide_LintHints = #True

  #Ide_LintHintDelayMs = 2200
  Global Ide_LintDue.i = 0
  Global Ide_LintLastPath.s = ""

  ; <summary>
  ; Schedule a soft lint pass after edits (saved Or unsaved buffer).
  ; </summary>
  ; <param name="path">string</param>
  Procedure Ide_LintHints_Schedule(path.s)
    If Ide_LiveCheckEnabled = #False
      ProcedureReturn
    EndIf
  If path = "" And Ide_FilePath = ""
      path = "<buffer>"
    EndIf
    Ide_LintLastPath = path
    Ide_LintDue = ElapsedMilliseconds() + #Ide_LintHintDelayMs
  EndProcedure

  ; <summary>
  ; Count keyword tokens on a Line (whole-word, lowercase).
  ; </summary>
  ; <param name="line">string</param>
  ; <param name="word">string</param>
  ; <returns>integer</returns>
  Procedure.i Ide_LintHints_CountWord(line.s, word.s)
    Protected low.s = LCase(Trim(line))
    Protected w.s = LCase(word)
    Protected pos.i = 1, n.i = 0, before.i, after.i
    Repeat
      pos = FindString(low, w, pos)
      If pos = 0
        Break
      EndIf
      before = 0
      after = 0
      If pos > 1
        before = Asc(Mid(low, pos - 1, 1))
      EndIf
      If pos + Len(w) <= Len(low)
        after = Asc(Mid(low, pos + Len(w), 1))
      EndIf
      If (before < Asc("a") Or before > Asc("z")) And (before < Asc("0") Or before > Asc("9")) And before <> Asc("_") And before <> Asc(".")
        If (after < Asc("a") Or after > Asc("z")) And (after < Asc("0") Or after > Asc("9")) And after <> Asc("_") And after <> Asc(".")
          n + 1
        EndIf
      EndIf
      pos + Len(w)
    ForEver
    ProcedureReturn n
  EndProcedure

  ; <summary>
  ; Scan buffer; push hints to the error list only (no output spam).
  ; </summary>
  ; <param name="text">string</param>
  Procedure Ide_LintHints_Run(text.s)
    Protected lines.s, line.s, i.i, nLines.i
    Protected openBlocks.i = 0, closeEnd.i = 0
    Protected inMatch.i = #False
    If text = ""
      ProcedureReturn
    EndIf
    Ide_Nav_LintClear()
    lines = text
    nLines = CountString(lines, Chr(10)) + 1
    For i = 0 To nLines - 1
      line = StringField(lines, i + 1, Chr(10))
      openBlocks + Ide_LintHints_CountWord(line, "function")
      openBlocks + Ide_LintHints_CountWord(line, "if")
      openBlocks + Ide_LintHints_CountWord(line, "while")
      openBlocks + Ide_LintHints_CountWord(line, "for")
      openBlocks + Ide_LintHints_CountWord(line, "match")
      closeEnd + Ide_LintHints_CountWord(line, "end")
      If Ide_LintHints_CountWord(line, "match") > 0
        inMatch = #True
      EndIf
      If inMatch And FindString(line, "Status.", 1)
        If FindString(line, Chr(34), 1) = 0 And FindString(line, "'", 1) = 0
          Ide_Nav_ErrorsPushHint(Ide_I18n_Fmt1("line {ln}: match arm may need a quoted enum literal (Status.X)", "lint.match_status", "{ln}", Str(i + 1)), i + 1)
        EndIf
      EndIf
      If Ide_LintHints_CountWord(line, "end") > 0 And inMatch
        ; crude: leave match after first end in block
      EndIf
    Next
    If openBlocks > closeEnd + 1
      Ide_Nav_ErrorsPushHint(Ide_I18n_Pick("Possible unclosed block: more opening keywords than 'end' lines", "lint.unclosed"), 0)
    EndIf
  EndProcedure

  ; <summary>
  ; Main-loop poll For debounced lint.
  ; </summary>
  Procedure Ide_LintHints_Poll()
    Protected path.s
    If Ide_LintDue = 0
      ProcedureReturn
    EndIf
    If ElapsedMilliseconds() < Ide_LintDue
      ProcedureReturn
    EndIf
    Ide_LintDue = 0
    path = Ide_LintLastPath
    If path <> "<buffer>" And Ide_FilePath <> "" And LCase(path) <> LCase(Ide_FilePath)
      ProcedureReturn
    EndIf
    If Ide_Runner_IsBusy()
      ProcedureReturn
    EndIf
    If Ide_LiveLintPanelOnly And Ide_ErrorsVisible = 0
      ProcedureReturn
    EndIf
    Ide_LintHints_Run(Ide_Editor_GetText())
  EndProcedure

CompilerEndIf
; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 18
; Folding = -
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)