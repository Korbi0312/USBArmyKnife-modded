// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#ifndef NO_LED
#if defined(LED_DI_PIN) && defined(LED_CI_PIN)
#include "../HardwareLED.h"
#include <APA102.h>
#include "../../../Debug/Logging.h"
#include "../../../Utilities/Settings.h"

#define LOG_LED "LED"

namespace Devices
{
    HardwareLED LED;
}

static APA102<LED_DI_PIN, LED_CI_PIN> ledStrip;

// Set the number of LEDs to control.
const uint16_t ledCount = 1;

// Create a buffer for holding the colors (3 bytes per color).
static rgb_color colors[ledCount];

const uint8_t brightness = 10;

static rgb_color hsvToRgb(uint16_t h, uint8_t s, uint8_t v)
{
    uint8_t f = (h % 60) * 255 / 60;
    uint8_t p = (255 - s) * (uint16_t)v / 255;
    uint8_t q = (255 - f * (uint16_t)s / 255) * (uint16_t)v / 255;
    uint8_t t = (255 - (255 - f) * (uint16_t)s / 255) * (uint16_t)v / 255;
    uint8_t r = 0, g = 0, b = 0;
    switch((h / 60) % 6){
        case 0: r = v; g = t; b = p; break;
        case 1: r = q; g = v; b = p; break;
        case 2: r = p; g = v; b = t; break;
        case 3: r = p; g = q; b = v; break;
        case 4: r = t; g = p; b = v; break;
        case 5: r = v; g = p; b = q; break;
    }
    return rgb_color(r, g, b);
}

void HardwareLED::setColor(uint8_t r, uint8_t g, uint8_t b) {
  colors[0] = rgb_color(r, g, b);
  ledStrip.write(colors, 1, brightness);
}

void HardwareLED::off() {
  ledStrip.write(colors, 1, 0);
}

void HardwareLED::on() {
  changeLEDState(true, 0, 0, 100, 255);
}

void HardwareLED::green() {
  colors[0] = rgb_color(0, 255, 0);
  ledStrip.write(colors, 1, brightness);
}

void HardwareLED::red() {
  colors[0] = rgb_color(255, 0, 0);
  ledStrip.write(colors, 1, brightness);
}

void HardwareLED::blue() {
  colors[0] = rgb_color(0, 0, 255);
  ledStrip.write(colors, 1, brightness);
}

void HardwareLED::changeLEDState(bool on, uint8_t hue, uint8_t saturation, uint8_t lum, uint8_t brightness)
{
  if (!on)
  {
    ledStrip.write(colors, 1, 0);
  }
  else
  {
    // The LED need some colour correction, otherwise the colours are not what you expect.
    // https://github.com/i-am-shodan/USBArmyKnife/issues/83
    if (hue == 100 && saturation == 100 && lum == 100) // green
    {
      hue = 120;     
    }

    // our brightness is between 0 - 255, need to rescale between 0-31
    brightness = (uint8_t) ((float) brightness * (31.f / 255.f));
    colors[0] = hsvToRgb(hue, saturation, lum);
    ledStrip.write(colors, 1, brightness);
  }
}

HardwareLED::HardwareLED()
{
}

void HardwareLED::loop(Preferences& prefs)
{
}

void HardwareLED::begin(Preferences &prefs)
{
  registerUserConfigurableSetting(CATEGORY_USB, "led-boot-color", USBArmyKnifeCapability::SettingType::String, "000000");
  String bootColor = prefs.getString("led-boot-color", "000000");
  if (bootColor.length() == 6) {
    long hex = strtol(bootColor.c_str(), NULL, 16);
    uint8_t r = (hex >> 16) & 0xFF;
    uint8_t g = (hex >> 8) & 0xFF;
    uint8_t b = hex & 0xFF;
    colors[0] = rgb_color(r, g, b);
    ledStrip.write(colors, 1, brightness);
    Debug::Log.info(LOG_LED, std::string("LED Boot-Farbe: #") + bootColor.c_str());
  } else {
    changeLEDState(true, 100, 100, 100, 200);
  }
  _initialized = true;
}
#endif
#endif