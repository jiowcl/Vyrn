;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - menu / toolbar command handlers
; Routes #MNU_* and project popup IDs to editor, runner, and dev tools.
; PureBasic 6.41

CompilerIf Defined(Ide_Commands, #PB_Constant) = #False
  #Ide_Commands = #True
  
  ; <summary>
  ; Save the active tab to its path, or prompt for a path when untitled.
  ; </summary>
  ; <returns>#True on success; #False on cancel or write failure.</returns>
  Procedure.i Ide_Cmd_Save()
    Protected path.s
    
    If Ide_FilePath <> ""
      If Ide_Editor_SaveTo(Ide_FilePath)
        Ide_Ui_SetStatus(Ide_I18n_Fmt1("Saved {path}", "status.saved", "{path}", Ide_FilePath))
        ProcedureReturn #True
      EndIf
      
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Failed to save:", "dlg.failed_save") + Chr(10) + Ide_FilePath, #PB_MessageRequester_Error)
      
      ProcedureReturn #False
    EndIf
    
    path = SaveFileRequester(Ide_I18n_Pick("Save Vyrn script", "dlg.save_script"), "untitled.vyrn", "Vyrn (*.vyrn)|*.vyrn|LuaLite (*.lua)|*.lua|All (*.*)|*.*", 0)
    
    If path = ""
      ProcedureReturn #False
    EndIf
    
    If GetExtensionPart(path) = ""
      path = path + ".vyrn"
    EndIf
    
    If Ide_Editor_SaveTo(path)
      Ide_Ui_SetStatus(Ide_I18n_Fmt1("Saved {path}", "status.saved", "{path}", path))
      
      ProcedureReturn #True
    EndIf
    
    MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Failed to save:", "dlg.failed_save") + Chr(10) + path, #PB_MessageRequester_Error)
    
    ProcedureReturn #False
  EndProcedure
  
  ; <summary>
  ; Prompt for a new path and save the active tab (Save As).
  ; </summary>
  ; <returns>#True on success; #False on cancel or write failure.</returns>
  Procedure.i Ide_Cmd_SaveAs()
    Protected path.s
    Protected start.s = Ide_FilePath
    
    If start = ""
      start = "untitled.vyrn"
    EndIf
    
    path = SaveFileRequester(Ide_I18n_Pick("Save Vyrn script as", "dlg.save_script_as"), start, "Vyrn (*.vyrn)|*.vyrn|LuaLite (*.lua)|*.lua|All (*.*)|*.*", 0)
    
    If path = ""
      ProcedureReturn #False
    EndIf
    
    If GetExtensionPart(path) = ""
      path = path + ".vyrn"
    EndIf
    
    If Ide_Editor_SaveTo(path)
      Ide_Ui_SetStatus(Ide_I18n_Fmt1("Saved {path}", "status.saved", "{path}", path))
      
      ProcedureReturn #True
    EndIf
    
    MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Failed to save:", "dlg.failed_save") + Chr(10) + path, #PB_MessageRequester_Error)
    
    ProcedureReturn #False
  EndProcedure
  
  ; <summary>
  ; Open a new untitled buffer; blocked while a script is running.
  ; </summary>
  Procedure Ide_Cmd_New()
    If Ide_Runner_IsBusy()
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Stop the running script before creating a new file.", "dlg.stop_before_new"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    Ide_Editor_New()
    Ide_Ui_SetStatus(Ide_I18n_Pick("New file", "status.new_file"))
  EndProcedure

  ; <summary>
  ; Open a .vyrn/.lua file via requester; blocked while a script is running.
  ; </summary>
  Procedure Ide_Cmd_Open()
    Protected path.s
    If Ide_Runner_IsBusy()
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Stop the running script before opening another file.", "dlg.stop_before_open"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    path = OpenFileRequester(Ide_I18n_Pick("Open Vyrn script", "dlg.open_script"), "", "Vyrn (*.vyrn)|*.vyrn|LuaLite (*.lua)|*.lua|All (*.*)|*.*", 0)
    If path = ""
      ProcedureReturn
    EndIf
    If Ide_Editor_LoadFile(path)
      Ide_Ui_SetStatus(Ide_I18n_Fmt1("Opened {path}", "status.opened", "{path}", path))
    Else
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Failed to open:", "dlg.failed_open") + Chr(10) + path, #PB_MessageRequester_Error)
    EndIf
  EndProcedure

  ; <summary>
  ; Close the active tab after optional save prompt; blocked while running.
  ; </summary>
  Procedure Ide_Cmd_CloseTab()
    If Ide_Runner_IsBusy()
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Stop the running script before closing a tab.", "dlg.stop_before_close"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    Ide_Editor_CloseTab()
  EndProcedure

  ; <summary>
  ; Show the find bar (and focus replace field when requested).
  ; </summary>
  ; <param name="showReplace">#True to focus the replace string gadget.</param>
  Procedure Ide_Cmd_ShowFind(showReplace.i = #False)
    Ide_Ui_ShowFind(showReplace)
    Ide_Editor_ResizeEditors()
  EndProcedure
  
  ; <summary>
  ; Show About dialog with author, runtime version, ABI, and DLL path.
  ; </summary>
  Procedure Ide_Cmd_About()
    Protected msg.s
    Protected dllHint.s

    If Vyrn_DllPath <> ""
      dllHint = Vyrn_DllPath
    Else
      dllHint = "(not loaded)"
    EndIf

    msg = "Vyrn IDE " + Ide_App_ReadVersion() + Chr(10) + Chr(10)
    msg = msg + Ide_I18n_Pick("Author: Jiowcl - Ji-Feng Tsai (jiowcl@gmail.com)", "about.author") + Chr(10)
    msg = msg + Ide_I18n_Pick("Product: ", "about.product") + Ide_App_ReadVersion() + Chr(10)
    msg = msg + Ide_I18n_Pick("Runtime: Vyrn ", "about.runtime") + Vyrn_ProductVersion() + " (ABI " + Str(Vyrn_Abi) + ")" + Chr(10)
    msg = msg + Ide_RuntimeHealth_AboutLine() + Chr(10) + Chr(10)
    msg = msg + Ide_I18n_Pick("Edit .vyrn scripts with tabs, find/replace, REPL, and run them via Vyrn.dll.", "about.blurb")
    msg = msg + Chr(10) + Ide_I18n_Pick("match arms need literals  -  use if/elif on enum members (Insert snippet).", "about.match_hint")

    MessageRequester(Ide_I18n_Pick("About Vyrn IDE", "about.title"), msg, #PB_MessageRequester_Info)
  EndProcedure
  
  ; <summary>
  ; Route a menu/toolbar/shortcut id (#MNU_*) to the matching command.
  ; </summary>
  ; <param name="menuId">Menu constant such as #MNU_SAVE or #MNU_RUN.</param>
  Procedure Ide_Cmd_Dispatch(menuId.i)
    Select menuId
      Case #MNU_NEW
        Ide_Cmd_New()
      Case #MNU_OPEN
        Ide_Cmd_Open()
      Case #MNU_SAVE
        Ide_Cmd_Save()
      Case #MNU_SAVEAS
        Ide_Cmd_SaveAs()
      Case #MNU_SAVE_ALL
        Ide_Editor_SaveAll()
      Case #MNU_REVERT
        Ide_Editor_RevertActive()
      Case #MNU_REVEAL
        Ide_Editor_RevealInExplorer("")
      Case #MNU_CLOSE
        Ide_Cmd_CloseTab()
      Case #MNU_EXIT
        If Ide_Runner_IsBusy()
          Ide_Runner_Stop()
        EndIf
        If Ide_Editor_ConfirmSaveAll()
          End
        EndIf
      Case #MNU_UNDO
        Ide_Editor_Undo()
      Case #MNU_REDO
        Ide_Editor_Redo()
      Case #MNU_CUT
        Ide_Editor_Cut()
      Case #MNU_COPY
        Ide_Editor_Copy()
      Case #MNU_PASTE
        Ide_Editor_Paste()
      Case #MNU_FIND
        Ide_Cmd_ShowFind(#False)
      Case #MNU_FINDNEXT
        If Ide_FindVisible = 0
          Ide_Cmd_ShowFind(#False)
        EndIf
        Ide_Editor_FindNext()
      Case #MNU_REPLACE
        Ide_Cmd_ShowFind(#True)
      Case #MNU_ZOOMIN
        Ide_Editor_ZoomIn()
      Case #MNU_ZOOMOUT
        Ide_Editor_ZoomOut()
      Case #MNU_ZOOMRESET
        Ide_Editor_ZoomReset()
      Case #MNU_THEME
        Ide_Editor_ToggleTheme()
      Case #MNU_RUN
        Ide_Runner_Run()
      Case #MNU_SYNC_RUNTIME
        Ide_Runner_SyncRuntime()
      Case #MNU_SHIP_STANDALONE
        Ide_Runner_Ship(0)
      Case #MNU_SHIP_STANDALONE_EXE
        Ide_Runner_Ship(1)
      Case #MNU_SHIP_COMPILE
        Ide_Runner_Ship(2)
      Case #MNU_SHIP_COMPILE_EXE
        Ide_Runner_Ship(3)
      Case #MNU_COMPILE_VYRNC
        Ide_Runner_CompileVyrnc(#False)
      Case #MNU_RUN_VYRNC
        Ide_Runner_CompileVyrnc(#True)
      Case #MNU_STOP
        Ide_Runner_Stop()
      Case #MNU_GOTO_LIGHT
        Ide_EditorAssist_GotoTokenLight()
      Case #MNU_GOTOLINE
        Ide_Editor_GotoLinePrompt()
      Case #MNU_ERRORS_HINTS
        Ide_Nav_ErrorsToggleHints()
      Case #MNU_ERRORS_FILTER_CODE
        Ide_Nav_ErrorsPromptFilter()
      Case #MNU_ERRORS_CLEAR_FILTER
        Ide_Nav_ErrorsFilterByCode("")
      Case #MNU_CHECK_SYNTAX
        Ide_Runner_CheckSyntax()
      Case #MNU_RUN_JSON_RECHECK
        Ide_Runner_CheckSyntaxJsonRefresh()
      Case #MNU_FORMAT_DOC
        Ide_Dev_FormatDocument()
      Case #MNU_FIND_ALL_TABS
        Ide_Editor_FindAllTabs()
      Case #MNU_TOGGLE_COMMENT
        Ide_Editor_ToggleComment()
      Case #MNU_PROJECT_OPEN
        Ide_Project_OpenFolder()
      Case #MNU_PROJECT_PANEL
        Ide_Project_TogglePanel()
      Case #MNU_PROJ_MRU_0
        Ide_Project_MruOpen(0)
      Case #MNU_PROJ_MRU_1
        Ide_Project_MruOpen(1)
      Case #MNU_PROJ_MRU_2
        Ide_Project_MruOpen(2)
      Case #MNU_PROJ_MRU_3
        Ide_Project_MruOpen(3)
      Case #MNU_PROJ_MRU_4
        Ide_Project_MruOpen(4)
      Case #MNU_FIND_PANEL
        Ide_Ui_ToggleFindBar()
      Case #MNU_PROJECT_VYRN_ONLY
        Ide_Project_ToggleVyrnFilter()
      Case #MNU_OPEN_SETTINGS
        Ide_Dev_OpenSettings()
      Case #MNU_OPEN_CONFIG_FOLDER
        Ide_Dev_OpenConfigFolder()
      Case #MNU_OPEN_EXT_FOLDER
        Ide_Dev_OpenExtFolder()
      Case #MNU_OPEN_LAST_SHIP
        Ide_Dev_OpenLastShipOut()
      Case #MNU_COPY_SHIP_CMD
        Ide_Dev_CopyLastShipCmd()
      Case #MNU_DUMP_BYTECODE
        Ide_Dev_DumpBytecode()
      Case #MNU_SHORTCUTS
        Ide_Dev_ShowShortcuts()
      Case #MNU_OUTLINE_PANEL
        Ide_Nav_OutlineToggle()
      Case #MNU_ERRORS_PANEL
        Ide_Nav_ErrorsToggle()
      Case #MNU_RUN_CONFIG
        Ide_RunConfig_ShowDialog()
      Case #MNU_RUN_ENTRY
        Ide_Project_RunEntry()
      Case #POP_OUT_COPY_ALL, #POP_OUT_COPY_ERR, #POP_OUT_REVEAL_SCRIPT, #POP_OUT_OPEN_TEMP
        Ide_Ui_HandleOutputPopup(menuId)
      Case #POP_ERR_COPY_LOC, #POP_ERR_COPY_CODE, #POP_ERR_SET_FILTER, #POP_ERR_CLEAR_FILTER
        Ide_Nav_ErrorsHandlePopup(menuId)
      Case #POP_STATUS_SHIP_OPEN, #POP_STATUS_SHIP_COPY, #POP_STATUS_SYNC
        Ide_Ui_HandleStatusPopup(menuId)
      Case #MNU_TAB_WIDTH_2
        Ide_Editor_SetTabWidth(2)
      Case #MNU_TAB_WIDTH_4
        Ide_Editor_SetTabWidth(4)
      Case #MNU_AUTOSAVE
        Ide_AutoSave_Toggle()
      Case #MNU_OUTPUT_CLEAR
        Ide_Ui_OutputClear()
      Case #MNU_OUTPUT_COPY
        Ide_Ui_OutputCopyAll()
      Case #MNU_OUTPUT_COPY_ERR
        If Ide_LastRunCopyDetail <> ""
          SetClipboardText(Ide_LastRunCopyDetail)
          Ide_Ui_SetStatus(Ide_I18n_Pick("Last run error copied", "status.copy_err"))
        Else
          MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("No failed run details to copy yet.", "dlg.no_copy_err"), #PB_MessageRequester_Info)
        EndIf
      Case #MNU_WELCOME
        Ide_ShowWelcome = #True
        Ide_Welcome_ApplyToActiveIfEmpty()
        Ide_Ui_SetStatus(Ide_I18n_Pick("Welcome  -  drag files onto the window; F5 Run, F8 syntax", "welcome.hint"))
        Ide_Editor_SavePrefs()
      Case #MNU_CUSTOM_0
        Ide_Extensions_RunCustom(0)
      Case #MNU_CUSTOM_1
        Ide_Extensions_RunCustom(1)
      Case #MNU_CUSTOM_2
        Ide_Extensions_RunCustom(2)
      Case #MNU_CUSTOM_3
        Ide_Extensions_RunCustom(3)
      Case #POP_PROJ_OPEN, #POP_PROJ_RUN, #POP_PROJ_SHIP, #POP_PROJ_REVEAL, #POP_PROJ_COPY, #POP_PROJ_SET_ENTRY
        Ide_Project_HandlePopup(menuId)
      Case #MNU_LIVE_CHECK
        Ide_LiveCheckEnabled = Bool(Ide_LiveCheckEnabled = 0)
        SetMenuItemState(#MENU_MAIN, #MNU_LIVE_CHECK, Ide_LiveCheckEnabled)
        Ide_Editor_SavePrefs()
        If Ide_LiveCheckEnabled
          Ide_Ui_SetStatus(Ide_I18n_Pick("Live syntax check enabled", "status.live_on"))
        Else
          Ide_Ui_SetStatus(Ide_I18n_Pick("Live syntax check disabled", "status.live_off"))
        EndIf
      Case #MNU_MRU_CLEAR
        Ide_Editor_MruClear()
      Case #MNU_SNIPPET_FUNC
      Case #MNU_SNIPPET_IF
      Case #MNU_SNIPPET_MAIN
      Case #MNU_SNIPPET_VYRN12
      Case #MNU_SNIPPET_ENUM
      Case #MNU_SNIPPET_STRUCT
      Case #MNU_SNIPPET_MATCH_IF
        Ide_Snippets_InsertKind(menuId)
      Case #MNU_REPL_PANEL
        Ide_Repl_TogglePanel()
      Case #MNU_REPL_RUN
        Ide_Repl_EvalLine()
      Case #MNU_REPL_RESET
        Ide_Repl_ResetVm()
      Case #MNU_LANG_EN
        Ide_Ui_SetLanguage(#Ide_Lang_En)
      Case #MNU_LANG_ZH
        Ide_Ui_SetLanguage(#Ide_Lang_Zh)
      Case #MNU_EXT_REFRESH
        Ide_Extensions_LoadList()
        Ide_Extensions_LoadToolsIni()
        Ide_Extensions_RefreshMenuLabels()
        Ide_Extensions_RefreshCustomMenu()
        Ide_Ui_SetStatus(Ide_I18n_Pick("Extensions refreshed", "ext.refreshed"))
      Case #MNU_ABOUT
        Ide_Cmd_About()
      Default
        If menuId >= #MNU_SAMPLE_0 And menuId <= #MNU_SAMPLE_23
          Ide_Samples_OpenIndex(menuId - #MNU_SAMPLE_0)
        ElseIf menuId >= #MNU_EXT_0 And menuId <= #MNU_EXT_7
          Ide_Extensions_RunIndex(menuId - #MNU_EXT_0)
        ElseIf menuId >= #MNU_MRU_0 And menuId <= #MNU_MRU_9
          If Ide_Runner_IsBusy() = #False
            Ide_Editor_OpenMru(menuId - #MNU_MRU_0)
          Else
            MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Stop the running script or wait for the current job before opening a file.", "dlg.stop_before_open_file"), #PB_MessageRequester_Info)
          EndIf
        EndIf
    EndSelect
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 92
; Folding = --
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; EnableOnError
; DisableDebugger
; CompileSourceDirectory
