;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - folder tree of .vyrn / .lua under a project root
; PureBasic 6.41

CompilerIf Defined(Ide_Project, #PB_Constant) = #False
  #Ide_Project = #True

  Global Ide_ProjectRoot.s = ""
  Global Ide_ProjectEntry.s = ""
  Global Ide_ProjectEntryRoot.s = ""
  Global Ide_ProjectVisible.i = #False
  Global Ide_ProjectWidth.i = 220
  Global Ide_ProjSplitDragging.i = #False
  Global Ide_ProjLayW.i = -1
  Global Ide_ProjLayH.i = -1
  Global Ide_ProjLayY0.i = -1
  Global Ide_ProjectScanCnt.i = 0
  #Ide_ProjectScanMax = 500
  Global Dim Ide_ProjectScanBuf.s(499)
  #Ide_MinProjectW = 140
  #Ide_MaxProjectW = 480
  #Ide_ProjMruMax = 5
  Global Ide_ProjMruCount.i = 0
  Global Dim Ide_ProjMruPath.s(4)
  Global Dim Ide_ProjEntryPath.s(4)
  Declare.i Ide_Editor_LoadFile(path.s)
  Declare Ide_Project_ListSetRedraw(enableRedraw.i)
  Declare Ide_Project_MruRefreshMenu()
  Declare Ide_Project_MruPush(path.s)
  Declare Ide_Runner_Run()
  Declare Ide_Runner_RunPath(path.s)
  Declare Ide_Runner_ShipForPath(path.s, mode.i)
  Declare Ide_Editor_RevealInExplorer(path.s)

  ; <summary>
  ; Horizontal offset of the editor area when the project panel is shown.
  ; </summary>
  ; <returns>integer</returns>
  Procedure.i Ide_Project_ClientLeft()
    If (Ide_ProjectVisible And Ide_ProjectRoot <> "") Or Ide_OutlineVisible
      If IsGadget(#GAD_PROJECT) Or IsGadget(#GAD_OUTLINE)
        ProcedureReturn Ide_ProjectWidth + #Ide_SplitVW
      EndIf
    EndIf
    ProcedureReturn 0
  EndProcedure

  ; <summary>
  ; True when the left project/outline column is shown (vertical split active).
  ; </summary>
  ; <returns>integer</returns>
  Procedure.i Ide_Project_SideColumnActive()
    If (Ide_ProjectVisible And Ide_ProjectRoot <> "") Or Ide_OutlineVisible
      If IsGadget(#GAD_PROJECT) Or IsGadget(#GAD_OUTLINE)
        ProcedureReturn #True
      EndIf
    EndIf
    ProcedureReturn #False
  EndProcedure

  ; <summary>
  ; Mouse is over the vertical split band (project vs editor).
  ; </summary>
  ; <returns>integer</returns>
  Procedure.i Ide_Project_PointerOnWidthSplit()
    Protected mx.i, my.i, gx.i, gy.i, gw.i, gh.i
    If Ide_SplitDragging
      ProcedureReturn #False
    EndIf
    If Ide_Project_SideColumnActive() = #False Or IsGadget(#GAD_SPLIT_V) = 0
      ProcedureReturn #False
    EndIf
    If GadgetHeight(#GAD_SPLIT_V) < 4
      ProcedureReturn #False
    EndIf
    mx = WindowMouseX(#WIN_IDE)
    my = WindowMouseY(#WIN_IDE)
    If my >= Ide_Ui_SplitterClientY() - 2
      ProcedureReturn #False
    EndIf
    gx = GadgetX(#GAD_SPLIT_V, #PB_Gadget_WindowCoordinate)
    gy = GadgetY(#GAD_SPLIT_V, #PB_Gadget_WindowCoordinate)
    gw = GadgetWidth(#GAD_SPLIT_V)
    gh = GadgetHeight(#GAD_SPLIT_V)
    If mx >= gx - #Ide_SplitVHit And mx <= gx + gw + #Ide_SplitVHit
      If my >= gy - 2 And my < gy + gh + 2
        ProcedureReturn #True
      EndIf
    EndIf
    ProcedureReturn #False
  EndProcedure

  ; <summary>
  ; Keep project column width within min/max and editor minimum width.
  ; </summary>
  ; <param name="ww">Main window client width.</param>
  Procedure Ide_Project_ClampWidth(ww.i)
    Protected maxW.i
    If Ide_Project_SideColumnActive() = #False
      ProcedureReturn
    EndIf
    maxW = ww - 200 - #Ide_SplitVW
    If maxW > #Ide_MaxProjectW
      maxW = #Ide_MaxProjectW
    EndIf
    If maxW < #Ide_MinProjectW
      maxW = #Ide_MinProjectW
    EndIf
    If Ide_ProjectWidth > maxW
      Ide_ProjectWidth = maxW
    EndIf
    If Ide_ProjectWidth < #Ide_MinProjectW
      Ide_ProjectWidth = #Ide_MinProjectW
    EndIf
  EndProcedure

  ; <summary>
  ; Begin dragging the project/outline vertical split.
  ; </summary>
  Procedure.i Ide_Project_WidthDragging()
    ProcedureReturn Ide_ProjSplitDragging
  EndProcedure

  ; <summary>
  ; Ide_Project_BeginWidthDrag
  ; </summary>
  Procedure Ide_Project_BeginWidthDrag()
    Ide_ProjSplitDragging = #True
    Ide_SplitVHover = #False
    Ide_SplitHHover = #False
    If IsGadget(#GAD_SPLIT)
      HideGadget(#GAD_SPLIT, #True)
      DisableGadget(#GAD_SPLIT, #True)
    EndIf
    Ide_Project_WidthDragTo(WindowMouseX(#WIN_IDE))
  EndProcedure

  ; <summary>
  ; End vertical split drag and persist width.
  ; </summary>
  Procedure Ide_Project_EndWidthDrag()
    If Ide_ProjSplitDragging = 0
      ProcedureReturn
    EndIf
    Ide_ProjSplitDragging = #False
    If IsGadget(#GAD_SPLIT)
      DisableGadget(#GAD_SPLIT, #False)
    EndIf
    Ide_ProjLayW = -1
    Ide_ProjLayH = -1
    Ide_ProjLayY0 = -1
    Ide_Editor_SavePrefs()
    Ide_Ui_Layout()
    Ide_Editor_ResizeEditors()
    Ide_Project_ListSetRedraw(#True)
  EndProcedure

  ; <summary>
  ; Resize project column while dragging the vertical split (mouse X in client coords).
  ; </summary>
  ; <param name="clientX">integer</param>
  Procedure Ide_Project_WidthDragTo(clientX.i)
    Protected ww.i, maxW.i, w.i
    If Ide_ProjSplitDragging = 0
      ProcedureReturn
    EndIf
    ww = WindowWidth(#WIN_IDE)
    maxW = ww - 200 - #Ide_SplitVW
    If maxW > #Ide_MaxProjectW
      maxW = #Ide_MaxProjectW
    EndIf
    If maxW < #Ide_MinProjectW
      maxW = #Ide_MinProjectW
    EndIf
    w = clientX
    If w > maxW
      w = maxW
    EndIf
    If w < #Ide_MinProjectW
      w = #Ide_MinProjectW
    EndIf
    If w = Ide_ProjectWidth
      ProcedureReturn
    EndIf
    Ide_ProjectWidth = w
    Ide_Ui_Layout()
    Ide_Editor_ResizeEditors()
    Ide_Ui_InvalidateEditorColumn()
  EndProcedure

  ; <summary>
  ; Suppress ListIcon full repaints while the project column width is dragged (Windows).
  ; </summary>
  ; <param name="enableRedraw">#True to resume painting and refresh once.</param>
  Procedure Ide_Project_ListSetRedraw(enableRedraw.i)
    Protected hwnd.i, u32.i, fnMsg.i, fnInv.i
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      If IsGadget(#GAD_PROJECT) = #False
        ProcedureReturn
      EndIf
      hwnd = GadgetID(#GAD_PROJECT)
      If hwnd = 0
        ProcedureReturn
      EndIf
      u32 = OpenLibrary(#PB_Any, "user32.dll")
      If u32 = 0
        ProcedureReturn
      EndIf
      fnMsg = GetFunction(u32, "SendMessageW")
      If fnMsg = 0
        fnMsg = GetFunction(u32, "SendMessageA")
      EndIf
      fnInv = GetFunction(u32, "InvalidateRect")
      If fnMsg
        CallFunctionFast(fnMsg, hwnd, 11, enableRedraw, 0)
      EndIf
      If enableRedraw And fnInv
        CallFunctionFast(fnInv, hwnd, 0, 0)
      EndIf
      CloseLibrary(u32)
    CompilerEndIf
  EndProcedure

  ; <summary>
  ; Show/hide and position the project list during main window layout.
  ; </summary>
  ; <param name="top">integer</param>
  ; <param name="findH">integer</param>
  ; <param name="editorH">integer</param>
  Procedure Ide_Project_LayoutPanel(top.i, findH.i, editorH.i)
    Protected ph.i, oh.i, y0.i = top + findH
    Protected projOn.i = #False
    Protected freezeList.i = #False
    If Ide_ProjectVisible And Ide_ProjectRoot <> ""
      projOn = #True
    EndIf
    ph = 0
    oh = 0
    If Ide_OutlineVisible And IsGadget(#GAD_OUTLINE)
      If projOn
        ; Project + Outline: split column (project top, symbol outline ~#Ide_SideSplit at bottom).
        oh = #Ide_SideSplit
        If oh > editorH / 2
          oh = editorH / 2
        EndIf
        ph = editorH - oh
        If ph < 80
          ph = 80
          oh = editorH - ph
        EndIf
      Else
        ; Outline only: full editor-column height.
        oh = editorH
        ph = 0
      EndIf
    ElseIf projOn
      ph = editorH
    EndIf
    If IsGadget(#GAD_PROJECT)
      If Ide_Project_WidthDragging() = 0
        HideGadget(#GAD_PROJECT, Bool(Ide_ProjectVisible = 0 Or Ide_ProjectRoot = ""))
      EndIf
      If Ide_ProjectVisible And Ide_ProjectRoot <> ""
        If Ide_ProjectWidth <> Ide_ProjLayW Or ph <> Ide_ProjLayH Or y0 <> Ide_ProjLayY0
          If Ide_Project_WidthDragging()
            freezeList = #True
            Ide_Project_ListSetRedraw(#False)
          EndIf
          ResizeGadget(#GAD_PROJECT, 0, y0, Ide_ProjectWidth, ph)
          Ide_ProjLayW = Ide_ProjectWidth
          Ide_ProjLayH = ph
          Ide_ProjLayY0 = y0
          If freezeList
            Ide_Project_ListSetRedraw(#True)
          EndIf
        EndIf
      Else
        Ide_ProjLayW = -1
        Ide_ProjLayH = -1
        Ide_ProjLayY0 = -1
      EndIf
    EndIf
    If IsGadget(#GAD_OUTLINE)
      If Ide_Project_WidthDragging() = 0
        HideGadget(#GAD_OUTLINE, Bool(Ide_OutlineVisible = 0))
      EndIf
      If Ide_OutlineVisible
        ResizeGadget(#GAD_OUTLINE, 0, y0 + ph, Ide_ProjectWidth, oh)
      EndIf
    EndIf
  EndProcedure

  ; <summary>
  ; Remove all rows from the project ListIcon gadget.
  ; </summary>
  Procedure Ide_Project_ClearList()
    If IsGadget(#GAD_PROJECT) = #False
      ProcedureReturn
    EndIf
    ClearGadgetItems(#GAD_PROJECT)
  EndProcedure

  ; <summary>
  ; Record one script path during scan (sorted when filling the list).
  ; </summary>
  ; <param name="fullPath">string</param>
  Procedure Ide_Project_AddScriptPath(fullPath.s)
    If Ide_ProjectScanCnt >= #Ide_ProjectScanMax
      ProcedureReturn
    EndIf
    If LCase(Right(fullPath, 5)) <> ".vyrn" And LCase(Right(fullPath, 4)) <> ".lua"
      ProcedureReturn
    EndIf
    If Ide_ProjectVyrnOnly And LCase(Right(fullPath, 5)) <> ".vyrn"
      ProcedureReturn
    EndIf
    Ide_ProjectScanBuf(Ide_ProjectScanCnt) = fullPath
    Ide_ProjectScanCnt + 1
  EndProcedure

  ; <summary>
  ; Sort scan buffer by file name (Case-insensitive), then path As tie-breaker.
  ; </summary>
  Procedure Ide_Project_SortScanBuf()
    Protected i.i, j.i, t.s, na.s, nb.s
    For i = 1 To Ide_ProjectScanCnt - 1
      j = i
      While j > 0
        na = LCase(GetFilePart(Ide_ProjectScanBuf(j - 1)))
        nb = LCase(GetFilePart(Ide_ProjectScanBuf(j)))
        If na = nb
          na = LCase(Ide_ProjectScanBuf(j - 1))
          nb = LCase(Ide_ProjectScanBuf(j))
        EndIf
        If na <= nb
          Break
        EndIf
        t = Ide_ProjectScanBuf(j - 1)
        Ide_ProjectScanBuf(j - 1) = Ide_ProjectScanBuf(j)
        Ide_ProjectScanBuf(j) = t
        j - 1
      Wend
    Next
  EndProcedure

  ; <summary>
  ; Push sorted scan buffer into #GAD_PROJECT.
  ; </summary>
  Procedure Ide_Project_FillListFromScan()
    Protected i.i, fullPath.s
    For i = 0 To Ide_ProjectScanCnt - 1
      fullPath = Ide_ProjectScanBuf(i)
      If Ide_ProjectEntry <> "" And LCase(fullPath) = LCase(Ide_ProjectEntry)
        AddGadgetItem(#GAD_PROJECT, -1, Ide_I18n_Pick("* ", "project.entry_mark") + GetFilePart(fullPath))
      Else
        AddGadgetItem(#GAD_PROJECT, -1, GetFilePart(fullPath))
      EndIf
      SetGadgetItemText(#GAD_PROJECT, CountGadgetItems(#GAD_PROJECT) - 1, fullPath, 1)
    Next
  EndProcedure

  ; <summary>
  ; Depth-first scan of a folder for .vyrn / .lua files.
  ; </summary>
  ; <param name="dir">string</param>
  Procedure Ide_Project_ScanDir(dir.s)
    Protected name.s, sub.s
    If Ide_ProjectScanCnt >= #Ide_ProjectScanMax
      ProcedureReturn
    EndIf
    If Right(dir, 1) <> "\" And Right(dir, 1) <> "/"
      dir = dir + "\"
    EndIf
    If ExamineDirectory(0, dir, "*.*") = 0
      ProcedureReturn
    EndIf
    While NextDirectoryEntry(0)
      name = DirectoryEntryName(0)
      Select DirectoryEntryType(0)
        Case #PB_DirectoryEntry_File
          Ide_Project_AddScriptPath(dir + name)
        Case #PB_DirectoryEntry_Directory
          If name <> "." And name <> ".."
            Ide_Project_ScanDir(dir + name)
          EndIf
      EndSelect
      If Ide_ProjectScanCnt >= #Ide_ProjectScanMax
        Break
      EndIf
    Wend
    FinishDirectory(0)
  EndProcedure

  ; <summary>
  ; Recursively add script files under Ide_ProjectRoot to the list gadget.
  ; </summary>
  Procedure Ide_Project_Refresh()
    Protected dir.s
    If IsGadget(#GAD_PROJECT) = #False
      ProcedureReturn
    EndIf
    Ide_Project_ClearList()
    If Ide_ProjectRoot = ""
      ProcedureReturn
    EndIf
    dir = Ide_ProjectRoot
    Ide_ProjectScanCnt = 0
    Ide_Project_ScanDir(dir)
    Ide_Project_SortScanBuf()
    Ide_Project_FillListFromScan()
    If Ide_ProjectScanCnt >= #Ide_ProjectScanMax
      AddGadgetItem(#GAD_PROJECT, -1, "(truncated...)")
    EndIf
  EndProcedure

  ; <summary>
  ; Prompt for a project root, refresh the file list, and show the panel.
  ; </summary>
  Procedure Ide_Project_OpenFolder()
    Protected picked.s = Ide_ProjectRoot
    If picked = ""
      picked = GetHomeDirectory()
    EndIf
    picked = InputRequester("Open Project Folder", "Project root directory:", picked)
    If picked = ""
      ProcedureReturn
    EndIf
    If Right(picked, 1) <> "\" And Right(picked, 1) <> "/"
      picked = picked + "\"
    EndIf
    Ide_ProjectRoot = picked
    Ide_ProjectVisible = #True
    Ide_Project_Refresh()
    HideGadget(#GAD_PROJECT, #False)
    SetMenuItemState(#MENU_MAIN, #MNU_PROJECT_PANEL, #True)
    Ide_Ui_Layout()
    Ide_Editor_ResizeEditors()
    Ide_Editor_SavePrefs()
    Ide_Project_MruPush(Ide_ProjectRoot)
    Ide_Ui_SetStatus(Ide_I18n_Fmt1("Project {root}", "status.project", "{root}", Ide_ProjectRoot))
  EndProcedure

  ; <summary>
  ; Show or hide the project panel (opens folder dialog when no root is set).
  ; </summary>
  Procedure Ide_Project_TogglePanel()
    If Ide_ProjectRoot = ""
      Ide_Project_OpenFolder()
      ProcedureReturn
    EndIf
    Ide_ProjectVisible = Bool(Ide_ProjectVisible = 0)
    HideGadget(#GAD_PROJECT, Bool(Ide_ProjectVisible = 0))
    SetMenuItemState(#MENU_MAIN, #MNU_PROJECT_PANEL, Ide_ProjectVisible)
    Ide_Ui_Layout()
    Ide_Editor_ResizeEditors()
    Ide_Editor_SavePrefs()
  EndProcedure

  ; <summary>
  ; Double-click handler: open the script path stored in column 1.
  ; </summary>
  ; <param name="root">string</param>
  Procedure Ide_Project_ApplyEntryForRoot(root.s)
    Protected i.i
    Ide_ProjectEntry = ""
    For i = 0 To Ide_ProjMruCount - 1
      If LCase(Ide_ProjMruPath(i)) = LCase(root)
        If Ide_ProjEntryPath(i) <> "" And FileSize(Ide_ProjEntryPath(i)) >= 0
          Ide_ProjectEntry = Ide_ProjEntryPath(i)
          Ide_ProjectEntryRoot = root
        EndIf
        ProcedureReturn
      EndIf
    Next
    If Ide_ProjectEntryRoot <> "" And LCase(Ide_ProjectEntryRoot) = LCase(root) And FileSize(Ide_ProjectEntry) >= 0
      ProcedureReturn
    EndIf
    Ide_ProjectEntryRoot = root
  EndProcedure
  
  ; <summary>
  ; Ide_Project_PersistEntryForRoot
  ; </summary>
  ; <param name="root">string</param>
  ; <param name="script">string</param>
  Procedure Ide_Project_PersistEntryForRoot(root.s, script.s)
    Protected i.i
    If root = "" Or script = ""
      ProcedureReturn
    EndIf
    For i = 0 To Ide_ProjMruCount - 1
      If LCase(Ide_ProjMruPath(i)) = LCase(root)
        Ide_ProjEntryPath(i) = script
        Ide_ProjectEntry = script
        Ide_ProjectEntryRoot = root
        Ide_Editor_SavePrefs()
        ProcedureReturn
      EndIf
    Next
    Ide_ProjectEntry = script
    Ide_ProjectEntryRoot = root
    Ide_Editor_SavePrefs()
  EndProcedure
  
  ; <summary>
  ; Ide_Project_SetRoot
  ; </summary>
  ; <param name="path">string</param>
  Procedure Ide_Project_SetRoot(path.s)
    Protected picked.s = Trim(path)
    If picked = ""
      ProcedureReturn
    EndIf
    If Right(picked, 1) <> "\" And Right(picked, 1) <> "/"
      picked = picked + "\"
    EndIf
    Ide_ProjectRoot = picked
    Ide_ProjectVisible = #True
    Ide_Project_Refresh()
    HideGadget(#GAD_PROJECT, #False)
    SetMenuItemState(#MENU_MAIN, #MNU_PROJECT_PANEL, #True)
    Ide_Project_MruPush(picked)
    Ide_Project_ApplyEntryForRoot(picked)
    Ide_Ui_Layout()
    Ide_Editor_ResizeEditors()
    Ide_Editor_SavePrefs()
    Ide_Ui_SetStatus(Ide_I18n_Pick("Project ", "project.set") + picked)
  EndProcedure

  ; <summary>
  ; IDE: Project MruPush.
  ; </summary>
  ; <param name="paths">see signature</param>
  Procedure Ide_Project_MruPush(path.s)
    Protected i.i, j.i
    If path = ""
      ProcedureReturn
    EndIf
    For i = 0 To Ide_ProjMruCount - 1
      If LCase(Ide_ProjMruPath(i)) = LCase(path)
        For j = i To Ide_ProjMruCount - 2
          Ide_ProjMruPath(j) = Ide_ProjMruPath(j + 1)
        Next
        If Ide_ProjMruCount > 0
          Ide_ProjMruCount - 1
        EndIf
        Break
      EndIf
    Next
    If Ide_ProjMruCount < #Ide_ProjMruMax
      Ide_ProjMruPath(Ide_ProjMruCount) = path
      Ide_ProjMruCount + 1
    Else
      For j = 0 To #Ide_ProjMruMax - 2
        Ide_ProjMruPath(j) = Ide_ProjMruPath(j + 1)
      Next
      Ide_ProjMruPath(#Ide_ProjMruMax - 1) = path
    EndIf
    Ide_Project_MruRefreshMenu()
  EndProcedure

  ; <summary>
  ; IDE: Project MruRefreshMenu.
  ; </summary>
  Procedure Ide_Project_MruRefreshMenu()
    Protected i.i, cap.s
    For i = 0 To #Ide_ProjMruMax - 1
      If i < Ide_ProjMruCount
        cap = Ide_ProjMruPath(i)
        If Len(cap) > 48
          cap = "..." + Right(cap, 45)
        EndIf
        SetMenuItemText(#MENU_MAIN, #MNU_PROJ_MRU_0 + i, cap)
        DisableMenuItem(#MENU_MAIN, #MNU_PROJ_MRU_0 + i, #False)
      Else
        SetMenuItemText(#MENU_MAIN, #MNU_PROJ_MRU_0 + i, Ide_I18n_Pick("(none)", "project.mru_none"))
        DisableMenuItem(#MENU_MAIN, #MNU_PROJ_MRU_0 + i, #True)
      EndIf
    Next
  EndProcedure

  ; <summary>
  ; IDE: Project MruOpen.
  ; </summary>
  ; <param name="idxi">see signature</param>
  Procedure Ide_Project_MruOpen(idx.i)
    If idx < 0 Or idx >= Ide_ProjMruCount
      ProcedureReturn
    EndIf
    Ide_Project_SetRoot(Ide_ProjMruPath(idx))
  EndProcedure

  ; <summary>
  ; IDE: Project SelectedPath.
  ; </summary>
  ; <returns>string</returns>
  Procedure.s Ide_Project_SelectedPath()
    Protected idx.i, path.s
    If IsGadget(#GAD_PROJECT) = #False
      ProcedureReturn ""
    EndIf
    idx = GetGadgetState(#GAD_PROJECT)
    If idx < 0
      ProcedureReturn ""
    EndIf
    path = GetGadgetItemText(#GAD_PROJECT, idx, 1)
    If path = "" Or Left(path, 1) = "("
      ProcedureReturn ""
    EndIf
    ProcedureReturn path
  EndProcedure

  ; <summary>
  ; IDE: Project HandlePopup.
  ; </summary>
  ; <param name="menuIdi">see signature</param>
  Procedure Ide_Project_HandlePopup(menuId.i)
    Protected path.s = Ide_Project_SelectedPath()
    If path = ""
      ProcedureReturn
    EndIf
    Select menuId
      Case #POP_PROJ_OPEN
        Ide_Editor_LoadFile(path)
      Case #POP_PROJ_RUN
        If Ide_Editor_LoadFile(path)
          Ide_Runner_Run()
        EndIf
      Case #POP_PROJ_SET_ENTRY
        Ide_Project_PersistEntryForRoot(Ide_ProjectRoot, path)
        Ide_Project_Refresh()
        Ide_Ui_SetStatus(Ide_I18n_Fmt1("Entry script: {path}", "project.entry_set", "{path}", path))
      Case #POP_PROJ_SHIP
        Ide_Runner_ShipForPath(path, 1)
      Case #POP_PROJ_REVEAL
        Ide_Editor_RevealInExplorer(path)
      Case #POP_PROJ_COPY
        SetClipboardText(path)
        Ide_Ui_SetStatus(Ide_I18n_Pick("Copied path", "project.copied"))
    EndSelect
  EndProcedure

  ; <summary>
  ; IDE: Project PopupAtRow.
  ; </summary>
  ; <param name="rowi">see signature</param>
  Procedure Ide_Project_PopupAtRow(row.i)
    Protected mx.i, my.i
    If row < 0
      ProcedureReturn
    EndIf
    SetGadgetState(#GAD_PROJECT, row)
    DisplayPopupMenu(#POP_PROJECT, WindowID(#WIN_IDE))
  EndProcedure

  ; <summary>
  ; IDE: Project ToggleVyrnFilter.
  ; </summary>
  Procedure Ide_Project_ToggleVyrnFilter()
    Ide_ProjectVyrnOnly = Bool(Ide_ProjectVyrnOnly = 0)
    SetMenuItemState(#MENU_MAIN, #MNU_PROJECT_VYRN_ONLY, Ide_ProjectVyrnOnly)
    If Ide_ProjectRoot <> ""
      Ide_Project_Refresh()
    EndIf
    Ide_Editor_SavePrefs()
    If Ide_ProjectVyrnOnly
      Ide_Ui_SetStatus(Ide_I18n_Pick("Project list: .vyrn only", "status.proj_vyrn"))
    Else
      Ide_Ui_SetStatus(Ide_I18n_Pick("Project list: .vyrn and .lua", "status.proj_all"))
    EndIf
  EndProcedure

  ; <summary>
  ; IDE: Project OnListActivate.
  ; </summary>
  Procedure Ide_Project_OnListActivate()
    Protected idx.i, path.s
    If IsGadget(#GAD_PROJECT) = #False
      ProcedureReturn
    EndIf
    idx = GetGadgetState(#GAD_PROJECT)
    If idx < 0
      ProcedureReturn
    EndIf
    path = GetGadgetItemText(#GAD_PROJECT, idx, 1)
    If path = "" Or Left(path, 1) = "("
      ProcedureReturn
    EndIf
    If Ide_Editor_LoadFile(path)
      Ide_Ui_SetStatus(Ide_I18n_Fmt1("Opened {path}", "status.opened", "{path}", path))
    EndIf
  EndProcedure

  ; <summary>
  ; Run the configured project entry script (F5 on that file).
  ; </summary>
  Procedure Ide_Project_RunEntry()
    Protected path.s = Ide_ProjectEntry
    If path = "" And Ide_ProjectRoot <> ""
      path = Ide_ProjectRoot + "main.vyrn"
      If FileSize(path) < 0
        path = Ide_ProjectRoot + "Main.vyrn"
      EndIf
    EndIf
    If path = "" Or FileSize(path) < 0
      MessageRequester(Ide_I18n_AppTitle(), Ide_I18n_Pick("Set an entry script (project right-click) or add main.vyrn under the project root.", "project.entry_missing"), #PB_MessageRequester_Info)
      ProcedureReturn
    EndIf
    Ide_Editor_LoadFile(path)
    Ide_Runner_RunPath(path)
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 36
; FirstLine = 4
; Folding = ----
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)