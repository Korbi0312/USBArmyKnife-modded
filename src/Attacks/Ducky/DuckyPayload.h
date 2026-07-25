#ifndef DUCKYDATA_H
#define DUCKYDATA_H

#include <Arduino.h>
#include <Preferences.h>
#include <functional>
#include <unordered_map>
#include <string>   // ⬅️ WICHTIG: Fehlt! Wurde hinzugefügt
#include "../../USBArmyKnifeCapability.h"

#define AUTORUN_FILENAME "/autorun.ds"

class DuckyPayload : public USBArmyKnifeCapability {
public:
    DuckyPayload();
    virtual void begin(Preferences &prefs);
    virtual void loop(Preferences &prefs);
    
    // ⬇️ Stoppt den aktuellen Payload sofort (Not-Aus / Emergency Reset)
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
};

namespace Attacks {
    extern DuckyPayload Ducky;
}

#endif