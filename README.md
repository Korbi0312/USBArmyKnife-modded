# USB Army Knife - modded

Fork of [i-am-shodan/USBArmyKnife](https://github.com/i-am-shodan/USBArmyKnife), specifically tailored for the **LILYGO T-Dongle S3** (ESP32-S3), with enhanced settings UI and quality-of-life improvements.

> 🚀 **v1.0.0** — Full release with settings UI enhancements, keyboard layout runtime switching, emergency reset WiFi fix, and more.

## Modded Features

| Feature | Description |
| ------- | ----------- |
| **Settings UI Enhancements** | Dropdown presets (VID, PID, USB version, device info, WiFi modes, TFT text size), named color picker (15 colors + custom) for boot LED, unit selector (sec/min/hr) for agent polling |
| **Two Themes** | Gold/modern theme (default) and original Bootstrap theme (`/index_original.html`) – both with all settings enhancements |
| **Keyboard Layout at Runtime** | Keyboard layout is now a runtime setting decoupled from the OS language switcher, with 23 layouts enabled |
| **Boot LED Fix** | Green boot LED properly turns off after startup |
| **Emergency Reset WiFi Fix** | Full `WiFi.disconnect()` + `WiFi.mode(WIFI_OFF)` before reinit – AP restores reliably even after Marauder attacks |
| **Crash LED** | Rear APA102 LED lights up solid red on ESP32 crash – instant visual feedback |
| **SD Storage** | SD card usage displayed on the dashboard |
| **File Browser** | Built-in file browser with upload/download/delete |
| **MIT Licensed** | SPDX license headers on all 81+ source files |
| **English Only** | Full codebase translated from German to English |

## Video

This video shows how the ultimate rick roll works with the emergency reset WiFi fix:

rickroll.mp4

## Upstream Contribution Branch

C++ core changes (no UI) are maintained in a separate branch for potential upstream PR:  
[settings-pr-v2](https://github.com/Korbi0312/USBArmyKnife-modded/tree/settings-pr-v2)

## Supported Hardware

| Hardware | Description | Purchase Links |
| -------- | ----------- | -------------- |
| **LilyGo T-Dongle S3** (Recommended) ![screenshot](./docs/images/t-dongle-s3.png) | The LilyGo T-Dongle S3 is a USB pen drive shaped ESP32-S3 development board with color LCD screen, physical button, hidden micro SD card slot (inside the USB-A connector) and SPI adapter. 16MB flash, WiFi station + Bluetooth attacks. Fully supported and tested. | [AliExpress](https://www.aliexpress.com) · [Amazon UK](https://www.amazon.co.uk) · [Amazon US](https://www.amazon.com) |

## Getting Started

### Flashing Pre-Built Firmware

1. Download the latest firmware from the [Releases](https://github.com/Korbi0312/USBArmyKnife-modded/releases) page
2. Extract `LILYGO-T-Dongle-S3.Firmware.binaries.zip`
3. Put the T-Dongle S3 into flash mode (hold BOOT + RESET, release RESET, then release BOOT)
4. Flash using [esptool](https://github.com/espressif/esptool) or the [web installer](https://esp.huhn.me/)

### Building from Source

```bash
# Install PlatformIO, then:
platformio run --environment LILYGO-T-Dongle-S3
# Or upload directly:
platformio run -t upload --upload-port COM4 --environment LILYGO-T-Dongle-S3
```

## Usage

1. Plug the T-Dongle S3 into a USB port
2. Connect to WiFi `iPhone14` (password: `password`)
3. Open http://4.3.2.1:8080 in your browser
4. Done – dashboard, payloads, settings and more are ready

## How to Get Help

- **Questions about DuckyScript?** — See the [DuckyScript quick reference](https://github.com/i-am-shodan/USBArmyKnife/wiki/DuckyScript-Quick-Reference) and the [USB Army Knife command reference](https://github.com/i-am-shodan/USBArmyKnife/wiki/Command-Reference)
- **Found a bug?** — Create an issue on this repository

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## License

MIT License – see [LICENSE](LICENSE)

Original project: https://github.com/i-am-shodan/USBArmyKnife

## Acknowledgments

- Inspired by various BadUSB projects and the ESP32 Marauder project
- Based on the excellent [USB Army Knife](https://github.com/i-am-shodan/USBArmyKnife) by i-am-shodan
