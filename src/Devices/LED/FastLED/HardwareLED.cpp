// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#if !defined(NO_LED) && !(defined(LED_DI_PIN) && defined(LED_CI_PIN))
#include "../HardwareLED.h"
#include "../../../Debug/Logging.h"
#include <FastLED.h>

#define LOG_LED "LED"
#define LED_PIN 39
#define NUM_LEDS 1

namespace Devices {
    HardwareLED LED;
}

static CRGB leds[NUM_LEDS];

HardwareLED::HardwareLED() {}

void HardwareLED::begin(Preferences &prefs) {
    FastLED.addLeds<WS2812, LED_PIN, GRB>(leds, NUM_LEDS);
    FastLED.setBrightness(64);
    registerUserConfigurableSetting(CATEGORY_USB, "led-boot-color", USBArmyKnifeCapability::SettingType::String, "000000");
    String bootColor = prefs.getString("led-boot-color", "000000");
    if (bootColor.length() == 6) {
        long hex = strtol(bootColor.c_str(), NULL, 16);
        uint8_t r = (hex >> 16) & 0xFF;
        uint8_t g = (hex >> 8) & 0xFF;
        uint8_t b = hex & 0xFF;
        setColor(r, g, b);
        Debug::Log.info(LOG_LED, std::string("LED Boot-Farbe: #") + bootColor.c_str());
    } else {
        off();
        Debug::Log.info(LOG_LED, "LED initialisiert (AUS)");
    }
    _initialized = true;
}

void HardwareLED::loop(Preferences &prefs) {
    // nothing to do
}

void HardwareLED::setColor(uint8_t r, uint8_t g, uint8_t b) {
    if (!_initialized) return;
    leds[0] = CRGB(r, g, b);
    FastLED.show();
}

void HardwareLED::off() {
    setColor(0, 0, 0);
}

void HardwareLED::on() {
    setColor(255, 255, 255);
}

void HardwareLED::green() {
    setColor(0, 255, 0);
}

void HardwareLED::red() {
    setColor(255, 0, 0);
}

void HardwareLED::blue() {
    setColor(0, 0, 255);
}

void HardwareLED::changeLEDState(bool on, uint8_t hue, uint8_t saturation, uint8_t lum, uint8_t brightness) {
    if (!_initialized) return;

    if (!on) {
        off();
        return;
    }

    FastLED.setBrightness(brightness);
    leds[0] = CHSV(hue, saturation, lum);
    FastLED.show();
}
#endif