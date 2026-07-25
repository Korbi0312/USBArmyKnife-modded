// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once

#include <Arduino.h>
#include <Preferences.h>
#include "../../USBArmyKnifeCapability.h"

class HardwareLED : public USBArmyKnifeCapability {
public:
    HardwareLED();
    virtual void begin(Preferences &prefs);
    virtual void loop(Preferences &prefs);
    
    void setColor(uint8_t r, uint8_t g, uint8_t b);
    void off();
    void on();
    void green();
    void red();
    void blue();
    void changeLEDState(bool on, uint8_t hue, uint8_t saturation, uint8_t lum, uint8_t brightness);

private:
    bool _initialized = false;
};

namespace Devices {
    extern HardwareLED LED;
}