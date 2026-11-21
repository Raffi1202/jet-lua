[🇬🇧 English](../en/Lua-Studio.md) · 🇩🇪 Deutsch

# Lua-Studio

## Lua-Studio (Einstellungsdatei je Modell)

Mit dem PC-Programm **Lua-Studio** gestaltest du die Anzeige je Modell frei: Für jeden Platz wählst du Wert, Darstellung (Zahl, Ring, Balken waagrecht oder senkrecht, Verlauf, Status), Titel, Bereich, Farben und Zusatzzeile (MIN, MAX oder Ø über den Lauf). Ab Version 0.3.0 (Studio-Format 2) kommen Symbole dazu (z. B. Turbine, Impeller, Tank, Pumpe, Temperatur, Akku), eine fette Einheit und Schmuck (Linien, Rahmen). Die Symbole liegen als Bilder in `scripts/studio/symbole/`; fehlt eines, zeigt Jet den Platz ohne Symbol und meldet «Symbole fehlen». Dateien im alten Format 1 laden weiter. Dazu kommen Einstellungen und Grenzwerte je Modell. Lua-Studio legt dafür auf der SD-Karte die Datei `scripts/studio/Modellname.jet.lua` an. Im Dateinamen stehen vom Modellnamen nur Buchstaben A–Z und Ziffern, alles andere wird zu `_` (aus «Jet 1» wird `Jet_1`); Lua-Studio rechnet das selbst. Jet liest die Datei beim Laden des Modells.

- **Ohne diese Datei** arbeitet Jet genau wie bisher, ohne Hinweis.

- **Ab Werk** sieht die Ansicht in Lua-Studio aus wie Jet ohne Datei: im Vollbild vier Tachos, STATUS und sechs Felder (LÄUFE bleibt fest unten links und öffnet die Flugliste), in der Kompaktansicht vier Tachos, STATUS und sieben Felder mit LÄUFE. Oben zeichnet Jet die Kopfleiste immer selbst.

- **Mit Datei** gilt ihre Ansicht nur für die Fenstergrösse, für die sie gemacht ist (z. B. Vollbild 800 × 480 oder mit Leisten 784 × 316), und im Vollbild nur auf Seite 1. Für andere Grössen zeichnet Jet seine eingebaute Anzeige.

- **Sicherheit bleibt fest:** Die Datei kann die Abschaltung nicht ändern. «Turbine aus» mit Grund kommt auch bei SF «aus», der Kopf bleibt rot, bis die Turbine wieder läuft, und Grenzwert-Alarme gelten auch bei SF «aus». Nur je Grenze darf die Datei das abwählen (`beiMotorAus = false`, in Lua-Studio der Haken «auch bei Motor aus»); im Menü heisst er «Alarm auch bei Turbine aus». Fehlercodes und Abschaltgründe kommen immer.

- **Grenzwerte** gelten je Wert, egal ob und wie er angezeigt wird. Fehlt ein Wert in der Datei, gilt die Werkgrenze. Eine Grenze geht nur aus, wenn die Datei das ausdrücklich so will (`aus = true`). Passt die Richtung nicht zum Wert, gilt ebenfalls die Werkgrenze, mit Hinweis. Grenzen gehen auch für weitere Sensoren, Kanäle oder nicht überwachte Werte, höchstens 6 je Modell (auch solche auf fehlende Sensoren zählen mit); weitere verwirft Jet mit Hinweis.

- **Änderst du an der Funke** Tank, Grenzwerte oder andere Einstellungen im Menü, schreibt Jet das in eine eigene Datei `…jet.funke.lua`. Die Datei von Lua-Studio bleibt unverändert. Lua-Studio zeigt die Unterschiede und übernimmt sie auf Wunsch.

- **Menü › Studio-Datei › Zurück:** mit Datei «Zurück auf Studio-Stand» (deine Änderungen an der Funke werden gelöscht), ohne Datei «Zurück auf Standard» (Einstellungen und Grenzwerte ab Werk; Sensoren und Läufe bleiben). Beides fragt nach.

- **Hinweise:** Ist die Datei kaputt, zu neu oder enthält sie ungültige Angaben, steht 8 Sekunden lang ein Hinweis in der Kopfzeile (z. B. «Studio-Datei kaputt - Standard»), danach oben rechts ein oranges «!». Jet läuft immer weiter, im Zweifel mit der eingebauten Anzeige.

- Jet schreibt dazu die Datei `…jet.info.json` mit Modellname, Sender, Fenstergrössen und Sensorliste. Nur Lua-Studio liest sie.

![Studio-Datei Vollbild](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2051%20Studio-Datei.png)

Beispiel einer Studio-Datei im Vollbild 800 × 480

![Studio-Datei kompakt](../../docs/bilder-simulator/Jet%20-%20Sim%20784x316%2050%20Studio-Datei.png)

Beispiel einer Studio-Datei kompakt 784 × 316

---
[← Start](../Home.md) | [Zurück](Alarme.md) | [Weiter →](FAQ.md)

## Studio-Layout finden (ab 0.5.0)

- **Orte:** Jet sucht die Studio-Datei in `SCRIPTS:/studio/`, `SD:/scripts/studio/` und `RADIO:/scripts/studio/`.
- **Name egal:** Passt der Dateiname nicht zum Modellnamen, im Widget-Menü unter **«Studio-Layout»** die Datei wählen (Liste mit Ort in Klammern). «automatisch (Modellname)» nimmt wie bisher `Modellname.jet.lua`. Die Wahl im Menü gewinnt.
- **Fenstergrösse egal:** Gibt es keine Ansicht für genau diese Grösse, rechnet Jet die ähnlichste Ansicht um und zeigt 5 Sekunden «Studio: Ansicht 800x480 angepasst». Zu kleine Plätze werden als Zahl gezeigt oder weggelassen.
- **Hinweiszeile:** Zeigt Jet trotz Datei die Standardanzeige, steht der Grund in der Kopfzeile (anstelle des Modellnamens), z. B. «Studio: Datei fehlerhaft (…)» oder «Studio: keine passende Ansicht».
