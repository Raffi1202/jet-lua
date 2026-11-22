🇬🇧 English · [🇩🇪 Deutsch](../de/Installation.md)

# Installation

## 1. What you need

- A FrSky radio with Ethos 26.2 and a colour display (list at the end).

- A turbine with telemetry to the radio, through one of these: JetCat with its own telemetry adapter (turbine 1 to 4), Xicoy with TeleX adapter, SportECU (e.g. ProJET Hornet III), VSpeak ECU converter (for Kingtech, Swiwin, PBS, evoJet, Hornet/Behotec, Jakadofsky, JetCat). Other turbines work with the setting «manual».

- The model's sensors already discovered (Model › Telemetry › Discover sensors).

- Your tank size in ml, the type and cell count of your ECU battery.

- A computer with FrSky Suite and a USB cable.

- The file `Jet-0.5.2.zip`. It is inside `Jet-0.5.2-share.zip`. Unzip only the outer ZIP, not the inner one.

## 2. Install

- Switch the radio on and connect it to the computer with the USB cable.

- The radio shows a choice. Select **Ethos Suite**.

- Open **FrSky Suite** on the computer. The radio appears at the top.

- Click **Lua library**, then **Install from local ZIP**.

- Select `Jet-0.5.2.zip`. The Suite copies everything to the right place.

- Unplug the cable and restart the radio.

Without the Suite: connect the radio as «USB storage» and copy the folder `jet` from the ZIP into `scripts`. If your radio loads scripts from the SD card (System › General › Storage location), it belongs in `scripts` on the SD card. Overwrite an existing folder, do not delete it.

## 10. Update and remove

**Update:** Install the new ZIP exactly as in chapter 2. Your settings, sensors, runs and counters stay.

**Remove:** First take the widget off the screen (Model › Screens), then uninstall it in FrSky Suite under Lua library. The Lua-Studio files are in `scripts/studio` and can be deleted there by hand.

## 11. Which radios

| Display | Radios | Status |
|---|---|---|
| 800 × 480, touch | X20, X20S, X20HD, X20 Pro, X20R, X20RS, X18R, X18RS | in the simulator and on a real X18RS (simulated telemetry) |
| 640 × 360, no touch | Twin X14, X14S | simulated |
| 480 × 320, touch | X18, X18S, X18SE, Twin X Lite, Twin X Lite S | simulated |
| 480 × 272, no touch | X10, X10S, X10 Express, X12S with Ethos | simulated |

![480x320](../../docs/bilder-simulator/Jet%20-%20Sim%20480x320%2006%20Alarm.png)

480 × 320 (X18): shortened titles

![English](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2012%20Englisch.png)

English: language in the menu or as the radio

Jet version 0.5.2 · 21 Nov 2026

---
[← Home](../Home.md) | [Next →](Setup.md)
