@echo off
setlocal EnableExtensions EnableDelayedExpansion
title USBArmyKnife Agent Uninstaller

set "DEST=C:\AgentInstall"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SETTINGS=%DEST%\VncDirect\vnc-settings.json"

net session >nul 2>&1
if !errorlevel! neq 0 (
    echo Administrator privileges required...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:show_menu
set "VNC_RUNNING=0"
tasklist /FI "IMAGENAME eq VncDirect.exe" 2>nul | find /i "VncDirect.exe" >nul
if !errorlevel! equ 0 set "VNC_RUNNING=1"

set "HAS_AUTOSTART=0"
schtasks /query /tn "USBArmyKnife Agent" >nul 2>&1
if !errorlevel! equ 0 set "HAS_AUTOSTART=1"
schtasks /query /tn "VNC Watchdog" >nul 2>&1
if !errorlevel! equ 0 set "HAS_AUTOSTART=1"

set "HAS_PASSWORD=0"
if exist "%SETTINGS%" (
    powershell -NoProfile -Command "try { $j = Get-Content '%SETTINGS%' -Raw | ConvertFrom-Json; if ($j.password -ne '' -and $j.password -ne $null) { exit 0 } } catch {}; exit 1"
    if !errorlevel! equ 0 set "HAS_PASSWORD=1"
)

cls
echo.
echo ========================================
echo   USBArmyKnife Agent Uninstaller
echo ========================================
echo.
echo   [1] Full Uninstall
echo       Removes autostart, all files and firewall rules.
echo.

if "%HAS_AUTOSTART%"=="1" (
    echo   [2] Remove Autostart only
    echo       Autostart is active. Remove it, files stay installed.
) else (
    echo   [2] Setup Autostart
    echo       Autostart is not set. Create scheduled tasks.
)
echo.

if "%VNC_RUNNING%"=="1" (
    echo   [3] Stop VNC Server
    echo       VNC Server is running on port 7002.
) else (
    echo   [3] Start VNC Server
    echo       VNC Server is not running.
)
echo.

if "%HAS_PASSWORD%"=="1" (
    echo   [4] Change VNC Password
    echo       A password is currently set.
) else (
    echo   [4] Set VNC Password
    echo       No password is set.
)
echo.
echo   [5] Exit
echo.
echo ========================================
echo.

set /p "CHOICE=Select option (1-5): "

if "%CHOICE%"=="1" goto UNINSTALL_ALL
if "%CHOICE%"=="2" goto TOGGLE_AUTOSTART
if "%CHOICE%"=="3" goto TOGGLE_VNC
if "%CHOICE%"=="4" goto MANAGE_PASSWORD
if "%CHOICE%"=="5" exit /b 0
echo.
echo Invalid input. Please select 1-5.
timeout /t 3 /nobreak >nul
goto show_menu

:UNINSTALL_ALL
echo.
echo === Full Uninstall ===
echo.
echo [1/6] Stopping running processes...
taskkill /F /IM AgentLauncher.exe >nul 2>&1
taskkill /F /IM VncDirect.exe >nul 2>&1
wmic process where "commandline like '%%vnc-watchdog%%'" call terminate >nul 2>&1
timeout /t 2 /nobreak >nul

echo [2/6] Removing autostart...
if exist "%STARTUP%\USBArmyKnifeAgent.vbs" ( del "%STARTUP%\USBArmyKnifeAgent.vbs" >nul 2>&1 & echo    [+] USBArmyKnifeAgent.vbs removed. )
if exist "%STARTUP%\VncDirect.vbs" ( del "%STARTUP%\VncDirect.vbs" >nul 2>&1 & echo    [+] VncDirect.vbs removed. )
schtasks /query /tn "USBArmyKnife Agent" >nul 2>&1
if !errorlevel! equ 0 ( schtasks /delete /tn "USBArmyKnife Agent" /f >nul 2>&1 & echo    [+] Scheduled task "USBArmyKnife Agent" removed. )
schtasks /query /tn "Security Script" >nul 2>&1
if !errorlevel! equ 0 ( schtasks /delete /tn "Security Script" /f >nul 2>&1 & echo    [+] Scheduled task "Security Script" removed. )
schtasks /query /tn "VNC Watchdog" >nul 2>&1
if !errorlevel! equ 0 ( schtasks /delete /tn "VNC Watchdog" /f >nul 2>&1 & echo    [+] Scheduled task "VNC Watchdog" removed. )
schtasks /query /tn "VNC Direct" >nul 2>&1
if !errorlevel! equ 0 ( schtasks /delete /tn "VNC Direct" /f >nul 2>&1 & echo    [+] Scheduled task "VNC Direct" removed. )

echo [3/6] Removing firewall rules...
netsh advfirewall firewall show rule name="VNC Direct 7002" >nul 2>&1
if !errorlevel! equ 0 ( netsh advfirewall firewall delete rule name="VNC Direct 7002" >nul 2>&1 & echo    [+] Firewall rule "VNC Direct 7002" removed. ) else ( echo    [-] not found. )
netsh advfirewall firewall show rule name="VNC Block Localhost" >nul 2>&1
if !errorlevel! equ 0 ( netsh advfirewall firewall delete rule name="VNC Block Localhost" >nul 2>&1 & netsh advfirewall firewall delete rule name="VNC Block Localhost v6" >nul 2>&1 & echo    [+] Firewall rules "VNC Block Localhost" removed. ) else ( echo    [-] not found. )

echo [4/6] Deleting files...
if exist "%DEST%" (
    rmdir /s /q "%DEST%" >nul 2>&1
    if not exist "%DEST%" ( echo    [+] %DEST% deleted. ) else ( echo    [!] Some files in use. Delete manually. )
)

echo [5/6] Re-enabling UAC...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f >nul 2>&1
echo    [+] UAC re-enabled. Restart required.

echo [6/6] Done.
echo.
echo ========================================
echo   Uninstall complete!
echo ========================================
echo.
echo Window closes in 10 seconds...
timeout /t 10 /nobreak >nul
exit /b 0

:TOGGLE_AUTOSTART
if "%HAS_AUTOSTART%"=="1" goto REMOVE_AUTOSTART
goto ADD_AUTOSTART

:REMOVE_AUTOSTART
echo.
echo === Removing Autostart ===
echo.
echo [1/3] Stopping processes...
taskkill /F /IM AgentLauncher.exe >nul 2>&1
taskkill /F /IM VncDirect.exe >nul 2>&1
wmic process where "commandline like '%%vnc-watchdog%%'" call terminate >nul 2>&1
timeout /t 1 /nobreak >nul

echo [2/3] Removing entries...
if exist "%STARTUP%\USBArmyKnifeAgent.vbs" ( del "%STARTUP%\USBArmyKnifeAgent.vbs" >nul 2>&1 & echo    [+] VBS removed. )
if exist "%STARTUP%\VncDirect.vbs" ( del "%STARTUP%\VncDirect.vbs" >nul 2>&1 & echo    [+] VBS removed. )
schtasks /query /tn "USBArmyKnife Agent" >nul 2>&1
if !errorlevel! equ 0 ( schtasks /delete /tn "USBArmyKnife Agent" /f >nul 2>&1 & echo    [+] Task removed. )
schtasks /query /tn "Security Script" >nul 2>&1
if !errorlevel! equ 0 ( schtasks /delete /tn "Security Script" /f >nul 2>&1 & echo    [+] Task removed. )
schtasks /query /tn "VNC Watchdog" >nul 2>&1
if !errorlevel! equ 0 ( schtasks /delete /tn "VNC Watchdog" /f >nul 2>&1 & echo    [+] Task removed. )
schtasks /query /tn "VNC Direct" >nul 2>&1
if !errorlevel! equ 0 ( schtasks /delete /tn "VNC Direct" /f >nul 2>&1 & echo    [+] Task removed. )

echo [3/3] Done.
echo.
echo Autostart successfully removed.
goto wait_menu

:ADD_AUTOSTART
echo.
echo === Setting up Autostart ===
echo.
if not exist "%DEST%\AgentLauncher.exe" (
    echo    [!] AgentLauncher.exe not found. Run installer first.
    echo.
    pause
    goto show_menu
)

echo Creating scheduled tasks...
schtasks /query /tn "USBArmyKnife Agent" >nul 2>&1
if !errorlevel! neq 0 ( schtasks /create /tn "USBArmyKnife Agent" /tr "%DEST%\AgentLauncher.exe vid=cafe pid=403f cwd=%DEST%" /sc onlogon /rl limited /f >nul 2>&1 & echo    [+] Task created. ) else ( echo    [-] Already exists. )
schtasks /query /tn "Security Script" >nul 2>&1
if !errorlevel! neq 0 ( schtasks /create /tn "Security Script" /tr "%DEST%\AgentLauncher.exe vid=cafe pid=403f cwd=%DEST%" /sc onlogon /rl limited /f >nul 2>&1 & echo    [+] Task created. ) else ( echo    [-] Already exists. )
schtasks /query /tn "VNC Watchdog" >nul 2>&1
if !errorlevel! neq 0 ( schtasks /create /tn "VNC Watchdog" /tr "powershell.exe -NoProfile -WindowStyle Hidden -Command \"while($true){if(!(Get-Process VncDirect -EA SilentlyContinue)){Start-Process '%DEST%\VncDirect\VncDirect.exe' -ArgumentList 'port=7002 cwd=%DEST%\VncDirect\vnc fps=360 scale=0'};Start-Sleep 5}\"" /sc onlogon /rl limited /f >nul 2>&1 & echo    [+] Task created. ) else ( echo    [-] Already exists. )
schtasks /query /tn "VNC Direct" >nul 2>&1
if !errorlevel! neq 0 ( schtasks /create /tn "VNC Direct" /tr "\"%DEST%\VncDirect\VncDirect.exe\" port=7002 cwd=\"%DEST%\VncDirect\vnc\" fps=360 scale=0" /sc onlogon /rl highest /it /f >nul 2>&1 & echo    [+] Task created. ) else ( echo    [-] Already exists. )

echo.
echo Autostart successfully set up.
goto wait_menu

:TOGGLE_VNC
if "%VNC_RUNNING%"=="1" goto STOP_VNC
goto START_VNC

:START_VNC
echo.
echo === Starting VNC Server ===
echo.
if not exist "%DEST%\VncDirect\VncDirect.exe" (
    echo    [!] VncDirect.exe not found. Run installer first.
    pause
    goto show_menu
)
echo    Starting VncDirect...
start "" "%DEST%\VncDirect\VncDirect.exe" port=7002 cwd=%DEST%\VncDirect\vnc fps=360 scale=0
timeout /t 3 /nobreak >nul
tasklist /FI "IMAGENAME eq VncDirect.exe" 2>nul | find /i "VncDirect.exe" >nul
if !errorlevel! equ 0 ( echo    [+] VNC Server started. ) else ( echo    [!] Failed to start. )
echo.
echo ========================================
for /f %%a in ('powershell -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.*' -and $_.IPAddress -notlike '192.168.56.*' } | Select-Object -First 1 -ExpandProperty IPAddress"') do (
    set "IP=%%a"
    goto gotip_s
)
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /r "IPv4"') do ( set "IP=%%a" & goto gotip_s )
:gotip_s
set "IP=%IP: =%"
echo   VNC URL: http://%IP%:7002/
echo ========================================
goto wait_menu

:STOP_VNC
echo.
echo === Stopping VNC Server ===
echo.
echo    Stopping VncDirect...
taskkill /F /IM VncDirect.exe >nul 2>&1
timeout /t 1 /nobreak >nul
tasklist /FI "IMAGENAME eq VncDirect.exe" 2>nul | find /i "VncDirect.exe" >nul
if !errorlevel! neq 0 ( echo    [+] VNC Server stopped. ) else ( echo    [!] Failed to stop. )
goto wait_menu

:MANAGE_PASSWORD
echo.
if "%HAS_PASSWORD%"=="1" (
    echo === Change VNC Password ===
    echo.
    echo A password is currently set.
) else (
    echo === Set VNC Password ===
    echo.
    echo No password is currently set.
)
echo.
echo Enter new password (leave empty to clear password):
echo.
set /p "NEWPASS=Password: "

echo.
echo Stopping VNC server...
taskkill /F /IM VncDirect.exe >nul 2>&1
timeout /t 2 /nobreak >nul

if not "%NEWPASS%"=="" (
    echo.
    echo Saving password...
    powershell -NoProfile -Command ^
        "$s = '%DEST%\VncDirect\vnc-settings.json'; " ^
        "$j = @{}; " ^
        "if (Test-Path $s) { try { $raw = Get-Content $s -Raw; $obj = $raw | ConvertFrom-Json; foreach ($p in $obj.PSObject.Properties) { $j[$p.Name] = $p.Value } } catch {} }; " ^
        "$j['password'] = '%NEWPASS%'; " ^
        "$j | ConvertTo-Json | Set-Content $s -Encoding UTF8"
    echo    Password saved.
) else (
    echo.
    echo Clearing password...
    powershell -NoProfile -Command ^
        "$s = '%DEST%\VncDirect\vnc-settings.json'; " ^
        "$j = @{}; " ^
        "if (Test-Path $s) { try { $raw = Get-Content $s -Raw; $obj = $raw | ConvertFrom-Json; foreach ($p in $obj.PSObject.Properties) { $j[$p.Name] = $p.Value } } catch {} }; " ^
        "$j['password'] = ''; " ^
        "$j | ConvertTo-Json | Set-Content $s -Encoding UTF8"
    timeout /t 1 /nobreak >nul
    echo    Password cleared.
)

echo.
echo Restarting VNC server...
timeout /t 1 /nobreak >nul
if exist "%DEST%\VncDirect\VncDirect.exe" (
    start "" "%DEST%\VncDirect\VncDirect.exe" port=7002 cwd=%DEST%\VncDirect\vnc fps=360 scale=0
    echo    VNC server restarted.
) else (
    echo    VNC server not found.
)
echo.
echo ========================================
if "%HAS_PASSWORD%"=="1" (
    echo   Password changed!
) else (
    echo   Password set!
)
echo ========================================
goto wait_menu

:wait_menu
echo.
echo Press any key to return to menu...
pause >nul
goto show_menu
