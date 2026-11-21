-- Jet: Prüfmakro (Simulator) für «widersprüchliche Quellen» (Entscheid des Users 21.11.2026). JetCat-Rahmen auf
-- 0x1B mit EGT 650 °C (0x500C). Den Wert des zugewiesenen Temperatursensors setzt der Lauf über TEST.sv, weil der
-- Simulator aus eingespeisten Rahmen keine Sensoren anlegt (gemessen 21.11.2026: Sensorliste leer).
-- Lauf 48: Sensor 420 °C (Abweichung 230 °C, Warnung); Lauf 49: Sensor 640 °C (in der Spanne, keine Warnung).
local DAUER = 8          -- s
local function frame(phys, app, v)
  simulator.injectSPortFrame({ module = 0, band = 0, rx = 0, physId = phys, primId = 0x10, appId = app, value = v })
end
for _ = 1, math.floor(DAUER / 0.1) do
  frame(0x1B, 0xF101, 80)                  -- RSSI hält die Telemetrie wach
  frame(0x1B, 0x5004, 13)                  -- Status: läuft
  frame(0x1B, 0x500D, 98400)               -- Drehzahl
  frame(0x1B, 0x500C, 650)                 -- EGT aus der ECU
  frame(0x1B, 0x5005, 1920)                -- Rest ml
  simulator.sleep(0.1)
end
