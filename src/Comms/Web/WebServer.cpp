// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

#ifndef NO_WEB
#include "WebServer.h"

#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include "AsyncJson.h"
#include <ArduinoJson.h>
#include <uptime.h>
#include <ElegantOTA.h>

#include "../../Devices/TFT/HardwareTFT.h"
#include "../../Devices/Storage/HardwareStorage.h"
#include "../../Devices/LED/HardwareLED.h"
#include "../../Devices/WiFi/HardwareWiFi.h"
#include "../../Devices/Microphone/HardwareMicrophone.h"
#include "../../Devices/USB/USBCore.h"
#include "../../Devices/USB/USBCDC.h"
#include "../../Attacks/Agent/Agent.h"
#include "../../Debug/Logging.h"

#include "../../Attacks/Marauder/Marauder.h"
#include "../../Attacks/Ducky/DuckyPayload.h"

#include "../../Utilities/Settings.h"
#include "../../version.h"

#define LOG_WEB "WEB"

namespace Comms
{
  WebSite Web;
}

static AsyncWebServer controlInterfaceWebServer(8080);
static AsyncWebSocket ws("/websockify");
static AsyncWebSocket audio("/audio");

extern std::unordered_map<const char *, std::pair<const uint8_t *, size_t>> staticHtmlFilesLookup;
static const char *remoteAddress = "127.0.0.1:7002";
static Preferences *preferences = nullptr;
static bool ledState = false;

extern void emergencyReset();

// ============================================================
// Original Bootstrap HTML (embedded in PROGMEM, served at /index_original.html)
// ============================================================
const char INDEX_ORIGINAL_HTML[] PROGMEM = R"rawliteral(<!DOCTYPE html><html data-bs-theme="light" lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0, shrink-to-fit=no"><title>Dashboard - USB Army Knife</title>
			<script>!function(){const e=()=>localStorage.getItem("theme"),t=document.documentElement.getAttribute("data-bss-forced-theme"),a=()=>{if(t)return t;const a=e();if(a)return a;const r=document.documentElement.getAttribute("data-bs-theme");return r||(window.matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light")},r=e=>{"auto"===e&&window.matchMedia("(prefers-color-scheme: dark)").matches?document.documentElement.setAttribute("data-bs-theme","dark"):document.documentElement.setAttribute("data-bs-theme",e)};r(a());const c=(e,t=!1)=>{const a=[].slice.call(document.querySelectorAll(".theme-switcher"));if(a.length){document.querySelectorAll("[data-bs-theme-value]").forEach((e=>{e.classList.remove("active"),e.setAttribute("aria-pressed","false")}));for(const t of a){const a=t.querySelector('[data-bs-theme-value="'+e+'"]');a&&(a.classList.add("active"),a.setAttribute("aria-pressed","true"))}}};window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change",(()=>{const t=e();"light"!==t&&"dark"!==t&&r(a())})),window.addEventListener("DOMContentLoaded",(()=>{c(a()),document.querySelectorAll("[data-bs-theme-value]").forEach((e=>{e.addEventListener("click",(t=>{t.preventDefault();const a=e.getAttribute("data-bs-theme-value");(e=>{localStorage.setItem("theme",e)})(a),r(a),c(a)}))}))}))}();</script><link rel="stylesheet" href="assets/bootstrap/css/bootstrap.min.css"><link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Nunito:200,200i,300,300i,400,400i,600,600i,700,700i,800,800i,900,900i&amp;display=swap"><link rel="stylesheet" href="assets/css/styles.min.css"></head><body id="page-top"><div id="wrapper"><div class="d-flex flex-column" id="content-wrapper"><div id="content"></div></div></div><nav class="navbar navbar-expand bg-dark py-3" data-bs-theme="dark"><div class="container"><a class="navbar-brand d-flex align-items-center" href="#"><span>USB Army Knife</span></a><button data-bs-toggle="collapse" class="navbar-toggler" data-bs-target="#navcol-5"><span class="visually-hidden">Toggle navigation</span><span class="navbar-toggler-icon"></span></button><div class="collapse navbar-collapse" id="navcol-5"><ul class="navbar-nav ms-auto"></ul><div class="theme-switcher dropdown"><a class="dropdown-toggle" aria-expanded="false" data-bs-toggle="dropdown" href="#"><svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" fill="currentColor" viewBox="0 0 16 16" class="bi bi-sun-fill mb-1">
  <path d="M8 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8M8 0a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 0m0 13a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 13m8-5a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2a.5.5 0 0 1 .5.5M3 8a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2A.5.5 0 0 1 3 8m10.657-5.657a.5.5 0 0 1 0 .707l-1.414 1.415a.5.5 0 1 1-.707-.708l1.414-1.414a.5.5 0 0 1 .707 0m-9.193 9.193a.5.5 0 0 1 0 .707L3.05 13.657a.5.5 0 0 1-.707-.707l1.414-1.414a.5.5 0 0 1 .707 0zm9.193 2.121a.5.5 0 0 1-.707 0l-1.414-1.414a.5.5 0 0 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .707M4.464 4.465a.5.5 0 0 1-.707 0L2.343 3.05a.5.5 0 1 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .708z"></path>
</svg></a><div class="dropdown-menu">
    <a class="dropdown-item d-flex align-items-center" href="#" data-bs-theme-value="light"><svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" fill="currentColor" viewBox="0 0 16 16" class="bi bi-sun-fill opacity-50 me-2">
  <path d="M8 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8M8 0a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 0m0 13a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 13m8-5a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2a.5.5 0 0 1 .5.5M3 8a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2A.5.5 0 0 1 3 8m10.657-5.657a.5.5 0 0 1 0 .707l-1.414 1.415a.5.5 0 1 1-.707-.708l1.414-1.414a.5.5 0 0 1 .707 0m-9.193 9.193a.5.5 0 0 1 0 .707L3.05 13.657a.5.5 0 0 1-.707-.707l1.414-1.414a.5.5 0 0 1 .707 0zm9.193 2.121a.5.5 0 0 1-.707 0l-1.414-1.414a.5.5 0 0 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .707M4.464 4.465a.5.5 0 0 1-.707 0L2.343 3.05a.5.5 0 1 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .708z"></path>
</svg>Light</a>
    <a class="dropdown-item d-flex align-items-center" href="#" data-bs-theme-value="dark"><svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" fill="currentColor" viewBox="0 0 16 16" class="bi bi-moon-stars-fill opacity-50 me-2">
  <path d="M6 .278a.768.768 0 0 1 .08.858 7.208 7.208 0 0 0-.878 3.46c0 4.021 3.278 7.277 7.318 7.277.527 0 1.04-.055 1.533-.16a.787.787 0 0 1 .81.316.733.733 0 0 1-.031.893A8.349 8.349 0 0 1 8.344 16C3.734 16 0 12.286 0 7.71 0 4.266 2.114 1.312 5.124.06A.752.752 0 0 1 6 .278"></path>
  <path d="M10.794 3.148a.217.217 0 0 1 .412 0l.387 1.162c.173.518.579.924 1.097 1.097l1.162.387a.217.217 0 0 1 0 .412l-1.162.387a1.734 1.734 0 0 0-1.097 1.097l-.387 1.162a.217.217 0 0 1-.412 0l-.387-1.162A1.734 1.734 0 0 0 9.31 6.593l-1.162-.387a.217.217 0 0 1 0-.412l1.162-.387a1.734 1.734 0 0 0 1.097-1.097l.387-1.162zM13.863.099a.145.145 0 0 1 .274 0l.258.774c.115.346.386.617.732.732l.774.258a.145.145 0 0 1 0 .274l-.774.258a1.156 1.156 0 0 0-.732.732l-.258.774a.145.145 0 0 1-.274 0l-.258-.774a1.156 1.156 0 0 0-.732-.732l-.774-.258a.145.145 0 0 1 0-.274l.774-.258c.346-.115.617-.386.732-.732L13.863.1z"></path>
</svg>Dark</a>
    <a class="dropdown-item d-flex align-items-center" href="#" data-bs-theme-value="auto"><svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" fill="currentColor" viewBox="0 0 16 16" class="bi bi-circle-half opacity-50 me-2">
  <path d="M8 15A7 7 0 1 0 8 1zm0 1A8 8 0 1 1 8 0a8 8 0 0 1 0 16"></path>
</svg>Auto</a>
    <!-- NEU: Modern -->
    <a class="dropdown-item d-flex align-items-center" href="#" data-bs-theme-value="modern">
        <svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" fill="currentColor" viewBox="0 0 16 16" class="bi bi-stars opacity-50 me-2">
            <path d="M8 0a1 1 0 0 1 1 1v2a1 1 0 1 1-2 0V1a1 1 0 0 1 1-1zm0 12a1 1 0 0 1 1 1v2a1 1 0 1 1-2 0v-2a1 1 0 0 1 1-1zm6.364-8.364a1 1 0 0 1 0 1.414l-1.414 1.414a1 1 0 1 1-1.414-1.414l1.414-1.414a1 1 0 0 1 1.414 0zM4.05 11.95a1 1 0 0 1 0 1.414L2.636 14.778a1 1 0 1 1-1.414-1.414l1.414-1.414a1 1 0 0 1 1.414 0zM16 8a1 1 0 0 1-1 1h-2a1 1 0 1 1 0-2h2a1 1 0 0 1 1 1zM3 8a1 1 0 0 1-1 1H0a1 1 0 0 1 0-2h2a1 1 0 0 1 1 1zm11.364 6.364a1 1 0 0 1-1.414 0l-1.414-1.414a1 1 0 1 1 1.414-1.414l1.414 1.414a1 1 0 0 1 0 1.414zM4.05 4.05a1 1 0 0 1-1.414 0L1.222 2.636a1 1 0 1 1 1.414-1.414l1.414 1.414a1 1 0 0 1 0 1.414z"/>
        </svg>
        Modern
    </a>
</div></div></div></div></nav><div><ul class="nav nav-tabs" role="tablist"><li class="nav-item" role="presentation"><a class="nav-link active" role="tab" data-bs-toggle="tab" href="#tab-1">Status</a></li><li class="nav-item" role="presentation"><a class="nav-link" role="tab" data-bs-toggle="tab" href="#tab-2">Settings</a></li><li class="nav-item" role="presentation"><a class="nav-link" role="tab" data-bs-toggle="tab" href="#tab-3">Commands</a></li><li class="nav-item" role="presentation"><a class="nav-link" role="tab" data-bs-toggle="tab" href="#tab-4">File Browser</a></li><li class="nav-item" role="presentation"><a class="nav-link" role="tab" data-bs-toggle="tab" href="#tab-8">VNC</a></li><li class="nav-item" role="presentation"><a class="nav-link" role="tab" data-bs-toggle="tab" id="micTab" href="#tab-9">Microphone</a></li><li class="nav-item" role="presentation"><a class="nav-link" role="tab" data-bs-toggle="tab" href="#tab-5" style="display: none;">Editor</a></li><li class="nav-item" role="presentation"><a class="nav-link" role="tab" data-bs-toggle="tab" href="#tab-6">Logs</a></li><li class="nav-item" role="presentation"><a class="nav-link" role="tab" data-bs-toggle="tab" href="#tab-10">Update</a></li><li class="nav-item" role="presentation"><a class="nav-link" role="tab" data-bs-toggle="tab" href="#tab-7">Help</a></li></ul><div class="tab-content"><div class="tab-pane active" role="tabpanel" id="tab-1"><div class="container py-4 py-xl-5"><div class="text-center text-white-50 bg-primary border rounded border-0 p-3"><div class="row row-cols-2 row-cols-md-4"><div class="col"><div class="p-3"><h4 class="fw-bold text-white mb-0">Status</h4><p id="status" class="mb-0">Connection Error</p></div></div><div class="col"><div class="p-3"><h4 class="fw-bold text-white mb-0">Uptime</h4><p id="uptime" class="mb-0">Unknown</p></div></div><div class="col"><div class="p-3"><h4 class="fw-bold text-white mb-0">USB Mode</h4><p id="USBmode" class="mb-0">Unknown</p></div></div><div class="col"><div class="p-3"><h4 class="fw-bold text-white mb-0">Errors</h4><p id="errorCount" class="mb-0">Unknown</p></div></div><div class="col"><h4 class="fw-bold text-white mb-0">Agent</h4><p id="agentStatus">Unknown</p></div><div class="col"><h4 class="fw-bold text-white mb-0">Connected to</h4><p id="machineName">Unknown</p></div></div></div></div><ul class="list-group"><li class="list-group-item" style="border-style: none;"><span>SD card</span><div class="progress" id="sdcard_capacity">
			<div class="progress-bar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="width: 0%;">0%</div>
		</div></li><li class="list-group-item" style="border-style: none;"><span>Memory</span><div class="progress" id="heapUsage">
			<div class="progress-bar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="width: 0%;">0%</div>
		</div></li></ul><form method="get" action="/runfile"><ul class="list-group"><li class="list-group-item" style="border-style: none;"><label class="form-label" style="color: rgb(133, 135, 150);">Run script</label><select class="form-select" id="scriptFileSelectionBox" name="filename"></select></li><li class="list-group-item"><input class="btn btn-primary" type="submit" value="Execute"></li></ul></form></div><div class="tab-pane" role="tabpanel" id="tab-2"><div class="accordion" role="tablist" id="settings-accordion"><div id="settingsLoading">Loading settings...</div></div></div><div class="tab-pane" role="tabpanel" id="tab-3"><div class="accordion" role="tablist" id="accordion-1"><div class="accordion-item"><h2 class="accordion-header" role="tab"><button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#accordion-1 .item-1" aria-expanded="false" aria-controls="accordion-1 .item-1">Marauder</button></h2><div class="accordion-collapse collapse item-1" role="tabpanel" data-bs-parent="#accordion-1"><div class="accordion-body"><form action="/marauder" method="get"><ul class="list-group"><li class="list-group-item" style="border-style: none;"><label class="form-label">Run an ESP32 Marauder command</label><select class="form-select" id="marauderCmd" name="marauderCmd"><optgroup label="Global"><option value="stopscan">stopscan</option></optgroup><optgroup label="Beacon spam"><option value="attack -t beacon -l">Spam already listed SSIDs</option><option value="attack -t beacon -r">Spam random SSIDs</option><option value="attack -t beacon -a">Create fake copies of an AP</option></optgroup><optgroup label="Deauth"><option value="attack -t deauth">Target selected APs</option><option value="attack -t deauth -c">Target selected APs and Stations</option></optgroup><optgroup label="Probe request flood"><option value="attack -t probe">Run standard probe request attack</option><option value="attack -t rickroll">Rickroll</option></optgroup><optgroup label="BT spam"><option value="btspamall">BT spam all</option></optgroup></select></li><li class="list-group-item" style="border-style: none;"><input class="btn btn-primary" type="submit" value="Execute"></li></ul></form></div></div></div><div class="accordion-item"><h2 class="accordion-header" role="tab"><button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#accordion-1 .item-2" aria-expanded="false" aria-controls="accordion-1 .item-2">Agent</button></h2><div class="accordion-collapse collapse item-2" role="tabpanel" data-bs-parent="#accordion-1"><div class="accordion-body"><form action="/runagentcmd" method="get"><ul class="list-group"><li class="list-group-item" style="border-style: none;"><label class="form-label">Run an operating system command to be run by the agent. The agent must be installed and connected.</label><input class="form-control" type="text" name="rawCommand" placeholder="dir *.txt"></li><li class="list-group-item" style="border-style: none;"><input class="btn btn-primary" type="submit" value="Execute"></li></ul></form></div></div></div><div class="accordion-item"><h2 class="accordion-header" role="tab"><button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#accordion-1 .item-3" aria-expanded="true" aria-controls="accordion-1 .item-3">Raw</button></h2><div class="accordion-collapse collapse show item-3" role="tabpanel" data-bs-parent="#accordion-1"><div class="accordion-body"><form action="/rawinput" method="get"><ul class="list-group"><li class="list-group-item" style="border-style: none;"><label class="form-label" for="rawCommand">Execute a command line</label><input class="form-control" type="text" name="rawCommand"></li><li class="list-group-item" style="border-style: none;"><input class="btn btn-primary" type="submit" value="Execute"></li></ul></form></div></div></div></div></div><div class="tab-pane" role="tabpanel" id="tab-4"><div class="accordion" role="tablist" id="accordion-2"><div class="accordion-item"><h2 class="accordion-header" role="tab"><button class="accordion-button" type="button" data-bs-toggle="collapse" data-bs-target="#accordion-2 .item-1" aria-expanded="true" aria-controls="accordion-2 .item-1">Browse</button></h2><div class="accordion-collapse collapse show item-1" role="tabpanel" data-bs-parent="#accordion-2"><div class="accordion-body"><div id="tree"></div><form action="/" method="get"><ul class="list-group"><li class="list-group-item" style="border-style: none;"><label class="form-label" for="filename">Filename</label><input class="form-control" type="text" id="fileSelectionBox" readonly="" name="filename"></li><li class="list-group-item" style="border-style: none;"><input class="btn btn-primary" type="submit" id="fileExecuteButton" style="margin-right: 10px;" value="Execute" formaction="/runfile" method="get" disabled=""><input class="btn btn-secondary" type="submit" id="fileDisplayButton" style="margin-right: 10px;" value="Display" formaction="/showimage" method="get" disabled=""><input class="btn btn-secondary" type="submit" id="fileDownloadButton" style="margin-right: 10px;" value="Download" formaction="/download" method="get" disabled=""><input class="btn btn-danger" type="submit" id="fileDeleteButton" value="Delete" disabled="" formaction="/delete" style="margin-right: 10px;"></li></ul></form></div></div></div><div class="accordion-item"><h2 class="accordion-header" role="tab"><button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#accordion-2 .item-2" aria-expanded="false" aria-controls="accordion-2 .item-2">Upload</button></h2><div class="accordion-collapse collapse item-2" role="tabpanel" data-bs-parent="#accordion-2"><div class="accordion-body"><ul class="list-group"><li class="list-group-item" style="border-style: none;"><input type="file" id="fileInputBox" style="margin-bottom: 8px;"></li><li class="list-group-item" style="border-style: none;"><input class="btn btn-primary btn-primary" type="submit" id="fileButton" value="Upload" onclick="uploadFile()"></li></ul><div class="progress" id="fileUploadProgressBar">
			<div class="progress-bar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="width: 0%;">0%</div>
		</div></div></div></div></div></div><div class="tab-pane" role="tabpanel" id="tab-8"><p style="margin-top: 5px;margin-right: 5px;margin-left: 5px;">With the agent installed you can inspect the screen of the remote machine by clicking&nbsp;<a href="/vnc/index.html">HERE</a></p></div><div class="tab-pane" role="tabpanel" id="tab-9"><ul class="list-group"><li class="list-group-item"><div class="row"><div class="col"><label class="col-form-label">Enable microphone</label></div><div class="col" id="micGrid"><label class="switch">
  <input type="checkbox">
  <span class="slider round"></span>
</label></div></div><div class="row" style="margin-bottom: 8px;"><div class="col"><span style="margin-right: 8px;">Download all captured audio as WAV</span></div><div class="col"><button class="btn btn-primary" type="button" onclick="onAudioSave()">Save</button></div></div><div class="row"><div class="col"><span style="margin-right: 8px;">Clear audio cache</span></div><div class="col"><button class="btn btn-primary" type="button" onclick="onAudioCacheClear()">Clear</button></div></div></li></ul></div><div class="tab-pane" role="tabpanel" id="tab-5"><div></div></div><div class="tab-pane" role="tabpanel" id="tab-6"><ul class="list-group"><li class="list-group-item" style="border-style: none;"><textarea id="logBox" rows="25" style="min-width: 99%;overflow: scroll;overflow-y: scroll;overflow-x: clip;" name="logBox"></textarea></li><li class="list-group-item" style="border-style: none;"><form method="get" action="/clearlogs"><input class="btn btn-primary" type="submit" value="Clear"></form></li></ul></div><div class="tab-pane" role="tabpanel" id="tab-7"><ul class="list-group"><li class="list-group-item" style="border-style: none;"><a href="https://docs.hak5.org/hak5-usb-rubber-ducky/duckyscript-tm-quick-reference">DuckyScript quick start guide</a></li><li class="list-group-item" style="border-style: none;"><a href="#">Documentation</a></li><li class="list-group-item" style="border-style: none;"><a href="#">GitHub issue tracker</a></li><li class="list-group-item" style="border-style: none;"><a href="https://github.com/justcallmekoko/ESP32Marauder/wiki">ESP32 Marauder project</a></li><li class="list-group-item"><span>Version</span><p id="versionTag">0000000000000000000000000000000000000000</p></li></ul></div><div class="tab-pane" role="tabpanel" id="tab-10"><p>To perform an over the air (OTA) firmware update&nbsp;<a href="/update">click here</a>. You will need a valid firmware.bin file for your hardware revision. <strong><span style="color: rgb(255, 15, 0);">WARNING </span></strong>- No checking is performed to ensure you're using the right version so beware!</p></div></div></div><footer class="text-center bg-dark"></footer><script src="assets/bootstrap/js/bootstrap.min.js"></script><script src="assets/js/script.min.js"></script>
<!-- Additional script for Modern theme switch -->
<script>
(function() {
    // When the Modern button is clicked, redirect to index.html
    document.querySelectorAll('[data-bs-theme-value="modern"]').forEach(function(el) {
        el.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopImmediatePropagation();
            localStorage.setItem('theme', 'gold');
            window.location.href = 'index.html';
        });
    });

    // On load: evaluate URL parameter ?theme=light/dark first (before localStorage check)
    const urlParams = new URLSearchParams(window.location.search);
    const themeParam = urlParams.get('theme');
    if (themeParam === 'light' || themeParam === 'dark') {
        document.documentElement.setAttribute('data-bs-theme', themeParam);
        localStorage.setItem('theme', themeParam);
        // Remove URL parameter without reloading the page
        if (window.history.replaceState) {
            const cleanUrl = window.location.pathname + window.location.hash;
            window.history.replaceState({}, '', cleanUrl);
        }
    }

    // On load: if stored theme is 'gold' or 'modern', redirect to index.html
    var storedTheme = localStorage.getItem('theme');
    if (storedTheme === 'gold' || storedTheme === 'modern') {
        window.location.href = 'index.html';
    }
})();
</script>

<script>
const SETTING_PRESETS = {
    'usbDeviceType': [['0','None (0)'],['1','Serial (1)'],['2','NCM (2)']],
    'usbClassType': [['0','None (0)'],['1','HID (1)'],['2','Storage (2)']]
};
function renderSettingInput(name, val, targetId) {
    const presets = SETTING_PRESETS[name];
    if (presets) {
        var opts = '';
        for (var i = 0; i < presets.length; i++) {
            var p = presets[i];
            opts += '<option value="' + p[0] + '"' + (String(val) === p[0] ? ' selected' : '') + '>' + p[1] + '</option>';
        }
        return '<select class="form-control" id="inp-' + targetId + '">' + opts + '</select>';
    }
    if (name === 'led-boot-color') {
        return '<input class="form-control" type="color" id="inp-' + targetId + '" value="#' + String(val).replace(/^#/, '') + '">';
    }
    return '<input class="form-control" type="text" id="inp-' + targetId + '" value="' + String(val).replace(/"/g, '&quot;') + '">';
}
async function loadSettingsOrig() {
    try {
        const res = await fetch('/api/settings');
        const categories = await res.json();
        const container = document.getElementById('settings-accordion');
        let itemId = 0;
        let html = '';
        for (const cat of categories) {
            const settings = cat.settings || [];
            for (const s of settings) {
                const name = s.name || '';
                const val = s.value !== undefined ? s.value : (s.default || '');
                itemId++;
                const targetId = 'setting-item-' + itemId;
                html += '<div class="accordion-item">';
                html += '<h2 class="accordion-header" role="tab">';
                html += '<button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#' + targetId + '" aria-expanded="false" aria-controls="' + targetId + '">' + name + '</button>';
                html += '</h2>';
                html += '<div class="accordion-collapse collapse" id="' + targetId + '" role="tabpanel" data-bs-parent="#settings-accordion">';
                html += '<div class="accordion-body">';
                html += '<div class="row"><div class="col"><label class="col-form-label">Current value</label></div><div class="col"><label class="col-form-label" id="cur-' + targetId + '">' + String(val) + '</label></div></div>';
                html += '<hr>';
                html += '<label class="form-label">New value</label>';
                html += '<div class="input-group">';
                html += renderSettingInput(name, val, targetId);
                html += '<button class="btn btn-primary" onclick="saveSetting(\'' + name + '\', \'' + targetId + '\')">Save</button>';
                html += '</div>';
                html += '</div></div></div>';
            }
        }
        container.innerHTML = html;
    } catch(e) {
        document.getElementById('settingsLoading').textContent = 'Error loading settings: ' + e.message;
    }
}

async function saveSetting(name, targetId) {
    const inp = document.getElementById('inp-' + targetId);
    let val = inp.value;
    if (name === 'led-boot-color') val = val.replace(/^#/, '');
    try {
        const res = await fetch('/set?name=' + encodeURIComponent(name) + '&value=' + encodeURIComponent(val));
        if (res.ok) {
            document.getElementById('cur-' + targetId).textContent = val;
            inp.value = val;
        } else {
            alert('Save failed');
        }
    } catch(e) {
        alert('Save error: ' + e.message);
    }
}

document.addEventListener('DOMContentLoaded', function() {
    loadSettingsOrig();
});
</script>

<script>
(function() {
    var lang = localStorage.getItem('lang') || 'en';
    function setKB(l) {
        var x = new XMLHttpRequest();
        x.open('GET', '/rawinput?rawCommand=' + encodeURIComponent('KEYBOARD_LAYOUT ' + l), true);
        x.send();
    }
    var i18n = {de:{
        'Status':'Status','Settings':'Einstellungen','Commands':'Befehle','File Browser':'Dateibrowser',
        'VNC':'VNC','Microphone':'Mikrofon','Editor':'Editor','Logs':'Protokolle',
        'Update':'Update','Help':'Hilfe','Connection Error':'Verbindungsfehler',
        'Unknown':'Unbekannt','Uptime':'Laufzeit','USB Mode':'USB-Modus',
        'Loading settings...':'Lade Einstellungen...','Loading...':'Lade...',
        'Run script':'Skript ausführen','Execute':'Ausführen','Clear':'Löschen',
        'Save':'Speichern','Memory':'Speicher','Storage':'Speicherplatz',
        'LED':'LED','Toggle LED':'LED umschalten','Run':'Ausführen',
        'Delete':'Löschen','Upload':'Hochladen','Download':'Herunterladen',
        'Refresh':'Aktualisieren','Ready':'Bereit',
        'Current value':'Aktueller Wert','New value':'Neuer Wert',
        'Error loading settings:':'Fehler beim Laden:','Save failed':'Fehler',
        'Save error:':'Speicherfehler:','USB Army Knife':'USB Army Knife',
        'Light':'Hell','Dark':'Dunkel','Auto':'Auto',
        'Run an ESP32 Marauder command':'Marauder Befehl ausführen',
        'Spam already listed SSIDs':'Gelistete SSIDs spam',
        'Spam random SSIDs':'Zufällige SSIDs','Create fake copies of an AP':'Fake-APs',
        'Target selected APs':'Ziel-APs','Target selected APs and Stations':'Ziel-APs + Stations',
        'Run standard probe request attack':'Standard Probe-Request',
        'With the agent installed you can inspect the screen of the remote machine by clicking':'Bildschirm anzeigen mit Agent:',
        'Enable microphone':'Mikrofon','Download all captured audio as WAV':'Audio als WAV',
        'Clear audio cache':'Audio-Cache leeren','To perform an over the air (OTA) firmware update':'OTA-Update:',
        'click here':'hier klicken','DuckyScript quick start guide':'DuckyScript-Guide',
        'ESP32 Marauder project':'Marauder Projekt','Documentation':'Dokumentation',
        'GitHub issue tracker':'GitHub Issues','Version':'Version',
    }};
    function so(el){if(!el.hasAttribute('data-o'))el.setAttribute('data-o',el.textContent.trim());}
    function ro(el){var o=el.getAttribute('data-o');if(o)el.textContent=o;}
    function tr(l){
        var t=i18n[l]||{};
        if(l==='en'){document.querySelectorAll('[data-o]').forEach(ro);return;}
        document.querySelectorAll('.nav-link,.dropdown-item,h4,h5,h6,th,label,.form-label,.accordion-button,p,.list-group-item,a,span,option,.col-form-label,.btn').forEach(function(el){
            var txt=el.textContent.trim();
            if(txt&&t[txt]&&t[txt]!==txt){so(el);el.textContent=t[txt];}
        });
        document.querySelectorAll('[title]').forEach(function(el){
            var txt=el.getAttribute('title').trim();
            if(txt&&t[txt])el.setAttribute('title',t[txt]);
        });
        document.querySelectorAll('[placeholder]').forEach(function(el){
            var txt=el.getAttribute('placeholder').trim();
            if(txt&&t[txt])el.setAttribute('placeholder',t[txt]);
        });
    }
    var nav=document.querySelector('.navbar .container');
    if(nav){
        var d=document.createElement('div');
        d.className='d-flex align-items-center ms-2';
        d.innerHTML='<button class="btn btn-sm btn-outline-light me-1 lb'+(lang==='de'?' active':'')+'" data-l="de">DE</button><button class="btn btn-sm btn-outline-light lb'+(lang==='en'?' active':'')+'" data-l="en">EN</button>';
        nav.appendChild(d);
    }
    var s=document.createElement('style');
    s.textContent='.lb.active{background:rgba(255,255,255,0.2);font-weight:700}.lb{cursor:pointer}';
    document.head.appendChild(s);
    if(lang==='de')setTimeout(function(){tr('de');},800);
    setInterval(function(){if(lang==='de')tr('de');},3000);
    document.addEventListener('click',function(e){
        var b=e.target.closest('.lb');
        if(b){
            var l=b.getAttribute('data-l');
            lang=l;localStorage.setItem('lang',l);
            document.querySelectorAll('.lb').forEach(function(x){x.classList.toggle('active',x.getAttribute('data-l')===l);});
            tr(l);
        }
    });
})();
</script>

</body></html>)rawliteral";

static const std::unordered_map<std::string, std::string> mimeTypes = {
    {".html", "text/html"},
    {".js", "application/javascript"},
    {".css", "text/css"},
    {".png", "image/png"},
    {".jpg", "image/jpeg"},
    {".jpeg", "image/jpeg"},
    {".gif", "image/gif"},
    {".bmp", "image/bmp"},
    {".webp", "image/webp"},
    {".ico", "image/x-icon"},
    {".svg", "image/svg+xml"},
    {".json", "application/json"},
    {".txt", "text/plain"},
    {".pdf", "application/pdf"},
    {".zip", "application/zip"}};

static std::string prettyPrintUptime()
{
  std::string ret;
  if (uptime::getDays() != 0)
  {
    ret += std::to_string(uptime::getDays()) + " days";
  }
  if (uptime::getHours() != 0)
  {
    ret += std::to_string(uptime::getHours()) + " hours";
  }
  if (uptime::getMinutes() != 0)
  {
    ret += std::to_string(uptime::getMinutes()) + " minutes";
  }
  if (ret.empty())
  {
    ret = "A few seconds";
  }

  return ret;
}

static void onWsEvent(AsyncWebSocket *server, AsyncWebSocketClient *client, AwsEventType type, void *arg, uint8_t *data, size_t len)
{
  if (type == WS_EVT_CONNECT)
  {
    uint32_t remoteAddLen = strlen(remoteAddress);
    Devices::USB::CDC.writeBinary(HostCommand::WSCONNECT, (uint8_t *)remoteAddress, remoteAddLen);
  }
  else if (type == WS_EVT_DATA && data != nullptr && len != 0)
  {
    Devices::USB::CDC.writeBinary(HostCommand::WSDATA, data, len);
  }
  else if (type == WS_EVT_DISCONNECT)
  {
    Devices::USB::CDC.writeBinary(HostCommand::WSDISCONNECT, nullptr, 0);
  }
  else
  {
    Devices::USB::CDC.writeDebugString("Got an unhandler websocket event: " + std::to_string(type));
  }
}

static void onWsAudioEvent(AsyncWebSocket *server, AsyncWebSocketClient *client, AwsEventType type, void *arg, uint8_t *data, size_t len)
{
  if (type == WS_EVT_DISCONNECT)
  {
    Devices::Mic.stopCapture();
  }
}


static std::pair<const uint8_t *, size_t> getStaticHtml(const String &url)
{
  for (const auto &[key, value] : staticHtmlFilesLookup)
  {
    if (url == key)
    {
      return value;
    }
  }
  return std::make_pair<const uint8_t *, size_t>(nullptr, 0);
}

static const char *GetMimeType(const char *fname)
{
  std::string filename(fname);
  // Extract the file extension
  size_t dotPos = filename.find_last_of('.');
  if (dotPos == std::string::npos)
  {
    // No extension found
    return nullptr;
  }

  std::string extension = filename.substr(dotPos);

  // Look up the MIME type
  auto it = mimeTypes.find(extension);
  if (it != mimeTypes.end())
  {
    return it->second.c_str();
  }
  else
  {
    // Extension not found in our mapping
    return nullptr;
  }
}

static void webRequestHandler(AsyncWebServerRequest *request)
{
  const auto &url = request->url();
  // Debug::Log.info(LOG_WEB, std::string("webRequestHandler ") + url.c_str());

  if (url == "/wpad.dat")
  {
    request->send(404);
  }
  else if (url == "/connecttest.txt")
  {
    request->send(404);
  }
  else if (url == "/index_original.html")
  {
    request->send(request->beginResponse_P(200, "text/html", INDEX_ORIGINAL_HTML));
  }
  // ============================================================
  // API routes for the modern UI
  // ============================================================
  else if (url == "/api/status")
  {
    AsyncJsonResponse *response = new AsyncJsonResponse();
    JsonObject root = response->getRoot();

    root["status"] = Attacks::Ducky.getPayloadRunningStatus();
    root["uptime"] = prettyPrintUptime();
    root["usbMode"] = Devices::USB::Core.getCurrentUSBMode();
    root["errors"] = Attacks::Ducky.getTotalErrors();
    root["led_state"] = ledState;

    if (preferences != nullptr) {
      root["wifi_ssid"] = preferences->getString("wifi-ap", "iPhone14");
    } else {
      root["wifi_ssid"] = "iPhone14";
    }
    root["agent"] = "Not connected";
    root["machine"] = root["wifi_ssid"];

    root["sd_pct"] = Devices::Storage.usedPercentage();
    root["sd_total"] = Devices::Storage.totalBytes();
    root["sd_used"] = Devices::Storage.usedBytes();

    root["heap_total"] = ESP.getHeapSize();
    root["heap_used"] = ESP.getHeapSize() - ESP.getFreeHeap();

    response->setLength();
    request->send(response);
  }
  else if (url == "/api/led/toggle")
  {
    ledState = !ledState;
    if (ledState) {
      Devices::LED.on();
    } else {
      Devices::LED.off();
    }
    request->send(200, "application/json", "{}");
  }
  else if (url == "/api/emergency_reset")
  {
    emergencyReset();
    request->send(200, "application/json", "{}");
  }
  else if (url == "/api/settings" && preferences != nullptr)
  {
    AsyncJsonResponse *response = new AsyncJsonResponse();
    JsonArray arr = response->getRoot().to<JsonArray>();
    enumerateSettingsAsJson(*preferences, arr);
    response->setLength();
    request->send(response);
  }
  else if (url == "/api/payloads")
  {
    AsyncJsonResponse *response = new AsyncJsonResponse();
    JsonArray arr = response->getRoot().to<JsonArray>();
    for (const auto &filename : Devices::Storage.listFiles()) {
      arr.add(filename);
    }
    response->setLength();
    request->send(response);
  }
  else if (url == "/api/payload/run" && request->hasParam("file"))
  {
    const String filename = request->getParam("file")->value();
    Debug::Log.info("WEB", std::string("API run payload: ") + filename.c_str());
    Attacks::Ducky.setPayload(filename.c_str());
    request->send(200, "application/json", "{}");
  }
  else if (url == "/api/payload/delete" && request->hasParam("file"))
  {
    const String filename = request->getParam("file")->value();
    Debug::Log.info("WEB", std::string("API delete payload: ") + filename.c_str());
    Devices::Storage.deleteFile(filename.c_str());
    request->send(200, "application/json", "{}");
  }
  else if (url == "/api/payload/upload" || url == "/upload")
  {
    request->send(200);
  }
  else if (url == "/list")
  {
    String html = "<div class=\"dir\">/</div>";
    for (const auto &filename : Devices::Storage.listFiles()) {
      html += "<div class=\"file\">" + String(filename.c_str()) + "</div>";
    }
    request->send(200, "text/html", html);
  }
  else if (url == "/logs")
  {
    String logText;
    for (const auto &logEntry : Debug::Log.getLogs()) {
      logText += String(logEntry.c_str()) + "\n";
    }
    request->send(200, "text/plain", logText);
  }
  else if (url == "/version")
  {
    request->send(200, "text/plain", GIT_COMMIT_HASH);
  }
  else if (url == "/audio/save")
  {
    request->send(200, "text/plain", "Audio is streamed via WebSocket, not saved as file. Use /audio websocket.");
  }
  else if (url == "/audio/clear")
  {
    request->send(200);
  }
  else if (url == "/data.json")
  {
    AsyncJsonResponse *response = new AsyncJsonResponse();
    JsonObject root = response->getRoot();

    root["sdCardPercentFull"] = Devices::Storage.usedPercentage();
    root["sd_total"] = Devices::Storage.totalBytes();
    root["sd_used"] = Devices::Storage.usedBytes();
    root["uptime"] = prettyPrintUptime();
    root["status"] = Attacks::Ducky.getPayloadRunningStatus();
    root["errorCount"] = Attacks::Ducky.getTotalErrors();
    root["USBmode"] = Devices::USB::Core.getCurrentUSBMode();
    root["freeHeap"] = ESP.getFreeHeap();
    root["heapSize"] = ESP.getHeapSize();
    root["agentConnected"] = Attacks::Agent.isAgentConnected();
    root["machineName"] = Attacks::Agent.machineName();
    root["version"] = GIT_COMMIT_HASH;

    float heapUsed = (float)(ESP.getHeapSize() - ESP.getFreeHeap());
    float totalHeap = (float)ESP.getHeapSize();

    root["heapUsagePc"] = (int)((heapUsed / totalHeap) * 100);
    root["numCores"] = ESP.getChipCores();
    root["chipModel"] = ESP.getChipModel();

    auto fileListing = root["fileListing"].to<JsonArray>();
    for (const auto &filename : Devices::Storage.listFiles())
    {
      fileListing.add(filename);
    }

    auto logMessages = root["logMessages"].to<JsonArray>();
    for (const auto &logEntry : Debug::Log.getLogs())
    {
      logMessages.add(logEntry);
    }

    if (preferences != nullptr)
    {
      auto settingsCategories = root["settingCategories"].to<JsonArray>();
      enumerateSettingsAsJson(*preferences, settingsCategories);
    }

    auto capabilities = root["capabilities"].to<JsonArray>();
#ifndef NO_SD
    capabilities.add("SD");
#endif
#ifndef NO_WIFI
    capabilities.add("WIFI");
#endif
#ifndef NO_TFT
    capabilities.add("TFT");
#endif
#ifndef NO_BUTTON
    capabilities.add("BUTTON");
#endif
#ifndef NO_LED
    capabilities.add("LED");
#endif
#ifndef NO_MIC
    capabilities.add("MIC");
#endif
#ifndef NO_ESP_MARAUDER
    capabilities.add("MARAUDER");
#endif

    response->setLength();
    request->send(response);
  }
  else if (url == "/clearlogs")
  {
    Debug::Log.getLogs().clear();
    request->redirect("/index.html"); // redirect to our main page
  }
  else if (url == "/generate_204")
  {
    request->redirect("/"); // redirect to our main page
  }
  else if (url == "/runfile" && request->hasParam("filename"))
  {
    const String filename = request->getParam("filename")->value();
    Debug::Log.info(LOG_WEB, std::string("Executing file from webUI - ") + filename.c_str());

    Attacks::Ducky.setPayload(filename.c_str());
    request->redirect("/index.html"); // redirect to our main page
  }
  else if (url == "/rawinput" && request->hasParam("rawCommand"))
  {
    const String cmdline = request->getParam("rawCommand")->value();
    Debug::Log.info(LOG_WEB, std::string("Running cmdline ") + cmdline.c_str());

    Attacks::Ducky.setPayloadCmdLine(cmdline.c_str());
    request->redirect("/index.html"); // redirect to our main page
  }
  else if (url == "/runagentcmd" && request->hasParam("rawCommand"))
  {
    const String cmdline = request->getParam("rawCommand")->value();
    Debug::Log.info(LOG_WEB, std::string("Running cmd with agent ") + cmdline.c_str());

    Attacks::Ducky.setPayloadCmdLine(std::string("AGENT_RUN ") + cmdline.c_str());
    request->redirect("/index.html"); // redirect to our main page
  }
  else if (url == "/showimage" && request->hasParam("filename"))
  {
    const String filename = request->getParam("filename")->value();
    Debug::Log.info(LOG_WEB, "Show image");
    Debug::Log.info(LOG_WEB, filename.c_str());

    Devices::TFT.displayPng(Devices::Storage, filename.c_str());

    request->redirect("/index.html"); // redirect to our main page
  }
  else if (url == "/marauder" && request->hasParam("marauderCmd"))
  {
    const String cmd = request->getParam("marauderCmd")->value();
    Debug::Log.info(LOG_WEB, std::string("Run Marauder command ") + std::string(cmd.c_str()));
    Attacks::Marauder.run(cmd.c_str());

    request->redirect("/index.html"); // redirect to our main page
  }
  else if (url == "/mic" && request->hasParam("enabled"))
  {
    const String cmd = request->getParam("enabled")->value();
    if (cmd == "true")
    {
      Debug::Log.info(LOG_WEB, "Starting Mic capture");
      Devices::Mic.startCapture();
    }
    else
    {
      Debug::Log.info(LOG_WEB, "Stopping Mic capture");
      Devices::Mic.stopCapture();
    }
    request->send(200);
  }
  else if (url == "/download" && request->hasParam("filename"))
  {
    String filename = request->getParam("filename")->value();
    if (!filename.startsWith("/")) filename = "/" + filename;
    Debug::Log.info(LOG_WEB, std::string("In download, filename: ")+filename.c_str());
    auto file = Devices::Storage.openFile(filename.c_str(), "r");

    if (file.available())
    {
      Debug::Log.info(LOG_WEB, std::string("Sending file: ") + filename.c_str());
      AsyncWebServerResponse *response = request->beginResponse(file, filename, "application/octet-stream", true);
      request->send(response);
      // file.close(); // TODO in order for download to work the file can't be closed
      // i've had a look at the code and can't see it closed by beginResponse etc
      // we could be leaking file handles
    }
    else
    {
      Debug::Log.info(LOG_WEB, std::string("File not found: ") + filename.c_str());
      request->send(404);
    }
  }
  else if (url == "/open" && request->hasParam("filename"))
  {
    String filename = request->getParam("filename")->value();
    if (!filename.startsWith("/")) filename = "/" + filename;
    Debug::Log.info(LOG_WEB, std::string("Opening file: ") + filename.c_str());
    auto file = Devices::Storage.openFile(filename.c_str(), "r");

    if (file.available())
    {
      const char *mime = GetMimeType(filename.c_str());
      if (mime == nullptr) mime = "application/octet-stream";
      AsyncWebServerResponse *response = request->beginResponse(file, filename, mime, false);
      request->send(response);
    }
    else
    {
      Debug::Log.info(LOG_WEB, std::string("File not found: ") + filename.c_str());
      request->send(404);
    }
  }
  else if (url == "/delete" && request->hasParam("filename"))
  {
    const String filename = request->getParam("filename")->value();

    Debug::Log.info(LOG_WEB, std::string("Deleting file: ") + std::string(filename.c_str()));

    Devices::Storage.deleteFile(filename.c_str());

    request->redirect("/index.html"); // redirect to our main page
  }
  else if (url.startsWith("/set") && preferences != nullptr && request->hasParam("name"))
  {
    const String settingName = request->getParam("name")->value();

    if (request->hasParam("value"))
    {
      const String settingValue = request->getParam("value")->value();

      Debug::Log.info(LOG_WEB, std::string("Set setting") + settingName.c_str() + " to " + settingValue.c_str());

      if (setSettingValue(*preferences, settingName.c_str(), settingValue.c_str()))
      {
        Debug::Log.info(LOG_WEB, "New setting has been set");
      }
      else
      {
        Debug::Log.info(LOG_WEB, "Setting could not be set");
      }
    }
    else
    {
      Debug::Log.info(LOG_WEB, "Removing setting");
      preferences->remove(settingName.c_str());
    }
    request->redirect("/index.html"); // redirect to our main page
  }
  else if (url.startsWith("/uploadFile"))
  {
    // ignore, handled else where
    request->send(404);
  }
  else
  {
    std::pair<const uint8_t *, size_t> data;
    const char *unknown = "application/octet-stream";

    if (url.isEmpty() || url.length() == 1)
    {
      data = getStaticHtml("/index.html");
    }
    else
    {
      data = getStaticHtml(url);
    }

    if (data.first != nullptr)
    {
      const char *mime = GetMimeType(url.isEmpty() || url.length() == 1 ? "/index.html" : url.c_str());

      AsyncWebServerResponse *response = request->beginResponse(200, mime != nullptr ? mime : unknown, data.first, data.second);
      response->addHeader("Content-Encoding", "gzip");
      response->addHeader("Cache-Control", "max-age=6000");
      request->send(response);
    }
    else
    {
      // Serial.println("sending 404");
      Debug::Log.error(LOG_WEB, std::string("Unknown URL: ") + url.c_str());
      request->send(404);
    }
  }
}

void handleUpload(AsyncWebServerRequest *request, String filename, size_t index, uint8_t *data, size_t len, bool final)
{
  const auto &url = request->url();

  if (url.startsWith("/uploadFile") || url == "/upload" || url.startsWith("/api/payload/upload"))
  {
    if (!index) {
    
      // We need to ensure that if the autorun.ds payload is currently running then we stop it
      // Otherwise we risk changing the file content while the script is executing
      if (filename == "autorun.ds")
      {
        Attacks::Ducky.setPayload("");
      }

      request->_tempFile = Devices::Storage.openFile(std::string("/")+filename.c_str(), "w");
      if (strlen(request->_tempFile.name()) == 0)
      {
        Debug::Log.error(LOG_WEB, std::string("File not available, no write permission"));
        request->send(500);
        return;
      }
    }

    if (len != 0)
    {
      if (request->_tempFile.write(data, len) != len)
      {
        Debug::Log.error(LOG_WEB, std::string("Error writing data to file"));
        request->send(500);
        return;
      }
      else
      {
        Debug::Log.info(LOG_WEB, std::string("Wrote data to file"));
      }
    }
    else if (!final) // len == 0
    {
      Debug::Log.error(LOG_WEB, std::string("File data to write is 0 bytes"));
      request->send(500);
      return;
    }

    if (final)
    {
      // close file
      Debug::Log.info(LOG_WEB, std::string("File uploaded ")+filename.c_str());
      request->_tempFile.close();
      Devices::Storage.refreshCache();
    }
    request->send(200);
  }
}

WebSite::WebSite()
{
}

void WebSite::begin(Preferences &prefs)
{
  if (Devices::WiFi.getState() == false)
  {
    return;
  }

  preferences = &prefs;

  controlInterfaceWebServer.onFileUpload(handleUpload);
  controlInterfaceWebServer.onNotFound(webRequestHandler);
  
  ws.onEvent(onWsEvent);
  audio.onEvent(onWsAudioEvent);

  controlInterfaceWebServer.addHandler(&ws);
  controlInterfaceWebServer.addHandler(&audio);
  controlInterfaceWebServer.begin();

  Devices::USB::CDC.setCallback(HostCommand::WSDATARECV, [](uint8_t *buffer, const size_t size) -> void
  { 
    ws.binaryAll(buffer, size);
  });

  Devices::Mic.setCallback([](uint8_t *buffer, const size_t size) -> bool
  {
    if (ESP.getFreeHeap() < (size * 2)) // double what we need
    {
      Debug::Log.info(LOG_WEB, "Could not write data to /audio, not enough free mem");
      return true;
    }

    audio.binaryAll(buffer, size);
    return true;
  });

  ElegantOTA.begin(&controlInterfaceWebServer); // Start ElegantOTA
}

void WebSite::loop(Preferences &prefs)
{
  if (preferences == nullptr)
  {
    return;
  }

  ws.cleanupClients();
  audio.cleanupClients();
  ElegantOTA.loop();
}

void WebSite::end()
{
  if (preferences == nullptr)
  {
    return;
  }

  // Not removing handlers etc is likely to leak memory
  // However we seem to get crashes if we do :(
  // TODO for later
}

#endif

