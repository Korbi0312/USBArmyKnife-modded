// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once

#include <string>
#include <vector>
#include <functional>

#include "../../USBArmyKnifeCapability.h"

class HardwareIR : USBArmyKnifeCapability {
public:
HardwareIR();

  virtual void loop(Preferences& prefs);
  virtual void begin(Preferences& prefs);
};

namespace Devices
{
    extern HardwareIR IR;
};