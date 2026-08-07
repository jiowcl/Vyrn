;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - Scintilla editor helpers
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
  
  CompilerIf Defined(STYLE_DEFAULT, #PB_Constant) = #False
    #STYLE_DEFAULT = 32
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
  CompilerIf Defined(SCI_MARKERSETFORE, #PB_Constant) = #False
    #SCI_MARKERSETFORE = 2041
  CompilerEndIf
  CompilerIf Defined(SCI_MARKERSETBACK, #PB_Constant) = #False
    #SCI_MARKERSETBACK = 2042
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

  #Ide_MarkError = 1
  #Ide_MarkWarn = 2
  #Ide_MarkErrorBack = 3
  #Ide_MarkWarnBack = 4
  #Ide_MarginSymbol = 1

  Global Ide_FilePath.s = ""
  Global Ide_NeedRestyle.i = #False
  Global Ide_TitleBase.s = "Vyrn IDE"

  Declare Ide_Editor_UpdateTitle()
  Declare Ide_Editor_UpdateCaretStatus()
  Declare.i Ide_Cmd_Save()
  
  ; <summary>
  ; Ide_ScintillaCallback
  ; </summary>
  ; <param name="Gadget">integer</param>
  ; <param name="*notify">struct</param>
  ; <returns>Returns void.</returns>
  Procedure Ide_ScintillaCallback(Gadget, *notify.SCNotification)
    Protected code.i, modType.i
    
    If Gadget <> #GAD_EDITOR Or *notify = 0
      ProcedureReturn
    EndIf
    
    code = *notify\nmhdr\code
    
    If code = #SCN_MODIFIED
      modType = *notify\modificationType
      
      If modType & (#SC_MOD_INSERTTEXT | #SC_MOD_DELETETEXT)
        Ide_NeedRestyle = #True
        Ide_Editor_UpdateTitle()
      EndIf
    ElseIf code = #SCN_UPDATEUI
      Ide_Editor_UpdateCaretStatus()
    EndIf
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_Create
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Editor_Create()
    Protected *font
    
    ScintillaGadget(#GAD_EDITOR, 0, #Ide_ToolbarH, 100, 100, @Ide_ScintillaCallback())
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETCODEPAGE, #SC_CP_UTF8)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETMARGINTYPEN, 0, #SC_MARGIN_NUMBER)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETMARGINWIDTHN, 0, 48)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETMARGINTYPEN, #Ide_MarginSymbol, #SC_MARGIN_SYMBOL)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETMARGINWIDTHN, #Ide_MarginSymbol, 16)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETMARGINMASKN, #Ide_MarginSymbol, (1 << #Ide_MarkError) | (1 << #Ide_MarkWarn))
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETTABWIDTH, 2)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETUSETABS, 0)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETSCROLLWIDTHTRACKING, 1)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETEOLMODE, #SC_EOL_LF)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETMODEVENTMASK, #SC_MOD_INSERTTEXT | #SC_MOD_DELETETEXT)

    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERDEFINE, #Ide_MarkError, #SC_MARK_SHORTARROW)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERSETFORE, #Ide_MarkError, RGB(200, 0, 0))
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERSETBACK, #Ide_MarkError, RGB(200, 0, 0))
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERDEFINE, #Ide_MarkWarn, #SC_MARK_SHORTARROW)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERSETFORE, #Ide_MarkWarn, RGB(180, 120, 0))
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERSETBACK, #Ide_MarkWarn, RGB(220, 160, 0))
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERDEFINE, #Ide_MarkErrorBack, #SC_MARK_BACKGROUND)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERSETBACK, #Ide_MarkErrorBack, RGB(255, 220, 220))
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERDEFINE, #Ide_MarkWarnBack, #SC_MARK_BACKGROUND)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERSETBACK, #Ide_MarkWarnBack, RGB(255, 244, 200))

    *font = UTF8("Consolas")
    
    If *font
      ScintillaSendMessage(#GAD_EDITOR, #SCI_STYLESETFONT, #STYLE_DEFAULT, *font)
      FreeMemory(*font)
    EndIf
    
    ScintillaSendMessage(#GAD_EDITOR, #SCI_STYLESETSIZE, #STYLE_DEFAULT, 11)
    Ide_Highlight_ApplyStyles(#GAD_EDITOR)
  EndProcedure

  Procedure Ide_Editor_ClearDiagnostics()
    If IsGadget(#GAD_EDITOR) = 0
      ProcedureReturn
    EndIf
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERDELETEALL, #Ide_MarkError)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERDELETEALL, #Ide_MarkWarn)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERDELETEALL, #Ide_MarkErrorBack)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERDELETEALL, #Ide_MarkWarnBack)
  EndProcedure

  ; lineNo is 1-based.
  Procedure Ide_Editor_GotoDiagnostic(lineNo.i, isWarn.i = #False)
    Protected lineCount.i, line0.i, pos.i, endPos.i
    If IsGadget(#GAD_EDITOR) = 0 Or lineNo < 1
      ProcedureReturn
    EndIf
    lineCount = ScintillaSendMessage(#GAD_EDITOR, #SCI_GETLINECOUNT)
    If lineNo > lineCount
      lineNo = lineCount
    EndIf
    line0 = lineNo - 1
    Ide_Editor_ClearDiagnostics()
    If isWarn
      ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERADD, line0, #Ide_MarkWarn)
      ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERADD, line0, #Ide_MarkWarnBack)
    Else
      ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERADD, line0, #Ide_MarkError)
      ScintillaSendMessage(#GAD_EDITOR, #SCI_MARKERADD, line0, #Ide_MarkErrorBack)
    EndIf
    ScintillaSendMessage(#GAD_EDITOR, #SCI_ENSUREVISIBLEENFORCEPOLICY, line0)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_GOTOLINE, line0)
    pos = ScintillaSendMessage(#GAD_EDITOR, #SCI_POSITIONFROMLINE, line0)
    endPos = ScintillaSendMessage(#GAD_EDITOR, #SCI_GETLINEENDPOSITION, line0)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETSEL, pos, endPos)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SCROLLCARET)
    Ide_Editor_UpdateCaretStatus()
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_GetText
  ; </summary>
  ; <returns>Returns string.</returns>
  Procedure.s Ide_Editor_GetText()
    Protected length.i = ScintillaSendMessage(#GAD_EDITOR, #SCI_GETLENGTH)
    Protected *buf, text.s
    
    If length < 0
      ProcedureReturn ""
    EndIf
    
    *buf = AllocateMemory(length + 1)
    
    If *buf = 0
      ProcedureReturn ""
    EndIf
    
    ScintillaSendMessage(#GAD_EDITOR, #SCI_GETTEXT, length + 1, *buf)
    text = PeekS(*buf, -1, #PB_UTF8)
    
    FreeMemory(*buf)
    
    ProcedureReturn text
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_SetText
  ; </summary>
  ; <param name="text">string</param>
  ; <returns>Returns void.</returns>
  Procedure Ide_Editor_SetText(text.s)
    Protected *utf = UTF8(text)
    
    If *utf
      ScintillaSendMessage(#GAD_EDITOR, #SCI_SETTEXT, 0, *utf)
      FreeMemory(*utf)
    Else
      ScintillaSendMessage(#GAD_EDITOR, #SCI_CLEARALL)
    EndIf
    
    ScintillaSendMessage(#GAD_EDITOR, #SCI_EMPTYUNDOBUFFER)
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETSAVEPOINT)
    Ide_Highlight_Restyle(#GAD_EDITOR)
    Ide_NeedRestyle = #False
    Ide_Editor_UpdateTitle()
    Ide_Editor_UpdateCaretStatus()
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_IsModified
  ; </summary>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Editor_IsModified()
    ProcedureReturn ScintillaSendMessage(#GAD_EDITOR, #SCI_GETMODIFY)
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_UpdateTitle
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Editor_UpdateTitle()
    Protected title.s = Ide_TitleBase
    Protected name.s
    
    If Ide_FilePath <> ""
      name = GetFilePart(Ide_FilePath)
    Else
      name = "untitled.vyrn"
    EndIf
    
    title = name + " - " + Ide_TitleBase
    
    If Ide_Editor_IsModified()
      title = "* " + title
    EndIf
    
    SetWindowTitle(#WIN_IDE, title)
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_UpdateCaretStatus
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Editor_UpdateCaretStatus()
    Protected pos.i = ScintillaSendMessage(#GAD_EDITOR, #SCI_GETCURRENTPOS)
    Protected line.i = ScintillaSendMessage(#GAD_EDITOR, #SCI_LINEFROMPOSITION, pos) + 1
    Protected col.i = ScintillaSendMessage(#GAD_EDITOR, #SCI_GETCOLUMN, pos) + 1
    Protected pathHint.s
    
    If Ide_FilePath <> ""
      pathHint = Ide_FilePath
    Else
      pathHint = "untitled.vyrn"
    EndIf
    
    Ide_Ui_SetStatus("Ln " + Str(line) + " Col " + Str(col) + " | " + pathHint + " | Vyrn " + Ide_Vyrn_ProductVersion())
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_New
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Editor_New()
    Ide_FilePath = ""
    Ide_Editor_SetText("-- vyrn: 12" + Chr(10) + Chr(10) + "print(" + Chr(34) + "Hello, Vyrn!" + Chr(34) + ")" + Chr(10))
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_LoadFile
  ; </summary>
  ; <param name="path">string</param>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Editor_LoadFile(path.s)
    Protected src.s = ""
    Protected f.i, line.s
    
    If path = "" Or FileSize(path) < 0
      ProcedureReturn #False
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
    
    ; Strip UTF-8 BOM
    If Len(src) >= 3 And Asc(Mid(src, 1, 1)) = 239 And Asc(Mid(src, 2, 1)) = 187 And Asc(Mid(src, 3, 1)) = 191
      src = Mid(src, 4)
    EndIf
    
    Ide_FilePath = path
    Ide_Editor_SetText(src)
    
    ProcedureReturn #True
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_SaveTo
  ; </summary>
  ; <param name="path">string</param>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Editor_SaveTo(path.s)
    Protected f.i, text.s
    
    If path = ""
      ProcedureReturn #False
    EndIf
    
    text = Ide_Editor_GetText()
    f = CreateFile(#PB_Any, path)
    
    If f = 0
      ProcedureReturn #False
    EndIf
    
    WriteString(f, text, #PB_UTF8)
    CloseFile(f)
    Ide_FilePath = path
    ScintillaSendMessage(#GAD_EDITOR, #SCI_SETSAVEPOINT)
    Ide_Editor_UpdateTitle()
    Ide_Editor_UpdateCaretStatus()
    
    ProcedureReturn #True
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_ConfirmSaveIfNeeded
  ; </summary>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Editor_ConfirmSaveIfNeeded()
    Protected r.i
    
    If Ide_Editor_IsModified() = 0
      ProcedureReturn #True
    EndIf
    
    r = MessageRequester("Vyrn IDE", "Save changes before continuing?", #PB_MessageRequester_YesNoCancel)
    
    If r = #PB_MessageRequester_Cancel
      ProcedureReturn #False
    EndIf
    
    If r = #PB_MessageRequester_Yes
      ProcedureReturn Ide_Cmd_Save()
    EndIf
    
    ProcedureReturn #True
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_Undo
  ; </summary>
  Procedure Ide_Editor_Undo()
    ScintillaSendMessage(#GAD_EDITOR, #SCI_UNDO)
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_Redo
  ; </summary>
  Procedure Ide_Editor_Redo()
    ScintillaSendMessage(#GAD_EDITOR, #SCI_REDO)
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_Cut
  ; </summary>
  Procedure Ide_Editor_Cut()
    ScintillaSendMessage(#GAD_EDITOR, #SCI_CUT)
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_Copy
  ; </summary>
  Procedure Ide_Editor_Copy()
    ScintillaSendMessage(#GAD_EDITOR, #SCI_COPY)
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_Paste
  ; </summary>
  Procedure Ide_Editor_Paste()
    ScintillaSendMessage(#GAD_EDITOR, #SCI_PASTE)
  EndProcedure
  
  ; <summary>
  ; Ide_Editor_PollRestyle
  ; </summary>
  Procedure Ide_Editor_PollRestyle()
    If Ide_NeedRestyle
      Ide_Highlight_Restyle(#GAD_EDITOR)
      Ide_NeedRestyle = #False
    EndIf
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 354
; FirstLine = 313
; Folding = -----
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; EnableOnError
; DisableDebugger
; CompileSourceDirectory