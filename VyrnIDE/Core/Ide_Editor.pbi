;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - Scintilla editor (tabs, find/replace, zoom, theme)
; PureBasic 6.40

CompilerIf Defined(Ide_Editor, #PB_Constant) = #False
  #Ide_Editor = #True

  CompilerIf Defined(SC_CP_UTF8, #PB_Constant) = #False
    #SC_CP_UTF8 = 65001
  CompilerEndIf
  CompilerIf Defined(SC_MARGIN_NUMBER, #PB_Constant) = #False
    #SC_MARGIN_NUMBER = 1
  CompilerEndIf
  CompilerIf Defined(SC_MOD_INSERTTEXT, #PB_Constant) = #False
    #SC_MOD_INSERTTEXT = $1
  CompilerEndIf
  CompilerIf Defined(SC_MOD_DELETETEXT, #PB_Constant) = #False
    #SC_MOD_DELETETEXT = $2
  CompilerEndIf
  CompilerIf Defined(SCN_MODIFIED, #PB_Constant) = #False
    #SCN_MODIFIED = 2012
  CompilerEndIf
  CompilerIf Defined(SCN_UPDATEUI, #PB_Constant) = #False
    #SCN_UPDATEUI = 2007
  CompilerEndIf
  CompilerIf Defined(SCI_SETMODEVENTMASK, #PB_Constant) = #False
    #SCI_SETMODEVENTMASK = 2351
  CompilerEndIf
  CompilerIf Defined(SCI_SETSCROLLWIDTHTRACKING, #PB_Constant) = #False
    #SCI_SETSCROLLWIDTHTRACKING = 2516
  CompilerEndIf
  CompilerIf Defined(SCI_EMPTYUNDOBUFFER, #PB_Constant) = #False
    #SCI_EMPTYUNDOBUFFER = 2175
  CompilerEndIf
  CompilerIf Defined(SC_EOL_LF, #PB_Constant) = #False
    #SC_EOL_LF = 2
  CompilerEndIf
  CompilerIf Defined(SC_MARGIN_SYMBOL, #PB_Constant) = #False
    #SC_MARGIN_SYMBOL = 0
  CompilerEndIf
  CompilerIf Defined(SC_MARK_SHORTARROW, #PB_Constant) = #False
    #SC_MARK_SHORTARROW = 4
  CompilerEndIf
  CompilerIf Defined(SC_MARK_BACKGROUND, #PB_Constant) = #False
    #SC_MARK_BACKGROUND = 22
  CompilerEndIf
  CompilerIf Defined(SCI_MARKERDELETEALL, #PB_Constant) = #False
    #SCI_MARKERDELETEALL = 2045
  CompilerEndIf
  CompilerIf Defined(SCI_MARKERDEFINE, #PB_Constant) = #False
    #SCI_MARKERDEFINE = 2040
  CompilerEndIf
  CompilerIf Defined(SCI_MARKERADD, #PB_Constant) = #False
    #SCI_MARKERADD = 2043
  CompilerEndIf
  CompilerIf Defined(SCI_SETMARGINMASKN, #PB_Constant) = #False
    #SCI_SETMARGINMASKN = 2243
  CompilerEndIf
  CompilerIf Defined(SCI_GOTOLINE, #PB_Constant) = #False
    #SCI_GOTOLINE = 2024
  CompilerEndIf
  CompilerIf Defined(SCI_ENSUREVISIBLEENFORCEPOLICY, #PB_Constant) = #False
    #SCI_ENSUREVISIBLEENFORCEPOLICY = 2234
  CompilerEndIf
  CompilerIf Defined(SCI_POSITIONFROMLINE, #PB_Constant) = #False
    #SCI_POSITIONFROMLINE = 2167
  CompilerEndIf
  CompilerIf Defined(SCI_GETLINEENDPOSITION, #PB_Constant) = #False
    #SCI_GETLINEENDPOSITION = 2136
  CompilerEndIf
  CompilerIf Defined(SCI_SETSEL, #PB_Constant) = #False
    #SCI_SETSEL = 2160
  CompilerEndIf
  CompilerIf Defined(SCI_SCROLLCARET, #PB_Constant) = #False
    #SCI_SCROLLCARET = 2169
  CompilerEndIf
  CompilerIf Defined(SCI_GETLINECOUNT, #PB_Constant) = #False
    #SCI_GETLINECOUNT = 2154
  CompilerEndIf
  CompilerIf Defined(SCI_SETCODEPAGE, #PB_Constant) = #False
    #SCI_SETCODEPAGE = 2037
  CompilerEndIf
  CompilerIf Defined(SCI_SETTABWIDTH, #PB_Constant) = #False
    #SCI_SETTABWIDTH = 2036
  CompilerEndIf
  CompilerIf Defined(SCI_SETUSETABS, #PB_Constant) = #False
    #SCI_SETUSETABS = 2124
  CompilerEndIf
  CompilerIf Defined(SCI_SETMARGINWIDTHN, #PB_Constant) = #False
    #SCI_SETMARGINWIDTHN = 2242
  CompilerEndIf
  CompilerIf Defined(SCI_SETMARGINTYPEN, #PB_Constant) = #False
    #SCI_SETMARGINTYPEN = 2240
  CompilerEndIf
  CompilerIf Defined(SCI_SETZOOM, #PB_Constant) = #False
    #SCI_SETZOOM = 2373
  CompilerEndIf
  CompilerIf Defined(SCI_ZOOMIN, #PB_Constant) = #False
    #SCI_ZOOMIN = 2333
  CompilerEndIf
  CompilerIf Defined(SCI_ZOOMOUT, #PB_Constant) = #False
    #SCI_ZOOMOUT = 2334
  CompilerEndIf
  CompilerIf Defined(SCI_GETZOOM, #PB_Constant) = #False
    #SCI_GETZOOM = 2374
  CompilerEndIf
  CompilerIf Defined(SCI_GETCURRENTPOS, #PB_Constant) = #False
    #SCI_GETCURRENTPOS = 2008
  CompilerEndIf
  CompilerIf Defined(SCI_SETTARGETSTART, #PB_Constant) = #False
    #SCI_SETTARGETSTART = 2190
  CompilerEndIf
  CompilerIf Defined(SCI_SETTARGETEND, #PB_Constant) = #False
    #SCI_SETTARGETEND = 2192
  CompilerEndIf
  CompilerIf Defined(SCI_SEARCHINTARGET, #PB_Constant) = #False
    #SCI_SEARCHINTARGET = 2197
  CompilerEndIf
  CompilerIf Defined(SCI_REPLACETARGET, #PB_Constant) = #False
    #SCI_REPLACETARGET = 2194
  CompilerEndIf
  CompilerIf Defined(SCI_SETSEARCHFLAGS, #PB_Constant) = #False
    #SCI_SETSEARCHFLAGS = 2198
  CompilerEndIf
  CompilerIf Defined(SCFIND_MATCHCASE, #PB_Constant) = #False
    #SCFIND_MATCHCASE = 4
  CompilerEndIf
  CompilerIf Defined(SCI_GETTARGETEND, #PB_Constant) = #False
    #SCI_GETTARGETEND = 2193
  CompilerEndIf
  CompilerIf Defined(SCI_GETSELTEXT, #PB_Constant) = #False
    #SCI_GETSELTEXT = 2161
  CompilerEndIf
  CompilerIf Defined(SCI_REPLACESEL, #PB_Constant) = #False
    #SCI_REPLACESEL = 2170
  CompilerEndIf
  CompilerIf Defined(SCI_SETFOCUS, #PB_Constant) = #False
    #SCI_SETFOCUS = 2380
  CompilerEndIf
  CompilerIf Defined(SCI_STYLESETFONT, #PB_Constant) = #False
    #SCI_STYLESETFONT = 2056
  CompilerEndIf
  CompilerIf Defined(SCI_STYLESETSIZE, #PB_Constant) = #False
    #SCI_STYLESETSIZE = 2050
  CompilerEndIf
  CompilerIf Defined(SCI_SETEOLMODE, #PB_Constant) = #False
    #SCI_SETEOLMODE = 2031
  CompilerEndIf
  CompilerIf Defined(SCI_UNDO, #PB_Constant) = #False
    #SCI_UNDO = 2176
  CompilerEndIf
  CompilerIf Defined(SCI_REDO, #PB_Constant) = #False
    #SCI_REDO = 2011
  CompilerEndIf
  CompilerIf Defined(SCI_CUT, #PB_Constant) = #False
    #SCI_CUT = 2177
  CompilerEndIf
  CompilerIf Defined(SCI_COPY, #PB_Constant) = #False
    #SCI_COPY = 2178
  CompilerEndIf
  CompilerIf Defined(SCI_PASTE, #PB_Constant) = #False
    #SCI_PASTE = 2179
  CompilerEndIf
  CompilerIf Defined(SCI_GETMODIFY, #PB_Constant) = #False
    #SCI_GETMODIFY = 2159
  CompilerEndIf
  CompilerIf Defined(SCI_SETSAVEPOINT, #PB_Constant) = #False
    #SCI_SETSAVEPOINT = 2014
  CompilerEndIf
  CompilerIf Defined(SCI_SETTEXT, #PB_Constant) = #False
    #SCI_SETTEXT = 2181
  CompilerEndIf
  CompilerIf Defined(SCI_GETTEXT, #PB_Constant) = #False
    #SCI_GETTEXT = 2182
  CompilerEndIf
  CompilerIf Defined(SCI_GETLENGTH, #PB_Constant) = #False
    #SCI_GETLENGTH = 2006
  CompilerEndIf
  CompilerIf Defined(SCI_CLEARALL, #PB_Constant) = #False
    #SCI_CLEARALL = 2004
  CompilerEndIf
  CompilerIf Defined(SCI_GETCOLUMN, #PB_Constant) = #False
    #SCI_GETCOLUMN = 2129
  CompilerEndIf
  CompilerIf Defined(SCI_LINEFROMPOSITION, #PB_Constant) = #False
    #SCI_LINEFROMPOSITION = 2166
  CompilerEndIf

  Structure Ide_Tab
    gadget.i
    path.s
    untitled.i
  EndStructure

  Global Dim Ide_Tabs.Ide_Tab(31)
  Global Ide_TabCount.i = 0
  Global Ide_UntitledSeq.i = 0
  Global Ide_Zoom.i = 0
  Global Ide_FilePath.s = ""
  Global Ide_NeedRestyle.i = #False
  Global Ide_NeedRestyleGadget.i = 0
  Global Ide_TitleBase.s = "Vyrn IDE"

  Declare Ide_Editor_Callback(g.i, *scinotify.SCNotification)
  Declare Ide_Editor_ApplyThemeAll()
  Declare Ide_Editor_ResizeEditors()
  Declare Ide_Editor_SyncActive()
  Declare Ide_Editor_UpdateTitle()
  Declare Ide_Editor_UpdateCaretStatus()
  Declare Ide_Editor_SavePrefs()
  Declare Ide_Editor_New()

  ; <summary>
  ; Path to vyrnide.ini next to the IDE executable.
  ; </summary>
  ; <returns>Full path of the preferences file.</returns>
  Procedure.s Ide_Editor_PrefPath()
    ProcedureReturn GetPathPart(ProgramFilename()) + "vyrnide.ini"
  EndProcedure

  ; <summary>
  ; Load theme and zoom preferences from vyrnide.ini.
  ; </summary>
  Procedure Ide_Editor_LoadPrefs()
    Protected path.s = Ide_Editor_PrefPath()
    
    If OpenPreferences(path)
      PreferenceGroup("editor")
      Ide_Theme_Dark = ReadPreferenceInteger("dark", 0)
      Ide_Zoom = ReadPreferenceInteger("zoom", 0)
      ClosePreferences()
    EndIf
  EndProcedure

  ; <summary>
  ; Persist theme and zoom preferences to vyrnide.ini.
  ; </summary>
  Procedure Ide_Editor_SavePrefs()
    Protected path.s = Ide_Editor_PrefPath()
    
    If CreatePreferences(path)
      PreferenceGroup("editor")
      WritePreferenceInteger("dark", Ide_Theme_Dark)
      WritePreferenceInteger("zoom", Ide_Zoom)
      ClosePreferences()
    EndIf
  EndProcedure

  ; <summary>
  ; Byte length of a null-terminated UTF-8 C string.
  ; </summary>
  ; <param name="*p">Pointer to UTF-8 bytes, or 0.</param>
  ; <returns>Length in bytes excluding the terminator.</returns>
  Procedure.i Ide_Utf8Bytes(*p)
    Protected n.i = 0
    
    If *p = 0
      ProcedureReturn 0
    EndIf
    
    While PeekA(*p + n)
      n = n + 1
    Wend
    
    ProcedureReturn n
  EndProcedure

  ; <summary>
  ; Index of the selected tab in #GAD_TABS.
  ; </summary>
  ; <returns>Tab index, 0 if selection invalid, or -1 when no tabs.</returns>
  Procedure.i Ide_Editor_ActiveIndex()
    Protected idx.i
    
    If Ide_TabCount < 1
      ProcedureReturn -1
    EndIf
    
    idx = GetGadgetState(#GAD_TABS)
    
    If idx < 0 Or idx >= Ide_TabCount
      ProcedureReturn 0
    EndIf
    
    ProcedureReturn idx
  EndProcedure

  ; <summary>
  ; Scintilla gadget id for the active tab.
  ; </summary>
  ; <returns>Gadget id, or 0 if none.</returns>
  Procedure.i Ide_Editor_CurrentGadget()
    Protected idx.i = Ide_Editor_ActiveIndex()
    If idx < 0
      ProcedureReturn 0
    EndIf
    
    ProcedureReturn Ide_Tabs(idx)\gadget
  EndProcedure

  ; <summary>
  ; Configure Scintilla chrome: UTF-8, tabs, margins, markers, font, zoom, and highlight styles.
  ; </summary>
  ; <param name="g">Scintilla gadget id.</param>
  Procedure Ide_Editor_ApplyGadgetChrome(g.i)
    Protected *font
    
    If g = 0 Or IsGadget(g) = 0
      ProcedureReturn
    EndIf
    
    ScintillaSendMessage(g, #SCI_SETCODEPAGE, #SC_CP_UTF8, 0)
    ScintillaSendMessage(g, #SCI_SETTABWIDTH, 2, 0)
    ScintillaSendMessage(g, #SCI_SETUSETABS, 0, 0)
    ScintillaSendMessage(g, #SCI_SETSCROLLWIDTHTRACKING, 1, 0)
    ScintillaSendMessage(g, #SCI_SETEOLMODE, #SC_EOL_LF, 0)
    ScintillaSendMessage(g, #SCI_SETMODEVENTMASK, #SC_MOD_INSERTTEXT | #SC_MOD_DELETETEXT, 0)
    ScintillaSendMessage(g, #SCI_SETMARGINTYPEN, 0, #SC_MARGIN_NUMBER)
    ScintillaSendMessage(g, #SCI_SETMARGINWIDTHN, 0, 48)
    ScintillaSendMessage(g, #SCI_SETMARGINTYPEN, #Ide_MarginSymbol, #SC_MARGIN_SYMBOL)
    ScintillaSendMessage(g, #SCI_SETMARGINWIDTHN, #Ide_MarginSymbol, 16)
    ScintillaSendMessage(g, #SCI_SETMARGINMASKN, #Ide_MarginSymbol, (1 << #Ide_MarkError) | (1 << #Ide_MarkWarn))
    ScintillaSendMessage(g, #SCI_MARKERDEFINE, #Ide_MarkError, #SC_MARK_SHORTARROW)
    ScintillaSendMessage(g, #SCI_MARKERDEFINE, #Ide_MarkWarn, #SC_MARK_SHORTARROW)
    ScintillaSendMessage(g, #SCI_MARKERDEFINE, #Ide_MarkErrorBack, #SC_MARK_BACKGROUND)
    ScintillaSendMessage(g, #SCI_MARKERDEFINE, #Ide_MarkWarnBack, #SC_MARK_BACKGROUND)
    *font = UTF8("Consolas")
    
    If *font
      ScintillaSendMessage(g, #SCI_STYLESETFONT, #STYLE_DEFAULT, *font)
      FreeMemory(*font)
    EndIf
    
    ScintillaSendMessage(g, #SCI_STYLESETSIZE, #STYLE_DEFAULT, 11)
    ScintillaSendMessage(g, #SCI_SETZOOM, Ide_Zoom, 0)
    Ide_Highlight_ApplyStyles(g)
    Ide_Highlight_Restyle(g)
  EndProcedure

  ; <summary>
  ; Tab caption for index: file name or untitled-N.vyrn, with * when modified.
  ; </summary>
  ; <param name="idx">Tab index.</param>
  ; <returns>Caption string, or empty if idx is out of range.</returns>
  Procedure.s Ide_Editor_TabCaption(idx.i)
    Protected name.s
    If idx < 0 Or idx >= Ide_TabCount
      ProcedureReturn ""
    EndIf
    
    If Ide_Tabs(idx)\untitled Or Ide_Tabs(idx)\path = ""
      name = "untitled-" + Str(Ide_Tabs(idx)\untitled) + ".vyrn"
    Else
      name = GetFilePart(Ide_Tabs(idx)\path)
    EndIf
    
    If ScintillaSendMessage(Ide_Tabs(idx)\gadget, #SCI_GETMODIFY)
      name = "*" + name
    EndIf
    
    ProcedureReturn name
  EndProcedure

  ; <summary>
  ; Refresh the panel item text for one tab from Ide_Editor_TabCaption.
  ; </summary>
  ; <param name="idx">Tab index.</param>
  Procedure Ide_Editor_RefreshTab(idx.i)
    If idx < 0 Or idx >= Ide_TabCount
      ProcedureReturn
    EndIf
    
    SetGadgetItemText(#GAD_TABS, idx, Ide_Editor_TabCaption(idx))
  EndProcedure

  ; <summary>
  ; Update the window title to "file - Vyrn IDE" (with dirty marker when modified).
  ; </summary>
  Procedure Ide_Editor_UpdateTitle()
    Protected idx.i = Ide_Editor_ActiveIndex()
    Protected title.s = Ide_TitleBase
    Protected name.s
    
    If idx >= 0
      If Ide_Tabs(idx)\path <> ""
        name = GetFilePart(Ide_Tabs(idx)\path)
      Else
        name = Ide_Editor_TabCaption(idx)
        
        If Left(name, 1) = "*"
          name = Mid(name, 2)
        EndIf
      EndIf
      title = name + " - " + Ide_TitleBase
      
      If ScintillaSendMessage(Ide_Tabs(idx)\gadget, #SCI_GETMODIFY)
        title = "* " + title
      EndIf
    EndIf
    
    SetWindowTitle(#WIN_IDE, title)
  EndProcedure

  ; <summary>
  ; Show caret line/column and active path in the status bar.
  ; </summary>
  Procedure Ide_Editor_UpdateCaretStatus()
    Protected g.i = Ide_Editor_CurrentGadget()
    Protected pos.i, line.i, col.i, pathHint.s
    
    If g = 0
      Ide_Ui_SetStatus("Ready")
      ProcedureReturn
    EndIf
    
    pos = ScintillaSendMessage(g, #SCI_GETCURRENTPOS)
    line = ScintillaSendMessage(g, #SCI_LINEFROMPOSITION, pos) + 1
    col = ScintillaSendMessage(g, #SCI_GETCOLUMN, pos) + 1
    
    If Ide_FilePath <> ""
      pathHint = Ide_FilePath
    Else
      pathHint = Ide_Editor_TabCaption(Ide_Editor_ActiveIndex())
      
      If Left(pathHint, 1) = "*"
        pathHint = Mid(pathHint, 2)
      EndIf
    EndIf
    
    Ide_Ui_SetStatus("Ln " + Str(line) + " Col " + Str(col) + " | " + pathHint + " | Vyrn " + Vyrn_ProductVersion())
  EndProcedure

  ; <summary>
  ; Sync Ide_FilePath and UI chrome after the active tab changes.
  ; </summary>
  Procedure Ide_Editor_SyncActive()
    Protected idx.i = Ide_Editor_ActiveIndex()
    
    If idx < 0
      Ide_FilePath = ""
      ProcedureReturn
    EndIf
    
    Ide_FilePath = Ide_Tabs(idx)\path
    Ide_Editor_RefreshTab(idx)
    Ide_Editor_UpdateTitle()
    Ide_Editor_UpdateCaretStatus()
  EndProcedure

  ; <summary>
  ; Resize every Scintilla to the current panel item client area.
  ; </summary>
  Procedure Ide_Editor_ResizeEditors()
    Protected i.i, innerW.i, innerH.i
    
    If IsGadget(#GAD_TABS) = 0
      ProcedureReturn
    EndIf
    
    innerW = GetGadgetAttribute(#GAD_TABS, #PB_Panel_ItemWidth)
    innerH = GetGadgetAttribute(#GAD_TABS, #PB_Panel_ItemHeight)
    
    If innerW < 40
      innerW = Ide_EditorW
    EndIf
    
    If innerH < 40
      innerH = Ide_EditorH - 28
    EndIf
    
    If innerW < 40 : innerW = 40 : EndIf
    If innerH < 40 : innerH = 40 : EndIf
    
    For i = 0 To Ide_TabCount - 1
      If IsGadget(Ide_Tabs(i)\gadget)
        ResizeGadget(Ide_Tabs(i)\gadget, 0, 0, innerW, innerH)
      EndIf
    Next
  EndProcedure

  ; <summary>
  ; Add a tab (optional path) with a new Scintilla; selects it and applies chrome.
  ; </summary>
  ; <param name="path">File path, or empty for untitled.</param>
  ; <returns>New tab index, or -1 if the 32-tab limit is reached.</returns>
  Procedure.i Ide_Editor_AddTab(path.s)
    Protected idx.i, g.i, caption.s
    
    If Ide_TabCount >= 32
      MessageRequester("Vyrn IDE", "Maximum 32 tabs.", #PB_MessageRequester_Warning)
      ProcedureReturn -1
    EndIf
    
    idx = Ide_TabCount
    
    If path = ""
      Ide_UntitledSeq = Ide_UntitledSeq + 1
      caption = "untitled-" + Str(Ide_UntitledSeq) + ".vyrn"
    Else
      caption = GetFilePart(path)
    EndIf
    
    AddGadgetItem(#GAD_TABS, idx, caption)
    OpenGadgetList(#GAD_TABS, idx)
    g = ScintillaGadget(#PB_Any, 0, 0, Ide_EditorW, 200, @Ide_Editor_Callback())
    CloseGadgetList()
    Ide_Tabs(idx)\gadget = g
    Ide_Tabs(idx)\path = path
    
    If path = ""
      Ide_Tabs(idx)\untitled = Ide_UntitledSeq
    Else
      Ide_Tabs(idx)\untitled = 0
    EndIf
    
    Ide_TabCount = Ide_TabCount + 1
    SetGadgetState(#GAD_TABS, idx)
    Ide_Editor_ApplyGadgetChrome(g)
    Ide_Editor_ResizeEditors()
    Ide_Editor_SyncActive()
    ProcedureReturn idx
  EndProcedure

  ; <summary>
  ; Find a tab whose path matches (case-insensitive).
  ; </summary>
  ; <param name="path">Absolute or relative file path.</param>
  ; <returns>Tab index, or -1 if not open.</returns>
  Procedure.i Ide_Editor_FindPath(path.s)
    Protected i.i
    
    If path = ""
      ProcedureReturn -1
    EndIf
    
    For i = 0 To Ide_TabCount - 1
      If LCase(Ide_Tabs(i)\path) = LCase(path)
        ProcedureReturn i
      EndIf
    Next
    
    ProcedureReturn -1
  EndProcedure

  ; <summary>
  ; Editor subsystem init: load prefs and apply window chrome.
  ; </summary>
  Procedure Ide_Editor_Create()
    Ide_Editor_LoadPrefs()
    Ide_Ui_ApplyChrome()
  EndProcedure

  ; <summary>
  ; Re-apply theme/chrome to UI and every open Scintilla, then save prefs.
  ; </summary>
  Procedure Ide_Editor_ApplyThemeAll()
    Protected i.i
    
    Ide_Ui_ApplyChrome()
    
    For i = 0 To Ide_TabCount - 1
      Ide_Editor_ApplyGadgetChrome(Ide_Tabs(i)\gadget)
    Next
    
    Ide_Editor_SavePrefs()
  EndProcedure

  ; <summary>
  ; Read full UTF-8 text from a Scintilla gadget.
  ; </summary>
  ; <param name="g">Scintilla gadget id.</param>
  ; <returns>Document text, or empty on failure.</returns>
  Procedure.s Ide_Editor_GetTextFrom(g.i)
    Protected len.i, *buf, result.s
    
    If g = 0 Or IsGadget(g) = 0
      ProcedureReturn ""
    EndIf
    
    len = ScintillaSendMessage(g, #SCI_GETLENGTH)
    
    If len <= 0
      ProcedureReturn ""
    EndIf
    
    *buf = AllocateMemory(len + 4)
    
    If *buf = 0
      ProcedureReturn ""
    EndIf
    
    FillMemory(*buf, len + 4, 0)
    ScintillaSendMessage(g, #SCI_GETTEXT, len + 1, *buf)
    result = PeekS(*buf, -1, #PB_UTF8)
    FreeMemory(*buf)
    
    ProcedureReturn result
  EndProcedure

  ; <summary>
  ; Replace active buffer text, clear undo, mark clean, and restyle.
  ; </summary>
  ; <param name="text">UTF-8 source to load into the active Scintilla.</param>
  Procedure Ide_Editor_SetText(text.s)
    Protected g.i = Ide_Editor_CurrentGadget()
    Protected *utf
    
    If g = 0
      ProcedureReturn
    EndIf
    
    *utf = UTF8(text)
    
    If *utf
      ScintillaSendMessage(g, #SCI_SETTEXT, 0, *utf)
      FreeMemory(*utf)
    Else
      ScintillaSendMessage(g, #SCI_CLEARALL)
    EndIf
    
    ScintillaSendMessage(g, #SCI_EMPTYUNDOBUFFER)
    ScintillaSendMessage(g, #SCI_SETSAVEPOINT)
    Ide_Highlight_Restyle(g)
    Ide_NeedRestyle = #False
    Ide_Editor_SyncActive()
  EndProcedure

  ; <summary>
  ; Get UTF-8 text of the active tab.
  ; </summary>
  ; <returns>Active document text.</returns>
  Procedure.s Ide_Editor_GetText()
    ProcedureReturn Ide_Editor_GetTextFrom(Ide_Editor_CurrentGadget())
  EndProcedure

  ; <summary>
  ; Whether the active buffer has unsaved changes.
  ; </summary>
  ; <returns>#True if modified.</returns>
  Procedure.i Ide_Editor_IsModified()
    Protected g.i = Ide_Editor_CurrentGadget()
    
    If g = 0
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn Bool(ScintillaSendMessage(g, #SCI_GETMODIFY) <> 0)
  EndProcedure

  ; <summary>
  ; Remove error/warning markers from the active Scintilla.
  ; </summary>
  Procedure Ide_Editor_ClearDiagnostics()
    Protected g.i = Ide_Editor_CurrentGadget()
    
    If g = 0
      ProcedureReturn
    EndIf
    
    ScintillaSendMessage(g, #SCI_MARKERDELETEALL, #Ide_MarkError)
    ScintillaSendMessage(g, #SCI_MARKERDELETEALL, #Ide_MarkWarn)
    ScintillaSendMessage(g, #SCI_MARKERDELETEALL, #Ide_MarkErrorBack)
    ScintillaSendMessage(g, #SCI_MARKERDELETEALL, #Ide_MarkWarnBack)
  EndProcedure

  ; <summary>
  ; Jump to a 1-based line, place error/warn markers, and select the line.
  ; </summary>
  ; <param name="lineNo">1-based source line.</param>
  ; <param name="isWarn">#True for warning markers; #False for error.</param>
  Procedure Ide_Editor_GotoDiagnostic(lineNo.i, isWarn.i = #False)
    Protected g.i = Ide_Editor_CurrentGadget()
    Protected lineCount.i, line0.i, pos.i, endPos.i
    
    If g = 0 Or lineNo < 1
      ProcedureReturn
    EndIf
    
    lineCount = ScintillaSendMessage(g, #SCI_GETLINECOUNT)
    
    If lineNo > lineCount
      lineNo = lineCount
    EndIf
    
    line0 = lineNo - 1
    Ide_Editor_ClearDiagnostics()
    
    If isWarn
      ScintillaSendMessage(g, #SCI_MARKERADD, line0, #Ide_MarkWarn)
      ScintillaSendMessage(g, #SCI_MARKERADD, line0, #Ide_MarkWarnBack)
    Else
      ScintillaSendMessage(g, #SCI_MARKERADD, line0, #Ide_MarkError)
      ScintillaSendMessage(g, #SCI_MARKERADD, line0, #Ide_MarkErrorBack)
    EndIf
    
    ScintillaSendMessage(g, #SCI_ENSUREVISIBLEENFORCEPOLICY, line0)
    ScintillaSendMessage(g, #SCI_GOTOLINE, line0)
    
    pos = ScintillaSendMessage(g, #SCI_POSITIONFROMLINE, line0)
    endPos = ScintillaSendMessage(g, #SCI_GETLINEENDPOSITION, line0)
    
    ScintillaSendMessage(g, #SCI_SETSEL, pos, endPos)
    ScintillaSendMessage(g, #SCI_SCROLLCARET)
    Ide_Editor_UpdateCaretStatus()
  EndProcedure

  ; <summary>
  ; Jump to a 1-based line using error markers (wrapper for GotoDiagnostic).
  ; </summary>
  ; <param name="line">1-based source line.</param>
  Procedure Ide_Editor_GotoLine(line.i)
    Ide_Editor_GotoDiagnostic(line, #False)
  EndProcedure

  ; <summary>
  ; Scintilla notification handler: schedule restyle on edit; update caret status on UI change.
  ; </summary>
  ; <param name="g">Scintilla gadget that raised the notification.</param>
  ; <param name="*scinotify">SCNotification pointer.</param>
  Procedure Ide_Editor_Callback(g.i, *scinotify.SCNotification)
    Protected idx.i, code.i, modType.i
    
    If *scinotify = 0
      ProcedureReturn
    EndIf
    
    code = *scinotify\nmhdr\code
    
    If code = #SCN_MODIFIED
      modType = *scinotify\modificationType
      If modType & (#SC_MOD_INSERTTEXT | #SC_MOD_DELETETEXT)
        Ide_NeedRestyle = #True
        Ide_NeedRestyleGadget = g
        
        For idx = 0 To Ide_TabCount - 1
          If Ide_Tabs(idx)\gadget = g
            Ide_Editor_RefreshTab(idx)
            
            If idx = Ide_Editor_ActiveIndex()
              Ide_Editor_UpdateTitle()
            EndIf
            
            Break
          EndIf
        Next
      EndIf
    ElseIf code = #SCN_UPDATEUI
      If g = Ide_Editor_CurrentGadget()
        Ide_Editor_UpdateCaretStatus()
      EndIf
    EndIf
  EndProcedure

  ; <summary>
  ; Write tab contents to path as UTF-8, update tab path, and mark save point.
  ; </summary>
  ; <param name="idx">Tab index.</param>
  ; <param name="path">Destination file path.</param>
  ; <returns>#True on success.</returns>
  Procedure.i Ide_Editor_SaveTabTo(idx.i, path.s)
    Protected fn.i, text.s
    
    If idx < 0 Or idx >= Ide_TabCount Or path = ""
      ProcedureReturn #False
    EndIf
    
    text = Ide_Editor_GetTextFrom(Ide_Tabs(idx)\gadget)
    fn = CreateFile(#PB_Any, path)
    
    If fn = 0
      ProcedureReturn #False
    EndIf
    
    WriteString(fn, text, #PB_UTF8)
    CloseFile(fn)
    Ide_Tabs(idx)\path = path
    Ide_Tabs(idx)\untitled = 0
    ScintillaSendMessage(Ide_Tabs(idx)\gadget, #SCI_SETSAVEPOINT)
    SetGadgetState(#GAD_TABS, idx)
    Ide_Editor_SyncActive()
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Save the active tab to path.
  ; </summary>
  ; <param name="path">Destination file path.</param>
  ; <returns>#True on success.</returns>
  Procedure.i Ide_Editor_SaveTo(path.s)
    ProcedureReturn Ide_Editor_SaveTabTo(Ide_Editor_ActiveIndex(), path)
  EndProcedure

  ; <summary>
  ; If tab is dirty, prompt Yes/No/Cancel; save when Yes (with Save As if untitled).
  ; </summary>
  ; <param name="idx">Tab index.</param>
  ; <returns>#True to continue; #False if user cancelled.</returns>
  Procedure.i Ide_Editor_ConfirmSaveTab(idx.i)
    Protected r.i, name.s, path.s
    
    If idx < 0 Or idx >= Ide_TabCount
      ProcedureReturn #True
    EndIf
    
    If ScintillaSendMessage(Ide_Tabs(idx)\gadget, #SCI_GETMODIFY) = 0
      ProcedureReturn #True
    EndIf
    
    SetGadgetState(#GAD_TABS, idx)
    Ide_Editor_SyncActive()
    name = Ide_Editor_TabCaption(idx)
    
    If Left(name, 1) = "*"
      name = Mid(name, 2)
    EndIf
    
    r = MessageRequester("Vyrn IDE", "Save changes to " + name + "?", #PB_MessageRequester_YesNoCancel)
    
    If r = #PB_MessageRequester_Cancel
      ProcedureReturn #False
    EndIf
    
    If r = #PB_MessageRequester_No
      ProcedureReturn #True
    EndIf
    
    path = Ide_Tabs(idx)\path
    
    If path = ""
      path = SaveFileRequester("Save Vyrn File", "untitled.vyrn", "Vyrn (*.vyrn)|*.vyrn|All (*.*)|*.*", 0)
      
      If path = ""
        ProcedureReturn #False
      EndIf
      
      If GetExtensionPart(path) = ""
        path = path + ".vyrn"
      EndIf
    EndIf
    
    ProcedureReturn Ide_Editor_SaveTabTo(idx, path)
  EndProcedure

  ; <summary>
  ; Prompt to save every dirty tab; abort if any dialog is cancelled.
  ; </summary>
  ; <returns>#True if all tabs are resolved; #False on cancel.</returns>
  Procedure.i Ide_Editor_ConfirmSaveAll()
    Protected i.i
    For i = 0 To Ide_TabCount - 1
      If Ide_Editor_ConfirmSaveTab(i) = #False
        ProcedureReturn #False
      EndIf
    Next
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Alias for ConfirmSaveAll (used by exit / close-window flows).
  ; </summary>
  ; <returns>#True if all tabs are resolved; #False on cancel.</returns>
  Procedure.i Ide_Editor_ConfirmSaveIfNeeded()
    ProcedureReturn Ide_Editor_ConfirmSaveAll()
  EndProcedure

  ; <summary>
  ; Close the active tab after save confirm; opens a new untitled if none remain.
  ; </summary>
  Procedure Ide_Editor_CloseTab()
    Protected idx.i, i.i
    idx = Ide_Editor_ActiveIndex()
    
    If idx < 0
      ProcedureReturn
    EndIf
    
    If Ide_Editor_ConfirmSaveTab(idx) = #False
      ProcedureReturn
    EndIf
    
    RemoveGadgetItem(#GAD_TABS, idx)
    
    For i = idx To Ide_TabCount - 2
      Ide_Tabs(i) = Ide_Tabs(i + 1)
    Next
    
    Ide_TabCount = Ide_TabCount - 1
    
    If Ide_TabCount < 1
      Ide_Editor_New()
    Else
      If idx >= Ide_TabCount
        idx = Ide_TabCount - 1
      EndIf
      
      SetGadgetState(#GAD_TABS, idx)
      Ide_Editor_ResizeEditors()
      Ide_Editor_SyncActive()
    EndIf
  EndProcedure

  ; <summary>
  ; Create an untitled tab seeded with a short Hello sample.
  ; </summary>
  Procedure Ide_Editor_New()
    Ide_Editor_AddTab("")
    Ide_Editor_SetText("-- vyrn: 12" + Chr(10) + Chr(10) + "local name = " + Chr(34) + "Vyrn" + Chr(34) + Chr(10) + "print(" + Chr(34) + "Hello, {name}!" + Chr(34) + ")" + Chr(10))
  EndProcedure

  ; <summary>
  ; Open path in a new tab, or activate an existing tab for that path.
  ; </summary>
  ; <param name="path">File to load.</param>
  ; <returns>#True on success.</returns>
  Procedure.i Ide_Editor_LoadFile(path.s)
    Protected src.s = ""
    Protected f.i, line.s, idx.i
    
    If path = "" Or FileSize(path) < 0
      ProcedureReturn #False
    EndIf
    
    idx = Ide_Editor_FindPath(path)
    
    If idx >= 0
      SetGadgetState(#GAD_TABS, idx)
      Ide_Editor_SyncActive()
      ProcedureReturn #True
    EndIf
    
    f = ReadFile(#PB_Any, path)
    
    If f = 0
      ProcedureReturn #False
    EndIf
    
    While Eof(f) = #False
      line = ReadString(f)
      src = src + line
      If Eof(f) = #False
        src = src + Chr(10)
      EndIf
    Wend
    
    CloseFile(f)
    
    If Len(src) >= 3 And Asc(Mid(src, 1, 1)) = 239 And Asc(Mid(src, 2, 1)) = 187 And Asc(Mid(src, 3, 1)) = 191
      src = Mid(src, 4)
    EndIf
    
    If Ide_Editor_AddTab(path) < 0
      ProcedureReturn #False
    EndIf
    
    Ide_Editor_SetText(src)
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Undo in the active Scintilla.
  ; </summary>
  Procedure Ide_Editor_Undo()
    Protected g.i = Ide_Editor_CurrentGadget()
    
    If g : ScintillaSendMessage(g, #SCI_UNDO) : EndIf
  EndProcedure

  ; <summary>
  ; Redo in the active Scintilla.
  ; </summary>
  Procedure Ide_Editor_Redo()
    Protected g.i = Ide_Editor_CurrentGadget()
    
    If g : ScintillaSendMessage(g, #SCI_REDO) : EndIf
  EndProcedure

  ; <summary>
  ; Cut selection in the active Scintilla.
  ; </summary>
  Procedure Ide_Editor_Cut()
    Protected g.i = Ide_Editor_CurrentGadget()
    
    If g : ScintillaSendMessage(g, #SCI_CUT) : EndIf
  EndProcedure

  ; <summary>
  ; Copy selection in the active Scintilla.
  ; </summary>
  Procedure Ide_Editor_Copy()
    Protected g.i = Ide_Editor_CurrentGadget()
    
    If g : ScintillaSendMessage(g, #SCI_COPY) : EndIf
  EndProcedure

  ; <summary>
  ; Paste clipboard into the active Scintilla.
  ; </summary>
  Procedure Ide_Editor_Paste()
    Protected g.i = Ide_Editor_CurrentGadget()
    
    If g : ScintillaSendMessage(g, #SCI_PASTE) : EndIf
  EndProcedure

  ; <summary>
  ; Main-loop poll: apply deferred syntax restyle after edits.
  ; </summary>
  Procedure Ide_Editor_PollRestyle()
    If Ide_NeedRestyle
      If Ide_NeedRestyleGadget And IsGadget(Ide_NeedRestyleGadget)
        Ide_Highlight_Restyle(Ide_NeedRestyleGadget)
      Else
        Ide_Highlight_Restyle(Ide_Editor_CurrentGadget())
      EndIf
      
      Ide_NeedRestyle = #False
    EndIf
  EndProcedure

  ; <summary>
  ; Apply Ide_Zoom to every open Scintilla and persist prefs.
  ; </summary>
  Procedure Ide_Editor_ApplyZoomAll()
    Protected i.i
    
    For i = 0 To Ide_TabCount - 1
      If IsGadget(Ide_Tabs(i)\gadget)
        ScintillaSendMessage(Ide_Tabs(i)\gadget, #SCI_SETZOOM, Ide_Zoom, 0)
      EndIf
    Next
    
    Ide_Editor_SavePrefs()
  EndProcedure

  ; <summary>
  ; Zoom in on the active editor and sync zoom across all tabs.
  ; </summary>
  Procedure Ide_Editor_ZoomIn()
    Protected g.i = Ide_Editor_CurrentGadget()
    
    If g
      ScintillaSendMessage(g, #SCI_ZOOMIN)
      Ide_Zoom = ScintillaSendMessage(g, #SCI_GETZOOM)
      Ide_Editor_ApplyZoomAll()
    EndIf
  EndProcedure

  ; <summary>
  ; Zoom out on the active editor and sync zoom across all tabs.
  ; </summary>
  Procedure Ide_Editor_ZoomOut()
    Protected g.i = Ide_Editor_CurrentGadget()
    
    If g
      ScintillaSendMessage(g, #SCI_ZOOMOUT)
      Ide_Zoom = ScintillaSendMessage(g, #SCI_GETZOOM)
      Ide_Editor_ApplyZoomAll()
    EndIf
  EndProcedure

  ; <summary>
  ; Reset zoom to 0 on all tabs.
  ; </summary>
  Procedure Ide_Editor_ZoomReset()
    Ide_Zoom = 0
    Ide_Editor_ApplyZoomAll()
  EndProcedure

  ; <summary>
  ; Toggle light/dark theme and refresh all editors.
  ; </summary>
  Procedure Ide_Editor_ToggleTheme()
    Ide_Theme_Dark = Bool(Ide_Theme_Dark = 0)
    Ide_Editor_ApplyThemeAll()
  EndProcedure

  ; <summary>
  ; UTF-8 text of the current selection in a Scintilla.
  ; </summary>
  ; <param name="g">Scintilla gadget id.</param>
  ; <returns>Selected text, or empty if none.</returns>
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
  ; Find next occurrence of the find-bar needle from the caret (wraps); respects Match case.
  ; </summary>
  ; <returns>#True if a match was selected.</returns>
  Procedure.i Ide_Editor_FindNext()
    Protected g.i = Ide_Editor_CurrentGadget()
    Protected needle.s, *utf8, nlen.i, pos.i, found.i, flags.i, length.i
    
    If g = 0
      ProcedureReturn #False
    EndIf
    
    needle = GetGadgetText(#GAD_FIND_STR)
    
    If needle = ""
      ProcedureReturn #False
    EndIf
    
    flags = 0
    
    If GetGadgetState(#GAD_FIND_CASE)
      flags = #SCFIND_MATCHCASE
    EndIf
    
    ScintillaSendMessage(g, #SCI_SETSEARCHFLAGS, flags, 0)
    *utf8 = UTF8(needle)
    nlen = Ide_Utf8Bytes(*utf8)
    pos = ScintillaSendMessage(g, #SCI_GETCURRENTPOS)
    length = ScintillaSendMessage(g, #SCI_GETLENGTH)
    ScintillaSendMessage(g, #SCI_SETTARGETSTART, pos, 0)
    ScintillaSendMessage(g, #SCI_SETTARGETEND, length, 0)
    found = ScintillaSendMessage(g, #SCI_SEARCHINTARGET, nlen, *utf8)
    
    If found < 0
      ScintillaSendMessage(g, #SCI_SETTARGETSTART, 0, 0)
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
  ; Whether selection equals the find needle under current Match case setting.
  ; </summary>
  ; <param name="sel">Current selection text.</param>
  ; <param name="needle">Find string from the find bar.</param>
  ; <returns>#True if they match.</returns>
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
  ; Replace the current matching selection, then find the next match.
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
      Ide_Ui_SetStatus("No more matches")
    EndIf
  EndProcedure

  ; <summary>
  ; Replace all find-bar matches in the active buffer and report the count.
  ; </summary>
  Procedure Ide_Editor_ReplaceAll()
    Protected g.i = Ide_Editor_CurrentGadget()
    Protected needle.s, repl.s, *n8, *r8, nlen.i, found.i, count.i, flags.i, length.i
    
    If g = 0
      ProcedureReturn
    EndIf
    
    needle = GetGadgetText(#GAD_FIND_STR)
    repl = GetGadgetText(#GAD_REPLACE_STR)
    
    If needle = ""
      ProcedureReturn
    EndIf
    
    flags = 0
    
    If GetGadgetState(#GAD_FIND_CASE)
      flags = #SCFIND_MATCHCASE
    EndIf
    
    ScintillaSendMessage(g, #SCI_SETSEARCHFLAGS, flags, 0)
    *n8 = UTF8(needle)
    *r8 = UTF8(repl)
    nlen = Ide_Utf8Bytes(*n8)
    count = 0
    ScintillaSendMessage(g, #SCI_SETTARGETSTART, 0, 0)
    length = ScintillaSendMessage(g, #SCI_GETLENGTH)
    ScintillaSendMessage(g, #SCI_SETTARGETEND, length, 0)
    found = ScintillaSendMessage(g, #SCI_SEARCHINTARGET, nlen, *n8)
    
    While found >= 0
      ScintillaSendMessage(g, #SCI_REPLACETARGET, -1, *r8)
      count = count + 1
      found = ScintillaSendMessage(g, #SCI_GETTARGETEND)
      length = ScintillaSendMessage(g, #SCI_GETLENGTH)
      ScintillaSendMessage(g, #SCI_SETTARGETSTART, found, 0)
      ScintillaSendMessage(g, #SCI_SETTARGETEND, length, 0)
      found = ScintillaSendMessage(g, #SCI_SEARCHINTARGET, nlen, *n8)
    Wend
    
    If *n8 : FreeMemory(*n8) : EndIf
    If *r8 : FreeMemory(*r8) : EndIf
    
    Ide_Highlight_Restyle(g)
    MessageRequester("Vyrn IDE", "Replaced " + Str(count) + " occurrence(s).", #PB_MessageRequester_Info)
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 229
; Folding = -------------------
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; DllProtection
; EnableOnError
; DisableDebugger
; CompileSourceDirectory
; Compiler = PureBasic 6.41 - C Backend (Windows - x64)