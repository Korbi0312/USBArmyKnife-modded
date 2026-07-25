// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once

#include "../../USBArmyKnifeCapability.h"
#include <string>

class ESP32Marauder : USBArmyKnifeCapability {
public:
  ESP32Marauder();

  virtual void loop(Preferences& prefs);
  virtual void begin(Preferences& prefs);

  void run(const std::string& cmd);
  bool isRunning() { return running; }
  uint16_t getPacketCount();
private:
  bool running = false;
};

namespace Attacks
{
    extern ESP32Marauder Marauder;
}