// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once

#include "../../USBArmyKnifeCapability.h"

class WebSite : USBArmyKnifeCapability {
public:
  WebSite();

  virtual void loop(Preferences& prefs);
  virtual void begin(Preferences& prefs);
  virtual void end();
};

namespace Comms
{
    extern WebSite Web;
}