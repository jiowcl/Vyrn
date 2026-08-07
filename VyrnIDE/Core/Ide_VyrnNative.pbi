;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; IDE shim: shared PureBasic Vyrn.dll loader lives in include/vyrn.pbi (next to vyrn.h).
; Prefer Vyrn_* APIs in new code; Ide_Vyrn_* macros remain for older IDE call sites.

CompilerIf Defined(Ide_VyrnNative, #PB_Constant) = #False
  #Ide_VyrnNative = #True

  XIncludeFile "..\..\Vyrn\Native\include\vyrn.pbi"

  Macro Ide_Vyrn_RequiredAbi : #Vyrn_RequiredAbi : EndMacro
  Macro Ide_Vyrn_DllPath : Vyrn_DllPath : EndMacro
  Macro Ide_Vyrn_LastError : Vyrn_LastError : EndMacro
  Macro Ide_Vyrn_Loaded : Vyrn_Loaded : EndMacro
  Macro Ide_Vyrn_Vm : Vyrn_Vm : EndMacro
  Macro Ide_Vyrn_ProductVer : Vyrn_ProductVer : EndMacro
  Macro Ide_Vyrn_Abi : Vyrn_Abi : EndMacro

  Macro Ide_Vyrn_ProductVersion : Vyrn_ProductVersion : EndMacro
  Macro Ide_Vyrn_IsReady : Vyrn_IsReady : EndMacro
  Macro Ide_Vyrn_Unload : Vyrn_Unload : EndMacro
  Macro Ide_Vyrn_ForceReload : Vyrn_ForceReload : EndMacro
  Macro Ide_Vyrn_TryOpen : Vyrn_TryOpen : EndMacro
  Macro Ide_Vyrn_Load : Vyrn_Load : EndMacro
  Macro Ide_Vyrn_Ensure : Vyrn_Ensure : EndMacro
  Macro Ide_Vyrn_SetPrintLogger : Vyrn_SetPrintLogger : EndMacro
  Macro Ide_Vyrn_FetchLastError : Vyrn_FetchLastError : EndMacro
  Macro Ide_Vyrn_RunFile : Vyrn_RunFile : EndMacro
  Macro Ide_Vyrn_Eval : Vyrn_Eval : EndMacro
  Macro Ide_Vyrn_WarningCount : Vyrn_WarningCount : EndMacro
  Macro Ide_Vyrn_GetWarning : Vyrn_GetWarning : EndMacro

CompilerEndIf

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 11
; Folding = ----
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; EnableOnError
; DisableDebugger
; CompileSourceDirectory