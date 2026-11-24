[🇬🇧 English](../en/Setup.md) · 🇩🇪 Deutsch

# Einrichten

## 3. Bildschirm einrichten

- Tippe unten auf das Symbol **Bildschirme** (zwei Rechtecke).

- Tippe oben rechts auf **+**.

- Wische nach unten bis zum Layout **Vollbild** (ein einziges grosses Feld) und tippe es an. Willst du die Ethos-Kopf- und Fussleiste behalten, wähle das Layout mit **einem Feld und den Leisten** (im Auswahlraster unten in der Mitte); Jet zeigt dann die Kompaktansicht (Kapitel 5).

- Tippe in das leere Feld, dann auf **Widget**.

- Wähle in der Liste **Jet**. Die Anzeige erscheint sofort.

![Widget-Liste](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2001%20Widget-Liste.png)

Das Menü des Widgets erreichst du später jederzeit über Modell › Bildschirme › den Bildschirm wählen › Widget antippen.

## 4. Sensoren zuweisen

- Schalte Empfänger und ECU ein, damit die Telemetrie läuft. Beim ersten Mal sucht Jet die Sensoren selbst; unten erscheint kurz blau «… Sensoren automatisch zugewiesen».

- Öffne das Menü. Oben steht bei **Erkannt** der Hersteller, den Jet an den Sensoren erkannt hat, z. B. «JetCat». Steht dort «noch nichts», öffne die Gruppe **Hersteller** und wähle ihn bei **Hersteller** selbst.

- Nur beim VSpeak-Converter: Wähle in der Gruppe **Hersteller** bei **ECU am VSpeak** die Turbine dahinter (Kingtech, Swiwin, PBS, evoJet, Hornet/Behotec, Jakadofsky, JetCat). Bis dahin steht bei Erkannt «VSpeak - Hersteller wählen» und der Status nur als «Code n».

- JetCat, Xicoy und SportECU senden einen Teil ihrer Werte mit Kennungen, für die Ethos keine Sensoren anlegt (JetCat 0x5000–0x53FF, SportECU-Kraftstoff 0x0A10; bei Xicoy 0x4400–0x4406 ist das noch nicht am Sender geprüft). Jet nimmt nur Werte von der Physical ID der Turbine an. Diese Werte liest Jet selbst aus der Telemetrie, du musst dafür nichts einstellen. Ihre Zeilen in der Gruppe **Sensoren** (z. B. Status, Soll-Drehzahl, Pumpe) dürfen leer bleiben.

- Hängen weitere Geräte mit denselben Kennungen am Empfänger (z. B. ein Drehzahlsensor), tippe oben bei **Turbinenwerte neu zuordnen** auf **Neu** und dann **JA, NEU**. Jet nimmt dann für alle Turbinenwerte den Sensor der Turbine (Physical ID 0x1B), sofern es einen gibt; Empfang, Höhe und Speed bleiben, ausser ihr Sensor ist gelöscht. Hast du im Modell «Alle Sensoren löschen» und neu gesucht, mach danach ebenfalls einmal **Neu**: Jet holt dann alle Werte von den neuen Sensoren.

- Öffne die Gruppe **Sensoren** und kontrolliere jede Zeile. Was leer oder falsch ist, wählst du von Hand. Eine leere Zeile ist erlaubt, das Feld zeigt dann einen Strich.

- Mit **Sensoren suchen (nur leere)** › **Suchen** füllt Jet später nur die leeren Zeilen, deine eigene Wahl bleibt.

- In der Gruppe **Zuordnung prüfen** steht je Zeile der gewählte Sensor mit Physical ID und AppID (z. B. «EngState1  P1B / 5004»). Passten mehrere gleiche Sensoren, steht darunter «n Sensoren passen, gewählt: … - bitte prüfen».

- Öffne die Gruppe **Turbine** und stelle **Tankgrösse**, **ECU-Akkuart** und **ECU-Akku Zellen** ein.

![Menü oben](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2002%20Menue.png)

### Woran Jet den Hersteller erkennt

Jet schaut auf die AppID der zugewiesenen Sensoren (eine Kennnummer, die du unter «Zuordnung prüfen» siehst). Von Hand gewählt gilt immer vor erkannt.

| Hersteller / Weg | Erkannt an | Liest Jet selbst | Kraftstoff |
|---|---|---|---|
| JetCat mit eigenem Adapter | Telemetrie mit Kennung 0x5000–0x53FF, sonst 0x0210 (ECU-Akku) zusammen mit 0x0500 (Drehzahl) | 0x5000–0x53FF: Status, Soll-Drehzahl, Pumpe, Rest ml, Fluss, Schub, Höhe, Speed, Welle, Strom; Turbine 2–4: Drehzahl, EGT, Kraftstoff, ECU-Akku, Status | % von der ECU, Rest ml |
| Xicoy mit TeleX | Telemetrie mit Kennung 0x4400–0x4406 | alle 7 Werte (EGT, Drehzahl, Gas, Akku, Pumpe, Kraftstoff %, Status) | % von der ECU |
| SportECU | Telemetrie mit Kennung 0x0A10, sonst 0x0410 zusammen mit 0x0900 | Kraftstoff ml (0x0A10) | Rest ml, % über die Tankgrösse |
| VSpeak-Converter | 0x0410 zusammen mit 0x0600 | nichts, Ethos findet die Sensoren selbst | ml, Rest oder verbraucht je nach ECU |
| von Hand | nur im Menü wählbar | nichts | Rest ml, % über die Tankgrösse |

| Zeile im Menü | Welcher Sensor gehört hinein |
|---|---|
| Drehzahl, Soll-Drehzahl | Ist- und Soll-Drehzahl der Turbine. Soll gibt es nur bei JetCat (EngSetRpm1). |
| EGT | Abgastemperatur, z. B. «EGTC» (Xicoy) oder «Tmp1» (VSpeak). |
| ECU-Akku | Spannung des Akkus der Turbinensteuerung, z. B. «VBAT» (Xicoy) oder «A3» (VSpeak, SportECU). |
| Pumpe | Pumpenspannung, z. B. «EngPumpV1», «PUMP», «A4». |
| Status | Statuscode der ECU, z. B. «EngState1», «STAT» oder «Tmp2». |
| Kraftstoff ml, Kraftstoff % | Kraftstoff in ml und in %. Was die ECU nicht liefert, bleibt leer. |
| Kraftstofffluss, Schub, Wellen-Drehzahl, ECU-Strom | Nur JetCat (EngFuelFlow1, EngThrust1, EngShaftRpm1, EngCurrent1). |
| Höhe, Geschwindigkeit | Von der ECU (JetCat), vom Vario oder GPS. |
| Gas % (Sensor) | Gasstellung von der ECU, z. B. «THRT» (Xicoy). Ohne Sensor nimmt Jet den Gaskanal (Gruppe Schalter). |
| RSSI, Empfängerakku | Empfangsstärke «RSSI» und Spannung des Empfängerakkus, z. B. «RxBatt». |

Turbine 2 bis 4 (JetCat) brauchen keine Zeilen im Menü: Jet liest ihre Werte selbst aus der Telemetrie. Ein selbst gelesener Wert gilt 5 Sekunden; kommt keiner mehr, gilt wieder der Sensor aus dem Menü.

![Xicoy](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2011%20Xicoy%20nur%20Teil.png)

Xicoy: Fluss und Speed fehlen (Strich), ein Feld zeigt GAS

![Kingtech](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2022%20Kingtech%20VSpeak.png)

Kingtech am VSpeak: Pumpe als Leistung «PW»

## 8. Alle Einstellungen

Menü öffnen: Modell › Bildschirme › den Bildschirm wählen › Widget antippen. Jede Änderung gilt sofort und bleibt gespeichert.

| Gruppe | Einstellung | Ab Werk | Bereich und Wirkung |
|---|---|---|---|
| oben | Studio-Datei | keine | Zeigt, ob eine Datei aus Lua-Studio gilt: keine, geladen, kaputt oder zu neu. Knopf **Zurück** (mit Rückfrage): mit Datei «Zurück auf Studio-Stand», ohne Datei «Zurück auf Standard». Siehe unten «Lua-Studio». |
| oben | Erkannt | – | Zeigt den Hersteller, der gerade gilt, oder «noch nichts». |
| Sensoren | 17 Zeilen | leer | Siehe Kapitel 4. Die erste Suche läuft von selbst. |
| Hersteller | Hersteller | automatisch | automatisch, JetCat, Xicoy, SportECU, VSpeak-Converter, von Hand. Bestimmt Statustexte und Kraftstoff. |
| Hersteller | ECU am VSpeak | nicht gewählt | Kingtech, Swiwin, PBS, evoJet, Hornet/Behotec, Jakadofsky, JetCat. Nur für den VSpeak-Converter. |
| Hersteller | Kraftstoff ml ist | nach Hersteller | Rest im Tank oder verbraucht. Bei Swiwin am VSpeak selbst wählen. |
| Hersteller | Drehzahl mal | 1 | 1, 10 oder 100. Für ECUs, die die Drehzahl geteilt senden; Beispiel: Ethos zeigt 9840, die ECU 98 400 → 10. |
| Hersteller | SportECU: Hornet-Texte | aus | Ein: Statuscodes der SportECU als Hornet-Texte statt «Code n». |
| Turbine | Tankgrösse | 0 ml | 0 bis 50 000 ml in 50er-Schritten. Für Kraftstoff % aus ml. 0 = nicht gesetzt. |
| Turbine | ECU-Akkuart | LiPo | LiPo, LiFe, Li-Ion, NiMH. Bestimmt den Bogen leer–voll und die Werkwerte der Grenzen. |
| Turbine | ECU-Akku Zellen | 2 S | 1 bis 6 Zellen. |
| Turbine | Leerlauf ab | 10000 U/min | 500 bis 200 000 U/min. Ohne Statussensor: ab hier gilt die Turbine als «läuft», darunter 2 s = Flammabriss. |
| Turbine | Lauf zählt ab | 30 s | 0 bis 600 s. Kürzere Läufe kommen nicht in die Liste. |
| Grenzwerte (0 = aus) | EGT Warnung über / Alarm über | 720 / 750 °C | 0 bis 1200 °C, Schritt 5. |
| Grenzwerte (0 = aus) | Kraftstoff Warnung unter / Alarm unter | 30 / 20 % | 0 bis 100 %. |
| Grenzwerte (0 = aus) | ECU-Zelle Warnung unter / Alarm unter | 3,70 / 3,50 V | 0 bis 4,50 V je Zelle, Schritt 0,05. |
| Grenzwerte (0 = aus) | RX-Akku Warnung unter / Alarm unter | 0 / 0 (aus) | 0 bis 20,00 V, Schritt 0,10. Ab Werk aus, weil Empfänger mit 5 bis 8,4 V laufen; bei 2S LiPo z. B. 7,40 / 7,00 V eintragen. |
| Grenzwerte (0 = aus) | RSSI Warnung unter / Alarm unter | 45 / 40 dB | 0 bis 120 dB. |
| Grenzwerte (0 = aus) | Höhe Warnung über / Alarm über | 110 / 120 m | 0 bis 5000 m. |
| Grenzwerte (0 = aus) | Speed Warnung über / Alarm über | 0 / 0 km/h (aus) | 0 bis 1500 km/h, Schritt 10. |
| Schalter | Turbine aus bei | SF↑ | Schalterstellung, in der die Turbine aus ist. Abschalten in dieser Stellung gilt als gewollt, ohne Alarm, ausser die ECU meldet einen Fehlercode. |
| Schalter | Ansage bei | SG↓ | Schalterstellung für die Ansage. |
| Schalter | Schalter 1 / Schalter 2 | leer | Eigene Schalter, die in der Kopfzeile erscheinen, solange sie eingeschaltet sind. |
| Schalter | Schalter 1 Name / Schalter 2 Name | STABI / FAHRWERK | Höchstens 12 Zeichen: Buchstaben, Ziffern, Leerzeichen, Punkt, Bindestrich. |
| Schalter | Gaskanal | leer | Kanal des Gases, für das Feld «Gas %», wenn kein Gas-Sensor zugewiesen ist. |
| Schalter | Gas umkehren | aus | Für «Gas Reverse» (Vollgas = Knüppel hinten): Jet zeigt 100 % − Kanal. Nur für den Gaskanal; «Gas %» von der ECU bleibt, wie die ECU es meldet. Ab 0.7.1. |
| Ansagen | Alarme ansagen | ein | Aus: bei Alarm nur Ton und Anzeige. |
| Ansagen | Warnung auch ansagen | aus | Ein: auch die orange Warnung wird angesagt. |
| Ansagen | Alarm wiederholen alle | 10 s | 3 bis 300 s. |
| Ansagen | Kraftstoff in Stufen | ein | Ansagen bei 75, 50, 30, 10 und 5 %. |
| Ansagen | «Turbine läuft/aus» | ein | Ansage beim Erreichen von «läuft» und beim gewollten Abschalten. |
| Ansagen | Ansage: Kraftstoff | ein | Was auf dem Ansageschalter gesagt wird. |
| Ansagen | Ansage: Laufzeit | ein | Was auf dem Ansageschalter gesagt wird. |
| Ansagen | Ansage: Höhe | aus | Was auf dem Ansageschalter gesagt wird. |
| Ansagen | Ton bei Alarm | ein | Piepton vor der Alarm-Ansage; bei einer Abschaltung nur, wenn keine Sprachdatei da ist. Ist die Ansage eines Alarms aus (oder fehlt seine Sprachdatei), kommt trotzdem immer ein Ton, auch wenn diese Einstellung aus ist. Ganz still ist ein Alarm nur, wenn seine Grenze abgeschaltet ist. |
| Ansagen | Vibration bei Alarm | aus | Der Sender vibriert bei Alarm, Abschaltung und den Kraftstoffstufen 10 und 5 %. |
| Felder | Tacho 1 bis 4, Feld 1 bis 6 | wie im Bild | Inhalt wählbar: leer, Drehzahl, EGT, Kraftstoff %, ECU-Akku, Status, Kraftstofffluss, Pumpe, Schub, Höhe, Speed, Empfang, Gas %, Welle, ECU-Strom, Laufzeit, Kraftstoff ml, Empfängerakku. |
| Felder | Tacho Drehzahl bis (0 = auto) | 0 | 0 bis 300 000, Schritt 1000. Endwert des Drehzahlbogens; 0 = höchste gemessene Drehzahl. |
| Alarm auch bei Turbine aus | alle | ein | Schaltet alle Haken darunter auf einmal ein oder aus. Darüber der Hinweis «Ohne Haken: still, solange Turbine aus». |
| Alarm auch bei Turbine aus | EGT, Kraftstoff, ECU-Akku, Empfängerakku, RSSI, Höhe, Speed | ein | Aus: Warnung und Alarm dieses Werts schweigen, solange «Turbine aus bei» auf aus steht. Fehlercodes und Abschaltgründe kommen immer. Siehe Kapitel 6. |
| Anzeige | Sprache / Language | wie der Sender | Deutsch oder English für Anzeige, Menü und Ansagen. Das Menü wechselt beim nächsten Öffnen. |

«Turbine aus bei» und «Ansage bei» setzt Jet beim ersten Start auf SF↑ und SG↓, wenn es diese Schalter gibt. Oben im Menü stehen ausserdem: Sensoren suchen (nur leere), Version, Erkannt, Turbinenwerte neu zuordnen (ersetzt nach der Rückfrage «Turbinenwerte neu zuordnen?» alle Turbinenwerte, deren Sensor nicht auf der Turbinen-ID 0x1B liegt, zum Beispiel wenn ein anderes Gerät dieselbe Drehzahl-ID sendet), Lauf beenden, Lauf Nr. zum Löschen, Lauf löschen, Ganze Liste löschen.

---
[← Start](../Home.md) | [Zurück](Installation.md) | [Weiter →](Anzeige.md)
