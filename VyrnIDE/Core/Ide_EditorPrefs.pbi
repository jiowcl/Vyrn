;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - editor preferences, MRU, and shared UTF-8 helpers
; PureBasic 6.41

CompilerIf Defined(Ide_EditorPrefs, #PB_Constant) = #False
  #Ide_EditorPrefs = #True

  #Ide_MruMax = 10

  Global Ide_FontName.s = "Consolas"
  Global Ide_FontSize.i = 11
  Global Ide_TabWidth.i = 2
  Global Ide_MruCount.i = 0
  Global Dim Ide_MruPath.s(9)
  Global Ide_LiveCheckEnabled.i = #True
  ; 0 = show Ide_FirstRun_MaybeShow once (new install); 1 = skip.
  Global Ide_FirstRunDone.i = 1
  Global Ide_Zoom.i = 0
  Global Ide_AutoSaveEnabled.i = #False
  Global Ide_ShowWelcome.i = #False
  Global Ide_ShipLastStandalone.s = ""
  Global Ide_ShipLastCompile.s = ""

  Declare Ide_Editor_RefreshMruMenu()
  Declare.i Ide_Editor_LoadFile(path.s)
  Declare.i Ide_Editor_CurrentGadget()
  Declare Ide_Editor_UpdateCaretStatus()
  Declare Ide_Editor_SavePrefs()

  ; <summary>
  ; Path to vyrnide.ini next to the IDE executable.
  ; </summary>
  Procedure.s Ide_Editor_PrefPath()
    ProcedureReturn GetPathPart(ProgramFilename()) + "vyrnide.ini"
  EndProcedure

  ; <summary>
  ; Load editor, window, MRU, and live-check prefs from vyrnide.ini.
  ; </summary>
  Procedure Ide_Editor_LoadPrefs()
    Protected path.s = Ide_Editor_PrefPath()
    Protected i.i
    If FileSize(path) < 0
      Ide_FirstRunDone = 0
    EndIf
    If OpenPreferences(path)
      PreferenceGroup("editor")
      Ide_Theme_Dark = ReadPreferenceInteger("dark", 0)
      Ide_Zoom = ReadPreferenceInteger("zoom", 0)
      Ide_OutputHeight = ReadPreferenceInteger("outputH", #Ide_DefaultOutH)
      Ide_PrefWinW = ReadPreferenceInteger("winW", 960)
      Ide_PrefWinH = ReadPreferenceInteger("winH", 640)
      Ide_PrefWinX = ReadPreferenceInteger("winX", -1)
      Ide_PrefWinY = ReadPreferenceInteger("winY", -1)
      Ide_FontName = ReadPreferenceString("fontName", "Consolas")
      Ide_FontSize = ReadPreferenceInteger("fontSize", 11)
      Ide_TabWidth = ReadPreferenceInteger("tabWidth", 2)
      If Ide_TabWidth < 2 Or Ide_TabWidth > 8
        Ide_TabWidth = 2
      EndIf
      Ide_LiveCheckEnabled = ReadPreferenceInteger("liveCheck", 1)
      Ide_UiLang = ReadPreferenceInteger("uiLang", -1)
      If Ide_UiLang = -1
        Ide_UiLang = Ide_I18n_DetectSystemLang()
        Ide_UiLangPinned = #False
      Else
        Ide_UiLangPinned = #True
        If Ide_UiLang <> #Ide_Lang_Zh
          Ide_UiLang = #Ide_Lang_En
        EndIf
      EndIf
      Ide_ReplVisible = ReadPreferenceInteger("replVisible", 1)
      Ide_OutlineVisible = ReadPreferenceInteger("outline", 0)
      Ide_ErrorsVisible = ReadPreferenceInteger("errorsPanel", 0)
      Ide_ErrShowHints = ReadPreferenceInteger("errShowHints", 1)
      Ide_LiveLintPanelOnly = ReadPreferenceInteger("lintPanelOnly", 1)
      Ide_ErrCodeFilter = ReadPreferenceString("errCodeFilter", "")
      Ide_AutoSaveEnabled = ReadPreferenceInteger("autoSave", 0)
      Ide_ShowWelcome = ReadPreferenceInteger("showWelcome", 1)
      Ide_FirstRunDone = ReadPreferenceInteger("firstRunDone", 1)
      Ide_FindBarPinned = ReadPreferenceInteger("findBar", 0)
      Ide_ProjectVyrnOnly = ReadPreferenceInteger("projectVyrnOnly", 0)
      If Ide_FontSize < 8
        Ide_FontSize = 11
      EndIf
      If Ide_FontSize > 28
        Ide_FontSize = 28
      EndIf
      Ide_MruCount = ReadPreferenceInteger("mruCount", 0)
      If Ide_MruCount > #Ide_MruMax
        Ide_MruCount = #Ide_MruMax
      EndIf
      If Ide_MruCount < 0
        Ide_MruCount = 0
      EndIf
      For i = 0 To #Ide_MruMax - 1
        Ide_MruPath(i) = ReadPreferenceString("mru" + Str(i), "")
      Next
      PreferenceGroup("project")
      Ide_ProjectRoot = ReadPreferenceString("root", "")
      Ide_ProjectVisible = ReadPreferenceInteger("visible", 0)
      Ide_ProjectWidth = ReadPreferenceInteger("width", 220)
      If Ide_ProjectWidth < #Ide_MinProjectW
        Ide_ProjectWidth = 220
      EndIf
      PreferenceGroup("run")
      Ide_RunCfg_MaxLoops = ReadPreferenceInteger("maxLoops", 0)
      Ide_RunCfg_MaxCalls = ReadPreferenceInteger("maxCalls", 256)
      Ide_RunCfg_MaxIns = ReadPreferenceInteger("maxIns", 0)
      Ide_RunCfg_CapNet = ReadPreferenceInteger("capNet", 1)
      Ide_RunCfg_CapProcess = ReadPreferenceInteger("capProcess", 1)
      Ide_RunCfg_NetAllow = ReadPreferenceString("netAllow", "")
      Ide_RunCfg_WorkDir = ReadPreferenceString("workDir", "")
      Ide_RunCfg_ScriptArgs = ReadPreferenceString("scriptArgs", "")
      Ide_RunCfg_Strict = ReadPreferenceInteger("strict", 0)
      Ide_RunCfg_Bench = ReadPreferenceInteger("bench", 0)
      Ide_RunCfg_Unlimited = ReadPreferenceInteger("unlimited", 0)
      Ide_RunCfg_JsonDiag = ReadPreferenceInteger("jsonDiag", 1)
      Ide_RunCfg_TimeoutSecs = ReadPreferenceInteger("timeoutSecs", 0)
      Ide_RunCfg_RunViaVyrnc = ReadPreferenceInteger("runViaVyrnc", 0)
      Ide_ProjectEntry = ReadPreferenceString("entryScript", "")
      Ide_ProjectEntryRoot = ReadPreferenceString("entryRoot", "")
      Ide_ShipLastStandalone = ReadPreferenceString("shipLastStandalone", "")
      Ide_ShipLastCompile = ReadPreferenceString("shipLastCompile", "")
      PreferenceGroup("projectMru")
      Ide_ProjMruCount = ReadPreferenceInteger("count", 0)
      If Ide_ProjMruCount > #Ide_ProjMruMax
        Ide_ProjMruCount = #Ide_ProjMruMax
      EndIf
      For i = 0 To #Ide_ProjMruMax - 1
        Ide_ProjMruPath(i) = ReadPreferenceString("p" + Str(i), "")
        Ide_ProjEntryPath(i) = ReadPreferenceString("e" + Str(i), "")
      Next
      ClosePreferences()
    EndIf
    Ide_I18n_Load()
    If Ide_UiLangPinned = #False
      If CreatePreferences(path)
        PreferenceGroup("editor")
        WritePreferenceInteger("uiLang", Ide_UiLang)
        ClosePreferences()
        Ide_UiLangPinned = #True
      EndIf
    EndIf
  EndProcedure

  ; <summary>
  ; Persist editor and window prefs to vyrnide.ini.
  ; </summary>
  Procedure Ide_Editor_SavePrefs()
    Protected path.s = Ide_Editor_PrefPath()
    Protected i.i
    If CreatePreferences(path)
      PreferenceGroup("editor")
      WritePreferenceInteger("dark", Ide_Theme_Dark)
      WritePreferenceInteger("zoom", Ide_Zoom)
      WritePreferenceInteger("outputH", Ide_OutputHeight)
      If IsWindow(#WIN_IDE)
        WritePreferenceInteger("winW", WindowWidth(#WIN_IDE))
        WritePreferenceInteger("winH", WindowHeight(#WIN_IDE))
        WritePreferenceInteger("winX", WindowX(#WIN_IDE))
        WritePreferenceInteger("winY", WindowY(#WIN_IDE))
      Else
        WritePreferenceInteger("winW", Ide_PrefWinW)
        WritePreferenceInteger("winH", Ide_PrefWinH)
        WritePreferenceInteger("winX", Ide_PrefWinX)
        WritePreferenceInteger("winY", Ide_PrefWinY)
      EndIf
      WritePreferenceString("fontName", Ide_FontName)
      WritePreferenceInteger("fontSize", Ide_FontSize)
      WritePreferenceInteger("tabWidth", Ide_TabWidth)
      WritePreferenceInteger("liveCheck", Ide_LiveCheckEnabled)
      WritePreferenceInteger("uiLang", Ide_UiLang)
      WritePreferenceInteger("replVisible", Ide_ReplVisible)
      WritePreferenceInteger("outline", Ide_OutlineVisible)
      WritePreferenceInteger("errorsPanel", Ide_ErrorsVisible)
      WritePreferenceInteger("errShowHints", Ide_ErrShowHints)
      WritePreferenceInteger("lintPanelOnly", Ide_LiveLintPanelOnly)
      WritePreferenceString("errCodeFilter", Ide_ErrCodeFilter)
      WritePreferenceInteger("autoSave", Ide_AutoSaveEnabled)
      WritePreferenceInteger("showWelcome", Ide_ShowWelcome)
      WritePreferenceInteger("firstRunDone", Ide_FirstRunDone)
      WritePreferenceInteger("findBar", Ide_FindBarPinned)
      WritePreferenceInteger("projectVyrnOnly", Ide_ProjectVyrnOnly)
      WritePreferenceInteger("mruCount", Ide_MruCount)
      For i = 0 To #Ide_MruMax - 1
        WritePreferenceString("mru" + Str(i), Ide_MruPath(i))
      Next
      PreferenceGroup("project")
      WritePreferenceString("root", Ide_ProjectRoot)
      WritePreferenceInteger("visible", Ide_ProjectVisible)
      WritePreferenceInteger("width", Ide_ProjectWidth)
      PreferenceGroup("run")
      WritePreferenceInteger("maxLoops", Ide_RunCfg_MaxLoops)
      WritePreferenceInteger("maxCalls", Ide_RunCfg_MaxCalls)
      WritePreferenceInteger("maxIns", Ide_RunCfg_MaxIns)
      WritePreferenceInteger("capNet", Ide_RunCfg_CapNet)
      WritePreferenceInteger("capProcess", Ide_RunCfg_CapProcess)
      WritePreferenceString("netAllow", Ide_RunCfg_NetAllow)
      WritePreferenceString("workDir", Ide_RunCfg_WorkDir)
      WritePreferenceString("scriptArgs", Ide_RunCfg_ScriptArgs)
      WritePreferenceInteger("strict", Ide_RunCfg_Strict)
      WritePreferenceInteger("bench", Ide_RunCfg_Bench)
      WritePreferenceInteger("unlimited", Ide_RunCfg_Unlimited)
      WritePreferenceInteger("jsonDiag", Ide_RunCfg_JsonDiag)
      WritePreferenceInteger("timeoutSecs", Ide_RunCfg_TimeoutSecs)
      WritePreferenceInteger("runViaVyrnc", Ide_RunCfg_RunViaVyrnc)
      WritePreferenceString("entryScript", Ide_ProjectEntry)
      WritePreferenceString("entryRoot", Ide_ProjectEntryRoot)
      WritePreferenceString("shipLastStandalone", Ide_ShipLastStandalone)
      WritePreferenceString("shipLastCompile", Ide_ShipLastCompile)
      PreferenceGroup("projectMru")
      WritePreferenceInteger("count", Ide_ProjMruCount)
      For i = 0 To #Ide_ProjMruMax - 1
        WritePreferenceString("p" + Str(i), Ide_ProjMruPath(i))
        WritePreferenceString("e" + Str(i), Ide_ProjEntryPath(i))
      Next
      ClosePreferences()
    EndIf
  EndProcedure

  ; <summary>
  ; Byte length of a null-terminated UTF-8 C string.
  ; </summary>
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
  ; Whether a path looks like a Vyrn/Lua script we should open in the editor.
  ; </summary>
  Procedure.i Ide_Editor_IsScriptPath(path.s)
    Protected ext.s = LCase(GetExtensionPart(path))
    ProcedureReturn Bool(ext = "vyrn" Or ext = "lua")
  EndProcedure

  ; <summary>
  ; IDE: Editor MruPush.
  ; </summary>
  ; <param name="paths">see signature</param>
  Procedure Ide_Editor_MruPush(path.s)
    Protected i.i, j.i, n.i
    If path = "" Or FileSize(path) < 0
      ProcedureReturn
    EndIf
    For i = 0 To Ide_MruCount - 1
      If LCase(Ide_MruPath(i)) = LCase(path)
        For j = i To Ide_MruCount - 2
          Ide_MruPath(j) = Ide_MruPath(j + 1)
        Next
        Ide_MruPath(Ide_MruCount - 1) = ""
        If Ide_MruCount > 0
          Ide_MruCount = Ide_MruCount - 1
        EndIf
        Break
      EndIf
    Next
    n = Ide_MruCount
    If n > #Ide_MruMax - 1
      n = #Ide_MruMax - 1
    EndIf
    For i = n To 1 Step -1
      Ide_MruPath(i) = Ide_MruPath(i - 1)
    Next
    Ide_MruPath(0) = path
    If Ide_MruCount < #Ide_MruMax
      Ide_MruCount = Ide_MruCount + 1
    EndIf
    Ide_Editor_RefreshMruMenu()
    Ide_Editor_SavePrefs()
  EndProcedure

  ; <summary>
  ; IDE: Editor MruClear.
  ; </summary>
  Procedure Ide_Editor_MruClear()
    Protected i.i
    Ide_MruCount = 0
    For i = 0 To #Ide_MruMax - 1
      Ide_MruPath(i) = ""
    Next
    Ide_Editor_RefreshMruMenu()
    Ide_Editor_SavePrefs()
  EndProcedure

  ; <summary>
  ; IDE: Editor RefreshMruMenu.
  ; </summary>
  Procedure Ide_Editor_RefreshMruMenu()
    Protected i.i, cap.s
    If IsMenu(#MENU_MAIN) = #False
      ProcedureReturn
    EndIf
    For i = 0 To #Ide_MruMax - 1
      If i < Ide_MruCount And Ide_MruPath(i) <> ""
        cap = GetFilePart(Ide_MruPath(i))
        SetMenuItemText(#MENU_MAIN, #MNU_MRU_0 + i, cap + Chr(9) + Ide_MruPath(i))
        DisableMenuItem(#MENU_MAIN, #MNU_MRU_0 + i, #False)
      Else
        SetMenuItemText(#MENU_MAIN, #MNU_MRU_0 + i, Ide_I18n_Pick("(empty)", "mnu.mru_empty"))
        DisableMenuItem(#MENU_MAIN, #MNU_MRU_0 + i, #True)
      EndIf
    Next
  EndProcedure

  ; <summary>
  ; IDE: Editor OpenMru.
  ; </summary>
  ; <param name="idxi">see signature</param>
  Procedure Ide_Editor_OpenMru(idx.i)
    If idx < 0 Or idx >= Ide_MruCount
      ProcedureReturn
    EndIf
    If Ide_Editor_LoadFile(Ide_MruPath(idx))
      Ide_Ui_SetStatus(Ide_I18n_Fmt1("Opened {path}", "status.opened", "{path}", Ide_MruPath(idx)))
    Else
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Failed to open:", "dlg.failed_open") + Chr(10) + Ide_MruPath(idx), #PB_MessageRequester_Error)
    EndIf
  EndProcedure

  ; <summary>
  ; IDE: Editor OpenPathIfScript.
  ; </summary>
  ; <param name="paths">see signature</param>
  Procedure Ide_Editor_OpenPathIfScript(path.s)
    If Ide_Editor_IsScriptPath(path) = #False
      ProcedureReturn
    EndIf
    If Ide_Editor_LoadFile(path)
      Ide_Ui_SetStatus(Ide_I18n_Fmt1("Opened {path}", "status.opened", "{path}", path))
    EndIf
  EndProcedure

  ; <summary>
  ; IDE: Editor GotoLinePrompt.
  ; </summary>
  Procedure Ide_Editor_GotoLinePrompt()
    Protected input.s, line.i, g.i
    input = InputRequester("Go to Line", "Line number (1-based):", "1")
    If input = ""
      ProcedureReturn
    EndIf
    line = Val(input)
    If line < 1
      ProcedureReturn
    EndIf
    g = Ide_Editor_CurrentGadget()
    If g = 0
      ProcedureReturn
    EndIf
    ScintillaSendMessage(g, #SCI_GOTOLINE, line - 1)
    ScintillaSendMessage(g, #SCI_SCROLLCARET)
    Ide_Editor_UpdateCaretStatus()
  EndProcedure

CompilerEndIf
