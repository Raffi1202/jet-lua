[🇬🇧 English](../en/Display.md) · 🇩🇪 Deutsch

# Anzeige

## 5. Die Anzeige

![Anzeige](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2004%20Normal.png)

| Nr. | Feld (Ort) | Was es zeigt |
|---|---|---|
| 1 | Modellname (Kopfzeile links) | Name des Modells im Sender. Die Kopfzeile wird orange bei einer Warnung und rot bei einem Alarm oder einer Abschaltung. |
| 2 | Laufzeit (Kopfzeile Mitte) | Dauer des laufenden Laufs in Minuten:Sekunden. Sie läuft, solange die Turbine dreht. |
| 3 | Turbinen-Pille (Kopfzeile rechts) | Zustand der Turbine: AUS grau, START blau, LÄUFT grün, ABSCHALTUNG rot. Links davon erscheinen deine eigenen Schalter als grüne Pille, solange sie eingeschaltet sind (z. B. «STABI», «FAHRWERK»). |
| 4 | Balken, Akkusymbol (ganz rechts) | Empfangsstärke (RSSI) in vier Stufen und der Akku des Senders. |
| 5 | DREHZAHL (Tacho 1) | Drehzahl in U/min. Der Bogen reicht bis zur höchsten Soll- oder Ist-Drehzahl in diesem Lauf (beginnt bei jedem Start neu) (oder bis «Tacho Drehzahl bis»). Darunter gelb SOLL (nur JetCat) oder HÖCHST. |
| 6 | EGT (Tacho 2) | Abgastemperatur in °C, Bogen 350–800 °C. Darunter HÖCHST = höchster Wert in diesem Lauf (beginnt bei jedem Start neu). |
| 7 | KRAFTSTOFF (Tacho 3) | Rest in %, darunter Rest in ml. Der %-Wert kommt von der ECU; fehlt er, rechnet Jet aus ml und Tankgrösse. |
| 8 | ECU-AKKU (Tacho 4) | Spannung des ECU-Akkus in Volt. Der Bogen geht von leer bis voll je ECU-Akkuart und Zellenzahl. Darunter TIEFST. |
| 9 | STATUS (gross, links) | Zustand der ECU als Text, Farbe wie die Pille: grün läuft, blau Start, grau aus/bereit/abkühlen, rot Fehler. Darunter «seit 4:13», solange sie läuft. Kennt Jet den Code nicht: «Code n». Antippen öffnet die letzten Statuswechsel (Kapitel 7). |
| 10 | «6 Läufe» (unten links) | Zahl der gezählten Läufe dieses Modells. Antippen öffnet die Flugliste. |
| 11 | FLUSS ml/min (Feld 1) | Kraftstofffluss in ml/min, darunter in diesem Lauf verbraucht in ml. |
| 12 | PUMPE (Feld 2) | Pumpenspannung in V, darunter HÖCHST. Bei Kingtech am VSpeak als Leistung «PW». |
| 13 | SCHUB (Feld 3) | Schub in N (nur JetCat), darunter HÖCHST. |
| 14 | HÖHE (Feld 4) | Höhe in m, darunter HÖCHST. |
| 15 | SPEED (Feld 5) | Geschwindigkeit in km/h, darunter HÖCHST. |
| 16 | EMPFANG (Feld 6) | RSSI in dB, darunter Empfängerakku («RX 7,9V») und TIEFST. Liefert dein Empfänger RSSI in dBm (negativ), steht «dBm». |

Ein kurzer grauer Strich statt einer Zahl heisst: Dieser Wert kommt gerade nicht an oder hat keinen Sensor. Was in welchem Tacho und Feld steht, kannst du im Menü ändern (Kapitel 8, Gruppe Felder).

**Kraftstoff:** Liefert die ECU nur ml, rechnet Jet die % aus der **Tankgrösse**. Ob die ml der Rest im Tank oder der Verbrauch sind, legt **Kraftstoff ml ist** fest; ab Werk «nach Hersteller». Ist die Tankgrösse 0 und fehlen die %, steht unter dem Tacho orange «Tankgrösse einstellen».

**Mehrere Turbinen:** Bei 2 bis 4 Turbinen zeigen EGT, KRAFTSTOFF und ECU-AKKU den kritischsten Wert (höchste EGT, wenigster Kraftstoff, tiefster Akku); hinter dem Titel steht dann z. B. «T2». Alle Turbinen nebeneinander zeigt Seite 2 (Kapitel 7).

### Kompaktansicht

Wählst du das Layout mit Kopf- und Fussleiste (Kapitel 3), merkt Jet das selbst und zeigt eine kompakte Ansicht: oben eine schmale Leiste mit Laufzeit, Pillen und Empfang (Modellname und Senderakku stehen in der Ethos-Kopfzeile), darunter die vier Tachos und acht Felder: STATUS, Feld 1 bis 6 und LÄUFE. Antippen von LÄUFE öffnet die Flugliste. Alles andere geht wie im Vollbild.

![Kompaktansicht](../../docs/bilder-simulator/Jet%20-%20Sim%20784x316%2033%20Kompakt%20Normal.png)

Kompaktansicht auf X20 und X18RS (784 × 316). Auf X14 und X18 / Twin X Lite ist sie entsprechend kleiner.

## 7. Bedienen

### Läufe erkennen

Ein Lauf beginnt, sobald die Turbine dreht: Die ECU meldet einen Start- oder Lauf-Status, oder ohne Statussensor (bzw. ohne bekannten Statustext) liegt die Drehzahl über 1000 U/min. Die Laufzeit oben läuft. Erreicht die Turbine «läuft» (grün; ohne Statussensor: Drehzahl ab «Leerlauf ab», ab Werk 10 000 U/min), sagt der Sender «Turbine läuft». Schaltest du sie mit «Turbine aus bei» ab, sagt er «Turbine aus» (beides nur, wenn «Turbine läuft/aus» ein ist).

Steht die Turbine 5 Sekunden (Drehzahl unter 1000 U/min, kein Start- oder Lauf-Status), endet der Lauf und kommt ohne Rückfrage in die Flugliste. Ein Lauf zählt erst ab 30 Sekunden («Lauf zählt ab»); kürzere Läufe, z. B. ein Fehlstart, fallen weg.

![Start](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2021%20Start.png)

Start: Pille START, Status blau

![Statusliste](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2026%20Statusliste.png)

STATUS antippen: letzte Statuswechsel

### Letzte Statuswechsel

Tippe auf das Feld STATUS. Es öffnet sich «LETZTE STATUSWECHSEL» mit den letzten 5 Wechseln, je mit der Laufzeit, der neuste oben. **SCHLIESSEN** oder eine Drehung am Drehrad schliesst das Fenster.

### Turbinen (Seite 2)

Nur bei 2 bis 4 Turbinen: Wische nach links. Je Turbine eine Spalte mit Drehzahl, EGT, Kraftstoff, ECU-Akku und Status. Werte über der Warnung sind orange, über dem Alarm rot.

![Turbinen](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2023%20Turbinen%202.png)

### Flugliste

Wische nach links (bei mehreren Turbinen zweimal) oder tippe auf «n Läufe». Rechts stehen die Läufe, der neuste oben, der laufende blau mit «läuft». Die Spalte «Ende» zeigt «SF aus», «Abschaltung» (rot) oder «-». Tippe einen Lauf an: Links erscheinen Laufzeit, Verbraucht, Höchst-EGT, Höchst-Drehzahl, Kraftstoff am Ende, Höchste Höhe, Höchst-Speed, Tiefster ECU-Akku, Ende (bei einer Abschaltung mit dem Text der ECU) und Turbinen.

![Flugliste](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2025%20Flugliste.png)

- Einen Lauf löschen: Lauf antippen, **LAUF n LÖSCHEN**, dann **JA, LÖSCHEN**. Unten erscheint «Lauf n gelöscht». Die späteren Nummern rücken nach.

- Alle Läufe löschen: **LISTE LÖSCHEN**, dann **JA, LÖSCHEN**. Unten erscheint «Flugliste gelöscht». Der Zähler beginnt wieder bei 1.

- Mit **ABBRECHEN** bleibt alles, wie es ist.

- Zurück zur Anzeige: **< ZURÜCK** oder nach rechts wischen.

Die Liste behält die letzten 20 Läufe und bleibt beim Ausschalten erhalten. Ein Lauf, der beim Ausschalten noch offen war, kommt beim nächsten Einschalten in die Liste.

### Lauf von Hand beenden

Im Menü oben bei **Lauf beenden** auf **Beenden** tippen. Es erscheint «Lauf beenden?» mit «Er kommt in die Flugliste.». **JA, BEENDEN** beendet ihn, unten erscheint «Lauf beendet». Ein neuer Lauf beginnt erst, wenn die Turbine einmal gestanden hat.

### Ansage auf Schalter

Schaltest du **SG↓** ein («Ansage bei»), sagt der Sender «Kraftstoff» mit %, «Laufzeit» mit Minuten und, wenn eingeschaltet, «Höhe» mit Metern. Was angesagt wird, wählst du in der Gruppe Ansagen.

### Sender ohne Berührung (X14, X10, X12)

Das Drehrad blättert von der Anzeige zur Seite Turbinen und zur Flugliste. Auf der Flugliste wählst du damit Läufe; vor dem ersten Lauf zurückdrehen führt wieder zur Anzeige. Im Menü oben gibt es **Lauf beenden**, **Lauf löschen** (vorher bei «Lauf Nr. zum Löschen» die Nummer wählen) und **Ganze Liste löschen**, jeweils mit Rückfrage.

---
[← Start](../Home.md) | [Zurück](Einrichten.md) | [Weiter →](Alarme.md)
