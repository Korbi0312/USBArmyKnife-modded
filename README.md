# USB Army Knife - modded

[![PlatformIO CI](https://github.com/Korbi0312/USBArmyKnife-modded/actions/workflows/main.yml/badge.svg)](https://github.com/Korbi0312/USBArmyKnife-modded/actions/workflows/main.yml)
[![Latest release](https://img.shields.io/github/v/release/Korbi0312/USBArmyKnife-modded)](https://github.com/Korbi0312/USBArmyKnife-modded/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**USB Army Knife - modded** is an expanded fork of [i-am-shodan/USBArmyKnife](https://github.com/i-am-shodan/USBArmyKnife), focused on the **LILYGO T-Dongle S3** (ESP32-S3). It combines BadUSB, USB storage and networking, ESP32 Marauder, display control and an optional Windows agent in one compact platform.

This fork adds two enhanced web interfaces with full 18-language support, runtime keyboard-layout selection, dependable SD-card file handling, PNG display support, improved device recovery and a PC-hosted VNC solution.

> **For authorized security testing only.** Use this project exclusively on systems, devices and networks you own or have explicit permission to test.

## Why USB Army Knife?

Individual physical-access techniques are often limited on their own. USB HID requires an interactive host session, network testing needs a suitable interface, and useful feedback or data may need another communication channel.

USB Army Knife brings these capabilities together in one small USB/Wi-Fi/Bluetooth platform. Payloads are written in an extended DuckyScript-compatible language and can combine USB modes, wireless functions, storage, display output, hardware controls and the optional serial agent.

- Want to run USB HID payloads with different keyboard layouts? USB Army Knife.
- Want to present storage, CD-ROM or USB networking from the same device? USB Army Knife.
- Want to capture traffic from an authorized USB NCM test interface? USB Army Knife.
- Want to build a custom on-device menu or a Hollywood-style progress display? USB Army Knife.
- Want to combine scripts with buttons, LEDs, displays, touch, IR or external sensors? USB Army Knife.
- Want to view and control an authorized test PC through an optional companion agent? USB Army Knife.

## Core USB Army Knife Features

These capabilities originate from or build directly on the original USB Army Knife project:

- **USB HID and BadUSB:** Execute keyboard commands and text input through USB HID using a DuckyScript-compatible interpreter.
- **Mass-storage emulation:** Present supported storage or disk images as a USB drive or read-only CD-ROM.
- **USB networking:** Expose a USB NCM network interface on supported targets and capture traffic to PCAP files.
- **Wi-Fi and Bluetooth testing:** Use the integrated ESP32 Marauder command set for authorized wireless assessment workflows.
- **Extended scripting:** Combine variables, conditions, loops, functions and USB Army Knife-specific commands in one payload.
- **Hardware interaction:** Control supported displays, buttons, LEDs, touchscreens, infrared hardware, microphones and external sensors.
- **Browser-based management:** Create and manage scripts, files and device settings from a phone or computer connected to the device.
- **Optional serial agent:** Communicate with a Windows companion over the USB serial connection for command, logging and screen-related features.

## Features Added in This Fork

### PC-hosted VNC

VncDirect hosts the noVNC interface directly on the Windows computer at port `7002`. The dongle handles agent deployment and communication, while screen processing and browser delivery run on the PC for improved performance and reduced ESP32 memory usage.

The VNC interface includes:

- live screen viewing;
- optional mouse and keyboard control;
- adjustable frame rate;
- quality and output-resolution presets;
- window, 100%, 75%, 50% and 25% scaling;
- a resizable viewing area;
- optional password protection; and
- a Tailscale-aware remote link for authorized private-network access.

### Windows Installer and Maintenance Tool

`Agent Installer.bat` downloads the required companion files, installs them on the Windows computer and configures the scheduled tasks, firewall rule and optional autostart required by the current workflow.

`Agent Uninstaller.bat` provides five maintenance actions:

1. Full uninstall
2. Enable or disable autostart
3. Start or stop the VNC server
4. Set, change or clear the VNC password
5. Exit

See [`tools/README.md`](tools/README.md) for the complete installation, removal, build and debugging instructions.

### Two Enhanced Web Interfaces

The modern gold-accented dashboard is the default interface. The original Bootstrap-based interface remains available at `/index_original.html`.

Both interfaces include the enhanced settings, file-management functions and localization system, so users can choose a visual style without losing functionality.

### Complete 18-language Interface

Both web interfaces are translated into:

`de`, `en`, `fr`, `es`, `it`, `pt`, `nl`, `ja`, `cs`, `da`, `fi`, `hr`, `hu`, `no`, `sv`, `sl`, `sk` and `tr`.

Translations cover navigation, labels, buttons, placeholders, dialogs, status messages and file-management actions.

### Runtime Keyboard-layout Selection

The HID keyboard layout is independent of the selected interface language. The default build enables 23 layouts, allowing payloads to select a layout at runtime without requiring a separate firmware build for each language.

### Improved Settings Interface

Common settings use clear presets while still supporting custom values where appropriate. Enhancements include:

- USB VID and PID presets;
- USB-version and device-information presets;
- Wi-Fi mode selection;
- TFT text-size presets;
- named boot-LED colors plus a custom color option; and
- seconds, minutes or hours for the agent polling interval.

### Integrated File Browser

The browser interface can create, upload, download, edit and delete files on supported storage. SD-card capacity and usage are shown on the dashboard, making it easier to identify space limitations before transferring larger payloads.

### Byte-exact File Saving

Writes are checked while data is stored in 4 KB chunks. Failed writes are retried up to three times, and insufficient storage returns HTTP 507 together with the available free space.

This prevents a successful response from being shown for an incomplete file and makes larger payload transfers more dependable.

### Streaming File Reads

Large files are streamed directly from storage instead of being loaded completely into an ESP32 memory buffer. This reduces heap usage and allows the browser editor to open larger files more reliably.

### PNG Display Support

Compatible boards can render `.png` files on their LCD. The original web interface provides a dedicated **Display** action, while DuckyScript payloads can show images directly with display commands.

### New-file Dialog

The new-file dialog combines the file type, keyboard layout and typing-speed presets in one workflow. It is available in both web interfaces and uses the selected interface language.

### Hardware-aware Microphone Controls

Compatible boards can stream microphone audio over Wi-Fi through the web interface. The controls are compiled and displayed only for boards with microphone hardware, such as the M5Stack AtomS3U, and remain hidden on the T-Dongle S3.

### Reliable Wi-Fi Recovery

Emergency reset now fully disconnects Wi-Fi and disables the radio before reinitializing it. This allows the management access point to recover more reliably after Marauder operations.

### Better Visual Status Feedback

- The green boot LED switches off correctly after startup.
- On the LILYGO T-Dongle S3, the rear APA102 LED turns solid red when the ESP32 panic handler is reached.
- SD-card usage is visible directly on the dashboard.

### English Source and MIT Licensing

The maintained source has been standardized in English. SPDX license headers identify the MIT license in the source files where applicable.

## Examples

The [`examples`](examples/) directory shows how individual features can be combined. Review each script and adapt its paths, keyboard layout, network settings and hardware assumptions before use.

| Example | Description |
| --- | --- |
| [Covert Storage](examples/covertstorage/) | Presents writable storage on the first connection and a separate read-only storage state on later connections. |
| [Progress Bar](examples/progressbar/) | Displays a PNG-based progress animation for multi-stage payload feedback. |
| [Ultimate Rickroll](examples/rickroll/) | Combines HID input, an ESP32 Marauder command and animated LCD images in one demonstration. |
| [USB Ethernet PCAP](examples/usb_ethernet_pcap/) | Turns the device into a USB NCM network adapter and stores captured interface traffic as a PCAP file. |
| [Deploy the Serial Agent](examples/install_agent_and_run_command/) | Deploys the optional companion from a disk image and displays command output in the web interface. |
| [PC-hosted VNC](examples/vnc/) | Uses the Windows companion and VncDirect to view and optionally control the authorized test computer from a browser. |
| [Simple UI](examples/simple_ui/) | Builds a button-driven script selector using display images and the filesystem API. |
| [Microphone Streaming](examples/hotmic/) | Streams audio from the M5Stack AtomS3U microphone through the web interface. |
| [Linux EXT Filesystem Test](examples/linux_panic/) | Demonstrates filesystem error handling on an isolated, authorized Linux test system. |
| [USB CD-ROM to NCM](examples/malicious_ethernet_adapter/) | Presents a CD-ROM image and then switches the device to USB NCM mode after companion detection. |
| [Multiple Keyboard Layouts](examples/multiple_keyboard_layouts/) | Changes the active HID keyboard layout within a running payload. |
| [Existing Wi-Fi Network](examples/wifi_connect_to_existing_ap/) | Switches from access-point mode to an existing authorized Wi-Fi network and displays the assigned IP address. |
| [LED Controls](examples/led/) | Demonstrates LED animation, payload interruption and clearing the status LED. |
| [Motion Sensor](examples/self_destruct/) | Uses an optional LD2410 sensor to trigger a custom display-and-reset handler. |
| [Watch UI](examples/watch/) | Builds a touchscreen menu and watch face on compatible hardware. |

## Supported Hardware

### LILYGO T-Dongle S3 — Recommended

![LILYGO T-Dongle S3](docs/images/t-dongle-s3.png)

The LILYGO T-Dongle S3 is a compact ESP32-S3 development board shaped like a USB flash drive. It includes a 160×80 color LCD, a physical button, a rear APA102 LED, 16 MB flash and a microSD slot integrated into the USB-A connector.

Its combination of native USB, Wi-Fi, Bluetooth, display and removable storage makes it the primary target for this fork. The version with the display is the recommended and tested configuration.

### Additional Build Targets

The repository also contains PlatformIO environments for:

- Waveshare ESP32-S3 LCD 1.47
- Generic ESP32-S2
- Generic ESP32-S3
- M5Stack AtomS3U
- Waveshare RP2040-GEEK
- Waveshare ESP32-S3-ETH
- Waveshare ESP32-S3-GEEK
- LILYGO T-Watch S3
- Evil Crow Cable Wind
- Pocket-Dongle-S3

Feature availability varies by board. Not every target includes Wi-Fi, Bluetooth, a web interface, SD storage, a display, a microphone, touch input, IR, LEDs or USB NCM support. Check the corresponding environment in [`platformio.ini`](platformio.ini) before building.

## Getting Started

Start with the [project wiki](https://github.com/Korbi0312/USBArmyKnife-modded/wiki) for board-specific flashing and setup guidance.

### Option 1: Flash Pre-built Firmware

1. Download the correct firmware package from [Releases](https://github.com/Korbi0312/USBArmyKnife-modded/releases).
2. Flash it with a compatible ESP32 web installer or [esptool](https://github.com/espressif/esptool).
3. Insert a prepared microSD card if the selected board uses external storage.
4. Connect to the configured device access point.
5. Open the web interface at the configured address.

### Option 2: Build from Source

Install PlatformIO and build the primary target:

```bash
platformio run --environment LILYGO-T-Dongle-S3
```

To upload directly, replace `COM4` with your board's port:

```bash
platformio run --target upload --upload-port COM4 --environment LILYGO-T-Dongle-S3
```

## Basic Usage

The default development configuration uses:

- **Wi-Fi SSID:** `iPhone14`
- **Wi-Fi password:** `password`
- **Web interface:** `http://4.3.2.1:8080`

1. Connect the T-Dongle S3 to a USB port.
2. Join its Wi-Fi access point.
3. Open the web interface.
4. Confirm that the running status and uptime are updating.
5. Use the file browser and editor to manage DuckyScript payloads, images and storage files.

Change the default Wi-Fi credentials before using the device outside an isolated test environment.

## VNC and Remote Screen Viewing

The current modded workflow hosts VNC on the authorized Windows computer rather than relaying the full screen through the dongle.

1. Install the optional PC companion as described in [`tools/README.md`](tools/README.md).
2. Start VncDirect and the companion agent.
3. Open `http://<PC-IP>:7002` in a browser.
4. Enter the configured VNC password if authentication is enabled.
5. Adjust frame rate, quality and scaling as needed.
6. Enable mouse and keyboard control only when required.

Do not expose port `7002` directly to the public internet. For remote access, use a trusted private network or an authenticated VPN such as Tailscale.

## How to Get Help

- **DuckyScript and commands**
  - [DuckyScript quick reference](https://github.com/i-am-shodan/USBArmyKnife/wiki/DuckyScript-Quick-Reference)
  - [USB Army Knife command reference](https://github.com/i-am-shodan/USBArmyKnife/wiki/Command-Reference)
- **Setup and examples**
  - [Project wiki](https://github.com/Korbi0312/USBArmyKnife-modded/wiki)
  - [Examples](examples/)
  - [Windows companion documentation](tools/README.md)
- **Bugs and suggestions**
  - [Open an issue](https://github.com/Korbi0312/USBArmyKnife-modded/issues)

When reporting a problem, include the board and PlatformIO environment, firmware version or commit, operating system, browser, reproduction steps and relevant logs.

## Upstream Contribution Branch

Core C++ changes intended for a possible upstream contribution are maintained separately in the [`settings-pr-v2`](https://github.com/Korbi0312/USBArmyKnife-modded/tree/settings-pr-v2) branch.

## Future Plans

### USB Host Mode and Mobile-device Support

A possible future direction is USB host-mode support, allowing compatible hardware to communicate with USB peripherals and mobile devices as a host. Potential research areas include standards such as PTP. This is not currently part of the supported feature set and requires additional protocol implementation and hardware validation.

## Contributing

Contributions are welcome. Fork the repository, create a focused branch and submit a pull request with a clear description of the change, supported hardware and test results.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgments

- Based on the excellent [USB Army Knife](https://github.com/i-am-shodan/USBArmyKnife) by i-am-shodan
- Inspired by BadUSB research and the ESP32 Marauder project
- Thanks to the upstream authors and contributors whose work made this fork possible

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Korbi0312/USBArmyKnife-modded&type=Date)](https://star-history.com/#Korbi0312/USBArmyKnife-modded&Date)
