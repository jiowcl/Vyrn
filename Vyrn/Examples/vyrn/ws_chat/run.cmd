@echo off
setlocal
cd /d "%~dp0\..\..\.."
if not exist "Vyrn.exe" (
  echo [error] Vyrn.exe not found in repo root:
  echo   %CD%
  echo Compile LuaLite_Main.pb first.
  pause
  exit /b 1
)
echo Starting WebSocket chat on ws://127.0.0.1:8765
echo Open examples\vyrn\ws_chat\client.html in a browser.
echo.
Vyrn.exe serve examples\vyrn\ws_chat\chat.vyrn --port 8765
set ERR=%ERRORLEVEL%
if not "%ERR%"=="0" pause
exit /b %ERR%
