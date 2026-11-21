-- Jet: Sensoren automatisch zuweisen (Vorgaben Sensorzuordnung, 20.11.2026; Muster Elektro).
-- Füllt nur leere Felder; was von Hand gesetzt ist, bleibt.
-- Stufe 1, Kennung: AppID + Teilwert -> Schlüssel (kennung.lua, gemeinsame Tabelle, dazu die Turbinen-AppIDs
--   unten in TURBINE, die Ethos nicht selbst anlegt). Je Feld eine Rangfolge von Schlüsseln; der erste Schlüssel,
--   zu dem es einen Sensor gibt, gewinnt. Passen mehrere Sensoren: zuerst der mit gültigem Wert, dann die
--   niedrigste Instanz, dann die niedrigste Physical ID. Dazu ein Hinweis «n Sensoren passen» im Menü.
-- Stufe 2, nur für Sensoren ohne Kennung: Name und Einheit als Rückfall.
-- Ethos begrenzt die Befehle je Aufruf: Die Suche läuft in Schritten über mehrere wakeup-Aufrufe (w.suchJob).
-- Rückgabe: nil = läuft noch (wieder aufrufen), sonst die Zahl der neu zugewiesenen Felder (fertig).
local JE_AUFRUF = 10   -- Sensoren lesen je Aufruf
local JE_REGEL = 25    -- Sensoren je Aufruf in der Rückfallstufe

-- Turbinen-AppIDs (Konzept Fassung 2, «Sensoren je Hersteller»): JetCat Slave 1, Xicoy TeleX, SportECU
local TURBINE = {
  { 0x5000, 0x5000, nil, "jc_hoehe" }, { 0x5001, 0x5001, nil, "jc_pumpe" }, { 0x5002, 0x5002, nil, "jc_strom" },
  { 0x5004, 0x5004, nil, "jc_status" }, { 0x5005, 0x5005, nil, "jc_ml" }, { 0x5006, 0x5006, nil, "jc_fluss" },
  { 0x5007, 0x5007, nil, "jc_schub" }, { 0x5008, 0x5008, nil, "jc_soll" }, { 0x5009, 0x5009, nil, "jc_speed" },
  { 0x500A, 0x500A, nil, "jc_welle" },
  { 0x4400, 0x4400, nil, "xc_egt" }, { 0x4401, 0x4401, nil, "xc_rpm" }, { 0x4402, 0x4402, nil, "xc_gas" },
  { 0x4403, 0x4403, nil, "xc_ecu" }, { 0x4404, 0x4404, nil, "xc_pumpe" }, { 0x4405, 0x4405, nil, "xc_proz" },
  { 0x4406, 0x4406, nil, "xc_status" },
  { 0x0A10, 0x0A10, nil, "se_ml" },
}

-- Rangfolge der Schlüssel je Feld. «kraftstoff» (0x0600) ist bei JetCat Rest %, beim VSpeak-Converter ml und bei
-- Betaflight/INAV verbrauchte mAh: entschieden wird nach den übrigen Sensoren (siehe unten).
local RANG = {
  rpm = { "xc_rpm", "rpm" }, soll = { "jc_soll" }, egt = { "xc_egt", "temp1" },
  ecu = { "akku_u", "xc_ecu", "adc3" }, pumpe = { "jc_pumpe", "xc_pumpe", "adc4" },
  status = { "jc_status", "xc_status", "temp2" }, ml = { "jc_ml", "se_ml", "kraftstoff_ml" },
  proz = { "xc_proz", "kraftstoff_proz" }, fluss = { "jc_fluss" }, schub = { "jc_schub" },
  hoehe = { "jc_hoehe", "hoehe", "gps_hoehe", "d_hoehe" }, speed = { "jc_speed", "airspeed", "gps_speed" },
  welle = { "jc_welle" }, strom = { "strom", "jc_strom" }, gasQ = { "xc_gas" },
  rssi = { "rssi", "rx_rssi1", "d_rssi" }, rx = { "rx_batt", "rx_batt1" },
}
-- Turbinenwerte: bei gleicher AppID auf mehreren Physical IDs gewinnt die Turbinen-ID 0x1B (JetCat Slave 1,
-- Xicoy, SportECU, VSpeak ab Werk; Sendertest 20.11.2026: Testgeräte auf 0x04/0x05/0x06 wurden sonst gewählt).
local TURB = { rpm = true, soll = true, egt = true, ecu = true, pumpe = true, status = true, ml = true, proz = true,
  fluss = true, schub = true, welle = true, strom = true, gasQ = true }
local PHYS_TURBINE = 0x1B
-- Allgemeine AppIDs, die andere Geräte anders nutzen: nur von 0x1B nehmen (Temp2 ist sonst eine Temperatur)
local NUR_1B = { temp2 = true }
local FOLGE = { "rpm", "soll", "egt", "ecu", "pumpe", "status", "ml", "proz", "fluss", "schub", "hoehe", "speed",
  "welle", "strom", "gasQ", "rssi", "rx" }

-- Rückfall (Stufe 2): Namensteile, Ausschluss (gilt für Namensteil und Einheit), Einheit
local REGELN = {
  { feld = "rpm", teile = { "rpm" }, ohne = { "set", "soll", "shaft", "welle" }, einheit = UNIT_RPM },
  { feld = "egt", teile = { "egt", "tmp1" }, ohne = {}, einheit = UNIT_CELSIUS },
  { feld = "status", teile = { "stat", "tmp2" }, ohne = {} },
  { feld = "ecu", teile = { "ecu", "vbat", "a3" }, ohne = { "rx" } },
  { feld = "pumpe", teile = { "pump", "a4" }, ohne = {} },
  { feld = "ml", teile = { "restfuel", "fuel ml" }, ohne = {} },
  { feld = "proz", teile = { "fuel" }, ohne = { "flow", "qual", "rest", "ml" } },
  { feld = "rssi", teile = { "rssi", "1rss" }, ohne = {} },
  { feld = "rx", teile = { "rxbt", "rx batt", "rx volt" }, ohne = {} },
}

local function rufe(q, f)
  if type(q[f]) ~= "function" then return nil end
  local okf, v = pcall(q[f], q)
  if okf then return v end
  return nil
end

local function hat(name, teile)
  for _, m in ipairs(teile) do
    if name:find(m, 1, true) then return true end
  end
  return false
end

-- Passt die Art eines Schlüssels zur Einheit des Sensors? (nur für Sensoren ohne Teilwert)
local function passt(key, e)
  if e == nil then return false end
  if key:find("_u$") or key:find("batt") then return e == UNIT_VOLT end
  if key:find("_i$") or key:find("strom") then return e == UNIT_AMPERE end
  if key:find("mah") then return e == UNIT_MILLIAMPERE_HOUR end
  if key:find("rpm") then return e == UNIT_RPM end
  if key:find("temp") then return e == UNIT_CELSIUS end
  return false
end

local function hex(x)
  if type(x) ~= "number" or x ~= x or x < 0 or x > 65535 then return "?" end
  return string.format("%04X", math.floor(x))
end

-- Bereich einer AppID im Index: einzelne IDs unter 0x0100 und ab 0xF000, sonst der 16er-Block
local function bereich(id)
  if id < 0x0100 or id >= 0xF000 then return id end
  return id - id % 16
end

-- Start: Sensorliste holen, kennung.lua laden und indizieren (eine Liste von Einträgen je Bereich)
local function start(w)
  local J = { schritt = "lesen", i = 0, S = {}, nach = {}, n = 0, regel = 0 }
  w.suchHinweis = {}
  J.neu = w.suche == "neu"     -- Turbinenfelder neu zuordnen (nach dem Lesen, nur wo es Ersatz auf 0x1B gibt)
  if system.getSources and CATEGORY_TELEMETRY_SENSOR then
    local ok, liste = pcall(system.getSources, CATEGORY_TELEMETRY_SENSOR)
    if ok and type(liste) == "table" then J.liste = liste end
  end
  J.liste = J.liste or {}
  J.schritt, J.index, J.k = "laden", {}, 0      -- Kennung laden und indizieren in eigenen Aufrufen (Befehlsgrenze)
  return J
end

-- Kennung laden (ein Aufruf), dann den Index in Stücken bauen (je Aufruf JE_INDEX Einträge)
local JE_INDEX = 60
local function index(J)
  if J.K == nil then
    local okK, K = pcall(function() local f = loadfile("kennung.lua") return f and f() end)
    if not (okK and type(K) == "table") then K = {} end
    for _, k in ipairs(TURBINE) do K[#K + 1] = k end
    J.K = K
    return false
  end
  local bis = math.min(#J.K, J.k + JE_INDEX)
  for i = J.k + 1, bis do
    local k = J.K[i]
    if type(k[1]) == "number" then
      local b = bereich(k[1])
      local l = J.index[b] or {}
      l[#l + 1] = k
      J.index[b] = l
    end
  end
  J.k = bis
  if bis >= #J.K then J.K = nil return true end
  return false
end

-- Schlüssel eines Sensors über den Index
local function schluessel(J, s)
  if type(s.id) ~= "number" or s.id ~= s.id or s.id < 0 or s.id > 65535 then return nil end
  local l = J.index[bereich(math.floor(s.id))]
  if l == nil then return nil end
  local erster = nil
  for _, k in ipairs(l) do
    if s.id >= k[1] and s.id <= k[2] then
      if type(s.teil) == "number" then
        if k[3] == nil or k[3] == s.teil then return k[4] end
      else
        -- Ohne Teilwert (gemessen 26.2: per Lua angelegte Sensoren liefern subId = nil): den Eintrag nehmen,
        -- dessen Art zur Einheit passt; sonst den ersten (Teilwert 0).
        erster = erster or k[4]
        if passt(k[4], s.einheit) then return k[4] end
      end
    end
  end
  return erster
end

local function setze(J, c, feld, s)
  if c[feld] ~= nil or s.vergeben then return false end
  c[feld] = s.q
  s.vergeben = true
  J.n = J.n + 1
  return true
end

return function(w)
  local c = w.cfg
  local J = w.suchJob
  if J == nil then
    w.suchJob = start(w)
    return nil
  end

  if J.schritt == "laden" then
    if index(J) then J.schritt = "lesen" end
    return nil
  end

  if J.schritt == "lesen" then                       -- je Aufruf höchstens JE_AUFRUF Sensoren
    local bis = math.min(#J.liste, J.i + JE_AUFRUF)
    for i = J.i + 1, bis do
      local q = J.liste[i]
      local name = rufe(q, "name")
      local s = { q = q, name = type(name) == "string" and string.lower(name) or "", roh = type(name) == "string" and name or "?",
        id = rufe(q, "appId"), teil = rufe(q, "subId"), phys = rufe(q, "physId"), einheit = rufe(q, "unit") }
      local wert = rufe(q, "value")
      s.wert = type(wert) == "number" and wert == wert and wert ~= 0
      s.key = schluessel(J, s)
      if s.key == "kraftstoff" then J.kraft = true end
      J.S[#J.S + 1] = s
      if s.key then
        local l = J.nach[s.key] or {}
        l[#l + 1] = s
        J.nach[s.key] = l
      end
    end
    J.i = bis
    if J.i >= #J.liste then
      J.schritt, J.index, J.liste = "kennung", nil, nil
      -- 0x0600: bei VSpeak (Status 0x0410 und Akku 0x0900, kein JetCat-Akku 0x0210) ml, sonst Kraftstoff %;
      -- verbrauchte mAh (Flugsteuerung) nie
      local vs = J.nach["temp2"] and J.nach["adc3"] and not J.nach["akku_u"]
      local l = J.nach["kraftstoff"]
      J.nach["kraftstoff"] = nil
      for _, s in ipairs(l or {}) do
        if s.einheit ~= UNIT_MILLIAMPERE_HOUR then
          s.key = (vs and s.einheit ~= UNIT_PERCENT) and "kraftstoff_ml" or "kraftstoff_proz"
          local m = J.nach[s.key] or {}
          m[#m + 1] = s
          J.nach[s.key] = m
        end
      end
    end
    return nil
  end

  if J.schritt == "kennung" and J.neu then
    -- Neu zuordnen: ein Turbinenfeld, dessen Sensor nicht auf 0x1B liegt, nur leeren, wenn es für dieses Feld einen
    -- Sensor auf 0x1B gibt (sonst bliebe es leer: keine Anzeige, keine Warnung)
    J.neu = nil
    -- Zuerst jedes zugewiesene Feld neu an den Sensor der aktuellen Liste binden (gleiche AppID, Teilwert, Physical
    -- ID und Name). Nach «Alle Sensoren löschen» + neu suchen liefern alte Verweise am Sender 0 statt nichts
    -- (Sendertest X18RS 20.11.2026: Empfang «0 dB», RX 0,0 V, Alarm). Ohne Gegenstück wird das Feld frei und neu zugewiesen.
    local function kenn(id, teil, phys, name)
      return tostring(id) .. ":" .. tostring(teil) .. ":" .. tostring(phys) .. ":" .. tostring(name)
    end
    local da = {}
    for _, s in ipairs(J.S) do da[kenn(s.id, s.teil, s.phys, s.roh)] = s end
    for _, f in ipairs(#J.S > 0 and FOLGE or {}) do   -- ohne Sensorliste nichts leeren (wie Elektro 0.3.2)
      local q = c[f]
      local kat = q ~= nil and rufe(q, "category") or nil
      if q ~= nil and (kat == nil or kat == CATEGORY_TELEMETRY_SENSOR or (CATEGORY_NONE ~= nil and kat == CATEGORY_NONE)) then
        local name = rufe(q, "name")
        local s = da[kenn(rufe(q, "appId"), rufe(q, "subId"), rufe(q, "physId"), type(name) == "string" and name or "?")]
        c[f] = s and s.q or nil
      end
    end
    for f in pairs(TURB) do
      local q = c[f]
      if q ~= nil and rufe(q, "physId") ~= PHYS_TURBINE then
        local ersatz = false
        for _, key in ipairs(RANG[f]) do
          for _, s in ipairs(J.nach[key] or {}) do
            if s.phys == PHYS_TURBINE and s.q ~= q then ersatz = true break end
          end
          if ersatz then break end
        end
        if ersatz then c[f] = nil end
      end
    end
    return nil
  end

  if J.schritt == "kennung" then                     -- Stufe 1: Kennung mit Rangfolge (kleine Listen)
    local function vor(a, b, turb)
      if turb then                                                       -- Turbinenwert: zuerst 0x1B
        local a1, b1 = a.phys == PHYS_TURBINE, b.phys == PHYS_TURBINE
        if a1 ~= b1 then return a1 end
      end
      if a.wert ~= b.wert then return a.wert end                         -- (a) liefert gerade einen Wert
      local ia, ib = (a.id or 0) % 16, (b.id or 0) % 16
      if ia ~= ib then return ia < ib end                                -- (b) niedrigste Instanz
      return (a.phys or 99) < (b.phys or 99)                             -- (c) niedrigste Physical ID
    end
    -- Turbinenwerte: erst über die ganze Rangfolge nur Sensoren auf 0x1B, dann ohne diese Bedingung
    local function waehle(feld, nur1B)
      for _, key in ipairs(RANG[feld]) do
        local beste, anz = nil, 0
        for _, s in ipairs(J.nach[key] or {}) do
          if not s.vergeben and not (NUR_1B[key] and s.phys ~= PHYS_TURBINE) and not (nur1B and s.phys ~= PHYS_TURBINE) then
            anz = anz + 1
            if beste == nil or vor(s, beste, TURB[feld]) then beste = s end
          end
        end
        if beste then
          if setze(J, c, feld, beste) and anz > 1 then
            w.suchHinweis[feld] = { anz, beste.roh, beste.phys, hex(beste.id) }
          end
          return true
        end
      end
      return false
    end
    for _, feld in ipairs(FOLGE) do
      if c[feld] == nil then
        if not (TURB[feld] and waehle(feld, true)) then waehle(feld, false) end
      end
    end
    J.schritt, J.nach = "rueckfall", nil
    return nil
  end

  -- Stufe 2: Regel für Regel (erst alle Namensteile, dann alle Einheiten), je Aufruf höchstens JE_REGEL Sensoren,
  -- nur Sensoren ohne Kennung
  if J.regel == 0 then J.regel, J.pos = 1, 0 end
  local nr = J.regel
  if nr <= 2 * #REGELN then
    local r = REGELN[nr <= #REGELN and nr or nr - #REGELN]
    local nachName = nr <= #REGELN
    local fertig = c[r.feld] ~= nil or (not nachName and r.einheit == nil)
    if not fertig then
      local bis = math.min(#J.S, J.pos + JE_REGEL)
      for k = J.pos + 1, bis do
        local s = J.S[k]
        if not s.key and not s.vergeben and not hat(s.name, r.ohne)
          and ((nachName and hat(s.name, r.teile)) or ((not nachName) and s.einheit == r.einheit)) then
          setze(J, c, r.feld, s)
          fertig = true
          break
        end
      end
      J.pos = bis
      if J.pos >= #J.S then fertig = true end
    end
    if fertig then J.regel, J.pos = nr + 1, 0 end
    if J.regel <= 2 * #REGELN then return nil end
  end
  w.suchJob = nil
  return J.n
end
