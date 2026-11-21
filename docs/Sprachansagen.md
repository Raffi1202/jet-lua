# Jet: Sprachansagen

Diese Liste ist die einzige Quelle der Ansagen. Texte immer hier ändern und dann neu erzeugen lassen
(eigenes Werkzeug mit Google Text-to-Speech).
Ablage: `src/jet/audio/de/<Dateiname>.wav` und `src/jet/audio/en/<Dateiname>.wav`.
Format WAV A-law, mono, 16 kHz, 8 Bit, Stimmen wie die Ethos-Originale (de-DE-Wavenet-E Tempo 1,1, en-US-Wavenet-F).
Lautstärke nicht anpassen. Folgt im Skript direkt eine Zahl («+ Zahl»), vorne und hinten keine Stille.
Vor dem Einsetzen anhören lassen. Fehlt eine Datei, spielt das Skript einen Ton.

| Dateiname | Deutsch | Englisch | Aussprache-Hinweis | Wann |
|---|---|---|---|---|
| `turbine_laeuft` | Turbine läuft | Turbine running | – | Turbine erreicht «läuft» (Einstellung «Turbine läuft/aus») |
| `turbine_aus` | Turbine aus | Turbine off | – | Turbine 1 aus; bei Abschaltung ohne SF folgt der Grund |
| `turbine_2_aus` | Turbine zwei aus | Turbine two off | – | wie oben, Turbine 2 |
| `turbine_3_aus` | Turbine drei aus | Turbine three off | – | wie oben, Turbine 3 |
| `turbine_4_aus` | Turbine vier aus | Turbine four off | – | wie oben, Turbine 4 |
| `flammabriss` | Flammabriss | Flameout | – | Grund nach «Turbine aus» |
| `kraftstoff_leer` | Kraftstoff leer | Out of fuel | – | Grund nach «Turbine aus» |
| `akku_tief` | Akku tief | Battery low | – | Grund nach «Turbine aus» |
| `uebertemperatur` | Übertemperatur | Overtemperature | – | Grund nach «Turbine aus» |
| `failsafe` | Failsafe | Failsafe | englisch «Fehl-sejf» | Grund nach «Turbine aus» |
| `stoerung` | Störung | Fault | – | Grund nach «Turbine aus», wenn keiner der obigen passt |
| `kraftstoff` | Kraftstoff | Fuel | – | + Zahl Prozent: Stufen 75/50/30/10/5 % und Abfrage per Schalter |
| `kraftstoff_reserve` | Achtung! Kraftstoff Reserve | Warning! Fuel reserve | – | Kraftstoff unter der Alarmschwelle (ab Werk 20 %), ohne Zahl |
| `egt_hoch` | Achtung! Abgastemperatur hoch | Warning! E G T high | EGT englisch buchstabiert | + Zahl Grad |
| `ecu_akku_tief` | Achtung! Akku der Turbinensteuerung tief | Warning! E C U battery low | ECU deutsch ausgeschrieben | + Zahl Volt |
| `empfaengerakku` | Achtung! Empfängerakku tief | Warning! Receiver battery low | – | + Zahl Volt |
| `empfang` | Achtung! Empfang schwach | Warning! Signal low | – | + Zahl dB |
| `hoehe` | Höhe | Altitude | – | + Zahl Meter (Alarm und Abfrage per Schalter) |
| `speed` | Geschwindigkeit | Speed | – | + Zahl km/h, nur wenn Speed-Schwellen gesetzt |
| `laufzeit` | Laufzeit | Run time | – | + Zahl Minuten, Abfrage per Schalter |
