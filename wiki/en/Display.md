🇬🇧 English · [🇩🇪 Deutsch](../de/Anzeige.md)

# Display

## 5. The display

![Display](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2004%20Normal.png)

The picture shows the German display. The English titles are given in brackets.

| No. | Field (place) | What it shows |
|---|---|---|
| 1 | Model name (header left) | Name of the model in the radio. The header turns orange on a warning and red on an alarm or a shutdown. |
| 2 | Run time (header centre) | Duration of the current run in minutes:seconds. It runs while the turbine turns. |
| 3 | Turbine pill (header right) | State of the turbine: OFF grey, START blue, RUNNING green, SHUTDOWN red. Your own switches appear to the left as a green pill while they are on (e.g. «STABI», «FAHRWERK»). |
| 4 | Bars, battery icon (far right) | Signal strength (RSSI) in four steps and the radio battery. |
| 5 | DREHZAHL (RPM), gauge 1 | RPM. The arc reaches the highest set or actual RPM in this run (starts again at each start) (or «RPM gauge up to»). Below in yellow SET (JetCat only) or MAX. |
| 6 | EGT, gauge 2 | Exhaust gas temperature in °C, arc 350–800 °C. Below MAX = highest value in this run (starts again at each start). |
| 7 | KRAFTSTOFF (FUEL), gauge 3 | Remaining fuel in %, below it remaining ml. The % comes from the ECU; without it Jet calculates from ml and tank size. |
| 8 | ECU-AKKU (ECU BATT), gauge 4 | ECU battery voltage. The arc goes from empty to full for the ECU battery type and cell count. Below MIN. |
| 9 | STATUS (large, left) | State of the ECU as text, colour as the pill: green running, blue start, grey off/ready/cooling, red fault. Below «since 4:13» while it runs. Unknown code: «Code n». Tap it to see the last status changes (chapter 7). |
| 10 | «6 Läufe» («6 runs», bottom left) | Number of counted runs of this model. Tap it to open the run list. |
| 11 | FLUSS (FLOW) ml/min, field 1 | Fuel flow in ml/min, below it fuel used in this run in ml. |
| 12 | PUMPE (PUMP), field 2 | Pump voltage in V, below MAX. With Kingtech at VSpeak as power «PW». |
| 13 | SCHUB (THRUST), field 3 | Thrust in N (JetCat only), below MAX. |
| 14 | HÖHE (ALTITUDE), field 4 | Altitude in m, below MAX. |
| 15 | SPEED, field 5 | Speed in km/h, below MAX. |
| 16 | EMPFANG (SIGNAL), field 6 | RSSI in dB, below the receiver battery («RX 7.9V») and MIN. If your receiver sends RSSI in dBm (negative), it shows «dBm». |

A short grey dash instead of a number means: this value is not arriving right now or has no sensor. You can change what each gauge and field shows in the menu (chapter 8, group Fields).

**Fuel:** If the ECU sends only ml, Jet calculates the % from the **Tank size**. Whether the ml are the remaining fuel or the used fuel is set by **Fuel ml is**; default «by manufacturer». If the tank size is 0 and there is no %, the gauge shows «Set tank size» in orange.

**Several turbines:** With 2 to 4 turbines, EGT, FUEL and ECU BATT show the most critical value (highest EGT, least fuel, lowest battery); the title then carries e.g. «T2». Page 2 shows all turbines side by side (chapter 7).

### Compact view

If you choose the layout with top and bottom bars (chapter 3), Jet notices this and shows a compact view: a narrow bar at the top with run time, pills and signal (model name and radio battery are in the Ethos header), below it the four gauges and eight fields: STATUS, field 1 to 6 and RUNS. Tapping RUNS opens the run list. Everything else works as in full screen.

![Compact view](../../docs/bilder-simulator/Jet%20-%20Sim%20784x316%2033%20Kompakt%20Normal.png)

Compact view on X20 and X18RS (784 × 316). On X14 and X18 / Twin X Lite it is smaller.

## 7. Operation

### Detecting runs

A run starts as soon as the turbine turns: the ECU reports a start or running status, or, without a status sensor (or without a known status text), the RPM is above 1000. The run time at the top runs. When the turbine reaches «running» (green; without a status sensor: RPM from «Idle from», default 10000), the radio says «Turbine running». When you switch it off with «Turbine off at», it says «Turbine off» (both only if «Turbine running/off» is on).

When the turbine has stood still for 5 seconds (RPM below 1000, no start or running status), the run ends and goes into the run list without a question. A run counts only from 30 seconds («Run counts from»); shorter runs, e.g. a failed start, are dropped.

![Start](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2021%20Start.png)

Start: pill START, status blue

![Status list](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2026%20Statusliste.png)

Tap STATUS: last status changes

### Last status changes

Tap the field STATUS. «LAST STATUS CHANGES» opens with the last 5 changes, each with the run time, newest at the top. **CLOSE** or one turn of the rotary encoder closes the window.

### Turbines (page 2)

Only with 2 to 4 turbines: swipe left. One column per turbine with RPM, EGT, fuel, ECU battery and status. Values beyond the warning are orange, beyond the alarm red.

![Turbines](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2023%20Turbinen%202.png)

### Run list

Swipe left (twice with several turbines) or tap «n runs». The runs are on the right, newest at the top, the current one blue with «running». The column «End» shows «SF off», «Shutdown» (red) or «-». Tap a run: on the left you see Run time, Fuel used, Max. EGT, Max. RPM, Fuel at end, Max. altitude, Max. speed, Lowest ECU batt, End (after a shutdown with the ECU's text) and Turbines.

![Run list](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2025%20Flugliste.png)

- Delete one run: tap the run, **DELETE RUN n**, then **YES, DELETE**. «Run n deleted» appears at the bottom. Later numbers move up.

- Delete all runs: **CLEAR LIST**, then **YES, DELETE**. «Run list cleared» appears at the bottom. The counter starts again at 1.

- **CANCEL** leaves everything as it is.

- Back to the display: **< BACK** or swipe right.

The list keeps the last 20 runs and stays when you switch off. A run that was still open when you switched off goes into the list the next time you switch on.

### End a run by hand

In the menu at the top, tap **End** next to **End run**. «End run?» appears with «It goes into the run list.». **YES, END** ends it and «Run ended» appears at the bottom. A new run starts only after the turbine has stood still once.

### Announcement on a switch

When you switch **SG↓** on («Announce at»), the radio says «Fuel» with %, «Run time» with minutes and, if switched on, «Altitude» with metres. You choose what is announced in the group Announcements.

### Radios without touch (X14, X10, X12)

The rotary encoder pages from the display to the Turbines page and to the run list. On the run list it selects runs; turning back before the first run returns to the display. At the top of the menu there are **End run**, **Delete run** (first choose the number at «Run no. to delete») and **Delete whole list**, each with a confirmation.

---
[← Home](../Home.md) | [Previous](Setup.md) | [Next →](Alarms.md)
