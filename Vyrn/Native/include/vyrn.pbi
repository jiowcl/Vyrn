;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; PureBasic dynamic loader for Vyrn.dll (ABI 5) — companion to include/vyrn.h
; PureBasic 6.40 (Windows x64)
;
; Usage:
;   XIncludeFile "include\vyrn.pbi"   ; path relative to your source
;   If Vyrn_Load() = 0 : ... : EndIf
;   Vyrn_SetPrintLogger(@MyLog(), 0)
;   Vyrn_RunFile("hello.vyrn")
;   Vyrn_Unload()
;
; VyrnValue layout matches vyrn.h (24 bytes on x64). String pointers from the DLL
; are short-lived — copy with Vyrn_AsString() before the next vyrn_* call.

CompilerIf Defined(Vyrn_Pbi, #PB_Constant) = #False
  #Vyrn_Pbi = #True

  #Vyrn_RequiredAbi = 5
  #Vyrn_Lib = 0

  #VYRN_TYPE_NIL    = 0
  #VYRN_TYPE_BOOL   = 1
  #VYRN_TYPE_NUMBER = 2
  #VYRN_TYPE_STRING = 3
  #VYRN_TYPE_TABLE  = 4

  #VYRN_MAX_ARGS = 16
  #VYRN_MAX_OUTS = 8

  #VYRN_ERR_OK             = 0
  #VYRN_ERR_INVALID_HANDLE = 1
  #VYRN_ERR_NOT_FOUND      = 2
  #VYRN_ERR_COMPILE        = 3
  #VYRN_ERR_RUNTIME        = 4
  #VYRN_ERR_TYPE           = 5
  #VYRN_ERR_ARG            = 6
  #VYRN_ERR_OTHER          = 7
  #VYRN_ERR_CANCELLED      = 8

  ; Must match include/vyrn.h VyrnValue (x64: 24 bytes).
  Structure VyrnValue
    type.l
    boolVal.l
    number.d
    *str
  EndStructure

  PrototypeC.i Vyrn_Proto_AbiVersion()
  PrototypeC.i Vyrn_Proto_Version()
  PrototypeC.i Vyrn_Proto_Create()
  PrototypeC Vyrn_Proto_Destroy(*vm)
  PrototypeC.i Vyrn_Proto_RequestCancel(*vm)
  PrototypeC.i Vyrn_Proto_SetLimits(*vm, maxLoops.i, maxCalls.i, maxIns.i)
  PrototypeC.i Vyrn_Proto_SetPrintLogger(*vm, logFn.i, userdata.i)
  PrototypeC.i Vyrn_Proto_RunFile(*vm, *path)
  PrototypeC.i Vyrn_Proto_Eval(*vm, *source)
  PrototypeC.i Vyrn_Proto_CallGlobal(*vm, *name, *args, argc.i, *out)
  PrototypeC.i Vyrn_Proto_CallGlobalMulti(*vm, *name, *args, argc.i, *outs, maxOut.i, *outCount)
  PrototypeC.i Vyrn_Proto_GetGlobal(*vm, *name, *out)
  PrototypeC.i Vyrn_Proto_SetGlobal(*vm, *name, *val)
  PrototypeC.i Vyrn_Proto_TableGet(*vm, tableId.i, *key, *out)
  PrototypeC.i Vyrn_Proto_TableSet(*vm, tableId.i, *key, *val)
  PrototypeC.i Vyrn_Proto_Register(*vm, *name, fn.i, userdata.i)
  PrototypeC.i Vyrn_Proto_CoCreate(*vm, *name, *out)
  PrototypeC.i Vyrn_Proto_CoResume(*vm, tid.i, *args, argc.i, *outs, maxOut.i, *outCount)
  PrototypeC.i Vyrn_Proto_CoClose(*vm, tid.i, *errMsg)
  PrototypeC.i Vyrn_Proto_CoYielded(*vm)
  PrototypeC.i Vyrn_Proto_CoFinished(*vm)
  PrototypeC.i Vyrn_Proto_LastError(*vm)
  PrototypeC.i Vyrn_Proto_LastErrorCode(*vm)
  PrototypeC.i Vyrn_Proto_WarningCount(*vm)
  PrototypeC.i Vyrn_Proto_GetWarning(*vm, index.i)
  PrototypeC.i Vyrn_Proto_CopyString(*src, *buf, bufSize.i)

  ; Host callback: int (*)(void *userdata, const VyrnValue *args, int argc, VyrnValue *out)
  PrototypeC.i VyrnHostFn(*userdata, *args, argc.i, *out.VyrnValue)

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
  Global Vyrn_Fn_RequestCancel.Vyrn_Proto_RequestCancel = 0
  Global Vyrn_Fn_SetLimits.Vyrn_Proto_SetLimits = 0
  Global Vyrn_Fn_SetPrintLogger.Vyrn_Proto_SetPrintLogger = 0
  Global Vyrn_Fn_RunFile.Vyrn_Proto_RunFile = 0
  Global Vyrn_Fn_Eval.Vyrn_Proto_Eval = 0
  Global Vyrn_Fn_CallGlobal.Vyrn_Proto_CallGlobal = 0
  Global Vyrn_Fn_CallGlobalMulti.Vyrn_Proto_CallGlobalMulti = 0
  Global Vyrn_Fn_GetGlobal.Vyrn_Proto_GetGlobal = 0
  Global Vyrn_Fn_SetGlobal.Vyrn_Proto_SetGlobal = 0
  Global Vyrn_Fn_TableGet.Vyrn_Proto_TableGet = 0
  Global Vyrn_Fn_TableSet.Vyrn_Proto_TableSet = 0
  Global Vyrn_Fn_Register.Vyrn_Proto_Register = 0
  Global Vyrn_Fn_CoCreate.Vyrn_Proto_CoCreate = 0
  Global Vyrn_Fn_CoResume.Vyrn_Proto_CoResume = 0
  Global Vyrn_Fn_CoClose.Vyrn_Proto_CoClose = 0
  Global Vyrn_Fn_CoYielded.Vyrn_Proto_CoYielded = 0
  Global Vyrn_Fn_CoFinished.Vyrn_Proto_CoFinished = 0
  Global Vyrn_Fn_LastError.Vyrn_Proto_LastError = 0
  Global Vyrn_Fn_LastErrorCode.Vyrn_Proto_LastErrorCode = 0
  Global Vyrn_Fn_WarningCount.Vyrn_Proto_WarningCount = 0
  Global Vyrn_Fn_GetWarning.Vyrn_Proto_GetWarning = 0
  Global Vyrn_Fn_CopyString.Vyrn_Proto_CopyString = 0

  Global NewList Vyrn_ScratchUtf8.i()

  Declare.i Vyrn_TryOpen(path.s)
  Declare.i Vyrn_Load()
  Declare.s Vyrn_CopyUtf8(*p)
  Declare.s Vyrn_FetchLastError()

  ; <summary>
  ; Free all UTF-8 buffers pinned by Vyrn_KeepUtf8 / Vyrn_SetString.
  ; </summary>
  Procedure Vyrn_ClearScratch()
    ForEach Vyrn_ScratchUtf8()
      If Vyrn_ScratchUtf8()
        FreeMemory(Vyrn_ScratchUtf8())
      EndIf
    Next
    
    ClearList(Vyrn_ScratchUtf8())
  EndProcedure

  ; <summary>
  ; Allocate a UTF-8 C string and keep it until the next clear/consume.
  ; </summary>
  ; <param name="s">PureBasic string to pin as UTF-8.</param>
  ; <returns>Pointer to UTF-8 bytes, or 0 on allocation failure.</returns>
  Procedure.i Vyrn_KeepUtf8(s.s)
    Protected *p = UTF8(s)
    
    If *p = 0
      ProcedureReturn 0
    EndIf
    
    AddElement(Vyrn_ScratchUtf8())
    Vyrn_ScratchUtf8() = *p
    ProcedureReturn *p
  EndProcedure

  ; <summary>
  ; Shared failure path: refresh Vyrn_LastError, clear scratch, return #False.
  ; </summary>
  ; <returns>Always #False.</returns>
  Procedure.i Vyrn_FailCall()
    Vyrn_LastError = Vyrn_FetchLastError()
    Vyrn_ClearScratch()
    
    ProcedureReturn #False
  EndProcedure

  ; <summary>
  ; Join directory and file with a backslash when needed.
  ; </summary>
  ; <param name="a">Directory path (may be empty).</param>
  ; <param name="b">File or relative path segment.</param>
  ; <returns>Combined path string.</returns>
  Procedure.s Vyrn_JoinPath(a.s, b.s)
    If a = ""
      ProcedureReturn b
    EndIf
    
    If Right(a, 1) <> "\" And Right(a, 1) <> "/"
      a = a + "\"
    EndIf
    
    ProcedureReturn a + b
  EndProcedure

  ; <summary>
  ; Copy a short-lived DLL UTF-8 pointer into a PureBasic string (via vyrn_copy_string when available).
  ; </summary>
  ; <param name="*p">Null-terminated UTF-8 from the DLL, or 0.</param>
  ; <returns>Copied string, or empty if *p is 0.</returns>
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

  ; <summary>
  ; Reset a VyrnValue to nil (type/bool/number/str cleared).
  ; </summary>
  ; <param name="*v">Value to clear; ignored if 0.</param>
  Procedure Vyrn_ClearValue(*v.VyrnValue)
    If *v = 0
      ProcedureReturn
    EndIf
    
    *v\type = #VYRN_TYPE_NIL
    *v\boolVal = 0
    *v\number = 0
    *v\STR = 0
  EndProcedure

  ; <summary>
  ; Set a VyrnValue to nil.
  ; </summary>
  ; <param name="*v">Destination value.</param>
  Procedure Vyrn_SetNil(*v.VyrnValue)
    Vyrn_ClearValue(*v)
  EndProcedure

  ; <summary>
  ; Set a VyrnValue to boolean.
  ; </summary>
  ; <param name="*v">Destination value.</param>
  ; <param name="b">Non-zero becomes #True.</param>
  Procedure Vyrn_SetBool(*v.VyrnValue, b.i)
    Vyrn_ClearValue(*v)
    
    If *v = 0
      ProcedureReturn
    EndIf
    
    *v\type = #VYRN_TYPE_BOOL
    *v\boolVal = Bool(b)
  EndProcedure

  ; <summary>
  ; Set a VyrnValue to number.
  ; </summary>
  ; <param name="*v">Destination value.</param>
  ; <param name="n">Double payload.</param>
  Procedure Vyrn_SetNumber(*v.VyrnValue, n.d)
    Vyrn_ClearValue(*v)
    
    If *v = 0
      ProcedureReturn
    EndIf
    
    *v\type = #VYRN_TYPE_NUMBER
    *v\number = n
  EndProcedure

  ; <summary>
  ; Set a VyrnValue to string; pins UTF-8 until the next consuming Vyrn_* call or ClearScratch.
  ; </summary>
  ; <param name="*v">Destination value.</param>
  ; <param name="s">String content.</param>
  Procedure Vyrn_SetString(*v.VyrnValue, s.s)
    Vyrn_ClearValue(*v)
    
    If *v = 0
      ProcedureReturn
    EndIf
    
    *v\type = #VYRN_TYPE_STRING
    *v\STR = Vyrn_KeepUtf8(s)
  EndProcedure

  ; <summary>
  ; Set a VyrnValue to a table handle (id stored in number).
  ; </summary>
  ; <param name="*v">Destination value.</param>
  ; <param name="tableId">Runtime table id.</param>
  Procedure Vyrn_SetTable(*v.VyrnValue, tableId.i)
    Vyrn_ClearValue(*v)
    
    If *v = 0
      ProcedureReturn
    EndIf
    
    *v\type = #VYRN_TYPE_TABLE
    *v\number = tableId
  EndProcedure

  ; <summary>
  ; Read a boolean VyrnValue.
  ; </summary>
  ; <param name="*v">Source value.</param>
  ; <returns>#True only when type is bool and boolVal is set; otherwise #False.</returns>
  Procedure.i Vyrn_AsBool(*v.VyrnValue)
    If *v = 0 Or *v\type <> #VYRN_TYPE_BOOL
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn Bool(*v\boolVal)
  EndProcedure

  ; <summary>
  ; Read the number field (does not require TYPE_NUMBER).
  ; </summary>
  ; <param name="*v">Source value.</param>
  ; <returns>number field, or 0 if *v is 0.</returns>
  Procedure.d Vyrn_AsNumber(*v.VyrnValue)
    If *v = 0
      ProcedureReturn 0
    EndIf
    
    ProcedureReturn *v\number
  EndProcedure

  ; <summary>
  ; Read a table id from a TABLE-typed value.
  ; </summary>
  ; <param name="*v">Source value.</param>
  ; <returns>Table id, or 0 if missing / wrong type.</returns>
  Procedure.i Vyrn_AsTableId(*v.VyrnValue)
    If *v = 0 Or *v\type <> #VYRN_TYPE_TABLE
      ProcedureReturn 0
    EndIf
    
    ProcedureReturn Int(*v\number)
  EndProcedure

  ; <summary>
  ; Copy a STRING-typed value into a PureBasic string (safe across later DLL calls).
  ; </summary>
  ; <param name="*v">Source value.</param>
  ; <returns>Copied string, or empty if not a string.</returns>
  Procedure.s Vyrn_AsString(*v.VyrnValue)
    If *v = 0 Or *v\type <> #VYRN_TYPE_STRING
      ProcedureReturn ""
    EndIf
    
    ProcedureReturn Vyrn_CopyUtf8(*v\STR)
  EndProcedure

  ; <summary>
  ; Copy one host-callback argument from an args array into *dst.
  ; </summary>
  ; <param name="*dst">Destination VyrnValue.</param>
  ; <param name="*args">Pointer to VyrnValue[argc] from the DLL.</param>
  ; <param name="argc">Argument count.</param>
  ; <param name="index">0-based argument index.</param>
  ; <returns>#True if copied; #False if out of range or null.</returns>
  Procedure.i Vyrn_GetArg(*dst.VyrnValue, *args, argc.i, index.i)
    If *dst = 0
      ProcedureReturn #False
    EndIf
    
    Vyrn_ClearValue(*dst)
    
    If *args = 0 Or index < 0 Or index >= argc
      ProcedureReturn #False
    EndIf
    
    CopyMemory(*args + index * SizeOf(VyrnValue), *dst, SizeOf(VyrnValue))
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Product version string from the loaded DLL.
  ; </summary>
  ; <returns>Version text, or "(DLL not loaded)" when unavailable.</returns>
  Procedure.s Vyrn_ProductVersion()
    If Vyrn_ProductVer <> ""
      ProcedureReturn Vyrn_ProductVer
    EndIf
    
    ProcedureReturn "(DLL not loaded)"
  EndProcedure

  ; <summary>
  ; Whether the library is loaded and a VM handle exists.
  ; </summary>
  ; <returns>#True when ready for API calls.</returns>
  Procedure.i Vyrn_IsReady()
    ProcedureReturn Bool(Vyrn_Loaded And Vyrn_Vm <> 0)
  EndProcedure

  ; <summary>
  ; Clear function pointers, globals, and scratch after unload or failed open.
  ; </summary>
  Procedure Vyrn_ResetFns()
    Vyrn_Fn_AbiVersion = 0
    Vyrn_Fn_Version = 0
    Vyrn_Fn_Create = 0
    Vyrn_Fn_Destroy = 0
    Vyrn_Fn_RequestCancel = 0
    Vyrn_Fn_SetLimits = 0
    Vyrn_Fn_SetPrintLogger = 0
    Vyrn_Fn_RunFile = 0
    Vyrn_Fn_Eval = 0
    Vyrn_Fn_CallGlobal = 0
    Vyrn_Fn_CallGlobalMulti = 0
    Vyrn_Fn_GetGlobal = 0
    Vyrn_Fn_SetGlobal = 0
    Vyrn_Fn_TableGet = 0
    Vyrn_Fn_TableSet = 0
    Vyrn_Fn_Register = 0
    Vyrn_Fn_CoCreate = 0
    Vyrn_Fn_CoResume = 0
    Vyrn_Fn_CoClose = 0
    Vyrn_Fn_CoYielded = 0
    Vyrn_Fn_CoFinished = 0
    Vyrn_Fn_LastError = 0
    Vyrn_Fn_LastErrorCode = 0
    Vyrn_Fn_WarningCount = 0
    Vyrn_Fn_GetWarning = 0
    Vyrn_Fn_CopyString = 0
    Vyrn_ClearScratch()
    Vyrn_Loaded = #False
    Vyrn_DllPath = ""
    Vyrn_ProductVer = ""
    Vyrn_Abi = 0
    Vyrn_Vm = 0
  EndProcedure

  ; <summary>
  ; Destroy the VM (if any) and close Vyrn.dll.
  ; </summary>
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

  ; <summary>
  ; Emergency reload: drop the library without vyrn_destroy, then reopen (prefer RequestCancel + Reset).
  ; </summary>
  ; <returns>#True if a DLL was loaded successfully afterward.</returns>
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

  ; <summary>
  ; Open path as Vyrn.dll, bind exports, check ABI, and create the default VM.
  ; </summary>
  ; <param name="path">Full path to Vyrn.dll / LibVyrn.dll.</param>
  ; <returns>#True on success; sets Vyrn_LastError on failure.</returns>
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
    Vyrn_Fn_RequestCancel = GetFunction(#Vyrn_Lib, "vyrn_request_cancel")
    Vyrn_Fn_SetLimits = GetFunction(#Vyrn_Lib, "vyrn_set_limits")
    Vyrn_Fn_SetPrintLogger = GetFunction(#Vyrn_Lib, "vyrn_set_print_logger")
    Vyrn_Fn_RunFile = GetFunction(#Vyrn_Lib, "vyrn_run_file")
    Vyrn_Fn_Eval = GetFunction(#Vyrn_Lib, "vyrn_eval")
    Vyrn_Fn_CallGlobal = GetFunction(#Vyrn_Lib, "vyrn_call_global")
    Vyrn_Fn_CallGlobalMulti = GetFunction(#Vyrn_Lib, "vyrn_call_global_multi")
    Vyrn_Fn_GetGlobal = GetFunction(#Vyrn_Lib, "vyrn_get_global")
    Vyrn_Fn_SetGlobal = GetFunction(#Vyrn_Lib, "vyrn_set_global")
    Vyrn_Fn_TableGet = GetFunction(#Vyrn_Lib, "vyrn_table_get")
    Vyrn_Fn_TableSet = GetFunction(#Vyrn_Lib, "vyrn_table_set")
    Vyrn_Fn_Register = GetFunction(#Vyrn_Lib, "vyrn_register")
    Vyrn_Fn_CoCreate = GetFunction(#Vyrn_Lib, "vyrn_coroutine_create_global")
    Vyrn_Fn_CoResume = GetFunction(#Vyrn_Lib, "vyrn_coroutine_resume")
    Vyrn_Fn_CoClose = GetFunction(#Vyrn_Lib, "vyrn_coroutine_close")
    Vyrn_Fn_CoYielded = GetFunction(#Vyrn_Lib, "vyrn_coroutine_yielded")
    Vyrn_Fn_CoFinished = GetFunction(#Vyrn_Lib, "vyrn_coroutine_finished")
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
    
    If Vyrn_Fn_CallGlobal = 0 Or Vyrn_Fn_CallGlobalMulti = 0 Or Vyrn_Fn_GetGlobal = 0 Or Vyrn_Fn_SetGlobal = 0 Or Vyrn_Fn_TableGet = 0 Or Vyrn_Fn_TableSet = 0 Or Vyrn_Fn_Register = 0
      Vyrn_LastError = "Vyrn.dll is missing value/host exports:" + Chr(10) + path
      CloseLibrary(#Vyrn_Lib)
      
      ProcedureReturn #False
    EndIf
    
    If Vyrn_Fn_CoCreate = 0 Or Vyrn_Fn_CoResume = 0 Or Vyrn_Fn_CoClose = 0 Or Vyrn_Fn_CoYielded = 0 Or Vyrn_Fn_CoFinished = 0 Or Vyrn_Fn_WarningCount = 0 Or Vyrn_Fn_GetWarning = 0 Or Vyrn_Fn_CopyString = 0
      Vyrn_LastError = "Vyrn.dll is missing ABI 4 exports (coroutine/warnings):" + Chr(10) + path
      CloseLibrary(#Vyrn_Lib)
      
      ProcedureReturn #False
    EndIf
    If Vyrn_Fn_RequestCancel = 0
      Vyrn_LastError = "Vyrn.dll is missing ABI 5 export vyrn_request_cancel:" + Chr(10) + path
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

  ; <summary>
  ; Search common locations (exe dir, Runtime\, %VYRN_DLL%, native\, cwd) and load Vyrn.dll.
  ; </summary>
  ; <returns>#True if loaded; sets Vyrn_LastError with search hints on failure.</returns>
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

  ; <summary>
  ; Ensure the DLL and VM are ready; load if needed.
  ; </summary>
  ; <returns>#True when Vyrn_IsReady after this call.</returns>
  Procedure.i Vyrn_Ensure()
    If Vyrn_IsReady()
      ProcedureReturn #True
    EndIf
    
    ProcedureReturn Vyrn_Load()
  EndProcedure

  ; <summary>
  ; Request cooperative cancel of the current script (ABI 5).
  ; </summary>
  ; <returns>#True if the DLL accepted the cancel request.</returns>
  Procedure.i Vyrn_RequestCancel()
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_RequestCancel = 0
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn Bool(Vyrn_Fn_RequestCancel(Vyrn_Vm) <> 0)
  EndProcedure

  ; <summary>
  ; Destroy and recreate the VM without unloading the DLL (after cooperative cancel).
  ; </summary>
  ; <returns>#True if a new VM was created (or Ensure succeeded).</returns>
  Procedure.i Vyrn_Reset()
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_Create = 0 Or Vyrn_Fn_Destroy = 0
      ProcedureReturn Vyrn_Ensure()
    EndIf
    
    Vyrn_Fn_Destroy(Vyrn_Vm)
    Vyrn_Vm = 0
    Vyrn_Vm = Vyrn_Fn_Create()
    
    If Vyrn_Vm = 0
      Vyrn_LastError = "vyrn_create failed during reset"
      ProcedureReturn #False
    EndIf
    
    If Vyrn_Fn_SetLimits
      Vyrn_Fn_SetLimits(Vyrn_Vm, 100000, 256, 1000000)
    EndIf
    
    Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Install a print logger callback for script print() output.
  ; </summary>
  ; <param name="logFn">Address of a ProcedureC(userdata, *msg) logger, or 0 to clear.</param>
  ; <param name="userdata">Opaque pointer passed to the logger.</param>
  Procedure Vyrn_SetPrintLogger(logFn.i, userdata.i = 0)
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_SetPrintLogger = 0
      ProcedureReturn
    EndIf
    
    Vyrn_Fn_SetPrintLogger(Vyrn_Vm, logFn, userdata)
  EndProcedure

  ; <summary>
  ; Set VM execution limits (loops, call depth, instructions).
  ; </summary>
  ; <param name="maxLoops">Maximum loop iterations.</param>
  ; <param name="maxCalls">Maximum call depth.</param>
  ; <param name="maxIns">Maximum instructions.</param>
  ; <returns>#True if limits were applied.</returns>
  Procedure.i Vyrn_SetLimits(maxLoops.i, maxCalls.i, maxIns.i)
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_SetLimits = 0
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn Bool(Vyrn_Fn_SetLimits(Vyrn_Vm, maxLoops, maxCalls, maxIns))
  EndProcedure

  ; <summary>
  ; Read the last error message from the VM (or the cached Vyrn_LastError if not ready).
  ; </summary>
  ; <returns>Error text (may be empty).</returns>
  Procedure.s Vyrn_FetchLastError()
    Protected *p
    
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_LastError = 0
      ProcedureReturn Vyrn_LastError
    EndIf
    
    *p = Vyrn_Fn_LastError(Vyrn_Vm)
    
    ProcedureReturn Vyrn_CopyUtf8(*p)
  EndProcedure

  ; <summary>
  ; Last error code from the VM (#VYRN_ERR_*).
  ; </summary>
  ; <returns>Error code, or #VYRN_ERR_OTHER when unavailable.</returns>
  Procedure.i Vyrn_LastErrorCode()
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_LastErrorCode = 0
      ProcedureReturn #VYRN_ERR_OTHER
    EndIf
    ProcedureReturn Vyrn_Fn_LastErrorCode(Vyrn_Vm)
  EndProcedure

  ; <summary>
  ; Compile and run a .vyrn/.lua file on the default VM.
  ; </summary>
  ; <param name="path">Script file path.</param>
  ; <returns>#True on success; sets Vyrn_LastError on failure.</returns>
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

  ; <summary>
  ; Compile and evaluate a source string on the default VM.
  ; </summary>
  ; <param name="source">Script source text.</param>
  ; <returns>#True on success; sets Vyrn_LastError on failure.</returns>
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

  ; <summary>
  ; Number of warnings from the last compile/run.
  ; </summary>
  ; <returns>Warning count, or 0 if not ready.</returns>
  Procedure.i Vyrn_WarningCount()
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_WarningCount = 0
      ProcedureReturn 0
    EndIf
    
    ProcedureReturn Vyrn_Fn_WarningCount(Vyrn_Vm)
  EndProcedure

  ; <summary>
  ; Get one warning message by index.
  ; </summary>
  ; <param name="index">0-based warning index.</param>
  ; <returns>Warning text, or empty if unavailable.</returns>
  Procedure.s Vyrn_GetWarning(index.i)
    Protected *p
    
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_GetWarning = 0
      ProcedureReturn ""
    EndIf
    
    *p = Vyrn_Fn_GetWarning(Vyrn_Vm, index)
    
    ProcedureReturn Vyrn_CopyUtf8(*p)
  EndProcedure

  ; <summary>
  ; Register a host callback as a global function visible to scripts.
  ; </summary>
  ; <param name="name">Global function name.</param>
  ; <param name="fnPtr">Address of a VyrnHostFn ProcedureC.</param>
  ; <param name="userdata">Opaque pointer passed to the callback.</param>
  ; <returns>#True on success.</returns>
  Procedure.i Vyrn_Register(name.s, fnPtr.i, userdata.i = 0)
    Protected *utf, ok.i
    
    If Vyrn_Ensure() = 0 Or Vyrn_Fn_Register = 0
      ProcedureReturn #False
    EndIf
    
    If name = "" Or fnPtr = 0
      Vyrn_LastError = "vyrn_register: bad name or callback"
      ProcedureReturn #False
    EndIf
    
    *utf = UTF8(name)
    
    If *utf = 0
      Vyrn_LastError = "UTF-8 conversion failed for name"
      
      ProcedureReturn #False
    EndIf
    
    ok = Vyrn_Fn_Register(Vyrn_Vm, *utf, fnPtr, userdata)
    FreeMemory(*utf)
    
    If ok = 0
      ProcedureReturn Vyrn_FailCall()
    EndIf
    
    Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Call a global script function with up to #VYRN_MAX_ARGS arguments; one return value.
  ; </summary>
  ; <param name="name">Global function name.</param>
  ; <param name="*args">Array of VyrnValue arguments (may be 0 if argc is 0).</param>
  ; <param name="argc">Argument count (clamped to #VYRN_MAX_ARGS).</param>
  ; <param name="*out">Receives the single return value.</param>
  ; <returns>#True on success; clears scratch on success.</returns>
  Procedure.i Vyrn_CallGlobal(name.s, *args.VyrnValue, argc.i, *out.VyrnValue)
    Protected *utf, ok.i, argsPtr.i
    
    If Vyrn_Ensure() = 0 Or Vyrn_Fn_CallGlobal = 0
      ProcedureReturn #False
    EndIf
    
    If argc < 0
      argc = 0
    EndIf
    
    If argc > #VYRN_MAX_ARGS
      argc = #VYRN_MAX_ARGS
    EndIf
    
    *utf = UTF8(name)
    
    If *utf = 0
      Vyrn_LastError = "UTF-8 conversion failed for name"
      ProcedureReturn #False
    EndIf
    
    argsPtr = 0
    
    If argc > 0 And *args
      argsPtr = *args
    EndIf
    
    ok = Vyrn_Fn_CallGlobal(Vyrn_Vm, *utf, argsPtr, argc, *out)
    
    FreeMemory(*utf)
    
    If ok = 0
      If *out
        Vyrn_ClearValue(*out)
      EndIf
      
      ProcedureReturn Vyrn_FailCall()
    EndIf
    
    Vyrn_ClearScratch()
    Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Call a global with multiple return values (up to #VYRN_MAX_OUTS).
  ; </summary>
  ; <param name="name">Global function name.</param>
  ; <param name="*args">Argument array.</param>
  ; <param name="argc">Argument count.</param>
  ; <param name="*outs">Output VyrnValue array.</param>
  ; <param name="maxOut">Capacity of *outs (must be &gt;= 1).</param>
  ; <param name="*outCount">Receives how many values were written.</param>
  ; <returns>#True on success.</returns>
  Procedure.i Vyrn_CallGlobalMulti(name.s, *args.VyrnValue, argc.i, *outs.VyrnValue, maxOut.i, *outCount)
    Protected *utf, ok.i, argsPtr.i, n.i
    
    If Vyrn_Ensure() = 0 Or Vyrn_Fn_CallGlobalMulti = 0
      ProcedureReturn #False
    EndIf
    
    If argc < 0
      argc = 0
    EndIf
    
    If argc > #VYRN_MAX_ARGS
      argc = #VYRN_MAX_ARGS
    EndIf
    
    n = maxOut
    
    If n < 1
      Vyrn_LastError = "vyrn_call_global_multi: max_out < 1"
      
      ProcedureReturn #False
    EndIf
    
    If n > #VYRN_MAX_OUTS
      n = #VYRN_MAX_OUTS
    EndIf
    
    *utf = UTF8(name)
    
    If *utf = 0
      Vyrn_LastError = "UTF-8 conversion failed for name"
      
      ProcedureReturn #False
    EndIf
    
    argsPtr = 0
    
    If argc > 0 And *args
      argsPtr = *args
    EndIf
    
    ok = Vyrn_Fn_CallGlobalMulti(Vyrn_Vm, *utf, argsPtr, argc, *outs, n, *outCount)
    FreeMemory(*utf)
    
    If ok = 0
      If *outCount
        PokeL(*outCount, 0)
      EndIf
      
      ProcedureReturn Vyrn_FailCall()
    EndIf
    
    Vyrn_ClearScratch()
    Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Read a global variable into *out.
  ; </summary>
  ; <param name="name">Global name.</param>
  ; <param name="*out">Receives the value.</param>
  ; <returns>#True on success.</returns>
  Procedure.i Vyrn_GetGlobal(name.s, *out.VyrnValue)
    Protected *utf, ok.i
    
    If Vyrn_Ensure() = 0 Or Vyrn_Fn_GetGlobal = 0
      ProcedureReturn #False
    EndIf
    
    *utf = UTF8(name)
    
    If *utf = 0
      Vyrn_LastError = "UTF-8 conversion failed for name"
      
      ProcedureReturn #False
    EndIf
    
    ok = Vyrn_Fn_GetGlobal(Vyrn_Vm, *utf, *out)
    FreeMemory(*utf)
    
    If ok = 0
      If *out
        Vyrn_ClearValue(*out)
      EndIf
      
      ProcedureReturn Vyrn_FailCall()
    EndIf
    
    Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Write a value into a global variable.
  ; </summary>
  ; <param name="name">Global name.</param>
  ; <param name="*val">Value to store.</param>
  ; <returns>#True on success; clears scratch on success.</returns>
  Procedure.i Vyrn_SetGlobal(name.s, *val.VyrnValue)
    Protected *utf, ok.i
    
    If Vyrn_Ensure() = 0 Or Vyrn_Fn_SetGlobal = 0
      ProcedureReturn #False
    EndIf
    
    *utf = UTF8(name)
    
    If *utf = 0
      Vyrn_LastError = "UTF-8 conversion failed for name"
      
      ProcedureReturn #False
    EndIf
    
    ok = Vyrn_Fn_SetGlobal(Vyrn_Vm, *utf, *val)
    FreeMemory(*utf)
    
    If ok = 0
      ProcedureReturn Vyrn_FailCall()
    EndIf
    
    Vyrn_ClearScratch()
    Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Read table[key] into *out.
  ; </summary>
  ; <param name="tableId">Table handle from a TABLE value.</param>
  ; <param name="*key">Key value.</param>
  ; <param name="*out">Receives the looked-up value.</param>
  ; <returns>#True on success.</returns>
  Procedure.i Vyrn_TableGet(tableId.i, *key.VyrnValue, *out.VyrnValue)
    Protected ok.i
    
    If Vyrn_Ensure() = 0 Or Vyrn_Fn_TableGet = 0
      ProcedureReturn #False
    EndIf
    
    ok = Vyrn_Fn_TableGet(Vyrn_Vm, tableId, *key, *out)
    
    If ok = 0
      If *out
        Vyrn_ClearValue(*out)
      EndIf
      
      ProcedureReturn Vyrn_FailCall()
    EndIf
    
    Vyrn_ClearScratch()
    Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Write table[key] = val.
  ; </summary>
  ; <param name="tableId">Table handle.</param>
  ; <param name="*key">Key value.</param>
  ; <param name="*val">Value to store.</param>
  ; <returns>#True on success.</returns>
  Procedure.i Vyrn_TableSet(tableId.i, *key.VyrnValue, *val.VyrnValue)
    Protected ok.i
    
    If Vyrn_Ensure() = 0 Or Vyrn_Fn_TableSet = 0
      
      ProcedureReturn #False
    EndIf
    
    ok = Vyrn_Fn_TableSet(Vyrn_Vm, tableId, *key, *val)
    
    If ok = 0
      ProcedureReturn Vyrn_FailCall()
    EndIf
    
    Vyrn_ClearScratch()
    Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Create a coroutine from a global function; *out receives the coroutine id value.
  ; </summary>
  ; <param name="name">Global function name to wrap.</param>
  ; <param name="*out">Receives the coroutine handle value.</param>
  ; <returns>#True on success.</returns>
  Procedure.i Vyrn_CoroutineCreateGlobal(name.s, *out.VyrnValue)
    Protected *utf, ok.i
    
    If Vyrn_Ensure() = 0 Or Vyrn_Fn_CoCreate = 0
      ProcedureReturn #False
    EndIf
    
    *utf = UTF8(name)
    
    If *utf = 0
      Vyrn_LastError = "UTF-8 conversion failed for name"
      
      ProcedureReturn #False
    EndIf
    
    ok = Vyrn_Fn_CoCreate(Vyrn_Vm, *utf, *out)
    FreeMemory(*utf)
    
    If ok = 0
      If *out
        Vyrn_ClearValue(*out)
      EndIf
      
      ProcedureReturn Vyrn_FailCall()
    EndIf
    
    Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Resume a coroutine with optional args; fills *outs / *outCount with yields or returns.
  ; </summary>
  ; <param name="tid">Coroutine id.</param>
  ; <param name="*args">Argument array (may be 0).</param>
  ; <param name="argc">Argument count.</param>
  ; <param name="*outs">Output value array.</param>
  ; <param name="maxOut">Capacity of *outs.</param>
  ; <param name="*outCount">Receives written count.</param>
  ; <returns>#True on success (check Yielded/Finished for status).</returns>
  Procedure.i Vyrn_CoroutineResume(tid.i, *args.VyrnValue, argc.i, *outs.VyrnValue, maxOut.i, *outCount)
    Protected ok.i, argsPtr.i, n.i
    
    If Vyrn_Ensure() = 0 Or Vyrn_Fn_CoResume = 0
      ProcedureReturn #False
    EndIf
    
    If argc < 0
      argc = 0
    EndIf
    
    If argc > #VYRN_MAX_ARGS
      argc = #VYRN_MAX_ARGS
    EndIf
    
    n = maxOut
    
    If n < 1
      n = 1
    EndIf
    
    If n > #VYRN_MAX_OUTS
      n = #VYRN_MAX_OUTS
    EndIf
    
    argsPtr = 0
    If argc > 0 And *args
      argsPtr = *args
    EndIf
    
    ok = Vyrn_Fn_CoResume(Vyrn_Vm, tid, argsPtr, argc, *outs, n, *outCount)
    
    If ok = 0
      If *outCount
        PokeL(*outCount, 0)
      EndIf
      
      ProcedureReturn Vyrn_FailCall()
    EndIf
    
    Vyrn_ClearScratch()
    Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Close a coroutine, optionally with an error message.
  ; </summary>
  ; <param name="tid">Coroutine id.</param>
  ; <param name="errMsg">Optional close reason (empty for none).</param>
  ; <returns>#True on success.</returns>
  Procedure.i Vyrn_CoroutineClose(tid.i, errMsg.s = "")
    Protected *utf, ok.i
    
    If Vyrn_Ensure() = 0 Or Vyrn_Fn_CoClose = 0
      ProcedureReturn #False
    EndIf
    
    *utf = 0
    
    If errMsg <> ""
      *utf = UTF8(errMsg)
    EndIf
    
    ok = Vyrn_Fn_CoClose(Vyrn_Vm, tid, *utf)
    
    If *utf
      FreeMemory(*utf)
    EndIf
    
    If ok = 0
      ProcedureReturn Vyrn_FailCall()
    EndIf
    
    Vyrn_LastError = ""
    
    ProcedureReturn #True
  EndProcedure

  ; <summary>
  ; Whether the last coroutine resume left the coroutine yielded.
  ; </summary>
  ; <returns>#True if yielded.</returns>
  Procedure.i Vyrn_CoroutineYielded()
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_CoYielded = 0
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn Bool(Vyrn_Fn_CoYielded(Vyrn_Vm))
  EndProcedure

  ; <summary>
  ; Whether the last coroutine resume finished the coroutine.
  ; </summary>
  ; <returns>#True if finished.</returns>
  Procedure.i Vyrn_CoroutineFinished()
    If Vyrn_IsReady() = 0 Or Vyrn_Fn_CoFinished = 0
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn Bool(Vyrn_Fn_CoFinished(Vyrn_Vm))
  EndProcedure

CompilerEndIf

; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 1267
; FirstLine = 1223
; Folding = --------
; Optimizer
; EnableAsm
; EnableXP
; DPIAware
; DllProtection
; EnableOnError
; DisableDebugger
; CompileSourceDirectory
; Compiler = PureBasic 6.41 - C Backend (Windows - x64)