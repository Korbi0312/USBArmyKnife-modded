// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once
#include "../ESP32BoardSupport.h"

class TWatchS3 : public ESP32BoardSupport
{
public:
  TWatchS3();

  void loop(Preferences& prefs) override;
  void begin(Preferences& prefs) override;
  bool hasCrashed() { return ESP32BoardSupport::hasCrashed(); }
};