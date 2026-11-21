# Jet changelog

The version number is in `src/jet/main.lua` (`local VERSION`). It is the same in the manual, in the Suite package and
here. The top section appears as release note in the FrSky Suite. From 0.4.0 on the changelog is in English;
**older entries in German**.

## 0.5.1 (2026-11-22)

- After the 5 s hint «Studio: view … adapted» no orange «!» stays in the header (the hint is one-off).
- The ZIP for sharing is now called `Jet-0.5.1-share.zip`.
- Studio hints («Studio: …») are shown in Jet's own header (instead of the model name; compact: instead of the flight time) and never cover values. The bottom band is gone.
- Curves draw at most 40 lines per paint.
- Test mode only: the info file leaves out the model path.
- Instruction count (Mac count): base load without Studio 8523 per paint; only the stress files exceed the 10 000 guide value (p12_voll up to 13 817, 100 symbols up to 12 752), all other test files stay below 9 500. To be checked on the radio.

## 0.5.0 (2026-11-22)

Studio layout is always found (Lua-Studio issue #1):
- **Search places:** the Studio file is searched in `SCRIPTS:/studio/`, `SD:/scripts/studio/` and `RADIO:/scripts/studio/` (in this order, the same place only once). Changes on the radio (`.funke.lua`) and the info file stay in `SCRIPTS:/studio/`.
- **Any file name:** new menu line **«Studio layout»**: «automatic (model name)» or any `*.jet.lua` of the three places. A choice in the menu wins over the model name. Stored at the end of the widget storage (storage FORMAT 2); an update from 0.4.0 keeps all sensors, the choice is «automatic».
- **Any window size:** without an exact view, Jet takes the view with the most similar aspect ratio (tie: larger area) and scales all slots and decoration to the free area below its own header, once when loading. Slots that get too small are shown as a number, or left out and counted. Hint for 5 s: «Studio: view 800x480 adapted».
- **Feedback:** if the default display is shown although a file was found or chosen, a line at the bottom tells why («Studio: file faulty (…)», «Studio: no matching view», «Studio: chosen file missing (…)»).
- **Info file:** new fields at the end: `studioQuelle`, `studioWahl` (`auto`/`menue`), `ansichtGenutzt`, `angepasst`, `hinweis`.
- Unchanged: Studio format 1/2, «no shutdown without aus», `beiMotorAus`, memory release, alarms and announcements.

## 0.4.0 (2026-11-21)

Pre-release (public beta), tested in the Ethos simulator; transmitter test on the X18RS follows.

- **«Alarm also with turbine off»** per value (EGT, fuel, ECU battery, receiver battery, RSSI, altitude, speed): new menu group with an «all» switch, on by default. Without the tick, warning and alarm of this value stay silent while «Turbine off at» is off (no tone, no announcement, no vibration, calm top bar; the value itself keeps its colour). When the switch goes back on, a silenced alarm comes at once. ECU error codes and shutdown reasons (e.g. «Flameout») always come. Lua-Studio key `beiMotorAus` per limit (format 2 §3.5, also in format 1, format number unchanged), also for extra limits, never for the status (`immerAlarm`); changes on the radio go into `.funke.lua`. `beschreibung.json` and the info file report `"beiMotorAus": true`.
- **Contradicting sources:** if the assigned sensor clearly differs from the ECU telemetry Jet reads itself (EGT, RPM, ECU battery, fuel), a warning comes after 3 s (orange top bar, hint at the bottom, no tone).
- **Memory freed after a model change:** main.lua holds the core only weakly. In the simulator about 5 KB stay after switching to a model without Jet instead of 145 KB, also with a Studio file and symbols (378 KB while open).
- **Fixed (alarm safety, format v1 §6.5):** a limit entry in a Studio file without an active stage (e.g. only `beiMotorAus = false`, only `ansage = false`, or `warnung = false` and `alarm = false`) switched the monitored alarm off. Now the factory limit applies; completely silent only with `aus = true`.

## 0.3.1 (21.11.2026)

Keine Vorabversion mehr. Nur Doku, der Code ist gleich wie 0.3.0 (ausser der Versionsnummer).

- Sendertest von 0.3.0 an der X18RS (Ethos 26.2.0, simulierte JetCat-Telemetrie) bestanden: Studio-Datei Format 2
  mit 20 Symbolen und fetten Einheiten flüssig, kein «Max instructions»; −10 → Kopf rot, Pille ABSCHALTUNG,
  Status-Platz rot; EGT 612 → 780 → EGT-Platz und Symbol rot, Kopf rot. Ansagen dabei nicht abgehört.
- Im ersten Lauf zeigte Jet zeitweise falsche Werte (7503 U/min, 25 °C, ECU-Akku 9,8 V): Das waren die eingebauten Testwerte des
  Telemetrie-Simulators, nicht Jet. Testleitfaden: vorher «C» senden.
- Noch offen am Sender: Belastung mit sehr vielen Symbolen und Schmuck, fehlendes Symbolbild, zu neue Datei,
  `.funke.lua` und «Zurück», Kompaktansicht und Englisch mit Studio-Datei, echte ECU, Suite-Installation.

## 0.3.0 (21.11.2026)

Vorabversion. **Lua-Studio-Format 2** (nach Elektro 0.4.0):

- **Symbole** (z. B. Turbine, Impeller, Tank, Pumpe, Temperatur, Akku, Höhe, Speed, Empfang) als Bildmasken aus
  `scripts/studio/symbole/`, **fette Einheit** und **Schmuck** (Linien, Rahmen); Referenz `studio_symbole.lua`
  wörtlich. Fehlen Symbole, zeigt Jet die Plätze ohne sie und meldet «Studio: n Symbole fehlen».
- Studio-Dateien im Format 1 laden weiter. `studio/beschreibung.json`: Formate [1, 2], Vorlagen «standard» und
  «mit_symbolen» (Vorschlag aus Lua-Studio, mit dem Studio-Code geprüft).
- Listen in der Studio-Datei (Werte, Grenzen, Einstellungen) höchstens 48 Einträge, Prüfung in Stücken zu 8; Kanäle
  werden zusätzlich auf einen gültigen Wert geprüft.
- Unverändert: Abschaltung mit Grund auch bei SF «aus», Alarm ohne Ansage gibt immer einen Ton, höchstens 6 weitere
  Grenzen, Studio-Schritt und Lesen nie im selben Aufruf.
- Erprobung: Mac-Prüfstand (Pflichttests des Formats, Zufallstest mit 5 Saaten) und 37 Simulator-Abläufe ohne
  Fehler; Sendertest folgt. **Test 12/17 nach Wortlaut nicht erfüllt:** Das ganze `paint` liegt am Prüfstand über
  5'000 Befehlen (eingebaute Seite rund 8'500, volle Format-2-Ansicht bis 13'472). Die eingebaute Seite lief am
  X18RS seit 0.1.0 ohne Abbruch, die Zählung am Prüfstand passt also bei `paint` nicht 1:1 zur Grenze am Sender.
  Geprüft wird darum ersatzweise, dass Format 2 höchstens 3'600 Befehle mehr kostet als dieselbe Datei in Format 1;
  am Sender wird die volle Ansicht gezielt getestet. Speicher am Prüfstand: mit Symbol-Datei rund 145–165 KB mehr
  als ohne Studio-Datei.

## 0.2.2 (21.11.2026)

Keine Vorabversion mehr. Nur Doku, der Code ist gleich wie 0.2.1 (ausser der Versionsnummer).

- Sendertest von 0.2.1 an der X18RS (Ethos 26.2.0, simulierte JetCat-Telemetrie) bestanden: Studio-Datei geladen,
  volle Ansicht mit 16 Plätzen flüssig mit Livewerten, Sensor-Plätze mit Werten, kein «Max instructions»; mit
  Studio-Datei −10 → «Turbine aus» + «Flammabriss», Status-Platz rot; kaputte Datei → Hinweis und Standard.
- Noch offen am Sender: zu neue Datei, Änderungen an der Funke (`.funke.lua`) und «Zurück», Kompaktansicht und
  Englisch mit Studio-Datei, eine selbst gestaltete Ansicht. Grenzwert-Alarme (z. B. EGT) wurden mit 0.2.x am Sender
  nicht wiederholt (geprüft mit 0.1.5; die Ansage-Logik hat sich in 0.2.0 geändert).
- Bekannt: Plätze in den reservierten Flächen (Kopfleiste, Knopf LÄUFE unten links) überdeckt Jet; die Testdatei
  `voll.jet.lua` nutzt sie (roter Kopf im Test kam von einer absichtlich überschrittenen Grenze dieser Datei).
  Lua-Studio sperrt diese Flächen.

## 0.2.1 (20.11.2026)

Korrekturen nach dem Befund von Elektro am Sender (X18RS) und einem Fund des Zufallstests:

- **Sensorliste:** `system.getSources` mit einer Tabelle `{ category = … }` liefert am Sender eine leere Liste. Jet
  holt die Liste jetzt mit der Kategorie als Zahl (Info-Datei, Sensoren der Studio-Datei).
- **Sensoren der Studio-Datei** werden immer in der Sensorliste gesucht (AppID, Teilwert, Physical ID falls angegeben),
  nicht mehr über `getSource` mit AppID (lieferte am Sender ein Objekt ohne Wert).
- **«Turbinenwerte neu zuordnen»** leert keine Felder, wenn die Sensorliste leer ist (wie Elektro 0.3.2).
- **Einstellungen gingen verloren:** Der Zufallstest fand, dass bei seltenen wakeup-Aufrufen Einstellungen nicht
  gespeichert wurden (Studio-Schritt und Lesen im selben bzw. in jedem Aufruf). Studio-Schritt und Lesen laufen
  nie im selben Aufruf; bei seltenen Aufrufen wechseln sie sich ab (gelesen wird dann jeden zweiten Aufruf). Zufallstest mit 5 Saaten ohne Fehler.

## 0.2.0 (20.11.2026)

- **Kein stummer Alarm (Entscheid User):** Ist die Ansage eines Alarms aus (Menü, Studio-Grenze `ansage = false`) oder
  fehlt seine Sprachdatei, kommt trotzdem immer ein Ton, auch bei «Ton bei Alarm» aus. Still nur mit `aus = true`.
- Alarme ohne Sprachdatei (Studio-Grenzen auf Sensoren und Kanäle) geben Ton und Vibration und halten «Turbine aus»
  mit Grund nicht mehr auf.
- Studio-Datei in kleinen Schritten geladen und angewendet (Laden und Anwenden unter 2'600 Befehle je Aufruf, auch bei
  der grössten zulässigen Datei); fehlende Sensoren (Kategorie «keine») gelten als nicht gefunden.
- Höchstens 6 weitere Grenzen (auf Sensoren, Kanäle oder nicht überwachte Werte) je Modell; behalten werden die mit
  den alphabetisch kleinsten Schlüsseln, weitere verwirft Jet mit Hinweis (Befehlsgrenze im laufenden Betrieb).
- **Einstellungsdatei aus Lua-Studio** (Lua-Studio-Format v1): Jet liest beim Laden des Modells
  `scripts/studio/<Kennung>.jet.lua` (Kennung = Modellname, nur A–Z und Ziffern, Rest `_`), prüft jede Angabe und
  zeigt bei Problemen einen Hinweis (nie ein Absturz). Frei belegbare Plätze mit Darstellungsart (Zahl, Ring, Balken
  waagrecht/senkrecht, Verlauf, Status), eigene Farben, Zusatzzeile MIN/MAX/Ø je Lauf. Standard wie bisher: 4 Tachos
  + Status + 6 Felder im Vollbild (LÄUFE fest unten links), 4 Tachos + Status + 7 Felder inkl. LÄUFE kompakt.
- Einstellungen und Grenzwerte je Modell, Grenzen auch für Sensoren und Kanäle. Fehlt eine Grenze in der Datei, gilt
  die Werkgrenze; nur `aus = true` schaltet sie ab. Passt die Richtung nicht zum Wert, gilt die Werkgrenze mit Hinweis.
- **Sicherheitslogik unverändert:** Abschaltung mit Grund auch bei SF «aus», Kopf rot bis die Turbine wieder läuft,
  Grenzwert-Alarme unabhängig von SF. Die Studio-Datei setzt nur Einstellungen und Grenzen.
- Änderungen im Funken-Menü gehen bei vorhandener Studio-Datei in `…jet.funke.lua`; die Datei von Lua-Studio bleibt
  unverändert. Neue Menüzeile «Studio-Datei: keine / geladen / kaputt / zu neu» mit «Zurück» (Studio-Stand bzw.
  Standard, mit Rückfrage). Info-Datei `…jet.info.json` für Lua-Studio (Modellname, Sender, Fenster, Sensorliste).
- Ohne Studio-Datei bleiben Anzeige, Einstellungen und Alarme wie in 0.1.6.
- Erprobung: Ethos-Simulator 26.2.0 (Abläufe 50–53: Studio-Datei 784 × 316 und 800 × 480, kaputt, zu neu) und
  Mac-Tests (`test/studio-test.lua`: Angriffs- und Grenzfalldateien, `.funke.lua` schreiben). **Sendertest folgt.**
- Speicher: mit Studio-Datei im Simulator rund 100–115 KB mehr Lua-Speicher als 0.1.6.

## 0.1.6 (20.11.2026)

Keine Vorabversion mehr. Nur Doku, der Code ist gleich wie 0.1.5 (ausser der Versionsnummer).

- Sendertest von 0.1.5 an der X18RS (Ethos 26.2.0, simulierte JetCat-Telemetrie) bestanden: Fehlercode −10 mit SF
  «aus» und «ein» → «Turbine aus» + «Flammabriss», Kopf rot, bis die Turbine wieder läuft (auch nach SF zurück); EGT-Alarm mit SF «aus»; «Turbine läuft».
- README, Anleitung und Testleitfaden auf diesen Stand gebracht; Hinweis, dass Ethos nach «Alle Sensoren löschen»
  lange selbst ansagt.

## 0.1.5 (20.11.2026)

Aus dem Diagnose-Test an der X18RS (Ethos 26.2.0) und Entscheid des Users:

- **Fehlercode auch bei SF «aus»:** Meldet die ECU beim Ausgehen einen Fehlercode (Gruppe rot, z. B. JetCat −10),
  gilt das immer als Abschaltung: «Turbine aus» + Grund, Kopf rot, Pille ABSCHALTUNG, Flugliste «Abschaltung».
  Vorher galt jedes Ausgehen bei SF «aus» als gewollt, ohne Grund und ohne Alarm.
- **Rot bis zum Neustart:** Der rote Kopf bleibt, bis die Turbine wieder startet; SF löscht ihn nicht mehr.
- **Ohne Statussensor:** Für einen Flammabriss über den Drehzahlabfall zählt die SF-Stellung beim Beginn des Abfalls.
  Legt der Pilot SF erst danach um, bleibt es eine Abschaltung mit Alarm.
- Grenzwert-Alarme (EGT, Kraftstoff, Akkus, Empfang) waren und sind unabhängig von SF.
- **Richtigstellung zu 0.1.3/0.1.4:** Der fehlende «Flammabriss» war kein Audio-Problem. In allen Sendertests stand
  SF auf «aus»; Jet wertete die Abschaltung darum als gewollt. Mit SF «ein» kamen am Sender «Turbine aus» und
  «Flammabriss» (Diagnose-Log). Die Warteschlange für mehrteilige Ansagen aus 0.1.4 bleibt.
- Diagnose-Ausgaben im Code (`local DIAG = false`, ab Werk aus). Neuer Simulator-Ablauf `test/43-abschaltung-sf-aus.json`.

## 0.1.4 (20.11.2026)

Korrektur aus dem Nachtest von 0.1.3 (X18RS, Ethos 26.2.0):

- **Abschaltgrund als eigene Ansage:** Zwei Sprachdateien direkt nacheinander spielen am Sender nur die erste;
  «Flammabriss» fehlte darum auch ohne Ton. Der Grund kommt jetzt als eigene Ansage 1,6 s nach «Turbine aus»
  (im Simulator gemessen: 1,7 s). Fehlt die Grund-Datei, kommt ein Ton (Einstellung «Ton bei Alarm»).
- **Ansageschalter Teil für Teil:** Kraftstoff, Laufzeit und Höhe kommen nacheinander mit 2,8 s Abstand statt in
  einem Aufruf (im Simulator gemessen: 4,1 / 7,0 / 10,0 s).
- **Mehrere Turbinen:** Gehen mehrere Turbinen kurz nacheinander aus, wird jede angesagt (Abschaltungen mit Grund
  zuerst); vorher überschrieb die letzte die anderen.
- Bestätigt am Sender: «Turbinenwerte neu zuordnen» nach «Alle Sensoren löschen» holt Empfang und RX wieder (0.1.3).

## 0.1.3 (20.11.2026)

Korrekturen aus dem Sendertest von 0.1.2 (X18RS, Ethos 26.2.0, simulierte JetCat-Telemetrie; Anzeige bestanden):

- **Abschaltgrund wird wieder angesagt:** Nach «Turbine aus» fehlte der Grund (z. B. «Flammabriss»). Der Ton direkt
  nach den Ansagen brach am Sender die zweite, noch wartende Sprachdatei ab. Der Ton kommt jetzt nur noch, wenn keine
  Sprachdatei da ist; die Vibration bleibt.
- **«Turbinenwerte neu zuordnen» nach gelöschten Sensoren:** Nach «Alle Sensoren löschen» und neuer Suche zeigte Jet
  Empfang «0 dB», RX 0,0 V und Alarm (alte Verweise liefern 0). Neu zuordnen bindet jetzt jedes Feld an den Sensor der
  aktuellen Liste (gleiche AppID, Teilwert, Physical ID und Name) und weist Felder ohne Gegenstück neu zu. Quellen
  ausserhalb der Telemetrie bleiben.
- Mac-Test `test/suche-test.lua` um diesen Fall ergänzt. Testleitfaden: Flugtest ist Testfall 16.

## 0.1.2 (20.11.2026)

- **Telemetrie direkt gelesen:** Per Lua angelegte Sensoren bekommen am echten Sender keine Werte (X18RS, Befund
  Heli RF). Jet liest darum die Werte, für die Ethos keine Sensoren anlegt, selbst aus der Telemetrie: JetCat
  0x5000–0x53FF (Status, Soll-Drehzahl, Pumpe, Rest ml, Fluss, Schub, Höhe, Speed, Welle, Strom, Turbine 2–4),
  Xicoy 0x4400–0x4406, SportECU 0x0A10. Ein solcher Wert gilt 5 s, danach wieder der Sensor aus dem Menü.
- Nur Rahmen von der Physical ID des Herstellers (JetCat 0x1B/0x0D/0x14/0x07, Xicoy und SportECU 0x1B) und mit
  glaubhaftem Wert zählen; höchstens 16 Rahmen je Weckruf.
- Negative Statuscodes (32 Bit) werden richtig gelesen.
- Der Hersteller wird auch an der empfangenen Telemetrie erkannt.
- **«Sensoren anlegen» und «Turbinen anlegen bis» entfernt** (die angelegten Sensoren blieben am Sender leer).
- «Turbine läuft» kommt bei mehreren Turbinen nur einmal.
- Neuer Simulator-Ablauf `test/40-rahmen-jetcat.json` mit echten S.Port-Rahmen (JetCat, Turbine 2, fremdes Gerät).

## 0.1.1 (20.11.2026)

Korrekturen aus dem ersten Sendertest (X18RS, Turbine und Testgeräte mit gleichen AppIDs am selben Empfänger):

- **Sensorsuche:** Bei gleicher AppID auf mehreren Physical IDs gewinnt für Turbinenwerte die Turbinen-ID 0x1B.
  Vorher wurden Drehzahl, EGT, ECU-Akku und Kraftstoff eines anderen Geräts gewählt.
- **Status über 0x0410 (Temp2)** nur noch von 0x1B; bei anderen Geräten ist Temp2 eine Temperatur («Code 35»).
- Bei Turbinenwerten zählt 0x1B vor der Rangfolge: ein Xicoy-Akku 0x4403 auf 0x1B gewinnt gegen eine fremde VFAS,
  der JetCat-Strom 0x5002 gegen einen fremden FAS-Strom.
- **Neuer Menüknopf «Turbinenwerte neu zuordnen»** (mit Rückfrage): ersetzt alle Turbinenwerte, deren Sensor nicht
  auf 0x1B liegt. Dasselbe geschieht nach «Sensoren anlegen».
- **Update von 0.1.0:** Jet ordnet die Turbinenwerte einmal neu zu, und die alten RX-Grenzen 7,4 / 7,0 V werden aus.
- **RX-Akku-Grenzen ab Werk aus** (vorher 7,4 / 7,0 V; Empfänger mit 5 V BEC waren dauernd im Alarm).
- Neuer Mac-Test `test/suche-test.lua` (Testgeräte mit gleichen AppIDs, Xicoy, Strom, 80 Sensoren, Update von 0.1.0).
- Sensorsuche: Kennung in mehreren Schritten geladen (höchstens rund 2'100 statt 4'900 Befehle je Aufruf).

## 0.1.0 (20.11.2026)

Erste Version (Vorabversion).

- **Hersteller:** JetCat mit eigenem Telemetrieadapter (Slave 1–4), Xicoy mit TeleX, SportECU (Hornet III u. a.),
  VSpeak-Converter für Kingtech, Swiwin, PBS, evoJet, Hornet/Behotec, Jakadofsky und JetCat; übrige «von Hand».
  Der Hersteller wird an den Sensoren erkannt oder im Menü gewählt.
- **Sensoren anlegen:** fehlende JetCat-, Xicoy- und SportECU-Sensoren per Menüknopf mit Rückfrage.
- **Anzeige:** vier Tachos (Drehzahl, EGT, Kraftstoff, ECU-Akku), grosses Feld STATUS, sechs frei belegbare Felder,
  Zahl der Läufe. Kompaktansicht im Ethos-Layout mit Kopf- und Fussleiste (784 × 316, 630 × 258, 472 × 210).
- **Statustexte** der ECU je Hersteller, deutsch und englisch, mit Farbe (läuft, Start, aus, Fehler); Liste der
  letzten 5 Statuswechsel.
- **Warnungen und Alarme:** zwei Schwellen je Wert; Kraftstoff-Ansagen bei 75/50/30/10/5 %, «Kraftstoff Reserve»
  unter 20 %; Abschaltung ohne SF↑ mit Grund («Flammabriss», «Kraftstoff leer» …).
- **Läufe:** Laufzeit statt Flugzeit, Läufe unter 30 s zählen nicht, Flugliste mit einzeln löschbaren Läufen.
- **Mehrere Turbinen** (JetCat Slave 2–4): Seite «Turbinen», Seite 1 zeigt den kritischsten Wert.
