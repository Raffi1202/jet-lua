🇬🇧 English · [🇩🇪 Deutsch](../de/Alarme.md)

# Alarms

> **Pre-release:** version 0.4.0 is tested in the Ethos simulator; the transmitter test on the X18RS follows. Use at your own risk.

## 6. Warnings and alarms

Every watched value has two limits: warning (orange) and alarm (red, frame, tone and announcement). You set both in the menu group **Limits (0 = off)**; 0 switches a limit off. Defaults:

| Value | Warning (orange) | Alarm (red, tone, announcement) |
|---|---|---|
| EGT | above 720 °C | above 750 °C, «Warning! E G T high» and the number |
| Fuel | below 30 % | below 20 %, «Warning! Fuel reserve» without number |
| ECU cell (limit per cell × ECU battery cells) | below 3.70 V (with 2 cells 7.4 V) | below 3.50 V (with 2 cells 7.0 V), «Warning! E C U battery low» and the voltage |
| RX battery | off by default (0); e.g. 7.40 V for 2S LiPo | off by default (0); e.g. 7.00 V for 2S LiPo, «Warning! Receiver battery low» and the number |
| RSSI (for dBm values: limit = dBm + 120, e.g. 40 = -80 dBm) | below 45 dB | below 40 dB, «Warning! Signal low» and the number |
| Altitude | above 110 m | above 120 m, «Altitude» and the number |
| Speed | off | off; when set: «Speed» and the number |

The ECU cell limits are for LiPo. If you choose another ECU battery type and the limits are still at the default, Jet changes them to suit: LiFe 3.10/3.00 V, Li-Ion 3.40/3.20 V, NiMH 1.15/1.10 V.

![Warning](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2005%20Warnung.png)

Warning: header and value orange

![Alarm](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2006%20Alarm.png)

Alarm: red header, red frame, tone and announcement

A warning or alarm starts when the value has been beyond the limit for 1 second and ends when it has been fine again for 3 seconds. An alarm beeps («Tone on alarm»), announces the value («Announce alarms») and repeats this every 10 seconds («Repeat alarm every») as long as it lasts. A warning is announced only if «Announce warnings too» is on. There are always at least 3 seconds between two announcements. Without telemetry there are no warnings.

### Alarm also with turbine off

By default all warnings and alarms also come when «Turbine off at» (default SF↑) is in the off position. In the menu group **Alarm also with turbine off** you can change this per value (EGT, fuel, ECU battery, receiver battery, RSSI, altitude, speed); **all** at the top switches all ticks at once. Without the tick this value stays silent while the switch is off: no tone, no announcement, no vibration, the top bar stays calm. The value itself still turns orange or red. If you switch back on and the value is still beyond its limit, the alarm comes at once. ECU error codes and shutdown reasons (e.g. «Flameout») always come, they cannot be deselected.

### Contradicting sources

If Jet reads a value directly from the ECU telemetry (JetCat, Xicoy, SportECU) and the sensor set for this value in the menu shows something clearly different at the same time, Jet shows a warning: orange top bar and at the bottom a hint such as «EGT: ECU data and sensor disagree» (again every 30 seconds). This applies to EGT (more than 50 °C or 15 %), RPM (more than 5000 rpm or 15 %), ECU battery (more than 0.5 V) and fuel (more than 10 %), once the difference lasts 3 seconds. Jet keeps showing the ECU value. Then check the assignment (menu › Check assignment), for example if a separate temperature sensor is assigned as EGT. No tone, no announcement.

### Fuel in steps

When the fuel drops below 75, 50, 30, 10 and 5 %, the radio says «Fuel» and the number in percent, once each. At 10 and 5 % it also vibrates if «Vibration on alarm» is on. If you refuel and the value rises 5 % above a step, that step counts again. Switch off with «Fuel in steps».

### Shutdown

If the ECU reports an error code when the turbine stops (e.g. «Low temp. Off»), or a running turbine stops while «Turbine off at» (default SF↑) is not on and the ECU itself does not report «off», this counts as a shutdown. An error code always counts, even if SF is already «off»: red header, pill SHUTDOWN, STATUS red with the ECU's text. The radio says «Turbine off» and about a second later the reason: «Flameout», «Out of fuel», «Battery low», «Overtemperature», «Failsafe» or otherwise «Fault». For turbines 2 to 4 it says «Turbine two off» and so on. Vibration follows the setting; a tone comes here only if there is no voice file. This announcement always comes, even if «Announce alarms» is off. Without a status sensor or without a known status text, a flameout is when the RPM stays below «Idle from» for 2 seconds. The display stays red until the turbine starts again; SF does not clear it. If you flip SF only after the flameout, it still counts as a shutdown. Limit alarms (EGT, fuel, batteries, signal) also come with SF «off», unless you remove the tick «Alarm also with turbine off» for a value (see above).

![Shutdown](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2020%20Abschaltung%20Flammabriss.png)

## What always comes

- **ECU error codes and shutdown reasons always come**, also with «Turbine off at» (SF) off and also with every tick «Alarm also with turbine off» removed: red header, pill SHUTDOWN, STATUS red with the ECU's text, «Turbine off» and the reason «Flameout», «Out of fuel», «Battery low», «Overtemperature», «Failsafe» or otherwise «Fault» (turbines 2 to 4: «Turbine two off» and so on). Without a status sensor: RPM below «Idle from» for 2 seconds counts as a flameout.
- This announcement also comes when «Announce alarms» is off. An alarm without announcement always gives a tone.
- The status of the ECU («immerAlarm» in Lua-Studio) never follows «Alarm also with turbine off».
- **Completely silent only with «off»:** in the menu a limit is off only at 0; a Lua-Studio file can switch a limit off only with `aus = true`. An entry without a limit stage (e.g. only `beiMotorAus = false`, or warning and alarm both `false`) gives the factory limit.
- The warning for contradicting sources has no tone and cannot be deselected.

---
[← Home](../Home.md) | [Previous](Display.md) | [Next →](Lua-Studio.md)
