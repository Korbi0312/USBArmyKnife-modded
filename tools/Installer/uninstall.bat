@echo off
setlocal EnableExtensions
title USBArmyKnife Uninstaller

set "DEST=C:\AgentInstall"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

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
echo       Removes autostart, all files and scheduled tasks.
echo.
echo ========================================
echo.

set /p "CHOICE=Select option (1 or 2): "

if "%CHOICE%"=="1" goto REMOVE_AUTOSTART
if "%CHOICE%"=="2" goto UNINSTALL_ALL
echo.
echo Invalid input. Please select 1 or 2.
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
timeout /t 1 /nobreak >nul

echo [2/3] Removing autostart entries...
set "found=0"

if exist "%STARTUP%\USBArmyKnifeAgent.vbs" (
    del "%STARTUP%\USBArmyKnifeAgent.vbs" >nul 2>&1
    echo    [+] USBArmyKnifeAgent.vbs removed.
    set "found=1"
) else (
    echo    [-] USBArmyKnifeAgent.vbs not found.
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

echo [1/4] Stopping running processes...
taskkill /F /IM AgentLauncher.exe >nul 2>&1
timeout /t 1 /nobreak >nul

echo [2/4] Removing autostart...
if exist "%STARTUP%\USBArmyKnifeAgent.vbs" (
    del "%STARTUP%\USBArmyKnifeAgent.vbs" >nul 2>&1
    echo    [+] USBArmyKnifeAgent.vbs removed.
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

echo [3/4] Deleting files...
if exist "%DEST%" (
    rmdir /s /q "%DEST%" >nul 2>&1
    if exist "%DEST%" (
        echo    [!] Could not fully delete %DEST% (files still in use?)
    ) else (
        echo    [+] %DEST% deleted completely.
    )
) else (
    echo    [-] %DEST% not found.
)

echo [4/4] Done.
echo.
echo ========================================
echo   Uninstall complete!
echo ========================================
echo.
echo Window closes in 10 seconds...
timeout /t 10 /nobreak >nul
exit /b 0
