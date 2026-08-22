@echo off
setlocal EnableExtensions
title USBArmyKnife Agent Uninstaller

set "DEST=C:\AgentInstall"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SETTINGS=%DEST%\VncDirect\vnc-settings.json"

REM --- Elevation check ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Administrator privileges required...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ========================================
echo   USBArmyKnife Agent Uninstaller
echo ========================================
echo.
echo   [1] Full Uninstall
echo       Removes autostart, all files and firewall rules.
echo.
echo   [2] Remove Autostart only
echo       Checks if autostart exists and removes it.
echo       Files stay installed.
echo.
echo   [3] Start VNC Server
echo       Starts VncDirect on this PC.
echo.
echo   [4] Stop VNC Server
echo       Stops VncDirect on this PC.
echo.

REM Check if password exists
set "HAS_PASSWORD=0"
if exist "%SETTINGS%" (
    findstr /i "\"password\" *: *\"[^\"]\+\"" "%SETTINGS%" >nul 2>&1
    if %errorlevel% equ 0 (
        set "HAS_PASSWORD=1"
    )
)

if "%HAS_PASSWORD%"=="1" (
    echo   [5] Change VNC Password
    echo       Current password is set. Change or clear it.
) else (
    echo   [5] Set VNC Password
    echo       No password is set. Set one now.
)
echo.
echo ========================================
echo.

set /p "CHOICE=Select option (1-5): "

if "%CHOICE%"=="1" goto UNINSTALL_ALL
if "%CHOICE%"=="2" goto REMOVE_AUTOSTART
if "%CHOICE%"=="3" goto START_VNC
if "%CHOICE%"=="4" goto STOP_VNC
if "%CHOICE%"=="5" goto MANAGE_PASSWORD
echo.
echo Invalid input. Please select 1-5.
timeout /t 10 /nobreak >nul
exit /b 1

REM ============================================================
REM  OPTION 1: Full Uninstall
REM ============================================================
:UNINSTALL_ALL
echo.
echo === Full Uninstall ===
echo.

echo [1/5] Stopping running processes...
taskkill /F /IM AgentLauncher.exe >nul 2>&1
taskkill /F /IM VncDirect.exe >nul 2>&1
wmic process where "commandline like '%%vnc-watchdog%%'" call terminate >nul 2>&1
timeout /t 2 /nobreak >nul

echo [2/5] Removing autostart...
if exist "%STARTUP%\USBArmyKnifeAgent.vbs" (
    del "%STARTUP%\USBArmyKnifeAgent.vbs" >nul 2>&1
    echo    [+] USBArmyKnifeAgent.vbs removed.
)
if exist "%STARTUP%\VncDirect.vbs" (
    del "%STARTUP%\VncDirect.vbs" >nul 2>&1
    echo    [+] VncDirect.vbs removed.
)
schtasks /query /tn "USBArmyKnife Agent" >nul 2>&1
if %errorlevel% equ 0 (
    schtasks /delete /tn "USBArmyKnife Agent" /f >nul 2>&1
    echo    [+] Scheduled task "USBArmyKnife Agent" removed.
)
schtasks /query /tn "Security Script" >nul 2>&1
if %errorlevel% equ 0 (
    schtasks /delete /tn "Security Script" /f >nul 2>&1
    echo    [+] Scheduled task "Security Script" removed.
)
schtasks /query /tn "VNC Watchdog" >nul 2>&1
if %errorlevel% equ 0 (
    schtasks /delete /tn "VNC Watchdog" /f >nul 2>&1
    echo    [+] Scheduled task "VNC Watchdog" removed.
)

echo [3/5] Removing firewall rules...
netsh advfirewall firewall show rule name="VNC Direct 7002" >nul 2>&1
if %errorlevel% equ 0 (
    netsh advfirewall firewall delete rule name="VNC Direct 7002" >nul 2>&1
    echo    [+] Firewall rule "VNC Direct 7002" removed.
) else (
    echo    [-] Firewall rule "VNC Direct 7002" not found.
)
netsh advfirewall firewall show rule name="VNC Block Localhost" >nul 2>&1
if %errorlevel% equ 0 (
    netsh advfirewall firewall delete rule name="VNC Block Localhost" >nul 2>&1
    netsh advfirewall firewall delete rule name="VNC Block Localhost v6" >nul 2>&1
    echo    [+] Firewall rules "VNC Block Localhost" removed.
) else (
    echo    [-] Firewall rules "VNC Block Localhost" not found.
)

echo [4/5] Deleting files...
if not exist "%DEST%" goto files_deleted
rmdir /s /q "%DEST%" >nul 2>&1
if not exist "%DEST%" (
    echo    [+] %DEST% deleted completely.
) else (
    echo    [!] Could not fully delete %DEST% - some files may still be in use.
    echo        Try deleting C:\AgentInstall manually.
)
:files_deleted

echo [5/5] Done.
echo.
echo ========================================
echo   Uninstall complete!
echo ========================================
echo.
echo Window closes in 10 seconds...
timeout /t 10 /nobreak >nul
exit /b 0

REM ============================================================
REM  OPTION 2: Remove Autostart only
REM ============================================================
:REMOVE_AUTOSTART
echo.
echo === Removing Autostart ===
echo.

echo [1/3] Stopping running processes...
taskkill /F /IM AgentLauncher.exe >nul 2>&1
taskkill /F /IM VncDirect.exe >nul 2>&1
wmic process where "commandline like '%%vnc-watchdog%%'" call terminate >nul 2>&1
timeout /t 1 /nobreak >nul

echo [2/3] Removing autostart entries...
set "found=0"

if exist "%STARTUP%\USBArmyKnifeAgent.vbs" (
    del "%STARTUP%\USBArmyKnifeAgent.vbs" >nul 2>&1
    echo    [+] USBArmyKnifeAgent.vbs removed.
    set "found=1"
)
if exist "%STARTUP%\VncDirect.vbs" (
    del "%STARTUP%\VncDirect.vbs" >nul 2>&1
    echo    [+] VncDirect.vbs removed.
    set "found=1"
)

schtasks /query /tn "USBArmyKnife Agent" >nul 2>&1
if %errorlevel% equ 0 (
    schtasks /delete /tn "USBArmyKnife Agent" /f >nul 2>&1
    echo    [+] Scheduled task "USBArmyKnife Agent" removed.
    set "found=1"
) else (
    echo    [-] Scheduled task "USBArmyKnife Agent" not found.
)

schtasks /query /tn "Security Script" >nul 2>&1
if %errorlevel% equ 0 (
    schtasks /delete /tn "Security Script" /f >nul 2>&1
    echo    [+] Scheduled task "Security Script" removed.
    set "found=1"
) else (
    echo    [-] Scheduled task "Security Script" not found.
)

schtasks /query /tn "VNC Watchdog" >nul 2>&1
if %errorlevel% equ 0 (
    schtasks /delete /tn "VNC Watchdog" /f >nul 2>&1
    echo    [+] Scheduled task "VNC Watchdog" removed.
    set "found=1"
) else (
    echo    [-] Scheduled task "VNC Watchdog" not found.
)

echo [3/3] Done.
echo.
if "%found%"=="0" (
    echo No autostart found. Everything is clean.
) else (
    echo Autostart successfully removed.
)
echo.
echo Window closes in 10 seconds...
timeout /t 10 /nobreak >nul
exit /b 0

REM ============================================================
REM  OPTION 3: Start VNC Server
REM ============================================================
:START_VNC
echo.
echo === Starting VNC Server ===
echo.

tasklist /FI "IMAGENAME eq VncDirect.exe" 2>nul | find /i "VncDirect.exe" >nul
if %errorlevel% equ 0 (
    echo    VNC Server is already running.
    goto vnc_started
)

if not exist "%DEST%\VncDirect\VncDirect.exe" (
    echo    [!] VncDirect.exe not found at %DEST%\VncDirect\
    echo        Run the installer first.
    echo.
    pause
    exit /b 1
)

echo    Starting VncDirect...
start "" "%DEST%\VncDirect\VncDirect.exe" port=7002 cwd=%DEST%\VncDirect\vnc fps=360 scale=0
timeout /t 3 /nobreak >nul

tasklist /FI "IMAGENAME eq VncDirect.exe" 2>nul | find /i "VncDirect.exe" >nul
if %errorlevel% equ 0 (
    echo    [+] VNC Server started successfully.
) else (
    echo    [!] Failed to start VNC Server.
)

:vnc_started
echo.
echo ========================================
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /r "IPv4"') do (
    set "IP=%%a"
    goto gotip_s
)
:gotip_s
set "IP=%IP: =%"
echo   VNC URL: http://%IP%:7002/
echo ========================================
echo.
echo Window closes in 10 seconds...
timeout /t 10 /nobreak >nul
exit /b 0

REM ============================================================
REM  OPTION 4: Stop VNC Server
REM ============================================================
:STOP_VNC
echo.
echo === Stopping VNC Server ===
echo.

tasklist /FI "IMAGENAME eq VncDirect.exe" 2>nul | find /i "VncDirect.exe" >nul
if %errorlevel% neq 0 (
    echo    VNC Server is not running.
    goto vnc_stopped
)

echo    Stopping VncDirect...
taskkill /F /IM VncDirect.exe >nul 2>&1
timeout /t 1 /nobreak >nul

tasklist /FI "IMAGENAME eq VncDirect.exe" 2>nul | find /i "VncDirect.exe" >nul
if %errorlevel% neq 0 (
    echo    [!] Failed to stop VNC Server.
) else (
    echo    [+] VNC Server stopped.
)

:vnc_stopped
echo.
echo Window closes in 10 seconds...
timeout /t 10 /nobreak >nul
exit /b 0

REM ============================================================
REM  OPTION 5: Manage Password
REM ============================================================
:MANAGE_PASSWORD
echo.
if "%HAS_PASSWORD%"=="1" (
    echo === Change VNC Password ===
    echo.
    echo A password is currently set.
    echo.
) else (
    echo === Set VNC Password ===
    echo.
    echo No password is currently set.
    echo.
)

echo Enter new password (leave empty to clear password):
echo.
set /p "NEWPASS=Password: "

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
    echo    Password cleared.
)

echo.
echo Restarting VNC server to apply changes...
taskkill /F /IM VncDirect.exe >nul 2>&1
timeout /t 2 /nobreak >nul
if exist "%DEST%\VncDirect\VncDirect.exe" (
    start "" "%DEST%\VncDirect\VncDirect.exe" port=7002 cwd=%DEST%\VncDirect\vnc fps=360 scale=0
    echo    VNC server restarted.
) else (
    echo    VNC server not found. Please restart manually.
)

echo.
echo ========================================
if "%HAS_PASSWORD%"=="1" (
    echo   Password changed successfully!
) else (
    echo   Password set successfully!
)
echo ========================================
echo.
echo Window closes in 10 seconds...
timeout /t 10 /nobreak >nul
exit /b 0
