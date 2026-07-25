// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once

#include <string>

#include "../../USBArmyKnifeCapability.h"

class HardwareWiFi : USBArmyKnifeCapability {
public:
  HardwareWiFi();

  virtual void loop(Preferences& prefs);
  virtual void begin(Preferences& prefs);
  virtual void end();
  void setWiFi(const bool& state);
  bool getState();
  std::string currentIPAddress();
};

namespace Devices
{
    extern HardwareWiFi WiFi;
}