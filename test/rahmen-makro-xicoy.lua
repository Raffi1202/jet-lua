-- Jet: Prüfmakro (Simulator). Speist S.Port-Rahmen ein wie ein Xicoy-TeleX-Adapter (Physical ID 0x1B, AppID
-- 0x4400–0x4406) und einen SportECU-Kraftstoffwert 0x0A10 von einem anderen Gerät auf falscher Physical ID.
local function frame(phys, app, v)
  simulator.injectSPortFrame({ module = 0, band = 0, rx = 0, physId = phys, primId = 0x10, appId = app, value = v })
end
for _ = 1, 60 do
  frame(0x1B, 0xF101, 80)
  frame(0x1B, 0x4400, 615)     -- EGT °C
  frame(0x1B, 0x4401, 112000)  -- Drehzahl
  frame(0x1B, 0x4402, 78)      -- Gas %
  frame(0x1B, 0x4403, 79)      -- ECU-Akku 7,9 V (Zehntel-Volt, Annahme)
  frame(0x1B, 0x4404, 9)       -- Pumpe 0,9 V
  frame(0x1B, 0x4405, 64)      -- Kraftstoff %
  frame(0x1B, 0x4406, 34)      -- Status 34 = «Läuft Vollgas»
  frame(0x06, 0x0A10, 500)     -- fremdes Gerät auf falscher Physical ID: muss ignoriert werden
  simulator.sleep(0.1)
end
