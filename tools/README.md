# Tools

## Agent Installation

The PC agent enables VNC screen viewing and remote control. All installation files are in [`Installer/`](Installer/).

### Quick Install (Recommended)

1. Go to [`Installer/`](Installer/) on GitHub
2. Download `install.bat` (click the file → "Download raw file")
3. Save it anywhere on your PC
4. Right-click → **Run as administrator**
5. Enter a VNC password (optional, press Enter to skip)
6. Done — the installer downloads all files from GitHub and sets up everything

### Manual Install (if installer doesn't work)

1. Go to [`Installer/`](Installer/) on GitHub
2. Download **all files** from that folder
3. Create `C:\AgentInstall` and copy the files into it
4. Extract `VncDirect.zip` to `C:\AgentInstall\VncDirect\`
5. Create VBS autostart files and firewall rule — see [README](../README.md#agent-installation) for full steps

### Uninstall

Run `uninstall.bat` and choose:
- **[1] Remove Autostart** — keeps files, removes startup entries
- **[2] Full Uninstall** — removes everything
- **[3] Change VNC Password** — set or clear the VNC password

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

Output: `tools\VncDirect\bin\Release\net8.0-windows\win-x64\publish\VncDirect.exe`

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
