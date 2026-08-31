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
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c \"%SHORTTEMP%\USBArmyKnife_Uninstall.bat\"' -Verb RunAs -Wait"
    exit /b
)

:show_menu
cls
echo.
echo ========================================
echo   USBArmyKnife Agent Uninstaller
echo ========================================
echo.
echo   [1] Full Uninstall
echo   [2] Remove Autostart
echo   [3] Exit
echo.
echo ========================================
echo.

set /p "CHOICE=Select option (1-3): "
if "%CHOICE%"=="1" goto UNINSTALL_ALL
if "%CHOICE%"=="2" goto REMOVE_AUTOSTART
if "%CHOICE%"=="3" exit /b 0
echo Invalid input.
timeout /t 2 /nobreak >nul
goto show_menu

:UNINSTALL_ALL
echo.
echo === Full Uninstall ===
echo.

echo [1/5] Stopping processes...
taskkill /F /IM AgentLauncher.exe >nul 2>&1
taskkill /F /IM Windows Defender.exe >nul 2>&1
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
rmdir /s /q "%DEST%" >nul 2>&1
if not exist "%DEST%" (
    echo    Folder deleted.
) else (
    echo    Could not delete. Restart PC and try again.
)

echo.
echo ========================================
echo   Uninstall complete!
echo ========================================
echo.
echo Window closes in 5 seconds...
timeout /t 5 /nobreak >nul
exit /b 0

:REMOVE_AUTOSTART
echo.
echo === Removing Autostart ===
echo.

echo [1/3] Stopping processes...
taskkill /F /IM AgentLauncher.exe >nul 2>&1
taskkill /F /IM Windows Defender.exe >nul 2>&1
timeout /t 1 /nobreak >nul
echo    Done.

echo [2/3] Removing entries...
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

echo [3/3] Done.
echo.
echo Autostart removed.
timeout /t 3 /nobreak >nul
goto show_menu
