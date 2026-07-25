// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#ifndef NO_BUTTON
#ifndef LILYGO_T_WATCH_S3

#include <OneButton.h>

#include "../HardwareButton.h"
#include "../../../Debug/Logging.h"

// ⬇️ External declaration of emergencyReset() (defined in main.cpp)
extern void emergencyReset();

static OneButton button(BTN_PIN, true);

namespace Devices
{
    HardwareButton Button;
}

HardwareButton::HardwareButton()
{
}

void HardwareButton::loop(Preferences& prefs)
{
    button.tick();
}

void HardwareButton::begin(Preferences &prefs)
{
  // Short press: set button state (for DuckyScript WAIT_FOR_BUTTON_PRESS)
  button.attachClick([] {
    Devices::Button.setButtonPressState(true, button.isLongPressed());
  });

  // Long press – calls emergencyReset() (Soft-Reset)
  button.attachLongPressStart([] {
    Debug::Log.info("BUTTON", "Long press detected - triggering emergency reset!");
    emergencyReset(); // ⬅️ Calls emergency reset from main.cpp
  });

  // Optional: handle tick after button release
  button.attachLongPressStop([] {
    Devices::Button.setButtonPressState(true, true);
  });

  // Set long-press interval to 3 seconds
  button.setLongPressIntervalMs(3000);
}

#endif
#endif