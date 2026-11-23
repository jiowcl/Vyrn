;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - toggle comment, brace highlight, tab width on all editors
; PureBasic 6.41

CompilerIf Defined(Ide_EditorAssist, #PB_Constant) = #False
  #Ide_EditorAssist = #True

  CompilerIf Defined(SCI_BRACEMATCH, #PB_Constant) = #False
    #SCI_BRACEMATCH = 2352
  CompilerEndIf
  CompilerIf Defined(SCI_INDICSETSTYLE, #PB_Constant) = #False
    #SCI_INDICSETSTYLE = 2080
  CompilerEndIf
  CompilerIf Defined(SCI_INDICSETFORE, #PB_Constant) = #False
    #SCI_INDICSETFORE = 2083
  CompilerEndIf
  CompilerIf Defined(SCI_SETINDICATORCURRENT, #PB_Constant) = #False
    #SCI_SETINDICATORCURRENT = 2500
  CompilerEndIf
  CompilerIf Defined(SCI_INDICATORCLEARRANGE, #PB_Constant) = #False
    #SCI_INDICATORCLEARRANGE = 2509
  CompilerEndIf
  CompilerIf Defined(SCI_INDICATORFILLRANGE, #PB_Constant) = #False
    #SCI_INDICATORFILLRANGE = 2508
  CompilerEndIf
  CompilerIf Defined(SCI_GETCURLINE, #PB_Constant) = #False
    #SCI_GETCURLINE = 2027
  CompilerEndIf

  #Ide_BraceIndic = 0

  ; <summary>
  ; Toggle line comment (-- ) on selected lines or the current line.
  ; </summary>
  Procedure Ide_Editor_ToggleComment()
    Protected g.i = Ide_Editor_CurrentGadget()
    Protected startPos.i, endPos.i, lineStart.i, lineEnd.i, line0.i, line1.i, l.i
    Protected lineLen.i, *buf, line.s, allComment.i, pos.i, insert.i
    If g = 0
      ProcedureReturn
    EndIf
    startPos = ScintillaSendMessage(g, #SCI_GETSELECTIONSTART)
    endPos = ScintillaSendMessage(g, #SCI_GETSELECTIONEND)
    line0 = ScintillaSendMessage(g, #SCI_LINEFROMPOSITION, startPos)
    line1 = ScintillaSendMessage(g, #SCI_LINEFROMPOSITION, endPos)
    If startPos = endPos
      line1 = line0
    ElseIf endPos > startPos
      If ScintillaSendMessage(g, #SCI_LINEFROMPOSITION, endPos - 1) > line1
        line1 = ScintillaSendMessage(g, #SCI_LINEFROMPOSITION, endPos - 1)
      EndIf
    EndIf
    allComment = #True
    For l = line0 To line1
      lineStart = ScintillaSendMessage(g, #SCI_POSITIONFROMLINE, l)
      lineEnd = ScintillaSendMessage(g, #SCI_GETLINEENDPOSITION, l)
      lineLen = lineEnd - lineStart
      If lineLen < 1
        allComment = #False
        Continue
      EndIf
      *buf = AllocateMemory(lineLen + 4)
      If *buf = 0
        Continue
      EndIf
      ScintillaSendMessage(g, #SCI_SETSEL, lineStart, lineEnd)
      ScintillaSendMessage(g, #SCI_GETSELTEXT, 0, *buf)
      line = Trim(PeekS(*buf, -1, #PB_UTF8))
      FreeMemory(*buf)
      If Left(line, 2) <> "--"
        allComment = #False
      EndIf
    Next
    For l = line1 To line0 Step -1
      lineStart = ScintillaSendMessage(g, #SCI_POSITIONFROMLINE, l)
      lineEnd = ScintillaSendMessage(g, #SCI_GETLINEENDPOSITION, l)
      If allComment
        ScintillaSendMessage(g, #SCI_SETSEL, lineStart, lineStart + 2)
        ScintillaSendMessage(g, #SCI_REPLACESEL, 0, 0)
      Else
        *buf = UTF8("-- ")
        ScintillaSendMessage(g, #SCI_SETSEL, lineStart, lineStart)
        ScintillaSendMessage(g, #SCI_REPLACESEL, 0, *buf)
        If *buf : FreeMemory(*buf) : EndIf
      EndIf
    Next
    ScintillaSendMessage(g, #SCI_SETSAVEPOINT, 0, 0)
    Ide_Highlight_Restyle(g)
  EndProcedure

  ; <summary>
  ; Highlight matching (), [], {} using indicator 0; clears when no match.
  ; </summary>
  Procedure Ide_EditorAssist_BraceHighlight(g.i)
    Protected pos.i, match.i, len.i, fore.i
    If g = 0
      ProcedureReturn
    EndIf
    len = ScintillaSendMessage(g, #SCI_GETLENGTH)
    pos = ScintillaSendMessage(g, #SCI_GETCURRENTPOS)
    ScintillaSendMessage(g, #SCI_SETINDICATORCURRENT, #Ide_BraceIndic, 0)
    ScintillaSendMessage(g, #SCI_INDICATORCLEARRANGE, 0, len)
    If pos <= 0
      ProcedureReturn
    EndIf
    match = ScintillaSendMessage(g, #SCI_BRACEMATCH, pos - 1, 0)
    If match < 0
      match = ScintillaSendMessage(g, #SCI_BRACEMATCH, pos, 0)
      If match >= 0
        pos = pos
      Else
        ProcedureReturn
      EndIf
    Else
      pos = pos - 1
    EndIf
    If Ide_Theme_Dark
      fore = RGB(120, 180, 255)
    Else
      fore = RGB(0, 90, 200)
    EndIf
    ScintillaSendMessage(g, #SCI_INDICSETFORE, #Ide_BraceIndic, fore)
    ScintillaSendMessage(g, #SCI_INDICSETSTYLE, #Ide_BraceIndic, 1)
    ScintillaSendMessage(g, #SCI_INDICATORFILLRANGE, pos, 1)
    ScintillaSendMessage(g, #SCI_INDICATORFILLRANGE, match, 1)
  EndProcedure

  ; <summary>
  ; Apply Ide_TabWidth to one Scintilla.
  ; </summary>
  Procedure Ide_EditorAssist_ApplyTabWidth(g.i)
    If g = 0
      ProcedureReturn
    EndIf
    ScintillaSendMessage(g, #SCI_SETTABWIDTH, Ide_TabWidth, 0)
    ScintillaSendMessage(g, #SCI_SETUSETABS, #False, 0)
  EndProcedure

  ; <summary>
  ; Set display tab width (spaces) for all open editors and persist in vyrnide.ini.
  ; </summary>
  ; <param name="w">Tab size in columns (2–8).</param>
  Procedure Ide_Editor_SetTabWidth(w.i)
    Protected i.i
    If w < 2 : w = 2 : EndIf
    If w > 8 : w = 8 : EndIf
    Ide_TabWidth = w
    For i = 0 To Ide_TabCount - 1
      If IsGadget(Ide_Tabs(i)\gadget)
        Ide_EditorAssist_ApplyTabWidth(Ide_Tabs(i)\gadget)
      EndIf
    Next
    Ide_Editor_SavePrefs()
    Ide_Ui_SetStatus(Ide_I18n_Fmt1("Tab width {w}", "status.tab_width", "{w}", Str(Ide_TabWidth)))
  EndProcedure

CompilerEndIf