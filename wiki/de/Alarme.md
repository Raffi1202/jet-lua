[🇬🇧 English](../en/Alarms.md) · 🇩🇪 Deutsch

# Alarme

> **Vorabversion:** Version 0.4.0 ist im Ethos-Simulator getestet, der Sendertest an der X18RS folgt. Nutzung auf eigene Verantwortung.

## 6. Warnungen und Alarme

Jeder überwachte Wert hat zwei Grenzen: Warnung (orange) und Alarm (rot, Rahmen, Ton und Ansage). Beide stellst du im Menü in der Gruppe **Grenzwerte (0 = aus)** ein, 0 schaltet eine Grenze aus. Die Werte ab Werk:

| Wert | Warnung (orange) | Alarm (rot, Ton, Ansage) |
|---|---|---|
| EGT | über 720 °C | über 750 °C, «Achtung! Abgastemperatur hoch» und die Zahl |
| Kraftstoff | unter 30 % | unter 20 %, «Achtung! Kraftstoff Reserve» ohne Zahl |
| ECU-Zelle (Grenze je Zelle × ECU-Akku Zellen) | unter 3,70 V (bei 2 Zellen 7,4 V) | unter 3,50 V (bei 2 Zellen 7,0 V), «Achtung! Akku der Turbinensteuerung tief» und die Spannung |
| RX-Akku | ab Werk aus (0); z. B. 7,40 V bei 2S LiPo | ab Werk aus (0); z. B. 7,00 V bei 2S LiPo, «Achtung! Empfängerakku tief» und die Zahl |
| RSSI (bei dBm-Werten: Schwelle = dBm + 120, z. B. 40 = -80 dBm) | unter 45 dB | unter 40 dB, «Achtung! Empfang schwach» und die Zahl |
| Höhe | über 110 m | über 120 m, «Höhe» und die Zahl |
| Speed | aus | aus; gesetzt: «Geschwindigkeit» und die Zahl |

Die ECU-Zellen-Grenzen gelten für LiPo. Wählst du eine andere ECU-Akkuart und stehen die Grenzen noch auf dem Werkwert, stellt Jet sie passend um: LiFe 3,10/3,00 V, Li-Ion 3,40/3,20 V, NiMH 1,15/1,10 V.

![Warnung](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2005%20Warnung.png)

Warnung: Kopf und Wert orange

![Alarm](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2006%20Alarm.png)

Alarm: Kopf rot, roter Rahmen, Ton und Ansage

Eine Warnung oder ein Alarm gilt, wenn der Wert 1 Sekunde lang jenseits der Grenze liegt, und endet, wenn er 3 Sekunden lang wieder gut ist. Ein Alarm piept («Ton bei Alarm»), sagt den Wert an («Alarme ansagen») und wiederholt das alle 10 Sekunden («Alarm wiederholen alle»), solange er besteht. Eine Warnung wird nur angesagt, wenn «Warnung auch ansagen» ein ist. Zwischen zwei Ansagen liegen immer mindestens 3 Sekunden. Ohne Telemetrie gibt es keine Warnungen.

### Alarm auch bei Turbine aus

Ab Werk kommen alle Warnungen und Alarme auch dann, wenn «Turbine aus bei» (ab Werk SF↑) auf aus steht. Im Menü in der Gruppe **Alarm auch bei Turbine aus** kannst du das je Wert ändern (EGT, Kraftstoff, ECU-Akku, Empfängerakku, RSSI, Höhe, Speed), oben schaltet **alle** alle Haken auf einmal. Ohne Haken schweigt dieser Wert, solange der Schalter auf aus steht: kein Ton, keine Ansage, keine Vibration, die Kopfzeile bleibt ruhig. Der Wert selbst wird trotzdem orange bzw. rot. Schaltest du den Schalter wieder ein und der Wert liegt noch jenseits der Grenze, kommt der Alarm sofort. Fehlercodes der ECU und Abschaltgründe (z. B. «Flammabriss») kommen immer, sie lassen sich nicht abwählen.

### Widersprüchliche Quellen

Liest Jet einen Wert direkt aus der Telemetrie der ECU (JetCat, Xicoy, SportECU) und zeigt der Sensor, der im Menü für diesen Wert steht, gleichzeitig etwas deutlich anderes, meldet Jet eine Warnung: Kopfzeile orange und unten der Hinweis z. B. «EGT: ECU-Daten und Sensor weichen ab» (alle 30 Sekunden wieder). Das gilt für EGT (mehr als 50 °C bzw. 15 %), Drehzahl (mehr als 5000 U/min bzw. 15 %), ECU-Akku (mehr als 0,5 V) und Kraftstoff (mehr als 10 %), und erst wenn die Abweichung 3 Sekunden besteht. Angezeigt wird weiter der Wert der ECU. Prüfe dann die Zuordnung (Menü › Zuordnung prüfen), zum Beispiel wenn ein eigener Temperatursensor als EGT zugewiesen ist. Ohne Ton und Ansage.

### Kraftstoff in Stufen

Fällt der Kraftstoff unter 75, 50, 30, 10 und 5 %, sagt der Sender je einmal «Kraftstoff» und die Zahl in Prozent. Bei 10 und 5 % vibriert er zusätzlich, wenn «Vibration bei Alarm» ein ist. Tankst du nach und der Wert steigt 5 % über eine Stufe, gilt sie wieder. Abschalten mit «Kraftstoff in Stufen».

### Abschaltung

Meldet die ECU beim Ausgehen einen Fehlercode (z. B. «Temperatur zu tief»), oder geht eine laufende Turbine aus, ohne dass «Turbine aus bei» (ab Werk SF↑) eingeschaltet ist und ohne dass die ECU selbst «aus» meldet, gilt das als Abschaltung. Ein Fehlercode gilt immer, auch wenn SF schon auf «aus» steht: Kopf rot, Pille ABSCHALTUNG, STATUS rot mit dem Text der ECU. Der Sender sagt «Turbine aus» und gut eine Sekunde später den Grund: «Flammabriss», «Kraftstoff leer», «Akku tief», «Übertemperatur», «Failsafe» oder sonst «Störung». Bei Turbine 2 bis 4 heisst es «Turbine zwei aus» usw. Die Vibration folgt der Einstellung; einen Ton gibt es hier nur, wenn keine Sprachdatei da ist. Diese Ansage kommt immer, auch wenn «Alarme ansagen» aus ist. Ohne Statussensor oder ohne bekannten Statustext gilt als Flammabriss, wenn die Drehzahl 2 Sekunden unter «Leerlauf ab» liegt. Die Anzeige bleibt rot, bis die Turbine wieder startet; SF löscht sie nicht. Legst du SF erst nach dem Flammabriss um, bleibt es eine Abschaltung. Grenzwert-Alarme (EGT, Kraftstoff, Akkus, Empfang) kommen auch bei SF «aus», ausser du nimmst bei einem Wert den Haken «Alarm auch bei Turbine aus» weg (siehe oben).

![Abschaltung](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2020%20Abschaltung%20Flammabriss.png)

## Was immer kommt

- **Fehlercodes der ECU und Abschaltgründe kommen immer**, auch wenn «Turbine aus bei» (SF) auf aus steht und auch ohne einen einzigen Haken «Alarm auch bei Turbine aus»: Kopf rot, Pille ABSCHALTUNG, STATUS rot mit dem Text der ECU, «Turbine aus» und der Grund «Flammabriss», «Kraftstoff leer», «Akku tief», «Übertemperatur», «Failsafe» oder sonst «Störung» (Turbine 2 bis 4: «Turbine zwei aus» usw.). Ohne Statussensor gilt als Flammabriss, wenn die Drehzahl 2 Sekunden unter «Leerlauf ab» liegt.
- Diese Ansage kommt auch, wenn «Alarme ansagen» aus ist. Ein Alarm ohne Ansage gibt immer einen Ton.
- Der Status der ECU («immerAlarm» in Lua-Studio) folgt nie «Alarm auch bei Turbine aus».
- **Ganz still nur mit «aus»:** Im Menü ist eine Grenze nur mit 0 aus; eine Lua-Studio-Datei schaltet eine Grenze nur mit `aus = true` aus. Ein Eintrag ohne Stufe (z. B. nur `beiMotorAus = false`, oder Warnung und Alarm beide `false`) gibt die Werkgrenze.
- Die Warnung bei widersprüchlichen Quellen hat keinen Ton und lässt sich nicht abwählen.

---
[← Start](../Home.md) | [Zurück](Anzeige.md) | [Weiter →](Lua-Studio.md)
