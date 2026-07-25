// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once
#include "BoardSupportImpl.h"

class ESP32BoardSupport : public BoardSupport {
public:
  ESP32BoardSupport();

  virtual void loop(Preferences& prefs) override;
  virtual void begin(Preferences& prefs) override;
  bool hasCrashed();
};