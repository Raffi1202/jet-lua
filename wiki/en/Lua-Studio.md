🇬🇧 English · [🇩🇪 Deutsch](../de/Lua-Studio.md)

# Lua-Studio

## Lua-Studio (settings file per model)

With the PC program **Lua-Studio** you design the display per model: for each field you choose the value, the style (number, ring, horizontal or vertical bar, trend, status), title, range, colours and an extra line (MIN, MAX or Ø over the run). From version 0.3.0 (Studio format 2) decorations are added (lines, frames, texts). Symbols and bold units existed from 0.3.0 to 0.5.6; since 0.6.0 they are removed. Files in the old format 1 still load. Settings and limits per model come on top. Lua-Studio creates the file `scripts/studio/modelname.jet.lua` on the SD card. The file name keeps only the letters A–Z and digits of the model name, everything else becomes `_` («Jet 1» becomes `Jet_1`); Lua-Studio works this out itself. Jet reads the file when the model is loaded.

> **Since 0.6.0 Jet shows no symbols** (decision 2026-11-22: less memory and processing time). Symbols in older Studio files are silently ignored; decorations (lines, frames, texts) stay.

- **Without this file** Jet works exactly as before, with no message.

- **By default** the view in Lua-Studio looks like Jet without a file: in full screen four gauges, STATUS and six fields (RUNS stays fixed at the bottom left and opens the run list), in the compact view four gauges, STATUS and seven fields including RUNS. Jet always draws the top bar itself.

- **With a file** its view applies only to the window size it was made for (e.g. full screen 800 × 480 or with bars 784 × 316), and in full screen only on page 1. For other sizes Jet draws its built-in display.

- **Safety stays fixed:** the file cannot change the shutdown logic. «Turbine off» with its reason comes also with SF «off», the top bar stays red until the turbine runs again, and limit alarms also apply with SF «off». Only per limit may the file deselect this (`beiMotorAus = false`, in Lua-Studio the tick «also with motor off»); in the menu it is called «Alarm also with turbine off». Error codes and shutdown reasons always come.

- **Limits** apply per value, whether and however it is shown. If a value is missing in the file, the factory limit applies. A limit is only switched off if the file says so explicitly (`aus = true`). If the direction does not fit the value, the factory limit applies as well, with a message. Limits also work for other sensors, channels or non-monitored values, at most 6 per model (limits on missing sensors count too); Jet drops further ones with a message.

- **If you change** tank, limits or other settings in the menu on the radio, Jet writes this to its own file `…jet.funke.lua`. The Lua-Studio file stays unchanged. Lua-Studio shows the differences and takes them over if you want.

- **Menu › Studio file › Reset:** with a file «Back to Studio settings» (your changes on the radio are deleted), without a file «Back to defaults» (factory settings and limits; sensors and runs stay). Both ask first.

- **Messages:** if the file is broken, too new or contains invalid entries, a hint shows in the header for 8 seconds (e.g. «Studio file broken - default»), then an orange «!» at the top right. Jet always keeps running, if in doubt with its built-in display.

- Jet also writes the file `…jet.info.json` with model name, radio, window sizes and sensor list. Only Lua-Studio reads it.

![Studio file full screen](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2051%20Studio-Datei.png)

Example of a Studio file, full screen 800 × 480 (German display)

![Studio file compact](../../docs/bilder-simulator/Jet%20-%20Sim%20784x316%2050%20Studio-Datei.png)

Example of a Studio file, compact 784 × 316 (German display)

---
[← Home](../Home.md) | [Previous](Alarms.md) | [Next →](FAQ.md)

## Finding the Studio layout (from 0.5.0)

- **Places:** Jet searches the Studio file in `SCRIPTS:/studio/`, `SD:/scripts/studio/` and `RADIO:/scripts/studio/`.
- **Any name:** if the file name does not match the model name, choose the file in the widget menu under **«Studio layout»** (list with the place in brackets). «automatic (model name)» takes `ModelName.jet.lua` as before. The menu choice wins.
- **Any window size:** without a view for exactly this size, Jet scales the most similar view and shows «Studio: view 800x480 adapted» for 5 seconds. Slots that get too small are shown as a number or left out.
- **Hint line:** if Jet shows the default display although there is a file, the reason is shown in the header (instead of the model name), e.g. «Studio: file faulty (…)» or «Studio: no matching view».

## One layout for all models (from 0.7.0)

- In Lua-Studio save the layout «For all models (Default)». It is then called `Standard.jet.lua` and lies in the same folder as the other Studio files.
- Jet takes the choice in the menu «Studio layout» first, then the model file (`ModelName.jet.lua`), then `Standard.jet.lua`.
- Changes on the radio stay per model.
- If a model is called «Standard», `Standard.jet.lua` counts as its own model file.
