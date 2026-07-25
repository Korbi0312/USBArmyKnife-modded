# USB Army Knife - modded

Fork speziell für den **LILYGO T-Dongle S3** (ESP32-S3).

## Supported Hardware

| Hardware | Beschreibung |
| -------- | ------------ |
| **LilyGo T-Dongle S3** (Recommended) | The LilyGo T-Dongle S3 is a USB pen drive shaped ESP32-S3 development board. It features a colour LCD screen, physical button, hidden/covert micro SD card adapter (inside the USB-A connector) as well as a SPI adapter. It has 16MB of flash. It is based on the ESP32-S3 chipset which enables it to host a WiFi station as well as support a range of WiFi and Bluetooth attacks. *It is incredibly cheap!* There are two versions of this device with and without the screen. Only the version with the screen has been tested. |

## Changes in this fork

- **Crash-LED**: Die hintere APA102-LED leuchtet dauerhaft rot bei einem Crash
- **Modern Gold UI**: Neue optische Oberfläche mit Deutsch/Englisch-Unterstützung, Settings-Presets, SD-Karten-Anzeige
- **Original UI Crash-Fix**: Wechsel zwischen Modern und Original stürzte nicht mehr ab (OOM-Fix via `beginResponse_P`)
- **SD Storage**: Nutzung der SD-Karte wird im Dashboard in % angezeigt
- **DuckyScript**: Deutsche Tastatur `win_de-DE` standardmäßig aktiviert
- **Emergency Reset**: Hard-Reset per langem Tastendruck
- **Boot-LED-Farbe**: Konfigurierbar über das Web-Interface
- **i18n**: Komplette deutsche und englische Übersetzung der Weboberfläche

## Flashing

1. Lade die neueste Firmware von den [Releases](https://github.com/Korbi0312/USBArmyKnife-modded/releases) herunter
2. Entpacke `LILYGO-T-Dongle-S3.Firmware.binaries.zip`
3. Folge der [originalen Installationsanleitung](https://github.com/i-am-shodan/USBArmyKnife/wiki/Installation)

## Usage

1. T-Dongle S3 in den USB-Port stecken
2. Mit dem WLAN `iPhone14` (Passwort: `password`) verbinden
3. http://4.3.2.1:8080 im Browser öffnen
4. Fertig!

## License

MIT License - siehe [LICENSE](LICENSE)
