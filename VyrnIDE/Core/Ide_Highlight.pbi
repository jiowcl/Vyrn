;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - simple Scintilla keyword / comment / string styler
; PureBasic 6.40

CompilerIf Defined(Ide_Highlight, #PB_Constant) = #False
  #Ide_Highlight = #True

  Enumeration
    #STY_DEFAULT = 0
    #STY_COMMENT = 1
    #STY_STRING = 2
    #STY_NUMBER = 3
    #STY_KEYWORD = 4
    #STY_OPERATOR = 5
    #STY_TYPE = 6
    #STY_INTERP = 7
  EndEnumeration

  CompilerIf Defined(STYLE_DEFAULT, #PB_Constant) = #False
    #STYLE_DEFAULT = 32
  CompilerEndIf
  CompilerIf Defined(STYLE_LINENUMBER, #PB_Constant) = #False
    #STYLE_LINENUMBER = 33
  CompilerEndIf
  CompilerIf Defined(SCI_STYLECLEARALL, #PB_Constant) = #False
    #SCI_STYLECLEARALL = 2058
  CompilerEndIf
  CompilerIf Defined(SCI_SETCARETFORE, #PB_Constant) = #False
    #SCI_SETCARETFORE = 2069
  CompilerEndIf
  CompilerIf Defined(SCI_SETSELBACK, #PB_Constant) = #False
    #SCI_SETSELBACK = 2068
  CompilerEndIf
  CompilerIf Defined(SCI_MARKERSETFORE, #PB_Constant) = #False
    #SCI_MARKERSETFORE = 2041
  CompilerEndIf
  CompilerIf Defined(SCI_MARKERSETBACK, #PB_Constant) = #False
    #SCI_MARKERSETBACK = 2042
  CompilerEndIf

  Global NewMap Ide_Keywords.i()
  Global NewMap Ide_Types.i()
  Global Ide_HighlightReady.i = #False

  ; <summary>
  ; Load keyword and type maps from DataSection once (idempotent).
  ; </summary>
  Procedure Ide_Highlight_InitMaps()
    Protected k.s
    If Ide_HighlightReady
      ProcedureReturn
    EndIf
    
    ForEach Ide_Keywords() : DeleteMapElement(Ide_Keywords()) : Next
    ForEach Ide_Types() : DeleteMapElement(Ide_Types()) : Next

    Restore Ide_KeywordData
    Repeat
      Read.s k
      If k = ""
        Break
      EndIf
      Ide_Keywords(LCase(k)) = 1
    ForEver

    Restore Ide_TypeData
    Repeat
      Read.s k
      If k = ""
        Break
      EndIf
      Ide_Types(LCase(k)) = 1
    ForEver

    Ide_HighlightReady = #True
  EndProcedure

  ; <summary>
  ; Apply light/dark style colors, caret, selection, and diagnostic marker colors to a Scintilla.
  ; </summary>
  ; <param name="g">Scintilla gadget id.</param>
  Procedure Ide_Highlight_ApplyStyles(g.i)
    Protected bg.i, fg.i, comment.i, STR.i, num.i, kw.i, op.i, typ.i, interp.i
    Protected marginBg.i, marginFg.i, caret.i, sel.i, errBg.i, warnBg.i

    If Ide_Theme_Dark
      bg = RGB(30, 30, 30)
      fg = RGB(212, 212, 212)
      comment = RGB(106, 153, 85)
      STR = RGB(206, 145, 120)
      num = RGB(181, 206, 168)
      kw = RGB(86, 156, 214)
      op = RGB(180, 180, 180)
      typ = RGB(78, 201, 176)
      interp = RGB(220, 220, 140)
      marginBg = RGB(37, 37, 38)
      marginFg = RGB(133, 133, 133)
      caret = RGB(248, 248, 242)
      sel = RGB(38, 79, 120)
      errBg = RGB(90, 40, 40)
      warnBg = RGB(90, 70, 30)
    Else
      bg = RGB(252, 252, 252)
      fg = RGB(30, 30, 30)
      comment = RGB(0, 128, 0)
      STR = RGB(163, 21, 21)
      num = RGB(0, 0, 200)
      kw = RGB(0, 0, 160)
      op = RGB(100, 100, 100)
      typ = RGB(43, 145, 175)
      interp = RGB(160, 90, 0)
      marginBg = RGB(245, 245, 245)
      marginFg = RGB(128, 128, 128)
      caret = RGB(0, 0, 0)
      sel = RGB(173, 214, 255)
      errBg = RGB(255, 220, 220)
      warnBg = RGB(255, 244, 200)
    EndIf

    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STYLE_DEFAULT, fg)
    ScintillaSendMessage(g, #SCI_STYLESETBACK, #STYLE_DEFAULT, bg)
    ScintillaSendMessage(g, #SCI_STYLECLEARALL)

    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_DEFAULT, fg)
    ScintillaSendMessage(g, #SCI_STYLESETBACK, #STY_DEFAULT, bg)
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_COMMENT, comment)
    ScintillaSendMessage(g, #SCI_STYLESETBACK, #STY_COMMENT, bg)
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_STRING, STR)
    ScintillaSendMessage(g, #SCI_STYLESETBACK, #STY_STRING, bg)
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_NUMBER, num)
    ScintillaSendMessage(g, #SCI_STYLESETBACK, #STY_NUMBER, bg)
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_KEYWORD, kw)
    ScintillaSendMessage(g, #SCI_STYLESETBACK, #STY_KEYWORD, bg)
    ScintillaSendMessage(g, #SCI_STYLESETBOLD, #STY_KEYWORD, #True)
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_OPERATOR, op)
    ScintillaSendMessage(g, #SCI_STYLESETBACK, #STY_OPERATOR, bg)
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_TYPE, typ)
    ScintillaSendMessage(g, #SCI_STYLESETBACK, #STY_TYPE, bg)
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_INTERP, interp)
    ScintillaSendMessage(g, #SCI_STYLESETBACK, #STY_INTERP, bg)
    ScintillaSendMessage(g, #SCI_STYLESETBOLD, #STY_INTERP, #True)

    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STYLE_LINENUMBER, marginFg)
    ScintillaSendMessage(g, #SCI_STYLESETBACK, #STYLE_LINENUMBER, marginBg)
    ScintillaSendMessage(g, #SCI_SETCARETFORE, caret)
    ScintillaSendMessage(g, #SCI_SETSELBACK, 1, sel)

    ScintillaSendMessage(g, #SCI_MARKERSETFORE, #Ide_MarkError, RGB(200, 0, 0))
    ScintillaSendMessage(g, #SCI_MARKERSETBACK, #Ide_MarkError, RGB(200, 0, 0))
    ScintillaSendMessage(g, #SCI_MARKERSETFORE, #Ide_MarkWarn, RGB(220, 160, 0))
    ScintillaSendMessage(g, #SCI_MARKERSETBACK, #Ide_MarkWarn, RGB(220, 160, 0))
    ScintillaSendMessage(g, #SCI_MARKERSETBACK, #Ide_MarkErrorBack, errBg)
    ScintillaSendMessage(g, #SCI_MARKERSETBACK, #Ide_MarkWarnBack, warnBg)
  EndProcedure

  ; <summary>
  ; Whether c can start an identifier (letter or underscore).
  ; </summary>
  ; <param name="c">Character code.</param>
  ; <returns>#True if valid identifier start.</returns>
  Procedure.i Ide_Highlight_IsIdentStart(c.i)
    If (c >= 'A' And c <= 'Z') Or (c >= 'a' And c <= 'z') Or c = '_'
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
  EndProcedure

  ; <summary>
  ; Whether c is a valid identifier continuation character.
  ; </summary>
  ; <param name="c">Character code.</param>
  ; <returns>#True if letter, digit, or underscore.</returns>
  Procedure.i Ide_Highlight_IsIdent(c.i)
    If Ide_Highlight_IsIdentStart(c) Or (c >= '0' And c <= '9')
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
  EndProcedure

  ; <summary>
  ; Whether c is an ASCII digit.
  ; </summary>
  ; <param name="c">Character code.</param>
  ; <returns>#True if '0'..'9'.</returns>
  Procedure.i Ide_Highlight_IsDigit(c.i)
    If c >= '0' And c <= '9'
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
  EndProcedure

  ; <summary>
  ; Whether c is treated as an operator/punctuation for styling.
  ; </summary>
  ; <param name="c">Character code.</param>
  ; <returns>#True for operators and brackets.</returns>
  Procedure.i Ide_Highlight_IsOp(c.i)
    Select c
      Case '+', '-', '*', '/', '%', '^', '=', '~', '<', '>', '#', '.', ':', ',', ';', '(', ')', '{', '}', '[', ']'
        ProcedureReturn #True
    EndSelect
    
    ProcedureReturn #False
  EndProcedure

  ; <summary>
  ; Style a quoted string (and {interp} inside double quotes); returns index after the string.
  ; </summary>
  ; <param name="g">Scintilla gadget id.</param>
  ; <param name="q">Opening quote character (34 or 39).</param>
  ; <param name="i">Index of the opening quote.</param>
  ; <param name="length">Document length in bytes.</param>
  ; <returns>Next byte index to continue styling from.</returns>
  Procedure.i Ide_Highlight_StyleString(g.i, q.i, i.i, length.i)
    Protected c2.i, interpStart.i, run.i
    i = i + 1
    ScintillaSendMessage(g, #SCI_SETSTYLING, 1, #STY_STRING)

    While i < length
      c2 = ScintillaSendMessage(g, #SCI_GETCHARAT, i)
      If c2 = '\' And i + 1 < length
        ScintillaSendMessage(g, #SCI_SETSTYLING, 2, #STY_STRING)
        i = i + 2
        Continue
      EndIf
      
      If c2 = q
        ScintillaSendMessage(g, #SCI_SETSTYLING, 1, #STY_STRING)
        ProcedureReturn i + 1
      EndIf
      
      If c2 = 10 Or c2 = 13
        ProcedureReturn i
      EndIf
      
      ; Double-quoted interpolation: "Hello, {name}!" (\{ \} are literals)
      If q = 34 And c2 = '{'
        interpStart = i
        i = i + 1
        
        While i < length
          c2 = ScintillaSendMessage(g, #SCI_GETCHARAT, i)
          
          If c2 = '}'
            i = i + 1
            Break
          EndIf
          
          If c2 = 10 Or c2 = 13 Or c2 = q
            Break
          EndIf
          
          i = i + 1
        Wend
        ScintillaSendMessage(g, #SCI_SETSTYLING, i - interpStart, #STY_INTERP)
        Continue
      EndIf
      
      run = 1
      i = i + 1
      
      While i < length
        c2 = ScintillaSendMessage(g, #SCI_GETCHARAT, i)
        
        If c2 = q Or c2 = '\' Or c2 = 10 Or c2 = 13
          Break
        EndIf
        
        If q = 34 And c2 = '{'
          Break
        EndIf
        
        run = run + 1
        i = i + 1
      Wend
      
      ScintillaSendMessage(g, #SCI_SETSTYLING, run, #STY_STRING)
    Wend
    
    ProcedureReturn i
  EndProcedure

  ; <summary>
  ; Full-document restyle: comments, strings, numbers, keywords, types, operators.
  ; </summary>
  ; <param name="g">Scintilla gadget id.</param>
  Procedure Ide_Highlight_Restyle(g.i)
    Protected length.i, i.i, c.i, c2.i, start.i, style.i
    Protected word.s
    
    If g = 0
      ProcedureReturn
    EndIf
    
    Ide_Highlight_InitMaps()
    length = ScintillaSendMessage(g, #SCI_GETLENGTH)
    
    If length < 0
      ProcedureReturn
    EndIf
    
    ScintillaSendMessage(g, #SCI_STARTSTYLING, 0, 0)

    i = 0
    
    While i < length
      c = ScintillaSendMessage(g, #SCI_GETCHARAT, i)

      If c = '-' And i + 1 < length And ScintillaSendMessage(g, #SCI_GETCHARAT, i + 1) = '-'
        start = i
        i = i + 2
        
        If i + 1 < length And ScintillaSendMessage(g, #SCI_GETCHARAT, i) = '[' And ScintillaSendMessage(g, #SCI_GETCHARAT, i + 1) = '['
          i = i + 2
          
          While i < length
            If ScintillaSendMessage(g, #SCI_GETCHARAT, i) = ']' And i + 1 < length And ScintillaSendMessage(g, #SCI_GETCHARAT, i + 1) = ']'
              i = i + 2
              Break
            EndIf
            
            i = i + 1
          Wend
        Else
          While i < length
            c2 = ScintillaSendMessage(g, #SCI_GETCHARAT, i)
            
            If c2 = 10 Or c2 = 13
              Break
            EndIf
            
            i = i + 1
          Wend
        EndIf
        
        ScintillaSendMessage(g, #SCI_SETSTYLING, i - start, #STY_COMMENT)
        Continue
      EndIf

      If c = 34 Or c = 39
        i = Ide_Highlight_StyleString(g, c, i, length)
        Continue
      EndIf

      If Ide_Highlight_IsDigit(c) Or (c = '.' And i + 1 < length And Ide_Highlight_IsDigit(ScintillaSendMessage(g, #SCI_GETCHARAT, i + 1)))
        start = i
        i = i + 1
        
        While i < length And (Ide_Highlight_IsDigit(ScintillaSendMessage(g, #SCI_GETCHARAT, i)) Or ScintillaSendMessage(g, #SCI_GETCHARAT, i) = '.')
          i = i + 1
        Wend
        
        ScintillaSendMessage(g, #SCI_SETSTYLING, i - start, #STY_NUMBER)
        Continue
      EndIf

      If Ide_Highlight_IsIdentStart(c)
        start = i
        word = ""
        
        While i < length And Ide_Highlight_IsIdent(ScintillaSendMessage(g, #SCI_GETCHARAT, i))
          word = word + Chr(ScintillaSendMessage(g, #SCI_GETCHARAT, i))
          i = i + 1
        Wend
        
        style = #STY_DEFAULT
        
        If FindMapElement(Ide_Keywords(), LCase(word))
          style = #STY_KEYWORD
        ElseIf FindMapElement(Ide_Types(), LCase(word))
          style = #STY_TYPE
        EndIf
        
        ScintillaSendMessage(g, #SCI_SETSTYLING, i - start, style)
        Continue
      EndIf

      If Ide_Highlight_IsOp(c)
        ScintillaSendMessage(g, #SCI_SETSTYLING, 1, #STY_OPERATOR)
        i = i + 1
        
        Continue
      EndIf

      ScintillaSendMessage(g, #SCI_SETSTYLING, 1, #STY_DEFAULT)
      i = i + 1
    Wend
  EndProcedure

  DataSection
    Ide_KeywordData:
    Data.s "if", "else", "elseif", "elif", "end", "while", "for", "repeat", "until", "do"
    Data.s "local", "let", "global", "func", "function", "def", "return", "yield"
    Data.s "and", "or", "not", "then", "in", "break", "continue", "const"
    Data.s "match", "struct", "import", "from", "enum", "as"
    Data.s "true", "false", "nil", ""
    Ide_TypeData:
    Data.s "number", "string", "boolean", "bool", "table", "function", ""
  EndDataSection

CompilerEndIf

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 387
; FirstLine = 357
; Folding = ---
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; DllProtection
; EnableOnError
; DisableDebugger
; CompileSourceDirectory
; Compiler = PureBasic 6.41 - C Backend (Windows - x64)