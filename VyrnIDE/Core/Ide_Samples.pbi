;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - open scripts from examples\vyrn (showcase + api + hello)
; PureBasic 6.41

CompilerIf Defined(Ide_Samples, #PB_Constant) = #False
  #Ide_Samples = #True

  #Ide_SampleMax = 24

  Global Ide_SampleCount.i = 0
  Global Dim Ide_SamplePath.s(#Ide_SampleMax - 1)
  Global Dim Ide_SampleCaption.s(#Ide_SampleMax - 1)

  ; <summary>
  ; Resolve examples\vyrn relative to the IDE exe or repo root.
  ; </summary>
  Procedure.s Ide_Samples_Root()
    Protected dir.s = GetPathPart(ProgramFilename())
    Protected root.s, cand.s
    cand = dir + "examples\vyrn"
    If FileSize(cand + "\hello.vyrn") >= 0
      ProcedureReturn cand
    EndIf
    cand = dir + "..\..\examples\vyrn"
    If FileSize(cand + "\hello.vyrn") >= 0
      ProcedureReturn cand
    EndIf
    root = Ide_Runner_FindRepoRoot()
    If root <> ""
      cand = root + "examples\vyrn"
      If FileSize(cand + "\hello.vyrn") >= 0
        ProcedureReturn cand
      EndIf
    EndIf
    ProcedureReturn ""
  EndProcedure

  ; <summary>
  ; Register one sample path with a menu caption (ignore when the slot table is full).
  ; </summary>
  Procedure Ide_Samples_Register(caption.s, path.s)
    If Ide_SampleCount >= #Ide_SampleMax
      ProcedureReturn
    EndIf
    If FileSize(path) < 0
      ProcedureReturn
    EndIf
    Ide_SampleCaption(Ide_SampleCount) = caption
    Ide_SamplePath(Ide_SampleCount) = path
    Ide_SampleCount + 1
  EndProcedure

  ; <summary>
  ; Rebuild the path table from fixed seeds plus api\*.vyrn.
  ; </summary>
  Procedure Ide_Samples_LoadList()
    Protected root.s, apiDir.s, name.s
    Ide_SampleCount = 0
    root = Ide_Samples_Root()
    If root = ""
      ProcedureReturn
    EndIf
    Ide_Samples_Register("hello.vyrn", root + "\hello.vyrn")
    Ide_Samples_Register("demo.vyrn", root + "\demo.vyrn")
    Ide_Samples_Register("showcase\\json", root + "\showcase\json.vyrn")
    Ide_Samples_Register("showcase\\http", root + "\showcase\http.vyrn")
    Ide_Samples_Register("showcase\\coroutines", root + "\showcase\coroutines.vyrn")
    apiDir = root + "\api"
    If ExamineDirectory(0, apiDir, "*.vyrn")
      While NextDirectoryEntry(0)
        If DirectoryEntryType(0) <> #PB_DirectoryEntry_File
          Continue
        EndIf
        name = DirectoryEntryName(0)
        Ide_Samples_Register("api\\" + name, apiDir + "\" + name)
        If Ide_SampleCount >= #Ide_SampleMax
          Break
        EndIf
      Wend
      FinishDirectory(0)
    EndIf
  EndProcedure

  ; <summary>
  ; Update sample menu item text after the list is built or language changes.
  ; </summary>
  Procedure Ide_Samples_RefreshMenuLabels()
    Protected i.i, label.s
    For i = 0 To #Ide_SampleMax - 1
      If i < Ide_SampleCount
        label = Ide_SampleCaption(i)
        SetMenuItemText(#MENU_MAIN, #MNU_SAMPLE_0 + i, label)
        DisableMenuItem(#MENU_MAIN, #MNU_SAMPLE_0 + i, #False)
      Else
        SetMenuItemText(#MENU_MAIN, #MNU_SAMPLE_0 + i, Ide_I18n_Pick("(n/a)", "sample.na"))
        DisableMenuItem(#MENU_MAIN, #MNU_SAMPLE_0 + i, #True)
      EndIf
    Next
  EndProcedure

  ; <summary>
  ; Call after the main menu exists: load paths and wire labels.
  ; </summary>
  Procedure Ide_Samples_InitMenu()
    Ide_Samples_LoadList()
    Ide_Samples_RefreshMenuLabels()
  EndProcedure

  ; <summary>
  ; Open sample path at index (0..#Ide_SampleMax-1).
  ; </summary>
  Procedure Ide_Samples_OpenIndex(idx.i)
    If idx < 0 Or idx >= Ide_SampleCount
      ProcedureReturn
    EndIf
    If Ide_Editor_LoadFile(Ide_SamplePath(idx))
      Ide_Ui_SetStatus(Ide_I18n_Pick("Opened sample ", "sample.opened") + Ide_SampleCaption(idx))
    EndIf
  EndProcedure

CompilerEndIf