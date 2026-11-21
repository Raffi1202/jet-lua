-- Jet: Prüfmakro (Simulator). Speist S.Port-Rahmen ein wie ein JetCat-Telemetrieadapter (Physical ID 0x1B),
-- eine zweite Turbine (0x0D) und ein fremdes Gerät mit gleicher Drehzahl-AppID (0x04).
local STATUS = 13
local DAUER = 6          -- s
local function frame(phys, app, v)
  simulator.injectSPortFrame({ module = 0, band = 0, rx = 0, physId = phys, primId = 0x10, appId = app, value = v })
end
local n = math.floor(DAUER / 0.1)
for _ = 1, n do
  frame(0x1B, 0xF101, 80)                  -- RSSI hält die Telemetrie wach
  frame(0x1B, 0x5004, STATUS & 0xFFFFFFFF) -- Status (negativ als 32 Bit)
  frame(0x1B, 0x5005, 1920)                -- Rest ml
  frame(0x1B, 0x5008, 98500)               -- Soll-Drehzahl
  frame(0x1B, 0x5001, 92)                  -- Pumpe 0,92 V
  frame(0x1B, 0x5006, 290)                 -- Fluss ml/min
  frame(0x1B, 0x5007, 1180)                -- Schub 118,0 N
  frame(0x0D, 0x510D, 97900)               -- Turbine 2: Drehzahl
  frame(0x0D, 0x510C, 728)                 -- Turbine 2: EGT
  frame(0x0D, 0x5104, 13)                  -- Turbine 2: Status
  frame(0x0D, 0x510E, 780)                 -- Turbine 2: ECU 7,80 V
  frame(0x0D, 0x5110, 61)                  -- Turbine 2: Kraftstoff %
  frame(0x04, 0x0500, 8000)                -- fremdes Gerät (Standard-ID, nicht im Lesebereich)
  frame(0x05, 0x5004, 99)                  -- fremdes Gerät im JetCat-Bereich auf falscher Physical ID: muss ignoriert werden
  simulator.sleep(0.1)
end
