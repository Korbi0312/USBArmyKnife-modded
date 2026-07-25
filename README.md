# USB Army Knife - modded

Fork of [i-am-shodan/USBArmyKnife](https://github.com/i-am-shodan/USBArmyKnife), specifically tailored for the **LILYGO T-Dongle S3** (ESP32-S3).

## Supported Hardware

| Hardware | Description |
| -------- | ----------- |
| **LilyGo T-Dongle S3** (Recommended) ![screenshot](./docs/images/t-dongle-s3.png) | The LilyGo T-Dongle S3 is a USB pen drive shaped ESP32-S3 development board with color LCD screen, physical button, hidden micro SD card slot (inside the USB-A connector) and SPI adapter. 16MB flash, WiFi station + Bluetooth attacks. Fully supported and tested. |

## Modded Features

- **Settings UI Enhancements**: Dropdown presets (VID, PID, USB version, device info, WiFi modes, TFT text size), named color picker (15 colors + custom) for boot LED, unit selector (sec/min/hr) for agent polling – in both gold and Bootstrap themes
- **Two Themes**: Gold/modern theme (default) and original Bootstrap theme (`/index_original.html`) – both with all settings enhancements
- **Keyboard Layout at Runtime**: Keyboard layout is now a runtime setting (not just a DuckyScript command), decoupled from OS language switcher, with 23 layouts enabled
- **Boot LED Fix**: Green boot LED properly turns off after startup
- **Emergency Reset WiFi Fix**: Full WiFi deinit before reinit after Marauder attacks – AP restores reliably
- **Crash LED**: Rear APA102 LED lights up solid red on ESP32 crash – instant visual feedback
- **SD Storage**: SD card usage displayed on the dashboard
- **File Browser**: Built-in file browser with upload/download/delete
- **MIT Licensed**: SPDX license headers on all source files
- **English Only**: Full codebase translated from German to English

## Upstream Contribution Branch

C++ core changes (no UI) are maintained in a separate branch for potential upstream PR: [settings-pr-v2](https://github.com/Korbi0312/USBArmyKnife-modded/tree/settings-pr-v2)

## Flashing

1. Download the latest firmware from the [Releases](https://github.com/Korbi0312/USBArmyKnife-modded/releases) page
2. Extract `LILYGO-T-Dongle-S3.Firmware.binaries.zip`
3. Put the T-Dongle S3 into flash mode (hold BOOT + RESET, release RESET, then release BOOT)
4. Flash using [esptool](https://github.com/espressif/esptool) or the [web installer](https://esp.huhn.me/)

## Usage

1. Plug the T-Dongle S3 into a USB port
2. Connect to WiFi `iPhone14` (password: `password`)
3. Open http://4.3.2.1:8080 in your browser
4. Done – dashboard, payloads, settings and more are ready

## Building

```bash
# Install PlatformIO, then:
platformio run --environment LILYGO-T-Dongle-S3
# Or upload directly:
platformio run -t upload --upload-port COM4 --environment LILYGO-T-Dongle-S3
```

## License

MIT License – see [LICENSE](LICENSE)

Original project: https://github.com/i-am-shodan/USBArmyKnife
