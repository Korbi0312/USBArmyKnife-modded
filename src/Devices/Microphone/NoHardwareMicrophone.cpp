// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#ifdef NO_MIC
#include "HardwareMicrophone.h"

namespace Devices
{
    HardwareMicrophone Mic;
}

HardwareMicrophone::HardwareMicrophone()
{
}

void HardwareMicrophone::begin(Preferences &prefs)
{
}

void HardwareMicrophone::loop(Preferences &prefs)
{
}

void HardwareMicrophone::setCallback(const std::function<bool(uint8_t *, const size_t)> &callback)
{
}
#endif