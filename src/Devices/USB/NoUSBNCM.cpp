// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#ifndef ARDUINO_ARCH_ESP32
#include "USBNCM.h"
#include "../../Debug/Logging.h"

USBNCM::USBNCM()
{
}

void USBNCM::startPacketCollection()
{
    Debug::Log.error("NCM", "Not supported on this architecture");
}

void USBNCM::stopPacketCollection()
{
    Debug::Log.error("NCM", "Not supported on this architecture");
}

void USBNCM::begin(Preferences &prefs)
{
}

void USBNCM::loop(Preferences &prefs)
{
}

void USBNCM::end()
{
}
#endif