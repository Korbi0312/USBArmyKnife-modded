// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once

#include "../../../../USBArmyKnifeCapability.h"

class LD2410MotionSensorExtension : USBArmyKnifeCapability {
public:
  LD2410MotionSensorExtension();

  virtual void loop(Preferences& prefs);
  virtual void begin(Preferences& prefs);
};