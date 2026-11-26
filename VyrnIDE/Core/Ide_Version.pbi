;--------------------------------------------------------------------------------------------
;  Copyright (c) Ji-Feng Tsai. All rights reserved.
;  Code released under the MIT license.
;--------------------------------------------------------------------------------------------

; Vyrn IDE - product version string (repo VERSION file)
; PureBasic 6.41

CompilerIf Defined(Ide_Version, #PB_Constant) = #False
  #Ide_Version = #True

  ; <summary>
  ; Read the first line of VERSION next to the IDE or repo root.
  ; </summary>
  ; <returns>string</returns>
  Procedure.s Ide_App_ReadVersion()
    Protected dir.s = GetPathPart(ProgramFilename())
    Protected root.s, path.s, fn.i, line.s
    Protected i.i
    For i = 1 To 4
      path = dir + "VERSION"
      If FileSize(path) >= 0
        fn = ReadFile(#PB_Any, path)
        If fn
          line = Trim(ReadString(fn))
          CloseFile(fn)
          If line <> ""
            ProcedureReturn line
          EndIf
        EndIf
      EndIf
      dir = GetPathPart(Left(dir, Len(dir) - 1))
      If Len(dir) < 3
        Break
      EndIf
    Next
    root = Ide_Runner_FindRepoRoot()
    If root <> ""
      path = root + "VERSION"
      If FileSize(path) >= 0
        fn = ReadFile(#PB_Any, path)
        If fn
          line = Trim(ReadString(fn))
          CloseFile(fn)
          If line <> ""
            ProcedureReturn line
          EndIf
        EndIf
      EndIf
    EndIf
    ProcedureReturn "IDE"
  EndProcedure

CompilerEndIf
; IDE Options = PureBasic 6.41 (Windows - x64)
; CursorPosition = 14
; Folding = -
; Optimizer
; EnableThread
; EnableOnError
; CompileSourceDirectory
; Compiler = PureBasic 6.40 - C Backend (Windows - x64)