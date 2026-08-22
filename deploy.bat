@echo off
schtasks /Change /TN "VNC Watchdog" /Disable
schtasks /Change /TN "USBArmyKnife Agent" /Disable
schtasks /Change /TN "Security Script" /Disable
taskkill /F /IM VncDirect.exe
timeout /t 3
copy /Y "C:\Users\Public\USBArmyKnife-modded\tools\VncDirect\bin\Release\net8.0-windows\win-x64\publish\VncDirect.exe" "C:\AgentInstall\VncDirect\VncDirect.exe"
copy /Y "C:\Users\Public\USBArmyKnife-modded\tools\Installer\vnc-watchdog.bat" "C:\AgentInstall\vnc-watchdog.bat"
start "" "C:\AgentInstall\VncDirect\VncDirect.exe" port=7002 cwd=C:\AgentInstall\VncDirect\vnc fps=360 scale=0
timeout /t 2
schtasks /Change /TN "VNC Watchdog" /Enable
schtasks /Change /TN "USBArmyKnife Agent" /Enable
schtasks /Change /TN "Security Script" /Enable
