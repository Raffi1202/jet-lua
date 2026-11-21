[🇬🇧 English](../en/Troubleshooting.md) · 🇩🇪 Deutsch

# Fehlerbehebung

## 9. Wenn etwas nicht geht

| Was du siehst | Ursache | Was du tust |
|---|---|---|
| Überall Striche, Laufzeit 0:00 | Keine Telemetrie | Empfänger und ECU einschalten. Prüfen, ob der Empfänger verbunden ist. |
| Drehzahl, EGT, ECU-Akku oder Status zeigen Werte eines anderen Geräts (z. B. Drehzahl 8000 statt 98400) | Ein anderes Gerät sendet dieselbe Kennung (AppID) und wurde zugewiesen | Menü oben › **Turbinenwerte neu zuordnen** › Neu › «JA, NEU». Danach in «Zuordnung prüfen» bei diesen Zeilen «P1B» kontrollieren. |
| Menü: Erkannt «noch nichts» | Keine Turbinen-Sensoren zugewiesen | Kapitel 4: Hersteller wählen, Suchen. Bei JetCat, Xicoy und SportECU erkennt Jet den Hersteller, sobald Telemetrie der Turbine kommt. |
| STATUS zeigt «Code 27» o. ä. | Hersteller oder ECU am VSpeak nicht gewählt, oder ein Code, den Jet nicht kennt | Menü › Hersteller kontrollieren. Bleibt es bei «Code n»: Code und Anzeige der ECU notieren und melden. |
| Orange «Tankgrösse einstellen» unter KRAFTSTOFF | Die ECU liefert nur ml, Tankgrösse ist 0 | Menü › Turbine › Tankgrösse einstellen. |
| Kraftstoff % steigt statt fällt | «Kraftstoff ml ist» passt nicht zur ECU | Menü › Hersteller › «Kraftstoff ml ist» umstellen. |
| Drehzahl 10- oder 100-mal zu klein | Die ECU sendet die Drehzahl geteilt | Menü › Hersteller › «Drehzahl mal» auf 10 oder 100. |
| Rot ABSCHALTUNG, obwohl du selbst abgestellt hast | «Turbine aus bei» ist nicht dein Schalter | Menü › Schalter › «Turbine aus bei» die Stellung wählen. |
| Läufe zählen nicht | Lauf kürzer als «Lauf zählt ab», oder ohne Statussensor keine Drehzahl | Sensoren Drehzahl und Status kontrollieren (Kapitel 4). |
| Keine Seite Turbinen, obwohl du 2 hast | Von Turbine 2 kommt keine Telemetrie | Slave-Adresse der zweiten ECU (2) und ihren Telemetrieadapter prüfen. |
| Bei Alarm nur ein Piepton und die Zahl | Die Sprachdateien fehlen auf dem Sender (Ordner `audio`) | Kapitel 2 wiederholen. |
| Unten «Studio-Datei kaputt - Standard», «zu neu» oder «n Fehler», danach oben rechts «!» | Die Datei von Lua-Studio ist kaputt, für eine neuere Jet-Version oder enthält ungültige Angaben | In Lua-Studio neu übertragen bzw. Jet aktualisieren. Was genau falsch ist, steht im Log (je Fehler eine Zeile). |
| Unten links steht roter Text | Fehler im Skript. Der Sender läuft normal weiter. | Text abfotografieren und als Fehler melden: auf GitHub unter Issues, Vorlage «Fehler / Bug» (siehe TESTLEITFADEN.md im Repo). |
| Das Widget fehlt in der Liste | Nicht installiert oder Sender nicht neu gestartet | Kapitel 2 wiederholen, Sender neu starten. |

## Lua-Speicher («too much RAM»)

Alle Lua-Skripte auf dem Sender teilen sich einen Lua-Speicher (rund 2048 KB auf der X18RS). Jet braucht rund 144 KB, mit Studio-Datei rund 100–115 KB mehr (Simulator). Ab 0.4.0 gibt Jet den Speicher bis auf rund 5 KB frei, wenn du auf ein Modell ohne Jet wechselst (im Simulator gemessen). Meldet der Sender «too much RAM» bzw. «Zu wenig Lua-Speicher»: **Sender aus- und wieder einschalten**, danach weniger verschiedene Lua-Widgets gleichzeitig nutzen.

---
[← Start](../Home.md) | [Zurück](FAQ.md) | [Weiter →](Versionen.md)
