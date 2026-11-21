-- Jet: Kern des Widgets. Liest die gewählten Quellen, erkennt den Hersteller, deutet den Statuscode der ECU,
-- rechnet Kraftstoff, Läufe, Höchst- und Tiefstwerte, Warnungen und Ansagen und ruft die Seite zum Zeichnen.
-- Alles Rechnen passiert in wecke(), zeichne() zeichnet nur.
-- Absturzsicher: jeder Wert wird geprüft (nil, Text, NaN, unendlich, riesig), jede Ethos-Abfrage läuft in pcall.
local K = {}
local Z = nil          -- zeichnen.lua
local SEITE = {}       -- geladene Seite (immer nur die sichtbare)
local SEITEN = 3       -- 1 Anzeige, 2 Turbinen (nur bei 2–4 Turbinen), 3 Flugliste

-- Diagnose am Sender: true schreibt jeden Ansage-Schritt ins Lua-Log (getLog / Suite «Debug-Log»). Im Release false.
local DIAG = false
local function dbg(fmt, ...) if DIAG then pcall(function(...) print("JET " .. string.format("%.2f ", os.clock()) .. string.format(fmt, ...)) end, ...) end end
local TEST = nil  -- TESTHAKEN: der Simulator-Ablauf ersetzt genau diese Zeile (bauplan.md, Abschnitt Testhaken)
local SUCHE = nil    -- suche.lua, nur geladen, solange eine Suche läuft
local ZUSTAND = nil  -- testzustand.lua, nur geladen mit TEST.zustand im Simulator
local STUDIO = nil   -- studio.lua (Lua-Studio-Format v1): nur geladen, solange eine Studio-Datei gilt oder geladen wird
local WIDGETS = setmetatable({}, { __mode = "k" })   -- alle Instanzen des Widgets (schwach: entfernte fallen weg)
local ANSICHT = nil  -- ansicht.lua: zeichnet die Plätze einer Studio-Ansicht
local STUDIO_HINWEIS_S = 8   -- s: so lange steht ein Studio-Hinweis unten, danach bleibt oben rechts ein «!»

local DT_LESEN = 0.2   -- s: Werte lesen und rechnen
local DT_BILD = 0.2    -- s: Bild höchstens so oft auffrischen
local AN_S = 1.0       -- s: so lange muss eine Bedingung gelten, bis die Warnung kommt
local AUS_S = 3.0      -- s: so lange muss sie weg sein, bis die Warnung geht
local ANSAGE_ABSTAND = 3.0
-- Mehrteilige Ansagen laufen über eine Warteschlange (w.folge), ein Teil je Durchlauf: zwei playFile direkt
-- nacheinander spielen am Sender nur die erste Datei (Nachtest X18RS 20.11.2026). Pause nach einem Teil:
-- nur Datei («Turbine n aus» höchstens 1,25 s) bzw. Datei + Zahl («Kraftstoff 50 Prozent»).
local GRUND_PAUSE = 1.6
local ZAHL_PAUSE = 2.8
local DAUER_S = 60     -- s: laufenden Lauf höchstens so oft in die Datei schreiben
local STEHT_S = 5      -- s: so lange muss die Turbine stehen, bis der Lauf endet
local FLAMME_S = 2     -- s: Drehzahl so lange unter «Leerlauf ab» ohne Statuscode = Flammabriss
local STEHT_RPM = 1000 -- U/min: darunter steht die Turbine
local SLOP = 14        -- Pixel: ab hier gilt eine Bewegung als Wisch
local GROSS = 1e7      -- Werte darüber gelten als unplausibel
-- Glaubhafter Bereich je Messwert: was ausserhalb liegt, gilt als «kein Wert» (Strich).
local BEREICH = { rpm = { 0, 400000 }, soll = { 0, 400000 }, egt = { -60, 1300 }, ecu = { 0, 40 }, pumpe = { 0, 40 },
  status = { -200, 200 }, ml = { 0, 100000 }, proz = { 0, 100 }, fluss = { 0, 50000 }, schub = { 0, 10000 },
  hoehe = { -1000, 20000 }, speed = { 0, 1500 }, welle = { 0, 400000 }, strom = { -50, 500 }, gasS = { 0, 100 },
  rssi = { -150, 150 }, rx = { 0, 40 } }
local STUFEN = { 75, 50, 30, 10, 5 }          -- Kraftstoff-Ansagen (20 % meldet der Alarm «Kraftstoff Reserve»)
local GRUND_WAV = { "flammabriss", "kraftstoff_leer", "akku_tief", "uebertemperatur", "failsafe" }
-- Statustabelle je Hersteller (status.lua): JetCat 1, Xicoy 2; VSpeak nach der ECU dahinter
local VS_TAB = { 3, 4, 5, 6, 7, 8, 1 }        -- Kingtech, Swiwin, PBS, evoJet, Hornet, Jakadofsky, JetCat
local VS_ART = { 2, 0, 2, 2, 1, 2, 1 }        -- Kraftstoff ml: 1 Rest, 2 verbraucht, 0 unklar
-- Sammelalarme (nur 2 s): werden übergangen, der vorige Code bleibt stehen
local SAMMEL = { [1] = -40, [3] = -20 }

local floor, abs, max, min = math.floor, math.abs, math.max, math.min

local function lade(datei)
  local f, e = loadfile(datei)
  if not f then error(e, 0) end
  return f()
end

local function clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

-- Zahl prüfen: nil bei nil, Text, NaN, unendlich oder unplausibel gross.
local function gut(v)
  if type(v) ~= "number" or v ~= v or v > GROSS or v < -GROSS then return nil end
  return v
end

local function zahl(q)
  if q == nil then return nil end
  local ok, v = pcall(q.value, q)
  if not ok then return nil end
  return gut(v)
end

local function rufe(q, f)
  if q == nil or type(q[f]) ~= "function" then return nil end
  local ok, v = pcall(q[f], q)
  if ok then return v end
  return nil
end

local function bereich(q)
  local lo, hi = gut(rufe(q, "minimum")), gut(rufe(q, "maximum"))
  if lo and hi and hi > lo then return lo, hi end
  return nil
end

-- Schalterartige Quelle: aktiv = über der Mitte ihres Bereichs. nil = keine Quelle.
local function aktiv(q)
  local v = zahl(q)
  if v == nil then return nil end
  local lo, hi = bereich(q)
  return v > (lo and (lo + hi) / 2 or 0)
end

-- Stellung eines Kanals in Prozent 0 … 100 seines Bereichs (Gas unten = 0).
local function prozent(q)
  local v = zahl(q)
  if v == nil then return nil end
  local lo, hi = bereich(q)
  if lo == nil then lo, hi = -1024, 1024 end
  return clamp((v - lo) / (hi - lo) * 100, 0, 100)
end

local function stellen(q, sonst)
  local d = rufe(q, "decimals")
  if type(d) == "number" and d >= 0 and d <= 3 then return floor(d) end
  return sonst
end

-- Sprache: 1 = Deutsch, 2 = English. Einstellung 0 heisst «wie der Sender».
local SENDER = nil
local function sprache(w)
  local sp = w.cfg.sprache
  if sp ~= 1 and sp ~= 2 then
    if SENDER == nil then
      SENDER = 2
      if system.getLocale then
        local ok, l = pcall(system.getLocale)
        if ok and type(l) == "string" and l:sub(1, 2):lower() == "de" then SENDER = 1 end
      end
    end
    sp = SENDER
  end
  if w.sp ~= sp or w.T == nil then
    w.sp = sp
    w.T = lade("texte.lua")(sp)
    w.hinweis = nil
    w.stCache = {}                       -- Statustexte in der neuen Sprache neu holen
  end
end

-- Sprachdatei abspielen: audio/de/<name>.wav oder audio/en/<name>.wav. false, wenn die Datei fehlt.
local AUDIO_DA = {}
local function sage(w, name)
  if not system.playFile then return false end
  local pfad = "audio/" .. (w.sp == 1 and "de" or "en") .. "/" .. name .. ".wav"
  local da = AUDIO_DA[pfad]
  if da == nil then
    local ok, f = pcall(io.open, pfad, "r")
    da = (ok and f ~= nil) or false
    if da then pcall(f.close, f) end
    AUDIO_DA[pfad] = da
  end
  local okP, errP = true, nil
  if da then okP, errP = pcall(system.playFile, pfad) end
  dbg("sage %s da=%s play=%s %s", pfad, tostring(da), tostring(okP), tostring(errP))
  return da
end

local function zahlSagen(x, einh, dez)
  if x == nil or not system.playNumber then return end
  if (dez or 0) == 0 then x = floor(x + 0.5) end
  pcall(system.playNumber, x, einh or 0, dez or 0)
end

local function imBereich(k, x)
  local b = BEREICH[k]
  if x == nil or (b and (x < b[1] or x > b[2])) then return nil end
  return x
end

-- Grenzwerte aus den Einstellungen als Zahlen; nil = nicht gesetzt (Warnung aus).
local GRENZEN = { { "egt", 1 }, { "kraft", 1 }, { "rx", 100 }, { "rssi", 1 }, { "hoehe", 1 }, { "speed", 1 } }
local function grenzen(w)
  local c, g = w.cfg, w.g
  if TEST and TEST.cfg then
    for k, x in pairs(TEST.cfg) do c[k] = x end
  end
  for _, e in ipairs(GRENZEN) do
    local wn, al = gut(c[e[1] .. "W"]), gut(c[e[1] .. "A"])
    g[e[1] .. "W"] = (wn and wn > 0) and wn / e[2] or nil
    g[e[1] .. "A"] = (al and al > 0) and al / e[2] or nil
  end
  local n = max(1, gut(c.ecuZellen) or 2)
  local wn, al = gut(c.ecuW), gut(c.ecuA)
  g.ecuW = (wn and wn > 0) and wn / 100 * n or nil
  g.ecuA = (al and al > 0) and al / 100 * n or nil
  g.wdh = gut(c.wdh) or 10
  sprache(w)
end

-- Vorgabe des Schalter-Standards des Users: Turbine aus = SF oben, Ansage = SG unten (nur beim ersten Start).
-- Ethos findet Schalterstellungen nur über die Nummer (SF↑ = 15, SG↓ = 20, gemessen 26.2.0); der Name der
-- gefundenen Quelle wird verglichen und sonst in den ersten 60 Nummern gesucht.
local function schalterVorgabe(w)
  local function quelle(nr)
    if not CATEGORY_SWITCH_POSITION then return nil end
    local ok, s = pcall(system.getSource, { category = CATEGORY_SWITCH_POSITION, member = nr })
    if ok and s then return s end
    return nil
  end
  local function hol(soll, nr)
    local q = quelle(nr)
    if q and rufe(q, "name") == soll then return q end
    for k = 0, 59 do
      q = quelle(k)
      if q and rufe(q, "name") == soll then return q end
    end
    return nil
  end
  local c = w.cfg
  if c.swAus == nil then c.swAus = hol("SF\u{2191}", 15) end
  if c.swAnsage == nil then c.swAnsage = hol("SG\u{2193}", 20) end
  if c.swAus or c.swAnsage then
    w.dateiOffen = true
    if model and model.dirty then pcall(model.dirty) end   -- damit Ethos die Quellen im Widget-Speicher sichert
  end
end

function K.neu()
  dbg("Widget neu angelegt")
  local F = lade("felder.lua")
  local w = {
    cfg = F.standard(), g = {}, v = {}, st = {}, dz = {},
    meld = {}, aktiv = {}, nAktiv = 0, stufe = 0, zustand = "keine",
    seite = 1, ziele = {}, nZiele = 0, liste = {}, oben = 0,
    dauer = {},            -- dauerhafte Werte (Datei daten/<Modell>.txt): Laufzähler, Löschnummer im Menü
    tb = {},               -- Turbinen 1–4: { rpm, egt, proz, ecu, code, gruppe, text, ansage, war, ... }
    rahmen = { {}, {}, {}, {} },   -- selbst gelesene Rahmenwerte je Turbine (Wert und Zeitpunkt)
    leser = {},                    -- S.Port-Leser je AppID-Bereich (sport.getSensor)
    nTurb = 1, wechsel = {}, kDone = {}, stCache = {},
    gelesen = false, autoOffen = true, version = K.VERSION, name = K.NAME,
  }
  for i = 1, 4 do w.tb[i] = {} end
  WIDGETS[w] = true
  w.kern = K                                       -- für die Flugliste (Grund der Abschaltung als Text)
  w.FLUG_N, w.MAX_FLUEGE = F.FLUG_N, F.MAX_FLUEGE
  w.ECU_LEER_VOLL = F.ECU_LEER_VOLL
  grenzen(w)
  if CATEGORY_SYSTEM_EVENT and SYSTEM_EVENT_TELEMETRY_ACTIVE then
    local ok, q = pcall(system.getSource, { category = CATEGORY_SYSTEM_EVENT, member = SYSTEM_EVENT_TELEMETRY_ACTIVE })
    if ok then w.qTele = q end
  end
  if CATEGORY_SYSTEM and MAIN_VOLTAGE then
    local ok, q = pcall(system.getSource, { category = CATEGORY_SYSTEM, member = MAIN_VOLTAGE })
    if ok then w.qSender = q end
  end
  return w
end

local function telemetrie(w)
  local q = w.qTele
  if q == nil then return true end
  local ok, v = pcall(q.value, q)
  if not ok then return true end
  if type(v) == "number" then return v > 0 end
  if type(v) == "boolean" then return v end
  return true
end

local function hinweis(w, text, now)
  w.hinweis = text
  w.hinweisBis = now + 3
end

-- ---------------------------------------------------------------- Hersteller
-- Erkannt wird an den AppIDs der zugewiesenen Sensoren (Konzept Fassung 2, «Hersteller und Erkennung»).
local function appIds(w)
  local c, ids = w.cfg, {}
  for _, k in ipairs({ "rpm", "egt", "ecu", "pumpe", "status", "ml", "proz", "soll", "gasQ" }) do
    local id = gut(rufe(c[k], "appId"))
    if id then ids[floor(id)] = true end
  end
  return ids
end

local function erkennen(w)
  if w.tRahmenHerst and os.clock() - w.tRahmenHerst <= 10 then   -- Rahmen eines Herstellers empfangen: eindeutig
    w.erkannt = w.rahmenHerst
    return
  end
  local ids = appIds(w)
  local e = nil
  local jc = ids[0x0210] and ids[0x0500]               -- JetCat Slave 1: ECU-Akku 0x0210 zusammen mit 0x0500
  for id in pairs(ids) do
    if id >= 0x5000 and id <= 0x53FF then jc = true end
    if id >= 0x4400 and id <= 0x4406 then e = e or 2 end
  end
  if jc then e = 1
  elseif e == 2 then e = 2
  elseif ids[0x0A10] then e = 3
  elseif ids[0x0410] and ids[0x0600] then e = 4
  elseif ids[0x0410] and ids[0x0900] then e = 3 end
  w.erkannt = e
end

-- Hersteller, der gerade gilt: von Hand gewählt vor erkannt. 1 JetCat, 2 Xicoy, 3 SportECU, 4 VSpeak, 5 von Hand
local function hersteller(w)
  local h = w.cfg.hersteller
  if h and h >= 1 and h <= 5 then return h end
  return w.erkannt
end
K.hersteller = hersteller

local function tabelle(w)
  local h, c = hersteller(w), w.cfg
  if h == 1 or h == 2 then return h end
  if h == 3 then return c.sportHornet and 7 or nil end
  if h == 4 then return VS_TAB[c.vsEcu or 0] end
  return nil
end

-- Kraftstoff ml: 1 Rest im Tank, 2 verbraucht, nil unklar
local function kraftArt(w)
  local c, h = w.cfg, hersteller(w)
  if c.kraftArt == 1 or c.kraftArt == 2 then return c.kraftArt end
  if h == 1 or h == 3 or h == 5 then return 1 end
  if h == 4 then
    local a = VS_ART[c.vsEcu or 0]
    if a and a > 0 then return a end
  end
  return nil
end

-- Statuscode -> Text, Gruppe, Ansage (über status.lua, je Tabelle/Code/Sprache gemerkt)
local function statusText(w, tab, code)
  if tab == nil or code == nil then return nil end
  local key = tab * 1000 + code
  local e = w.stCache[key]
  if e == nil then
    local ok, f = pcall(lade, "status.lua")
    local t, g, a = nil, nil, nil
    if ok and type(f) == "function" then
      local ok2, t2, g2, a2 = pcall(f, tab, code, w.sp)
      if ok2 then t, g, a = t2, g2, a2 end
    end
    e = { t or false, g or false, a or false }
    w.stCache[key] = e
    collectgarbage()
  end
  return e[1] or nil, e[2] or nil, e[3] or nil
end
K.statusText = statusText

-- ---------------------------------------------------------------- Rahmen lesen (JetCat, Xicoy, SportECU)
-- Ethos legt für 0x5000–0x53FF, 0x4400–0x4406 und 0x0A10 keine Sensoren an, und per Lua angelegte DIY-Sensoren
-- bekommen am echten Sender keine Werte (X18RS, 20.11.2026, Befund Heli RF). Darum liest Jet diese S.Port-Rahmen
-- selbst (sport.getSensor + popFrame, wie Heli RF 1.9.1). Ein Wert gilt GILT_S Sekunden, danach gilt wieder ein
-- zugewiesener Sensor. Je Leser und Weckruf höchstens 16 Rahmen (Befehlsgrenze).
local GILT_S = 5
local LESER = { { 0x5000, 0x53FF }, { 0x4400, 0x440F }, { 0x0A10, 0x0A1F } }
-- JetCat: Parameter (AppID mod 0x100) -> Feld, Teiler (JetCat-PDF: Pumpe/Akku/Strom 0,01; Schub 0,1 N)
local JC = { [0x00] = { "hoehe", 1 }, [0x01] = { "pumpe", 100 }, [0x02] = { "strom", 100 }, [0x04] = { "status", 1 },
  [0x05] = { "ml", 1 }, [0x06] = { "fluss", 1 }, [0x07] = { "schub", 10 }, [0x08] = { "soll", 1 }, [0x09] = { "speed", 1 },
  [0x0A] = { "welle", 1 }, [0x0C] = { "egt", 1 }, [0x0D] = { "rpm", 1 }, [0x0E] = { "ecu", 100 }, [0x0F] = { "strom", 10 },
  [0x10] = { "proz", 1 } }
-- Xicoy TeleX: VBAT und PUMP in Zehntel-Volt angenommen (das Xicoy-Lua zeigt beide mit einer Kommastelle;
-- nicht belegt, am Sender zu prüfen)
local XC = { [0x4400] = { "egt", 1 }, [0x4401] = { "rpm", 1 }, [0x4402] = { "gasS", 1 }, [0x4403] = { "ecu", 10 },
  [0x4404] = { "pumpe", 10 }, [0x4405] = { "proz", 1 }, [0x4406] = { "status", 1 } }
local RAHMEN_FELDER = { "hoehe", "pumpe", "strom", "status", "ml", "fluss", "schub", "soll", "speed", "welle", "egt",
  "rpm", "ecu", "proz", "gasS" }
local SLAVE_F = { "rpm", "egt", "proz", "ecu", "status", "ml" }
-- Widerspruch Rahmen gegen zugewiesenen Sensor: Abweichung über max(fest, Anteil vom Rahmenwert), Rohwerte
-- (Drehzahl vor dem Faktor). Kurze Unterschiede beim Hoch- und Runterlaufen fängt melde (AN_S) und die Spanne ab.
local WIDERSPRUCH = { egt = { 50, 0.15 }, rpm = { 5000, 0.15 }, ecu = { 0.5, 0 }, proz = { 10, 0 } }

-- 32-Bit-Wert mit Vorzeichen (Statuscodes sind negativ)
local function signiert(x)
  if x >= 0x80000000 and x <= 0xFFFFFFFF then return x - 0x100000000 end
  return x
end

-- Physical ID eines Rahmens als 0 … 31 (manche Fassungen liefern das Leitungsbyte mit Prüfbits)
local PHYS_JC = { 0x1B, 0x0D, 0x14, 0x07 }       -- JetCat Slave 1–4 (JetCat-PDF: Poll 0x1B, 0x0D, 0x34, 0x67)
local PHYS_STD = 0x1B                            -- Xicoy TeleX und SportECU ab Werk
local MAX_RAHMEN = 16                            -- je Weckruf über alle Leser (Befehlsgrenze am Sender)

local function rahmenLesen(w, now)
  if sport == nil or sport.getSensor == nil then return end
  local L = w.leser
  -- Leser je Bereich einzeln holen und fehlende alle 5 s neu versuchen
  if now - (w.tLeser or -100) >= 5 then
    w.tLeser = now
    for i, b in ipairs(LESER) do
      if L[i] == nil then
        local ok, se = pcall(sport.getSensor, { appIdStart = b[1], appIdEnd = b[2] })
        if ok and se then L[i] = se end
      end
    end
  end
  local R = w.rahmen
  local gelesen, leer = 0, 0
  local i = w.leserNr or 1
  -- abwechselnd: je Leser ein Rahmen, bis MAX_RAHMEN gelesen oder alle Leser leer sind
  while gelesen < MAX_RAHMEN and leer < #LESER do
    i = i % #LESER + 1
    local se = L[i]
    local f = nil
    if se then
      local ok, fr = pcall(se.popFrame, se)
      if ok then f = fr end
    end
    if not f then
      leer = leer + 1
    else
      leer, gelesen = 0, gelesen + 1
      local a = gut(rufe(f, "appId"))
      local x = rufe(f, "value")
      x = type(x) == "number" and gut(signiert(x)) or nil   -- erst Vorzeichen, dann prüfen (−10 kommt als 4294967286)
      local p = gut(rufe(f, "physId"))
      p = p and floor(p) % 32 or nil
      if a and x then
        local feld, teil, t, herst, soll = nil, 1, 1, nil, PHYS_STD
        if a >= 0x5000 and a <= 0x53FF then
          local e = JC[a % 0x100]
          if e then
            feld, teil, t, herst = e[1], e[2], (a - 0x5000) // 0x100 + 1, 1
            soll = PHYS_JC[t]
          end
        elseif XC[a] then
          feld, teil, herst = XC[a][1], XC[a][2], 2
        elseif a == 0x0A10 then
          feld, herst = "ml", 3
        end
        -- nur von der Physical ID des Herstellers (ohne lesbare ID: annehmen) und nur glaubhafte Werte
        if feld and (p == nil or p == soll) then
          local wert = x / teil
          local bk = feld == "gasS" and "gasS" or feld
          if imBereich(bk, wert) ~= nil then
            local r = R[t]
            r[feld] = wert
            r[feld .. "_t"] = now
            w.rahmenHerst, w.tRahmenHerst = herst, now
          end
        end
      end
    end
  end
  w.leserNr = i
end

-- Frischer Rahmenwert der Turbine t, sonst nil
local function rw(w, t, feld, now)
  local r = w.rahmen[t]
  local tt = r[feld .. "_t"]
  if tt and now - tt <= GILT_S then return r[feld] end
  return nil
end

-- ---------------------------------------------------------------- Lesen
local function hoch(v, k, x) if x and (v[k] == nil or x > v[k]) then v[k] = x end end
local function tief(v, k, x) if x and (v[k] == nil or x < v[k]) then v[k] = x end end

-- Gruppe einer Turbine: aus dem Statuscode (Tabelle), sonst aus der Drehzahl.
local function gruppe(w, t)
  if t.gStatus then return t.gStatus end
  local r = t.rpm
  if r == nil then return t.code ~= nil and 1 or nil end
  if r >= (w.cfg.leerlauf or 10000) then return 3 end
  if r >= STEHT_RPM then return 2 end
  return 1
end

local function statusLesen(w, t, roh, tab, n, now)
  local code = roh and floor(roh + 0.5) or nil
  if code ~= nil and tab and SAMMEL[tab] == code then code = t.code end
  t.code = code
  t.text, t.gStatus, t.ansage = statusText(w, tab, code)
  if code ~= t.codeAlt then
    if code ~= nil then
      local T = w.T
      local text = t.text or string.format(T.code, tostring(code))
      if n > 1 then text = "T" .. n .. " " .. text end
      local l = w.wechsel
      l[#l + 1] = { w.akt and w.akt[2] or 0, text, t.gStatus or 0 }
      while #l > 5 do table.remove(l, 1) end
    end
    t.codeAlt = code
  end
end

local function lesen(w, now, dt)
  local c, v = w.cfg, w.v
  local tele = telemetrie(w)
  local testWerte = TEST and (TEST.v or TEST.ohne or TEST.tele ~= nil)
  if testWerte then tele = TEST.tele ~= false end
  v.tele = tele
  local function s(q) if tele then return zahl(q) end return nil end
  v.rpm, v.soll, v.egt, v.ecu, v.pumpe, v.status = s(c.rpm), s(c.soll), s(c.egt), s(c.ecu), s(c.pumpe), s(c.status)
  v.ml, v.proz, v.fluss, v.schub, v.hoehe, v.speed = s(c.ml), s(c.proz), s(c.fluss), s(c.schub), s(c.hoehe), s(c.speed)
  v.welle, v.strom, v.gasS, v.rssi, v.rx = s(c.welle), s(c.strom), s(c.gasQ), s(c.rssi), s(c.rx)
  v.aus, v.ansageSw, v.sw1, v.sw2 = aktiv(c.swAus), aktiv(c.swAnsage), aktiv(c.sw1), aktiv(c.sw2)
  v.gasP = prozent(c.gas)
  v.sender = zahl(w.qSender)
  -- Frische Rahmenwerte (JetCat, Xicoy, SportECU) gelten vor zugewiesenen Sensoren. Zeigt ein zugewiesener
  -- Sensor dabei deutlich anderes (z. B. Rahmen 500C gegen Temperatursensor 0400), wird das als Warnung angezeigt
  -- (Entscheid des Users 21.11.2026). Ist der Sensor derselbe Wert der ECU, sind beide gleich: keine Warnung.
  w.widersp = nil
  if TEST and TEST.sv then for k, x in pairs(TEST.sv) do v[k] = x end end   -- Simulator: Sensorwert ohne echten Sensor
  if tele then
    for _, k in ipairs(RAHMEN_FELDER) do
      local x = rw(w, 1, k, now)
      if x ~= nil then
        local tol = WIDERSPRUCH[k]
        if tol and w.widersp == nil and v[k] ~= nil and abs(v[k] - x) > max(tol[1], abs(x) * tol[2]) then w.widersp = k end
        v[k] = x
      end
    end
  end
  -- Turbinen 2–4 (JetCat-Slaves) nur aus Rahmen
  local nT = 1
  for t = 2, 4 do
    local tb = w.tb[t]
    for _, k in ipairs(SLAVE_F) do tb[k] = tele and rw(w, t, k, now) or nil end
    if tb.rpm or tb.egt or tb.status then nT = t end
  end
  w.nTurb = nT
  if testWerte then
    for k, x in pairs(TEST.v or {}) do v[k] = x end
    for _, k in ipairs(TEST.ohne or {}) do v[k] = nil end
    if TEST.turb then
      w.nTurb = #TEST.turb + 1
      for i, r in ipairs(TEST.turb) do
        local tb = w.tb[i + 1]
        tb.rpm, tb.egt, tb.proz, tb.ecu, tb.status, tb.ml = r[1], r[2], r[3], r[4], r[5], r[6]
      end
    end
    if not tele then
      for k in pairs(BEREICH) do v[k] = nil end
      for t = 2, 4 do local tb = w.tb[t] tb.rpm, tb.egt, tb.proz, tb.ecu, tb.status, tb.ml = nil, nil, nil, nil, nil, nil end
    end
  end
  for k in pairs(BEREICH) do v[k] = imBereich(k, v[k]) end
  local f = c.rpmFaktor or 1
  if v.rpm then v.rpm = v.rpm * f end
  if v.soll then v.soll = v.soll * f end
  if v.welle then v.welle = v.welle * f end
  -- dBm (negativ, ELRS/Crossfire): intern +120 wie ein positiver Wert (Schwellen, Balken), angezeigt wird dBm
  v.dbm = nil
  if v.rssi and v.rssi < 0 then v.rssi, v.dbm = v.rssi + 120, true end
  v.gas = v.gasS or v.gasP
  local h = hersteller(w)
  v.pumpePW = h == 4 and c.vsEcu == 1          -- Kingtech am VSpeak: Pumpe als Leistung «PW» (2,57 V = 257 PW)

  -- Kraftstoff: % von der ECU; sonst aus ml und Tankgrösse (Rest oder verbraucht)
  local tank = (c.tank or 0) > 0 and c.tank or nil
  local art = kraftArt(w)
  v.mlRest = nil
  if v.ml then
    if art == 1 then v.mlRest = v.ml elseif art == 2 and tank then v.mlRest = max(0, tank - v.ml) end
  end
  v.prozVon = v.proz and 1 or nil
  if v.proz == nil and v.mlRest and tank then v.proz, v.prozVon = clamp(v.mlRest / tank * 100, 0, 100), 2 end
  if v.mlRest == nil and v.proz and tank then v.mlRest = v.proz * tank / 100 end
  v.tankFehlt = tele and v.ml ~= nil and v.proz == nil and tank == nil

  -- Turbine 1 und die übrigen: Status und Gruppe
  local tab = tabelle(w)
  local t1 = w.tb[1]
  t1.rpm, t1.egt, t1.proz, t1.ecu = v.rpm, v.egt, v.proz, v.ecu
  statusLesen(w, t1, v.status, tab, 1, now)
  t1.gruppe = gruppe(w, t1)
  for t = 2, w.nTurb do
    local tb = w.tb[t]
    for _, k in ipairs({ "rpm", "egt", "proz", "ecu" }) do tb[k] = imBereich(k, tb[k]) end
    if tb.rpm then tb.rpm = tb.rpm * f end
    statusLesen(w, tb, imBereich("status", tb.status), 1, t, now)
    tb.gruppe = gruppe(w, tb)
  end
  -- Bei mehreren Turbinen gilt auf Seite 1 der kritischste Wert (höchste EGT, tiefster Kraftstoff, tiefster Akku)
  v.krit = nil
  if w.nTurb > 1 then
    v.krit = {}
    for t = 2, w.nTurb do
      local tb = w.tb[t]
      if tb.egt and (v.egt == nil or tb.egt > v.egt) then v.egt, v.krit.egt = tb.egt, t end
      if tb.proz and (v.proz == nil or tb.proz < v.proz) then v.proz, v.krit.proz = tb.proz, t end
      if tb.ecu and (v.ecu == nil or tb.ecu < v.ecu) then v.ecu, v.krit.ecu = tb.ecu, t end
    end
  end

  if tele then
    hoch(v, "egtHoch", v.egt) hoch(v, "rpmHoch", v.rpm) hoch(v, "sollHoch", v.soll)
    hoch(v, "pumpeHoch", v.pumpe) hoch(v, "schubHoch", v.schub) hoch(v, "hoeheHoch", v.hoehe)
    hoch(v, "speedHoch", v.speed) hoch(v, "welleHoch", v.welle)
    if v.ecu and v.ecu > 0.5 then tief(v, "ecuTief", v.ecu) end
    if v.rx and v.rx > 0.5 then tief(v, "rxTief", v.rx) end
    tief(v, "rssiTief", v.rssi)
  end
end

-- Einheiten, Modellname, Hersteller (alle 2 s).
local function liesEinheiten(w)
  local c = w.cfg
  w.dz.hoehe = stellen(c.hoehe, 0)
  local ok, n = pcall(model.name)
  w.modell = (ok and type(n) == "string" and n ~= "") and n or nil
  if TEST and TEST.modell then w.modell = TEST.modell end   -- neutraler Name für Testbilder (nichts von der Funke ins Repo)
  if TEST and TEST.erkannt then w.erkannt = TEST.erkannt else erkennen(w) end
end

-- ---------------------------------------------------------------- Warnungen
-- Eine Warnung führen: kommt nach AN_S, geht nach AUS_S (so flattert sie an der Grenze nicht).
-- ma == false («auch bei Turbine aus» abgewählt, Lua-Studio-Format 2 §3.5): solange der Schalter «Turbine aus» auf
-- aus steht, schweigt sie (kein Ton, keine Ansage, keine Vibration, Kopfleiste nicht gefärbt); der Wert selbst
-- behält seine Farbe. Nur für Grenzwerte; Fehlercodes und Abschaltgründe laufen nicht über melde.
local function melde(w, now, name, stufe, bed, wav, wert, einh, dez, ma)
  local m = w.meld[name]
  if m == nil then
    m = { an = false, name = name }
    w.meld[name] = m
  end
  if bed then
    m.weg = nil
    if not m.an then
      m.seit = m.seit or now
      if now - m.seit >= AN_S then
        m.an = true
        m.tAns = nil
      end
    end
  else
    m.seit = nil
    if m.an then
      m.weg = m.weg or now
      if now - m.weg >= AUS_S then m.an = false end
    end
  end
  local still = m.an and ma == false and w.v.aus
  if m.an and not still and m.still then m.tAns = nil end   -- Schalter wieder ein: Alarm sofort, nicht erst nach wdh
  m.still = still or nil
  if m.an and not still then
    m.stufe, m.wav, m.wert, m.einh, m.dez = stufe, wav, wert, einh, dez
    w.nAktiv = w.nAktiv + 1
    w.aktiv[w.nAktiv] = m
  end
  return m.an
end

-- Überwachte Werte: Name, Wert in w.v, true = Alarm unter der Schwelle, Ansage, Einheit, Kommastellen
local UEBERWACHT = {
  { "egt", "egt", false, "egt_hoch", "UNIT_CELSIUS", 0 },
  { "kraft", "proz", true, "kraftstoff_reserve", "UNIT_PERCENT", 0 },
  { "ecu", "ecu", true, "ecu_akku_tief", "UNIT_VOLT", 1 },
  { "rx", "rx", true, "empfaengerakku", "UNIT_VOLT", 1 },
  { "rssi", "rssi", true, "empfang", "UNIT_DB", 0 },
  { "hoehe", "hoehe", false, "hoehe", "UNIT_METER", 0 },
  { "speed", "speed", false, "speed", "UNIT_KPH", 0 },
}

local function warnungen(w, now)
  local v, g, st, c = w.v, w.g, w.st, w.cfg
  w.nAktiv = 0
  local d = v.tele
  for _, u in ipairs(UEBERWACHT) do
    local k, x = u[1], v[u[2]]
    local gw, ga = g[k .. "W"], g[k .. "A"]
    local function jenseits(gr) return gr ~= nil and x ~= nil and ((u[3] and x < gr) or ((not u[3]) and x > gr)) end
    local al = d and jenseits(ga) or false
    local einh = _ENV[u[5]] or 0
    local xs = (k == "rssi" and v.dbm and x) and x - 120 or x
    local wav = u[4]
    if w.studio and STUDIO and xs then                      -- Studio-Datei: angepassten Wert ansagen (6.4)
      local a = w.studio.werte["lua:" .. STUDIO.UEBERWACHT[k][1]]
      if a then xs = xs * a.faktor + a.versatz end
    end
    if k == "kraft" then xs = nil end                       -- «Kraftstoff Reserve» ohne Zahl
    local ma = c[k .. "MA"]
    local a = melde(w, now, k .. "A", 2, al, wav, xs, einh, u[6], ma)
    local wn = melde(w, now, k .. "W", 1, d and not al and jenseits(gw) or false, wav, xs, einh, u[6], ma)
    if x == nil or (gw == nil and ga == nil) then
      st[k] = nil
    else
      st[k] = a and 2 or ((wn or jenseits(gw)) and 1 or 0)
    end
  end
  -- Widerspruch Rahmen/Sensor (siehe lesen): Warnung nur zur Anzeige (Kopfleiste orange, Hinweis unten, alle 30 s
  -- wieder), ohne Ton und Ansage; erst wenn er 3 s besteht (2 s hier plus AN_S in melde).
  if w.widersp then w.widerspSeit = w.widerspSeit or now else w.widerspSeit = nil end
  if melde(w, now, "quelleW", 1, w.widersp ~= nil and now - w.widerspSeit >= 2, nil, nil, 0, 0) then
    w.widerspK = w.widersp or w.widerspK
    if now - (w.tWidersp or -100) >= 30 then
      w.tWidersp = now
      local T = w.T
      hinweis(w, string.format(T.widerspruch, T.wName and T.wName[w.widerspK] or tostring(w.widerspK)), now)
    end
  else
    w.tWidersp = nil
  end
  if w.studio and STUDIO then                    -- Grenzen der Studio-Datei für Sensoren, Kanäle, weitere Werte
    STUDIO.grenzenExtra(w, now, melde, d)
  end
  -- Ist der Alarm eines Werts an, fällt dessen Warnung weg
  local n = 0
  for i = 1, w.nAktiv do
    local m = w.aktiv[i]
    local alarm = m.stufe == 1 and w.meld[m.name:sub(1, -2) .. "A"]
    if not (alarm and alarm.an) then
      n = n + 1
      w.aktiv[n] = m
    end
  end
  w.nAktiv = n
  local stx = 0
  for i = 1, n do
    if w.aktiv[i].stufe > stx then stx = w.aktiv[i].stufe end
  end
  if w.absch then stx = 2 end                        -- Abschaltung (ohne SF oder mit Fehlercode): Kopf rot
  w.stufe = stx
  if stx == 2 then
    w.zustand = "alarm"
  elseif stx == 1 then
    w.zustand = "warnung"
  elseif not d then
    w.zustand = "keine"
  else
    w.zustand = "ok"
  end
end

-- ---------------------------------------------------------------- Läufe
-- Ein Lauf ist eine Liste (felder.lua): 1 Nr, 2 Dauer s, 3 verbraucht ml, 4 Höchst-EGT, 5 Höchst-Drehzahl,
-- 6 Kraftstoff % am Ende, 7 höchste Höhe, 8 Höchst-Speed, 9 tiefster ECU-Akku, 10 Ende (0 normal, 1 SF aus,
-- 2 Abschaltung), 11 Statuscode beim Ende, 12 Statustabelle, 13 Turbinen. Der laufende Lauf (w.akt) hat dazu
-- ml0 (Kraftstoff ml beim Start) und steht (Zeitpunkt, seit die Turbine steht).

local function laufEnde(w)
  local a = w.akt
  w.akt = nil
  w.tB = 0
  if a == nil or a[1] == nil then return end
  local r = {}
  for i = 1, w.FLUG_N do r[i] = a[i] end
  local l = w.liste
  l[#l + 1] = r
  while #l > w.MAX_FLUEGE do table.remove(l, 1) end
  w.dateiOffen, w.dateiJetzt = true, true
end

-- Einen Lauf löschen; der Zähler geht um eins zurück, spätere Nummern rücken nach (Muster heli-lua).
local function laufLoeschen(w, nr)
  nr = gut(nr)
  if nr == nil then return false end
  nr = floor(nr)
  local weg = false
  if w.akt and w.akt[1] == nr then
    w.akt, weg = nil, true
    w.laufSperre = true                       -- bis die Turbine steht, beginnt kein neuer Lauf
  else
    for i, r in ipairs(w.liste) do
      if r[1] == nr then
        table.remove(w.liste, i)
        weg = true
        break
      end
    end
  end
  w.wahl = nil
  if not weg then return false end
  w.dauer.laeufe = max(0, (w.dauer.laeufe or 0) - 1)
  for _, r in ipairs(w.liste) do
    if r[1] and r[1] > nr then r[1] = r[1] - 1 end
  end
  if w.akt and w.akt[1] and w.akt[1] > nr then w.akt[1] = w.akt[1] - 1 end
  w.dateiOffen, w.dateiJetzt = true, true
  return true
end

-- Abschaltungen und Ansagen «läuft/aus» je Turbine; Flammabriss auch ohne Statuscode über den Drehzahlabfall.
local function turbinen(w, now)
  local c, v = w.cfg, w.v
  if not v.tele then return end                  -- ohne Telemetrie nichts ändern: Lauf und Zustand bleiben stehen
  local leer = c.leerlauf or 10000
  local tab = tabelle(w)
  for n = 1, w.nTurb do
    local t = w.tb[n]
    local g = t.gruppe
    if g == 3 then
      t.lief, t.tUnter = true, nil
      if t.gAlt ~= 3 and c.laufAns and v.tele then
        local schon = false                           -- «Turbine läuft» nur, wenn noch keine andere läuft
        for m = 1, w.nTurb do if m ~= n and w.tb[m].lief then schon = true end end
        if not schon then w.offenLaeuft = true end
      end
    elseif t.lief and v.tele then
      -- Drehzahlabfall ohne Status: erst nach FLAMME_S als Flammabriss werten
      local ohneStatus = t.gStatus == nil
      local fall = ohneStatus and t.rpm ~= nil and t.rpm < leer
      if fall and not t.tUnter then t.tUnter, t.sfBeiAbfall = now, v.aus == true end   -- SF beim Beginn des Abfalls zählt
      local ende = (not ohneStatus) or (fall and now - t.tUnter >= FLAMME_S)
      if ende then
        t.lief, t.tUnter = false, nil
        -- Gewollt: normaler Stopp der ECU, oder SF auf «aus» ohne Fehlercode. Ein Fehlercode (Gruppe 4) ist immer eine
        -- Abschaltung mit Grund und Alarm, auch bei SF auf «aus» (Entscheid User 20.11.2026)
        local sfAus = v.aus == true
        if ohneStatus then sfAus = t.sfBeiAbfall == true end    -- SF erst nach dem Flammabriss umgelegt: trotzdem Alarm
        local gewollt = t.gStatus == 1 or (sfAus and t.gStatus ~= 4)
        if gewollt then
          if c.laufAns then w.offenAus = w.offenAus or {} w.offenAus[#w.offenAus + 1] = { n } end
          dbg("aus gewollt n=%d gStatus=%s code=%s aus=%s laufAns=%s", n, tostring(t.gStatus), tostring(t.code), tostring(v.aus), tostring(c.laufAns))
          t.ende = v.aus == true and 1 or 0
        else
          local a = t.gStatus == 4 and (t.ansage or 6) or (ohneStatus and 1 or 6)
          w.offenAus = w.offenAus or {}
          w.offenAus[#w.offenAus + 1] = { n, a }
          dbg("aus Abschaltung n=%d a=%s gStatus=%s code=%s ansage=%s ohneStatus=%s", n, tostring(a), tostring(t.gStatus),
            tostring(t.code), tostring(t.ansage), tostring(ohneStatus))
          w.absch = { n, t.gStatus == 4 and t.text or nil, ohneStatus }
          t.ende = 2
        end
        if w.akt and (n == 1 or t.ende == 2) then          -- Ende und Grund kommen in den Lauf
          w.akt[10], w.akt[11], w.akt[12] = t.ende, t.code, n > 1 and 1 or tab
        end
      end
    end
    t.gAlt = g
  end
  -- Abschaltung gilt bis zum nächsten Start der Turbine; SF löscht sie nicht (Entscheid User 20.11.2026: voller Alarm)
  if w.absch then
    local t = w.tb[w.absch[1]]
    if t.gruppe == 2 or t.gruppe == 3 then w.absch = nil end
  end
end

-- Pille im Kopf: 1 AUS, 2 START, 3 LÄUFT, 4 ABSCHALTUNG
local function pille(w)
  if w.absch then return 4 end
  local p = 1
  for n = 1, w.nTurb do
    local g = w.tb[n].gruppe
    if g == 4 then return 4 end
    if g == 3 then p = 3 elseif g == 2 and p < 3 then p = 2 end
  end
  return p
end

local function lauf(w, now, dt)
  local c, v = w.cfg, w.v
  -- Ohne Telemetrie ist unbekannt, ob die Turbine steht: der Lauf wird angehalten, nicht beendet (Befund Prüfung
  -- 20.11.2026: ein Telemetrie-Loch über 5 s teilte sonst den Lauf in zwei)
  if not v.tele then
    if w.akt then w.akt.steht = nil end
    return
  end
  local dreht, steht = false, true
  for n = 1, w.nTurb do
    local t = w.tb[n]
    if t.gruppe == 2 or t.gruppe == 3 then dreht = true end
    if (t.rpm and t.rpm >= STEHT_RPM) or t.gruppe == 2 or t.gruppe == 3 then steht = false end
  end
  w.pille = pille(w)
  if w.laufSperre then
    if steht then w.laufSperre = nil end
    return
  end
  local a = w.akt
  if a == nil then
    if not (dreht and v.tele) then return end
    a = { nil, 0 }
    a.ml0 = v.mlRest
    -- Höchst- und Tiefstwerte gelten je Lauf: beim Start neu beginnen
    v.egtHoch, v.rpmHoch, v.sollHoch, v.pumpeHoch, v.schubHoch = nil, nil, nil, nil, nil
    v.hoeheHoch, v.speedHoch, v.welleHoch, v.ecuTief, v.rxTief, v.rssiTief = nil, nil, nil, nil, nil, nil
    a[13] = w.nTurb
    w.akt = a
    if STUDIO and w.studio then STUDIO.flugNeu(w) end   -- Min/Max/Mittel der Studio-Plätze je Lauf
  end
  if steht then
    a.steht = a.steht or now
    if now - a.steht >= STEHT_S then
      if a[1] then laufEnde(w) else w.akt = nil end   -- unter «Lauf zählt ab»: verwerfen (Fehlstart)
      return
    end
  else
    a.steht = nil
  end
  if steht then return end
  a[2] = (a[2] or 0) + dt
  if a[1] == nil and a[2] >= (c.flugMin or 30) then
    w.dauer.laeufe = (w.dauer.laeufe or 0) + 1
    a[1] = w.dauer.laeufe
    w.dateiOffen = true
  end
  if a.ml0 == nil then a.ml0 = v.mlRest end
  if a.ml0 and v.mlRest then a[3] = max(0, a.ml0 - v.mlRest) end
  if v.egt and (a[4] == nil or v.egt > a[4]) then a[4] = v.egt end
  if v.rpm and (a[5] == nil or v.rpm > a[5]) then a[5] = v.rpm end
  if v.proz then a[6] = v.proz end
  if v.hoehe and (a[7] == nil or v.hoehe > a[7]) then a[7] = v.hoehe end
  if v.speed and (a[8] == nil or v.speed > a[8]) then a[8] = v.speed end
  if v.ecu and v.ecu > 0.5 and (a[9] == nil or v.ecu < a[9]) then a[9] = v.ecu end
  a[13] = max(a[13] or 1, w.nTurb)
  if a[1] and now - (w.tAkt or -1000) >= DAUER_S then   -- laufenden Lauf ab und zu sichern
    w.tAkt = now
    w.dateiOffen = true
  end
end

-- ---------------------------------------------------------------- Ansagen
-- Nie zwei innerhalb von 3 s. Reihenfolge: neuer Alarm, Abschaltung/«Turbine aus», wiederholter Alarm, «Turbine läuft»,
-- Schalter, Kraftstoffstufe. Alarme ohne Ansage-Datei nur als Ton, ausserhalb dieser Reihenfolge.
local ansagen
function ansagen(w, now)
  local c, v = w.cfg, w.v
  if v.ansageSw ~= nil then
    if v.ansageSw and w.ansageAlt == false then w.offenSG = true end
    w.ansageAlt = v.ansageSw
  end
  -- Warteschlange: { Datei, Zahl, Einheit, Dezimalen, Ersatzton {Hz, ms, Pause} }; ein Teil je Durchlauf
  local F = w.folge
  if F and F[1] then
    if now < (w.tFolge or 0) then
      if DIAG and now - (w.tDbg or 0) >= 0.5 then w.tDbg = now dbg("folge wartet n=%d bis %.2f", #F, w.tFolge) end
      return
    end
    local e = table.remove(F, 1)
    dbg("folge Teil %s zahl=%s rest=%d", tostring(e[1]), tostring(e[2]), #F)
    local da = sage(w, e[1])
    if e[2] ~= nil then zahlSagen(e[2], e[3], e[4]) end
    if not da and e[5] and system.playTone then pcall(system.playTone, e[5][1], e[5][2], e[5][3]) end
    local pause = e[2] ~= nil and ZAHL_PAUSE or GRUND_PAUSE
    w.tFolge = now + pause
    w.tAnsage = now + pause - ANSAGE_ABSTAND             -- nächste Einzelansage erst nach diesem Teil
    return
  end
  -- Kraftstoff in Stufen: jede Stufe einmal; tankt man nach (Wert steigt um 5 % über die Stufe), wieder frei
  if v.proz and v.tele then
    for _, s in ipairs(STUFEN) do
      if v.proz > s + 5 then
        w.kDone[s] = nil
      elseif v.proz < s and not w.kDone[s] then
        w.kDone[s] = true
        if w.kErster and c.kraftStufen then w.offenKraft = min(w.offenKraft or 100, s) end
      end
    end
    w.kErster = true                       -- erster Wert: Stufen still übernehmen
  end
  -- Alarme ohne Ansage-Datei (Grenzen der Studio-Datei für Sensoren, Kanäle, weitere Werte): nur Ton (und
  -- Vibration), je Eintrag eigene Wiederholung; sie belegen keine Ansage-Lücke (w.tAnsage bleibt), höchstens einer
  -- je Sekunde. Warnungen ohne Datei bleiben still.
  if now - (w.tTon or -100) >= 1 then
    for i = 1, w.nAktiv do
      local m = w.aktiv[i]
      if m.wav == nil and m.stufe == 2 and (m.tAns == nil or now - m.tAns >= w.g.wdh) then
        m.tAns, w.tTon = now, now
        if system.playTone then pcall(system.playTone, 2200, 180, 60) end   -- Ton erzwungen: keine Ansage möglich
        local key, S = m.name:sub(1, -2), w.studio
        local vib = c.vibration
        if S and S.gVib[key] ~= nil then vib = S.gVib[key] end
        if vib and system.playHaptic then pcall(system.playHaptic, "- . -") end
        break
      end
    end
  end
  if w.tAnsage and now - w.tAnsage < ANSAGE_ABSTAND then
    if DIAG and w.offenAus and w.offenAus[1] and now - (w.tDbg or 0) >= 0.5 then
      w.tDbg = now dbg("Sperre ANSAGE_ABSTAND, offenAus wartet (tAnsage %.2f)", w.tAnsage)
    end
    return
  end
  -- Alarme und Warnungen mit Ansage-Datei: neue zuerst, dann die Abschaltung («Turbine aus» + Grund), erst danach
  -- Wiederholungen. So verdrängen wiederholte Grenzwert-Ansagen die Abschaltung nie.
  local neu, wdh = nil, nil
  for i = 1, w.nAktiv do
    local m = w.aktiv[i]
    if m.wav and (m.stufe == 2 or c.warnAnsage) then
      if m.tAns == nil then
        if neu == nil or m.stufe > neu.stufe then neu = m end
      elseif now - m.tAns >= w.g.wdh and (wdh == nil or m.stufe > wdh.stufe) then
        wdh = m
      end
    end
  end
  local wahl = neu
  if wdh and not (w.offenAus and w.offenAus[1]) and (wahl == nil or wdh.stufe > wahl.stufe) then wahl = wdh end
  if wahl then
    dbg("Alarm %s Stufe %s (offenAus=%d, folge=%d)", tostring(wahl.wav), tostring(wahl.stufe),
      w.offenAus and #w.offenAus or 0, w.folge and #w.folge or 0)
    wahl.tAns, w.tAnsage = now, now
    -- Studio-Datei: Ansage und Vibration je Wert
    local key, S = wahl.name:sub(1, -2), w.studio
    local vib = c.vibration
    if S and S.gVib[key] ~= nil then vib = S.gVib[key] end
    if wahl.stufe == 2 and c.ton and system.playTone then pcall(system.playTone, 2200, 180, 60) end
    local gesagt = false
    if (c.ansage or wahl.stufe == 1) and not (S and S.gAns[key] == false) then
      gesagt = sage(w, wahl.wav)
      zahlSagen(wahl.wert, wahl.einh, wahl.dez)
    end
    -- Alarm ohne Ansage (global oder je Grenze aus, oder Datei fehlt): immer ein Ton («Ton erzwingen»)
    if wahl.stufe == 2 and not c.ton and not gesagt and system.playTone then pcall(system.playTone, 2200, 180, 60) end
    if vib and wahl.stufe == 2 and system.playHaptic then pcall(system.playHaptic, "- . -") end
    return
  end
  if w.offenAus and w.offenAus[1] then
    local L = w.offenAus                                  -- mehrere Turbinen: Abschaltung mit Grund zuerst
    local k = 1
    for i = 1, #L do if L[i][2] then k = i break end end
    local o = table.remove(L, k)
    dbg("offenAus n=%s a=%s grund=%s ton=%s vib=%s", tostring(o[1]), tostring(o[2]), tostring(o[2] and GRUND_WAV[o[2]]),
      tostring(c.ton), tostring(c.vibration))
    local name = o[1] > 1 and ("turbine_" .. o[1] .. "_aus") or "turbine_aus"
    w.folge = w.folge or {}
    if o[2] then
      -- «Turbine aus» und der Grund als zwei Teile; Ton nur, wenn die Grund-Datei fehlt
      w.folge[#w.folge + 1] = { name }
      w.folge[#w.folge + 1] = { GRUND_WAV[o[2]] or "stoerung", nil, nil, nil, c.ton and { 2200, 180, 60 } or nil }
      if c.vibration and system.playHaptic then pcall(system.playHaptic, "- . -") end
    else
      w.folge[#w.folge + 1] = { name, nil, nil, nil, { 900, 250, 0 } }
    end
    w.tFolge = now
    return ansagen(w, now)
  end
  if w.offenLaeuft then
    w.offenLaeuft, w.tAnsage = false, now
    if not sage(w, "turbine_laeuft") and system.playTone then pcall(system.playTone, 1500, 120, 0) end
    return
  end
  if w.offenSG then                                      -- Ansageschalter: jeder Teil einzeln über die Warteschlange
    w.offenSG = false
    w.folge = w.folge or {}
    local F2 = w.folge
    if c.sgKraft and v.proz then F2[#F2 + 1] = { "kraftstoff", v.proz, UNIT_PERCENT, 0 } end
    if c.sgZeit then F2[#F2 + 1] = { "laufzeit", floor(floor(w.akt and w.akt[2] or 0) / 60), UNIT_MINUTE, 0 } end
    if c.sgHoehe and v.hoehe then F2[#F2 + 1] = { "hoehe", v.hoehe, UNIT_METER, 0 } end
    w.tFolge = now
    if F2[1] then return ansagen(w, now) end
    return
  end
  if w.offenKraft then
    local p = w.offenKraft
    w.offenKraft, w.tAnsage = nil, now
    sage(w, "kraftstoff")
    zahlSagen(p, UNIT_PERCENT, 0)
    if p <= 10 and c.vibration and system.playHaptic then pcall(system.playHaptic, "- . -") end
  end
end

-- ---------------------------------------------------------------- Testhaken
-- Zustand alle 0,5 s als JSON in test-zustand.json (nur Simulator, nur mit TEST.zustand).
local function testZustand(w, now)
  if now - (w.tZustand or -10) < 0.5 then return end
  w.tZustand = now
  if ZUSTAND == nil then
    local ok, v = pcall(system.getVersion)
    if not (ok and type(v) == "table" and v.simulation) then TEST.zustand = nil return end
    local okL, f = pcall(lade, "testzustand.lua")
    if not okL then TEST.zustand = nil print(tostring(w.name) .. ": Fehler: testzustand.lua " .. tostring(f)) return end
    ZUSTAND = f
  end
  local a, t1 = w.akt, w.tb[1]
  w.testExtra = { akt = a and { nr = a[1], dauer = a[2], ml = a[3], ende = a[10] or false } or false, nListe = #w.liste,
    wahl = w.wahl or 0, st = w.st, pille = w.pille or 0, gruppe = t1.gruppe or 0, statusText = t1.text or "",
    code = t1.code or false, hersteller = hersteller(w) or 0, erkannt = w.erkannt or 0, nTurb = w.nTurb,
    absch = w.absch and true or false, rahmen = w.rahmenHerst or false, mlRest = w.v.mlRest or false, proz = w.v.proz or false,
    nWechsel = #w.wechsel, suchHinweis = w.suchHinweis or false, widersp = w.widerspK or false,
    studio = w.studioZustand or "", studioFehler = w.studioFehler or 0, kennung = w.studioKennung or "",
    studioHinweis = w.sHinweis or "", sDauer = w.sDauer or "", studioQuelle = w.studioQuelle or "",
    studioWahl = w.studioWahlArt or "", angepasst = w.angepasst or false, ansichtGenutzt = w.ansichtGenutzt or "", ansicht = (w.studio and w.L and w.studio.ansichten[w.L.W .. "x" .. w.L.H]) and true or false,
    tank = w.cfg.tank, egtW = w.cfg.egtW, egtA = w.cfg.egtA, ecuW = w.cfg.ecuW, ecuA = w.cfg.ecuA, kraftW = w.cfg.kraftW,
    kraftA = w.cfg.kraftA,
    symbole = (w.sym and not w.symOffen) and (select(1, w.sym.zaehler())) or 0 }   -- Format 2: geladene Symbole
  local ok, e = pcall(ZUSTAND, w, now, "test-zustand.json")
  if not ok or not e then print(tostring(w.name) .. ": Fehler: Testzustand konnte nicht geschrieben werden " .. tostring(e)) end
end

-- Testhaken einmalig: Läufe, laufender Lauf, Seite, Rückfrage, Statuswechsel
local function testStart(w)
  if not TEST or w.testFertig then return end
  w.testFertig = true
  if TEST.liste then
    w.liste = {}
    for i, r in ipairs(TEST.liste) do w.liste[i] = r end
    w.dauer.laeufe = TEST.laeufe or #TEST.liste
  end
  if TEST.akt then
    w.akt = {}
    for i, x in ipairs(TEST.akt) do w.akt[i] = x end
    w.akt.ml0 = TEST.akt.ml0
  end
  if TEST.lief then w.tb[1].lief, w.tb[1].gAlt = true, 3 end
  if TEST.seite then w.seite = TEST.seite end
  if TEST.wahl then w.wahl = TEST.wahl end
  if TEST.dialog then w.dialog = TEST.dialog end
  if TEST.wechsel then w.wechsel = TEST.wechsel end
  if TEST.absch then w.absch = TEST.absch end
end

-- ---------------------------------------------------------------- Studio-Datei
-- Format 2: Symbole der Studio-Datei (Referenz studio_symbole.lua, nur geladen bei format = 2) freigeben
local function symFrei(w)
  if w.sym then pcall(w.sym.freigeben) end
  w.sym, w.symOffen = nil, false
end

-- Studio-Hinweis: Band unten (8 s), danach «!» oben rechts bis zum nächsten Modellwechsel; Text auch ins Log
local function studioHinweis(w, text, now, dauer)
  -- mit eigener Dauer (Ansicht angepasst): nur das Band, danach kein «!» (einmaliger Hinweis)
  w.sHinweis, w.sHinweisBis, w.sAusruf = text, now + (dauer or STUDIO_HINWEIS_S), w.sAusruf or not dauer
  print(tostring(w.name) .. ": " .. text)
end

-- Studio-Datei (Lua-Studio-Format v1): einmal nach dem Laden des Modells in Schritten lesen, danach laufend
-- Quellen suchen, Min/Max/Kurven führen, Änderungen aus dem Menü in .funke.lua schreiben und die Info-Datei.
-- Die Sicherheitslogik (Abschaltung, Grenzwert-Alarme, Ansagen) bleibt im Kern; die Datei setzt nur Einstellungen
-- und Grenzen und fügt Grenzen für weitere Werte hinzu.
-- Ansicht für die aktuelle Fenstergrösse: genau passend, sonst einmal je Grösse umrechnen (R3); keine: Hinweiszeile
local function ansichtPruefen(w, now)
  local S, W, H, T = w.studio, w.L.W, w.L.H, w.T
  local key = W .. "x" .. H
  local a = S.ansichten[key]
  if a == nil and not w.ansichtVersucht[key] then
    w.ansichtVersucht[key] = true
    a = STUDIO.anpassen(S.ansichten, W, H, function(b, h) return Z.layout(b, h).kh end)
    if a then
      S.ansichten[key] = a
      local t = string.format(T.studioAngepasst, a.quelle)
      if a.weg > 0 then t = t .. ", " .. string.format(T.studioWeg, tostring(a.weg)) end
      studioHinweis(w, t, now, 5)
    end
  end
  local gen = a and (a.angepasst and a.quelle or key) or ""
  local dauer = (a == nil and w.seite == 1) and T.studioKeineAnsicht or nil
  if gen ~= w.ansichtGenutzt or (a and a.angepasst or false) ~= w.angepasst or dauer ~= w.sDauerAnsicht then
    w.ansichtGenutzt, w.angepasst, w.infoOffen = gen, a and a.angepasst or false, true
    if w.sDauer == nil or w.sDauer == w.sDauerAnsicht then w.sDauer = dauer end
    w.sDauerAnsicht = dauer
  end
end

local function studioWecke(w, now)
  local T = w.T
  if STUDIO == nil then
    local ok, m = pcall(lade, "studio.lua")
    if not ok then
      print(tostring(w.name) .. ": studio.lua nicht ladbar: " .. tostring(m))
      w.studioFertig, w.infoOffen = true, false
      return
    end
    STUDIO = m
  end
  if not w.studioFertig then
    -- felder.lua nur einmal je Ladevorgang laden (Verzeichnisse bleiben), danach wieder freigeben
    if w.studioF == nil then w.studioF = lade("felder.lua") return end
    local F = w.studioF
    if TEST and TEST.kennung then w.testKennung = TEST.kennung end   -- neutrale Kennung für Testbilder
    local J = w.studioErg
    if J == nil then                                -- Datei lesen und prüfen, ein Schritt je Aufruf
      J = STUDIO.schritt(w, F)
      if J == nil then return end
      if J.zustand == "geladen" then w.studioErg = J return end   -- Anwenden ab dem nächsten Aufruf (Befehlsgrenze)
    elseif not STUDIO.anwendenSchritt(w, J, F) then -- Anwenden in Schritten; cfg und w.studio erst im letzten
      return
    end
    w.studioErg, w.studioF = nil, nil
    w.studioFertig, w.infoOffen, w.studioZustand = true, true, J.zustand
    symFrei(w)
    if J.zustand ~= "geladen" then w.studio = nil end
    w.studioKennung = J.k
    w.studioFehler = 0
    -- Woher die Datei kam (Info-Datei) und die bleibende Hinweiszeile, wenn trotz Datei der Standard gilt
    w.studioQuelle, w.studioWahlArt = J.quelle or "", J.wahl or "auto"
    w.sDauer, w.angepasst, w.ansichtGenutzt, w.ansichtVersucht = nil, false, "", {}
    local dname = J.quelle and J.quelle:match("[^/]*$") or ""
    if J.zustand == "kaputt" then w.sDauer = string.format(T.studioDateiFehler, dname)
    elseif J.zustand == "zuNeu" then w.sDauer = T.studioZuNeu
    elseif J.zustand == "fehlt" and J.wahl == "menue" then w.sDauer = string.format(T.studioDateiFehlt, dname) end
    if J.zustand == "geladen" then
      if J.roh then                                     -- Format 2: Symbole in eigenen wakeup prüfen und laden
        local okS, SY = pcall(lade, "studio_symbole.lua")
        if okS and type(SY) == "table" then
          w.sym = SY
          local okA = pcall(SY.start, J.roh)
          w.symOffen = okA
          if not okA then symFrei(w) end
        else
          print(tostring(w.name) .. ": studio_symbole.lua nicht ladbar: " .. tostring(SY))
        end
        J.roh = nil
      end
      grenzen(w)
      w.stCache = {}
      w.studioFehler = J.fehler
      if J.fehler > 0 then studioHinweis(w, string.format(T.studioFehler, tostring(J.fehler)), now) end
      if J.funkeVerworfen then studioHinweis(w, T.funkeVerworfen, now) end
    elseif J.zustand == "kaputt" then
      studioHinweis(w, T.studioKaputt, now)
    elseif J.zustand == "zuNeu" then
      studioHinweis(w, T.studioZuNeu, now)
    end
    return
  end
  if w.studio and w.L then ansichtPruefen(w, now) end
  if w.studio then STUDIO.wecke(w, now) end
  if w.symOffen and w.sym then                          -- Symbole: Prüfen und Laden in Stücken (nie in paint)
    local ok, fertig = pcall(w.sym.schritt)
    if not ok or fertig then
      w.symOffen = false
      local okZ, _, fehlend = pcall(w.sym.zaehler)
      if okZ and type(fehlend) == "number" and fehlend > 0 then studioHinweis(w, string.format(T.symFehlen, tostring(fehlend)), now) end
    end
  end
  if w.funkeOffen and w.studio and now - (w.tFunke or -100) >= 2 then
    w.funkeOffen, w.tFunke = false, now
    local ok, gut = pcall(function() return STUDIO.funkeSchreiben(w.testKennung or STUDIO.kennung(), STUDIO.funkeAusCfg(w, lade("felder.lua"))) end)
    if not (ok and gut) then studioHinweis(w, T.funkeNicht, now) end
  end
  if w.infoOffen then
    local ok, fertig = pcall(STUDIO.infoSchritt, w, w.version, STUDIO.FORMATE or { STUDIO.FORMAT })
    if not ok then print(tostring(w.name) .. ": Info-Datei: " .. tostring(fertig)) end
    if not ok or fertig then
      w.infoOffen = false
      -- ohne Studio-Datei kein Speicher dafür; nur, wenn auch keine andere Instanz des Widgets studio.lua braucht
      local braucht = false
      for x in pairs(WIDGETS) do
        if x.studio or (x ~= w and (not x.studioFertig or x.infoOffen)) then braucht = true end
      end
      if not braucht then STUDIO = nil collectgarbage() end
    end
  end
end

-- ---------------------------------------------------------------- Ablauf
local function seiteDa(w, s) return s ~= 2 or w.nTurb > 1 end

function K.wecke(w)
  local now = os.clock()
  if w.tL == nil then w.tL, w.tE, w.tB = now - DT_LESEN, now - 3, now - 1 end
  local lesenJetzt = now - w.tL >= DT_LESEN
  -- Studio-Datei: eigene Aufrufe ohne Lesen und Rechnen (Befehlsgrenze am Sender je Aufruf); kommt länger als 1 s
  -- kein solcher Aufruf, läuft der Schritt trotzdem
  -- Nie Studio-Schritt und Lesen im selben Aufruf (Prüfung 7). Der Rückfall nach 1 s nimmt nur einen Aufruf, nach dem
  -- vorher gelesen wurde: bei seltenen Aufrufen wechseln Studio-Schritt und Lesen ab, das Lesen kommt nie zu kurz.
  if (not w.studioFertig or w.studio or w.infoOffen)
    and (not lesenJetzt or (w.gelesenZuletzt and now - (w.tStudio or -100) >= 1)) then
    w.tStudio = now
    studioWecke(w, now)
    lesenJetzt, w.gelesenZuletzt = false, false
  end
  if lesenJetzt then
    w.gelesenZuletzt = true
    local dt = now - w.tL
    if dt < 0 or dt > 5 then dt = 0 end
    w.tL = now
    testStart(w)
    if not w.vorgabe then
      w.vorgabe = true
      if not w.gelesen then schalterVorgabe(w) end
    end
    rahmenLesen(w, now)
    if now - w.tE >= 2 then                        -- vor dem Lesen: Hersteller gilt schon für den ersten Statuscode
      w.tE = now
      liesEinheiten(w)
    end
    lesen(w, now, dt)
    turbinen(w, now)
    lauf(w, now, dt)
    warnungen(w, now)
    ansagen(w, now)
    if w.sHinweis and now >= w.sHinweisBis then w.sHinweis, w.infoOffen = nil, true end
    if not seiteDa(w, w.seite) then w.seite = 1 end
    if TEST and TEST.zustand then testZustand(w, now) end
    if w.hinweis and now >= w.hinweisBis then w.hinweis = nil end
    -- Datei schreiben: sofort nach einer Rückfrage, sonst frühestens 2 s nach dem letzten Schreiben
    if w.dateiOffen and (w.dateiJetzt or now - (w.tDatei or -100) >= 2) then
      w.dateiOffen, w.dateiJetzt, w.tDatei = false, false, now
      local ok, F = pcall(lade, "felder.lua")
      local okS, erfolg = false, false
      if ok then okS, erfolg = pcall(F.schreibeDatei, w) end
      if not (okS and erfolg) then
        if not w.dateiFehler then print(tostring(w.name) .. ": Fehler: Datei konnte nicht geschrieben werden") end
        w.dateiFehler = true
        w.fehler = "Datei schreiben"
      end
    end
    -- Sensorsuche in Schritten (Ethos begrenzt die Befehle je Aufruf): ein Schritt je wakeup, bis sie fertig ist.
    -- Erster Start ohne gespeicherte Einstellungen: automatisch, sobald Telemetrie da ist (alle 5 s, höchstens 10-mal).
    if w.suche then
      if SUCHE == nil then
        local okL, f = pcall(lade, "suche.lua")
        SUCHE = okL and f or false
      end
      local ok, n = false, "suche.lua nicht ladbar"
      if SUCHE then ok, n = pcall(SUCHE, w) end
      if not ok or n ~= nil then
        local auto = w.suche == "auto"
        w.suche, w.suchJob, SUCHE = nil, nil, nil
        collectgarbage()
        if ok and type(n) == "number" then
          if n > 0 or not auto then
            grenzen(w)
            hinweis(w, string.format(auto and w.T.autoSuche or w.T.neuSuche, tostring(n)), now)
            if model and model.dirty then pcall(model.dirty) end
          end
          if auto and (n > 0 or (w.nAuto or 0) >= 10) then w.autoOffen = false end
        else
          print(tostring(w.name) .. ": Fehler in der Sensorsuche: " .. tostring(n))
          w.fehler = "Suche: " .. tostring(n)
          w.autoOffen = false
        end
      end
    elseif w.autoOffen and w.v.tele and not (TEST and (TEST.v or TEST.ohne or TEST.tele ~= nil)) and now - (w.tAuto or -100) >= 5 then
      w.tAuto = now
      w.nAuto = (w.nAuto or 0) + 1
      w.suche = "auto"
    end
  end

  if lcd.isVisible and not lcd.isVisible() then return end
  if now - w.tB >= DT_BILD then
    w.tB = now
    if Z == nil then Z = lade("zeichnen.lua") end
    if SEITE[w.seite] == nil then
      for i = 1, SEITEN do SEITE[i] = nil end
      collectgarbage()
      SEITE[w.seite] = lade("seite" .. w.seite .. ".lua")
    end
    w.blink = floor(now * 2) % 2 == 0
    lcd.invalidate()
  end
end

function K.zeichne(w)
  if Z == nil then return end
  local W, H = lcd.getWindowSize()
  local L = w.L
  if L == nil or L.W ~= W or L.H ~= H then
    L = Z.layout(W, H)
    w.L = L
  end
  Z.punkt = w.sp == 2            -- Englisch: Dezimalpunkt, Tausender mit Komma
  Z.grund(L)
  w.nZiele = 0
  if W < 300 or H < 150 then                    -- zu klein für Tachos und Felder: nur Name und Laufzeit
    local a = w.akt
    Z.text(L, W / 2, H * 0.32, tostring(w.name), 16, Z.C.grau, CENTERED, W - 8)
    Z.text(L, W / 2, H * 0.68, Z.zeit(a and a[2] or 0), 34, Z.C.weiss, CENTERED, W - 8, true)
    return
  end
  local fe = w.fenster or {}                       -- Fenstergrössen für die Info-Datei
  w.fenster = fe
  local neu = true
  for _, f in ipairs(fe) do if f[1] == W and f[2] == H then neu = false end end
  if neu and #fe < 8 then fe[#fe + 1] = { W, H } w.infoOffen = true end
  local S = SEITE[w.seite]
  local A = w.studio and w.seite == 1 and w.studio.ansichten[W .. "x" .. H]
  if A and STUDIO then                             -- Ansicht der Studio-Datei für genau diese Fenstergrösse
    if ANSICHT == nil then ANSICHT = lade("ansicht.lua") end
    ANSICHT.zeichne(w, L, Z, A, STUDIO)
  elseif S then
    S.zeichne(w, L, Z)
  end
  Z.kopf(w, L)
  Z.hinweis(w, L)
  Z.studioHinweis(w, L)
  if w.dialog then
    w.zielAb = w.nZiele + 1      -- bei offener Rückfrage zählen nur ihre eigenen Knöpfe
    if w.dialog == "status" then Z.statusListe(w, L) else Z.dialog(w, L) end
  end
end

local function treffer(w, x, y)
  local ab = w.dialog and (w.zielAb or 1) or 1
  for i = w.nZiele or 0, ab, -1 do         -- zuletzt gezeichnet liegt oben
    local z = w.ziele[i]
    if x >= z.x and x < z.x + z.b and y >= z.y and y < z.y + z.h then return z.id, z.arg end
  end
  return nil
end

local function blaettern(w, r)
  local s = w.seite + r
  if s == 2 and not seiteDa(w, 2) then s = s + r end
  return clamp(s, 1, SEITEN)
end

-- Aktion nach Antippen oder aus dem Menü. Alles, was Daten löscht, geht nur über eine Rückfrage mit «JA, …».
local function aktion(w, id, arg, now)
  local T = w.T
  if id == "abbrechen" then
    w.dialog = nil
  elseif id == "status" then
    w.dialog = "status"
  elseif id == "liste_seite" then
    w.seite = 3
  elseif id == "seite1" then
    w.seite = 1
  elseif id == "wahl" then
    w.wahl = arg
  elseif id == "loeschen" and w.wahl then
    w.dialog = "loeschen"
  elseif id == "liste" and (#w.liste > 0 or (w.akt and w.akt[1])) then
    w.dialog = "liste"
  elseif id == "ja_loeschen" then
    w.dialog = nil
    local nr = arg or w.wahl
    if laufLoeschen(w, nr) then hinweis(w, string.format(T.geloescht, tostring(floor(nr))), now) end
  elseif id == "ja_liste" then
    w.dialog = nil
    w.liste, w.wahl, w.dauer.laeufe, w.oben = {}, nil, 0, 0
    if w.akt and w.akt[1] then w.akt, w.laufSperre = nil, true end
    hinweis(w, T.listeWeg, now)
    w.dateiOffen, w.dateiJetzt = true, true
  elseif id == "ja_ende" then
    w.dialog = nil
    if w.akt then
      if w.akt[1] then laufEnde(w) else w.akt = nil end
      w.laufSperre = true
      hinweis(w, T.laufBeendet, now)
    end
  elseif id == "ja_studio" then                    -- Zurück auf Studio-Stand: .funke.lua löschen, neu laden
    w.dialog = nil
    if STUDIO == nil then STUDIO = lade("studio.lua") end
    STUDIO.funkeSchreiben(w.testKennung or STUDIO.kennung(), nil)
    w.studio, w.studioFertig, w.studioJob, w.studioErg, w.studioF, w.funkeOffen = nil, false, nil, nil, nil, false
    symFrei(w)
    hinweis(w, T.studioZurueck, now)
  elseif id == "ja_standard" then                  -- ohne Studio-Datei: Einstellungen und Grenzwerte auf Werk
    w.dialog = nil
    local F = lade("felder.lua")
    local werk, c = F.standard(), w.cfg
    for k, x in pairs(werk) do
      if F.studioEinstellung(k) or k:match("^%l+[WA]$") then c[k] = x end
    end
    local z = F.ECU_WERK[c.ecuArt] or F.ECU_WERK[1]
    c.ecuW, c.ecuA = z[1], z[2]
    grenzen(w)
    w.stCache = {}
    hinweis(w, T.standardZurueck, now)
    w.dateiOffen, w.dateiJetzt = true, true
  elseif id == "ja_neu" then
    w.dialog = nil
    w.suche, w.suchJob = "neu", nil          -- Turbinenfelder, die nicht auf 0x1B liegen, neu zuordnen
  end
  w.tB = 0
end

-- Einträge der Flugliste, neueste zuerst (der laufende Lauf oben)
function K.eintraege(w)
  local e = {}
  if w.akt and w.akt[1] then e[1] = w.akt end
  for i = #w.liste, 1, -1 do e[#e + 1] = w.liste[i] end
  return e
end

-- Wisch nach links/rechts blättert, auf der Flugliste rollt auf/ab die Liste. Drehrad: blättert vorwärts, auf der
-- Flugliste wählt es den Lauf (vor den ersten Lauf = zurück zu Seite 1). Drehungen behält das Widget immer
-- (gemessen 26.1.2: gibt es eine zurück, kommen keine mehr an).
function K.ereignis(w, kat, wert, x, y)
  if kat == EVT_KEY and (wert == KEY_ROTARY_RIGHT or wert == KEY_ROTARY_LEFT) then
    if w.dialog then
      if w.dialog == "status" then w.dialog = nil end
      return true
    end
    local rechts = wert == KEY_ROTARY_RIGHT
    if w.seite ~= 3 then
      w.seite = blaettern(w, rechts and 1 or -1)
    else
      local e = K.eintraege(w)
      local i = 0
      for k, r in ipairs(e) do if r[1] == w.wahl then i = k end end
      i = i + (rechts and 1 or -1)
      if i < 1 then
        w.wahl, w.seite = nil, 1
      else
        i = min(i, #e)
        w.wahl = e[i] and e[i][1] or nil
        local sicht = w.sicht or 6
        if i > w.oben + sicht then w.oben = i - sicht end
        if i <= w.oben then w.oben = i - 1 end
      end
    end
    w.tB = 0
    return true
  end
  if kat ~= EVT_TOUCH then return false end
  x, y = gut(x), gut(y)
  if x == nil or y == nil then return false end
  local t = w.touch
  if wert == TOUCH_START then
    local id, arg = treffer(w, x, y)
    w.touch = { x = x, y = y, id = id, arg = arg }
    return w.dialog ~= nil
  elseif wert == TOUCH_MOVE and t then
    local dx, dy = x - t.x, y - t.y
    if abs(dx) > SLOP or abs(dy) > SLOP then t.id = nil end
    if w.dialog then return true end
    if not t.mein and not t.ethos and abs(dx) > SLOP and abs(dx) > abs(dy) then
      local neu = blaettern(w, dx < 0 and 1 or -1)
      if neu ~= w.seite then t.mein = true else t.ethos = true end
    end
    if w.seite == 3 and not t.mein and not t.ethos and abs(dy) > SLOP and abs(dy) > abs(dx) then t.rollen = true end
    t.dx, t.dy = dx, dy
    if t.rollen then return true end
    return not t.ethos
  elseif wert == TOUCH_END and t then
    w.touch = nil
    if t.mein then
      if abs(t.dx or 0) >= 50 then
        w.seite = blaettern(w, (t.dx < 0) and 1 or -1)
        w.tB = 0
      end
      return true
    end
    if t.rollen then
      local schritte = floor(abs(t.dy or 0) / 40)
      if schritte > 0 then
        local n = #K.eintraege(w)
        w.oben = clamp(w.oben + ((t.dy < 0) and schritte or -schritte), 0, max(0, n - (w.sicht or 6)))
        w.tB = 0
      end
      return true
    end
    local id, arg = treffer(w, x, y)
    if t.id and t.id == id then
      aktion(w, id, arg or t.arg, os.clock())
      return true
    end
    return w.dialog ~= nil
  end
  return false
end

function K.menue(w)
  local F = lade("felder.lua")
  lade("menue.lua")(w, F, function()
    grenzen(w)
    w.stCache = {}
    w.dateiOffen = true
    if w.studio then w.funkeOffen = true end     -- mit Studio-Datei gehen Änderungen nach .funke.lua
    if model and model.dirty then pcall(model.dirty) end
  end, function()
    w.suche, w.suchJob = "menue", nil       -- läuft in den nächsten wakeup-Aufrufen, Hinweis am Ende
    return "gestartet"
  end, function(id, arg)
    aktion(w, id, arg, os.clock())
  end, K)
end

-- Für das Menü: studio.lua (Dateiliste) und neu laden nach einer anderen Wahl der Studio-Datei
function K.studioModul()
  if STUDIO == nil then STUDIO = lade("studio.lua") end
  return STUDIO
end
function K.studioNeu(w)
  w.studio, w.studioFertig, w.studioJob, w.studioErg, w.studioF = nil, false, nil, nil, nil
  w.sDauer, w.sDauerAnsicht, w.sHinweis = nil, nil, nil
  symFrei(w)
  grenzen(w)
end

function K.lies(w)
  local F = lade("felder.lua")
  w.gelesen = F.lies(w)
  -- Die Studio-Datei gilt über den gelesenen Einstellungen: nach jedem Lesen neu anwenden
  w.studio, w.studioFertig, w.studioJob, w.studioErg, w.studioF = nil, false, nil, nil, nil
  symFrei(w)
  local d = w.dauer
  if not (gut(d.laeufe) and d.laeufe >= 0) then d.laeufe = 0 end
  d.laeufe = floor(d.laeufe)
  if w.offen then                                  -- offener Lauf vom letzten Mal: abschliessen
    w.liste[#w.liste + 1] = w.offen
    while #w.liste > w.MAX_FLUEGE do table.remove(w.liste, 1) end
    w.offen = nil
    w.dateiOffen = true
  end
  w.autoOffen = not w.gelesen
  -- Update von 0.1.0 (Datei ohne Formatnummer): einmal die Turbinenwerte neu zuordnen (0.1.0 bevorzugte die
  -- Turbinen-ID 0x1B nicht) und die Datei mit Formatnummer schreiben
  if w.update010 then
    w.update010 = nil
    w.suche, w.suchJob = "neu", nil
    w.dateiOffen = true
  end
  grenzen(w)
end

function K.schreibe(w)
  local F = lade("felder.lua")
  F.schreibe(w)
end

return K
