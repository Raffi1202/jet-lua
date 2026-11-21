# Jet – display for turbines (FrSky Ethos)

**English** · [Deutsch](README.de.md) · Documentation: [Wiki (English)](wiki/en/Installation.md) · [Wiki (Deutsch)](wiki/de/Installation.md)

> **Configure on your PC with [Lua-Studio](https://github.com/Raffi1202/lua-studio)** – arrange the screen, choose values, alarms and symbols, then transfer to the radio. Download: [latest release](https://github.com/Raffi1202/lua-studio/releases/latest) · [Wiki](https://github.com/Raffi1202/lua-studio/tree/main/wiki)

**Jet** is an Ethos widget (full screen or compact view with the Ethos bars) for turbine jets on FrSky radios with a
colour display. It shows RPM, EGT, fuel, ECU battery and the ECU status as text, with two limits per value (warning
and alarm), voice announcements, fuel announcements in steps, shutdown detection with the reason, and a list of turbine
runs. Display, menu and voice are in German and English.

![Jet on 800 × 480 (Ethos simulator)](docs/bilder-simulator/Jet%20-%20Sim%20800x480%2004%20Normal.png)

- **Several brands:** JetCat with its own telemetry adapter (up to 4 engines), Xicoy TeleX, SportECU, and the VSpeak ECU
  converter for Kingtech, Swiwin, PBS, evoJet, Hornet/Behotec, Jakadofsky and JetCat. Jet detects the brand from the
  sensors, or you choose it in the menu. Jet reads the JetCat, Xicoy and SportECU values for which Ethos creates no
  sensors directly from the telemetry.
- **Shutdown with reason:** «Turbine off» and the reason («Flameout», «Out of fuel», «Battery low» …) when the turbine
  stops without the turbine-off switch or with an ECU error code.
- **Alarm also with turbine off** (new in 0.4.0): per value, on by default. ECU error codes and shutdown reasons always come.
- **Contradicting sources** (new in 0.4.0): a warning if the assigned sensor clearly differs from the ECU telemetry.
- **Lua-Studio:** a settings file per model (`scripts/studio/<id>.jet.lua`) places values freely (number, ring, bar,
  trend or status, symbols, own colours) and sets settings and limits. Without it Jet shows its built-in display.

**Status:** public pre-release (public beta). 0.4.0 is tested in the Ethos simulator (26.2.0); the transmitter test on
the X18RS follows. Earlier versions passed radio tests on an X18RS with simulated JetCat telemetry. **Never tested with
a real turbine ECU**: during your first runs rely on the GSU or ECU display, not on Jet's alarms. Use at your own risk.

## Quick start

1. Download `Jet-0.4.0.zip` from the latest [release](https://github.com/Raffi1202/jet-lua/releases).
2. Connect the radio via USB, choose **Ethos Suite** on the radio and open the **FrSky Suite** on the computer.
3. Suite › **Lua library** › **Install from local ZIP** › choose the ZIP. Restart the radio.
4. Model › Screens › **+** › layout **Full screen** (or with bars) › tap the box › widget **Jet**.
5. Switch on model and turbine: Jet assigns the sensors itself. Then set **tank size** and **ECU battery** in the
   widget menu under **Turbine**.

Full instructions: [`docs/Jet - Manual.pdf`](docs/Jet%20-%20Manual.pdf) (German: [`docs/Jet - Anleitung.pdf`](docs/Jet%20-%20Anleitung.pdf))
and the [wiki](wiki/Home.md). Testers: please follow [`TESTLEITFADEN.md`](TESTLEITFADEN.md) (German, English summary at the
end) and report problems via *Issues*.

## Radios

All radios with Ethos 26.2 and a colour display (800 × 480, 640 × 360, 480 × 320, 480 × 272). Tested on a real radio
only on the X18RS; other display sizes only in the simulator. Jet needs about 144 KB of Lua memory, with a Studio file
about 100–115 KB more; after switching to a model without Jet about 5 KB stay (simulator).

## Development

Not needed for testers. The tests need Lua 5.4, the Ethos simulator (plugin «ethos-tools», Ethos 26.2 or later) and
helper scripts of the developer (random test, simulator driver, PDF and package build) that are not in this repo.
Without them you can check the syntax: `luac5.4 -p src/jet/*.lua`.

## Related projects

| Project | What it does |
|---|---|
| [Elektro](https://github.com/Raffi1202/elektro-lua) | Ethos widget for electric models |
| [Heli RF](https://github.com/Raffi1202/heli-lua) | Ethos widget for Rotorflight helicopters |
| [Segler](https://github.com/Raffi1202/segler-lua) | Ethos widget for gliders (vario, thermals) |
| [Motoren ECU / Vergaser](https://github.com/Raffi1202/motoren-lua) | Ethos widgets for gas engines |
| [Lua-Studio](https://github.com/Raffi1202/lua-studio) | PC app to set up the widgets (Mac/Windows) |
| [Telemetry simulator](https://github.com/Raffi1202/telemetrie-simulator) | ESP32-S3 that simulates FrSky telemetry sensors |
| [Ethos model converter](https://github.com/Raffi1202/ethos-modell-konverter) | Move models between Ethos radios |
| [Ethos sensor IDs](https://github.com/Raffi1202/ethos-sensor-ids) | Which sensor Ethos creates for each AppID |

## License

GPL-3.0, see [LICENSE](LICENSE). The module `src/jet/studio_symbole.lua` comes from Lua-Studio (same author, same
license). The test symbols in `test/studio/symbole/` are partly based on Tabler Icons (MIT, © Paweł Kuna), license text there.
