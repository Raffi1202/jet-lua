🇬🇧 English · [🇩🇪 Deutsch](../de/Fehlerbehebung.md)

# Troubleshooting

## 9. Troubleshooting

| What you see | Cause | What to do |
|---|---|---|
| Dashes everywhere, run time 0:00 | No telemetry | Switch on receiver and ECU. Check that the receiver is bound. |
| RPM, EGT, ECU battery or status show values of another device (e.g. RPM 8000 instead of 98400) | Another device sends the same ID (AppID) and was assigned | Menu top › **Reassign turbine values** › Reassign › «YES, REASSIGN». Then check «P1B» on these lines in «Check assignment». |
| Menu: Detected «nothing yet» | No turbine sensors assigned | Chapter 4: select the manufacturer, search. With JetCat, Xicoy and SportECU Jet detects the manufacturer as soon as telemetry from the turbine arrives. |
| STATUS shows «Code 27» or similar | Manufacturer or ECU at VSpeak not selected, or a code Jet does not know | Check Menu › Manufacturer. If it stays «Code n»: note the code and what the ECU shows and report it. |
| Orange «Set tank size» below FUEL | The ECU sends only ml, tank size is 0 | Menu › Turbine › set Tank size. |
| Fuel % rises instead of falling | «Fuel ml is» does not match the ECU | Menu › Manufacturer › change «Fuel ml is». |
| RPM 10 or 100 times too small | The ECU sends the RPM divided | Menu › Manufacturer › «RPM times» to 10 or 100. |
| Red SHUTDOWN although you stopped it yourself | «Turbine off at» is not your switch | Menu › Switches › select the position at «Turbine off at». |
| Runs are not counted | Run shorter than «Run counts from», or no RPM without a status sensor | Check the RPM and Status sensors (chapter 4). |
| No Turbines page although you have 2 | No telemetry from turbine 2 | Check the slave address of the second ECU (2) and its telemetry adapter. |
| Only a beep and the number on alarm | The voice files are missing on the radio (folder `audio`) | Repeat chapter 2. |
| At the bottom «Studio file broken - default», «too new» or «n errors», then «!» at the top right | The Lua-Studio file is broken, made for a newer Jet version or contains invalid entries | Transfer it again from Lua-Studio or update Jet. The log says what exactly is wrong (one line per error). |
| Red text at the bottom left | Script error. The radio keeps working. | Take a photo of the text and report it: on GitHub under Issues, template «Fehler / Bug» (see TESTLEITFADEN.md in the repository). |
| The widget is missing from the list | Not installed or radio not restarted | Repeat chapter 2, restart the radio. |

## Lua memory ("too much RAM")

All Lua scripts on the radio share one Lua memory (about 2048 KB on the X18RS). Jet needs about 144 KB, with a Studio file about 100–115 KB more (simulator). From 0.4.0 Jet frees its memory down to about 5 KB when you switch to a model without Jet (measured in the simulator). If the radio reports «too much RAM» or too little Lua memory: **switch the radio off and on again**, then use fewer different Lua widgets at the same time.

---
[← Home](../Home.md) | [Previous](FAQ.md) | [Next →](Changelog.md)
