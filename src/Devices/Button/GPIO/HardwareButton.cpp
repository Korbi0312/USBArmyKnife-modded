#ifndef NO_BUTTON
#ifndef LILYGO_T_WATCH_S3

#include <OneButton.h>

#include "../HardwareButton.h"
#include "../../../Debug/Logging.h"

// ⬇️ Externe Deklaration der emergencyReset()-Funktion (definiert in main.cpp)
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
  // Kurzer Druck: Button-Status setzen (für DuckyScript WAIT_FOR_BUTTON_PRESS)
  button.attachClick([] {
    Devices::Button.setButtonPressState(true, button.isLongPressed());
  });

  // Langer Druck – ruft emergencyReset() auf (Soft-Reset)
  button.attachLongPressStart([] {
    Debug::Log.info("BUTTON", "Long press detected - triggering emergency reset!");
    emergencyReset(); // ⬅️ Not-Aus aus main.cpp aufrufen
  });

  // Falls der Button nach dem Loslassen nochmal getickt wird (optional)
  button.attachLongPressStop([] {
    Devices::Button.setButtonPressState(true, true);
  });

  // Langdruck-Intervall auf 3 Sekunden setzen
  button.setLongPressIntervalMs(3000);
}

#endif
#endif