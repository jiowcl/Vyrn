;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - symbol outline + pinned error list (Phase D / mid-tier UX)
; Outline scans def/struct/enum/local/module; error list dedupes by file+line.
; F8 syntax check can auto-open the error panel via Ide_Nav_ErrorsPrepareF8.
; PureBasic 6.41

CompilerIf Defined(Ide_NavPanels, #PB_Constant) = #False
  #Ide_NavPanels = #True

  Global Ide_ErrCount.i = 0
  Global Dim Ide_ErrLine.s(49)
  Global Dim Ide_ErrFile.s(49)
  Global Dim Ide_ErrRow.i(49)
  Global Ide_ErrAutoOpen.i = #False
  Global Dim Ide_ErrHint.i(49)
  Global Dim Ide_ErrCol.i(49)
  Global Dim Ide_ErrCode.s(49)
  Global Dim Ide_ErrListMap.i(49)
  #Ide_ErrMax = 50

  ; <summary>
  ; F8 syntax check can auto-open the error panel via Ide_Nav_ErrorsPrepareF8.
  ; </summary>
  ; <param name="bodys">see signature</param>
  ; <param name="paths">see signature</param>
  ; <param name="lni">see signature</param>
  ; <returns>string</returns>
  Procedure.s Ide_Nav_ErrorsDisplay(body.s, path.s, ln.i)
    Protected cap.s, rest.s
    If path <> ""
      cap = GetFilePart(path)
      If Len(body) > Len(path) And Left(body, Len(path)) = path
        rest = Trim(Mid(body, Len(path) + 1))
        If Left(rest, 1) = ":"
          rest = Trim(Mid(rest, 2))
        EndIf
        If rest <> ""
          ProcedureReturn cap + ": " + rest
        EndIf
      EndIf
      If cap <> "" And ln > 0
        ProcedureReturn cap + " (Ln " + Str(ln) + ")"
      EndIf
    EndIf
    ProcedureReturn body
  EndProcedure

  ; <summary>
  ; IDE: Nav ErrorsRefreshGadget.
  ; </summary>
  ; <param name="gadgetRow">integer</param>
  ; <returns>integer</returns>
  Procedure.i Ide_Nav_ErrorsListIndex(gadgetRow.i)
    If gadgetRow < 0 Or gadgetRow >= #Ide_ErrMax
      ProcedureReturn -1
    EndIf
    ProcedureReturn Ide_ErrListMap(gadgetRow)
  EndProcedure
  
  ; <summary>
  ; IDE: Nav ErrorsRefreshGadget.
  ; </summary>
  Procedure Ide_Nav_ErrorsRefreshGadget()
    Protected i.i, cap.s, row.i = 0, f.s, code.s
    If IsGadget(#GAD_ERRLIST) = #False
      ProcedureReturn
    EndIf
    ClearGadgetItems(#GAD_ERRLIST)
    f = LCase(Trim(Ide_ErrCodeFilter))
    For i = 0 To Ide_ErrCount - 1
      If Ide_ErrShowHints = #False And Ide_ErrHint(i)
        Continue
      EndIf
      code = Ide_ErrCode(i)
      If f <> ""
        If code = ""
          Continue
        EndIf
        If FindString(LCase(code), f, 1, #PB_String_NoCase) = 0
          Continue
        EndIf
      EndIf
      Ide_ErrListMap(row) = i
      cap = Ide_Nav_ErrorsDisplay(Ide_ErrLine(i), Ide_ErrFile(i), Ide_ErrRow(i))
      If Ide_ErrCode(i) <> ""
        cap = cap + " [" + Ide_ErrCode(i) + "]"
      EndIf
      If Ide_ErrHint(i)
        cap = Ide_I18n_Pick("(hint) ", "err.hint_prefix") + cap
      EndIf
      AddGadgetItem(#GAD_ERRLIST, -1, cap)
      SetGadgetItemText(#GAD_ERRLIST, CountGadgetItems(#GAD_ERRLIST) - 1, Str(Ide_ErrRow(i)), 1)
      If Ide_ErrCol(i) > 0
        SetGadgetItemText(#GAD_ERRLIST, CountGadgetItems(#GAD_ERRLIST) - 1, Str(Ide_ErrCol(i)), 2)
      EndIf
      row + 1
    Next
  EndProcedure

  ; <summary>
  ; IDE: Nav OutlineRefresh.
  ; </summary>
  Procedure Ide_Nav_OutlineRefresh()
    Protected g.i, text.s, lines.s, i.i, n.i, line.s, name.s, kind.s, pos.i
    If IsGadget(#GAD_OUTLINE) = #False
      ProcedureReturn
    EndIf
    ClearGadgetItems(#GAD_OUTLINE)
    g = Ide_Editor_CurrentGadget()
    If g = 0
      ProcedureReturn
    EndIf
    text = Ide_Editor_GetTextFrom(g)
    n = CountString(text, Chr(10)) + 1
    For i = 1 To n
      line = Trim(StringField(text, i, Chr(10)))
      If Len(line) < 4
        Continue
      EndIf
      If FindString(LCase(line), "def ", 1) = 1 Or FindString(line, "def\t", 1) = 1 Or FindString(line, " def ", 1) > 0
        kind = "def"
        pos = FindString(line, "def", 1, #PB_String_NoCase)
        name = Trim(Mid(line, pos + 3))
        name = StringField(name, 1, "(")
        name = StringField(name, 1, " ")
        name = StringField(name, 1, Chr(9))
      ElseIf FindString(LCase(line), "struct ", 1) > 0
        kind = "struct"
        pos = FindString(line, "struct", 1, #PB_String_NoCase)
        name = Trim(Mid(line, pos + 6))
        name = StringField(name, 1, "{")
        name = StringField(name, 1, " ")
      ElseIf FindString(LCase(line), "enum ", 1) > 0
        kind = "enum"
        pos = FindString(line, "enum", 1, #PB_String_NoCase)
        name = Trim(Mid(line, pos + 4))
        name = StringField(name, 1, "{")
        name = StringField(name, 1, " ")
      ElseIf FindString(LCase(line), "local ", 1) = 1 Or FindString(line, "local\t", 1) = 1
        kind = "local"
        pos = FindString(line, "local", 1, #PB_String_NoCase)
        name = Trim(Mid(line, pos + 5))
        name = StringField(name, 1, "=")
        name = StringField(name, 1, " ")
      ElseIf FindString(LCase(line), "module ", 1) = 1
        kind = "mod"
        pos = FindString(line, "module", 1, #PB_String_NoCase)
        name = Trim(Mid(line, pos + 6))
        name = StringField(name, 1, " ")
      Else
        Continue
      EndIf
      If name = ""
        Continue
      EndIf
      AddGadgetItem(#GAD_OUTLINE, -1, kind + " " + name)
      SetGadgetItemText(#GAD_OUTLINE, CountGadgetItems(#GAD_OUTLINE) - 1, Str(i), 1)
    Next
  EndProcedure

  ; <summary>
  ; IDE: Nav OutlineToggle.
  ; </summary>
  Procedure Ide_Nav_OutlineToggle()
    Ide_OutlineVisible = Bool(Ide_OutlineVisible = 0)
    SetMenuItemState(#MENU_MAIN, #MNU_OUTLINE_PANEL, Ide_OutlineVisible)
    Ide_Ui_Layout()
    Ide_Editor_ResizeEditors()
    If Ide_OutlineVisible
      Ide_Nav_OutlineRefresh()
    EndIf
    Ide_Editor_SavePrefs()
  EndProcedure

  ; <summary>
  ; IDE: Nav OutlineActivate.
  ; </summary>
  Procedure Ide_Nav_OutlineActivate()
    Protected idx.i, ln.i
    If IsGadget(#GAD_OUTLINE) = #False
      ProcedureReturn
    EndIf
    idx = GetGadgetState(#GAD_OUTLINE)
    If idx < 0
      ProcedureReturn
    EndIf
    ln = Val(GetGadgetItemText(#GAD_OUTLINE, idx, 1))
    If ln > 0
      Ide_Editor_GotoDiagnostic(ln, #False)
    EndIf
  EndProcedure

  ; <summary>
  ; IDE: Nav ErrorsClear.
  ; </summary>
  Procedure Ide_Nav_ErrorsClear()
    Protected i.i
    Ide_ErrCount = 0
    For i = 0 To #Ide_ErrMax - 1
      Ide_ErrHint(i) = 0
      Ide_ErrCol(i) = 0
      Ide_ErrCode(i) = ""
    Next
    If IsGadget(#GAD_ERRLIST)
      ClearGadgetItems(#GAD_ERRLIST)
    EndIf
  EndProcedure

  ; <summary>
  ; Clear soft lint rows only (keeps compile/run errors).
  ; </summary>
  Procedure Ide_Nav_LintClear()
    Protected i.i, j.i
    j = 0
    For i = 0 To Ide_ErrCount - 1
      If Ide_ErrHint(i) = 0
        If j <> i
          Ide_ErrLine(j) = Ide_ErrLine(i)
          Ide_ErrFile(j) = Ide_ErrFile(i)
          Ide_ErrRow(j) = Ide_ErrRow(i)
          Ide_ErrHint(j) = 0
          Ide_ErrCol(j) = Ide_ErrCol(i)
          Ide_ErrCode(j) = Ide_ErrCode(i)
        EndIf
        j + 1
      EndIf
    Next
    Ide_ErrCount = j
    Ide_Nav_ErrorsRefreshGadget()
  EndProcedure

  ; <summary>
  ; IDE: Nav ErrorsFindDup.
  ; </summary>
  ; <param name="paths">see signature</param>
  ; <param name="lni">see signature</param>
  ; <param name="bodys">see signature</param>
  Procedure.i Ide_Nav_ErrorsFindDup(path.s, ln.i, body.s)
    Protected i.i
    For i = 0 To Ide_ErrCount - 1
      If Ide_ErrRow(i) = ln And LCase(Ide_ErrLine(i)) = LCase(body)
        If path = "" Or LCase(Ide_ErrFile(i)) = LCase(path)
          ProcedureReturn i
        EndIf
      EndIf
    Next
    ProcedureReturn -1
  EndProcedure

  ; <summary>
  ; IDE: Nav ErrorsPush.
  ; </summary>
  ; <param name="lines">see signature</param>
  Procedure Ide_Nav_ErrorsPushMeta(body.s, path.s, ln.i, col.i, code.s, isHint.i)
    Protected i.i
    If body = ""
      ProcedureReturn
    EndIf
    If path = ""
      path = Ide_FilePath
    EndIf
    If ln = 0
      ln = Ide_Diag_ParseLineAny(body)
    EndIf
    If Ide_Nav_ErrorsFindDup(path, ln, body) >= 0
      ProcedureReturn
    EndIf
    If Ide_ErrCount >= #Ide_ErrMax
      For i = 0 To #Ide_ErrMax - 2
        Ide_ErrLine(i) = Ide_ErrLine(i + 1)
        Ide_ErrFile(i) = Ide_ErrFile(i + 1)
        Ide_ErrRow(i) = Ide_ErrRow(i + 1)
        Ide_ErrHint(i) = Ide_ErrHint(i + 1)
        Ide_ErrCol(i) = Ide_ErrCol(i + 1)
        Ide_ErrCode(i) = Ide_ErrCode(i + 1)
      Next
      Ide_ErrCount = #Ide_ErrMax - 1
    EndIf
    i = Ide_ErrCount
    Ide_ErrLine(i) = body
    Ide_ErrFile(i) = path
    Ide_ErrRow(i) = ln
    Ide_ErrCol(i) = col
    Ide_ErrCode(i) = code
    Ide_ErrHint(i) = isHint
    Ide_ErrCount + 1
    If isHint And Ide_ErrorsVisible = 0
      Ide_ErrAutoOpen = #True
    EndIf
    Ide_Nav_ErrorsRefreshGadget()
  EndProcedure
  
  ; <summary>
  ; Ide_Nav_ErrorsPush
  ; </summary>
  ; <param name="line">string</param>
  Procedure Ide_Nav_ErrorsPush(line.s)
    Protected body.s, ln.i, path.s, parsed.s, i.i, cap.s
    body = line
    If Left(LCase(body), 8) = "[error] "
      body = Trim(Mid(body, 9))
    ElseIf FindString(LCase(body), "[error]", 1) <> 0
      ProcedureReturn
    EndIf
    ln = Ide_Diag_ParseLineAny(body)
    parsed = Ide_Diag_ParseSourcePath(body)
    path = parsed
    If path = ""
      path = Ide_FilePath
    EndIf
    Ide_Nav_ErrorsPushMeta(body, path, ln, 0, "", #False)
  EndProcedure

  ; <summary>
  ; Push a soft lint / heuristic warning into the error List.
  ; </summary>
  ; <param name="body">string</param>
  ; <param name="ln">integer</param>
  Procedure Ide_Nav_ErrorsPushHint(body.s, ln.i = 0)
    Protected path.s = Ide_FilePath
    Ide_Nav_ErrorsPushMeta(body, path, ln, 0, "", #True)
  EndProcedure
  
  ; <summary>
  ; Ide_Nav_ErrorsToggleHints
  ; </summary>
  Procedure Ide_Nav_ErrorsToggleHints()
    Ide_ErrShowHints = Bool(Ide_ErrShowHints = 0)
    SetMenuItemState(#MENU_MAIN, #MNU_ERRORS_HINTS, Ide_ErrShowHints)
    Ide_Editor_SavePrefs()
    Ide_Nav_ErrorsRefreshGadget()
    If Ide_ErrShowHints
      Ide_Ui_SetStatus(Ide_I18n_Pick("Error list: show hints", "status.err_hints_on"))
    Else
      Ide_Ui_SetStatus(Ide_I18n_Pick("Error list: errors only", "status.err_hints_off"))
    EndIf
  EndProcedure

  ; <summary>
  ; After a failed F5 run, auto-open the error List when new rows appear.
  ; </summary>
  Procedure Ide_Nav_ErrorsPrepareRun()
    Ide_ErrAutoOpen = #True
  EndProcedure

  ; <summary>
  ; IDE: Nav ErrorsPrepareF8.
  ; </summary>
  Procedure Ide_Nav_ErrorsPrepareF8()
    Ide_ErrAutoOpen = #True
  EndProcedure

  ; <summary>
  ; IDE: Nav ErrorsOnSyntaxCheckDone.
  ; </summary>
  ; <param name="oki">see signature</param>
  Procedure Ide_Nav_ErrorsOnSyntaxCheckDone(ok.i)
    If ok
      Ide_ErrAutoOpen = #False
      ProcedureReturn
    EndIf
    If Ide_ErrAutoOpen And Ide_ErrCount > 0
      If Ide_ErrorsVisible = #False
        Ide_ErrorsVisible = #True
        SetMenuItemState(#MENU_MAIN, #MNU_ERRORS_PANEL, #True)
        Ide_Ui_Layout()
        Ide_Editor_ResizeEditors()
        Ide_Editor_SavePrefs()
      EndIf
      Ide_Nav_ErrorsRefreshGadget()
    EndIf
    Ide_ErrAutoOpen = #False
  EndProcedure

  ; <summary>
  ; IDE: Nav ErrorsToggle.
  ; </summary>
  Procedure Ide_Nav_ErrorsToggle()
    Ide_ErrorsVisible = Bool(Ide_ErrorsVisible = 0)
    SetMenuItemState(#MENU_MAIN, #MNU_ERRORS_PANEL, Ide_ErrorsVisible)
    Ide_Ui_Layout()
    Ide_Editor_ResizeEditors()
    If Ide_ErrorsVisible
      Ide_Nav_ErrorsRefreshGadget()
    EndIf
    Ide_Editor_SavePrefs()
  EndProcedure

  ; <summary>
  ; IDE: Nav ErrorsActivate.
  ; </summary>
  ; <param name="prefix">string</param>
  Procedure Ide_Nav_ErrorsFilterByCode(prefix.s)
    Ide_ErrCodeFilter = Trim(prefix)
    Ide_Nav_ErrorsRefreshGadget()
    If Ide_ErrCodeFilter <> ""
      Ide_Ui_SetStatus(Ide_I18n_Fmt1("Error list filter: {code}", "status.err_filter", "{code}", Ide_ErrCodeFilter))
    Else
      Ide_Ui_SetStatus(Ide_I18n_Pick("Error list filter cleared", "status.err_filter_clear"))
    EndIf
    Ide_Editor_SavePrefs()
  EndProcedure
  
  ; <summary>
  ; Ide_Nav_ErrorsPromptFilter
  ; </summary>
  Procedure Ide_Nav_ErrorsPromptFilter()
    Protected s.s = InputRequester(Ide_I18n_Pick("Error list", "dlg.err_list_title"), Ide_I18n_Pick("Show rows whose diagnostic code contains (empty = all):", "dlg.err_filter_prompt"), Ide_ErrCodeFilter, #PB_InputRequester_HandleCancel)
    If s <> #PB_InputRequester_Cancel
      Ide_Nav_ErrorsFilterByCode(s)
    EndIf
  EndProcedure
  
  ; <summary>
  ; Ide_Nav_ErrorsCopyRowLocation
  ; </summary>
  ; <param name="errIdx">integer</param>
  Procedure Ide_Nav_ErrorsCopyRowLocation(errIdx.i)
    Protected loc.s
    If errIdx < 0 Or errIdx >= Ide_ErrCount
      ProcedureReturn
    EndIf
    loc = Ide_ErrFile(errIdx)
    If loc = ""
      loc = Ide_FilePath
    EndIf
    If Ide_ErrRow(errIdx) > 0
      loc = loc + ":" + Str(Ide_ErrRow(errIdx))
      If Ide_ErrCol(errIdx) > 0
        loc = loc + ":" + Str(Ide_ErrCol(errIdx))
      EndIf
    EndIf
    SetClipboardText(loc)
    Ide_Ui_SetStatus(Ide_I18n_Pick("Copied error location", "status.err_copy_loc"))
  EndProcedure
  
  ; <summary>
  ; Ide_Nav_ErrorsCopyRowCode
  ; </summary>
  ; <param name="errIdx">integer</param>
  Procedure Ide_Nav_ErrorsCopyRowCode(errIdx.i)
    If errIdx < 0 Or errIdx >= Ide_ErrCount Or Ide_ErrCode(errIdx) = ""
      Ide_Ui_SetStatus(Ide_I18n_Pick("No diagnostic code on this row", "status.err_no_code"))
      ProcedureReturn
    EndIf
    SetClipboardText(Ide_ErrCode(errIdx))
    Ide_Ui_SetStatus(Ide_I18n_Pick("Copied diagnostic code", "status.err_copy_code"))
  EndProcedure
  
  ; <summary>
  ; Ide_Nav_ErrorsHandlePopup
  ; </summary>
  ; <param name="item">integer</param>
  Procedure Ide_Nav_ErrorsHandlePopup(item.i)
    Protected idx.i, errIdx.i
    idx = GetGadgetState(#GAD_ERRLIST)
    If idx < 0
      ProcedureReturn
    EndIf
    errIdx = Ide_Nav_ErrorsListIndex(idx)
    If errIdx < 0
      ProcedureReturn
    EndIf
    Select item
      Case #POP_ERR_COPY_LOC
        Ide_Nav_ErrorsCopyRowLocation(errIdx)
      Case #POP_ERR_COPY_CODE
        Ide_Nav_ErrorsCopyRowCode(errIdx)
      Case #POP_ERR_SET_FILTER
        If Ide_ErrCode(errIdx) <> ""
          Ide_Nav_ErrorsFilterByCode(Ide_ErrCode(errIdx))
        EndIf
      Case #POP_ERR_CLEAR_FILTER
        Ide_Nav_ErrorsFilterByCode("")
    EndSelect
  EndProcedure
  
  ; <summary>
  ; Ide_Nav_ErrorsActivate
  ; </summary>
  Procedure Ide_Nav_ErrorsActivate()
    Protected idx.i, ln.i, errIdx.i
    If IsGadget(#GAD_ERRLIST) = #False
      ProcedureReturn
    EndIf
    idx = GetGadgetState(#GAD_ERRLIST)
    If idx < 0
      ProcedureReturn
    EndIf
    errIdx = Ide_Nav_ErrorsListIndex(idx)
    If errIdx < 0 Or errIdx >= Ide_ErrCount
      ProcedureReturn
    EndIf
    ln = Ide_ErrRow(errIdx)
    If ln > 0
      If Ide_ErrHint(errIdx)
        Ide_Editor_GotoDiagnosticPath(Ide_ErrFile(errIdx), ln, #True)
      Else
        Ide_Editor_GotoDiagnosticPath(Ide_ErrFile(errIdx), ln, #False)
      EndIf
      If Ide_ErrCol(errIdx) > 0
        Ide_Editor_GotoColumn(Ide_ErrCol(errIdx))
      EndIf
    ElseIf Ide_ErrHint(errIdx)
      Ide_Ui_SetStatus(Ide_I18n_Pick("Hint has no line number", "status.hint_no_ln"))
    EndIf
  EndProcedure

  ; <summary>
  ; IDE: Nav ErrorsLayout.
  ; </summary>
  ; <param name="lefti">see signature</param>
  ; <param name="y0i">see signature</param>
  ; <param name="wi">see signature</param>
  ; <param name="hi">see signature</param>
  Procedure Ide_Nav_ErrorsLayout(left.i, y0.i, w.i, h.i)
    If IsGadget(#GAD_ERRLIST) = #False
      ProcedureReturn
    EndIf
    HideGadget(#GAD_ERRLIST, Bool(Ide_ErrorsVisible = 0))
    If Ide_ErrorsVisible
      ResizeGadget(#GAD_ERRLIST, 0, y0, w, h)
    EndIf
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 30
; Folding = -----
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)