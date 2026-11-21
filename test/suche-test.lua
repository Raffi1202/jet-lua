-- Jet: Sensorzuordnung auf dem Mac mit nachgebildeten Ethos-Sensoren, Lage wie beim Sendertest 20.11.2026:
-- Testgeräte mit denselben AppIDs auf anderen Physical IDs (0x02, 0x04, 0x05, 0x06, 0x0E) und die Turbine auf 0x1B.
-- Aufruf (im Projektordner): /opt/homebrew/opt/lua@5.4/bin/lua test/suche-test.lua src/jet
local ordner = arg[1] or "src/jet"
local fehler = 0
local function pruef(bed, text) if not bed then fehler = fehler + 1 print("FEHLER: " .. text) end end
CATEGORY_TELEMETRY_SENSOR, UNIT_VOLT, UNIT_AMPERE, UNIT_MILLIAMPERE_HOUR, UNIT_PERCENT = 1, 1, 2, 3, 4
UNIT_RPM, UNIT_CELSIUS, UNIT_METER, UNIT_METER_PER_SECOND, UNIT_KPH = 5, 6, 7, 8, 9
local SENS = {}
system = { getSources = function() return SENS end }
local function sensor(name, id, teil, phys, einheit, wert)
  return { n = name, i = id, t = teil, p = phys, e = einheit, w = wert,
    name = function(s) return s.n end, appId = function(s) return s.i end, subId = function(s) return s.t end,
    physId = function(s) return s.p end, unit = function(s) return s.e end, value = function(s) return s.w end,
    category = function(s) return s.k or CATEGORY_TELEMETRY_SENSOR end }
end
local alt = loadfile
loadfile = function(p) return alt(ordner .. "/" .. p) end
local MAXBEF = 0
local function suche(w)
  local f = assert(loadfile("suche.lua"))()
  local n, k = nil, 0
  repeat
    local bef = 0
    debug.sethook(function() bef = bef + 1 end, "", 1)
    n = f(w)
    debug.sethook()
    if bef > MAXBEF then MAXBEF = bef end
    k = k + 1
  until n ~= nil or k > 500
  return n
end

-- Testgeräte (Motoren-/Elektro-Telemetrie des ESP)
local fremd = {
  rpm = sensor("Drehzahl", 0x0500, 0, 0x04, UNIT_RPM, 8000),
  temp = sensor("Temp1", 0x0400, 0, 0x05, UNIT_CELSIUS, 40),
  temp2 = sensor("Temp2", 0x0410, 0, 0x05, UNIT_CELSIUS, 35),
  fuel = sensor("Kraftstoff", 0x0600, 0, 0x06, UNIT_PERCENT, 1500),
  v02 = sensor("VFAS", 0x0210, 0, 0x02, UNIT_VOLT, 11.1),
  v0e = sensor("VFAS", 0x0210, 0, 0x0E, UNIT_VOLT, 22.2),
  adc4 = sensor("ADC4", 0x0910, 0, 0x04, UNIT_VOLT, 4.2),
}
-- JetCat auf 0x1B, von Ethos selbst angelegt
local jc = {
  rpm = sensor("Drehzahl", 0x0500, 0, 0x1B, UNIT_RPM, 98400),
  egt = sensor("Temp1", 0x0400, 0, 0x1B, UNIT_CELSIUS, 612),
  ecu = sensor("VFAS", 0x0210, 0, 0x1B, UNIT_VOLT, 7.9),
  proz = sensor("Kraftstoff", 0x0600, 0, 0x1B, UNIT_PERCENT, 64),
}
-- von «Sensoren anlegen» erzeugt (Lua-Sensoren haben keinen Teilwert)
local neu = {
  status = sensor("EngState1", 0x5004, nil, 0x1B, nil, 13),
  ml = sensor("EngRestFuel1", 0x5005, nil, 0x1B, nil, 1920),
  soll = sensor("EngSetRpm1", 0x5008, nil, 0x1B, UNIT_RPM, 98500),
  pumpe = sensor("EngPumpV1", 0x5001, nil, 0x1B, UNIT_VOLT, 0.92),
}
local function liste(...)
  local l = {}
  for _, t in ipairs({ ... }) do for _, s in pairs(t) do l[#l + 1] = s end end
  table.sort(l, function(a, b) return (a.p * 65536 + a.i) < (b.p * 65536 + b.i) end)   -- kleine Physical ID zuerst
  return l
end

-- 1. Erste automatische Suche: Turbinenwerte von 0x1B, Status nicht von Temp2 eines anderen Geräts
SENS = liste(fremd, jc)
local w = { cfg = {}, suche = "auto" }
suche(w)
local c = w.cfg
pruef(c.rpm == jc.rpm, "1: Drehzahl von 0x1B erwartet")
pruef(c.egt == jc.egt, "1: EGT von 0x1B erwartet")
pruef(c.ecu == jc.ecu, "1: ECU-Akku 0x0210 von 0x1B erwartet")
pruef(c.proz == jc.proz, "1: Kraftstoff % von 0x1B erwartet")
pruef(c.status == nil, "1: Status darf nicht Temp2 von 0x05 sein")

-- 2. Lage am Sender: falsch belegt (alte Suche), dann «Sensoren anlegen» -> Turbinenfelder neu zuordnen
local rssi = sensor("RSSI", 0xF101, 0, 0x00, nil, 80)
SENS = liste(fremd, jc, neu, { rssi })
w = { cfg = { rpm = fremd.rpm, egt = fremd.temp, ecu = fremd.v02, status = fremd.temp2, pumpe = fremd.adc4, proz = fremd.fuel,
  rssi = rssi }, suche = "neu" }
suche(w)
c = w.cfg
pruef(c.rpm == jc.rpm, "2: Drehzahl neu von 0x1B erwartet")
pruef(c.egt == jc.egt, "2: EGT neu von 0x1B erwartet")
pruef(c.ecu == jc.ecu, "2: ECU-Akku neu von 0x1B erwartet")
pruef(c.status == neu.status, "2: Status 0x5004 erwartet")
pruef(c.ml == neu.ml and c.soll == neu.soll and c.pumpe == neu.pumpe, "2: ml, Soll, Pumpe von den angelegten Sensoren erwartet")
pruef(c.proz == jc.proz, "2: Kraftstoff % von 0x1B erwartet")
pruef(c.rssi == rssi, "2: Nicht-Turbinenfeld mit gültigem Sensor muss bleiben")

-- 2c. «Alle Sensoren löschen» + neu suchen, dann Neu zuordnen (Sendertest X18RS 20.11.2026): alte Verweise
-- (nicht mehr in der Liste, Wert 0) werden durch die neuen Sensoren ersetzt; eine Quelle ausserhalb der Telemetrie bleibt.
local altRssi = sensor("RSSI", 0xF101, 0, 0x00, nil, 0)
local altRx = sensor("RxBatt", 0xF104, 0, 0x00, UNIT_VOLT, 0)
altRssi.name = function() return nil end
local neuRssi = sensor("RSSI", 0xF101, 0, 0x00, nil, 80)
local neuRx = sensor("RxBatt", 0xF104, 0, 0x00, UNIT_VOLT, 5.1)
local gas = sensor("Gas", 0, 0, 0, nil, 50)
gas.k = 99
SENS = liste(jc, { neuRssi, neuRx })
w = { cfg = { rssi = altRssi, rx = altRx, rpm = jc.rpm, gasQ = gas }, suche = "neu" }
suche(w)
pruef(w.cfg.rssi == neuRssi, "2c: Empfang muss auf den neuen Sensor wechseln")
pruef(w.cfg.rx == neuRx, "2c: RX-Akku muss auf den neuen Sensor wechseln")
pruef(w.cfg.rpm == jc.rpm, "2c: gültige Drehzahl muss bleiben")
pruef(w.cfg.gasQ == gas, "2c: Quelle ausserhalb der Telemetrie muss bleiben")

-- 2b. Neu zuordnen ohne Ersatz auf 0x1B: Feld bleibt belegt (nie leer machen)
local eigen = sensor("Mein Akku", 0x0210, 0, 0x02, UNIT_VOLT, 7.6)
SENS = { eigen, fremd.rpm }
w = { cfg = { ecu = eigen, rpm = fremd.rpm }, suche = "neu" }
suche(w)
pruef(w.cfg.ecu == eigen and w.cfg.rpm == fremd.rpm, "2b: ohne Sensor auf 0x1B darf nichts geleert werden")

-- 3. Normale Suche lässt Belegtes stehen (von Hand gesetzt bleibt)
w = { cfg = { rpm = fremd.rpm }, suche = "menue" }
suche(w)
pruef(w.cfg.rpm == fremd.rpm, "3: von Hand gesetzte Drehzahl muss bleiben")

-- 4. Xicoy: ECU-Akku 0x4403 auf 0x1B vor fremder VFAS 0x0210 auf 0x02 (Vorrang 0x1B über die ganze Rangfolge)
local xcEcu = sensor("VBAT", 0x4403, nil, 0x1B, UNIT_VOLT, 7.4)
SENS = { fremd.v02, xcEcu }
w = { cfg = {}, suche = "auto" }
suche(w)
pruef(w.cfg.ecu == xcEcu, "4: Xicoy-VBAT auf 0x1B vor fremder VFAS erwartet")

-- 5. JetCat-Strom 0x5002 auf 0x1B vor fremdem FAS-Strom 0x0200 auf 0x02
local fas, jcI = sensor("Strom", 0x0200, 0, 0x02, UNIT_AMPERE, 30), sensor("EngCurrent1", 0x5002, nil, 0x1B, UNIT_AMPERE, 1.2)
SENS = { fas, jcI }
w = { cfg = {}, suche = "auto" }
suche(w)
pruef(w.cfg.strom == jcI, "5: JetCat-Strom auf 0x1B vor fremdem FAS erwartet")

-- 6. Viele Sensoren (80): Befehlsgrenze
local viele = liste(fremd, jc, neu)
for i = 1, 66 do viele[#viele + 1] = sensor("Sensor " .. i, 0x0500 + (i % 16), 0, i % 27, UNIT_RPM, i) end
SENS = viele
w = { cfg = {}, suche = "auto" }
suche(w)
pruef(w.cfg.rpm == jc.rpm, "6: auch mit 80 Sensoren Drehzahl von 0x1B")

-- 7. Update von 0.1.0: Datei ohne Formatnummer -> einmal neu zuordnen, alte RX-Grenzen 7,40/7,00 V aus
local DATEI = "# Jet: Einstellungen\nrxW=740\nrxA=700\negtW=720\nd_laeufe=3.00\n"
io = { open = function(_, m) if m == "w" then return nil end
  local gelesen = false
  return { read = function() if gelesen then return nil end gelesen = true return DATEI end, close = function() end } end }
model = { path = function() return "models/test.bin" end, name = function() return "TEST" end }
storage = nil
local F = assert(loadfile("felder.lua"))()
w = { name = "Jet" }
F.lies(w)
pruef(w.update010 == true, "7: Datei ohne dver muss als 0.1.0 erkannt werden")
pruef(w.cfg.rxW == 0 and w.cfg.rxA == 0, "7: alte RX-Grenzen 740/700 müssen 0 werden")
pruef(w.cfg.egtW == 720 and w.dauer.laeufe == 3, "7: übrige Werte bleiben")
DATEI = ""
w = { name = "Jet" }
F.lies(w)
pruef(w.update010 == nil, "7: leere Datei ist kein Update von 0.1.0")
DATEI = "# Jet\ndver=2\nrxW=740\nrxA=700\n"
w = { name = "Jet" }
F.lies(w)
pruef(w.update010 == nil and w.cfg.rxW == 740, "7: ab 0.1.1 gesetzte RX-Grenzen bleiben")

print(string.format("meiste Befehle in einem Aufruf: %d (Grenze am Sender 5000)", MAXBEF))
pruef(MAXBEF < 5000, "zu viele Befehle in einem Aufruf")
print(fehler == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehler .. " Fehler"))
