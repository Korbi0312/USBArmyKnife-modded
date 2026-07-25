# USB Army Knife - modded

Fork speziell für den **LILYGO T-Dongle S3** (ESP32-S3).

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
