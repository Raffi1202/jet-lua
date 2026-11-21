# Jet – Anzeige für Turbinen (FrSky Ethos)

[English](README.md) · **Deutsch** · Dokumentation: [Wiki (Deutsch)](wiki/de/Installation.md) · [Wiki (English)](wiki/en/Installation.md)

> **Am PC einrichten mit [Lua-Studio](https://github.com/Raffi1202/lua-studio)**: Bildschirm einteilen, Werte, Alarme und Symbole wählen, auf die Funke übertragen.

Ethos-Widget für Jets mit Turbine auf FrSky-Sendern mit Farbdisplay. Es zeigt auf einem Bildschirm Drehzahl,
Abgastemperatur (EGT), Kraftstoff, ECU-Akku und den Zustand der Turbinensteuerung (ECU) als Text. Dazu kommen
Warnungen und Alarme mit Sprachansagen sowie eine Liste der Turbinenläufe. Anzeige, Menü und Ansagen gibt es auf
Deutsch und Englisch.

![Jet auf 800 × 480 (Ethos-Simulator)](docs/bilder-simulator/Jet%20-%20Sim%20800x480%2004%20Normal.png)

- **Mehrere Hersteller:** JetCat mit eigenem Telemetrieadapter (auch 2–4 Turbinen), Xicoy mit TeleX, SportECU
  (ProJET Hornet III u. a.) und der VSpeak-Converter für Kingtech, Swiwin, PBS, evoJet, Hornet/Behotec, Jakadofsky
  und JetCat. Der Hersteller wird an den Sensoren erkannt oder im Menü gewählt. Alle anderen: Sensoren von Hand.
- **Vier Tachos:** Drehzahl, EGT, Kraftstoff % und ECU-Akku. **STATUS** als Text in der Farbe des Zustands
  (läuft grün, Start blau, aus grau, Fehler rot). **Sechs Felder** frei belegbar (Fluss, Pumpe, Schub, Höhe, Speed,
  Empfang, Gas % …).
- **Vollbild oder kompakt:** Im Layout mit Ethos-Kopf- und Fussleiste zeigt Jet von selbst eine Kompaktansicht mit
  vier Tachos und acht Feldern.
- **Kraftstoff:** % von der ECU oder aus ml und Tankgrösse (Rest oder verbraucht). Ansagen bei 75, 50, 30, 10 und 5 %,
  «Kraftstoff Reserve» unter 20 %.
- **Abschaltung ohne SF↑ oder mit Fehlercode der ECU:** «Turbine aus» mit Grund («Flammabriss», «Kraftstoff leer», «Akku tief» …).
- **Läufe:** Laufzeit statt Flugzeit, Läufe unter 30 s (Fehlstart) zählen nicht. Die letzten 20 Läufe, einzeln löschbar.
- **Sensoren** werden beim ersten Start automatisch zugewiesen. Die Werte von JetCat (0x5000–0x53FF), Xicoy und
  SportECU, für die Ethos keine Sensoren anlegt, liest Jet selbst aus der Telemetrie.
- **Lua-Studio (neu in 0.2.0):** Eine Einstellungsdatei je Modell aus dem PC-Programm Lua-Studio belegt die Plätze
  frei (Zahl, Ring, Balken, Verlauf oder Status, eigene Farben; ab 0.3.0 Format 2 mit Symbolen wie Turbine,
  Tank, Pumpe, fetter Einheit und Schmuck) und setzt Einstellungen und Grenzwerte. Die
  Sicherheitslogik bleibt fest: Abschaltung mit Grund auch bei SF «aus», Grenzwert-Alarme auch bei SF «aus» (ab 0.5.1
  je Wert abwählbar: «Alarm auch bei Turbine aus»). Ohne
  diese Datei läuft alles wie bisher.

> **Stand 0.3.1:** Sendertest an der X18RS bestanden (0.1.5/0.1.6 ohne Studio-Datei, 0.2.1 mit Studio-Datei: geladen,
> volle Ansicht mit 16 Plätzen flüssig, Sensor-Plätze mit Werten, Abschaltung mit Grund, kaputte Datei → Standard;
> simulierte JetCat-Telemetrie). 0.2.2 ändert nur die Doku.
> 0.3.0 (Studio-Format 2 mit Symbolen) hat den Sendertest an der X18RS bestanden (Symbole, fette Einheiten, flüssig, kein
> «Max instructions», Abschaltung −10, EGT-Alarm 780 °C); noch offen: Belastung mit sehr vielen Symbolen und Schmuck,
> fehlendes Symbolbild. 0.3.1 ändert nur die Doku.
> **0.5.1 (Vorabversion, nur im Simulator):** «Alarm auch bei Turbine aus» je Wert, Warnung bei widersprüchlichen
> Quellen (ECU-Rahmen gegen Sensor), Speicher nach dem Modellwechsel frei (im Simulator 145 KB → 5 KB). Sendertest folgt.
> Mit einer echten Turbinen-ECU noch nie getestet.

Öffentliche Vorabversion (public beta). Nutzung auf eigene Verantwortung. Lizenz: GPL-3.0, siehe unten.

## Schnellstart in 5 Schritten

1. `Jet-0.5.1.zip` aus dem neusten **Release** herunterladen (rechts auf der Repo-Seite unter «Releases»).
2. Sender per USB anschliessen, am Sender **Ethos Suite** wählen, am Computer die **FrSky Suite** öffnen.
3. Suite › **Lua-Bibliothek** › **Von lokaler ZIP installieren** › die ZIP wählen. Danach den Sender neu starten.
4. Modell › Bildschirme › **+** › Layout **Vollbild** (oder mit Leisten) › ins Feld tippen › Widget **Jet**.
5. Modell und Turbine einschalten: Jet sucht die Sensoren selbst. Danach im Widget-Menü unter **Turbine** die
   **Tankgrösse** und den **ECU-Akku** einstellen. Die Werte von JetCat, Xicoy und SportECU, für die Ethos keine
   Sensoren anlegt, liest Jet selbst aus der Telemetrie.

Ohne Suite geht es auch per USB-Speicher bzw. SD-Karte (Anleitung Kapitel 2).

## Anleitung und Testen

| Was | Datei |
|---|---|
| Anleitung zum Ausdrucken | [`docs/Jet - Anleitung.pdf`](docs/Jet%20-%20Anleitung.pdf) (HTML-Fassung in `docs/anleitung/`) |
| Manual (English) | [`docs/Jet - Manual.pdf`](docs/Jet%20-%20Manual.pdf) |
| Testleitfaden für Tester (Häkchenliste) | [`TESTLEITFADEN.md`](TESTLEITFADEN.md) |
| Fehler melden, Wünsche | GitHub › Issues › New issue (Vorlagen «Fehler / Bug» und «Wunsch / Idee») |
| Versionen | [`CHANGELOG.md`](CHANGELOG.md) |
| Texte der Sprachansagen | [`docs/Sprachansagen.md`](docs/Sprachansagen.md) |

## Sender und Stand der Erprobung (Version 0.5.1, 21.11.2026)

| Display | Sender | Stand |
|---|---|---|
| 800 × 480, Berührung | X20, X20S, X20HD, X20 Pro, X20R, X20RS, X18R, X18RS | Simulator; echte X18RS mit 0.1.5/0.1.6 und 0.2.1 mit Studio-Datei und 0.3.0 mit Symbolen (Format 2) (Ethos 26.2.0, simulierte Telemetrie) |
| 640 × 360, ohne Berührung | Twin X14, X14S | nur im Simulator nachgestellt |
| 480 × 320, Berührung | X18, X18S, X18SE, Twin X Lite, Twin X Lite S | nur im Simulator nachgestellt |
| 480 × 272, ohne Berührung | X10, X10S, X10 Express, X12S (mit Ethos) | nur im Simulator nachgestellt |

**Getestet:** im Ethos-Simulator 26.2.0 laufen 44 Abläufe fehlerfrei (zwei mit echten S.Port-Rahmen: JetCat und Xicoy) (Vollbild und Kompaktansicht in allen Grössen,
JetCat, Xicoy, Kingtech über VSpeak, Start, Lauf, Abschaltung, 2 und 4 Turbinen, Flugliste mit Löschen,
Statuswechsel, Englisch, Neustart, mit 0.2.0 die Studio-Datei in 784 × 316 und 800 × 480, kaputt und zu neu, mit 0.3.0
Format 2, mit 0.5.1 «Alarm auch bei Turbine aus» mit Schalter aus/ein und widersprüchliche Quellen),
dazu auf dem Mac ein Zufallstest mit Unsinnswerten, ein Test der Sensorzuordnung mit mehreren Geräten gleicher AppID
und mit 0.2.0 ein Test der Studio-Datei (kaputte und bösartige Dateien, `.funke.lua` schreiben).

**Am echten Sender:** Version 0.1.0 lief auf der X18RS ohne Lua-Fehler, auch in der Kompaktansicht 784 × 316. Sie
wählte aber bei gleicher AppID die Sensoren eines anderen Geräts statt der Turbine. Das ist in 0.1.1 behoben.
Vor dem Sendertest von 0.1.1 zeigte sich (Heli RF), dass per Lua angelegte Sensoren am
echten Sender keine Werte bekommen; darum liest 0.1.2 diese Werte selbst und legt keine Sensoren mehr an.
0.1.2 (X18RS, 20.11.2026, simulierte JetCat-Telemetrie): Anzeige, Status, Abschaltung und Kraftstoff-Ansage ok;
«Flammabriss» fehlte nach «Turbine aus». 0.1.3: «Neu zuordnen» nach gelöschten Sensoren ok. 0.1.4 (Diagnose-Log):
der Grund fehlte, weil SF auf «aus» stand und Jet die Abschaltung darum als gewollt wertete; mit SF «ein» kamen
«Turbine aus» und «Flammabriss». Der fehlende Grund war kein Audio-Problem. 0.1.5 (X18RS, 20.11.2026): Sendertest bestanden: Fehlercode −10 mit SF «aus» und «ein» → «Turbine aus» + «Flammabriss»,
Kopf rot, bis die Turbine wieder läuft (auch nach SF zurück); EGT-Alarm mit SF «aus»; «Turbine läuft». 0.1.6 ändert nur die Doku.
0.2.1 (X18RS, 21.11.2026): Studio-Datei geladen, volle Ansicht mit 16 Plätzen flüssig mit Livewerten, −10 mit
Studio-Datei → «Turbine aus» + «Flammabriss», kaputte Datei → Standard. Dabei fiel auf: Die Testdatei setzt Plätze
in die reservierten Flächen (Kopfleiste, Knopf LÄUFE unten links im Vollbild); dort überdeckt Jet sie. Lua-Studio sperrt
diese Flächen. 0.2.2 ändert nur die Doku.

**Noch nicht getestet:**
- 0.5.1 am echten Sender: «Alarm auch bei Turbine aus» (Haken ein/aus, Schalter aus/ein), Warnung bei widersprüchlichen
  Quellen mit einem echten Temperatursensor 0x0400 (der Simulator legt aus Rahmen keine Sensoren an), Speicher nach dem
  Modellwechsel mit MemLog
- am echten Sender mit Studio-Datei: zu neue Datei, Änderungen an der Funke (`.funke.lua`) und «Zurück», Kompaktansicht und Englisch mit Studio-Datei, eine selbst gestaltete Ansicht
- mit einer echten Turbinen-ECU: bisher nur simulierte Telemetrie
- Installation über die FrSky Suite
- am Sender gehört: «Kraftstoff» + Zahl, «Turbine aus», «Flammabriss», «Turbine läuft», «EGT hoch»; noch offen: Ansageschalter mit
  mehreren Teilen, englische Ansagen, Vibration, Turbine 2–4, Xicoy und SportECU

**Am Sender zu prüfen, bekannte Grenzen:**
- Wie Ethos die Drehzahl 0x0500 anzeigt (JetCat sendet «× 100», SportECU «× 10»). Stimmt die Zahl nicht, im Menü
  **Hersteller › Drehzahl mal** anpassen.
- Ob Ethos die Xicoy-Werte 0x4400–0x4406 selbst anlegt, und die Physical IDs der JetCat-Turbinen 2–4.
- Ob negative Statuscodes über 0x0410 (Ethos zeigt «Temp. 2») richtig ankommen.
- Die deutschen Statustexte sind eigene Übersetzungen der Hersteller-Kürzel. Der JetCat-eigene Adapter sendet
  vermutlich dieselben Codes wie der VSpeak-JetCat-Converter (nicht belegt).
- Lua-Speicher rund 144 KB (0.1.6), mit Studio-Datei im Simulator rund 100–115 KB mehr. Nach dem Wechsel auf ein
  Modell ohne Jet bleiben ab 0.5.1 rund 5 KB (Simulator, auch mit Studio-Datei und Symbolen). Mit vielen anderen
  Lua-Widgets auf dem Sender kann er knapp werden.
- Getestet ist nur Ethos 26.2.

## Wo liegt was

| Inhalt | Ort |
|---|---|
| Skript, 1:1 so wie es auf den Sender kommt | `src/jet/` |
| Anleitung (PDF, Quelle als HTML) | `docs/`, `docs/anleitung/` |
| Bilder aus dem Ethos-Simulator | `docs/bilder-simulator/` |
| Abläufe für den Simulator | `test/` |
| Beschreibung für das Lua-Studio (Werte, Darstellungen, Einstellungen, Standardansicht, Vorlagen; Formate 1 und 2) | `studio/beschreibung.json` |
| Release-ZIP (nicht im Repo, als Download im GitHub-Release) | `dist/` |

## Entwickeln (nur für den Entwickler)

Für Tester nicht nötig. Die Tests brauchen Lua 5.4, den Ethos-Simulator (Plugin «ethos-tools», ab Ethos 26.2) und
Hilfsskripte des Entwicklers (Zufallstest, Simulator-Treiber, PDF- und Paketbau), die nicht in diesem Repo liegen.
Ohne diese Skripte geht die Syntaxprüfung:

```sh
luac5.4 -p src/jet/*.lua
```

## Weitere Projekte

| Projekt | Wozu |
|---|---|
| [Electric](https://github.com/Raffi1202/electric-lua) | Ethos-Widget für Elektromodelle |
| [Heli](https://github.com/Raffi1202/heli-lua) | Ethos-Widget für Helis mit Telemetrie (jedes Flybarless-System) |
| [Glider](https://github.com/Raffi1202/glider-lua) | Ethos-Widget für Segler (Vario, Thermik) |
| [Gas Engine ECU / Carb](https://github.com/Raffi1202/gas-engine-lua) | Ethos-Widgets für Verbrennungsmotoren |
| [Lua-Studio](https://github.com/Raffi1202/lua-studio) | PC-Programm zum Einrichten der Widgets (Mac/Windows) |

## Lizenz

GPL-3.0, siehe [LICENSE](LICENSE). Das Modul `src/jet/studio_symbole.lua` stammt aus Lua-Studio (gleicher Autor, gleiche
Lizenz). Die Test-Symbole in `test/studio/symbole/` beruhen teils auf Tabler Icons (MIT, © Paweł Kuna), Lizenztext dort.
