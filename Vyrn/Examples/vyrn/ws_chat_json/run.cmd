@echo off
setlocal
cd /d "%~dp0\..\..\.."
set "EXE="
if exist "Vyrn.exe" set "EXE=Vyrn.exe"
if "%EXE%"=="" if exist "bin\LuaLiteVM_build.exe" set "EXE=bin\LuaLiteVM_build.exe"
if "%EXE%"=="" (
  echo [error] Vyrn.exe not found. Compile LuaLite_Main.pb first.
  pause
  exit /b 1
)
echo JSON chat + binary ping demo
echo   http://127.0.0.1:8766/
echo.
"%EXE%" serve examples\vyrn\ws_chat_json\chat.vyrn --port 8766
set ERR=%ERRORLEVEL%
if not "%ERR%"=="0" pause
exit /b %ERR%
