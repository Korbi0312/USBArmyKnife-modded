// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once

#include <string>
#include <vector>
#include <functional>

#include "../../USBArmyKnifeCapability.h"
#include "../Storage/HardwareStorage.h"

class HardwareMicrophone : USBArmyKnifeCapability {
public:
  HardwareMicrophone();

  virtual void loop(Preferences& prefs);
  virtual void begin(Preferences& prefs);
  void setCallback(const std::function<bool(uint8_t *, const size_t)> &callback);
  void startCapture() { capture = true; }
  void stopCapture() { capture = false; }
private:
  bool capture = false;
};

namespace Devices
{
    extern HardwareMicrophone Mic;
};