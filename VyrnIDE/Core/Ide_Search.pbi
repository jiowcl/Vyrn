;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - find / replace (regex, selection scope, all tabs)
; PureBasic 6.41

CompilerIf Defined(Ide_Search, #PB_Constant) = #False
  #Ide_Search = #True

  CompilerIf Defined(SCFIND_REGEXP, #PB_Constant) = #False
    #SCFIND_REGEXP = $200000
  CompilerEndIf
  CompilerIf Defined(SCI_GETSELECTIONSTART, #PB_Constant) = #False
    #SCI_GETSELECTIONSTART = 2143
  CompilerEndIf
  CompilerIf Defined(SCI_GETSELECTIONEND, #PB_Constant) = #False
    #SCI_GETSELECTIONEND = 2145
  CompilerEndIf

  ; <summary>
  ; Build Scintilla search flags from the find bar gadgets.
  ; </summary>
  ; <returns>integer</returns>
  Procedure.i Ide_Search_Flags()
    Protected flags.i = 0
    If IsGadget(#GAD_FIND_CASE) And GetGadgetState(#GAD_FIND_CASE)
      flags = #SCFIND_MATCHCASE
    EndIf
    If IsGadget(#GAD_FIND_REGEX) And GetGadgetState(#GAD_FIND_REGEX)
      flags | #SCFIND_REGEXP
    EndIf
    ProcedureReturn flags
  EndProcedure

  ; <summary>
  ; Target range for search: whole doc or current selection when "In selection" is checked.
  ; </summary>
  ; <param name="g">integer</param>
  Procedure Ide_Search_SetTarget(g.i)
    Protected start.i, selEnd.i, len.i
    len = ScintillaSendMessage(g, #SCI_GETLENGTH)
    start = 0
    selEnd = len
    If IsGadget(#GAD_FIND_INSEL) And GetGadgetState(#GAD_FIND_INSEL)
      start = ScintillaSendMessage(g, #SCI_GETSELECTIONSTART)
      selEnd = ScintillaSendMessage(g, #SCI_GETSELECTIONEND)
      If start = selEnd
        selEnd = len
      EndIf
    EndIf
    ScintillaSendMessage(g, #SCI_SETSEARCHFLAGS, Ide_Search_Flags(), 0)
    ScintillaSendMessage(g, #SCI_SETTARGETSTART, start, 0)
    ScintillaSendMessage(g, #SCI_SETTARGETEND, selEnd, 0)
  EndProcedure

  ; <summary>
  ; Read the current selection from a Scintilla as a PureBasic string.
  ; </summary>
  ; <param name="g">Scintilla gadget number.</param>
  ; <returns>string</returns>
  Procedure.s Ide_Editor_GetSelText(g.i)
    Protected len.i, *buf, result.s
    If g = 0
      ProcedureReturn ""
    EndIf
    len = ScintillaSendMessage(g, #SCI_GETSELTEXT, 0, 0)
    If len <= 1
      ProcedureReturn ""
    EndIf
    *buf = AllocateMemory(len + 4)
    If *buf = 0
      ProcedureReturn ""
    EndIf
    FillMemory(*buf, len + 4, 0)
    ScintillaSendMessage(g, #SCI_GETSELTEXT, 0, *buf)
    result = PeekS(*buf, -1, #PB_UTF8)
    FreeMemory(*buf)
    ProcedureReturn result
  EndProcedure

  ; <summary>
  ; True when the selected text equals the find needle (respects Match case).
  ; </summary>
  ; <param name="sel">string</param>
  ; <param name="needle">string</param>
  ; <returns>integer</returns>
  Procedure.i Ide_Editor_SelMatches(sel.s, needle.s)
    If sel = "" Or needle = ""
      ProcedureReturn #False
    EndIf
    If GetGadgetState(#GAD_FIND_CASE)
      ProcedureReturn Bool(sel = needle)
    EndIf
    ProcedureReturn Bool(LCase(sel) = LCase(needle))
  EndProcedure

  ; <summary>
  ; Find next in the active tab (wraps within target range).
  ; </summary>
  ; <returns>integer</returns>
  Procedure.i Ide_Editor_FindNext()
    Protected g.i = Ide_Editor_CurrentGadget()
    Protected needle.s, *utf8, nlen.i, pos.i, found.i, rangeStart.i, rangeEnd.i
    If g = 0
      ProcedureReturn #False
    EndIf
    needle = GetGadgetText(#GAD_FIND_STR)
    If needle = ""
      ProcedureReturn #False
    EndIf
    rangeStart = ScintillaSendMessage(g, #SCI_GETCURRENTPOS)
    If IsGadget(#GAD_FIND_INSEL) And GetGadgetState(#GAD_FIND_INSEL)
      rangeStart = ScintillaSendMessage(g, #SCI_GETSELECTIONSTART)
      rangeEnd = ScintillaSendMessage(g, #SCI_GETSELECTIONEND)
      If rangeEnd <= rangeStart
        rangeEnd = ScintillaSendMessage(g, #SCI_GETLENGTH)
      EndIf
    Else
      rangeEnd = ScintillaSendMessage(g, #SCI_GETLENGTH)
    EndIf
    ScintillaSendMessage(g, #SCI_SETSEARCHFLAGS, Ide_Search_Flags(), 0)
    *utf8 = UTF8(needle)
    nlen = Ide_Utf8Bytes(*utf8)
    pos = ScintillaSendMessage(g, #SCI_GETCURRENTPOS)
    ScintillaSendMessage(g, #SCI_SETTARGETSTART, pos, 0)
    ScintillaSendMessage(g, #SCI_SETTARGETEND, rangeEnd, 0)
    found = ScintillaSendMessage(g, #SCI_SEARCHINTARGET, nlen, *utf8)
    If found < 0
      ScintillaSendMessage(g, #SCI_SETTARGETSTART, rangeStart, 0)
      ScintillaSendMessage(g, #SCI_SETTARGETEND, pos, 0)
      found = ScintillaSendMessage(g, #SCI_SEARCHINTARGET, nlen, *utf8)
    EndIf
    If *utf8
      FreeMemory(*utf8)
    EndIf
    If found >= 0
      ScintillaSendMessage(g, #SCI_SETSEL, found, ScintillaSendMessage(g, #SCI_GETTARGETEND))
      ScintillaSendMessage(g, #SCI_SCROLLCARET)
      ProcedureReturn #True
    EndIf
    ProcedureReturn #False
  EndProcedure

  ; <summary>
  ; Replace the current selection when it matches, then find the next occurrence.
  ; </summary>
  Procedure Ide_Editor_ReplaceOnce()
    Protected g.i = Ide_Editor_CurrentGadget()
    Protected needle.s, repl.s, *utf8
    If g = 0
      ProcedureReturn
    EndIf
    needle = GetGadgetText(#GAD_FIND_STR)
    repl = GetGadgetText(#GAD_REPLACE_STR)
    If Ide_Editor_SelMatches(Ide_Editor_GetSelText(g), needle)
      *utf8 = UTF8(repl)
      ScintillaSendMessage(g, #SCI_REPLACESEL, 0, *utf8)
      If *utf8
        FreeMemory(*utf8)
      EndIf
    EndIf
    If Ide_Editor_FindNext() = #False
      Ide_Ui_SetStatus(Ide_I18n_Pick("No more matches", "status.no_matches"))
    EndIf
  EndProcedure

  ; <summary>
  ; Replace every match in the current search target (whole doc or selection).
  ; </summary>
  Procedure Ide_Editor_ReplaceAll()
    Protected g.i = Ide_Editor_CurrentGadget()
    Protected needle.s, repl.s, *n8, *r8, nlen.i, found.i, count.i, rangeEnd.i
    If g = 0
      ProcedureReturn
    EndIf
    needle = GetGadgetText(#GAD_FIND_STR)
    repl = GetGadgetText(#GAD_REPLACE_STR)
    If needle = ""
      ProcedureReturn
    EndIf
    Ide_Search_SetTarget(g)
    *n8 = UTF8(needle)
    *r8 = UTF8(repl)
    nlen = Ide_Utf8Bytes(*n8)
    count = 0
    found = ScintillaSendMessage(g, #SCI_SEARCHINTARGET, nlen, *n8)
    While found >= 0
      ScintillaSendMessage(g, #SCI_REPLACETARGET, -1, *r8)
      count = count + 1
      found = ScintillaSendMessage(g, #SCI_GETTARGETEND)
      rangeEnd = ScintillaSendMessage(g, #SCI_GETTARGETEND)
      ScintillaSendMessage(g, #SCI_SETTARGETSTART, found, 0)
      ScintillaSendMessage(g, #SCI_SETTARGETEND, rangeEnd, 0)
      found = ScintillaSendMessage(g, #SCI_SEARCHINTARGET, nlen, *n8)
    Wend
    If *n8 : FreeMemory(*n8) : EndIf
    If *r8 : FreeMemory(*r8) : EndIf
    Ide_Highlight_Restyle(g)
    MessageRequester(Ide_I18n_AppTitle(), ReplaceString(Ide_I18n_Pick("Replaced {n} occurrence(s).", "dlg.replace_count"), "{n}", Str(count)), #PB_MessageRequester_Info)
  EndProcedure

  ; <summary>
  ; Find next in each open tab; stops on first match and switches to that tab.
  ; </summary>
  Procedure Ide_Editor_FindAllTabs()
    Protected i.i, g.i, saved.i, needle.s, *utf8, nlen.i, found.i
    needle = GetGadgetText(#GAD_FIND_STR)
    If needle = ""
      ProcedureReturn
    EndIf
    saved = GetGadgetState(#GAD_TABS)
    *utf8 = UTF8(needle)
    nlen = Ide_Utf8Bytes(*utf8)
    For i = 0 To Ide_TabCount - 1
      SetGadgetState(#GAD_TABS, i)
      Ide_Editor_SyncActive()
      g = Ide_Tabs(i)\gadget
      If g = 0
        Continue
      EndIf
      ScintillaSendMessage(g, #SCI_SETSEARCHFLAGS, Ide_Search_Flags(), 0)
      ScintillaSendMessage(g, #SCI_SETTARGETSTART, 0, 0)
      ScintillaSendMessage(g, #SCI_SETTARGETEND, ScintillaSendMessage(g, #SCI_GETLENGTH), 0)
      found = ScintillaSendMessage(g, #SCI_SEARCHINTARGET, nlen, *utf8)
      If found >= 0
        SetGadgetState(#GAD_TABS, i)
        Ide_Editor_SyncActive()
        ScintillaSendMessage(g, #SCI_SETSEL, found, ScintillaSendMessage(g, #SCI_GETTARGETEND))
        ScintillaSendMessage(g, #SCI_SCROLLCARET)
        Ide_Ui_SetStatus(Ide_I18n_Fmt1("Match in {tab}", "status.match_tab", "{tab}", Ide_Editor_TabCaption(i)))
        If *utf8 : FreeMemory(*utf8) : EndIf
        ProcedureReturn
      EndIf
    Next
    If *utf8 : FreeMemory(*utf8) : EndIf
    SetGadgetState(#GAD_TABS, saved)
    Ide_Editor_SyncActive()
    Ide_Ui_SetStatus(Ide_I18n_Pick("No matches in open tabs", "status.no_tab_matches"))
  EndProcedure

CompilerEndIf
; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 113
; FirstLine = 84
; Folding = ---
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)