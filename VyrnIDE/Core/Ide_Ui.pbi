;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - window layout, gadget IDs, menus, output pane, status bar
; Menu title indices (#Ide_MnuTitle_*) must match MenuTitle() order in Ide_Ui_CreateMenus.
; PureBasic 6.41

CompilerIf Defined(Ide_Ui, #PB_Constant) = #False
  #Ide_Ui = #True

  Declare Ide_Editor_ResizeEditors()
  Declare Ide_Editor_SavePrefs()
  Declare Ide_Editor_UpdateCaretStatus()
  Declare Ide_Editor_RefreshMruMenu()
  Declare Ide_Ui_OutputInitUnicode()
  Declare Ide_Ui_ApplyListColumnLabels()
  Declare.i Ide_Project_ClientLeft()
  Declare Ide_Project_LayoutPanel(top.i, findH.i, left.i, editorH.i)
  Declare Ide_Project_MruRefreshMenu()
  Declare Ide_Editor_UpdateTitle()
  Declare Ide_Samples_InitMenu()
  Declare Ide_Samples_RefreshMenuLabels()
  Declare Ide_Extensions_InitMenu()
  Declare Ide_Extensions_RefreshMenuLabels()
  Declare Ide_Snippets_RefreshMenuLabels()
  Declare Ide_Ui_RefreshThemeMenuLabel()
  Declare Ide_Runner_SyncRuntime()
  Declare.i Ide_RuntimeHealth_NeedsSync()
  Declare Ide_Cmd_Dispatch(menuId.i)
  Declare Ide_Editor_RevealInExplorer(path.s)
  Declare Ide_Runner_IsBusy()
  Declare.s Ide_Runner_LastScriptPath()
  Declare Ide_Ui_OutputCopyAll()
  Declare Ide_Ui_ApplyPopupLabels()
  Declare Ide_Ui_MaybeSyncPrompt()
  Declare Ide_Ui_HandleStatusPopup(menuId.i)

  Global Ide_StatusBase.s = ""
  Global Ide_StatusShipDir.s = ""

  ; REPL bar lives above the output editor (#Ide_ReplBarH pixels when Ide_ReplVisible).
  #Ide_ReplBarH = 26
  Global Ide_ReplVisible.i = #True

  Enumeration
    #WIN_IDE = 0
  EndEnumeration

  Enumeration
    #GAD_TOOL_OPEN = 0
    #GAD_TOOL_SAVE
    #GAD_TOOL_RUN
    #GAD_TOOL_STOP
    #GAD_TOOL_SYNC
    #GAD_TOOL_RUN_ENTRY
    #GAD_TABS
    #GAD_FIND_STR
    #GAD_FIND_NEXT
    #GAD_REPLACE_STR
    #GAD_REPLACE
    #GAD_REPLACE_ALL
    #GAD_FIND_CASE
    #GAD_FIND_REGEX
    #GAD_FIND_INSEL
    #GAD_PROJECT
    #GAD_OUTLINE
    #GAD_ERRLIST
    #GAD_REPL_INPUT
    #GAD_REPL_RUN
    #GAD_OUTPUT
    #GAD_STATUS
    #GAD_SPLIT
  EndEnumeration

  #Ide_MarkError = 1
  #Ide_MarkWarn = 2
  #Ide_MarkErrorBack = 3
  #Ide_MarkWarnBack = 4
  #Ide_MarginSymbol = 1

  Enumeration
    #MENU_MAIN = 0
  EndEnumeration

  Enumeration 550
    #POP_PROJECT = 550
    #POP_PROJ_OPEN
    #POP_PROJ_RUN
    #POP_PROJ_SHIP
    #POP_PROJ_REVEAL
    #POP_PROJ_COPY
    #POP_PROJ_SET_ENTRY
  EndEnumeration

  Enumeration 560
    #POP_OUTPUT = 560
    #POP_OUT_COPY_ALL
    #POP_OUT_COPY_ERR
    #POP_OUT_REVEAL_SCRIPT
    #POP_OUT_OPEN_TEMP
  EndEnumeration

  Enumeration 565
    #POP_STATUS = 565
    #POP_STATUS_SHIP_OPEN
    #POP_STATUS_SHIP_COPY
    #POP_STATUS_SYNC
  EndEnumeration

  Enumeration 570
    #POP_ERRORS = 570
    #POP_ERR_COPY_LOC
    #POP_ERR_COPY_CODE
    #POP_ERR_SET_FILTER
    #POP_ERR_CLEAR_FILTER
  EndEnumeration

  Global Ide_SyncPromptDone.i = #False

  ; SetMenuTitleText(#MENU_MAIN, index, ...)  -  order matches MenuTitle() in Ide_Ui_CreateMenus.
  #Ide_MnuTitle_File = 0
  #Ide_MnuTitle_OpenRecent = 1
  #Ide_MnuTitle_RecentProjects = 2
  #Ide_MnuTitle_Edit = 3
  #Ide_MnuTitle_View = 4
  #Ide_MnuTitle_Run = 5
  #Ide_MnuTitle_Ship = 6
  #Ide_MnuTitle_Tools = 7
  #Ide_MnuTitle_Examples = 8
  #Ide_MnuTitle_Automation = 9
  #Ide_MnuTitle_Developer = 10
  #Ide_MnuTitle_Help = 11

  Enumeration
    #MNU_NEW = 0
    #MNU_OPEN
    #MNU_SAVE
    #MNU_SAVEAS
    #MNU_SAVE_ALL
    #MNU_REVERT
    #MNU_CLOSE
    #MNU_EXIT
    #MNU_UNDO
    #MNU_REDO
    #MNU_CUT
    #MNU_COPY
    #MNU_PASTE
    #MNU_FIND
    #MNU_FINDNEXT
    #MNU_REPLACE
    #MNU_ZOOMIN
    #MNU_ZOOMOUT
    #MNU_ZOOMRESET
    #MNU_THEME
    #MNU_RUN
    #MNU_STOP
    #MNU_SYNC_RUNTIME
    #MNU_SHIP_STANDALONE
    #MNU_SHIP_STANDALONE_EXE
    #MNU_SHIP_COMPILE
    #MNU_SHIP_COMPILE_EXE
    #MNU_COMPILE_VYRNC
    #MNU_RUN_VYRNC
    #MNU_GOTO_LIGHT
    #MNU_GOTOLINE
    #MNU_CHECK_SYNTAX
    #MNU_MRU_0
    #MNU_MRU_1
    #MNU_MRU_2
    #MNU_MRU_3
    #MNU_MRU_4
    #MNU_MRU_5
    #MNU_MRU_6
    #MNU_MRU_7
    #MNU_MRU_8
    #MNU_MRU_9
    #MNU_MRU_CLEAR
    #MNU_PROJECT_OPEN
    #MNU_PROJECT_PANEL
    #MNU_PROJ_MRU_0
    #MNU_PROJ_MRU_1
    #MNU_PROJ_MRU_2
    #MNU_PROJ_MRU_3
    #MNU_PROJ_MRU_4
    #MNU_REVEAL
    #MNU_OUTLINE_PANEL
    #MNU_ERRORS_PANEL
    #MNU_ERRORS_HINTS
    #MNU_ERRORS_FILTER_CODE
    #MNU_ERRORS_CLEAR_FILTER
    #MNU_TOGGLE_COMMENT
    #MNU_FIND_ALL_TABS
    #MNU_RUN_CONFIG
    #MNU_RUN_ENTRY
    #MNU_TAB_WIDTH_2
    #MNU_TAB_WIDTH_4
    #MNU_LIVE_CHECK
    #MNU_AUTOSAVE
    #MNU_OUTPUT_CLEAR
    #MNU_OUTPUT_COPY
    #MNU_OUTPUT_COPY_ERR
    #MNU_WELCOME
    #MNU_CUSTOM_0
    #MNU_CUSTOM_1
    #MNU_CUSTOM_2
    #MNU_CUSTOM_3
    #MNU_SNIPPET_FUNC
    #MNU_SNIPPET_IF
    #MNU_SNIPPET_MAIN
    #MNU_SNIPPET_VYRN12
    #MNU_SNIPPET_ENUM
    #MNU_SNIPPET_STRUCT
    #MNU_SNIPPET_MATCH_IF
    #MNU_REPL_PANEL
    #MNU_REPL_RUN
    #MNU_REPL_RESET
    #MNU_LANG_EN
    #MNU_LANG_ZH
    #MNU_EXT_REFRESH
    #MNU_EXT_0
    #MNU_EXT_1
    #MNU_EXT_2
    #MNU_EXT_3
    #MNU_EXT_4
    #MNU_EXT_5
    #MNU_EXT_6
    #MNU_EXT_7
    #MNU_SAMPLE_0
    #MNU_SAMPLE_1
    #MNU_SAMPLE_2
    #MNU_SAMPLE_3
    #MNU_SAMPLE_4
    #MNU_SAMPLE_5
    #MNU_SAMPLE_6
    #MNU_SAMPLE_7
    #MNU_SAMPLE_8
    #MNU_SAMPLE_9
    #MNU_SAMPLE_10
    #MNU_SAMPLE_11
    #MNU_SAMPLE_12
    #MNU_SAMPLE_13
    #MNU_SAMPLE_14
    #MNU_SAMPLE_15
    #MNU_SAMPLE_16
    #MNU_SAMPLE_17
    #MNU_SAMPLE_18
    #MNU_SAMPLE_19
    #MNU_SAMPLE_20
    #MNU_SAMPLE_21
    #MNU_SAMPLE_22
    #MNU_SAMPLE_23
    #MNU_FIND_PANEL
    #MNU_PROJECT_VYRN_ONLY
    #MNU_OPEN_SETTINGS
    #MNU_OPEN_EXT_FOLDER
    #MNU_OPEN_LAST_SHIP
    #MNU_COPY_SHIP_CMD
    #MNU_DUMP_BYTECODE
    #MNU_SHORTCUTS
    #MNU_OPEN_CONFIG_FOLDER
    #MNU_FORMAT_DOC
    #MNU_RUN_JSON_RECHECK
    #MNU_ABOUT
  EndEnumeration

  #Ide_OutColor_Auto = -1
  #Ide_OutColor_Default = 0
  #Ide_OutColor_Error = 1
  #Ide_OutColor_Warn = 2
  #Ide_OutColor_Ok = 3
  #Ide_OutColor_Info = 4
  #Ide_OutColor_Muted = 5

  CompilerIf Defined(EM_REPLACESEL, #PB_Constant) = #False
    #EM_REPLACESEL = 194
  CompilerEndIf
  CompilerIf Defined(EM_SETRECT, #PB_Constant) = #False
    #EM_SETRECT = 179
  CompilerEndIf
  CompilerIf Defined(WM_SIZE, #PB_Constant) = #False
    #WM_SIZE = 5
  CompilerEndIf
  Structure Ide_Rect
    left.l
    top.l
    right.l
    bottom.l
  EndStructure
  CompilerIf Defined(EM_SETCHARFORMAT, #PB_Constant) = #False
    #EM_SETCHARFORMAT = 1092
  CompilerEndIf
  CompilerIf Defined(CFM_COLOR, #PB_Constant) = #False
    #CFM_COLOR = $40000000
  CompilerEndIf
  CompilerIf Defined(SCF_SELECTION, #PB_Constant) = #False
    #SCF_SELECTION = 1
  CompilerEndIf
  CompilerIf Defined(CCM_SETUNICODEFORMAT, #PB_Constant) = #False
    #CCM_SETUNICODEFORMAT = 8197
  CompilerEndIf
  ; VK_OEM_2  -  '/' on US keyboards (Ctrl+/ toggle comment)
  CompilerIf Defined(PB_Shortcut_Slash, #PB_Constant) = #False
    #PB_Shortcut_Slash = 191
  CompilerEndIf
  CompilerIf Defined(PB_Shortcut_Return, #PB_Constant) = #False
    #PB_Shortcut_Return = 13
  CompilerEndIf

  Structure Ide_CharFormat
    cbSize.l
    dwMask.l
    dwEffects.l
    yHeight.l
    yOffset.l
    crTextColor.l
    bCharSet.b
    bPitchAndFamily.b
    szFaceName.c[32]
  EndStructure

  Global Ide_OutlineVisible.i = #False
  Global Ide_ErrorsVisible.i = #False
  Global Ide_ErrShowHints.i = #True
  Global Ide_LiveLintPanelOnly.i = #True
  Global Ide_ErrCodeFilter.s = ""
  Global Ide_SplitDragging.i = #False
  #Ide_ErrPanelH = 88
  #Ide_SideSplit = 120
  Global Ide_SplitDragAnchorY.i = 0
  Global Ide_PrefWinW.i = 960
  Global Ide_PrefWinH.i = 640
  Global Ide_PrefWinX.i = -1
  Global Ide_PrefWinY.i = -1
  Global Ide_LastLayoutW.i = 0
  Global Ide_LastLayoutH.i = 0

  #Ide_ToolbarH = 36
  #Ide_FindH = 30
  #Ide_StatusH = 24
  #Ide_StatusGap = 4
  ; Small pad above status (RichEdit occasional bleed); menu height is handled in Ide_Ui_ClientHeight().
  #Ide_OutputPad = 4
  #Ide_SplitH = 6
  #Ide_DefaultOutH = 160
  #Ide_MinEditorH = 120
  #Ide_MinOutH = 80

  Global Ide_OutputHeight.i = #Ide_DefaultOutH
  Global Ide_LayoutEditorH.i = 100
  Global Ide_LayoutOutH.i = #Ide_DefaultOutH
  Global Ide_FindVisible.i = #False
  Global Ide_FindBarPinned.i = #False
  Global Ide_ProjectVyrnOnly.i = #False
  Global Ide_Theme_Dark.i = #False
  Global Ide_EditorW.i = 100
  Global Ide_EditorH.i = 100

  ; <summary>
  ; Height of the REPL bar when Ide_ReplVisible is #True.
  ; </summary>
  Procedure.i Ide_Ui_ReplBarH()
    If Ide_ReplVisible
      ProcedureReturn #Ide_ReplBarH
    EndIf
    ProcedureReturn 0
  EndProcedure

  ; <summary>
  ; Refresh toolbar button captions for the active uiLang.
  ; </summary>
  Procedure Ide_Ui_ApplyToolbarLabels()
    If IsGadget(#GAD_TOOL_OPEN)
      SetGadgetText(#GAD_TOOL_OPEN, Ide_I18n_Pick("Open", "tool.open"))
      SetGadgetText(#GAD_TOOL_SAVE, Ide_I18n_Pick("Save", "tool.save"))
      SetGadgetText(#GAD_TOOL_RUN, Ide_I18n_Pick("Run", "tool.run"))
      SetGadgetText(#GAD_TOOL_STOP, Ide_I18n_Pick("Stop", "tool.stop"))
      SetGadgetText(#GAD_TOOL_SYNC, Ide_I18n_Pick("Sync", "tool.sync"))
      If IsGadget(#GAD_TOOL_RUN_ENTRY)
        SetGadgetText(#GAD_TOOL_RUN_ENTRY, Ide_I18n_Pick("Run entry", "tool.run_entry"))
      EndIf
    EndIf
    If IsGadget(#GAD_REPL_RUN)
      SetGadgetText(#GAD_REPL_RUN, Ide_I18n_Pick("Eval", "tool.eval"))
    EndIf
    If IsGadget(#GAD_FIND_NEXT)
      SetGadgetText(#GAD_FIND_NEXT, Ide_I18n_Pick("Find", "find.find"))
      SetGadgetText(#GAD_REPLACE, Ide_I18n_Pick("Replace", "find.replace"))
      SetGadgetText(#GAD_REPLACE_ALL, Ide_I18n_Pick("Replace All", "find.replace_all"))
      SetGadgetText(#GAD_FIND_CASE, Ide_I18n_Pick("Match case", "find.match_case"))
      SetGadgetText(#GAD_FIND_REGEX, Ide_I18n_Pick("Regex", "find.regex"))
      SetGadgetText(#GAD_FIND_INSEL, Ide_I18n_Pick("In sel", "find.in_sel"))
    EndIf
  EndProcedure

  ; <summary>
  ; IDE: Ui ApplyProjectPopupLabels.
  ; </summary>
  Procedure Ide_Ui_ApplyProjectPopupLabels()
    If IsMenu(#POP_PROJECT) = #False
      ProcedureReturn
    EndIf
    SetMenuItemText(#POP_PROJECT, #POP_PROJ_OPEN, Ide_I18n_Pick("Open", "pop.proj_open"))
    SetMenuItemText(#POP_PROJECT, #POP_PROJ_RUN, Ide_I18n_Pick("Run", "pop.proj_run"))
    SetMenuItemText(#POP_PROJECT, #POP_PROJ_SHIP, Ide_I18n_Pick("Ship (Standalone EXE)...", "pop.proj_ship"))
    SetMenuItemText(#POP_PROJECT, #POP_PROJ_REVEAL, Ide_I18n_Pick("Reveal in Explorer", "pop.proj_reveal"))
    SetMenuItemText(#POP_PROJECT, #POP_PROJ_COPY, Ide_I18n_Pick("Copy Path", "pop.proj_copy"))
  EndProcedure

  ; <summary>
  ; Re-apply main menu labels after uiLang or REPL visibility changes.
  ; </summary>
  Procedure Ide_Ui_ApplyMenuLabels()
    If IsMenu(#MENU_MAIN) = #False
      ProcedureReturn
    EndIf
    SetMenuTitleText(#MENU_MAIN, #Ide_MnuTitle_File, Ide_I18n_Pick("File", "mnu.title.file"))
    SetMenuTitleText(#MENU_MAIN, #Ide_MnuTitle_OpenRecent, Ide_I18n_Pick("Open Recent", "mnu.title.open_recent"))
    SetMenuTitleText(#MENU_MAIN, #Ide_MnuTitle_RecentProjects, Ide_I18n_Pick("Recent Projects", "mnu.title.recent_projects"))
    SetMenuTitleText(#MENU_MAIN, #Ide_MnuTitle_Edit, Ide_I18n_Pick("Edit", "mnu.title.edit"))
    SetMenuTitleText(#MENU_MAIN, #Ide_MnuTitle_View, Ide_I18n_Pick("View", "mnu.title.view"))
    SetMenuTitleText(#MENU_MAIN, #Ide_MnuTitle_Run, Ide_I18n_Pick("Run", "mnu.title.run"))
    SetMenuTitleText(#MENU_MAIN, #Ide_MnuTitle_Ship, Ide_I18n_Pick("Ship", "mnu.title.ship"))
    SetMenuTitleText(#MENU_MAIN, #Ide_MnuTitle_Tools, Ide_I18n_Pick("Tools", "mnu.title.tools"))
    SetMenuTitleText(#MENU_MAIN, #Ide_MnuTitle_Examples, Ide_I18n_Pick("Examples", "mnu.title.examples"))
    SetMenuTitleText(#MENU_MAIN, #Ide_MnuTitle_Automation, Ide_I18n_Pick("Automation", "mnu.title.automation"))
    SetMenuTitleText(#MENU_MAIN, #Ide_MnuTitle_Developer, Ide_I18n_Pick("Developer", "mnu.title.developer"))
    SetMenuTitleText(#MENU_MAIN, #Ide_MnuTitle_Help, Ide_I18n_Pick("Help", "mnu.title.help"))
    SetMenuItemText(#MENU_MAIN, #MNU_NEW, Ide_I18n_Pick("New" + Chr(9) + "Ctrl+N", "mnu.new"))
    SetMenuItemText(#MENU_MAIN, #MNU_OPEN, Ide_I18n_Pick("Open..." + Chr(9) + "Ctrl+O", "mnu.open"))
    SetMenuItemText(#MENU_MAIN, #MNU_SAVE, Ide_I18n_Pick("Save" + Chr(9) + "Ctrl+S", "mnu.save"))
    SetMenuItemText(#MENU_MAIN, #MNU_SAVEAS, Ide_I18n_Pick("Save As...", "mnu.save_as"))
    SetMenuItemText(#MENU_MAIN, #MNU_SAVE_ALL, Ide_I18n_Pick("Save All" + Chr(9) + "Ctrl+Shift+S", "mnu.save_all"))
    SetMenuItemText(#MENU_MAIN, #MNU_REVERT, Ide_I18n_Pick("Revert File", "mnu.revert"))
    SetMenuItemText(#MENU_MAIN, #MNU_REVEAL, Ide_I18n_Pick("Reveal in Explorer", "mnu.reveal"))
    SetMenuItemText(#MENU_MAIN, #MNU_CLOSE, Ide_I18n_Pick("Close Tab" + Chr(9) + "Ctrl+W", "mnu.close"))
    SetMenuItemText(#MENU_MAIN, #MNU_MRU_CLEAR, Ide_I18n_Pick("Clear Recent List", "mnu.mru_clear"))
    SetMenuItemText(#MENU_MAIN, #MNU_PROJECT_OPEN, Ide_I18n_Pick("Open Project Folder...", "mnu.project_open"))
    SetMenuItemText(#MENU_MAIN, #MNU_EXIT, Ide_I18n_Pick("Exit", "mnu.exit"))
    SetMenuItemText(#MENU_MAIN, #MNU_UNDO, Ide_I18n_Pick("Undo" + Chr(9) + "Ctrl+Z", "mnu.undo"))
    SetMenuItemText(#MENU_MAIN, #MNU_REDO, Ide_I18n_Pick("Redo" + Chr(9) + "Ctrl+Y", "mnu.redo"))
    SetMenuItemText(#MENU_MAIN, #MNU_CUT, Ide_I18n_Pick("Cut" + Chr(9) + "Ctrl+X", "mnu.cut"))
    SetMenuItemText(#MENU_MAIN, #MNU_COPY, Ide_I18n_Pick("Copy" + Chr(9) + "Ctrl+C", "mnu.copy"))
    SetMenuItemText(#MENU_MAIN, #MNU_PASTE, Ide_I18n_Pick("Paste" + Chr(9) + "Ctrl+V", "mnu.paste"))
    SetMenuItemText(#MENU_MAIN, #MNU_FIND, Ide_I18n_Pick("Find..." + Chr(9) + "Ctrl+F", "mnu.find"))
    SetMenuItemText(#MENU_MAIN, #MNU_FINDNEXT, Ide_I18n_Pick("Find Next" + Chr(9) + "F3", "mnu.find_next"))
    SetMenuItemText(#MENU_MAIN, #MNU_REPLACE, Ide_I18n_Pick("Replace..." + Chr(9) + "Ctrl+H", "mnu.replace"))
    SetMenuItemText(#MENU_MAIN, #MNU_FIND_ALL_TABS, Ide_I18n_Pick("Find in All Tabs", "mnu.find_all_tabs"))
    SetMenuItemText(#MENU_MAIN, #MNU_TOGGLE_COMMENT, Ide_I18n_Pick("Toggle Comment" + Chr(9) + "Ctrl+/", "mnu.toggle_comment"))
    SetMenuItemText(#MENU_MAIN, #MNU_GOTOLINE, Ide_I18n_Pick("Go to Line..." + Chr(9) + "Ctrl+G", "mnu.goto_line"))
    SetMenuItemText(#MENU_MAIN, #MNU_FORMAT_DOC, Ide_I18n_Pick("Format Document" + Chr(9) + "Ctrl+Shift+I", "mnu.format_doc"))
    SetMenuItemText(#MENU_MAIN, #MNU_ZOOMIN, Ide_I18n_Pick("Zoom In" + Chr(9) + "Ctrl++", "mnu.zoom_in"))
    SetMenuItemText(#MENU_MAIN, #MNU_ZOOMOUT, Ide_I18n_Pick("Zoom Out" + Chr(9) + "Ctrl+-", "mnu.zoom_out"))
    SetMenuItemText(#MENU_MAIN, #MNU_ZOOMRESET, Ide_I18n_Pick("Reset Zoom" + Chr(9) + "Ctrl+0", "mnu.zoom_reset"))
    Ide_Ui_RefreshThemeMenuLabel()
    SetMenuItemText(#MENU_MAIN, #MNU_FIND_PANEL, Ide_I18n_Pick("Find Bar", "mnu.find_panel"))
    SetMenuItemText(#MENU_MAIN, #MNU_PROJECT_VYRN_ONLY, Ide_I18n_Pick("Project: .vyrn only", "mnu.project_vyrn_only"))
    SetMenuItemText(#MENU_MAIN, #MNU_PROJECT_PANEL, Ide_I18n_Pick("Project Panel", "mnu.project_panel"))
    SetMenuItemText(#MENU_MAIN, #MNU_OUTLINE_PANEL, Ide_I18n_Pick("Symbol Outline", "mnu.outline_panel"))
    SetMenuItemText(#MENU_MAIN, #MNU_ERRORS_PANEL, Ide_I18n_Pick("Error List", "mnu.errors_panel"))
    SetMenuItemText(#MENU_MAIN, #MNU_ERRORS_HINTS, Ide_I18n_Pick("Show lint hints in error list", "mnu.err_hints"))
    SetMenuItemText(#MENU_MAIN, #MNU_GOTO_LIGHT, Ide_I18n_Pick("Go to definition (light)" + Chr(9) + "Ctrl+F12", "mnu.goto_light"))
    SetMenuItemText(#MENU_MAIN, #MNU_ERRORS_FILTER_CODE, Ide_I18n_Pick("Filter errors by code...", "mnu.err_filter_code"))
    SetMenuItemText(#MENU_MAIN, #MNU_ERRORS_CLEAR_FILTER, Ide_I18n_Pick("Clear error code filter", "mnu.err_filter_clear"))
    SetMenuItemText(#MENU_MAIN, #MNU_TAB_WIDTH_2, Ide_I18n_Pick("Tab Width 2", "mnu.tab_w2"))
    SetMenuItemText(#MENU_MAIN, #MNU_TAB_WIDTH_4, Ide_I18n_Pick("Tab Width 4", "mnu.tab_w4"))
    SetMenuItemText(#MENU_MAIN, #MNU_RUN, Ide_I18n_Pick("Run Current" + Chr(9) + "F5", "mnu.run"))
    SetMenuItemText(#MENU_MAIN, #MNU_STOP, Ide_I18n_Pick("Stop" + Chr(9) + "Shift+F5", "mnu.stop"))
    SetMenuItemText(#MENU_MAIN, #MNU_COMPILE_VYRNC, Ide_I18n_Pick("Compile to .vyrnc" + Chr(9) + "F7", "mnu.compile_vyrnc"))
    SetMenuItemText(#MENU_MAIN, #MNU_RUN_VYRNC, Ide_I18n_Pick("Compile & Run .vyrnc" + Chr(9) + "Ctrl+F5", "mnu.run_vyrnc"))
    SetMenuItemText(#MENU_MAIN, #MNU_CHECK_SYNTAX, Ide_I18n_Pick("Check Syntax" + Chr(9) + "F8", "mnu.check_syntax"))
    SetMenuItemText(#MENU_MAIN, #MNU_RUN_JSON_RECHECK, Ide_I18n_Pick("Refresh error list (JSON)...", "mnu.run_json_recheck"))
    SetMenuItemText(#MENU_MAIN, #MNU_RUN_CONFIG, Ide_I18n_Pick("Run Configuration...", "mnu.run_config"))
    SetMenuItemText(#MENU_MAIN, #MNU_RUN_ENTRY, Ide_I18n_Pick("Run Entry Script", "mnu.run_entry"))
    Ide_Ui_ApplyPopupLabels()
    SetMenuItemText(#MENU_MAIN, #MNU_SHIP_STANDALONE, Ide_I18n_Pick("Standalone Folder...", "mnu.ship_standalone"))
    SetMenuItemText(#MENU_MAIN, #MNU_SHIP_STANDALONE_EXE, Ide_I18n_Pick("Build Windows EXE (Standalone)...", "mnu.ship_standalone_exe"))
    SetMenuItemText(#MENU_MAIN, #MNU_SHIP_COMPILE, Ide_I18n_Pick("Compile Folder...", "mnu.ship_compile"))
    SetMenuItemText(#MENU_MAIN, #MNU_SHIP_COMPILE_EXE, Ide_I18n_Pick("Compile + Build EXE...", "mnu.ship_compile_exe"))
    SetMenuItemText(#MENU_MAIN, #MNU_LIVE_CHECK, Ide_I18n_Pick("Live Syntax Check", "mnu.live_check"))
    SetMenuItemText(#MENU_MAIN, #MNU_AUTOSAVE, Ide_I18n_Pick("Auto-save (30s)", "mnu.autosave"))
    SetMenuItemText(#MENU_MAIN, #MNU_OUTPUT_CLEAR, Ide_I18n_Pick("Clear Output", "mnu.output_clear"))
    SetMenuItemText(#MENU_MAIN, #MNU_OUTPUT_COPY, Ide_I18n_Pick("Copy All Output", "mnu.output_copy"))
    SetMenuItemText(#MENU_MAIN, #MNU_OUTPUT_COPY_ERR, Ide_I18n_Pick("Copy Last Run Error", "mnu.output_copy_err"))
    SetMenuItemText(#MENU_MAIN, #MNU_SYNC_RUNTIME, Ide_I18n_Pick("Sync Runtime DLL" + Chr(9) + "Ctrl+Shift+R", "mnu.sync"))
    SetMenuItemText(#MENU_MAIN, #MNU_REPL_PANEL, Ide_I18n_Pick("REPL Input Bar", "mnu.repl_panel"))
    SetMenuItemText(#MENU_MAIN, #MNU_REPL_RUN, Ide_I18n_Pick("Eval REPL Line" + Chr(9) + "Ctrl+Enter", "mnu.repl_run"))
    SetMenuItemText(#MENU_MAIN, #MNU_REPL_RESET, Ide_I18n_Pick("Reset VM State", "mnu.repl_reset"))
    SetMenuItemText(#MENU_MAIN, #MNU_LANG_EN, Ide_I18n_Pick("English UI", "mnu.lang_en"))
    SetMenuItemText(#MENU_MAIN, #MNU_LANG_ZH, Ide_I18n_Pick("Traditional Chinese UI", "mnu.lang_zh"))
    SetMenuItemText(#MENU_MAIN, #MNU_EXT_REFRESH, Ide_I18n_Pick("Refresh Extension List", "mnu.ext_refresh"))
    SetMenuItemText(#MENU_MAIN, #MNU_OPEN_SETTINGS, Ide_I18n_Pick("Open vyrnide.ini", "mnu.open_settings"))
    SetMenuItemText(#MENU_MAIN, #MNU_OPEN_CONFIG_FOLDER, Ide_I18n_Pick("Open IDE config folder", "mnu.open_config_dir"))
    SetMenuItemText(#MENU_MAIN, #MNU_OPEN_EXT_FOLDER, Ide_I18n_Pick("Open extensions folder", "mnu.open_ext"))
    SetMenuItemText(#MENU_MAIN, #MNU_OPEN_LAST_SHIP, Ide_I18n_Pick("Open last ship output", "mnu.open_ship_out"))
    SetMenuItemText(#MENU_MAIN, #MNU_COPY_SHIP_CMD, Ide_I18n_Pick("Copy last ship command", "mnu.copy_ship_cmd"))
    SetMenuItemText(#MENU_MAIN, #MNU_DUMP_BYTECODE, Ide_I18n_Pick("Dump bytecode (CLI --dump)", "dev.dump_menu"))
    SetMenuItemText(#MENU_MAIN, #MNU_SHORTCUTS, Ide_I18n_Pick("Keyboard Shortcuts", "mnu.shortcuts"))
    SetMenuItemText(#MENU_MAIN, #MNU_WELCOME, Ide_I18n_Pick("Show Welcome Hints", "mnu.welcome"))
    SetMenuItemText(#MENU_MAIN, #MNU_ABOUT, Ide_I18n_Pick("About Vyrn IDE", "mnu.about"))
    SetMenuItemState(#MENU_MAIN, #MNU_LANG_EN, Bool(Ide_UiLang = #Ide_Lang_En))
    SetMenuItemState(#MENU_MAIN, #MNU_LANG_ZH, Bool(Ide_UiLang = #Ide_Lang_Zh))
    SetMenuItemState(#MENU_MAIN, #MNU_REPL_PANEL, Ide_ReplVisible)
    SetMenuItemState(#MENU_MAIN, #MNU_FIND_PANEL, Ide_FindVisible)
    SetMenuItemState(#MENU_MAIN, #MNU_PROJECT_VYRN_ONLY, Ide_ProjectVyrnOnly)
    SetMenuItemState(#MENU_MAIN, #MNU_ERRORS_HINTS, Ide_ErrShowHints)
    Ide_Samples_RefreshMenuLabels()
    Ide_Extensions_RefreshMenuLabels()
    Ide_Snippets_RefreshMenuLabels()
    Ide_Ui_ApplyProjectPopupLabels()
    Ide_Ui_ApplyListColumnLabels()
    Ide_Editor_RefreshMruMenu()
    Ide_Project_MruRefreshMenu()
  EndProcedure

  ; ListIcon column titles are fixed at gadget creation (PB has no runtime header API).
  ; <summary>
  ; ListIcon column titles are fixed at gadget creation (PB has no runtime header API).
  ; </summary>
  Procedure Ide_Ui_ApplyListColumnLabels()
  EndProcedure

  ; <summary>
  ; Set UI language, refresh chrome, and persist prefs.
  ; </summary>
  Procedure Ide_Ui_SetLanguage(lang.i)
    If lang = #Ide_Lang_Zh
      Ide_UiLang = #Ide_Lang_Zh
    Else
      Ide_UiLang = #Ide_Lang_En
    EndIf
    Ide_UiLangPinned = #True
    Ide_Ui_ApplyMenuLabels()
    Ide_Ui_ApplyToolbarLabels()
    Ide_Editor_UpdateTitle()
    Ide_Editor_SavePrefs()
  EndProcedure

  ; <summary>
  ; Build the main menu bar (File / Edit / View / Run / Ship / Tools / Help) and accelerator labels.
  ; </summary>
  Procedure Ide_Ui_CreateMenus()
    CreateMenu(#MENU_MAIN, WindowID(#WIN_IDE))
    MenuTitle("File")
    MenuItem(#MNU_NEW, "New" + Chr(9) + "Ctrl+N")
    MenuItem(#MNU_OPEN, "Open..." + Chr(9) + "Ctrl+O")
    MenuItem(#MNU_SAVE, "Save" + Chr(9) + "Ctrl+S")
    MenuItem(#MNU_SAVEAS, "Save As...")
    MenuItem(#MNU_SAVE_ALL, "Save All" + Chr(9) + "Ctrl+Shift+S")
    MenuItem(#MNU_REVERT, "Revert File")
    MenuBar()
    MenuItem(#MNU_REVEAL, "Reveal in Explorer")
    MenuItem(#MNU_CLOSE, "Close Tab" + Chr(9) + "Ctrl+W")
    MenuBar()
    MenuTitle("Open Recent")
    MenuItem(#MNU_MRU_0, "(none)")
    MenuItem(#MNU_MRU_1, "")
    MenuItem(#MNU_MRU_2, "")
    MenuItem(#MNU_MRU_3, "")
    MenuItem(#MNU_MRU_4, "")
    MenuItem(#MNU_MRU_5, "")
    MenuItem(#MNU_MRU_6, "")
    MenuItem(#MNU_MRU_7, "")
    MenuItem(#MNU_MRU_8, "")
    MenuItem(#MNU_MRU_9, "")
    MenuBar()
    MenuItem(#MNU_MRU_CLEAR, "Clear Recent List")
    MenuBar()
    MenuItem(#MNU_PROJECT_OPEN, "Open Project Folder...")
    MenuBar()
    MenuTitle("Recent Projects")
    MenuItem(#MNU_PROJ_MRU_0, "(none)")
    MenuItem(#MNU_PROJ_MRU_1, "")
    MenuItem(#MNU_PROJ_MRU_2, "")
    MenuItem(#MNU_PROJ_MRU_3, "")
    MenuItem(#MNU_PROJ_MRU_4, "")
    MenuBar()
    MenuItem(#MNU_EXIT, "Exit")
    MenuTitle("Edit")
    MenuItem(#MNU_UNDO, "Undo" + Chr(9) + "Ctrl+Z")
    MenuItem(#MNU_REDO, "Redo" + Chr(9) + "Ctrl+Y")
    MenuBar()
    MenuItem(#MNU_CUT, "Cut" + Chr(9) + "Ctrl+X")
    MenuItem(#MNU_COPY, "Copy" + Chr(9) + "Ctrl+C")
    MenuItem(#MNU_PASTE, "Paste" + Chr(9) + "Ctrl+V")
    MenuBar()
    MenuItem(#MNU_FIND, "Find..." + Chr(9) + "Ctrl+F")
    MenuItem(#MNU_FINDNEXT, "Find Next" + Chr(9) + "F3")
    MenuItem(#MNU_REPLACE, "Replace..." + Chr(9) + "Ctrl+H")
    MenuBar()
    MenuItem(#MNU_FIND_ALL_TABS, "Find in All Tabs")
    MenuBar()
    MenuItem(#MNU_TOGGLE_COMMENT, "Toggle Comment" + Chr(9) + "Ctrl+/")
    MenuBar()
    MenuItem(#MNU_GOTO_LIGHT, "Go to definition (light)" + Chr(9) + "Ctrl+F12")
    MenuItem(#MNU_GOTOLINE, "Go to Line..." + Chr(9) + "Ctrl+G")
    MenuBar()
    MenuItem(#MNU_FORMAT_DOC, "Format Document" + Chr(9) + "Ctrl+Shift+I")
    MenuBar()
    MenuItem(#MNU_SNIPPET_FUNC, "Insert Function...")
    MenuItem(#MNU_SNIPPET_IF, "Insert If / Else")
    MenuItem(#MNU_SNIPPET_MAIN, "Insert Main + print")
    MenuBar()
    MenuItem(#MNU_SNIPPET_VYRN12, "Insert vyrn: 12 header")
    MenuItem(#MNU_SNIPPET_ENUM, "Insert enum block")
    MenuItem(#MNU_SNIPPET_STRUCT, "Insert struct block")
    MenuItem(#MNU_SNIPPET_MATCH_IF, "Insert status if/elif (not match)")
    MenuTitle("View")
    MenuItem(#MNU_FIND_PANEL, "Find Bar")
    MenuBar()
    MenuItem(#MNU_ZOOMIN, "Zoom In" + Chr(9) + "Ctrl++")
    MenuItem(#MNU_ZOOMOUT, "Zoom Out" + Chr(9) + "Ctrl+-")
    MenuItem(#MNU_ZOOMRESET, "Reset Zoom" + Chr(9) + "Ctrl+0")
    MenuBar()
    MenuItem(#MNU_THEME, "Dark Theme")
    MenuBar()
    MenuItem(#MNU_PROJECT_PANEL, "Project Panel")
    MenuItem(#MNU_PROJECT_VYRN_ONLY, "Project: .vyrn only")
    MenuItem(#MNU_OUTLINE_PANEL, "Symbol Outline")
    MenuItem(#MNU_ERRORS_PANEL, "Error List")
    MenuItem(#MNU_ERRORS_HINTS, "Show lint hints in error list")
    MenuBar()
    MenuItem(#MNU_ERRORS_FILTER_CODE, "Filter errors by code...")
    MenuItem(#MNU_ERRORS_CLEAR_FILTER, "Clear error code filter")
    MenuBar()
    MenuItem(#MNU_TAB_WIDTH_2, "Tab Width 2")
    MenuItem(#MNU_TAB_WIDTH_4, "Tab Width 4")
    MenuTitle("Run")
    MenuItem(#MNU_RUN, "Run Current" + Chr(9) + "F5")
    MenuItem(#MNU_STOP, "Stop" + Chr(9) + "Shift+F5")
    MenuBar()
    MenuItem(#MNU_COMPILE_VYRNC, "Compile to .vyrnc" + Chr(9) + "F7")
    MenuItem(#MNU_RUN_VYRNC, "Compile && Run .vyrnc" + Chr(9) + "Ctrl+F5")
    MenuBar()
    MenuItem(#MNU_CHECK_SYNTAX, "Check Syntax" + Chr(9) + "F8")
    MenuBar()
    MenuItem(#MNU_RUN_JSON_RECHECK, "Refresh error list (JSON)...")
    MenuBar()
    MenuItem(#MNU_RUN_CONFIG, "Run Configuration...")
    MenuItem(#MNU_RUN_ENTRY, "Run Entry Script")
    MenuTitle("Ship")
    MenuItem(#MNU_SHIP_STANDALONE, "Standalone Folder...")
    MenuItem(#MNU_SHIP_STANDALONE_EXE, "Build Windows EXE (Standalone)...")
    MenuBar()
    MenuItem(#MNU_SHIP_COMPILE, "Compile Folder...")
    MenuItem(#MNU_SHIP_COMPILE_EXE, "Compile + Build EXE...")
    MenuTitle("Tools")
    MenuItem(#MNU_LIVE_CHECK, "Live Syntax Check")
    MenuItem(#MNU_AUTOSAVE, "Auto-save (30s)")
    MenuBar()
    MenuItem(#MNU_OUTPUT_CLEAR, "Clear Output")
    MenuItem(#MNU_OUTPUT_COPY, "Copy All Output")
    MenuItem(#MNU_OUTPUT_COPY_ERR, "Copy Last Run Error")
    MenuBar()
    MenuItem(#MNU_REPL_PANEL, "REPL Input Bar")
    MenuItem(#MNU_REPL_RUN, "Eval REPL Line" + Chr(9) + "Ctrl+Enter")
    MenuItem(#MNU_REPL_RESET, "Reset VM State")
    MenuBar()
    MenuItem(#MNU_LANG_EN, "English UI")
    MenuItem(#MNU_LANG_ZH, "Traditional Chinese UI")
    MenuBar()
    MenuTitle("Examples")
    MenuItem(#MNU_SAMPLE_0, "(loading)")
    MenuItem(#MNU_SAMPLE_1, "")
    MenuItem(#MNU_SAMPLE_2, "")
    MenuItem(#MNU_SAMPLE_3, "")
    MenuItem(#MNU_SAMPLE_4, "")
    MenuItem(#MNU_SAMPLE_5, "")
    MenuItem(#MNU_SAMPLE_6, "")
    MenuItem(#MNU_SAMPLE_7, "")
    MenuItem(#MNU_SAMPLE_8, "")
    MenuItem(#MNU_SAMPLE_9, "")
    MenuItem(#MNU_SAMPLE_10, "")
    MenuItem(#MNU_SAMPLE_11, "")
    MenuItem(#MNU_SAMPLE_12, "")
    MenuItem(#MNU_SAMPLE_13, "")
    MenuItem(#MNU_SAMPLE_14, "")
    MenuItem(#MNU_SAMPLE_15, "")
    MenuItem(#MNU_SAMPLE_16, "")
    MenuItem(#MNU_SAMPLE_17, "")
    MenuItem(#MNU_SAMPLE_18, "")
    MenuItem(#MNU_SAMPLE_19, "")
    MenuItem(#MNU_SAMPLE_20, "")
    MenuItem(#MNU_SAMPLE_21, "")
    MenuItem(#MNU_SAMPLE_22, "")
    MenuItem(#MNU_SAMPLE_23, "")
    MenuTitle("Automation")
    MenuItem(#MNU_CUSTOM_0, "(none)")
    MenuItem(#MNU_CUSTOM_1, "")
    MenuItem(#MNU_CUSTOM_2, "")
    MenuItem(#MNU_CUSTOM_3, "")
    MenuBar()
    MenuItem(#MNU_EXT_REFRESH, "Refresh Extension List")
    MenuItem(#MNU_EXT_0, "(none)")
    MenuItem(#MNU_EXT_1, "")
    MenuItem(#MNU_EXT_2, "")
    MenuItem(#MNU_EXT_3, "")
    MenuItem(#MNU_EXT_4, "")
    MenuItem(#MNU_EXT_5, "")
    MenuItem(#MNU_EXT_6, "")
    MenuItem(#MNU_EXT_7, "")
    MenuTitle("Developer")
    MenuItem(#MNU_SYNC_RUNTIME, "Sync Runtime DLL" + Chr(9) + "Ctrl+Shift+R")
    MenuItem(#MNU_OPEN_SETTINGS, "Open vyrnide.ini")
    MenuItem(#MNU_OPEN_CONFIG_FOLDER, "Open IDE config folder")
    MenuItem(#MNU_OPEN_EXT_FOLDER, "Open extensions folder")
    MenuItem(#MNU_OPEN_LAST_SHIP, "Open last ship output")
    MenuItem(#MNU_COPY_SHIP_CMD, "Copy last ship command")
    MenuItem(#MNU_DUMP_BYTECODE, "Dump bytecode (CLI --dump)")
    MenuTitle("Help")
    MenuItem(#MNU_SHORTCUTS, "Keyboard Shortcuts")
    MenuItem(#MNU_WELCOME, "Show Welcome Hints")
    MenuBar()
    MenuItem(#MNU_ABOUT, "About Vyrn IDE")
  EndProcedure

  ; <summary>
  ; Project List right-click menu (separate from #MENU_MAIN).
  ; </summary>
  Procedure Ide_Ui_CreateErrorsPopup()
    If CreatePopupMenu(#POP_ERRORS) = 0
      ProcedureReturn
    EndIf
    MenuItem(#POP_ERR_COPY_LOC, "Copy location (path:line:col)")
    MenuItem(#POP_ERR_COPY_CODE, "Copy diagnostic code")
    MenuBar()
    MenuItem(#POP_ERR_SET_FILTER, "Filter list by this code...")
    MenuItem(#POP_ERR_CLEAR_FILTER, "Clear code filter")
    Ide_Ui_ApplyPopupLabels()
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_ErrorsPopupShow
  ; </summary>
  Procedure Ide_Ui_ErrorsPopupShow()
    If IsMenu(#POP_ERRORS) = #False
      ProcedureReturn
    EndIf
    DisplayPopupMenu(#POP_ERRORS, GadgetID(#GAD_ERRLIST))
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_CreateOutputPopup
  ; </summary>
  Procedure Ide_Ui_CreateOutputPopup()
    If CreatePopupMenu(#POP_OUTPUT) = 0
      ProcedureReturn
    EndIf
    MenuItem(#POP_OUT_COPY_ALL, "Copy all output")
    MenuBar()
    MenuItem(#POP_OUT_COPY_ERR, "Copy last run error")
    MenuItem(#POP_OUT_REVEAL_SCRIPT, "Reveal last run script")
    MenuItem(#POP_OUT_OPEN_TEMP, "Open temp run folder")
    Ide_Ui_ApplyPopupLabels()
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_CreateStatusPopup
  ; </summary>
  Procedure Ide_Ui_CreateStatusPopup()
    If CreatePopupMenu(#POP_STATUS) = 0
      ProcedureReturn
    EndIf
    MenuItem(#POP_STATUS_SHIP_OPEN, "Open ship output")
    MenuItem(#POP_STATUS_SHIP_COPY, "Copy ship path")
    MenuBar()
    MenuItem(#POP_STATUS_SYNC, "Sync runtime DLL")
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_ApplyPopupLabels
  ; </summary>
  Procedure Ide_Ui_ApplyPopupLabels()
    If IsMenu(#POP_OUTPUT)
      SetMenuItemText(#POP_OUTPUT, #POP_OUT_COPY_ALL, Ide_I18n_Pick("Copy all output", "pop.out_copy_all"))
      SetMenuItemText(#POP_OUTPUT, #POP_OUT_COPY_ERR, Ide_I18n_Pick("Copy last run error", "pop.out_copy_err"))
      SetMenuItemText(#POP_OUTPUT, #POP_OUT_REVEAL_SCRIPT, Ide_I18n_Pick("Reveal last run script", "pop.out_reveal"))
      SetMenuItemText(#POP_OUTPUT, #POP_OUT_OPEN_TEMP, Ide_I18n_Pick("Open temp run folder", "pop.out_temp"))
    EndIf
    If IsMenu(#POP_PROJECT)
      SetMenuItemText(#POP_PROJECT, #POP_PROJ_OPEN, Ide_I18n_Pick("Open", "pop.proj_open"))
      SetMenuItemText(#POP_PROJECT, #POP_PROJ_RUN, Ide_I18n_Pick("Run", "pop.proj_run"))
      SetMenuItemText(#POP_PROJECT, #POP_PROJ_SET_ENTRY, Ide_I18n_Pick("Set as entry script", "pop.proj_entry"))
      SetMenuItemText(#POP_PROJECT, #POP_PROJ_SHIP, Ide_I18n_Pick("Ship (Standalone EXE)...", "pop.proj_ship"))
      SetMenuItemText(#POP_PROJECT, #POP_PROJ_REVEAL, Ide_I18n_Pick("Reveal in Explorer", "pop.proj_reveal"))
      SetMenuItemText(#POP_PROJECT, #POP_PROJ_COPY, Ide_I18n_Pick("Copy Path", "pop.proj_copy"))
    EndIf
    If IsMenu(#POP_STATUS)
      SetMenuItemText(#POP_STATUS, #POP_STATUS_SHIP_OPEN, Ide_I18n_Pick("Open ship output", "pop.ship_open"))
      SetMenuItemText(#POP_STATUS, #POP_STATUS_SHIP_COPY, Ide_I18n_Pick("Copy ship path", "pop.ship_copy"))
      SetMenuItemText(#POP_STATUS, #POP_STATUS_SYNC, Ide_I18n_Pick("Sync runtime DLL", "pop.sync"))
    EndIf
    If IsMenu(#POP_ERRORS)
      SetMenuItemText(#POP_ERRORS, #POP_ERR_COPY_LOC, Ide_I18n_Pick("Copy location (path:line:col)", "pop.err_copy_loc"))
      SetMenuItemText(#POP_ERRORS, #POP_ERR_COPY_CODE, Ide_I18n_Pick("Copy diagnostic code", "pop.err_copy_code"))
      SetMenuItemText(#POP_ERRORS, #POP_ERR_SET_FILTER, Ide_I18n_Pick("Filter list by this code...", "pop.err_set_filter"))
      SetMenuItemText(#POP_ERRORS, #POP_ERR_CLEAR_FILTER, Ide_I18n_Pick("Clear code filter", "pop.err_clear_filter"))
    EndIf
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_MaybeSyncPrompt
  ; </summary>
  Procedure Ide_Ui_MaybeSyncPrompt()
    If Ide_SyncPromptDone Or Vyrn_IsReady() = 0
      ProcedureReturn
    EndIf
    If Ide_RuntimeHealth_NeedsSync() = #False
      ProcedureReturn
    EndIf
    Ide_SyncPromptDone = #True
    If MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Vyrn.dll beside the IDE differs from native\\Vyrn.dll. Sync now?", "dlg.sync_prompt"), #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
      Ide_Runner_SyncRuntime()
    EndIf
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_CreateProjectPopup
  ; </summary>
  Procedure Ide_Ui_CreateProjectPopup()
    If CreatePopupMenu(#POP_PROJECT) = 0
      ProcedureReturn
    EndIf
    MenuItem(#POP_PROJ_OPEN, "Open")
    MenuItem(#POP_PROJ_RUN, "Run")
    MenuItem(#POP_PROJ_SET_ENTRY, "Set as entry script")
    MenuItem(#POP_PROJ_SHIP, "Ship (Standalone EXE)...")
    MenuBar()
    MenuItem(#POP_PROJ_REVEAL, "Reveal in Explorer")
    MenuItem(#POP_PROJ_COPY, "Copy Path")
  EndProcedure

  ; <summary>
  ; Height reserved for the find/replace bar when it is visible.
  ; </summary>
  ; <returns>#Ide_FindH when visible; otherwise 0.</returns>
  Procedure.i Ide_Ui_FindBarH()
    If Ide_FindVisible
      ProcedureReturn #Ide_FindH
    EndIf
    ProcedureReturn 0
  EndProcedure

  ; <summary>
  ; Drawable client height below the menu bar (PB WindowHeight includes menu area on Windows).
  ; </summary>
  Procedure.i Ide_Ui_ClientHeight()
    Protected h.i
    If IsWindow(#WIN_IDE) = 0
      ProcedureReturn 0
    EndIf
    h = WindowHeight(#WIN_IDE) - MenuHeight()
    If h < 80
      h = 80
    EndIf
    ProcedureReturn h
  EndProcedure

  ; <summary>
  ; Keep status TextGadget above the output RichEdit (Windows z-order bleed).
  ; </summary>
  Procedure Ide_Ui_EnsureStatusOnTop()
    Protected u32.i, fnPos.i, fnInv.i, hs.i
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      If IsGadget(#GAD_STATUS) = #False
        ProcedureReturn
      EndIf
      hs = GadgetID(#GAD_STATUS)
      If hs = 0
        ProcedureReturn
      EndIf
      u32 = OpenLibrary(#PB_Any, "user32.dll")
      If u32
        fnPos = GetFunction(u32, "SetWindowPos")
        If fnPos
          ; HWND_TOP, SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE
          CallFunctionFast(fnPos, hs, 0, 0, 0, 0, 0, 3 | 1 | $10)
        EndIf
        fnInv = GetFunction(u32, "InvalidateRect")
        If fnInv
          CallFunctionFast(fnInv, hs, 0, 1)
        EndIf
        CloseLibrary(u32)
      EndIf
    CompilerEndIf
  EndProcedure

  ; <summary>
  ; Clip output RichEdit paint/layout To its gadget height (stops covering status bar).
  ; </summary>
  Procedure Ide_Ui_OutputClipClient()
    Protected hwnd.i, rc.Ide_Rect, w.i, h.i, u32.i, fn.i
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      If IsGadget(#GAD_OUTPUT) = #False
        ProcedureReturn
      EndIf
      hwnd = GadgetID(#GAD_OUTPUT)
      w = GadgetWidth(#GAD_OUTPUT)
      h = GadgetHeight(#GAD_OUTPUT)
      If hwnd = 0 Or w < 8 Or h < 8
        ProcedureReturn
      EndIf
      u32 = OpenLibrary(#PB_Any, "user32.dll")
      If u32
        fn = GetFunction(u32, "GetClientRect")
        If fn
          CallFunctionFast(fn, hwnd, @rc)
          If rc\right > 0 And rc\bottom > 6
            rc\bottom = rc\bottom - 2
          Else
            rc\left = 0
            rc\top = 0
            rc\right = w
            rc\bottom = h - 2
          EndIf
        Else
          rc\left = 0
          rc\top = 0
          rc\right = w
          rc\bottom = h - 2
        EndIf
        CloseLibrary(u32)
      Else
        rc\left = 0
        rc\top = 0
        rc\right = w
        rc\bottom = h - 2
      EndIf
      SendMessage_(hwnd, #EM_SETRECT, 0, @rc)
      SendMessage_(hwnd, #WM_SIZE, 0, (h << 16) | (w & $FFFF))
    CompilerEndIf
  EndProcedure

  ; <summary>
  ; Minimum height of the output stack (REPL + error List + output editor).
  ; </summary>
  Procedure.i Ide_Ui_MinOutputBucket()
    Protected need.i = 40
    need + Ide_Ui_ReplBarH()
    If Ide_ErrorsVisible
      need + #Ide_ErrPanelH
    EndIf
    If need < #Ide_MinOutH
      ProcedureReturn #Ide_MinOutH
    EndIf
    ProcedureReturn need
  EndProcedure

  ; <summary>
  ; Split client height between editor And output; always reserves status bar.
  ; </summary>
  Procedure Ide_Ui_ComputeEditorOutHeights(wh.i)
    Protected top.i = #Ide_ToolbarH
    Protected findH.i = Ide_Ui_FindBarH()
    Protected avail.i, minOut.i, minEd.i, desired.i
    Protected ed.i, ou.i
    minEd = #Ide_MinEditorH
    minOut = Ide_Ui_MinOutputBucket()
    avail = wh - top - findH - #Ide_SplitH - #Ide_StatusH - #Ide_StatusGap - #Ide_OutputPad
    desired = Ide_OutputHeight
    If avail < 80
      avail = 80
    EndIf
    If avail >= minEd + minOut
      ou = desired
      If ou > avail - minEd
        ou = avail - minEd
      EndIf
      If ou < minOut
        ou = minOut
      EndIf
      ed = avail - ou
    Else
      ou = minOut
      If ou > avail - 40
        ou = avail - 40
      EndIf
      If ou < 20
        ou = 20
      EndIf
      ed = avail - ou
      If ed < 40
        ed = 40
        If ed > avail - 20
          ed = avail - 20
          If ed < 20
            ed = 20
          EndIf
        EndIf
        ou = avail - ed
      EndIf
    EndIf
    If ed < 20
      ed = 20
      If ed > avail - 20
        ed = avail - 20
      EndIf
      ou = avail - ed
    EndIf
    Ide_LayoutEditorH = ed
    Ide_LayoutOutH = ou
  EndProcedure

  ; <summary>
  ; Relayout toolbar, find bar, tab panel, splitter, output, and status for the window size.
  ; </summary>
  Procedure Ide_Ui_Layout()
    Protected ww.i = WindowWidth(#WIN_IDE)
    Protected wh.i = Ide_Ui_ClientHeight()
    Protected top.i = #Ide_ToolbarH
    Protected findH.i = Ide_Ui_FindBarH()
    Protected outH.i
    Protected editorH.i
    Protected left.i = Ide_Project_ClientLeft()
    Protected cw.i
    Protected replH.i = Ide_Ui_ReplBarH()
    Protected outEditH.i
    Protected yBase.i, yRepl.i, yOut.i
    Protected statusTop.i, errH.i

    If IsWindow(#WIN_IDE) = 0
      ProcedureReturn
    EndIf

    If ww < 200 : ww = 200 : EndIf
    If wh < 240 : wh = 240 : EndIf

    Ide_Ui_ComputeEditorOutHeights(wh)
    editorH = Ide_LayoutEditorH
    outH = Ide_LayoutOutH

    If IsGadget(#GAD_TOOL_OPEN) : ResizeGadget(#GAD_TOOL_OPEN, 8, 6, 70, 24) : EndIf
    If IsGadget(#GAD_TOOL_SAVE) : ResizeGadget(#GAD_TOOL_SAVE, 86, 6, 70, 24) : EndIf
    If IsGadget(#GAD_TOOL_RUN) : ResizeGadget(#GAD_TOOL_RUN, 164, 6, 70, 24) : EndIf
    If IsGadget(#GAD_TOOL_STOP) : ResizeGadget(#GAD_TOOL_STOP, 242, 6, 70, 24) : EndIf
    If IsGadget(#GAD_TOOL_RUN_ENTRY) : ResizeGadget(#GAD_TOOL_RUN_ENTRY, 320, 6, 82, 24) : EndIf
    If IsGadget(#GAD_TOOL_SYNC) : ResizeGadget(#GAD_TOOL_SYNC, 408, 6, 70, 24) : EndIf

    If IsGadget(#GAD_FIND_STR)
      HideGadget(#GAD_FIND_STR, Bool(Ide_FindVisible = 0))
      HideGadget(#GAD_FIND_NEXT, Bool(Ide_FindVisible = 0))
      HideGadget(#GAD_REPLACE_STR, Bool(Ide_FindVisible = 0))
      HideGadget(#GAD_REPLACE, Bool(Ide_FindVisible = 0))
      HideGadget(#GAD_REPLACE_ALL, Bool(Ide_FindVisible = 0))
      HideGadget(#GAD_FIND_CASE, Bool(Ide_FindVisible = 0))
      HideGadget(#GAD_FIND_REGEX, Bool(Ide_FindVisible = 0))
      HideGadget(#GAD_FIND_INSEL, Bool(Ide_FindVisible = 0))
      ResizeGadget(#GAD_FIND_STR, left + 8, top + 3, 160, 22)
      ResizeGadget(#GAD_FIND_NEXT, left + 172, top + 3, 60, 22)
      ResizeGadget(#GAD_REPLACE_STR, left + 238, top + 3, 130, 22)
      ResizeGadget(#GAD_REPLACE, left + 372, top + 3, 60, 22)
      ResizeGadget(#GAD_REPLACE_ALL, left + 436, top + 3, 70, 22)
      ResizeGadget(#GAD_FIND_CASE, left + 512, top + 3, 76, 22)
      ResizeGadget(#GAD_FIND_REGEX, left + 592, top + 3, 52, 22)
      ResizeGadget(#GAD_FIND_INSEL, left + 648, top + 3, 78, 22)
    EndIf

    Ide_Project_LayoutPanel(top, findH, left, editorH)
    cw = ww - left
    If cw < 200
      cw = 200
    EndIf
    If IsGadget(#GAD_TABS) : ResizeGadget(#GAD_TABS, left, top + findH, cw, editorH) : EndIf
    If IsGadget(#GAD_SPLIT) : ResizeGadget(#GAD_SPLIT, 0, top + findH + editorH, ww, #Ide_SplitH) : EndIf
    yBase = top + findH + editorH + #Ide_SplitH
    statusTop = wh - #Ide_StatusH
    errH = 0
    If IsGadget(#GAD_REPL_INPUT)
      HideGadget(#GAD_REPL_INPUT, Bool(replH = 0))
      HideGadget(#GAD_REPL_RUN, Bool(replH = 0))
      If replH
        ResizeGadget(#GAD_REPL_INPUT, 8, yBase + 2, ww - 90, replH - 4)
        ResizeGadget(#GAD_REPL_RUN, ww - 76, yBase + 2, 68, replH - 4)
      EndIf
    EndIf
    yRepl = yBase + replH
    If IsGadget(#GAD_ERRLIST)
      HideGadget(#GAD_ERRLIST, Bool(Ide_ErrorsVisible = 0))
      If Ide_ErrorsVisible
        errH = #Ide_ErrPanelH
        If yRepl + errH + 24 > statusTop
          errH = statusTop - yRepl - 24
          If errH < 0
            errH = 0
          EndIf
        EndIf
        If errH > 0
          ResizeGadget(#GAD_ERRLIST, 0, yRepl, ww, errH)
          yRepl = yRepl + errH
        EndIf
      EndIf
    EndIf
    outEditH = statusTop - yRepl - #Ide_StatusGap - #Ide_OutputPad
    If outEditH < 0
      outEditH = 0
    EndIf
    If IsGadget(#GAD_OUTPUT)
      ResizeGadget(#GAD_OUTPUT, 0, yRepl, ww, outEditH)
      Ide_Ui_OutputClipClient()
    EndIf
    If IsGadget(#GAD_STATUS)
      ResizeGadget(#GAD_STATUS, 0, statusTop, ww, #Ide_StatusH)
    EndIf
    Ide_Ui_EnsureStatusOnTop()

    Ide_EditorW = ww
    Ide_EditorH = editorH
  EndProcedure

  ; <summary>
  ; Relayout While the user resizes the main window (live tracking).
  ; </summary>
  Procedure Ide_Ui_PollWindowSize()
    Protected ww.i, wh.i
    If IsWindow(#WIN_IDE) = 0
      ProcedureReturn
    EndIf
    ww = WindowWidth(#WIN_IDE)
    wh = Ide_Ui_ClientHeight()
    If ww <> Ide_LastLayoutW Or wh <> Ide_LastLayoutH
      Ide_LastLayoutW = ww
      Ide_LastLayoutH = wh
      Ide_Ui_Layout()
      Ide_Editor_ResizeEditors()
    EndIf
  EndProcedure

  ; <summary>
  ; Client Y of the splitter bar (for hit-testing drags).
  ; </summary>
  ; <returns>Splitter top coordinate in window client space.</returns>
  Procedure.i Ide_Ui_SplitterClientY()
    Protected top.i = #Ide_ToolbarH + Ide_Ui_FindBarH()
    Protected editorH.i
    Ide_Ui_ComputeEditorOutHeights(Ide_Ui_ClientHeight())
    editorH = Ide_LayoutEditorH
    ProcedureReturn top + editorH
  EndProcedure

  ; <summary>
  ; Begin dragging the editor/output split (capture anchor Y).
  ; </summary>
  ; <param name="clientY">Mouse Y in window client coordinates.</param>
  Procedure Ide_Ui_BeginSplitDrag(clientY.i)
    Ide_SplitDragging = #True
    Ide_SplitDragAnchorY = clientY
  EndProcedure

  ; <summary>
  ; End splitter drag and persist output height via editor prefs.
  ; </summary>
  Procedure Ide_Ui_EndSplitDrag()
    If Ide_SplitDragging = 0
      ProcedureReturn
    EndIf
    Ide_SplitDragging = #False
    Ide_Editor_SavePrefs()
  EndProcedure

  ; <summary>
  ; Resize output pane while dragging the splitter (client Y of the split bar).
  ; </summary>
  ; <param name="clientY">Mouse Y in window client coordinates.</param>
  Procedure Ide_Ui_SplitDragTo(clientY.i)
    Protected wh.i = Ide_Ui_ClientHeight()
    Protected top.i = #Ide_ToolbarH + Ide_Ui_FindBarH()
    Protected outH.i
    Protected maxOut.i

    If Ide_SplitDragging = 0
      ProcedureReturn
    EndIf

    outH = wh - clientY - #Ide_SplitH - #Ide_StatusH - #Ide_StatusGap - #Ide_OutputPad
    maxOut = wh - top - #Ide_StatusH - #Ide_StatusGap - #Ide_OutputPad - #Ide_SplitH - #Ide_MinEditorH
    If maxOut < Ide_Ui_MinOutputBucket()
      maxOut = Ide_Ui_MinOutputBucket()
    EndIf
    If outH > maxOut
      outH = maxOut
    EndIf
    If outH < #Ide_MinOutH
      outH = #Ide_MinOutH
    EndIf
    Ide_OutputHeight = outH
    Ide_Ui_Layout()
    Ide_Editor_ResizeEditors()
  EndProcedure

  ; <summary>
  ; Map an output color kind to RGB for light/dark chrome.
  ; </summary>
  ; <param name="kind">#Ide_OutColor_* value.</param>
  ; <returns>Text color.</returns>
  Procedure.i Ide_Ui_OutputTextColor(kind.i)
    If kind = #Ide_OutColor_Error
      If Ide_Theme_Dark
        ProcedureReturn RGB(255, 120, 120)
      EndIf
      ProcedureReturn RGB(180, 0, 0)
    ElseIf kind = #Ide_OutColor_Warn
      If Ide_Theme_Dark
        ProcedureReturn RGB(255, 200, 100)
      EndIf
      ProcedureReturn RGB(160, 90, 0)
    ElseIf kind = #Ide_OutColor_Ok
      If Ide_Theme_Dark
        ProcedureReturn RGB(120, 220, 140)
      EndIf
      ProcedureReturn RGB(0, 120, 0)
    ElseIf kind = #Ide_OutColor_Muted
      If Ide_Theme_Dark
        ProcedureReturn RGB(150, 150, 150)
      EndIf
      ProcedureReturn RGB(110, 110, 110)
    ElseIf kind = #Ide_OutColor_Info
      If Ide_Theme_Dark
        ProcedureReturn RGB(160, 200, 255)
      EndIf
      ProcedureReturn RGB(0, 70, 160)
    EndIf
    If Ide_Theme_Dark
      ProcedureReturn RGB(210, 210, 210)
    EndIf
    ProcedureReturn RGB(30, 30, 30)
  EndProcedure

  ; <summary>
  ; Infer output color kind from a standard [prefix] line.
  ; </summary>
  ; <param name="line">Single output line.</param>
  ; <returns>#Ide_OutColor_*</returns>
  Procedure.i Ide_Ui_OutputKindFromLine(line.s)
    Protected s.s = LCase(Trim(line))
    If Left(s, 8) = "[error]"
      ProcedureReturn #Ide_OutColor_Error
    ElseIf Left(s, 7) = "[warn]"
      ProcedureReturn #Ide_OutColor_Warn
    ElseIf Left(s, 4) = "[ok]"
      ProcedureReturn #Ide_OutColor_Ok
    ElseIf Left(s, 9) = "[stopped]"
      ProcedureReturn #Ide_OutColor_Muted
    ElseIf Left(s, 7) = "[check]"
      ProcedureReturn #Ide_OutColor_Info
    ElseIf Left(s, 7) = "[ship]" Or Left(s, 9) = "[compile]"
      ProcedureReturn #Ide_OutColor_Info
    EndIf
    ProcedureReturn #Ide_OutColor_Default
  EndProcedure

  ; <summary>
  ; Menu label For theme toggle (opposite of current mode).
  ; </summary>
  Procedure Ide_Ui_RefreshThemeMenuLabel()
    If IsMenu(#MENU_MAIN) = #False
      ProcedureReturn
    EndIf
    If Ide_Theme_Dark
      SetMenuItemText(#MENU_MAIN, #MNU_THEME, Ide_I18n_Pick("Light Theme", "mnu.theme_light"))
    Else
      SetMenuItemText(#MENU_MAIN, #MNU_THEME, Ide_I18n_Pick("Dark Theme", "mnu.theme_dark"))
    EndIf
    SetMenuItemState(#MENU_MAIN, #MNU_THEME, Ide_Theme_Dark)
  EndProcedure

  ; <summary>
  ; Apply light/dark chrome colors to window, splitter, output, status, and theme menu check.
  ; </summary>
  Procedure Ide_Ui_ApplyChrome()
    Protected bg.i, fg.i, split.i, outBg.i, outFg.i
    
    If Ide_Theme_Dark
      bg = RGB(32, 32, 32)
      fg = RGB(220, 220, 220)
      split = RGB(70, 70, 70)
      outBg = RGB(24, 24, 24)
      outFg = RGB(210, 210, 210)
    Else
      bg = RGB(240, 240, 240)
      fg = RGB(30, 30, 30)
      split = RGB(200, 200, 200)
      outBg = RGB(252, 252, 252)
      outFg = RGB(30, 30, 30)
    EndIf
    
    If IsWindow(#WIN_IDE)
      SetWindowColor(#WIN_IDE, bg)
    EndIf
    
    If IsGadget(#GAD_SPLIT)
      SetGadgetColor(#GAD_SPLIT, #PB_Gadget_BackColor, split)
    EndIf
    
    If IsGadget(#GAD_OUTPUT)
      SetGadgetColor(#GAD_OUTPUT, #PB_Gadget_BackColor, outBg)
      SetGadgetColor(#GAD_OUTPUT, #PB_Gadget_FrontColor, outFg)
    EndIf
    
    If IsGadget(#GAD_STATUS)
      SetGadgetColor(#GAD_STATUS, #PB_Gadget_BackColor, bg)
      SetGadgetColor(#GAD_STATUS, #PB_Gadget_FrontColor, fg)
    EndIf
    
    Ide_Ui_RefreshThemeMenuLabel()
  EndProcedure

  ; <summary>
  ; Create the main IDE window, gadgets, menus, and keyboard shortcuts.
  ; </summary>
  ; <returns>#True on success; #False if OpenWindow fails.</returns>
  Procedure.i Ide_Ui_CreateWindow()
    Protected flags.i = #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget
    Protected wx.i, wy.i, ww.i, wh.i

    ww = Ide_PrefWinW
    wh = Ide_PrefWinH
    If ww < 640
      ww = 960
    EndIf
    If wh < 480
      wh = 640
    EndIf
    If Ide_PrefWinX >= 0 And Ide_PrefWinY >= 0
      wx = Ide_PrefWinX
      wy = Ide_PrefWinY
    Else
      wx = #PB_Ignore
      wy = #PB_Ignore
      flags | #PB_Window_ScreenCentered
    EndIf

    If OpenWindow(#WIN_IDE, wx, wy, ww, wh, "Vyrn IDE", flags) = 0
      ProcedureReturn #False
    EndIf

    EnableWindowDrop(#WIN_IDE, #PB_Drop_Files, #PB_Drag_Copy)

    Ide_Ui_CreateMenus()
    Ide_Ui_CreateProjectPopup()

    ButtonGadget(#GAD_TOOL_OPEN, 8, 6, 70, 24, "Open")
    ButtonGadget(#GAD_TOOL_SAVE, 86, 6, 70, 24, "Save")
    ButtonGadget(#GAD_TOOL_RUN, 164, 6, 70, 24, "Run")
    ButtonGadget(#GAD_TOOL_STOP, 242, 6, 70, 24, "Stop")
    ButtonGadget(#GAD_TOOL_RUN_ENTRY, 320, 6, 82, 24, "Run entry")
    ButtonGadget(#GAD_TOOL_SYNC, 408, 6, 70, 24, "Sync")
    DisableGadget(#GAD_TOOL_STOP, #True)
    Ide_Ui_CreateOutputPopup()
    Ide_Ui_CreateErrorsPopup()
    Ide_Ui_CreateStatusPopup()

    StringGadget(#GAD_FIND_STR, 8, 40, 180, 22, "")
    ButtonGadget(#GAD_FIND_NEXT, 192, 40, 70, 22, "Find")
    StringGadget(#GAD_REPLACE_STR, 270, 40, 160, 22, "")
    ButtonGadget(#GAD_REPLACE, 434, 40, 70, 22, "Replace")
    ButtonGadget(#GAD_REPLACE_ALL, 508, 40, 90, 22, "Replace All")
    CheckBoxGadget(#GAD_FIND_CASE, 604, 40, 90, 22, "Match case")
    CheckBoxGadget(#GAD_FIND_REGEX, 700, 40, 52, 22, "Regex")
    CheckBoxGadget(#GAD_FIND_INSEL, 756, 40, 78, 22, "In sel")
    ListIconGadget(#GAD_PROJECT, 0, #Ide_ToolbarH, 200, 200, Ide_I18n_Pick("Script", "col.script"), 200, #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_GridLines)
    AddGadgetColumn(#GAD_PROJECT, 1, Ide_I18n_Pick("Path", "col.path"), 400)
    ListIconGadget(#GAD_OUTLINE, 0, #Ide_ToolbarH, 200, 100, Ide_I18n_Pick("Symbol", "col.symbol"), 180, #PB_ListIcon_AlwaysShowSelection)
    AddGadgetColumn(#GAD_OUTLINE, 1, Ide_I18n_Pick("Line", "col.line"), 48)
    HideGadget(#GAD_OUTLINE, #True)
    ListIconGadget(#GAD_ERRLIST, 0, 0, 10, #Ide_ErrPanelH, Ide_I18n_Pick("Errors", "col.errors"), 600, #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_GridLines)
    AddGadgetColumn(#GAD_ERRLIST, 1, Ide_I18n_Pick("Ln", "col.ln"), 40)
    AddGadgetColumn(#GAD_ERRLIST, 2, Ide_I18n_Pick("Col", "col.col"), 36)
    HideGadget(#GAD_ERRLIST, #True)
    EnableGadgetDrop(#GAD_PROJECT, #PB_Drop_Files, #PB_Drag_Copy)
    HideGadget(#GAD_FIND_STR, #True)
    HideGadget(#GAD_FIND_NEXT, #True)
    HideGadget(#GAD_REPLACE_STR, #True)
    HideGadget(#GAD_REPLACE, #True)
    HideGadget(#GAD_REPLACE_ALL, #True)
    HideGadget(#GAD_FIND_CASE, #True)
    HideGadget(#GAD_FIND_REGEX, #True)
    HideGadget(#GAD_FIND_INSEL, #True)
    HideGadget(#GAD_PROJECT, #True)

    ; Empty panel; tabs are added via Ide_Editor_AddTab (OpenGadgetList → AddGadgetItem → CloseGadgetList).
    PanelGadget(#GAD_TABS, 0, #Ide_ToolbarH, 100, 100)
    CloseGadgetList()

    TextGadget(#GAD_SPLIT, 0, 0, 10, #Ide_SplitH, "", #PB_Text_Border | #PB_Text_Center)
    StringGadget(#GAD_REPL_INPUT, 8, 0, 200, #Ide_ReplBarH, "")
    ButtonGadget(#GAD_REPL_RUN, 220, 0, 60, #Ide_ReplBarH, "Eval")
    EditorGadget(#GAD_OUTPUT, 0, 0, 10, 10, #PB_Editor_ReadOnly)
    Ide_Ui_OutputInitUnicode()
    TextGadget(#GAD_STATUS, 0, 0, 10, #Ide_StatusH, "Ready")

    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_F5, #MNU_RUN)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Shift | #PB_Shortcut_F5, #MNU_STOP)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_F7, #MNU_COMPILE_VYRNC)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_F8, #MNU_CHECK_SYNTAX)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_F5, #MNU_RUN_VYRNC)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_G, #MNU_GOTOLINE)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Slash, #MNU_TOGGLE_COMMENT)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_R, #MNU_SYNC_RUNTIME)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_N, #MNU_NEW)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_O, #MNU_OPEN)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_S, #MNU_SAVE)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_S, #MNU_SAVE_ALL)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_W, #MNU_CLOSE)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Z, #MNU_UNDO)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Y, #MNU_REDO)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_F, #MNU_FIND)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_F3, #MNU_FINDNEXT)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_H, #MNU_REPLACE)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Add, #MNU_ZOOMIN)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Subtract, #MNU_ZOOMOUT)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_0, #MNU_ZOOMRESET)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Return, #MNU_REPL_RUN)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_F5, #MNU_RUN_ENTRY)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_F12, #MNU_GOTO_LIGHT)
    AddKeyboardShortcut(#WIN_IDE, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_I, #MNU_FORMAT_DOC)

    DisableMenuItem(#MENU_MAIN, #MNU_STOP, #True)
    Ide_Samples_InitMenu()
    Ide_Extensions_InitMenu()
    Ide_Ui_ApplyMenuLabels()
    Ide_Ui_ApplyToolbarLabels()
    Ide_Ui_ApplyChrome()
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Set the status bar text.
  ; </summary>
  ; <param name="msg">Status message to display.</param>
  ; <summary>Runtime suffix for the status bar (ABI + DLL sync hint).</summary>
  Procedure.s Ide_Ui_RuntimeTag()
    Protected tag.s, ver.s, abi.s
    If Vyrn_IsReady() = 0
      ProcedureReturn " | " + Ide_I18n_Pick("(runtime missing)", "status.rt_missing")
    EndIf
    ver = Vyrn_ProductVersion()
    abi = Str(Vyrn_Abi)
    If Ide_RuntimeHealth_NeedsSync()
      tag = Ide_I18n_Pick("[sync] click to update DLL", "status.rt_sync")
    Else
      tag = Ide_I18n_Pick("[ok]", "status.rt_ok")
    EndIf
    ProcedureReturn " | " + tag + " Vyrn " + ver + " ABI " + abi
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_RefreshStatusBar
  ; </summary>
  Procedure Ide_Ui_RefreshStatusBar()
    Protected full.s
    If IsGadget(#GAD_STATUS) = #False
      ProcedureReturn
    EndIf
    If Ide_StatusBase = ""
      Ide_StatusBase = Ide_I18n_Pick("Ready", "status.ready")
    EndIf
    full = Ide_StatusBase
    If Ide_Runner_IsBusy() = #False And Left(LCase(Ide_StatusBase), 7) <> "running"
      full + Ide_Ui_RuntimeTag()
    EndIf
    SetGadgetText(#GAD_STATUS, full)
    Ide_Ui_EnsureStatusOnTop()
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_RefreshSyncChrome
  ; </summary>
  Procedure Ide_Ui_RefreshSyncChrome()
    If IsGadget(#GAD_TOOL_SYNC) = #False
      ProcedureReturn
    EndIf
    If Vyrn_IsReady() And Ide_RuntimeHealth_NeedsSync()
      SetGadgetColor(#GAD_TOOL_SYNC, #PB_Gadget_BackColor, RGB(255, 214, 120))
    Else
      SetGadgetColor(#GAD_TOOL_SYNC, #PB_Gadget_BackColor, #PB_Default)
    EndIf
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_RefreshRuntimeStatus
  ; </summary>
  Procedure Ide_Ui_RefreshRuntimeStatus()
    Ide_Ui_RefreshStatusBar()
    Ide_Ui_RefreshSyncChrome()
  EndProcedure

  ; <summary>
  ; Update the status bar gadget caption (Not localized by itself).
  ; </summary>
  Procedure Ide_Ui_SetStatus(msg.s)
    Ide_StatusBase = msg
    Ide_Ui_RefreshStatusBar()
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_StatusClick
  ; </summary>
  Procedure Ide_Ui_StatusClick()
    If Ide_StatusShipDir <> "" And IsMenu(#POP_STATUS)
      DisplayPopupMenu(#POP_STATUS, GadgetID(#GAD_STATUS))
      ProcedureReturn
    EndIf
    If Vyrn_IsReady() And Ide_RuntimeHealth_NeedsSync()
      Ide_Runner_SyncRuntime()
    EndIf
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_HandleStatusPopup
  ; </summary>
  ; <param name="menuId">integer</param>
  Procedure Ide_Ui_HandleStatusPopup(menuId.i)
    Select menuId
      Case #POP_STATUS_SHIP_OPEN
        If Ide_StatusShipDir <> "" And FileSize(Ide_StatusShipDir) >= 0
          RunProgram("explorer.exe", Ide_StatusShipDir, GetPathPart(ProgramFilename()))
          Ide_Ui_SetStatus(Ide_I18n_Fmt1("Opened {dir}", "status.opened_dir", "{dir}", Ide_StatusShipDir))
        EndIf
      Case #POP_STATUS_SHIP_COPY
        If Ide_StatusShipDir <> ""
          SetClipboardText(Ide_StatusShipDir)
          Ide_Ui_SetStatus(Ide_I18n_Pick("Ship path copied", "status.ship_copied"))
        EndIf
      Case #POP_STATUS_SYNC
        Ide_Runner_SyncRuntime()
    EndSelect
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_OutputPopupShow
  ; </summary>
  Procedure Ide_Ui_OutputPopupShow()
    If IsGadget(#GAD_OUTPUT) = #False
      ProcedureReturn
    EndIf
    DisplayPopupMenu(#POP_OUTPUT, GadgetID(#GAD_OUTPUT))
  EndProcedure
  
  ; <summary>
  ; Ide_Ui_HandleOutputPopup
  ; </summary>
  ; <param name="menuId">integer</param>
  Procedure Ide_Ui_HandleOutputPopup(menuId.i)
    Protected dir.s
    Select menuId
      Case #POP_OUT_COPY_ALL
        Ide_Ui_OutputCopyAll()
      Case #POP_OUT_COPY_ERR
        Ide_Cmd_Dispatch(#MNU_OUTPUT_COPY_ERR)
      Case #POP_OUT_REVEAL_SCRIPT
        If Ide_Runner_LastScriptPath() <> "" And FileSize(Ide_Runner_LastScriptPath()) >= 0
          Ide_Editor_RevealInExplorer(Ide_Runner_LastScriptPath())
        Else
          MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("No on-disk run script yet (use F5).", "out.no_run_path"), #PB_MessageRequester_Info)
        EndIf
      Case #POP_OUT_OPEN_TEMP
        dir = GetTemporaryDirectory() + "vyrn_ide_run"
        If FileSize(dir) <> -2
          dir = GetTemporaryDirectory()
        EndIf
        If dir <> ""
          RunProgram("explorer.exe", dir, GetPathPart(ProgramFilename()))
          Ide_Ui_SetStatus(Ide_I18n_Fmt1("Opened {dir}", "status.opened_dir", "{dir}", dir))
        EndIf
    EndSelect
  EndProcedure

  ; <summary>
  ; Configure the output RichEdit for UTF-16 (avoids mojibake when appending via EM_REPLACESEL).
  ; Call once after #GAD_OUTPUT is created.
  ; </summary>
  Procedure Ide_Ui_OutputInitUnicode()
    Protected hwnd.i
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      If IsGadget(#GAD_OUTPUT) = #False
        ProcedureReturn
      EndIf
      hwnd = GadgetID(#GAD_OUTPUT)
      If hwnd
        SendMessage_(hwnd, #CCM_SETUNICODEFORMAT, 1, 0)
      EndIf
    CompilerEndIf
  EndProcedure

  ; <summary>
  ; Color the current selection in the output RichEdit (Windows).
  ; </summary>
  ; <param name="kind">#Ide_OutColor_*</param>
  Procedure Ide_Ui_OutputColorSelection(kind.i)
    Protected cf.Ide_CharFormat
    Protected hwnd.i
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      hwnd = GadgetID(#GAD_OUTPUT)
      If hwnd = 0
        ProcedureReturn
      EndIf
      cf\cbSize = SizeOf(Ide_CharFormat)
      cf\dwMask = #CFM_COLOR
      cf\crTextColor = Ide_Ui_OutputTextColor(kind)
      SendMessage_(hwnd, #EM_SETCHARFORMAT, #SCF_SELECTION, @cf)
    CompilerEndIf
  EndProcedure

  ; <summary>
  ; Append a line to the output pane and scroll to the end (Windows).
  ; Uses SetGadgetText on Windows so paths/messages with non-ASCII characters stay readable.
  ; </summary>
  ; <param name="line">Text to append (a newline is added).</param>
  ; <param name="kind">#Ide_OutColor_Auto to infer from [error]/[warn]/[ok] prefixes.</param>
  Declare Ide_Nav_ErrorsPush(line.s)
  Declare Ide_Nav_ErrorsClear()
  Declare Ide_Nav_ErrorsPrepareF8()
  Declare Ide_Nav_ErrorsOnSyntaxCheckDone(ok.i)
  
  ; <summary>
  ; IDE: Ui OutputClear.
  ; </summary>
  Procedure Ide_Ui_OutputClear()
    If IsGadget(#GAD_OUTPUT)
      SetGadgetText(#GAD_OUTPUT, "")
    EndIf
    Ide_Nav_ErrorsClear()
  EndProcedure

  ; <summary>
  ; IDE: Ui OutputCopyAll.
  ; </summary>
  Procedure Ide_Ui_OutputCopyAll()
    Protected t.s
    If IsGadget(#GAD_OUTPUT) = #False
      ProcedureReturn
    EndIf
    t = GetGadgetText(#GAD_OUTPUT)
    If t <> ""
      SetClipboardText(t)
      Ide_Ui_SetStatus(Ide_I18n_Pick("Output copied", "out.copied"))
    EndIf
  EndProcedure

  ; <summary>
  ; IDE: Ui OutputAppend.
  ; </summary>
  ; <param name="lines">see signature</param>
  ; <param name="kindi">see signature</param>
  Procedure Ide_Ui_OutputAppend(line.s, kind.i = #Ide_OutColor_Auto)
    Protected text.s = line + Chr(10)
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      Protected hwnd.i = GadgetID(#GAD_OUTPUT)
      Protected cur.s, start.i, span.i
      If hwnd = 0
        ProcedureReturn
      EndIf
      If kind = #Ide_OutColor_Auto
        kind = Ide_Ui_OutputKindFromLine(line)
      EndIf
      cur = GetGadgetText(#GAD_OUTPUT)
      start = Len(cur)
      If cur <> "" And Right(cur, 1) <> Chr(10)
        cur = cur + Chr(10)
        start = Len(cur)
      EndIf
      span = Len(text)
      SetGadgetText(#GAD_OUTPUT, cur + text)
      If kind <> #Ide_OutColor_Default
        SendMessage_(hwnd, #EM_SETSEL, start, start + span)
        Ide_Ui_OutputColorSelection(kind)
      EndIf
      SendMessage_(hwnd, #EM_SETSEL, -1, -1)
      SendMessage_(hwnd, #EM_SCROLLCARET, 0, 0)
      If kind = #Ide_OutColor_Error
        Ide_Nav_ErrorsPush(line)
      EndIf
      Ide_Ui_OutputClipClient()
      Ide_Ui_EnsureStatusOnTop()
    CompilerElse
      Protected cur.s = GetGadgetText(#GAD_OUTPUT)
      If cur <> "" And Right(cur, 1) <> Chr(10)
        cur = cur + Chr(10)
      EndIf
      SetGadgetText(#GAD_OUTPUT, cur + text)
    CompilerEndIf
  EndProcedure

  ; <summary>
  ; When the output pane is empty, show a one-line legend For tag prefixes (i18n).
  ; </summary>
  Procedure Ide_Ui_MaybeOutputLegend()
    Protected t.s
    If IsGadget(#GAD_OUTPUT) = 0
      ProcedureReturn
    EndIf
    t = GetGadgetText(#GAD_OUTPUT)
    If t <> ""
      ProcedureReturn
    EndIf
    Ide_Ui_OutputAppend(Ide_I18n_Pick("[hint] Output: [ok]/[warn]/[error]/[info]  -  double-click to jump; Run menu copies last error", "out.legend"), #Ide_OutColor_Info)
  EndProcedure

  ; <summary>
  ; Show the find bar and focus find or replace field.
  ; </summary>
  ; <param name="showReplace">#True to focus replace; #False to focus find.</param>
  Procedure Ide_Ui_ToggleFindBar()
    Ide_FindVisible = Bool(Ide_FindVisible = 0)
    Ide_FindBarPinned = Ide_FindVisible
    SetMenuItemState(#MENU_MAIN, #MNU_FIND_PANEL, Ide_FindVisible)
    Ide_Ui_Layout()
    Ide_Editor_ResizeEditors()
    Ide_Editor_SavePrefs()
    If Ide_FindVisible
      SetActiveGadget(#GAD_FIND_STR)
      Ide_Ui_SetStatus(Ide_I18n_Pick("Find bar  -  Ctrl+F, F3 next, Ctrl+H replace", "status.find_bar_on"))
    Else
      Ide_Editor_UpdateCaretStatus()
    EndIf
  EndProcedure

  ; <summary>
  ; IDE: Ui OutputScrollToLastError.
  ; </summary>
  Procedure Ide_Ui_OutputScrollToLastError()
    Protected t.s, pos.i, hwnd.i, off.i, scan.i, hit.i
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      If IsGadget(#GAD_OUTPUT) = 0
        ProcedureReturn
      EndIf
      t = GetGadgetText(#GAD_OUTPUT)
      pos = 0
      scan = 1
      Repeat
        hit = FindString(LCase(t), "[error]", scan, #PB_String_NoCase)
        If hit = 0
          Break
        EndIf
        pos = hit
        scan = hit + 1
      ForEver
      If pos <= 0
        ProcedureReturn
      EndIf
      hwnd = GadgetID(#GAD_OUTPUT)
      off = pos - 1
      SendMessage_(hwnd, #EM_SETSEL, off, Len(t))
      SendMessage_(hwnd, #EM_SCROLLCARET, 0, 0)
    CompilerEndIf
  EndProcedure

  ; <summary>
  ; IDE: Ui ShowFind.
  ; </summary>
  ; <param name="showReplacei">see signature</param>
  Procedure Ide_Ui_ShowFind(showReplace.i = #False)
    Ide_FindVisible = #True
    Ide_FindBarPinned = #True
    SetMenuItemState(#MENU_MAIN, #MNU_FIND_PANEL, #True)
    Ide_Ui_Layout()
    
    If showReplace And IsGadget(#GAD_REPLACE_STR)
      SetActiveGadget(#GAD_REPLACE_STR)
    ElseIf IsGadget(#GAD_FIND_STR)
      SetActiveGadget(#GAD_FIND_STR)
    EndIf
    Ide_Ui_SetStatus(Ide_I18n_Pick("Find bar  -  Ctrl+F, F3 next, Ctrl+H replace", "status.find_bar_on"))
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 719
; FirstLine = 502
; Folding = -----------
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; DllProtection
; EnableOnError
; DisableDebugger
; CompileSourceDirectory
; Compiler = PureBasic 6.41 - C Backend (Windows - x64)