// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once

#include "../USBArmyKnifeCapability.h"

class Auxiliary : USBArmyKnifeCapability {
public:
  Auxiliary();

  virtual void loop(Preferences& prefs);
  virtual void begin(Preferences& prefs);
};