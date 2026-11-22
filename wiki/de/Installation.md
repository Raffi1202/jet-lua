[🇬🇧 English](../en/Installation.md) · 🇩🇪 Deutsch

# Installation

## 1. Was du brauchst

- Einen FrSky-Sender mit Ethos 26.2 und Farbdisplay (Liste am Schluss).

- Eine Turbine mit Telemetrie zum Sender, über einen dieser Wege: JetCat mit eigenem Telemetrieadapter (Turbine 1 bis 4), Xicoy mit TeleX-Adapter, SportECU (z. B. ProJET Hornet III), VSpeak-ECU-Converter (für Kingtech, Swiwin, PBS, evoJet, Hornet/Behotec, Jakadofsky, JetCat). Andere Turbinen gehen mit der Einstellung «von Hand».

- Am Modell die Sensoren schon gesucht (Modell › Telemetrie › Sensoren suchen).

- Die Grösse deines Tanks in ml, die Art und Zellenzahl deines ECU-Akkus.

- Einen Computer mit der FrSky Suite und ein USB-Kabel.

- Die Datei `Jet-0.5.2.zip`. Sie liegt neben dieser Anleitung in `Jet-0.5.2-share.zip`. Entpacke nur die äussere ZIP, die innere nicht.

## 2. Installieren

- Sender einschalten und mit dem USB-Kabel am Computer anschliessen.

- Am Sender erscheint eine Auswahl. Wähle **Ethos Suite**.

- Öffne am Computer die **FrSky Suite**. Der Sender wird oben angezeigt.

- Klicke auf **Lua-Bibliothek**, dann auf **Von lokaler ZIP installieren**.

- Wähle die Datei `Jet-0.5.2.zip`. Die Suite kopiert alles an den richtigen Ort.

- Ziehe das Kabel ab und starte den Sender neu.

Ohne Suite: Sender als «USB-Speicher» anschliessen und den Ordner `jet` aus der ZIP in den Ordner `scripts` kopieren. Lädt dein Sender die Skripte von der SD-Karte (System › Allgemein › Speicherort), gehört er nach `scripts` auf der SD-Karte. Einen vorhandenen Ordner überschreiben, nicht löschen.

## 10. Aktualisieren und Entfernen

**Aktualisieren:** Die neue ZIP genau wie in Kapitel 2 installieren. Deine Einstellungen, Sensoren, Läufe und Zähler bleiben erhalten.

**Entfernen:** Zuerst das Widget vom Bildschirm nehmen (Modell › Bildschirme), dann in der FrSky Suite unter Lua-Bibliothek deinstallieren. Die Dateien für Lua-Studio liegen in `scripts/studio` und können dort von Hand gelöscht werden.

## 11. Welche Sender

| Display | Sender | Stand |
|---|---|---|
| 800 × 480, Berührung | X20, X20S, X20HD, X20 Pro, X20R, X20RS, X18R, X18RS | im Simulator und an einer echten X18RS (simulierte Telemetrie) |
| 640 × 360, ohne Berührung | Twin X14, X14S | im Simulator nachgestellt |
| 480 × 320, Berührung | X18, X18S, X18SE, Twin X Lite, Twin X Lite S | im Simulator nachgestellt |
| 480 × 272, ohne Berührung | X10, X10S, X10 Express, X12S mit Ethos | im Simulator nachgestellt |

![480x320](../../docs/bilder-simulator/Jet%20-%20Sim%20480x320%2006%20Alarm.png)

480 × 320 (X18): gekürzte Titel

![Englisch](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2012%20Englisch.png)

Englisch: Sprache im Menü oder wie der Sender

Jet Version 0.5.2 · 21.11.2026

---
[← Start](../Home.md) | [Weiter →](Einrichten.md)
