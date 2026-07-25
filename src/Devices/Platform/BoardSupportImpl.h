// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once

#include "../../USBArmyKnifeCapability.h"

class BoardSupport : public USBArmyKnifeCapability {
public:
  BoardSupport();

  virtual void loop(Preferences& prefs);
  virtual void begin(Preferences& prefs);
  bool hasCrashed() { return false; }
};