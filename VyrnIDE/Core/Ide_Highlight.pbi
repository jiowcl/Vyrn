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
  EndEnumeration

  Global NewMap Ide_Keywords.i()
  Global NewMap Ide_Types.i()
  Global Ide_HighlightReady.i = #False
  
  ; <summary>
  ; Ide_Highlight_InitMaps
  ; </summary>
  ; <returns>Returns void.</returns>
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
  ; Ide_Highlight_ApplyStyles
  ; </summary>
  ; <param name="g">integer</param>
  ; <returns>Returns void.</returns>
  Procedure Ide_Highlight_ApplyStyles(g.i)
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_DEFAULT, RGB(30, 30, 30))
    ScintillaSendMessage(g, #SCI_STYLESETBACK, #STY_DEFAULT, RGB(252, 252, 252))
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_COMMENT, RGB(0, 128, 0))
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_STRING, RGB(163, 21, 21))
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_NUMBER, RGB(0, 0, 200))
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_KEYWORD, RGB(0, 0, 160))
    ScintillaSendMessage(g, #SCI_STYLESETBOLD, #STY_KEYWORD, #True)
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_OPERATOR, RGB(100, 100, 100))
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_TYPE, RGB(43, 145, 175))
    ScintillaSendMessage(g, #SCI_STYLECLEARALL)
    ; Re-apply after CLEARALL (it copies STYLE_DEFAULT to all).
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_COMMENT, RGB(0, 128, 0))
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_STRING, RGB(163, 21, 21))
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_NUMBER, RGB(0, 0, 200))
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_KEYWORD, RGB(0, 0, 160))
    ScintillaSendMessage(g, #SCI_STYLESETBOLD, #STY_KEYWORD, #True)
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_OPERATOR, RGB(100, 100, 100))
    ScintillaSendMessage(g, #SCI_STYLESETFORE, #STY_TYPE, RGB(43, 145, 175))
  EndProcedure
  
  ; <summary>
  ; Ide_Highlight_IsIdentStart
  ; </summary>
  ; <param name="c">integer</param>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Highlight_IsIdentStart(c.i)
    If (c >= 'A' And c <= 'Z') Or (c >= 'a' And c <= 'z') Or c = '_'
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  ; <summary>
  ; Ide_Highlight_IsIdent
  ; </summary>
  ; <param name="c">integer</param>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Highlight_IsIdent(c.i)
    If Ide_Highlight_IsIdentStart(c) Or (c >= '0' And c <= '9')
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  ; <summary>
  ; Ide_Highlight_IsDigit
  ; </summary>
  ; <param name="c">integer</param>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Highlight_IsDigit(c.i)
    If c >= '0' And c <= '9'
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  ; <summary>
  ; Ide_Highlight_IsOp
  ; </summary>
  ; <param name="c">integer</param>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Highlight_IsOp(c.i)
    Select c
      Case '+', '-', '*', '/', '%', '^', '=', '~', '<', '>', '#', '.', ':', ',', ';', '(', ')', '{', '}', '[', ']'
        ProcedureReturn #True
    EndSelect
    
    ProcedureReturn #False
  EndProcedure
  
  ; <summary>
  ; Ide_Highlight_Restyle
  ; </summary>
  ; <param name="g">integer</param>
  ; <returns>Returns integer.</returns>
  Procedure Ide_Highlight_Restyle(g.i)
    Protected length.i, i.i, c.i, c2.i, start.i, style.i
    Protected word.s, q.i
    
    Ide_Highlight_InitMaps()
    length = ScintillaSendMessage(g, #SCI_GETLENGTH)
    
    If length < 0
      ProcedureReturn
    EndIf
    
    ScintillaSendMessage(g, #SCI_STARTSTYLING, 0, 0)

    i = 0
    
    While i < length
      c = ScintillaSendMessage(g, #SCI_GETCHARAT, i)

      ; Line comment -- or block --[[ ... ]]
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

      ; String
      If c = 34 Or c = 39
        q = c
        start = i
        i = i + 1
        
        While i < length
          c2 = ScintillaSendMessage(g, #SCI_GETCHARAT, i)
          
          If c2 = '\' And i + 1 < length
            i = i + 2
            
            Continue
          EndIf
          
          If c2 = q
            i = i + 1
            
            Break
          EndIf
          
          If c2 = 10 Or c2 = 13
            Break
          EndIf
          
          i = i + 1
        Wend
        
        ScintillaSendMessage(g, #SCI_SETSTYLING, i - start, #STY_STRING)
        
        Continue
      EndIf

      ; Number
      If Ide_Highlight_IsDigit(c) Or (c = '.' And i + 1 < length And Ide_Highlight_IsDigit(ScintillaSendMessage(g, #SCI_GETCHARAT, i + 1)))
        start = i
        i = i + 1
        
        While i < length And (Ide_Highlight_IsDigit(ScintillaSendMessage(g, #SCI_GETCHARAT, i)) Or ScintillaSendMessage(g, #SCI_GETCHARAT, i) = '.')
          i = i + 1
        Wend
        
        ScintillaSendMessage(g, #SCI_SETSTYLING, i - start, #STY_NUMBER)
        
        Continue
      EndIf

      ; Identifier / keyword / type
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

      ; Operator
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

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 55
; FirstLine = 18
; Folding = --
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; EnableOnError
; DisableDebugger
; CompileSourceDirectory