// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#ifndef DUCKYDATA_H
#define DUCKYDATA_H

#include <Arduino.h>
#include <Preferences.h>
#include <functional>
#include <unordered_map>
#include <string>   // ⬅️ IMPORTANT: Was missing! Added explicitly
#include "../../USBArmyKnifeCapability.h"

#define AUTORUN_FILENAME "/autorun.ds"

class DuckyPayload : public USBArmyKnifeCapability {
public:
    DuckyPayload();
    virtual void begin(Preferences &prefs);
    virtual void loop(Preferences &prefs);
    
    // ⬇️ Stops the current payload immediately (Emergency / Soft Reset)
    void stop();

    void registerExtension(const std::string& command, 
                          std::function<int(const std::string&, 
                                           const std::unordered_map<std::string, std::string>&, 
                                           const std::unordered_map<std::string, int>&)> callback);
    void registerDynamicVariable(std::function<std::pair<std::string, std::string>()> func);
    uint8_t getTotalErrors();
    void setPayload(const std::string &path);
    void setPayloadCmdLine(const std::string &cmdLine);
    std::string getPayloadRunningStatus();
    void setTypingDelay(uint32_t ms);
    void setKeyboardLayout(const std::string &layout);
};

namespace Attacks {
    extern DuckyPayload Ducky;
}

#endif