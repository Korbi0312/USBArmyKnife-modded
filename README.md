# USB Army Knife - modded

Fork von [i-am-shodan/USBArmyKnife](https://github.com/i-am-shodan/USBArmyKnife), speziell angepasst für den **LILYGO T-Dongle S3** (ESP32-S3).

## Supported Hardware

| Hardware | Beschreibung |
| -------- | ------------ |
| **LilyGo T-Dongle S3** (Recommended) ![screenshot](./docs/images/t-dongle-s3.png) | Der T-Dongle S3 ist ein USB-Stick-förmiges ESP32-S3 Development-Board mit farbigem LCD-Display, physischem Taster, verstecktem microSD-Kartenleser (im USB-A Stecker) und SPI-Adapter. 16MB Flash, WiFi-Station und Bluetooth-Angriffe. In dieser Version voll unterstützt und getestet. |

## Features dieses Forks

- **Crash-LED**: Die hintere APA102-LED leuchtet dauerhaft rot, falls der ESP32 abstürzt – sofort erkennbar
- **Modern Gold UI**: Neue optische Oberfläche mit Gold-Design, Deutsch/Englisch (i18n), Settings-Presets (USB-Modus, LED-Farbe), SD-Karten-Auslastung in %
- **Original UI Crash-Fix**: Wechsel zwischen Modern und Original UI stürzte nicht mehr ab (OOM-Fix)
- **Emergency Reset**: Langes Drücken der Taste löst einen Software-Reset aus
- **Boot-LED-Farbe**: Die Startfarbe der LED ist über das Web-Interface konfigurierbar
- **DuckyScript**: Deutsche Tastatur `win_de-DE` standardmäßig aktiviert
- **SD Storage**: Speicherbelegung der SD-Karte wird im Dashboard angezeigt
- **Datei-Browser**: Integrierter Dateibrowser mit Upload/Download/Löschen

## Flashing

1. Lade die neueste Firmware von den [Releases](https://github.com/Korbi0312/USBArmyKnife-modded/releases) herunter
2. Entpacke `LILYGO-T-Dongle-S3.Firmware.binaries.zip`
3. Versetze den T-Dongle S3 in den Flash-Modus (BOOT + RESET gedrückt halten, RESET loslassen, dann BOOT loslassen)
4. Flash mit [esptool](https://github.com/espressif/esptool) oder über den [Web-Installer](https://esp.huhn.me/)

## Usage

1. T-Dongle S3 in einen USB-Port stecken
2. Mit dem WLAN `iPhone14` (Passwort: `password`) verbinden
3. http://4.3.2.1:8080 im Browser öffnen
4. Fertig – Dashboard, Payloads, Einstellungen und mehr stehen bereit

## Building

```bash
# PlattformIO installiert? Dann einfach:
platformio run --environment LILYGO-T-Dongle-S3
# Oder mit Upload:
platformio run -t upload --upload-port COM4 --environment LILYGO-T-Dongle-S3
```

## Lizenz

MIT License – siehe [LICENSE](LICENSE)

Original-Projekt: https://github.com/i-am-shodan/USBArmyKnife
