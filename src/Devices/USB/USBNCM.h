// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#pragma once

#include "../../USBArmyKnifeCapability.h"
#include "USBCore.h"

class USBNCM : USBArmyKnifeCapability {
public:
  USBNCM();

  virtual void loop(Preferences& prefs);
  virtual void begin(Preferences& prefs);
  virtual void end();

  void startPacketCollection();
  void stopPacketCollection();
};

namespace Devices::USB
{
    extern USBNCM NCM;
}