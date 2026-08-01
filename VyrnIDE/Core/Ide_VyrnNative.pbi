;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - dynamic loader for Vyrn.dll (ABI 4)
; PureBasic 6.40

CompilerIf Defined(Ide_VyrnNative, #PB_Constant) = #False
  #Ide_VyrnNative = #True

  #Ide_Vyrn_RequiredAbi = 4
  #Ide_Vyrn_Lib = 0

  PrototypeC.i Ide_Proto_AbiVersion()
  PrototypeC.i Ide_Proto_Version()
  PrototypeC.i Ide_Proto_Create()
  PrototypeC Ide_Proto_Destroy(*vm)
  PrototypeC.i Ide_Proto_SetLimits(*vm, maxLoops.i, maxCalls.i, maxIns.i)
  PrototypeC.i Ide_Proto_SetPrintLogger(*vm, logFn.i, userdata.i)
  PrototypeC.i Ide_Proto_RunFile(*vm, *path)
  PrototypeC.i Ide_Proto_Eval(*vm, *source)
  PrototypeC.i Ide_Proto_LastError(*vm)
  PrototypeC.i Ide_Proto_LastErrorCode(*vm)
  PrototypeC.i Ide_Proto_WarningCount(*vm)
  PrototypeC.i Ide_Proto_GetWarning(*vm, index.i)
  PrototypeC.i Ide_Proto_CopyString(*src, *buf, bufSize.i)

  Global Ide_Vyrn_DllPath.s = ""
  Global Ide_Vyrn_LastError.s = ""
  Global Ide_Vyrn_Loaded.i = #False
  Global Ide_Vyrn_Vm.i = 0
  Global Ide_Vyrn_ProductVer.s = ""
  Global Ide_Vyrn_Abi.i = 0

  Global Ide_Fn_AbiVersion.Ide_Proto_AbiVersion = 0
  Global Ide_Fn_Version.Ide_Proto_Version = 0
  Global Ide_Fn_Create.Ide_Proto_Create = 0
  Global Ide_Fn_Destroy.Ide_Proto_Destroy = 0
  Global Ide_Fn_SetLimits.Ide_Proto_SetLimits = 0
  Global Ide_Fn_SetPrintLogger.Ide_Proto_SetPrintLogger = 0
  Global Ide_Fn_RunFile.Ide_Proto_RunFile = 0
  Global Ide_Fn_Eval.Ide_Proto_Eval = 0
  Global Ide_Fn_LastError.Ide_Proto_LastError = 0
  Global Ide_Fn_LastErrorCode.Ide_Proto_LastErrorCode = 0
  Global Ide_Fn_WarningCount.Ide_Proto_WarningCount = 0
  Global Ide_Fn_GetWarning.Ide_Proto_GetWarning = 0
  Global Ide_Fn_CopyString.Ide_Proto_CopyString = 0
  
  ; <summary>
  ; Ide_Vyrn_JoinPath
  ; </summary>
  ; <param name="a">string</param>
  ; <param name="b">string</param>
  ; <returns>Returns string.</returns>
  Procedure.s Ide_Vyrn_JoinPath(a.s, b.s)
    If a = ""
      ProcedureReturn b
    EndIf
    
    If Right(a, 1) <> "\" And Right(a, 1) <> "/"
      a = a + "\"
    EndIf
    
    ProcedureReturn a + b
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_CopyUtf8
  ; </summary>
  ; <param name="*p">pointer</param>
  ; <returns>Returns string.</returns>
  Procedure.s Ide_Vyrn_CopyUtf8(*p)
    Protected need.i, *buf, s.s
    
    If *p = 0 Or Ide_Fn_CopyString = 0
      If *p = 0
        ProcedureReturn ""
      EndIf
      
      ProcedureReturn PeekS(*p, -1, #PB_UTF8)
    EndIf
    
    need = Ide_Fn_CopyString(*p, 0, 0)
    
    If need < 1
      ProcedureReturn ""
    EndIf
    
    *buf = AllocateMemory(need)
    
    If *buf = 0
      ProcedureReturn PeekS(*p, -1, #PB_UTF8)
    EndIf
    
    Ide_Fn_CopyString(*p, *buf, need)
    s = PeekS(*buf, -1, #PB_UTF8)
    FreeMemory(*buf)
    
    ProcedureReturn s
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_ProductVersion
  ; </summary>
  ; <returns>Returns string.</returns>
  Procedure.s Ide_Vyrn_ProductVersion()
    If Ide_Vyrn_ProductVer <> ""
      ProcedureReturn Ide_Vyrn_ProductVer
    EndIf
    
    ProcedureReturn "(DLL not loaded)"
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_IsReady
  ; </summary>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Vyrn_IsReady()
    ProcedureReturn Bool(Ide_Vyrn_Loaded And Ide_Vyrn_Vm <> 0)
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_Unload
  ; </summary>
  ; <returns>Returns void.</returns>
  Procedure Ide_Vyrn_Unload()
    If Ide_Vyrn_Vm <> 0 And Ide_Fn_Destroy <> 0
      Ide_Fn_Destroy(Ide_Vyrn_Vm)
      Ide_Vyrn_Vm = 0
    EndIf
    
    If IsLibrary(#Ide_Vyrn_Lib)
      CloseLibrary(#Ide_Vyrn_Lib)
    EndIf
    
    Ide_Fn_AbiVersion = 0
    Ide_Fn_Version = 0
    Ide_Fn_Create = 0
    Ide_Fn_Destroy = 0
    Ide_Fn_SetLimits = 0
    Ide_Fn_SetPrintLogger = 0
    Ide_Fn_RunFile = 0
    Ide_Fn_Eval = 0
    Ide_Fn_LastError = 0
    Ide_Fn_LastErrorCode = 0
    Ide_Fn_WarningCount = 0
    Ide_Fn_GetWarning = 0
    Ide_Fn_CopyString = 0
    Ide_Vyrn_Loaded = #False
    Ide_Vyrn_DllPath = ""
    Ide_Vyrn_ProductVer = ""
    Ide_Vyrn_Abi = 0
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_TryOpen
  ; </summary>
  ; <param name="path">string</param>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Vyrn_TryOpen(path.s)
    Protected *ver
    
    If path = "" Or FileSize(path) < 0
      ProcedureReturn #False
    EndIf
    
    If IsLibrary(#Ide_Vyrn_Lib)
      CloseLibrary(#Ide_Vyrn_Lib)
    EndIf
    
    If OpenLibrary(#Ide_Vyrn_Lib, path) = 0
      Ide_Vyrn_LastError = "Failed to load library:" + Chr(10) + path
      
      ProcedureReturn #False
    EndIf

    Ide_Fn_AbiVersion = GetFunction(#Ide_Vyrn_Lib, "vyrn_abi_version")
    Ide_Fn_Version = GetFunction(#Ide_Vyrn_Lib, "vyrn_version")
    Ide_Fn_Create = GetFunction(#Ide_Vyrn_Lib, "vyrn_create")
    Ide_Fn_Destroy = GetFunction(#Ide_Vyrn_Lib, "vyrn_destroy")
    Ide_Fn_SetLimits = GetFunction(#Ide_Vyrn_Lib, "vyrn_set_limits")
    Ide_Fn_SetPrintLogger = GetFunction(#Ide_Vyrn_Lib, "vyrn_set_print_logger")
    Ide_Fn_RunFile = GetFunction(#Ide_Vyrn_Lib, "vyrn_run_file")
    Ide_Fn_Eval = GetFunction(#Ide_Vyrn_Lib, "vyrn_eval")
    Ide_Fn_LastError = GetFunction(#Ide_Vyrn_Lib, "vyrn_last_error")
    Ide_Fn_LastErrorCode = GetFunction(#Ide_Vyrn_Lib, "vyrn_last_error_code")
    Ide_Fn_WarningCount = GetFunction(#Ide_Vyrn_Lib, "vyrn_warning_count")
    Ide_Fn_GetWarning = GetFunction(#Ide_Vyrn_Lib, "vyrn_get_warning")
    Ide_Fn_CopyString = GetFunction(#Ide_Vyrn_Lib, "vyrn_copy_string")

    If Ide_Fn_AbiVersion = 0 Or Ide_Fn_Create = 0 Or Ide_Fn_Destroy = 0 Or Ide_Fn_RunFile = 0 Or Ide_Fn_Eval = 0 Or Ide_Fn_LastError = 0 Or Ide_Fn_SetPrintLogger = 0 Or Ide_Fn_SetLimits = 0
      Ide_Vyrn_LastError = "LibVyrn.dll is missing required exports:" + Chr(10) + path
      CloseLibrary(#Ide_Vyrn_Lib)
      
      ProcedureReturn #False
    EndIf

    Ide_Vyrn_Abi = Ide_Fn_AbiVersion()
    
    If Ide_Vyrn_Abi < #Ide_Vyrn_RequiredAbi
      Ide_Vyrn_LastError = "LibVyrn.dll ABI " + Str(Ide_Vyrn_Abi) + " is older than required " + Str(#Ide_Vyrn_RequiredAbi) + ":" + Chr(10) + path + Chr(10) + Chr(10) + "Please copy a newer LibVyrn.dll into the IDE Output or Runtime folder."
      CloseLibrary(#Ide_Vyrn_Lib)
      Ide_Fn_AbiVersion = 0
      
      ProcedureReturn #False
    EndIf

    If Ide_Fn_Version <> 0
      *ver = Ide_Fn_Version()
      Ide_Vyrn_ProductVer = Ide_Vyrn_CopyUtf8(*ver)
    Else
      Ide_Vyrn_ProductVer = "unknown"
    EndIf

    Ide_Vyrn_Vm = Ide_Fn_Create()
    If Ide_Vyrn_Vm = 0
      Ide_Vyrn_LastError = "vyrn_create failed:" + Chr(10) + path
      CloseLibrary(#Ide_Vyrn_Lib)
      
      ProcedureReturn #False
    EndIf

    Ide_Fn_SetLimits(Ide_Vyrn_Vm, 100000, 256, 1000000)
    Ide_Vyrn_DllPath = path
    Ide_Vyrn_Loaded = #True
    Ide_Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_Load
  ; </summary>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Vyrn_Load()
    Protected exeDir.s = GetPathPart(ProgramFilename())
    Protected envPath.s = GetEnvironmentVariable("VYRN_DLL")
    Protected Dim cand.s(10)
    Protected i.i

    Ide_Vyrn_Unload()
    Ide_Vyrn_LastError = ""

    cand(0) = Ide_Vyrn_JoinPath(exeDir, "Vyrn.dll")
    cand(1) = Ide_Vyrn_JoinPath(exeDir, "LibVyrn.dll")
    cand(2) = Ide_Vyrn_JoinPath(exeDir, "Runtime\Vyrn.dll")
    cand(3) = Ide_Vyrn_JoinPath(exeDir, "Runtime\LibVyrn.dll")
    cand(4) = Ide_Vyrn_JoinPath(exeDir, "..\Runtime\Vyrn.dll")
    cand(5) = Ide_Vyrn_JoinPath(exeDir, "..\Runtime\LibVyrn.dll")
    cand(6) = envPath
    cand(7) = Ide_Vyrn_JoinPath(exeDir, "..\..\native\Vyrn.dll")
    cand(8) = Ide_Vyrn_JoinPath(GetCurrentDirectory(), "Vyrn.dll")
    cand(9) = Ide_Vyrn_JoinPath(GetCurrentDirectory(), "native\Vyrn.dll")
    cand(10) = Ide_Vyrn_JoinPath(GetCurrentDirectory(), "ide\Runtime\Vyrn.dll")

    For i = 0 To 7
      If cand(i) <> "" And FileSize(cand(i)) >= 0
        If Ide_Vyrn_TryOpen(cand(i))
          ProcedureReturn #True
        EndIf
        
        ; Keep last error from TryOpen; continue searching only if open failed for other reasons.
        ; ABI mismatch should stop — already set LastError.
        If FindString(Ide_Vyrn_LastError, "ABI ", 1) > 0
          ProcedureReturn #False
        EndIf
      EndIf
    Next

    If Ide_Vyrn_LastError = ""
      Ide_Vyrn_LastError = "LibVyrn.dll not found." + Chr(10) + Chr(10) + "Searched:" + Chr(10) + "  " + cand(0) + Chr(10) + "  " + cand(2) + Chr(10) + "  %VYRN_DLL%" + Chr(10) + Chr(10) + "Run scripts\sync_ide_runtime.ps1 (or place Vyrn.dll next to VyrnIDE.exe)."
    EndIf
    
    ProcedureReturn #False
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_Ensure
  ; </summary>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Vyrn_Ensure()
    If Ide_Vyrn_IsReady()
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn Ide_Vyrn_Load()
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_SetPrintLogger
  ; </summary>
  ; <param name="logFn">integer</param>
  ; <param name="userdata">integer</param>
  ; <returns>Returns void.</returns>
  Procedure Ide_Vyrn_SetPrintLogger(logFn.i, userdata.i = 0)
    If Ide_Vyrn_IsReady() = 0 Or Ide_Fn_SetPrintLogger = 0
      ProcedureReturn
    EndIf
    
    Ide_Fn_SetPrintLogger(Ide_Vyrn_Vm, logFn, userdata)
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_FetchLastError
  ; </summary>
  ; <returns>Returns string.</returns>
  Procedure.s Ide_Vyrn_FetchLastError()
    Protected *p
    
    If Ide_Vyrn_IsReady() = 0 Or Ide_Fn_LastError = 0
      ProcedureReturn Ide_Vyrn_LastError
    EndIf
    
    *p = Ide_Fn_LastError(Ide_Vyrn_Vm)
    ProcedureReturn Ide_Vyrn_CopyUtf8(*p)
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_RunFile
  ; </summary>
  ; <param name="path">string</param>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Vyrn_RunFile(path.s)
    Protected *utf, ok.i
    
    If Ide_Vyrn_Ensure() = 0
      ProcedureReturn #False
    EndIf
    
    *utf = UTF8(path)
    
    If *utf = 0
      Ide_Vyrn_LastError = "UTF-8 conversion failed for path"
      ProcedureReturn #False
    EndIf
    
    ok = Ide_Fn_RunFile(Ide_Vyrn_Vm, *utf)
    
    FreeMemory(*utf)
    
    If ok = 0
      Ide_Vyrn_LastError = Ide_Vyrn_FetchLastError()
      ProcedureReturn #False
    EndIf
    
    Ide_Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_Eval
  ; </summary>
  ; <param name="source">string</param>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Vyrn_Eval(source.s)
    Protected *utf, ok.i
    
    If Ide_Vyrn_Ensure() = 0
      ProcedureReturn #False
    EndIf
    
    *utf = UTF8(source)
    
    If *utf = 0
      Ide_Vyrn_LastError = "UTF-8 conversion failed for source"
      ProcedureReturn #False
    EndIf
    
    ok = Ide_Fn_Eval(Ide_Vyrn_Vm, *utf)
    FreeMemory(*utf)
    
    If ok = 0
      Ide_Vyrn_LastError = Ide_Vyrn_FetchLastError()
      
      ProcedureReturn #False
    EndIf
    
    Ide_Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_WarningCount
  ; </summary>
  ; <returns>Returns integer.</returns>
  Procedure.i Ide_Vyrn_WarningCount()
    If Ide_Vyrn_IsReady() = 0 Or Ide_Fn_WarningCount = 0
      ProcedureReturn 0
    EndIf
    
    ProcedureReturn Ide_Fn_WarningCount(Ide_Vyrn_Vm)
  EndProcedure
  
  ; <summary>
  ; Ide_Vyrn_GetWarning
  ; </summary>
  ; <param name="index">integer</param>
  ; <returns>Returns string.</returns>
  Procedure.s Ide_Vyrn_GetWarning(index.i)
    Protected *p
    
    If Ide_Vyrn_IsReady() = 0 Or Ide_Fn_GetWarning = 0
      ProcedureReturn ""
    EndIf
    
    *p = Ide_Fn_GetWarning(Ide_Vyrn_Vm, index)
    
    ProcedureReturn Ide_Vyrn_CopyUtf8(*p)
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 247
; FirstLine = 219
; Folding = ---
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; EnableOnError
; DisableDebugger
; CompileSourceDirectory