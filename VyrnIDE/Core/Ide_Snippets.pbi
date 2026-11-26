;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - insert common Vyrn code templates at the cursor
; PureBasic 6.41

CompilerIf Defined(Ide_Snippets, #PB_Constant) = #False
  #Ide_Snippets = #True

  ; <summary>
  ; Insert UTF-8 text at the current Scintilla caret.
  ; </summary>
  ; <param name="text">string</param>
  Procedure Ide_Snippets_Insert(text.s)
    Protected g.i = Ide_Editor_CurrentGadget()
    Protected *utf
    If g = 0 Or text = ""
      ProcedureReturn
    EndIf
    *utf = UTF8(text)
    If *utf
      ScintillaSendMessage(g, #SCI_REPLACESEL, 0, *utf)
      FreeMemory(*utf)
    EndIf
  EndProcedure

  ; <summary>
  ; Update Insert Snippet submenu labels (optional i18n).
  ; </summary>
  Procedure Ide_Snippets_RefreshMenuLabels()
    SetMenuItemText(#MENU_MAIN, #MNU_SNIPPET_FUNC, Ide_I18n_Pick("Function...", "snippet.func"))
    SetMenuItemText(#MENU_MAIN, #MNU_SNIPPET_IF, Ide_I18n_Pick("If / Else block", "snippet.if"))
    SetMenuItemText(#MENU_MAIN, #MNU_SNIPPET_MAIN, Ide_I18n_Pick("Main + print", "snippet.main"))
    SetMenuItemText(#MENU_MAIN, #MNU_SNIPPET_VYRN12, Ide_I18n_Pick("vyrn: 12 header", "snippet.vyrn12"))
    SetMenuItemText(#MENU_MAIN, #MNU_SNIPPET_ENUM, Ide_I18n_Pick("enum block", "snippet.enum"))
    SetMenuItemText(#MENU_MAIN, #MNU_SNIPPET_STRUCT, Ide_I18n_Pick("struct block", "snippet.struct"))
    SetMenuItemText(#MENU_MAIN, #MNU_SNIPPET_MATCH_IF, Ide_I18n_Pick("status if/elif (not match)", "snippet.match_if"))
  EndProcedure

  ; <summary>
  ; Dispatch built-in snippet templates.
  ; </summary>
  ; <param name="kind">integer</param>
  Procedure Ide_Snippets_InsertKind(kind.i)
    Select kind
      Case #MNU_SNIPPET_FUNC
        Ide_Snippets_Insert("function name(args)" + Chr(10) + "  -- body" + Chr(10) + "  return nil" + Chr(10) + "end" + Chr(10))
      Case #MNU_SNIPPET_IF
        Ide_Snippets_Insert("if condition then" + Chr(10) + "  -- then" + Chr(10) + "else" + Chr(10) + "  -- else" + Chr(10) + "end" + Chr(10))
      Case #MNU_SNIPPET_MAIN
        Ide_Snippets_Insert("function main()" + Chr(10) + "  print(" + Chr(34) + "hello" + Chr(34) + ")" + Chr(10) + "  return 0" + Chr(10) + "end" + Chr(10))
      Case #MNU_SNIPPET_VYRN12
        Ide_Snippets_Insert("-- vyrn: 12" + Chr(10))
      Case #MNU_SNIPPET_ENUM
        Ide_Snippets_Insert("enum Status: number" + Chr(10) + "    Idle" + Chr(10) + "    Running" + Chr(10) + "end" + Chr(10))
      Case #MNU_SNIPPET_STRUCT
        Ide_Snippets_Insert("struct Vec2" + Chr(10) + "    x: number" + Chr(10) + "    y: number" + Chr(10) + "end" + Chr(10))
      Case #MNU_SNIPPET_MATCH_IF
        Ide_Snippets_Insert("-- match arms only accept literals; compare enums with if/elif" + Chr(10) + "if st == Status.Running then" + Chr(10) + "    print(" + Chr(34) + "running" + Chr(34) + ")" + Chr(10) + "elif st == Status.Idle then" + Chr(10) + "    print(" + Chr(34) + "idle" + Chr(34) + ")" + Chr(10) + "end" + Chr(10))
    EndSelect
  EndProcedure

CompilerEndIf
; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 44
; FirstLine = 16
; Folding = -
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)