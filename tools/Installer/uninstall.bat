@echo off
setlocal EnableExtensions
title USBArmyKnife Uninstaller

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
echo   USBArmyKnife Uninstaller
echo ========================================
echo.
echo   [1] Remove Autostart only
echo       Checks if autostart exists and removes it.
echo       Files stay installed.
echo.
echo   [2] Full Uninstall
echo       Removes autostart, all files and firewall rule.
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
    echo   [3] Change VNC Password
    echo       Current password is set. Change or clear it.
) else (
    echo   [3] Set VNC Password
    echo       No password is set. Set one now.
)
echo.
echo ========================================
echo.

set /p "CHOICE=Select option (1, 2 or 3): "

if "%CHOICE%"=="1" goto REMOVE_AUTOSTART
if "%CHOICE%"=="2" goto UNINSTALL_ALL
if "%CHOICE%"=="3" goto MANAGE_PASSWORD
echo.
echo Invalid input. Please select 1, 2 or 3.
timeout /t 10 /nobreak >nul
exit /b 1

REM ============================================================
REM  OPTION 1: Remove Autostart only
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

REM Remove old VBS files (from previous installer versions)
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
REM  OPTION 2: Full Uninstall
REM ============================================================
:UNINSTALL_ALL
echo.
echo === Full Uninstall ===
echo.

echo [1/5] Stopping running processes...
taskkill /F /IM AgentLauncher.exe >nul 2>&1
taskkill /F /IM VncDirect.exe >nul 2>&1
taskkill /F /IM cmd.exe /FI "WINDOWTITLE eq *vnc-watchdog*" >nul 2>&1
wmic process where "commandline like '%%vnc-watchdog%%'" call terminate >nul 2>&1
timeout /t 2 /nobreak >nul

echo [2/5] Removing autostart...
REM Remove old VBS files (from previous installer versions)
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

echo [3/5] Removing firewall rule...
netsh advfirewall firewall show rule name="VNC Direct 7002" >nul 2>&1
if %errorlevel% equ 0 (
    netsh advfirewall firewall delete rule name="VNC Direct 7002" >nul 2>&1
    echo    [+] Firewall rule "VNC Direct 7002" removed.
) else (
    echo    [-] Firewall rule not found.
)

echo [4/5] Deleting files...
if not exist "%DEST%" goto :files_deleted
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
REM  OPTION 3: Manage Password
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
    start "" "%DEST%\VncDirect\VncDirect.exe" port=7002 cwd=%DEST%\VncDirect\vnc fps=240 scale=0
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
