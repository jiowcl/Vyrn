;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - UI language strings (English / Traditional Chinese from UTF-8 ini)
; Status bar and output copy use Ide_I18n_Pick / Ide_I18n_Fmt with keys in i18n\zh-Hant.ini.
; Menu chrome is applied from Ide_Ui_ApplyMenuLabels when uiLang is zh.
; PureBasic 6.41

CompilerIf Defined(Ide_I18n, #PB_Constant) = #False
  #Ide_I18n = #True

  #Ide_Lang_En = 0
  #Ide_Lang_Zh = 1

  Global Ide_UiLang.i = #Ide_Lang_En
  Global NewMap Ide_I18n_Zh.s()
  Global Ide_I18n_Loaded.i = #False
  Global Ide_UiLangPinned.i = #False

  ; <summary>
  ; Locate ide\i18n\zh-Hant.ini beside the IDE exe or dev tree.
  ; </summary>
  ; <returns>string.</returns>
  Procedure.s Ide_I18n_FindIniPath()
    Protected dir.s = GetPathPart(ProgramFilename())
    Protected cand.s
    cand = dir + "i18n\zh-Hant.ini"
    If FileSize(cand) >= 0
      ProcedureReturn cand
    EndIf
    cand = dir + "..\i18n\zh-Hant.ini"
    If FileSize(cand) >= 0
      ProcedureReturn cand
    EndIf
    cand = dir + "..\..\ide\i18n\zh-Hant.ini"
    If FileSize(cand) >= 0
      ProcedureReturn cand
    EndIf
    ProcedureReturn ""
  EndProcedure

  ; <summary>
  ; Replace escape sequences (\t \n \\) in ini values.
  ; </summary>
  ; <param name="s">string</param>
  ; <returns>string.</returns>
  Procedure.s Ide_I18n_Unescape(s.s)
    Protected t.s = s
    t = ReplaceString(t, "\\", Chr(1))
    t = ReplaceString(t, "\t", Chr(9))
    t = ReplaceString(t, "\n", Chr(10))
    t = ReplaceString(t, Chr(1), "\")
    ProcedureReturn t
  EndProcedure

  ; <summary>
  ; Load zh-Hant string table from UTF-8 ini (idempotent).
  ; </summary>
  Procedure Ide_I18n_Load()
    Protected path.s, fn.i, line.s, key.s, val.s, eq.i
    If Ide_I18n_Loaded
      ProcedureReturn
    EndIf
    ForEach Ide_I18n_Zh() : DeleteMapElement(Ide_I18n_Zh()) : Next
    path = Ide_I18n_FindIniPath()
    If path = ""
      Ide_I18n_Loaded = #True
      ProcedureReturn
    EndIf
    fn = ReadFile(#PB_Any, path)
    If fn = 0
      Ide_I18n_Loaded = #True
      ProcedureReturn
    EndIf
    While Eof(fn) = #False
      line = Trim(ReadString(fn, #PB_UTF8))
      If line = "" Or Left(line, 1) = "#" Or Left(line, 1) = ";"
        Continue
      EndIf
      eq = FindString(line, "=", 1)
      If eq <= 1
        Continue
      EndIf
      key = Trim(Left(line, eq - 1))
      val = Trim(Mid(line, eq + 1))
      Ide_I18n_Zh(key) = Ide_I18n_Unescape(val)
    Wend
    CloseFile(fn)
    Ide_I18n_Loaded = #True
  EndProcedure

  ; <summary>
  ; First-run UI language: VYRN_IDE_LANG wins; else Windows UI language (Chinese → zh); else English.
  ; </summary>
  ; <returns>integer.</returns>
  Procedure.i Ide_I18n_DetectSystemLang()
    Protected env.s = Trim(GetEnvironmentVariable("VYRN_IDE_LANG"))
    Protected k32.i, langFn.l, langId.i
    If env <> ""
      If LCase(Left(env, 2)) = "zh"
        ProcedureReturn #Ide_Lang_Zh
      EndIf
      ProcedureReturn #Ide_Lang_En
    EndIf
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      k32 = OpenLibrary(#PB_Any, "kernel32.dll")
      If k32
        langFn = GetFunction(k32, "GetUserDefaultUILanguage")
        If langFn
          langId = CallFunctionFast(langFn)
          If (langId & $3FF) = $04
            CloseLibrary(k32)
            ProcedureReturn #Ide_Lang_Zh
          EndIf
        EndIf
        CloseLibrary(k32)
      EndIf
    CompilerEndIf
    ProcedureReturn #Ide_Lang_En
  EndProcedure

  ; <summary>
  ; Pick localized text: English default, or zh-Hant from ini when key is set and uiLang is zh.
  ; </summary>
  ; <param name="en">English label.</param>
  ; <param name="key">Key in i18n\zh-Hant.ini (empty = English only).</param>
  Procedure.s Ide_I18n_Pick(en.s, key.s)
    Protected t.s
    If Ide_UiLang <> #Ide_Lang_Zh Or key = ""
      ProcedureReturn en
    EndIf
    If Ide_I18n_Loaded = #False
      Ide_I18n_Load()
    EndIf
    If FindMapElement(Ide_I18n_Zh(), key)
      t = Ide_I18n_Zh(key)
      If t <> ""
        ProcedureReturn t
      EndIf
    EndIf
    ProcedureReturn en
  EndProcedure

  ; <summary>
  ; IDE: I18n AppTitle.
  ; </summary>
  ; <returns>string</returns>
  Procedure.s Ide_I18n_AppTitle()
    ProcedureReturn Ide_I18n_Pick("Vyrn IDE", "app.title")
  EndProcedure

  ; <summary>
  ; Localized template With one {token} replacement.
  ; </summary>
  ; <param name="en">string</param>
  ; <param name="key">string</param>
  ; <param name="token">string</param>
  ; <param name="value">string</param>
  ; <returns>string</returns>
  Procedure.s Ide_I18n_Fmt1(en.s, key.s, token.s, value.s)
    ProcedureReturn ReplaceString(Ide_I18n_Pick(en, key), token, value)
  EndProcedure

  ; <summary>
  ; Localized template With two token replacements (order: t1, t2).
  ; </summary>
  ; <param name="en">string</param>
  ; <param name="key">string</param>
  ; <param name="t1">string</param>
  ; <param name="v1">string</param>
  ; <param name="t2">string</param>
  ; <param name="v2">string</param>
  ; <returns>string</returns>
  Procedure.s Ide_I18n_Fmt2(en.s, key.s, t1.s, v1.s, t2.s, v2.s)
    Protected s.s = Ide_I18n_Pick(en, key)
    s = ReplaceString(s, t1, v1)
    ProcedureReturn ReplaceString(s, t2, v2)
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 173
; FirstLine = 134
; Folding = --
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)