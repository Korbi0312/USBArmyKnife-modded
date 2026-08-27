# Tools

The `tools/` directory contains the optional Windows companion components for USB Army Knife - modded. These tools provide the serial agent, PC-hosted VNC service, installer scripts and debugging helpers.

> **For authorized security testing only.** Install these tools exclusively on Windows systems that you own or have explicit permission to administer. The installer can create scheduled tasks, add firewall rules and configure autostart. Review the scripts before running them and remove the components when your test is complete.

## Agent and VNC workflow

The optional PC workflow consists of three parts:

- **AgentLauncher** starts the companion agent and connects it to the configured USB device.
- **Agent** provides the PC-side functionality used by supported device workflows.
- **VncDirect** hosts the browser-based noVNC interface directly on the Windows computer.

The PC-hosted design keeps screen processing and browser delivery on the computer instead of relaying the complete video stream through the ESP32. The VNC web interface listens on port `7002` by default.

Treat port `7002` as a management interface. Restrict it to a trusted network, configure a password, and stop the service when it is not required.

## Quick Install

1. Download [`Agent Installer.bat`](Agent%20Installer.bat) from this repository.
2. Review the batch file and confirm that its download URLs and installation actions are appropriate for your test system.
3. Run the script as administrator.
4. Configure a VNC password when prompted. Press Enter only if an unauthenticated, isolated lab setup is intentional.
5. Confirm that the agent and VNC service are running.
6. Open `http://<PC-IP>:7002` from a browser on the authorized test network.

The installer places the companion files under:

```text
C:\ProgramData\Windows Defender
```

This path is retained for compatibility with the current installer. Because the directory name resembles a Windows system location, document the installation clearly and review the installer before use.

## What the installer configures

Depending on the selected options and current version, the installer may configure:

- `AgentLauncher.exe` for the USB Army Knife companion agent;
- `Windows Defender.exe` for the PC-hosted VNC service;
- VNC web assets and native runtime libraries;
- a hidden login launcher;
- scheduled tasks for agent or VNC startup;
- an inbound firewall rule for TCP port `7002`; and
- optional VNC password storage.

Before using the installer in an enterprise environment, have the system owner review every downloaded binary, scheduled task, firewall rule and persistence setting.

## Uninstall and Maintenance

Run [`Agent Uninstaller.bat`](Agent%20Uninstaller.bat) as administrator and select the required action:

- **[1] Full Uninstall** - removes scheduled tasks, firewall rules and installed files.
- **[2] Remove Autostart / Setup Autostart** - disables or enables scheduled startup tasks.
- **[3] Start/Stop VNC Server** - controls the PC-hosted VNC service.
- **[4] Set/Change VNC Password** - configures or clears the VNC password.
- **[5] Exit** - leaves the system unchanged.

After uninstalling, verify that the following items are gone or intentionally retained:

- scheduled tasks named `USBArmyKnife Agent`, `Security Script` and `Windows Defender`;
- firewall rules named `VNC Direct 7002` and `VNC Block Localhost`; and
- the installation directory under `C:\ProgramData\Windows Defender`.

## Manual Installation

Use the manual procedure only when you have reviewed the installer and understand each component.

1. Download the required files from [`Installer/`](Installer/).
2. Create the VNC web directory:

   ```text
   C:\ProgramData\Windows Defender\VncDirect\vnc
   ```

3. Place `AgentLauncher.exe` in `C:\ProgramData\Windows Defender\`.
4. Place `Windows Defender.exe`, `turbojpeg.dll` and `vcruntime140.dll` in `C:\ProgramData\Windows Defender\VncDirect\`.
5. Extract `vnc-web.zip` into the `VncDirect` directory.
6. Create only the scheduled tasks required for your lab and record their names and commands.
7. Add a narrowly scoped firewall rule for TCP port `7002`.
8. Start the agent and VNC service manually, verify connectivity, and stop them after testing.

Do not expose the VNC port directly to the public internet. If remote access is required, use a private VPN such as Tailscale and apply its access controls.

## Build from Source

The current PC tools target 64-bit Windows. Cross-compilation is not supported by the current project workflow.

### Prerequisites

- Windows 10 or Windows 11, 64-bit
- [.NET 8.0 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/8.0)

### Build the Agent

```powershell
cd tools\AgentLauncher
dotnet publish -r win-x64 -c Release

cd ..\Agent
dotnet publish -r win-x64 -c Release
```

Expected outputs include:

```text
tools\AgentLauncher\bin\Release\net8.0-windows\win-x64\publish\AgentLauncher.exe
tools\Agent\bin\Release\net8.0-windows\win-x64\publish\PortableApp.dll
```

### Build VncDirect

```powershell
cd tools\VncDirect
dotnet publish -r win-x64 -c Release --self-contained true /p:PublishSingleFile=true
```

The resulting executable is written to the corresponding `publish` directory. Review the output and test it on an isolated Windows machine before packaging it for distribution.

## Debug Logs

The agent API can be used to display device debug output:

1. Open the PowerShell helper in `DebugLogs`.
2. Set the correct COM port.
3. Run the script from a PowerShell terminal.
4. Connect the device and reproduce the problem.
5. Remove or redact sensitive information before sharing logs in an issue.

If the serial connection is not ready when the script starts, a payload can wait for the agent connection before continuing:

```text
WHILE (AGENT_CONNECTED() == FALSE)
  DELAY 2000
END_WHILE
```

## Debug Build

```powershell
cd tools\Agent
dotnet build --configuration Debug /p:OutputType=Exe
.\bin\Debug\net8.0-windows\PortableApp.exe vid=cafe pid=403f
```

Replace the VID, PID and working directory with the values used by your test device. Never use a debug build on a system that is not part of your authorized test environment.
