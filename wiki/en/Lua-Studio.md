🇬🇧 English · [🇩🇪 Deutsch](../de/Lua-Studio.md)

# Lua-Studio

## Lua-Studio (settings file per model)

With the PC program **Lua-Studio** you design the display per model: for each field you choose the value, the style (number, ring, horizontal or vertical bar, trend, status), title, range, colours and an extra line (MIN, MAX or Ø over the run). From version 0.3.0 (Studio format 2) there are symbols too (e.g. turbine, impeller, tank, pump, temperature, battery), a bold unit and decoration (lines, frames). The symbols are images in `scripts/studio/symbole/`; if one is missing, Jet shows the place without it and reports «symbols missing». Files in the old format 1 still load. Settings and limits per model come on top. Lua-Studio creates the file `scripts/studio/modelname.jet.lua` on the SD card. The file name keeps only the letters A–Z and digits of the model name, everything else becomes `_` («Jet 1» becomes `Jet_1`); Lua-Studio works this out itself. Jet reads the file when the model is loaded.

- **Without this file** Jet works exactly as before, with no message.

- **By default** the view in Lua-Studio looks like Jet without a file: in full screen four gauges, STATUS and six fields (RUNS stays fixed at the bottom left and opens the run list), in the compact view four gauges, STATUS and seven fields including RUNS. Jet always draws the top bar itself.

- **With a file** its view applies only to the window size it was made for (e.g. full screen 800 × 480 or with bars 784 × 316), and in full screen only on page 1. For other sizes Jet draws its built-in display.

- **Safety stays fixed:** the file cannot change the shutdown logic. «Turbine off» with its reason comes also with SF «off», the top bar stays red until the turbine runs again, and limit alarms also apply with SF «off». Only per limit may the file deselect this (`beiMotorAus = false`, in Lua-Studio the tick «also with motor off»); in the menu it is called «Alarm also with turbine off». Error codes and shutdown reasons always come.

- **Limits** apply per value, whether and however it is shown. If a value is missing in the file, the factory limit applies. A limit is only switched off if the file says so explicitly (`aus = true`). If the direction does not fit the value, the factory limit applies as well, with a message. Limits also work for other sensors, channels or non-monitored values, at most 6 per model (limits on missing sensors count too); Jet drops further ones with a message.

- **If you change** tank, limits or other settings in the menu on the radio, Jet writes this to its own file `…jet.funke.lua`. The Lua-Studio file stays unchanged. Lua-Studio shows the differences and takes them over if you want.

- **Menu › Studio file › Reset:** with a file «Back to Studio settings» (your changes on the radio are deleted), without a file «Back to defaults» (factory settings and limits; sensors and runs stay). Both ask first.

- **Messages:** if the file is broken, too new or contains invalid entries, a band shows at the bottom for 8 seconds (e.g. «Studio file broken - default»), then an orange «!» at the top right. Jet always keeps running, if in doubt with its built-in display.

- Jet also writes the file `…jet.info.json` with model name, radio, window sizes and sensor list. Only Lua-Studio reads it.

![Studio file full screen](../../docs/bilder-simulator/Jet%20-%20Sim%20800x480%2051%20Studio-Datei.png)

Example of a Studio file, full screen 800 × 480 (German display)

![Studio file compact](../../docs/bilder-simulator/Jet%20-%20Sim%20784x316%2050%20Studio-Datei.png)

Example of a Studio file, compact 784 × 316 (German display)

---
[← Home](../Home.md) | [Previous](Alarms.md) | [Next →](FAQ.md)
