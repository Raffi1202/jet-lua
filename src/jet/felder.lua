-- Jet: Liste aller Einstellungen (für Menü, Werkwerte und Speicher). Wird nur bei Bedarf geladen und wieder
-- freigegeben. Eine Einstellung steht nur hier: Menü, Prüfung und Speichern richten sich nach dieser Liste.
-- Art: q = Quelle (Sensor, Kanal, Schalter), z = Zahl, b = Ja/Nein, w = Auswahl, t = eigener Text.
-- Jeder Text steht in zwei Sprachen: { "deutsch", "english" }. Ein einfacher Text gilt für beide.
-- q: { name, "q", Text }
-- z: { name, "z", Text, Werkwert, min, max, Kommastellen, Einheit, Schritt }. Zahlen mit Kommastellen sind als ganze
--    Zahl gespeichert (Kommastellen 2: 740 bedeutet 7,40).
-- b: { name, "b", Text, Werkwert }
-- w: { name, "w", Text, Werkwert, { { "Text", 1 }, { "Text", 2 } } }
-- t: { name, "t", Text, Werkwert }  (höchstens 12 Zeichen)
-- Grenzwerte: 0 = aus. Werkwerte nach dem freigegebenen Konzept Fassung 2 (20.11.2026).
local M = {}

-- Inhalte der Tachos und Felder (Nummern bleiben für immer gleich, sie stehen in der Datei)
local INHALT = {
  { { "leer", "empty" }, 0 }, { { "Drehzahl", "RPM" }, 1 }, { "EGT", 2 }, { { "Kraftstoff %", "Fuel %" }, 3 },
  { { "ECU-Akku", "ECU battery" }, 4 }, { "Status", 5 }, { { "Kraftstofffluss", "Fuel flow" }, 6 },
  { { "Pumpe", "Pump" }, 7 }, { { "Schub", "Thrust" }, 8 }, { { "Höhe", "Altitude" }, 9 }, { "Speed", 10 },
  { { "Empfang", "Signal" }, 11 }, { { "Gas %", "Throttle %" }, 12 }, { { "Welle", "Shaft RPM" }, 13 },
  { { "ECU-Strom", "ECU current" }, 14 }, { { "Laufzeit", "Run time" }, 15 }, { { "Kraftstoff ml", "Fuel ml" }, 16 },
  { { "Empfängerakku", "Receiver battery" }, 17 },
}
M.INHALT = INHALT

M.gruppen = {
  { { "Sensoren", "Sensors" }, {
    { "rpm", "q", { "Drehzahl", "RPM" } },
    { "soll", "q", { "Soll-Drehzahl", "Set RPM" } },
    { "egt", "q", "EGT" },
    { "ecu", "q", { "ECU-Akku", "ECU battery" } },
    { "pumpe", "q", { "Pumpe", "Pump" } },
    { "status", "q", "Status" },
    { "ml", "q", { "Kraftstoff ml", "Fuel ml" } },
    { "proz", "q", { "Kraftstoff %", "Fuel %" } },
    { "fluss", "q", { "Kraftstofffluss", "Fuel flow" } },
    { "schub", "q", { "Schub", "Thrust" } },
    { "hoehe", "q", { "Höhe", "Altitude" } },
    { "speed", "q", { "Geschwindigkeit", "Speed" } },
    { "welle", "q", { "Wellen-Drehzahl", "Shaft RPM" } },
    { "strom", "q", { "ECU-Strom", "ECU current" } },
    { "gasQ", "q", { "Gas % (Sensor)", "Throttle % (sensor)" } },
    { "rssi", "q", "RSSI" },
    { "rx", "q", { "Empfängerakku", "Receiver battery" } },
  } },
  { { "Hersteller", "Manufacturer" }, {
    { "hersteller", "w", { "Hersteller", "Manufacturer" }, 0,
      { { { "automatisch", "automatic" }, 0 }, { "JetCat", 1 }, { "Xicoy", 2 }, { "SportECU", 3 },
        { { "VSpeak-Converter", "VSpeak converter" }, 4 }, { { "von Hand", "manual" }, 5 } } },
    { "vsEcu", "w", { "ECU am VSpeak", "ECU at VSpeak" }, 0,
      { { { "nicht gewählt", "not selected" }, 0 }, { "Kingtech", 1 }, { "Swiwin", 2 }, { "PBS", 3 }, { "evoJet", 4 },
        { { "Hornet/Behotec", "Hornet/Behotec" }, 5 }, { "Jakadofsky", 6 }, { "JetCat", 7 } } },
    { "kraftArt", "w", { "Kraftstoff ml ist", "Fuel ml is" }, 0,
      { { { "nach Hersteller", "by manufacturer" }, 0 }, { { "Rest im Tank", "remaining" }, 1 }, { { "verbraucht", "used" }, 2 } } },
    { "rpmFaktor", "w", { "Drehzahl mal", "RPM times" }, 1, { { "1", 1 }, { "10", 10 }, { "100", 100 } } },
    { "sportHornet", "b", { "SportECU: Hornet-Texte", "SportECU: Hornet texts" }, false },
  } },
  { { "Turbine", "Turbine" }, {
    { "tank", "z", { "Tankgrösse", "Tank size" }, 0, 0, 50000, 0, " ml", 50 },
    { "ecuArt", "w", { "ECU-Akkuart", "ECU battery type" }, 1,
      { { "LiPo", 1 }, { "LiFe", 2 }, { "Li-Ion", 3 }, { "NiMH", 4 } } },
    { "ecuZellen", "z", { "ECU-Akku Zellen", "ECU battery cells" }, 2, 1, 6, 0, " S" },
    { "leerlauf", "z", { "Leerlauf ab", "Idle from" }, 10000, 500, 200000, 0, " U/min", 500 },
    { "flugMin", "z", { "Lauf zählt ab", "Run counts from" }, 30, 0, 600, 0, " s", 5 },
  } },
  { { "Grenzwerte (0 = aus)", "Limits (0 = off)" }, {
    { "egtW", "z", { "EGT Warnung über", "EGT warn above" }, 720, 0, 1200, 0, " °C", 5 },
    { "egtA", "z", { "EGT Alarm über", "EGT alarm above" }, 750, 0, 1200, 0, " °C", 5 },
    { "kraftW", "z", { "Kraftstoff Warnung unter", "Fuel warn below" }, 30, 0, 100, 0, " %" },
    { "kraftA", "z", { "Kraftstoff Alarm unter", "Fuel alarm below" }, 20, 0, 100, 0, " %" },
    { "ecuW", "z", { "ECU-Zelle Warnung unter", "ECU cell warn below" }, 370, 0, 450, 2, " V", 5 },
    { "ecuA", "z", { "ECU-Zelle Alarm unter", "ECU cell alarm below" }, 350, 0, 450, 2, " V", 5 },
    { "rxW", "z", { "RX-Akku Warnung unter", "RX batt warn below" }, 0, 0, 2000, 2, " V", 10 },
    { "rxA", "z", { "RX-Akku Alarm unter", "RX batt alarm below" }, 0, 0, 2000, 2, " V", 10 },
    { "rssiW", "z", { "RSSI Warnung unter", "RSSI warning below" }, 45, 0, 120, 0, " dB" },
    { "rssiA", "z", { "RSSI Alarm unter", "RSSI alarm below" }, 40, 0, 120, 0, " dB" },
    { "hoeheW", "z", { "Höhe Warnung über", "Altitude warn above" }, 110, 0, 5000, 0, " m" },
    { "hoeheA", "z", { "Höhe Alarm über", "Altitude alarm above" }, 120, 0, 5000, 0, " m" },
    { "speedW", "z", { "Speed Warnung über", "Speed warn above" }, 0, 0, 1500, 0, " km/h", 10 },
    { "speedA", "z", { "Speed Alarm über", "Speed alarm above" }, 0, 0, 1500, 0, " km/h", 10 },
  } },
  { { "Schalter", "Switches" }, {
    { "swAus", "q", { "Turbine aus bei", "Turbine off at" } },
    { "swAnsage", "q", { "Ansage bei", "Announce at" } },
    { "sw1", "q", { "Schalter 1", "Switch 1" } },
    { "sw1Name", "t", { "Schalter 1 Name", "Switch 1 name" }, "STABI" },
    { "sw2", "q", { "Schalter 2", "Switch 2" } },
    { "sw2Name", "t", { "Schalter 2 Name", "Switch 2 name" }, "FAHRWERK" },
    { "gas", "q", { "Gaskanal", "Throttle channel" } },
    -- 0.7.1: Gas Reverse (Vollgas = Knüppel hinten): Gas % = 100 − Gas % des Kanals (Werk aus)
    { "gasInv", "b", { "Gas umkehren", "Reverse throttle" }, false },
  } },
  { { "Ansagen", "Announcements" }, {
    { "ansage", "b", { "Alarme ansagen", "Announce alarms" }, true },
    { "warnAnsage", "b", { "Warnung auch ansagen", "Announce warnings too" }, false },
    { "wdh", "z", { "Alarm wiederholen alle", "Repeat alarm every" }, 10, 3, 300, 0, " s" },
    { "kraftStufen", "b", { "Kraftstoff in Stufen", "Fuel in steps" }, true },
    { "laufAns", "b", { "«Turbine läuft/aus»", "«Turbine running/off»" }, true },
    { "sgKraft", "b", { "Ansage: Kraftstoff", "Announce: fuel" }, true },
    { "sgZeit", "b", { "Ansage: Laufzeit", "Announce: run time" }, true },
    { "sgHoehe", "b", { "Ansage: Höhe", "Announce: altitude" }, false },
    { "ton", "b", { "Ton bei Alarm", "Tone on alarm" }, true },
    { "vibration", "b", { "Vibration bei Alarm", "Vibration on alarm" }, false },
  } },
  { { "Felder", "Fields" }, {
    { "t1", "w", { "Tacho 1", "Gauge 1" }, 1, INHALT },
    { "t2", "w", { "Tacho 2", "Gauge 2" }, 2, INHALT },
    { "t3", "w", { "Tacho 3", "Gauge 3" }, 3, INHALT },
    { "t4", "w", { "Tacho 4", "Gauge 4" }, 4, INHALT },
    { "f1", "w", { "Feld 1", "Field 1" }, 6, INHALT },
    { "f2", "w", { "Feld 2", "Field 2" }, 7, INHALT },
    { "f3", "w", { "Feld 3", "Field 3" }, 8, INHALT },
    { "f4", "w", { "Feld 4", "Field 4" }, 9, INHALT },
    { "f5", "w", { "Feld 5", "Field 5" }, 10, INHALT },
    { "f6", "w", { "Feld 6", "Field 6" }, 11, INHALT },
    { "maxRpm", "z", { "Tacho Drehzahl bis (0 = auto)", "RPM gauge up to (0 = auto)" }, 0, 0, 300000, 0, "", 1000 },
  } },
  -- «Alarm auch bei Turbine aus» je überwachtem Wert (Lua-Studio-Format 2 §3.5, Schlüssel beiMotorAus): ohne Haken
  -- schweigt dieser Grenzwert-Alarm, solange der Schalter «Turbine aus» auf aus steht. Fehlercodes und
  -- Abschaltgründe kommen immer. Das Menü setzt oben einen Schalter «alle» davor.
  { { "Alarm auch bei Turbine aus", "Alarm also with turbine off" }, {
    { "egtMA", "b", "EGT", true },
    { "kraftMA", "b", { "Kraftstoff", "Fuel" }, true },
    { "ecuMA", "b", { "ECU-Akku", "ECU battery" }, true },
    { "rxMA", "b", { "Empfängerakku", "Receiver battery" }, true },
    { "rssiMA", "b", "RSSI", true },
    { "hoeheMA", "b", { "Höhe", "Altitude" }, true },
    { "speedMA", "b", "Speed", true },
  } },
  { { "Anzeige", "Display" }, {
    { "sprache", "w", "Sprache / Language", 0,
      { { { "wie der Sender", "as the radio" }, 0 }, { "Deutsch", 1 }, { "English", 2 } } },
  } },
}

-- Werkwerte der ECU-Zellen-Schwellen je Akkuart (Warnung, Alarm in 1/100 V je Zelle) und Bogen leer/voll je Zelle
M.ECU_WERK = { { 370, 350 }, { 310, 300 }, { 340, 320 }, { 115, 110 } }
M.ECU_LEER_VOLL = { { 3.3, 4.2 }, { 2.8, 3.6 }, { 2.8, 4.2 }, { 1.0, 1.4 } }

-- Text in der Sprache sp (1 = Deutsch, 2 = English).
function M.text(t, sp)
  if type(t) == "table" then return t[sp] or t[1] end
  return t
end

-- Eigener Text (Schalternamen): nur Buchstaben, Ziffern, Leerzeichen, Punkt, Bindestrich, Umlaute; höchstens
-- 12 Zeichen. Sonst nil.
function M.eigen(v)
  if type(v) ~= "string" then return nil end
  v = v:gsub("[^%w %.%-\195\164\195\182\195\188\195\132\195\150\195\156]", ""):gsub("^%s+", ""):gsub("%s+$", "")
  if #v > 24 then v = v:sub(1, 24) end
  while #v > 0 and #v > 12 do
    v = v:sub(1, #v - 1)
    while #v > 0 and v:byte(#v) >= 128 and v:byte(#v) < 192 do v = v:sub(1, #v - 1) end   -- kein halbes Zeichen
    if #v > 0 and v:byte(#v) >= 192 then v = v:sub(1, #v - 1) end
  end
  if v == "" then return nil end
  return v
end

-- Reihenfolge im Speicher. Ethos speichert Quellen nach Reihenfolge, nicht nach Namen:
-- neue Einstellungen kommen immer ANS ENDE dieser Liste, nie dazwischen. Jede Einstellung aus M.gruppen steht hier.
M.folge = {
  "rpm", "soll", "egt", "ecu", "pumpe", "status", "ml", "proz", "fluss", "schub", "hoehe", "speed", "welle", "strom",
  "gasQ", "rssi", "rx", "swAus", "swAnsage", "sw1", "sw2", "gas",
  "hersteller", "vsEcu", "kraftArt", "rpmFaktor", "sportHornet",
  "tank", "ecuArt", "ecuZellen", "leerlauf", "flugMin",
  "egtW", "egtA", "kraftW", "kraftA", "ecuW", "ecuA", "rxW", "rxA", "rssiW", "rssiA", "hoeheW", "hoeheA", "speedW", "speedA",
  "sw1Name", "sw2Name",
  "ansage", "warnAnsage", "wdh", "kraftStufen", "laufAns", "sgKraft", "sgZeit", "sgHoehe", "ton", "vibration",
  "t1", "t2", "t3", "t4", "f1", "f2", "f3", "f4", "f5", "f6", "maxRpm",
  "sprache",
  "egtMA", "kraftMA", "ecuMA", "rxMA", "rssiMA", "hoeheMA", "speedMA", "gasInv",
}

-- Speicherformat der Quellen im Widget-Speicher: Nummer -> Zahl der Quellen in diesem Format.
-- Kommt eine Quelle dazu: ans Ende von M.folge, FORMAT um eins erhöhen und hier eine Zeile anfügen. Alte Formate
-- bleiben stehen, damit ein Update die Zuweisungen behält (Lehre Motoren ECU 1.2.0, 19.11.2026).
-- FORMAT 2 (0.5.0): nach den Quellen folgt die im Menü gewählte Studio-Datei (Pfad, "" = automatisch).
M.FORMAT = 2
M.FORMATE = { [1] = 22, [2] = 22 }
-- Format der Datei daten/<Modell>.txt: 2 ab 0.1.1 (0.1.0 schrieb keine Nummer)
M.DVER = 2

-- Feld zu einem Namen (Verzeichnis einmal aufbauen: Ethos begrenzt die Befehle je Aufruf).
local INDEX = nil
function M.feld(name)
  if INDEX == nil then
    INDEX = {}
    for _, g in ipairs(M.gruppen) do
      for _, f in ipairs(g[2]) do INDEX[f[1]] = f end
    end
  end
  return INDEX[name]
end

-- Darf das Studio diese Einstellung setzen? (Lua-Studio-Format v1, studio/beschreibung.json): keine Quellen, keine
-- Grenzwerte und kein «auch bei Turbine aus» (die kommen über «grenzen»), keine Belegung der Tachos und Felder (die kommt über «ansichten»).
local STUDIO_GRUPPE = nil
function M.studioEinstellung(name)
  if STUDIO_GRUPPE == nil then
    STUDIO_GRUPPE = {}
    for gi, g in ipairs(M.gruppen) do
      local gname = type(g[1]) == "table" and g[1][1] or g[1]
      if gname ~= "Sensoren" and gname ~= "Felder" and gname:sub(1, 10) ~= "Grenzwerte" and gname:sub(1, 5) ~= "Alarm" then
        for _, f in ipairs(g[2]) do
          if f[2] ~= "q" then STUDIO_GRUPPE[f[1]] = true end
        end
      end
    end
  end
  return STUDIO_GRUPPE[name] == true
end

function M.standard()
  local c = {}
  for _, g in ipairs(M.gruppen) do
    for _, f in ipairs(g[2]) do
      if f[2] ~= "q" then c[f[1]] = f[4] end
    end
  end
  return c
end

local function istQuelle(v)
  local t = type(v)
  if not (t == "userdata" or (t == "table" and type(v.value) == "function")) then return false end
  if CATEGORY_NONE then
    local ok, k = pcall(v.category, v)
    if ok and k == CATEGORY_NONE then return false end
  end
  return true
end
M.istQuelle = istQuelle

-- Gespeicherten Wert prüfen; passt er nicht, gilt der Wert ab Werk.
local function pruefe(f, v)
  local art = f[2]
  if art == "q" then
    if istQuelle(v) then return v end
    return nil
  elseif art == "b" then
    if type(v) == "boolean" then return v end
  elseif art == "z" then
    if type(v) == "number" and v == v and v >= f[5] and v <= f[6] then return math.floor(v) end
  elseif art == "t" then
    return M.eigen(v) or f[4]
  elseif art == "w" then
    if type(v) == "number" then
      for _, a in ipairs(f[5]) do
        if a[2] == v then return v end
      end
    end
  end
  return f[4]
end
M.pruefe = pruefe

local function quellen()
  local r = {}
  for _, name in ipairs(M.folge) do
    local f = M.feld(name)
    if f and f[2] == "q" then r[#r + 1] = name end
  end
  return r
end
M.quellen = quellen

-- Dateiname zum aktuellen Modell (Ordner und Name, nur Buchstaben, Ziffern, _ und -).
function M.datei()
  local ok, p = pcall(model.path)
  if not ok or type(p) ~= "string" or p == "" then
    local ok2, n = pcall(model.name)
    p = (ok2 and type(n) == "string" and n ~= "") and n or "modell"
  end
  p = p:gsub("%.bin$", ""):gsub("[^%w%-]", "_")
  return "daten/" .. p .. ".txt"
end

-- Datei ganz lesen (Ethos liest nur in Stücken), höchstens 12 KB.
local function liesDatei(pfad)
  local ok, f = pcall(io.open, pfad, "r")
  if not ok or not f then return nil end
  local teile, n = {}, 0
  while n < 12288 do
    local ok2, s = pcall(f.read, f, 512)
    if not ok2 or type(s) ~= "string" or s == "" then break end
    teile[#teile + 1] = s
    n = n + #s
  end
  pcall(f.close, f)
  return table.concat(teile)
end

-- Lauf als Zeile: 1 Nr, 2 Dauer s, 3 verbraucht ml, 4 Höchst-EGT, 5 Höchst-Drehzahl, 6 Kraftstoff % am Ende,
-- 7 höchste Höhe, 8 Höchst-Speed, 9 tiefster ECU-Akku, 10 Ende (0 normal, 1 SF aus, 2 Abschaltung),
-- 11 Statuscode beim Ende, 12 Statustabelle, 13 Zahl der Turbinen. Fehlende Werte bleiben leer.
M.FLUG_N = 13
local FORM = { "%.0f", "%.0f", "%.0f", "%.0f", "%.0f", "%.0f", "%.0f", "%.0f", "%.2f", "%.0f", "%.0f", "%.0f", "%.0f" }
local MAX_FLUEGE = 20
M.MAX_FLUEGE = MAX_FLUEGE

local function zeile(r)
  local e = {}
  for i = 1, M.FLUG_N do
    local x = r[i]
    e[i] = (type(x) == "number" and x == x and x > -1e7 and x < 1e7) and string.format(FORM[i], x) or ""
  end
  return table.concat(e, ",")
end

local function flug(d)
  local r, i = {}, 0
  for teil in (d .. ","):gmatch("([^,]*),") do
    i = i + 1
    if i <= M.FLUG_N then
      local x = tonumber(teil)
      if x and x == x and x > -1e7 and x < 1e7 then r[i] = x end
    end
  end
  if r[1] and r[1] >= 1 then
    r[1] = math.floor(r[1])
    return r
  end
  return nil
end

-- Einstellungen lesen. Gibt true zurück, wenn schon etwas gespeichert war (sonst läuft die automatische Suche).
function M.lies(w)
  local c = M.standard()
  w.cfg = c
  w.studioWahl = ""
  local gefunden = false
  -- Quellen aus dem Widget-Speicher, in jedem bekannten Format
  if storage and storage.read then
    local function hol(name)
      local ok, v = pcall(storage.read, name)
      if ok then return v end
      return nil
    end
    local q = quellen()
    local fmt = hol("fmt")
    local anz = type(fmt) == "number" and M.FORMATE[fmt] or nil
    if anz then
      local werte = {}
      for i = 1, anz do werte[i] = hol("q" .. i) end
      local wahl = fmt >= 2 and hol("wahl") or ""
      if hol("ende") == fmt then
        w.studioWahl = (type(wahl) == "string" and #wahl <= 120) and wahl or ""
        gefunden = true
        for i, name in ipairs(q) do
          if i <= anz then c[name] = istQuelle(werte[i]) and werte[i] or nil end
        end
      else
        print(tostring(w.name) .. ": gespeicherte Sensoren unlesbar, bitte neu zuweisen")
      end
    end
  end
  -- Zahlen, dauerhafte Werte und Läufe aus der Datei
  local text = liesDatei(M.datei())
  w.dauer, w.liste, w.offen = {}, {}, nil
  if text then
    gefunden = true
    local dver = tonumber(text:match("dver%s*=%s*(%d+)") or "")
    if dver == nil and text:match("[%w_]+%s*=") then   -- Datei von 0.1.0 (eine leere Datei zählt nicht)
      w.update010 = true
      if text:match("rxW%s*=%s*740") and text:match("rxA%s*=%s*700") then
        text = text:gsub("rxW%s*=%s*740", "rxW=0"):gsub("rxA%s*=%s*700", "rxA=0")   -- alte Werkgrenzen RX-Akku: jetzt aus
      end
    end
    for z in text:gmatch("[^\r\n]+") do
      local k, v = z:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
      if k == "f" then
        local r = flug(v)
        if r and #w.liste < MAX_FLUEGE then w.liste[#w.liste + 1] = r end
      elseif k == "a" then
        w.offen = flug(v)
      elseif k and k:sub(1, 2) == "d_" then
        local x = tonumber(v)
        if x and x == x and x > -1e7 and x < 1e7 then w.dauer[k:sub(3)] = x end
      elseif k then
        local f = M.feld(k)
        if f and f[2] == "b" then
          c[k] = pruefe(f, v == "1")
        elseif f and f[2] == "t" then
          c[k] = pruefe(f, v)
        elseif f and (f[2] == "z" or f[2] == "w") then
          c[k] = pruefe(f, tonumber(v))
        end
      end
    end
  end
  return gefunden
end

-- Quellen in den Widget-Speicher (Ethos ruft das beim Speichern des Modells auf).
function M.schreibe(w)
  if not (storage and storage.write) then return end
  local c = w.cfg
  local q = quellen()
  pcall(storage.write, "fmt", M.FORMAT)
  for i, name in ipairs(q) do
    local v = c[name]
    pcall(storage.write, "q" .. i, istQuelle(v) and v or 0)
  end
  pcall(storage.write, "wahl", type(w.studioWahl) == "string" and w.studioWahl or "")
  pcall(storage.write, "ende", M.FORMAT)
end

-- Zahlen, dauerhafte Werte und Läufe in die Datei. Gibt true zurück, wenn geschrieben.
function M.schreibeDatei(w)
  local c = w.cfg
  local z = { "# " .. tostring(w.name) .. ": Einstellungen, Zähler und Läufe dieses Modells", "dver=" .. M.DVER }
  for _, name in ipairs(M.folge) do
    local f = M.feld(name)
    local v = c[name]
    if f and f[2] == "b" then
      z[#z + 1] = name .. "=" .. (v and "1" or "0")
    elseif f and f[2] == "t" then
      local e = M.eigen(v)
      if e then z[#z + 1] = name .. "=" .. e end
    elseif f and f[2] ~= "q" and type(v) == "number" then
      z[#z + 1] = name .. "=" .. string.format("%d", math.floor(v))
    end
  end
  local namen = {}
  for k, x in pairs(w.dauer or {}) do
    if type(k) == "string" and type(x) == "number" and x == x then namen[#namen + 1] = k end
  end
  table.sort(namen)
  for _, k in ipairs(namen) do z[#z + 1] = "d_" .. k .. "=" .. string.format("%.2f", w.dauer[k]) end
  for _, r in ipairs(w.liste or {}) do z[#z + 1] = "f=" .. zeile(r) end
  if w.akt and w.akt[1] then z[#z + 1] = "a=" .. zeile(w.akt) end      -- offener Lauf geht beim Ausschalten nicht verloren
  if os and os.mkdir then pcall(os.mkdir, "daten") end
  local ok, f = pcall(io.open, M.datei(), "w")
  if not ok or not f then return false end
  local okw = pcall(f.write, f, table.concat(z, "\n") .. "\n")
  pcall(f.close, f)
  return okw
end

return M
