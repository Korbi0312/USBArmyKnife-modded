# USB Army Knife - modded

Fork of [i-am-shodan/USBArmyKnife](https://github.com/i-am-shodan/USBArmyKnife), specifically tailored for the **LILYGO T-Dongle S3** (ESP32-S3).

## Supported Hardware

| Hardware | Description |
| -------- | ----------- |
| **LilyGo T-Dongle S3** (Recommended) ![screenshot](./docs/images/t-dongle-s3.png) | The LilyGo T-Dongle S3 is a USB pen drive shaped ESP32-S3 development board with color LCD screen, physical button, hidden micro SD card slot (inside the USB-A connector) and SPI adapter. 16MB flash, WiFi station + Bluetooth attacks. Fully supported and tested. |

## Modded Features

- **Crash LED**: Rear APA102 LED lights up solid red on ESP32 crash – instant visual feedback
- **Modern Gold UI**: New gold-themed web interface with German/English i18n, setting presets (USB mode, LED color), SD card usage in %
- **Original UI Crash Fix**: Switching between Modern and Original UI no longer crashes (OOM fix via `beginResponse_P`)
- **Emergency Reset**: Long button press triggers a software reset
- **Boot LED Color**: Configurable startup LED color via the web interface
- **DuckyScript**: German keyboard layout `win_de-DE` enabled by default
- **SD Storage**: SD card usage displayed on the dashboard
- **File Browser**: Built-in file browser with upload/download/delete

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
