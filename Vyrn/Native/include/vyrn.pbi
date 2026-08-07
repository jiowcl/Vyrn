;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; PureBasic dynamic loader for Vyrn.dll (ABI 4) — companion to include/vyrn.h
; PureBasic 6.40 (Windows x64)
;
; Usage:
;   XIncludeFile "include\vyrn.pbi"   ; path relative to your source
;   If Vyrn_Load() = 0 : ... : EndIf
;   Vyrn_SetPrintLogger(@MyLog(), 0)
;   Vyrn_RunFile("hello.vyrn")
;   Vyrn_Unload()

CompilerIf Defined(Vyrn_Pbi, #PB_Constant) = #False
  #Vyrn_Pbi = #True

  #Vyrn_RequiredAbi = 4
  #Vyrn_Lib = 0

  PrototypeC.i Vyrn_Proto_AbiVersion()
  PrototypeC.i Vyrn_Proto_Version()
  PrototypeC.i Vyrn_Proto_Create()
  PrototypeC Vyrn_Proto_Destroy(*vm)
  PrototypeC.i Vyrn_Proto_SetLimits(*vm, maxLoops.i, maxCalls.i, maxIns.i)
  PrototypeC.i Vyrn_Proto_SetPrintLogger(*vm, logFn.i, userdata.i)
  PrototypeC.i Vyrn_Proto_RunFile(*vm, *path)
  PrototypeC.i Vyrn_Proto_Eval(*vm, *source)
  PrototypeC.i Vyrn_Proto_LastError(*vm)
  PrototypeC.i Vyrn_Proto_LastErrorCode(*vm)
  PrototypeC.i Vyrn_Proto_WarningCount(*vm)
  PrototypeC.i Vyrn_Proto_GetWarning(*vm, index.i)
  PrototypeC.i Vyrn_Proto_CopyString(*src, *buf, bufSize.i)

  Global Vyrn_DllPath.s = ""
  Global Vyrn_LastError.s = ""
  Global Vyrn_Loaded.i = #False
  Global Vyrn_Vm.i = 0
  Global Vyrn_ProductVer.s = ""
  Global Vyrn_Abi.i = 0

  Global Vyrn_Fn_AbiVersion.Vyrn_Proto_AbiVersion = 0
  Global Vyrn_Fn_Version.Vyrn_Proto_Version = 0
  Global Vyrn_Fn_Create.Vyrn_Proto_Create = 0
  Global Vyrn_Fn_Destroy.Vyrn_Proto_Destroy = 0
  Global Vyrn_Fn_SetLimits.Vyrn_Proto_SetLimits = 0
  Global Vyrn_Fn_SetPrintLogger.Vyrn_Proto_SetPrintLogger = 0
  Global Vyrn_Fn_RunFile.Vyrn_Proto_RunFile = 0
  Global Vyrn_Fn_Eval.Vyrn_Proto_Eval = 0
  Global Vyrn_Fn_LastError.Vyrn_Proto_LastError = 0
  Global Vyrn_Fn_LastErrorCode.Vyrn_Proto_LastErrorCode = 0
  Global Vyrn_Fn_WarningCount.Vyrn_Proto_WarningCount = 0
  Global Vyrn_Fn_GetWarning.Vyrn_Proto_GetWarning = 0
  Global Vyrn_Fn_CopyString.Vyrn_Proto_CopyString = 0

  Declare.i Vyrn_TryOpen(path.s)
  Declare.i Vyrn_Load()

  Procedure.s Vyrn_JoinPath(a.s, b.s)
    If a = ""
      ProcedureReturn b
    EndIf
    If Right(a, 1) <> "\" And Right(a, 1) <> "/"
      a = a + "\"
    EndIf
    ProcedureReturn a + b
  EndProcedure

  Procedure.s Vyrn_CopyUtf8(*p)
    Protected need.i, *buf, s.s
    If *p = 0 Or Vyrn_Fn_CopyString = 0
      If *p = 0
        ProcedureReturn ""
      EndIf
      ProcedureReturn PeekS(*p, -1, #PB_UTF8)
    EndIf
    need = Vyrn_Fn_CopyString(*p, 0, 0)
    If need < 1
      ProcedureReturn ""
    EndIf
    *buf = AllocateMemory(need)
    If *buf = 0
      ProcedureReturn PeekS(*p, -1, #PB_UTF8)
    EndIf
    Vyrn_Fn_CopyString(*p, *buf, need)
    s = PeekS(*buf, -1, #PB_UTF8)
    FreeMemory(*buf)
    ProcedureReturn s
  EndProcedure

  Procedure.s Vyrn_ProductVersion()
    If Vyrn_ProductVer <> ""
      ProcedureReturn Vyrn_ProductVer
    EndIf
    ProcedureReturn "(DLL not loaded)"
  EndProcedure

  Procedure.i Vyrn_IsReady()
    ProcedureReturn Bool(Vyrn_Loaded And Vyrn_Vm <> 0)
  EndProcedure

  Procedure Vyrn_ResetFns()
    Vyrn_Fn_AbiVersion = 0
    Vyrn_Fn_Version = 0
    Vyrn_Fn_Create = 0
    Vyrn_Fn_Destroy = 0
    Vyrn_Fn_SetLimits = 0
    Vyrn_Fn_SetPrintLogger = 0
    Vyrn_Fn_RunFile = 0
    Vyrn_Fn_Eval = 0
    Vyrn_Fn_LastError = 0
    Vyrn_Fn_LastErrorCode = 0
    Vyrn_Fn_WarningCount = 0
    Vyrn_Fn_GetWarning = 0
    Vyrn_Fn_CopyString = 0
    Vyrn_Loaded = #False
    Vyrn_DllPath = ""
    Vyrn_ProductVer = ""
    Vyrn_Abi = 0
    Vyrn_Vm = 0
  EndProcedure

  Procedure Vyrn_Unload()
    If Vyrn_Vm <> 0 And Vyrn_Fn_Destroy <> 0
      Vyrn_Fn_Destroy(Vyrn_Vm)
      Vyrn_Vm = 0
    EndIf
    If IsLibrary(#Vyrn_Lib)
      CloseLibrary(#Vyrn_Lib)
    EndIf
    Vyrn_ResetFns()
  EndProcedure

  ; Drop the library without vyrn_destroy (e.g. after KillThread left the VM corrupt).
  Procedure.i Vyrn_ForceReload()
    Protected saved.s = Vyrn_DllPath
    Vyrn_Vm = 0
    If IsLibrary(#Vyrn_Lib)
      CloseLibrary(#Vyrn_Lib)
    EndIf
    Vyrn_ResetFns()
    If saved <> "" And FileSize(saved) >= 0
      If Vyrn_TryOpen(saved)
        ProcedureReturn #True
      EndIf
    EndIf
    ProcedureReturn Vyrn_Load()
  EndProcedure

  Procedure.i Vyrn_TryOpen(path.s)
    Protected *ver
    If path = "" Or FileSize(path) < 0
      ProcedureReturn #False
    EndIf
    If IsLibrary(#Vyrn_Lib)
      CloseLibrary(#Vyrn_Lib)
    EndIf
    If OpenLibrary(#Vyrn_Lib, path) = 0
      Vyrn_LastError = "Failed to load library:" + Chr(10) + path
      ProcedureReturn #False
    EndIf

    Vyrn_Fn_AbiVersion = GetFunction(#Vyrn_Lib, "vyrn_abi_version")
    Vyrn_Fn_Version = GetFunction(#Vyrn_Lib, "vyrn_version")
    Vyrn_Fn_Create = GetFunction(#Vyrn_Lib, "vyrn_create")
    Vyrn_Fn_Destroy = GetFunction(#Vyrn_Lib, "vyrn_destroy")
    Vyrn_Fn_SetLimits = GetFunction(#Vyrn_Lib, "vyrn_set_limits")
    Vyrn_Fn_SetPrintLogger = GetFunction(#Vyrn_Lib, "vyrn_set_print_logger")
    Vyrn_Fn_RunFile = GetFunction(#Vyrn_Lib, "vyrn_run_file")
    Vyrn_Fn_Eval = GetFunction(#Vyrn_Lib, "vyrn_eval")
    Vyrn_Fn_LastError = GetFunction(#Vyrn_Lib, "vyrn_last_error")
    Vyrn_Fn_LastErrorCode = GetFunction(#Vyrn_Lib, "vyrn_last_error_code")
    Vyrn_Fn_WarningCount = GetFunction(#Vyrn_Lib, "vyrn_warning_count")
    Vyrn_Fn_GetWarning = GetFunction(#Vyrn_Lib, "vyrn_get_warning")
    Vyrn_Fn_CopyString = GetFunction(#Vyrn_Lib, "vyrn_copy_string")

    If Vyrn_Fn_AbiVersion = 0 Or Vyrn_Fn_Create = 0 Or Vyrn_Fn_Destroy = 0 Or Vyrn_Fn_RunFile = 0 Or Vyrn_Fn_Eval = 0 Or Vyrn_Fn_LastError = 0 Or Vyrn_Fn_SetPrintLogger = 0 Or Vyrn_Fn_SetLimits = 0
      Vyrn_LastError = "Vyrn.dll is missing required exports:" + Chr(10) + path
      CloseLibrary(#Vyrn_Lib)
      ProcedureReturn #False
    EndIf

    Vyrn_Abi = Vyrn_Fn_AbiVersion()
    If Vyrn_Abi < #Vyrn_RequiredAbi
      Vyrn_LastError = "Vyrn.dll ABI " + Str(Vyrn_Abi) + " is older than required " + Str(#Vyrn_RequiredAbi) + ":" + Chr(10) + path
      CloseLibrary(#Vyrn_Lib)
      Vyrn_Fn_AbiVersion = 0
      ProcedureReturn #False
    EndIf

    If Vyrn_Fn_Version <> 0
      *ver = Vyrn_Fn_Version()
      Vyrn_ProductVer = Vyrn_CopyUtf8(*ver)
    Else
      Vyrn_ProductVer = "unknown"
    EndIf

    Vyrn_Vm = Vyrn_Fn_Create()
    If Vyrn_Vm = 0
      Vyrn_LastError = "vyrn_create failed:" + Chr(10) + path
      CloseLibrary(#Vyrn_Lib)
      ProcedureReturn #False
    EndIf

    Vyrn_Fn_SetLimits(Vyrn_Vm, 100000, 256, 1000000)
    Vyrn_DllPath = path
    Vyrn_Loaded = #True
    Vyrn_LastError = ""
    ProcedureReturn #True
  EndProcedure

  ; Search common locations: exe dir, Runtime\, %VYRN_DLL%, native\, cwd.
  Procedure.i Vyrn_Load()
    Protected exeDir.s = GetPathPart(ProgramFilename())
    Protected envPath.s = GetEnvironmentVariable("VYRN_DLL")
    Protected Dim cand.s(10)
    Protected i.i

    Vyrn_Unload()
    Vyrn_LastError = ""

    cand(0) = Vyrn_JoinPath(exeDir, "Vyrn.dll")
    cand(1) = Vyrn_JoinPath(exeDir, "LibVyrn.dll")
    cand(2) = Vyrn_JoinPath(exeDir, "Runtime\Vyrn.dll")
    cand(3) = Vyrn_JoinPath(exeDir, "Runtime\LibVyrn.dll")
    cand(4) = Vyrn_JoinPath(exeDir, "..\Runtime\Vyrn.dll")
    cand(5) = Vyrn_JoinPath(exeDir, "..\Runtime\LibVyrn.dll")
    cand(6) = envPath
    cand(7) = Vyrn_JoinPath(exeDir, "..\..\native\Vyrn.dll")
    cand(8) = Vyrn_JoinPath(GetCurrentDirectory(), "Vyrn.dll")
    cand(9) = Vyrn_JoinPath(GetCurrentDirectory(), "native\Vyrn.dll")
    cand(10) = Vyrn_JoinPath(GetCurrentDirectory(), "ide\Runtime\Vyrn.dll")

    For i = 0 To 10
      If cand(i) <> "" And FileSize(cand(i)) >= 0
        If Vyrn_TryOpen(cand(i))
          ProcedureReturn #True
        EndIf
        If FindString(Vyrn_LastError, "ABI ", 1) > 0
          ProcedureReturn #False
        EndIf
      EndIf
    Next

    If Vyrn_LastError = ""
      Vyrn_LastError = "Vyrn.dll not found." + Chr(10) + Chr(10) + "Searched:" + Chr(10) + "  " + cand(0) + Chr(10) + "  " + cand(4) + Chr(10) + "  %VYRN_DLL%" + Chr(10) + "  native\Vyrn.dll" + Chr(10) + Chr(10) + "Build with scripts\build_native.ps1 or set VYRN_DLL."
    EndIf
    ProcedureReturn #False
  EndProcedure

  Procedure.i Vyrn_Ensure()
    If Vyrn_IsReady()
      ProcedureReturn #True
    EndIf
    ProcedureReturn Vyrn_Load()
  EndProcedure

  Procedure Vyrn_SetPrintLogger(logFn.i, userdata.i = 0)
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_SetPrintLogger = 0
      ProcedureReturn
    EndIf
    Vyrn_Fn_SetPrintLogger(Vyrn_Vm, logFn, userdata)
  EndProcedure

  Procedure.i Vyrn_SetLimits(maxLoops.i, maxCalls.i, maxIns.i)
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_SetLimits = 0
      ProcedureReturn #False
    EndIf
    ProcedureReturn Bool(Vyrn_Fn_SetLimits(Vyrn_Vm, maxLoops, maxCalls, maxIns))
  EndProcedure

  Procedure.s Vyrn_FetchLastError()
    Protected *p
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_LastError = 0
      ProcedureReturn Vyrn_LastError
    EndIf
    *p = Vyrn_Fn_LastError(Vyrn_Vm)
    ProcedureReturn Vyrn_CopyUtf8(*p)
  EndProcedure

  Procedure.i Vyrn_LastErrorCode()
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_LastErrorCode = 0
      ProcedureReturn 0
    EndIf
    ProcedureReturn Vyrn_Fn_LastErrorCode(Vyrn_Vm)
  EndProcedure

  Procedure.i Vyrn_RunFile(path.s)
    Protected *utf, ok.i
    If Vyrn_Ensure() = 0
      ProcedureReturn #False
    EndIf
    *utf = UTF8(path)
    If *utf = 0
      Vyrn_LastError = "UTF-8 conversion failed for path"
      ProcedureReturn #False
    EndIf
    ok = Vyrn_Fn_RunFile(Vyrn_Vm, *utf)
    FreeMemory(*utf)
    If ok = 0
      Vyrn_LastError = Vyrn_FetchLastError()
      ProcedureReturn #False
    EndIf
    Vyrn_LastError = ""
    ProcedureReturn #True
  EndProcedure

  Procedure.i Vyrn_Eval(source.s)
    Protected *utf, ok.i
    If Vyrn_Ensure() = 0
      ProcedureReturn #False
    EndIf
    *utf = UTF8(source)
    If *utf = 0
      Vyrn_LastError = "UTF-8 conversion failed for source"
      ProcedureReturn #False
    EndIf
    ok = Vyrn_Fn_Eval(Vyrn_Vm, *utf)
    FreeMemory(*utf)
    If ok = 0
      Vyrn_LastError = Vyrn_FetchLastError()
      ProcedureReturn #False
    EndIf
    Vyrn_LastError = ""
    ProcedureReturn #True
  EndProcedure

  Procedure.i Vyrn_WarningCount()
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_WarningCount = 0
      ProcedureReturn 0
    EndIf
    ProcedureReturn Vyrn_Fn_WarningCount(Vyrn_Vm)
  EndProcedure

  Procedure.s Vyrn_GetWarning(index.i)
    Protected *p
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_GetWarning = 0
      ProcedureReturn ""
    EndIf
    *p = Vyrn_Fn_GetWarning(Vyrn_Vm, index)
    ProcedureReturn Vyrn_CopyUtf8(*p)
  EndProcedure

CompilerEndIf
