# Testleitfaden Jet 0.4.0

Danke, dass du Jet testest. Arbeite die Testfälle der Reihe nach durch und hake ab, was so klappt wie beschrieben.
Klappt etwas nicht, melde es (ganz unten steht wie). Ein Testfall dauert meistens nur ein bis zwei Minuten.

## Was du brauchst

- FrSky-Sender mit Ethos **26.2** und Farbdisplay. Jet lief bisher im Simulator und an einer echten X18RS mit simulierter Telemetrie.
  Jeder echte Sender hilft, ein anderer als die X18RS besonders.
- Eine Turbine mit Telemetrie: JetCat mit eigenem Telemetrieadapter, Xicoy mit TeleX, SportECU oder VSpeak-ECU-Converter
  (Kingtech, Swiwin, PBS, evoJet, Hornet/Behotec, Jakadofsky, JetCat). Ohne Turbine geht vieles auch mit dem
  Telemetrie-Simulator; schreib dann in die Meldung, was du benutzt hast. Beim Telemetrie-Simulator vorher «C» senden:
  Er schickt nach jedem Start eingebaute Testwerte (z. B. 25 °C, Drehzahl-Rampe), die sonst die Anzeige verfälschen.
- Am Modell: die Sensoren schon gesucht (Modell › Telemetrie › Sensoren suchen).
- Tankgrösse in ml, Art und Zellenzahl deines ECU-Akkus.
- Computer mit der FrSky Suite und ein USB-Kabel.
- Die Datei `Jet-0.4.0.zip` aus dem GitHub-Release (Seite «Releases» rechts im Repo).
- Die Anleitung `docs/Jet - Anleitung.pdf`. Die Testfälle verweisen auf ihre Kapitel.

**Sicherheit:** Jet hat noch nie eine echte Turbinen-ECU gesehen. Verlass dich beim ersten Lauf nicht auf seine
Anzeige und seine Alarme, sondern auf die GSU bzw. die Anzeige deiner ECU. Läufe nur mit gesichertem Modell, Feuerlöscher
und im Freien. Der Flugtest (Testfall 17) ist freiwillig.

**Vorher sichern:** Erstelle in der FrSky Suite eine Sicherung deines Senders. Jet ändert keine Modelleinstellungen
und legt keine Sensoren an. Seine Daten liegen im Ordner `scripts/jet`, die Dateien für Lua-Studio in `scripts/studio`.

## Testfälle

Notiere dir für die Meldung: Sender, Ethos-Version (System › Info), Hersteller und Weg zum Sender (z. B. «Xicoy TeleX»)
und welche Sensoren dein Modell hat.

### 1. Installieren (Anleitung Kapitel 2)
- [ ] Mit der FrSky Suite: Lua-Bibliothek › Von lokaler ZIP installieren › `Jet-0.4.0.zip`. Sender neu starten.
- **Erwartet:** Die Suite meldet keinen Fehler. Nach dem Neustart erscheint keine Fehlermeldung.
  (Die Installation über die Suite ist noch nicht ausprobiert. Klappt sie nicht, schreib genau, was die Suite meldet.)

### 2. Bildschirm einrichten (Kapitel 3)
- [ ] Neuer Bildschirm mit dem Layout **Vollbild**, Widget **Jet** wählen.
- **Erwartet:** Die Anzeige erscheint sofort: oben Modellname, Laufzeit und Pille AUS, darunter vier Tachos, links
  STATUS und «0 Läufe», rechts sechs Felder. Unten links steht **kein** roter Text.
- [ ] Einen zweiten Bildschirm mit dem Layout **mit Kopf- und Fussleiste** (ein Feld, im Auswahlraster unten Mitte) anlegen und Jet wählen.
- **Erwartet:** Kompaktansicht: oben Laufzeit, Pille und Empfang, darunter vier Tachos und acht Felder (STATUS, Fluss,
  Pumpe, Schub, Höhe, Speed, Empfang, Läufe). Nichts ragt über den Rand, kein roter Text. LÄUFE antippen öffnet die Flugliste.

### 3. Ohne Telemetrie
- [ ] Empfänger aus.
- **Erwartet:** Überall graue Striche, Laufzeit 0:00, keine Warnung, kein roter Text.

### 4. Sensoren und Hersteller (Kapitel 4)
- [ ] Empfänger und ECU einschalten, etwa 10 Sekunden warten.
- **Erwartet:** Unten erscheint kurz blau «… Sensoren automatisch zugewiesen». Werte erscheinen in den Tachos.
- [ ] Widget-Menü öffnen (Modell › Bildschirme › Widget antippen). Oben bei **Erkannt** nachsehen.
- **Erwartet:** Dort steht dein Hersteller (JetCat, Xicoy, SportECU oder «VSpeak - Hersteller wählen»).
- [ ] Je nach Hersteller:
  - **JetCat:** Nichts einstellen. **Erwartet:** STATUS zeigt Text (z. B. «Läuft»), SOLL und PUMPE haben Werte, obwohl ihre
    Zeilen in der Gruppe Sensoren leer sein dürfen (Jet liest 0x5000–0x53FF selbst). Bei 2 bis 4 Turbinen erscheint die Seite «Turbinen».
  - **Xicoy:** Nichts einstellen. **Erwartet:** EGT, Drehzahl, ECU-Akku, Pumpe, Kraftstoff % und Status haben Werte.
    **Bitte notieren**, ob ECU-AKKU und PUMPE mit der ECU übereinstimmen.
  - **SportECU:** Tankgrösse einstellen. **Erwartet:** Kraftstoff % und ml haben Werte (Jet liest 0x0A10 selbst).
  - **VSpeak:** Hersteller › **ECU am VSpeak** deine Turbine wählen. **Erwartet:** Bei Erkannt verschwindet «Hersteller wählen»,
    STATUS zeigt Text statt «Code n».
- [ ] Gruppe **Zuordnung prüfen** öffnen.
- **Erwartet:** Jede Zeile nennt einen passenden Sensor oder «kein Sensor». Die Empfängerspannung steht **nicht** bei ECU-Akku.
- [ ] Eine Zeile in der Gruppe **Sensoren** leeren, dann oben **Suchen** drücken.
- **Erwartet:** Nur die leere Zeile wird neu gefüllt, deine anderen Zeilen bleiben.
- [ ] Hängen am Empfänger weitere Geräte mit denselben Werten (z. B. ein Drehzahl- oder Spannungssensor): oben
  **Turbinenwerte neu zuordnen** › **Neu** › «JA, NEU».
- **Erwartet:** Drehzahl, EGT, ECU-Akku, Kraftstoff und Status zeigen die Werte der Turbine (in Zuordnung prüfen
  steht bei diesen Zeilen «P1B»), nicht die des anderen Geräts. Empfang, Höhe und Speed bleiben, wie sie waren.

- [ ] Nur wenn du magst: Modell › Telemetrie › **Alle Sensoren löschen**, dann **Sensoren suchen**. Danach im Widget-Menü
  **Turbinenwerte neu zuordnen** › **Neu** › «JA, NEU».
- **Erwartet:** Empfang und RX-Akku zeigen wieder echte Werte (nicht «0 dB» / «0,0 V»), kein roter Kopf.
- Hinweis: Nach «Alle Sensoren löschen» und neuer Suche sagt Ethos selbst minutenlang neue Sensoren und Konflikte an. Das kommt von Ethos, nicht von Jet.

### 5. Hersteller von Hand
- [ ] Menü › Hersteller › **Hersteller** auf einen falschen Hersteller stellen, dann zurück auf **automatisch**.
- **Erwartet:** Mit dem falschen Hersteller zeigt STATUS andere Texte oder «Code n». Mit «automatisch» wieder richtig.

### 6. Werte und Farben (Kapitel 5)
- [ ] Menü › Turbine: Tankgrösse, ECU-Akkuart und ECU-Akku Zellen einstellen. Tank voll.
- **Erwartet:** KRAFTSTOFF zeigt etwa 100 % und darunter die ml. ECU-AKKU zeigt die Spannung, der Bogen passt zum Ladezustand.
- [ ] Drehzahl am Boden mit der Anzeige der ECU bzw. GSU vergleichen (Leerlauf und eine höhere Stufe).
- **Erwartet:** Gleiche Zahl. Ist sie 10- oder 100-mal kleiner: Menü › Hersteller › **Drehzahl mal** umstellen und **bitte melden**, welcher Wert stimmt.
- [ ] Liefert deine ECU nur ml (SportECU, VSpeak): Tankgrösse auf 0 stellen.
- **Erwartet:** Orange «Tankgrösse einstellen» unter KRAFTSTOFF. Danach wieder richtig einstellen.

### 7. Warnung und Alarm (Kapitel 6)
- [ ] Menü › Grenzwerte (0 = aus): «Kraftstoff Warnung unter» auf 95 % und «Kraftstoff Alarm unter» auf 90 % stellen (zum Testen, danach zurück auf 30/20).
- **Erwartet:** Liegt der Kraftstoff darunter: Kopfzeile erst orange (Warnung), dann rot mit rotem Rahmen um KRAFTSTOFF,
  Ton und Ansage «Achtung! Kraftstoff Reserve». Die Ansage wiederholt sich alle 10 Sekunden.
- [ ] Ebenso «ECU-Zelle Warnung unter» knapp über die aktuelle Zellenspannung stellen (danach zurück auf 3,70/3,50 V).
- **Erwartet:** ECU-AKKU orange. Mit dem Alarm: rot, «Achtung! Akku der Turbinensteuerung tief» und die Spannung.
- [ ] Schalter **SG↓** einschalten.
- **Erwartet:** Ansage «Kraftstoff» mit Prozent und «Laufzeit» mit Minuten.
- [ ] Neu in 0.4.0, «Alarm auch bei Turbine aus» (Kapitel 6): Kraftstoff-Alarm wie oben auslösen, Schalter «Turbine aus bei» (SF↑) auf aus.
- **Erwartet:** Haken «Kraftstoff» in der Gruppe **Alarm auch bei Turbine aus** ein (ab Werk): Alarm mit Ton und Ansage wie oben.
- [ ] Haken «Kraftstoff» aus, SF bleibt aus.
- **Erwartet:** Still: kein Ton, keine Ansage, Kopfzeile nicht rot; KRAFTSTOFF selbst ist rot.
- [ ] Haken bleibt aus, SF auf ein.
- **Erwartet:** Der Alarm kommt sofort mit Ton und Ansage. Danach Haken wieder ein und die Grenzen zurück auf 30/20.
- [ ] Mit einer Abschaltung (Fehlercode, z. B. −10) bei SF aus und allen Haken aus («alle» aus).
- **Erwartet:** «Turbine aus» und der Grund kommen trotzdem, Kopf rot. Danach «alle» wieder ein.
- [ ] Neu in 0.4.0, nur mit einem zweiten Temperatursensor (z. B. 0x0400) neben der JetCat-Telemetrie: diesen Sensor im Menü
  als **EGT** zuweisen; er soll deutlich anders als die EGT der ECU messen (mehr als 50 °C).
- **Erwartet:** Nach etwa 3 Sekunden Kopfzeile orange und unten «EGT: ECU-Daten und Sensor weichen ab», ohne Ton. Angezeigt wird die EGT der ECU.
  Messen beide gleich (weniger als 50 °C Unterschied): keine Warnung.

### 8. Start, Lauf und gewolltes Abschalten mit SF (Kapitel 7)
- [ ] Prüfen, dass im Menü › Schalter «Turbine aus bei» dein Turbine-aus-Schalter steht (ab Werk SF↑).
- [ ] Turbine starten und über 30 Sekunden laufen lassen.
- **Erwartet:** Pille START (blau) und STATUS blau mit dem Startschritt der ECU, die Laufzeit läuft. Bei «läuft»: Pille LÄUFT (grün),
  Ansage «Turbine läuft», STATUS grün mit «seit …».
- [ ] STATUS antippen.
- **Erwartet:** «LETZTE STATUSWECHSEL» mit bis zu 5 Einträgen und Laufzeit. **SCHLIESSEN** schliesst das Fenster.
- [ ] Turbine mit SF abstellen und auslaufen lassen.
- **Erwartet:** Ansage «Turbine aus», **kein** Alarm, Kopf nicht rot. Schon nach 30 s Laufzeit steht unten links
  eine Zahl mehr bei «Läufe». 5 Sekunden nach dem Stillstand steht der Lauf in der Flugliste, mit Ende «SF aus».

### 9. Abschalten ohne SF (Kapitel 6, «Abschaltung»)
- [ ] Nur wenn es sicher geht: Turbine laufen lassen und **nicht** über SF abstellen, sondern über die GSU, die ECU oder Kraftstoff zu.
- **Erwartet:** Kopf rot, Pille ABSCHALTUNG, STATUS rot mit dem Text der ECU. Ansage «Turbine aus» und ein Grund
  («Flammabriss», «Kraftstoff leer», «Akku tief», «Übertemperatur», «Failsafe» oder «Störung»). Rot bleibt bis zum nächsten Start;
  SF löscht es nicht. In der Flugliste Ende «Abschaltung» (rot), in den Details der Text der ECU.
- [ ] **Bitte notieren:** was die ECU bzw. GSU anzeigt, was STATUS in Jet zeigt und welcher Grund angesagt wurde.
- [ ] Meldet deine ECU nach dem Abstellen mit SF einen Fehlercode (STATUS rot), kommt ebenfalls «Turbine aus» mit Grund und Alarm.
  **Bitte notieren**, wenn das bei einem normalen Abstellen mit SF passiert (dann wäre es ein Fehlalarm).

### 10. Fehlstart
- [ ] Einen Start nach weniger als 30 Sekunden abbrechen.
- **Erwartet:** Der Lauf kommt **nicht** in die Flugliste, die Zahl der Läufe bleibt gleich.

### 11. Kraftstoffstufen (Kapitel 6, «Kraftstoff in Stufen»)
- [ ] Während eines Laufs oder mit dem Telemetrie-Simulator den Kraftstoff von voll bis unter 5 % sinken lassen.
- **Erwartet:** Je einmal «Kraftstoff 75 Prozent», 50, 30, unter 20 % «Achtung! Kraftstoff Reserve», dann 10 und 5 Prozent.
  Mit «Vibration bei Alarm» ein vibriert der Sender bei 10 und 5 %. Keine Stufe wird doppelt angesagt.

### 12. Flugliste und Löschen (Kapitel 7, «Flugliste»)
- [ ] Nach links wischen (bei mehreren Turbinen zweimal) oder «n Läufe» antippen.
- **Erwartet:** Rechts die Liste, der neuste Lauf oben. Ein Lauf antippen zeigt links Laufzeit, Verbraucht, Höchst-EGT, Höchst-Drehzahl usw.
- [ ] Einen Lauf löschen: **LAUF n LÖSCHEN** › **JA, LÖSCHEN**.
- **Erwartet:** «Lauf n gelöscht», die späteren Nummern rücken nach. **ABBRECHEN** ändert nichts.
- [ ] Menü › **Lauf beenden** › **Beenden** während eines Laufs über 30 s.
- **Erwartet:** Rückfrage «Lauf beenden?». Mit **JA, BEENDEN** steht «Lauf beendet» und der Lauf in der Liste.
- [ ] Sender aus- und wieder einschalten.
- **Erwartet:** Einstellungen, Sensoren, Zähler und Flugliste sind noch da. Kein roter Text.

### 13. Mehrere Turbinen (nur JetCat mit 2 bis 4 Turbinen)
- [ ] Nach links wischen.
- **Erwartet:** Seite «Turbinen» mit einer Spalte je Turbine. Auf Seite 1 steht beim kritischsten Wert z. B. «T2».
- [ ] **Bitte notieren:** unter Zuordnung prüfen bzw. Modell › Telemetrie die Physical ID der Sensoren von Turbine 2 bis 4.

### 14. Ohne Berührung über das Menü (X14, X10, X12; auf anderen Sendern mit dem Drehrad)
- [ ] Mit dem Drehrad zur Flugliste und zurück. Im Menü oben **Lauf Nr. zum Löschen** wählen, dann **Lauf löschen** › **Löschen**,
  danach **Ganze Liste löschen** › **Löschen**.
- **Erwartet:** Alles geht ohne Berührung, jede Löschung fragt nach («JA, LÖSCHEN» oder «ABBRECHEN»).

### 15. Englisch
- [ ] Menü › Anzeige › Sprache / Language auf **English**, Menü schliessen und wieder öffnen.
- **Erwartet:** Anzeige, Menü, Statustexte und Ansagen sind englisch.

### 16. Studio-Datei (neu in 0.2.0, Symbole ab 0.3.0, nur wenn du Lua-Studio hast)
Die Datei heisst `scripts/studio/<Kennung>.jet.lua`. Die Kennung ist der Modellname, nur Buchstaben A–Z und Ziffern,
alles andere wird zu `_` (aus «Jet 1» wird `Jet_1`). Lua-Studio legt sie selbst an, dazu die Symbole in `scripts/studio/symbole/`.
- [ ] Ab 0.3.0: Datei mit Symbolen (Studio-Format 2) laden. **Erwartet:** Symbole, fette Einheit und Schmuck erscheinen;
  fehlt ein Symbolbild, Hinweis «Symbole fehlen», die Werte stehen trotzdem.
- [ ] Ohne Studio-Datei Menü öffnen.
- **Erwartet:** Oben steht «Studio-Datei: keine» mit dem Knopf **Zurück**. Sonst ist alles wie in 0.1.6.
- [ ] In Lua-Studio für dein Modell eine Ansicht gestalten, auf den Sender übertragen, das Modell neu laden.
- **Erwartet:** Jet zeigt deine Plätze, das Menü zeigt «Studio-Datei: geladen». Steht unten ein Hinweis
  («Studio-Datei …»), bitte mit Log melden. Abschaltung und Grenzwert-Alarme verhalten sich wie in Testfall 7 und 9.
- [ ] Im Widget-Menü z. B. die **Tankgrösse** ändern, Sender aus- und wieder einschalten.
- **Erwartet:** Die Änderung bleibt (sie steht in `…jet.funke.lua`, die Datei von Lua-Studio bleibt unverändert).
- [ ] Menü › Studio-Datei › **Zurück** › «JA, ZURÜCK».
- **Erwartet:** Unten «Zurück auf Studio-Stand», die Tankgrösse ist wieder die aus Lua-Studio (falls du sie dort eingestellt hast).
- [ ] Die Studio-Datei kaputt machen (am Computer mit einem Texteditor ganz am Anfang `xxx` einfügen), Modell neu laden.
- **Erwartet:** Kein Lua-Fehler. Unten 8 s lang «Studio-Datei kaputt - Standard», danach oben rechts ein oranges «!».
  Jet zeigt die eingebaute Anzeige, das Menü «Studio-Datei: kaputt». Danach die Datei in Lua-Studio neu übertragen.

### 17. Echter Flug (freiwillig)
- [ ] Einen normalen Flug machen.
- **Erwartet:** Plausible Werte, Kraftstoff-Ansagen in Stufen, kein Fehlalarm. Der Lauf steht danach in der Liste.

### 18. Speicher nach Modellwechsel (neu in 0.4.0, nur mit dem Messwerkzeug MemLog)
- [ ] MemLog im Modell einschalten, ein Modell mit Jet anzeigen (einmal mit, einmal ohne Studio-Datei), dann auf ein Modell ohne Jet wechseln.
- **Erwartet:** Nach dem Wechsel bleibt von Jet höchstens rund 20 KB belegt (im Simulator rund 5 KB). Zurück im Jet-Modell
  läuft alles wie vorher (Einstellungen, Läufe, Studio-Datei).

## Mit echter Turbine: bitte notieren

Diese Werte kann nur jemand mit echter ECU liefern. Schreib sie in die Meldung, auch wenn alles gestimmt hat.

| Was | Wie |
|---|---|
| Statuscodes | Jeden Zustand, den du siehst (Start, Läuft, Auslaufen, Abkühlen, Fehler): was STATUS in Jet zeigt (Text oder «Code n») und was die ECU bzw. GSU gleichzeitig anzeigt. Ein Bild von beiden ist ideal. |
| Abschaltung | Code und Text bei einer Abschaltung, angesagter Grund. Negative Codes besonders (z. B. «-28»). |
| Drehzahl | Drehzahl in Ethos (Modell › Telemetrie, Sensor «RPM» bzw. «EngRpm») und an der ECU bei gleicher Stufe. Welche Einstellung «Drehzahl mal» stimmt. |
| Kraftstoff | Ob ml der Rest oder der Verbrauch ist, und ob % mit der ECU übereinstimmt. |
| Sensoren | Welche Sensoren Ethos selbst gefunden hat, mit Physical ID und AppID (Gruppe Zuordnung prüfen). |
| Xicoy: ECU-Akku und Pumpe | Was ECU-AKKU und PUMPE in Jet zeigen und was die ECU anzeigt. Jet liest VBAT und PUMP als Zehntel-Volt (so zeigt sie das Xicoy-Lua); ob das stimmt, ist nicht belegt. |

## Einen Fehler melden

1. Im Repo auf GitHub: **Issues › New issue › «Fehler / Bug»** (Vorlage `fehler`). Das Formular fragt Sender,
   Ethos-Version, Lua-Version, Schritte, Log und Bild ab.
2. **Bildschirmfoto:** Am Sender ein Foto mit dem Handy genügt. Wichtig ist roter Text unten links im Widget.
3. **Log:** Lua-Fehler stehen im Log des Senders. In der FrSky Suite (Sender per USB im Modus «Ethos Suite»)
   das **Debug-Log** öffnen und den Text mit «Jet» kopieren. Alternativ unter System › Info die gespeicherten Fehler abfotografieren.
4. Gib die **Nummer des Testfalls** an und was du erwartet hast.

Ideen und Wünsche bitte mit der Vorlage **«Wunsch / Idee»**.

## Bekannte Grenzen von 0.4.0

- Im Ethos-Simulator 26.2 (X18RS) und mit dem Zufallstest geprüft, andere Bildschirmgrössen nachgestellt. Sendertest an einer echten X18RS mit simulierter Telemetrie bestanden (0.1.5, Code gleich in 0.1.6).
- Die Studio-Datei (neu in 0.2.0) hat mit 0.2.1 den Sendertest an der X18RS bestanden (laden, volle Ansicht, kaputt),
  die Symbole (Format 2) mit 0.3.0 (Symbole, fette Einheiten, Abschaltung, EGT-Alarm). Noch offen: die Belastung mit
  sehr vielen Symbolen und Schmuck im Vollbild und ein fehlendes Symbolbild.
  Am echten Sender noch offen: «zu neu», Änderungen in `.funke.lua` und «Zurück», Kompaktansicht und Englisch mit
  Studio-Datei, eine selbst gestaltete Ansicht. Bitte darauf besonders achten.
- Plätze in den reservierten Flächen (Kopfleiste oben, Knopf LÄUFE unten links im Vollbild) überdeckt Jet. Lua-Studio
  sperrt diese Flächen; eine von Hand geschriebene Datei kann sie trotzdem nutzen.
- Noch nie mit einer echten Turbinen-ECU, nur mit simulierter Telemetrie.
- Installation über die FrSky Suite noch nicht ausprobiert.
- Unsicher: Drehzahl-Faktor des Sensors 0x0500 («Drehzahl mal»), ob Ethos die Xicoy-Sensoren 0x4400–0x4406 selbst anlegt,
  Physical IDs der JetCat-Turbinen 2 bis 4, negative Statuscodes über den Sensor «Temp2» (0x0410).
- Die deutschen Statustexte sind eigene Übersetzungen der Herstellertexte; die englischen sind die Originale.
- Die Sprachdateien sind erst teilweise am Sender abgehört. Fehlt eine, kommt bei «Turbine läuft», «Turbine aus» und (mit «Ton bei Alarm») dem Abschaltgrund ein Ton; bei einem Alarm kommt dann immer ein Ton.
- 0.4.0 ist nur im Simulator geprüft: «Alarm auch bei Turbine aus», Warnung bei widersprüchlichen Quellen (im Simulator
  mit einem Testhaken für den Sensorwert, weil der Simulator aus Rahmen keine Sensoren anlegt) und die Speicherfreigabe.
- Lua-Speicher rund 144 KB, mit Studio-Datei im Simulator rund 100–115 KB mehr; nach dem Wechsel auf ein Modell ohne Jet
  rund 5 KB (Simulator). Auf Sendern mit vielen anderen
  Lua-Widgets kann der Speicher knapp werden.

## English

*The widget, the menu and the manual are also in English (`docs/Jet - Manual.pdf`). Set the language in the widget menu
(Display › Sprache / Language) or leave it «as the radio». Work through the test cases above in order; they follow the
manual's chapters. Test case 16 (new in 0.2.0) checks the Lua-Studio settings file; it passed a radio test on an X18RS with 0.2.1. New in 0.4.0 (simulator only so far): test case 7 checks «Alarm also with turbine off» and the warning for contradicting sources, test case 18 the memory after a model change (needs the MemLog tool). Jet has run in the simulator and on one X18RS with simulated telemetry, and has never seen a real turbine ECU, so do not rely on its alarms
during your first runs. If you have a real turbine, please note the status codes (what Jet shows and what the ECU or GSU
shows at the same time) and the RPM in Ethos compared with the ECU. Report problems with the issue template «Fehler / Bug»,
attach a photo and the Debug log from FrSky Suite.*
