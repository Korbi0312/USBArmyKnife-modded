// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once

#include <Arduino.h>
#include <soc/gpio_struct.h>
#include "esp_attr.h"

#define CRASH_LED_DI_PIN 40
#define CRASH_LED_CI_PIN 39

// GPIO 32+ use the "out1" / "enable1" registers
#define CRASH_DI_BIT (1 << (CRASH_LED_DI_PIN - 32))
#define CRASH_CI_BIT (1 << (CRASH_LED_CI_PIN - 32))

static inline void IRAM_ATTR initCrashLedPins() {
    GPIO.enable1_w1ts.val = CRASH_DI_BIT | CRASH_CI_BIT;
}

static inline void IRAM_ATTR setCrashLedRed() {
    initCrashLedPins();

    // APA102 protocol: start frame (32 zeros), LED frame, end frame (32 ones)
    auto sendBit = [](bool bit) {
        if (bit) GPIO.out1_w1ts.val = CRASH_DI_BIT;
        else     GPIO.out1_w1tc.val = CRASH_DI_BIT;
        GPIO.out1_w1ts.val = CRASH_CI_BIT;
        GPIO.out1_w1tc.val = CRASH_CI_BIT;
    };
    auto sendByte = [&](uint8_t b) {
        for (int i = 7; i >= 0; i--) sendBit((b >> i) & 1);
    };

    for (int i = 0; i < 32; i++) sendBit(0);

    sendByte(0xFF); sendByte(0x00); sendByte(0x00); sendByte(0xFF);

    for (int i = 0; i < 32; i++) sendBit(1);
}

static inline void IRAM_ATTR crashHalt() {
    setCrashLedRed();
    while (1) { }
}
