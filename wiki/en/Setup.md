🇬🇧 English · [🇩🇪 Deutsch](../de/Einrichten.md)

# Setup

## 3. Set up the screen

- Tap the **Screens** icon at the bottom (two rectangles).

- Tap **+** at the top right.

- Swipe down to the layout **Full screen** (one large field) and tap it. To keep the Ethos top and bottom bars, choose the layout with **one field and the bars** instead (bottom centre of the layout grid); Jet then shows the compact view (chapter 5).

- Tap the empty field, then **Widget**.

- Select **Jet** in the list. The display appears at once.

![Widget list](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2001%20Widget-Liste.png)

You reach the widget menu any time through Model › Screens › select the screen › tap the widget.

## 4. Assign sensors

- Switch on receiver and ECU so that telemetry runs. The first time, Jet looks for the sensors by itself; a short blue note «… sensors assigned automatically» appears at the bottom.

- Open the menu. At the top, **Detected** shows the manufacturer Jet recognised from the sensors, e.g. «JetCat». If it says «nothing yet», open the group **Manufacturer** and select it under **Manufacturer** yourself.

- VSpeak converter only: in the group **Manufacturer**, select the turbine behind it under **ECU at VSpeak** (Kingtech, Swiwin, PBS, evoJet, Hornet/Behotec, Jakadofsky, JetCat). Until then Detected shows «VSpeak - Select manufacturer» and the status only as «Code n».

- JetCat, Xicoy and SportECU send part of their values with IDs for which Ethos creates no sensors (JetCat 0x5000–0x53FF, SportECU fuel 0x0A10; for Xicoy 0x4400–0x4406 this is not yet checked on a radio). Jet only accepts values from the turbine's Physical ID. Jet reads these values from the telemetry itself; you do not need to set anything. Their lines in the group **Sensors** (e.g. Status, Set RPM, Pump) may stay empty.

- If other devices with the same IDs are connected to the receiver (e.g. an RPM sensor), tap **Reassign** next to **Reassign turbine values** at the top, then **YES, REASSIGN**. Jet then takes the turbine's sensor (Physical ID 0x1B) for every turbine value, if there is one; signal, altitude and speed stay unless their sensor was deleted. If you used «Delete all sensors» in the model and discovered again, also tap **Reassign** once: Jet then takes all values from the new sensors.

- Open the group **Sensors** and check every line. Select anything empty or wrong by hand. An empty line is allowed; the field then shows a dash.

- With **Find sensors (empty only)** › **Search** Jet later fills only the empty lines; your own choice stays.

- The group **Check assignment** shows the chosen sensor of each line with Physical ID and AppID (e.g. «EngState1  P1B / 5004»). If several identical sensors matched, a line below says «n sensors match, chosen: … - please check».

- Open the group **Turbine** and set **Tank size**, **ECU battery type** and **ECU battery cells**.

![Top of the menu](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2002%20Menue.png)

### How Jet recognises the manufacturer

Jet looks at the AppID of the assigned sensors (an identification number you see under «Check assignment»). A manufacturer selected by hand always comes before the detected one.

| Manufacturer / path | Detected by | Jet reads itself | Fuel |
|---|---|---|---|
| JetCat with own adapter | telemetry with ID 0x5000–0x53FF, otherwise 0x0210 (ECU battery) together with 0x0500 (RPM) | 0x5000–0x53FF: status, set RPM, pump, remaining ml, flow, thrust, altitude, speed, shaft, current; turbines 2–4: RPM, EGT, fuel, ECU battery, status | % from the ECU, remaining ml |
| Xicoy with TeleX | telemetry with ID 0x4400–0x4406 | all 7 values (EGT, RPM, throttle, battery, pump, fuel %, status) | % from the ECU |
| SportECU | telemetry with ID 0x0A10, otherwise 0x0410 together with 0x0900 | fuel ml (0x0A10) | remaining ml, % from the tank size |
| VSpeak converter | 0x0410 together with 0x0600 | none, Ethos finds the sensors itself | ml, remaining or used depending on the ECU |
| manual | only selectable in the menu | none | remaining ml, % from the tank size |

| Line in the menu | Which sensor belongs there |
|---|---|
| RPM, Set RPM | Actual and set RPM of the turbine. Set RPM exists only with JetCat (EngSetRpm1). |
| EGT | Exhaust gas temperature, e.g. «EGTC» (Xicoy) or «Tmp1» (VSpeak). |
| ECU battery | Voltage of the turbine controller's battery, e.g. «VBAT» (Xicoy) or «A3» (VSpeak, SportECU). |
| Pump | Pump voltage, e.g. «EngPumpV1», «PUMP», «A4». |
| Status | Status code of the ECU, e.g. «EngState1», «STAT» or «Tmp2». |
| Fuel ml, Fuel % | Fuel in ml and in %. Leave empty what the ECU does not send. |
| Fuel flow, Thrust, Shaft RPM, ECU current | JetCat only (EngFuelFlow1, EngThrust1, EngShaftRpm1, EngCurrent1). |
| Altitude, Speed | From the ECU (JetCat), the vario or GPS. |
| Throttle % (sensor) | Throttle position from the ECU, e.g. «THRT» (Xicoy). Without a sensor Jet uses the throttle channel (group Switches). |
| RSSI, Receiver battery | Signal strength «RSSI» and receiver battery voltage, e.g. «RxBatt». |

Turbines 2 to 4 (JetCat) need no lines in the menu: Jet reads their values from the telemetry itself. A value read this way is valid for 5 seconds; if none arrives, the sensor from the menu applies again.

![Xicoy](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2011%20Xicoy%20nur%20Teil.png)

Xicoy: flow and speed missing (dash), one field shows THROTTLE

![Kingtech](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2022%20Kingtech%20VSpeak.png)

Kingtech at VSpeak: pump as power «PW»

## 8. All settings

Open the menu: Model › Screens › select the screen › tap the widget. Every change applies at once and is saved.

| Group | Setting | Default | Range and effect |
|---|---|---|---|
| top | Studio file | none | Shows whether a file from Lua-Studio applies: none, loaded, broken or too new. Button **Reset** (asks first): with a file «Back to Studio settings», without a file «Back to defaults». See «Lua-Studio» below. |
| top | Detected | – | Shows the manufacturer that currently applies, or «nothing yet». |
| Sensors | 17 lines | empty | See chapter 4. The first search runs by itself. |
| Manufacturer | Manufacturer | automatic | automatic, JetCat, Xicoy, SportECU, VSpeak converter, manual. Decides status texts and fuel. |
| Manufacturer | ECU at VSpeak | not selected | Kingtech, Swiwin, PBS, evoJet, Hornet/Behotec, Jakadofsky, JetCat. VSpeak converter only. |
| Manufacturer | Fuel ml is | by manufacturer | remaining or used. Select it yourself for Swiwin at VSpeak. |
| Manufacturer | RPM times | 1 | 1, 10 or 100. For ECUs that send the RPM divided; example: Ethos shows 9840, the ECU 98,400 → 10. |
| Manufacturer | SportECU: Hornet texts | off | On: SportECU status codes as Hornet texts instead of «Code n». |
| Turbine | Tank size | 0 ml | 0 to 50,000 ml in steps of 50. For fuel % from ml. 0 = not set. |
| Turbine | ECU battery type | LiPo | LiPo, LiFe, Li-Ion, NiMH. Sets the arc empty–full and the default limits. |
| Turbine | ECU battery cells | 2 S | 1 to 6 cells. |
| Turbine | Idle from | 10000 U/min | 500 to 200,000 RPM. Without a status sensor: from here the turbine counts as «running», 2 s below = flameout. |
| Turbine | Run counts from | 30 s | 0 to 600 s. Shorter runs do not go into the list. |
| Limits (0 = off) | EGT warn above / EGT alarm above | 720 / 750 °C | 0 to 1200 °C, step 5. |
| Limits (0 = off) | Fuel warn below / Fuel alarm below | 30 / 20 % | 0 to 100 %. |
| Limits (0 = off) | ECU cell warn below / ECU cell alarm below | 3.70 / 3.50 V | 0 to 4.50 V per cell, step 0.05. |
| Limits (0 = off) | RX batt warn below / RX batt alarm below | 0 / 0 (off) | 0 to 20.00 V, step 0.10. Off by default because receivers run on 5 to 8.4 V; for 2S LiPo enter e.g. 7.40 / 7.00 V. |
| Limits (0 = off) | RSSI warning below / RSSI alarm below | 45 / 40 dB | 0 to 120 dB. |
| Limits (0 = off) | Altitude warn above / Altitude alarm above | 110 / 120 m | 0 to 5000 m. |
| Limits (0 = off) | Speed warn above / Speed alarm above | 0 / 0 km/h (off) | 0 to 1500 km/h, step 10. |
| Switches | Turbine off at | SF↑ | Switch position in which the turbine is off. Stopping in this position is intended, no alarm, unless the ECU reports an error code. |
| Switches | Announce at | SG↓ | Switch position for the announcement. |
| Switches | Switch 1 / Switch 2 | empty | Your own switches, shown in the header while they are on. |
| Switches | Switch 1 name / Switch 2 name | STABI / FAHRWERK | At most 12 characters: letters, digits, space, dot, hyphen. |
| Switches | Throttle channel | empty | Throttle channel, for the field «Throttle %» when no throttle sensor is assigned. |
| Switches | Reverse throttle | off | For «throttle reverse» (full throttle = stick back): Jet shows 100 % − channel. Only the throttle channel; «Throttle %» from the ECU stays as the ECU reports it. From 0.7.1. |
| Announcements | Announce alarms | on | Off: on alarm only tone and display. |
| Announcements | Announce warnings too | off | On: the orange warning is announced as well. |
| Announcements | Repeat alarm every | 10 s | 3 to 300 s. |
| Announcements | Fuel in steps | on | Announcements at 75, 50, 30, 10 and 5 %. |
| Announcements | «Turbine running/off» | on | Announcement on reaching «running» and on an intended stop. |
| Announcements | Announce: fuel | on | What is said on the announcement switch. |
| Announcements | Announce: run time | on | What is said on the announcement switch. |
| Announcements | Announce: altitude | off | What is said on the announcement switch. |
| Announcements | Tone on alarm | on | Beep before the alarm announcement; on a shutdown only if there is no voice file. If an alarm is not announced (or its voice file is missing), a beep always comes, even with this setting off. An alarm is only silent if its limit is switched off. |
| Announcements | Vibration on alarm | off | The radio vibrates on alarm, shutdown and the fuel steps 10 and 5 %. |
| Fields | Gauge 1 to 4, Field 1 to 6 | as in the picture | Content: empty, RPM, EGT, Fuel %, ECU battery, Status, Fuel flow, Pump, Thrust, Altitude, Speed, Signal, Throttle %, Shaft RPM, ECU current, Run time, Fuel ml, Receiver battery. |
| Fields | RPM gauge up to (0 = auto) | 0 | 0 to 300,000, step 1000. End of the RPM arc; 0 = highest measured RPM. |
| Alarm also with turbine off | all | on | Switches all ticks below on or off at once. Above it the hint «Unticked: silent while turbine off». |
| Alarm also with turbine off | EGT, Fuel, ECU battery, Receiver battery, RSSI, Altitude, Speed | on | Off: warning and alarm of this value stay silent while «Turbine off at» is off. Error codes and shutdown reasons always come. See chapter 6. |
| Display | Sprache / Language | as the radio | Deutsch or English for display, menu and announcements. The menu changes the next time you open it. |

On first start Jet sets «Turbine off at» and «Announce at» to SF↑ and SG↓ if these switches exist. The top of the menu also holds: Find sensors (empty only), Version, Detected, Reassign turbine values (after the question «Reassign turbine values?» it replaces every turbine value whose sensor is not on the turbine ID 0x1B, for example when another device sends the same RPM ID), End run, Run no. to delete, Delete run, Delete whole list.

---
[← Home](../Home.md) | [Previous](Installation.md) | [Next →](Display.md)
