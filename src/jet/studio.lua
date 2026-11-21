-- Jet: Studio-Datei je Modell lesen, prüfen und anwenden (Lua-Studio-Format v1).
-- Wird nur geladen, solange ein Modell geladen wird bzw. eine Studio-Datei gilt. Alles in Schritten: Der Kern ruft
-- M.schritt(w) je wakeup auf, bis es «fertig» meldet (Befehlsgrenze am Sender).
-- Dateien: <Kennung>.jet.lua (schreibt nur das Studio; gesucht in SCRIPTS:/studio/, SD:/scripts/studio/,
-- RADIO:/scripts/studio/ oder im Menü gewählt), SCRIPTS:/studio/<Kennung>.jet.funke.lua (schreibt nur dieses Lua),
-- SCRIPTS:/studio/<Kennung>.jet.info.json (schreibt nur dieses Lua, liest nur das Studio).
local M = {}
local floor = math.floor

M.ORDNER = "SCRIPTS:/studio/"
M.LUA = "jet"
M.FORMAT = 2           -- höchstes Format, das diese Version liest (Format 2 seit 0.3.0)
M.FORMATE = { 1, 2 }   -- für die Info-Datei
-- Suchorte der Studio-Datei in dieser Reihenfolge. SCRIPTS: ist SD: oder RADIO:, je nach Skript-Speicherort;
-- liegt Jet selbst unter SD:/scripts/jet (bzw. RADIO:), ist dieser Ort derselbe und wird nur einmal durchsucht.
M.ORTE = { { "SCRIPTS:/studio/", "SCRIPTS" }, { "SD:/scripts/studio/", "SD" }, { "RADIO:/scripts/studio/", "RADIO" } }
function M.orte()
  local function da(p) local ok, f = pcall(io.open, p, "r") if ok and f then f:close() return true end return false end
  local gleich = (da("SD:/scripts/jet/main.lua") and "SD") or (da("RADIO:/scripts/jet/main.lua") and "RADIO") or nil
  local r = {}
  for _, o in ipairs(M.ORTE) do
    if o[2] ~= gleich then r[#r + 1] = o end
  end
  return r
end

-- Alle Studio-Dateien dieses Luas an allen Orten (für das Menü, nur beim Öffnen): { { pfad, anzeige }, ... }
function M.liste()
  local r, ende = {}, "." .. M.LUA .. ".lua"
  for _, o in ipairs(M.orte()) do
    local ok, l = pcall(system.listFiles, o[1])
    if ok and type(l) == "table" then
      for _, n in ipairs(l) do
        if type(n) == "string" and #r < 40 and n:sub(-#ende) == ende and n:sub(-#ende - 6) ~= ".funke" .. ende then
          r[#r + 1] = { o[1] .. n, n:sub(1, -#ende - 1) .. " (" .. o[2] .. ")" }
        end
      end
    end
  end
  return r
end

M.MAX_EXTRA = 6        -- weitere Grenzen (Sensoren, Kanäle, nicht überwachte Lua-Werte), siehe Stufe 3 beim Anwenden

-- ===== Referenz studioLaden, WÖRTLICH aus «Lua-Studio-Format v1 - Referenz studio_laden.lua» =====
local MAX_BYTE = 16384
local MAX_ELEMENTE = 1200   -- Kommas + «=» + «{» ausserhalb von Texten (Befehle und Speicher, gemessen)
local MAX_TABELLEN = 240    -- «{» ausserhalb von Texten (Speicher)
local SCHLUESSELWOERTER = { "and", "break", "do", "else", "elseif", "end", "for", "function", "goto", "if", "in",
  "local", "nil", "not", "or", "repeat", "then", "until", "while" }

local function studioLaden(pfad, hoechstesFormat)
  local ok, f = pcall(io.open, pfad, "r")
  if not ok or not f then return nil, "fehlt" end
  local teile, n = {}, 0
  while true do
    local ok2, s = pcall(f.read, f, 512)
    if not ok2 then f:close() return nil, "kaputt" end
    if not s or #s == 0 then break end
    n = n + #s
    if n > MAX_BYTE then f:close() return nil, "kaputt" end
    teile[#teile + 1] = s
  end
  f:close()
  local s = table.concat(teile)
  teile = nil
  -- 1. Anfang: nur «return {»
  if not s:find("^%s*return%s*{") then return nil, "kaputt" end
  -- 2. erlaubte Bytes: Buchstaben, Ziffern, Leerraum, _ { } [ ] = , " \ - .
  if s:find('[^%w%s_{}%[%]=,"\\%-%.]') then return nil, "kaputt" end
  -- 2b. nach «\» nur Ziffern (Dezimal-Escapes); sperrt \" \z \x \u{…}, die die Textgrenzen verschieben könnten
  if s:find("\\%D") then return nil, "kaputt" end
  -- 3. verbotene Folgen: Verkettung, Kommentar, lange Texte
  if s:find("..", 1, true) or s:find("--", 1, true) or s:find("[[", 1, true) then return nil, "kaputt" end
  -- 4. Schlüsselwörter ausserhalb von Texten (Texte enthalten nie ein rohes ", das Studio schreibt \34)
  local ohneTexte = s:gsub('"[^"]*"', '""')
  for _, w in ipairs(SCHLUESSELWOERTER) do
    if ohneTexte:find("%f[%w_]" .. w .. "%f[^%w_]") then return nil, "kaputt" end
  end
  -- 4b. «-» nur als Vorzeichen direkt vor einer Ziffer, nach = , { [ (keine Rechenketten)
  if ohneTexte:find("%-%s*%D") or ohneTexte:find("[^=,{%[%s]%s*%-") then return nil, "kaputt" end
  local _, anzahlReturn = ohneTexte:gsub("%f[%w_]return%f[^%w_]", "")
  if anzahlReturn ~= 1 then return nil, "kaputt" end
  -- 4b2. kein Name und keine Zahl länger als 24 Zeichen (Speicher: lange Schlüssel)
  if ohneTexte:find(string.rep("[%w_]", 25)) then return nil, "kaputt" end
  -- 4c. reine Daten: Namen nur als Schlüssel direkt vor «=», sonst nur true/false (kein _ENV, keine Variablen, keine Aufrufe)
  if ohneTexte:find("==", 1, true) then return nil, "kaputt" end
  local rest = ohneTexte:gsub("^%s*return", "")
  rest = rest:gsub("[%a_][%w_]*%s*=", "=")
  rest = rest:gsub("%f[%w_]true%f[^%w_]", "")
  rest = rest:gsub("%f[%w_]false%f[^%w_]", "")
  local nameGefunden = rest:find("[%a_]")
  rest = nil
  if nameGefunden then return nil, "kaputt" end
  -- 4d. nach «[» nur ein Text, eine Zahl oder ein Vorzeichen (keine Ausdrücke als Schlüssel)
  if ohneTexte:find('%[%s*[^%d"%-]') then return nil, "kaputt" end
  -- 5. Grösse der Tabelle begrenzen (Befehlsgrenze beim Aufbau)
  local _, kommas = ohneTexte:gsub(",", "")
  local _, gleich = ohneTexte:gsub("=", "")
  local _, klammern = ohneTexte:gsub("{", "")
  if klammern > MAX_TABELLEN or kommas + gleich + klammern > MAX_ELEMENTE then return nil, "kaputt" end
  -- 6. laden ohne Umgebung, nur Text
  -- Zwischentexte der Prüfung freigeben, bevor übersetzt wird (Speicher-Spitze)
  ohneTexte = nil
  collectgarbage("collect")
  local ok3, chunk = pcall(load, s, "=studio", "t", {})
  s = nil
  collectgarbage("collect")
  if not ok3 or type(chunk) ~= "function" then return nil, "kaputt" end
  local ok4, d = pcall(chunk)
  if not ok4 or type(d) ~= "table" or math.type(d.format) ~= "integer" or d.format < 1 then return nil, "kaputt" end
  if d.format > hoechstesFormat then return nil, "zuNeu" end
  return d
end
-- ===== Ende Referenz =====
M.studioLaden = studioLaden

-- Werte dieses Luas (wie studio/beschreibung.json): Feld in w.v (oder Sonderfall mit «!»), Einheit, Stellen, min,
-- max, Grenzrichtung (nur überwachte Werte), Name de/en; u = Name in kern.lua (UEBERWACHT, cfg <u>W / <u>A).
-- Die Prüfung test/studio-test.lua vergleicht mit der JSON-Datei.
M.WERTE = {
  drehzahl = { "rpm", "U/min", 0, 0, 300000, nil, "Drehzahl", "RPM" },
  egt = { "egt", "°C", 0, 0, 1200, "ueber", "EGT", "EGT", u = "egt" },
  kraftstoff_proz = { "proz", "%", 0, 0, 100, "unter", "Kraftstoff %", "Fuel %", u = "kraft" },
  ecu_akku = { "ecu", "V", 1, 0, 30, "unter", "ECU-Akku", "ECU battery", u = "ecu" },
  fluss = { "fluss", "ml/min", 0, 0, 5000, nil, "Kraftstofffluss", "Fuel flow" },
  pumpe = { "pumpe", "V", 2, 0, 10, nil, "Pumpe", "Pump" },
  schub = { "schub", "N", 0, 0, 2000, nil, "Schub", "Thrust" },
  hoehe = { "hoehe", "m", 0, 0, 2000, "ueber", "Höhe", "Altitude", u = "hoehe" },
  speed = { "speed", "km/h", 0, 0, 600, "ueber", "Speed", "Speed", u = "speed" },
  empfang = { "rssi", "dB", 0, 0, 100, "unter", "Empfang", "Signal", u = "rssi" },
  gas_proz = { "gas", "%", 0, 0, 100, nil, "Gas %", "Throttle %" },
  welle = { "welle", "U/min", 0, 0, 300000, nil, "Welle", "Shaft RPM" },
  ecu_strom = { "strom", "A", 1, 0, 50, nil, "ECU-Strom", "ECU current" },
  laufzeit = { "!laufzeit", "s", 0, 0, 7200, nil, "Laufzeit", "Run time" },
  kraftstoff_ml = { "!ml", "ml", 0, 0, 50000, nil, "Kraftstoff ml", "Fuel ml" },
  rx_akku = { "rx", "V", 1, 0, 20, "unter", "Empfängerakku", "Receiver battery", u = "rx" },
  status = { "!status", "", 0, 1, 4, nil, "Status", "Status", status = true },
  laeufe = { "!laeufe", "", 0, 0, 100, nil, "Läufe", "Runs" },
}
-- überwachte Werte: Name in kern.lua (UEBERWACHT, GRENZEN) -> Studio-Schlüssel und Teiler im cfg. ECU-Akku: das cfg
-- hält die Schwelle je Zelle in 1/100 V, der Wert ist die ganze Spannung (Teiler 100 / Zellen, M.teiler).
M.UEBERWACHT = { egt = { "egt", 1 }, kraft = { "kraftstoff_proz", 1 }, ecu = { "ecu_akku", 100 }, rx = { "rx_akku", 100 },
  rssi = { "empfang", 1 }, hoehe = { "hoehe", 1 }, speed = { "speed", 1 } }
function M.teiler(n, c)
  if n == "ecu" then
    local z = c and c.ecuZellen
    if math.type(z) ~= "integer" or z < 1 then z = 2 end
    return 100 / z
  end
  return M.UEBERWACHT[n][2]
end

-- Darstellungsarten und Mindestgrösse (X18RS, 784 Pixel breit), Abschnitt 7
M.DARST = { zahl = { 90, 50 }, ring = { 110, 110 }, balken_w = { 140, 40 }, balken_s = { 50, 110 },
  kurve = { 180, 90 }, status = { 120, 40 } }

-- Studio-Name einer Einstellung (klein mit _) -> Name in felder.lua
local function luaName(s) return (s:gsub("_(%l)", function(c) return c:upper() end)) end
M.luaName = luaName

-- Modellkennung (Abschnitt 2.1), byteweise
function M.kennung()
  local ok, n = pcall(model.name)
  local k = ((ok and type(n) == "string") and n or ""):gsub("[^%w]", "_"):sub(1, 32)
  if k == "" then k = "modell" end
  return k
end

local function endlich(v) return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge end
local function ganz(v) return math.type(v) == "integer" end
local function kuerze(t, n)
  if type(t) ~= "string" then return nil end
  if #t <= n then return t end
  local e = n
  while e > 0 do
    local b = t:byte(e + 1)
    if b == nil or b < 0x80 or b > 0xBF then break end   -- nur vor einem Byte kürzen, das ein Zeichen beginnt
    e = e - 1
  end
  return t:sub(1, e)
end
M.kuerze = kuerze
local function farbe(f)
  if type(f) ~= "table" or #f ~= 3 then return nil end
  for i = 1, 3 do
    if not ganz(f[i]) or f[i] < 0 or f[i] > 255 then return nil end
  end
  return { f[1], f[2], f[3] }
end

-- Wert-Schlüssel nach 6.6. Rückgabe: Art ("lua", "sensor", "kanal", "leer") und Teile, sonst nil.
function M.schluessel(k)
  if type(k) ~= "string" then return nil end
  if k == "leer" then return "leer" end
  local s = k:match("^lua:([%w_]+)$")
  if s then return M.WERTE[s] and "lua" or nil, s end
  local a, sub, ph = k:match("^sensor:(%x%x%x%x):(%d+):?(%d*)$")
  if a and not a:find("%l") then
    local p = ph ~= "" and tonumber(ph) or nil
    if p and p > 27 then return nil end
    return "sensor", tonumber(a, 16), tonumber(sub), p
  end
  local n = k:match("^kanal:(%d+)$")
  if n and tonumber(n) >= 1 and tonumber(n) <= 64 then return "kanal", tonumber(n) end
  return nil
end

-- ===== Prüfen (Abschnitt 6). Jede Prüfung zählt Fehler und schreibt je Fehler eine Zeile ins Log. =====
local function fehler(J, wo, warum)
  J.fehler = J.fehler + 1
  print("Jet: Studio-Datei " .. J.datei .. ": " .. wo .. ": " .. warum)
end

-- Prüfen in Stücken (Befehlsgrenze am Sender): je Aufruf höchstens n Einträge einer Tabelle, der Zeiger (letzter
-- Schlüssel für next) bleibt in J.zeiger. f(J, Schlüssel, Wert, ziel, F) darf der Tabelle t keine Schlüssel zufügen.
-- Rückgabe true = Tabelle fertig.
local function stueck(J, t, n, f, ziel, F)
  local k, v = J.zeiger, nil
  for _ = 1, n do
    k, v = next(t, k)
    if k == nil then J.zeiger = nil return true end
    f(J, k, v, ziel, F)
  end
  J.zeiger = k
  return false
end

-- Einträge je Aufruf (gemessen mit der grössten gültigen Datei, test/studio-test.lua i): je Abschnitt < 2500 Befehle)
-- Format 2, Regel 7.1: höchstens 8 Einträge je Aufruf beim Prüfen, Zusammenführen und Anwenden (seit 0.3.0).
M.JE_EINST, M.JE_WERTE, M.JE_GRENZEN, M.JE_FERTIG, M.JE_EXTRA = 8, 8, 8, 8, 8
-- Format 2, Regel 7.2: werte, grenzen und einstellungen höchstens 48 Einträge, ab dem 49. verworfen plus Hinweis
M.MAX_LISTE = 48

-- Einstellungen: nur die, die felder.lua kennt und die keine Quelle, kein Grenzwert und kein Feld sind
local function einstellung(J, s, v, ziel, F)
  local f = type(s) == "string" and F.feld(luaName(s))
  if f and F.studioEinstellung(f[1]) then
    local art, gut = f[2], nil
    if art == "z" then gut = ganz(v) and v >= f[5] and v <= f[6]
    elseif art == "b" then gut = type(v) == "boolean"
    elseif art == "t" then gut = type(v) == "string" and F.eigen(v) ~= nil
    elseif art == "w" then
      if ganz(v) then for _, a in ipairs(f[5]) do if a[2] == v then gut = true end end end
    end
    if gut then ziel[f[1]] = (art == "t") and F.eigen(v) or v
    else fehler(J, "einstellungen." .. tostring(s), "ungültig, Werkwert") end
  end
end

local function wertEintrag(J, k, e, ziel)
  local art, s = M.schluessel(k)
  if not art or art == "leer" or type(e) ~= "table" then
    fehler(J, "werte." .. tostring(k), "Eintrag verworfen")
  elseif art == "lua" and M.WERTE[s].u and type(e.faktor) == "number" and e.faktor < 0 then
    -- überwachter Wert mit negativem Faktor: die Alarmrichtung würde sich drehen, darum ganzer Eintrag verworfen
    fehler(J, "werte." .. k .. ".faktor", "negativ bei überwachtem Wert, Eintrag verworfen")
  else
    local a = { faktor = 1, versatz = 0 }
    if e.faktor ~= nil then
      if endlich(e.faktor) and math.abs(e.faktor) >= 0.0001 and math.abs(e.faktor) <= 10000 then a.faktor = e.faktor
      else fehler(J, "werte." .. k .. ".faktor", "ungültig, 1") end
    end
    if e.versatz ~= nil then
      if endlich(e.versatz) and e.versatz >= -100000 and e.versatz <= 100000 then a.versatz = e.versatz
      else fehler(J, "werte." .. k .. ".versatz", "ungültig, 0") end
    end
    if e.einheit ~= nil then
      if type(e.einheit) == "string" then a.einheit = kuerze(e.einheit, 8) else fehler(J, "werte." .. k .. ".einheit", "kein Text") end
    end
    if e.stellen ~= nil then
      if ganz(e.stellen) and e.stellen >= 0 and e.stellen <= 3 then a.stellen = e.stellen
      else fehler(J, "werte." .. k .. ".stellen", "ungültig") end
    end
    if e.name ~= nil then
      if type(e.name) == "string" then a.name = kuerze(e.name, 24) else fehler(J, "werte." .. k .. ".name", "kein Text") end
    end
    ziel[k] = a
  end
end

-- Grenzen: nur Felder sammeln; die Richtung und die Reihenfolge prüft grenzeFertig nach dem Zusammenführen
local function grenzeEintrag(J, k, e, ziel)
  local art = M.schluessel(k)
  if not art or art == "leer" or type(e) ~= "table" then
    fehler(J, "grenzen." .. tostring(k), "Eintrag verworfen")
  else
    local z = ziel[k] or {}
    if e.richtung ~= nil then
      if e.richtung == "unter" or e.richtung == "ueber" then z.richtung = e.richtung
      else z.richtungFalsch = true end
    end
    for _, n in ipairs({ "warnung", "alarm" }) do      -- false = diese Stufe aus (Format 6.5)
      if e[n] ~= nil then
        if e[n] == false or endlich(e[n]) then z[n] = e[n]
        else
          fehler(J, "grenzen." .. k .. "." .. n, "ungültig, Werkgrenze dieser Stufe")
          z[n] = "werk"                               -- überwachter Wert: Werkgrenze; sonst gilt die Stufe als nicht vorhanden
        end
      end
    end
    for _, n in ipairs({ "ansage", "vibration", "aus", "beiMotorAus" }) do   -- beiMotorAus: Format 2 §3.5, falsch = true
      if e[n] ~= nil then
        if type(e[n]) == "boolean" then z[n] = e[n] else fehler(J, "grenzen." .. k .. "." .. n, "kein true/false") end
      end
    end
    ziel[k] = z
  end
end

-- Ein Abschnitt der Studio-Datei (funke = aus .funke.lua) in Stücken. Rückgabe true = fertig.
local function abschnitt(J, d, name, n, f, ziel, F, funke)
  local t = d and d[name]
  if t == nil then return true end
  local datei = J.datei
  if funke then J.datei = J.k .. "." .. M.LUA .. ".funke.lua" end
  local fertig = true
  if type(t) ~= "table" then fehler(J, name, "keine Tabelle")
  else
    J.nListe = J.nListe or 0
    fertig = stueck(J, t, n, function(J2, k, v, z, F2)
      J2.nListe = J2.nListe + 1
      if J2.nListe <= M.MAX_LISTE then f(J2, k, v, z, F2) end   -- Regel 7.2: ab dem 49. Eintrag verworfen
    end, ziel, F)
    if fertig then
      if J.nListe > M.MAX_LISTE then fehler(J, name, (J.nListe - M.MAX_LISTE) .. " Einträge über " .. M.MAX_LISTE .. " verworfen") end
      J.nListe = nil
    end
  end
  J.datei = datei
  return fertig
end

-- Nach dem Zusammenführen: Richtung und Reihenfolge einer Grenze prüfen. Ergebnis:
-- { richtung, warnung (oder nil = aus), alarm, ansage, vibration } bzw. { werk = true } oder { aus = true }
local function grenzeFertig(J, k, z, still)
  local function f(wo, warum) if not still then fehler(J, wo, warum) end end
  local art, s = M.schluessel(k)
  local def = art == "lua" and M.WERTE[s][6] or nil
  local richtung = z.richtung or def
  local e = { ansage = z.ansage ~= false, vibration = z.vibration ~= false, beiMotorAus = z.beiMotorAus ~= false }
  if art == "lua" and M.WERTE[s].status then e.beiMotorAus = true end   -- "immerAlarm": Status nie still (§3.5)
  if def and M.WERTE[s].u and (z.richtungFalsch or richtung ~= def) then
    -- überwachter Jet-Wert mit falscher oder abweichender Richtung: Werkgrenze bleibt (Alarm-Sicherheit)
    f("grenzen." .. k .. ".richtung", "passt nicht zum Wert, Werkgrenze gilt")
    e.werk = true
  elseif z.richtungFalsch or richtung == nil or (def and richtung ~= def) then
    f("grenzen." .. k .. ".richtung", "fehlt oder ungültig, Grenze aus")
    e.aus = true
  elseif z.aus then
    e.aus = true
  else
    e.richtung = richtung
    e.warnung = z.warnung or nil
    e.alarm = z.alarm or nil
    local ueberwacht = def and M.WERTE[s].u
    -- Alarm-Sicherheit (Entscheid des Users 20.11.2026): ein überwachter Wert wird nur mit aus = true ganz still. Ein
    -- Eintrag ohne aktive Stufe (keine Stufe, nur ansage/beiMotorAus, oder warnung = false und alarm = false) gibt
    -- die Werkgrenze, mit Hinweis.
    if ueberwacht and not e.warnung and not e.alarm then
      if z.warnung ~= nil or z.alarm ~= nil then f("grenzen." .. k, "keine Stufe aktiv, ganz aus nur mit aus = true: Werkgrenze") end
      e.warnung, e.alarm = "werk", "werk"
    end
    if e.warnung == "werk" and not ueberwacht then e.warnung = nil end
    if e.alarm == "werk" and not ueberwacht then e.alarm = nil end
    if type(e.warnung) == "number" and type(e.alarm) == "number" and ((richtung == "unter" and not (e.alarm < e.warnung))
      or (richtung == "ueber" and not (e.alarm > e.warnung))) then
      f("grenzen." .. k, "Alarm und Warnung vertauscht, nur Alarm gilt")
      e.warnung = nil
    end
  end
  return e
end

-- ganze Tabelle auf einmal (nur für Prüfungen am Mac; der Ablauf auf dem Sender geht in Stücken über M.schritt)
function M.grenzenFertig(J, roh, still)
  local r = {}
  for k, z in pairs(roh) do r[k] = grenzeFertig(J, k, z, still) end
  return r
end

local function pruefePlatz(J, wo, p, br, ho, kurven)
  if type(p) ~= "table" then fehler(J, wo, "kein Platz, verworfen") return nil end
  for _, n in ipairs({ "x", "y", "b", "h" }) do
    if not ganz(p[n]) then fehler(J, wo .. "." .. n, "fehlt oder keine ganze Zahl, Platz verworfen") return nil end
  end
  local darst = p.darstellung
  if darst ~= nil and not M.DARST[darst] then fehler(J, wo .. ".darstellung", "unbekannt, zahl") darst = nil end
  darst = darst or "zahl"
  local art, s = M.schluessel(p.w)
  if not art then fehler(J, wo .. ".w", "unbekannter Wert, Platz verworfen") return nil end
  if darst == "status" and not (art == "lua" and M.WERTE[s].status) then fehler(J, wo .. ".darstellung", "status passt nicht, zahl") darst = "zahl" end
  if darst ~= "status" and art == "lua" and M.WERTE[s].status then darst = "status" end
  if darst == "kurve" and kurven[1] >= 2 then fehler(J, wo, "mehr als 2 Kurven, zahl") darst = "zahl" end
  -- Mindestgrösse (Abschnitt 7): Tabellenwert × breite / 800, gerundet; Bezug immer 800
  local mb = floor(M.DARST[darst][1] * br / 800 + 0.5)
  local mh = floor(M.DARST[darst][2] * br / 800 + 0.5)
  if p.x < 0 or p.y < 0 or p.x + p.b > br or p.y + p.h > ho or p.b < mb or p.h < mh then
    fehler(J, wo, "Lage oder Grösse ungültig, Platz verworfen")
    return nil
  end
  if darst == "kurve" then kurven[1] = kurven[1] + 1 end
  local q = { x = p.x, y = p.y, b = p.b, h = p.h, w = p.w, art = art, s = s, darst = darst, zusatz = "keine", kurveS = 120,
    roh = (J.d and J.d.format == 2) and p or nil }     -- Original-Platz für studio_symbole.lua (nur Format 2)
  if p.titel ~= nil then
    if type(p.titel) == "string" then q.titel = kuerze(p.titel, 24) else fehler(J, wo .. ".titel", "kein Text") end
  end
  if p.min ~= nil or p.max ~= nil then
    if endlich(p.min) and endlich(p.max) and p.max > p.min then q.min, q.max = p.min, p.max
    else fehler(J, wo .. ".min/max", "ungültig, Standard") end
  end
  for _, n in ipairs({ "farbe", "farbeWarn", "farbeAlarm", "hintergrund" }) do
    if p[n] ~= nil then
      q[n] = farbe(p[n])
      if not q[n] then fehler(J, wo .. "." .. n, "ungültig, Standard") end
    end
  end
  if p.zusatz ~= nil then
    if p.zusatz == "keine" or p.zusatz == "min" or p.zusatz == "max" or p.zusatz == "mittel" then q.zusatz = p.zusatz
    else fehler(J, wo .. ".zusatz", "ungültig, keine") end
  end
  if p.kurveS ~= nil then
    if ganz(p.kurveS) and p.kurveS >= 30 and p.kurveS <= 600 then q.kurveS = p.kurveS
    else fehler(J, wo .. ".kurveS", "ungültig, 120") end
  end
  if p.stufen ~= nil then
    local ok = type(p.stufen) == "table" and #p.stufen <= 3
    local st = {}
    if ok then
      for i, e in ipairs(p.stufen) do
        local fb = type(e) == "table" and farbe(e.farbe)
        if not (fb and endlich(e.ab) and (i == 1 or e.ab > st[i - 1].ab)) then ok = false break end
        st[i] = { ab = e.ab, farbe = fb }
      end
    end
    if ok then q.stufen = st else fehler(J, wo .. ".stufen", "ungültig, Liste verworfen") end
  end
  return q
end

-- Eine Ansicht in Teilen prüfen: je Aufruf höchstens JE_AUFRUF Plätze. Rückgabe: true = fertig.
local JE_AUFRUF = 4                 -- gemessen: Platz mit allen Feldern ~600 Befehle
local function pruefeAnsicht(J, i, a)
  local wo = "ansichten[" .. i .. "]"
  local A = J.ansicht
  if A == nil then
    if type(a) ~= "table" or not ganz(a.breite) or not ganz(a.hoehe) or a.breite < 100 or a.breite > 1024
      or a.hoehe < 100 or a.hoehe > 1024 or type(a.plaetze) ~= "table" then
      fehler(J, wo, "Ansicht verworfen")
      return true
    end
    A = { r = { breite = a.breite, hoehe = a.hoehe, plaetze = {}, roh = (J.d and J.d.format == 2) and a or nil },
      kurven = { 0 }, k = 0 }
    J.ansicht = A
  end
  local bis = math.min(#a.plaetze, 16, A.k + JE_AUFRUF)
  for k = A.k + 1, bis do
    local q = pruefePlatz(J, wo .. ".plaetze[" .. k .. "]", a.plaetze[k], a.breite, a.hoehe, A.kurven)
    if q then A.r.plaetze[#A.r.plaetze + 1] = q end
  end
  A.k = bis
  if A.k < math.min(#a.plaetze, 16) then return false end
  if #a.plaetze > 16 then fehler(J, wo, "mehr als 16 Plätze, Rest verworfen") end
  local key = A.r.breite .. "x" .. A.r.hoehe
  J.ansichten[key] = J.ansichten[key] or A.r
  J.ansicht = nil
  return true
end

-- Ansicht für eine Fenstergrösse ohne eigene Ansicht (einmal je Grösse, im wakeup): die Ansicht mit dem ähnlichsten
-- Seitenverhältnis, bei Gleichstand die grössere Fläche; Plätze proportional auf die freie Fläche unter der eigenen
-- Kopfzeile. kopf(b, h) = Kopfzeilenhöhe dieses Luas bei dieser Fenstergrösse. Zu kleine Plätze werden «zahl», sind
-- sie auch dafür zu klein, fallen sie weg (gezählt in .weg). Rückgabe: Ansicht oder nil (keine da)
function M.anpassen(ansichten, W, H, kopf)
  local best, bd, bf
  for _, a in pairs(ansichten) do
    if not a.angepasst then
      local d = math.abs(math.log((a.breite / a.hoehe) / (W / H)))
      local f = a.breite * a.hoehe
      if best == nil or d < bd - 1e-9 or (d <= bd + 1e-9 and f > bf) then best, bd, bf = a, d, f end
    end
  end
  if best == nil then return nil end
  local kq, kz = kopf(best.breite, best.hoehe), kopf(W, H)
  local fx, fy = W / best.breite, (H - kz) / (best.hoehe - kq)
  local r = { breite = W, hoehe = H, plaetze = {}, roh = best.roh, angepasst = true, weg = 0,
    quelle = best.breite .. "x" .. best.hoehe, sk = { fx = fx, fy = fy, kq = kq, kz = kz, W = W, H = H } }
  local function mind(d, n) return floor(M.DARST[d][n] * W / 800 + 0.5) end
  for _, q in ipairs(best.plaetze) do
    local oben = math.max(q.y, kq)
    local n = {}
    for k, v in pairs(q) do n[k] = v end
    n.x = floor(q.x * fx + 0.5)
    n.y = floor(kz + (oben - kq) * fy + 0.5)
    n.b = math.min(floor(q.b * fx + 0.5), W - n.x)
    n.h = math.min(floor((q.y + q.h - oben) * fy + 0.5), H - n.y)
    if n.darst ~= "zahl" and q.art ~= "leer" and (n.b < mind(n.darst, 1) or n.h < mind(n.darst, 2)) then n.darst = "zahl" end
    if n.b < mind("zahl", 1) or n.h < mind("zahl", 2) then r.weg = r.weg + 1
    else r.plaetze[#r.plaetze + 1] = n end
  end
  return r
end

-- ===== Ablauf beim Modellwechsel, ein Schritt je Aufruf =====
-- Rückgabe: nil = läuft noch, sonst das Ergebnis { zustand = "fehlt"|"geladen"|"kaputt"|"zuNeu", ... }
function M.schritt(w, F)
  local J = w.studioJob
  if J == nil then
    J = { stufe = 1, fehler = 0, k = w.testKennung or M.kennung() }
    J.basis = M.ORDNER .. J.k .. "." .. M.LUA
    J.datei = J.k .. "." .. M.LUA .. ".lua"
    w.studioJob = J
    return nil
  end
  if J.stufe == 1 then                                   -- Studio-Datei suchen und laden
    -- Gewählt im Menü gewinnt; sonst <Kennung>.jet.lua am ersten Ort, der sie hat
    local d, grund
    if type(w.studioWahl) == "string" and w.studioWahl ~= "" then
      J.wahl, J.quelle = "menue", w.studioWahl
      d, grund = studioLaden(w.studioWahl, M.FORMAT)
    else
      J.wahl, grund = "auto", "fehlt"
      for _, o in ipairs(M.orte()) do
        d, grund = studioLaden(o[1] .. J.datei, M.FORMAT)
        if grund ~= "fehlt" then J.quelle = o[1] .. J.datei break end
      end
    end
    if not d then
      J.zustand = grund
      if grund ~= "fehlt" then print("Jet: Studio-Datei " .. tostring(J.quelle) .. ": " .. grund) end
      w.studioJob = nil
      return J
    end
    J.d, J.stufe = d, 2
    return nil
  elseif J.stufe == 2 then                               -- .funke.lua laden, übrig gebliebene .funke.neu
    local fu, grund = studioLaden(J.basis .. ".funke.lua", M.FORMAT)
    -- übrig gebliebene .funke.neu (Strom weg beim Schreiben): nur ohne .funke.lua übernehmen, sonst löschen
    local okO, nf = pcall(io.open, J.basis .. ".funke.neu", "r")
    if okO and nf then
      nf:close()
      local neu = grund == "fehlt" and studioLaden(J.basis .. ".funke.neu", M.FORMAT)
      local okR, r = false, nil
      if neu then okR, r = pcall(os.rename, J.basis .. ".funke.neu", J.basis .. ".funke.lua") end
      if neu and okR and r then fu, grund = neu, nil
      else pcall(os.remove, J.basis .. ".funke.neu") end
    end
    if fu == nil and grund ~= "fehlt" and grund ~= nil then
      J.funkeVerworfen = true
      print("Jet: Studio-Datei " .. J.k .. "." .. M.LUA .. ".funke.lua: " .. tostring(grund) .. ", verworfen")
    end
    J.fu, J.stufe = fu, 3
    return nil
  elseif J.stufe == 3 then                               -- Verzeichnisse in felder.lua einmal aufbauen
    F.feld("tank")
    F.studioEinstellung("tank")
    J.einst, J.werte, J.grenzenRoh, J.funkeEinst, J.funkeGrenzen = {}, {}, {}, {}, {}
    J.stufe = 31
    return nil
  elseif J.stufe == 31 then                              -- Einstellungen der Studio-Datei, in Stücken
    if abschnitt(J, J.d, "einstellungen", M.JE_EINST, einstellung, J.einst, F) then J.stufe = 32 end
    return nil
  elseif J.stufe == 32 then                              -- Einstellungen der .funke.lua
    if abschnitt(J, J.fu, "einstellungen", M.JE_EINST, einstellung, J.funkeEinst, F, true) then J.stufe = 33 end
    return nil
  elseif J.stufe == 33 then                              -- Wert-Anpassungen
    if abschnitt(J, J.d, "werte", M.JE_WERTE, wertEintrag, J.werte, F) then J.stufe = 34 end
    return nil
  elseif J.stufe == 34 then                              -- Grenzen der Studio-Datei
    if abschnitt(J, J.d, "grenzen", M.JE_GRENZEN, grenzeEintrag, J.grenzenRoh, F) then J.stufe = 35 end
    return nil
  elseif J.stufe == 35 then                              -- Grenzen der .funke.lua
    if abschnitt(J, J.fu, "grenzen", M.JE_GRENZEN, grenzeEintrag, J.funkeGrenzen, F, true) then
      J.stufe, J.ai, J.ansichten = 4, 0, {}
    end
    return nil
  elseif J.stufe == 4 then                               -- je Aufruf eine Ansicht
    local liste = J.d.ansichten
    if liste ~= nil and type(liste) ~= "table" then fehler(J, "ansichten", "keine Liste") liste = nil end
    if J.ansicht == nil then J.ai = J.ai + 1 end
    local a = liste and liste[J.ai]
    if a ~= nil and J.ai <= 2 then
      pruefeAnsicht(J, J.ai, a)
      return nil
    end
    if liste and #liste > 2 then fehler(J, "ansichten", "mehr als 2, Rest verworfen") end
    J.stufe = 5
    return nil
  elseif J.stufe == 5 then                               -- Einstellungen zusammenführen (Studio, darüber .funke.lua)
    J.einstStudio = {}
    for k, v in pairs(J.einst) do J.einstStudio[k] = v end
    for k, v in pairs(J.funkeEinst) do J.einst[k] = v end
    local werk = F.standard()
    J.werkC = { ecuArt = J.einst.ecuArt or werk.ecuArt, ecuZellen = J.einst.ecuZellen or werk.ecuZellen }
    J.werk, J.grenzenStudio, J.stufe = werk, {}, 51
    return nil
  elseif J.stufe == 51 then                              -- Studio-Stand der Grenzen merken (Fehler zählt Stufe 53)
    if stueck(J, J.grenzenRoh, M.JE_FERTIG, function(J2, k, z) J2.grenzenStudio[k] = grenzeFertig(J2, k, z, true) end) then
      J.stufe = 52
    end
    return nil
  elseif J.stufe == 52 then                              -- .funke.lua je Feld über die Studio-Grenze (oder Werkgrenze)
    if stueck(J, J.funkeGrenzen, M.JE_FERTIG, function(J2, k, z)
      local g = J2.grenzenRoh[k] or M.werkGrenze(k, F, J2.werkC, J2.werk) or {}
      for n, x in pairs(z) do g[n] = x end
      J2.grenzenRoh[k] = g
    end) then
      J.stufe, J.grenzen = 53, {}
    end
    return nil
  end
  -- Stufe 53: Richtung und Reihenfolge prüfen, in Stücken; danach fertig
  if not stueck(J, J.grenzenRoh, M.JE_FERTIG, function(J2, k, z) J2.grenzen[k] = grenzeFertig(J2, k, z) end) then return nil end
  J.zustand = "geladen"
  -- Format 2: studio_symbole.lua (Referenz) braucht die Original-Tabellen (symbole, ansichten mit Plätzen und deko).
  -- Nur diese bleiben, werte/grenzen/einstellungen der Datei werden frei.
  local d = J.d
  if d.format == 2 then J.roh = { format = 2, symbole = d.symbole, ansichten = d.ansichten } end
  J.d, J.fu, J.grenzenRoh, J.funkeGrenzen, J.funkeEinst, J.werk, J.werkC = nil, nil, nil, nil, nil, nil, nil
  w.studioJob = nil
  return J
end

-- Werkgrenze eines überwachten Lua-Werts als Eintrag in angezeigter Einheit (für das Zusammenführen, Format 6.5).
-- c: Einstellungen mit ecuArt und ecuZellen (ECU-Akku: Werkschwelle je Akkuart, mal Zellen)
-- werk: F.standard() (wird sonst hier gebaut)
function M.werkGrenze(key, F, c, werk)
  local art, s = M.schluessel(key)
  if art ~= "lua" or not M.WERTE[s].u then return nil end
  local n = M.WERTE[s].u
  werk = werk or F.standard()
  c = c or werk
  local wW, wA = werk[n .. "W"], werk[n .. "A"]
  if n == "ecu" then
    local z = F.ECU_WERK[c.ecuArt or 1] or F.ECU_WERK[1]
    wW, wA = z[1], z[2]
  end
  local div = M.teiler(n, c)
  return { richtung = M.WERTE[s][6], warnung = (wW and wW > 0) and wW / div or false,
    alarm = (wA and wA > 0) and wA / div or false }
end

-- ===== .funke.lua schreiben (Abschnitt 9): Text nach Abschnitt 4, erst .funke.neu, prüfen, dann umbenennen =====
local function esc(t)
  return '"' .. t:gsub(".", function(c) return "\\" .. c:byte() end) .. '"'
end
local function zahl(v)
  if ganz(v) then return string.format("%d", v) end
  if v == floor(v) and math.abs(v) < 1e9 then return string.format("%d", floor(v)) end
  return string.format("%.4f", v)
end
M.esc, M.zahl = esc, zahl

-- einst: { [Name in felder.lua] = Wert }, grenzen: { [Schlüssel] = { warnung=, alarm=, aus=, beiMotorAus= } }
function M.funkeText(einst, grenzen)
  local t = { "return { format = 1, einstellungen = {" }
  local namen = {}
  for k in pairs(einst) do namen[#namen + 1] = k end
  table.sort(namen)
  for _, k in ipairs(namen) do
    local s = k:gsub("(%u)", function(c) return "_" .. c:lower() end)
    local v = einst[k]
    local x = type(v) == "boolean" and tostring(v) or (type(v) == "string" and esc(v) or zahl(v))
    t[#t + 1] = " " .. s .. " = " .. x .. ","
  end
  t[#t + 1] = " }, grenzen = {"
  local gk = {}
  for k in pairs(grenzen) do gk[#gk + 1] = k end
  table.sort(gk)
  for _, k in ipairs(gk) do
    local e = grenzen[k]
    local f = {}
    if e.aus == true then f[#f + 1] = "aus = true" elseif e.aus == false then f[#f + 1] = "aus = false" end
    if e.warnung == false then f[#f + 1] = "warnung = false" elseif e.warnung then f[#f + 1] = "warnung = " .. zahl(e.warnung) end
    if e.alarm == false then f[#f + 1] = "alarm = false" elseif e.alarm then f[#f + 1] = "alarm = " .. zahl(e.alarm) end
    if e.beiMotorAus ~= nil then f[#f + 1] = "beiMotorAus = " .. tostring(e.beiMotorAus) end
    t[#t + 1] = " [" .. esc(k) .. "] = { " .. table.concat(f, ", ") .. " },"
  end
  t[#t + 1] = " } }\n"
  return table.concat(t)
end

-- Rückgabe true, wenn geschrieben (oder leer gelöscht)
function M.funkeSchreiben(kennung, text)
  local basis = M.ORDNER .. kennung .. "." .. M.LUA
  pcall(os.mkdir, "SCRIPTS:/studio")
  if text == nil then                                   -- nichts geändert: Datei weg
    pcall(os.remove, basis .. ".funke.lua")
    return true
  end
  local ok, f = pcall(io.open, basis .. ".funke.neu", "w")
  if not ok or not f then return false end
  local okW = pcall(f.write, f, text)
  f:close()
  if not okW or not studioLaden(basis .. ".funke.neu", M.FORMAT) then
    pcall(os.remove, basis .. ".funke.neu")
    return false
  end
  -- Am Sender überschreibt os.rename eine vorhandene Datei nicht (gemessen X18RS 20.11.2026): erst löschen
  local alt = io.open(basis .. ".funke.lua", "r")
  if alt then alt:close() pcall(os.remove, basis .. ".funke.lua") end
  local okR, r = pcall(os.rename, basis .. ".funke.neu", basis .. ".funke.lua")
  return okR and r ~= nil and r ~= false
end

-- ===== Info-Datei (Abschnitt 14), JSON, nur das Studio liest sie =====
local function jtext(t)
  t = tostring(t or "")
  return '"' .. t:gsub('[%c"\\]', function(c)
    if c == '"' then return '\\"' elseif c == "\\" then return "\\\\" elseif c == "\n" then return "\\n" end
    return string.format("\\u%04X", c:byte())
  end) .. '"'
end
M.jtext = jtext

-- Liste aller Telemetriesensoren. Am Sender (X18RS, Ethos 26.2.0, 20.11.2026, Befund Elektro) liefert getSources mit
-- einer Tabelle { category = … } eine LEERE Liste; mit der Kategorie als Zahl geht es (wie die Sensorsuche).
local function sensorListe()
  if not (system.getSources and CATEGORY_TELEMETRY_SENSOR) then return {} end
  local ok, l = pcall(system.getSources, CATEGORY_TELEMETRY_SENSOR)
  if ok and type(l) == "table" and #l > 0 then return l end
  ok, l = pcall(system.getSources, { category = CATEGORY_TELEMETRY_SENSOR })
  if ok and type(l) == "table" then return l end
  return {}
end

-- Sensorliste in Schritten (je Aufruf 10, höchstens 100). Rückgabe: nil = läuft, sonst true (geschrieben/unnötig)
function M.infoSchritt(w, version, formate)
  local I = w.infoJob
  if I == nil then
    I = { i = 0, s = {} }
    I.liste = sensorListe()
    w.infoJob = I
    return nil
  end
  local bis = math.min(#I.liste, I.i + 10, 100)
  for i = I.i + 1, bis do
    local q = I.liste[i]
    local function r(f) local okf, v = pcall(q[f], q) if okf then return v end return nil end
    local a, sub, ph, nm, e = r("appId"), r("subId"), r("physId"), r("name"), r("unit")
    local t = '{ "appId": ' .. (ganz(a) and a or 0) .. ', "sub": ' .. (ganz(sub) and sub or 0)
      .. ', "phys": ' .. (ganz(ph) and ph or 0) .. ', "name": ' .. jtext(nm)
    local okE, eh = false, nil
    if e ~= nil and system.getUnitName then okE, eh = pcall(system.getUnitName, e) end
    if okE and type(eh) == "string" and eh ~= "" then t = t .. ', "einheit": ' .. jtext(eh) end
    I.s[#I.s + 1] = t .. " }"
  end
  I.i = bis
  if I.i < math.min(#I.liste, 100) then return nil end
  local okV, ver = pcall(system.getVersion)
  ver = okV and type(ver) == "table" and ver or {}
  local fenster = {}
  for _, f in ipairs(w.fenster or {}) do fenster[#fenster + 1] = '{ "breite": ' .. f[1] .. ', "hoehe": ' .. f[2] .. ' }' end
  local okN, name = pcall(model.name)
  local okP, pfad = pcall(model.path)
  local st = w.studio and w.studio.zustand or w.studioZustand or "fehlt"
  local t = '{\n "format": 1,\n "lua": "' .. M.LUA .. '",\n "luaVersion": ' .. jtext(version)
    .. ',\n "formate": [' .. table.concat(formate, ", ") .. '],\n "modell": ' .. jtext(w.testKennung and "JET DEMO" or (okN and name or ""))
    .. ',\n "kennung": ' .. jtext(w.testKennung or M.kennung())
    .. ((okP and type(pfad) == "string") and (',\n "modellPfad": ' .. jtext(pfad)) or "")
    .. ',\n "funke": ' .. jtext(ver.board) .. ',\n "ethos": ' .. jtext(ver.version)
    .. ',\n "fenster": [' .. table.concat(fenster, ", ") .. '],\n "beiMotorAus": true,\n "studioDatei": ' .. jtext(st)
    .. ((w.studioFehler and w.studioFehler > 0) and (',\n "fehler": ' .. w.studioFehler) or "")
    .. ',\n "sensoren": [\n  ' .. table.concat(I.s, ",\n  ") .. '\n ]'
    .. ',\n "studioQuelle": ' .. jtext(w.studioQuelle or "") .. ',\n "studioWahl": ' .. jtext(w.studioWahlArt or "auto")
    .. ',\n "ansichtGenutzt": ' .. jtext(w.ansichtGenutzt or "") .. ',\n "angepasst": ' .. tostring(w.angepasst == true)
    .. ',\n "hinweis": ' .. jtext(w.sDauer or w.sHinweis or "") .. '\n}\n'
  w.infoJob = nil
  if t == w.infoAlt then return true end               -- nichts geändert: nicht schreiben (SD-Karte schonen)
  pcall(os.mkdir, "SCRIPTS:/studio")
  local ok, f = pcall(io.open, M.ORDNER .. (w.testKennung or M.kennung()) .. "." .. M.LUA .. ".info.json", "w")
  if ok and f then
    local okW = pcall(f.write, f, t)
    f:close()
    if okW then w.infoAlt = t return true end
  end
  print("Jet: Info-Datei konnte nicht geschrieben werden")
  return true
end

-- ===== Anwenden und Betrieb =====
-- Grenze eines überwachten Werts als Ganzzahlen im cfg (<name>W, <name>A), aus dem Eintrag e (oder Werk).
-- melden: Grenze über dem Menübereich als Fehler zählen (nur für die geltende Grenze, nicht für den Studio-Stand)
local function grenzeCfg(J, F, c, n, e, werk, melden)
  local info = M.UEBERWACHT[n]
  local key, div = "lua:" .. info[1], M.teiler(n, c)
  local wW, wA = werk[n .. "W"], werk[n .. "A"]
  if n == "ecu" then                                 -- ECU-Akku: Werkschwelle je Akkuart (wie im Menü)
    local z = F.ECU_WERK[c.ecuArt] or F.ECU_WERK[1]
    wW, wA = z[1], z[2]
  end
  if e == nil or e.werk then return wW, wA end
  if e.aus then return 0, 0 end
  local a = J.werte and J.werte[key]
  local fW, fA = F.feld(n .. "W"), F.feld(n .. "A")
  local function roh(x, f, werkWert, stufe)
    if x == "werk" then return werkWert end           -- ungültige Stufe: Werkgrenze
    if x == nil then return 0 end
    if a then x = (x - a.versatz) / a.faktor end      -- Grenze gilt im angezeigten Wert, cfg im Rohwert
    x = floor(x * div + 0.5)
    if x < 1 then x = 1 end                          -- 0 hiesse «Stufe aus»: eine gesetzte Grenze bleibt an
    if x > f[6] then                                 -- über dem Menübereich: nicht still kürzen, Werkgrenze
      if melden then fehler(J, "grenzen." .. key .. "." .. stufe, "über dem Bereich im Menü, Werkgrenze") end
      return werkWert
    end
    return x
  end
  return roh(e.warnung, fW, wW, "warnung"), roh(e.alarm, fA, wA, "alarm")
end

-- Ergebnis von M.schritt auf das Widget anwenden (nur bei Zustand «geladen»), in Schritten wie M.schritt
-- (Befehlsgrenze). Das cfg des Widgets und w.studio ändern sich erst im letzten Schritt, alles auf einmal.
-- Rückgabe true = fertig.
function M.anwendenSchritt(w, J, F)
  local A = J.anw
  if A == nil then                                   -- 1: Einstellungen (Studio-Stand und geltender Wert)
    local werk = F.standard()
    A = { werk = werk, cfg = {}, S = { zustand = "geladen", werte = J.werte, ansichten = J.ansichten, einstBasis = {},
      grenzBasis = {}, gAns = {}, gVib = {}, extra = {}, quellen = {}, offen = {}, st = {}, zx = {}, kurven = {} },
      schl = {}, stufe = 2 }
    J.anw = A
    for _, g in ipairs(F.gruppen) do
      for _, f in ipairs(g[2]) do
        local k = f[1]
        if F.studioEinstellung(k) then
          local b = J.einstStudio[k]
          if b == nil then b = werk[k] end
          A.S.einstBasis[k] = b
          local v = J.einst[k]
          if v == nil then v = werk[k] end
          A.cfg[k] = v
        end
      end
    end
    return false
  end
  local S, cv = A.S, A.cfg
  if A.stufe == 2 then                               -- 2: Grenzen der überwachten Werte (mit den neuen Einstellungen)
    local c = setmetatable({}, { __index = function(_, k) local v = cv[k] if v == nil then v = w.cfg[k] end return v end })
    for n, info in pairs(M.UEBERWACHT) do
      local key = "lua:" .. info[1]
      local e = J.grenzen[key]
      cv[n .. "W"], cv[n .. "A"] = grenzeCfg(J, F, c, n, e, A.werk, true)
      local bW, bA = grenzeCfg(J, F, c, n, J.grenzenStudio[key], A.werk)
      local gs = J.grenzenStudio[key]
      cv[n .. "MA"] = not (e and e.beiMotorAus == false)            -- «auch bei Turbine aus», fehlt = true
      S.grenzBasis[n] = { bW, bA, not (gs and gs.beiMotorAus == false) }
      if e then S.gAns[n], S.gVib[n] = e.ansage, e.vibration end
    end
    A.stufe = 3
    return false
  end
  if A.stufe == 3 then                               -- 3: weitere Grenzen (Sensoren, Kanäle, nicht überwachte Lua-Werte)
    if stueck(J, J.grenzen, M.JE_EXTRA, function(_, key, e)
      local art, s = M.schluessel(key)
      if not (art == "lua" and M.WERTE[s].u) and not e.aus and (e.warnung or e.alarm) then
        -- Höchstens M.MAX_EXTRA weitere Grenzen: sie laufen bei jedem Lesen in einem Aufruf (~150 Befehle je Grenze,
        -- Befehlsgrenze am Sender; Prüfungen 6/7, 20.11.2026). Behalten werden immer die mit den kleinsten Schlüsseln
        -- (unabhängig von der Reihenfolge in der Tabelle), der Rest wird mit Hinweis verworfen.
        local X = S.extra
        if #X >= M.MAX_EXTRA then
          local gi = 1
          for i = 2, #X do if X[i].key > X[gi].key then gi = i end end
          if key > X[gi].key then
            fehler(J, "grenzen." .. tostring(key), "mehr als " .. M.MAX_EXTRA .. " weitere Grenzen, verworfen") return
          end
          local alt = table.remove(X, gi)
          fehler(J, "grenzen." .. tostring(alt.key), "mehr als " .. M.MAX_EXTRA .. " weitere Grenzen, verworfen")
          S.gAns[alt.key], S.gVib[alt.key], A.schl[alt.key] = nil, nil, nil
        end
        X[#X + 1] = { key = key, art = art, s = s, e = e }
        S.gAns[key], S.gVib[key] = e.ansage, e.vibration
        if art == "sensor" or art == "kanal" then A.schl[key] = true end
      end
    end) then A.stufe = 4 end
    return false
  end
  -- 4: Quellen der Ansichten, dann alles auf einmal übernehmen
  for _, a in pairs(J.ansichten) do
    for _, q in ipairs(a.plaetze) do
      if q.art == "sensor" or q.art == "kanal" then A.schl[q.w] = true end
    end
  end
  for key in pairs(A.schl) do S.offen[#S.offen + 1] = key end
  local c = w.cfg
  for k, v in pairs(cv) do c[k] = v end
  S.fehler = J.fehler                               -- mit den Fehlern aus Schritt 2 (Grenze über dem Menübereich)
  J.anw = nil
  w.studio = S
  return true
end

-- alles auf einmal (nur für Prüfungen am Mac)
function M.anwenden(w, J, F)
  while not M.anwendenSchritt(w, J, F) do end
end

-- Sensoren und Kanäle der Studio-Datei suchen, in Schritten. Rückgabe true = fertig.
function M.quellenSchritt(w)
  local S = w.studio
  local key = S.offen[#S.offen]
  if key == nil then return true end
  local art, a, sub, ph = M.schluessel(key)
  local q, eh, dez = nil, nil, nil
  if art == "kanal" and CATEGORY_CHANNEL then
    local ok, r = pcall(system.getSource, { category = CATEGORY_CHANNEL, member = a - 1 })
    if ok and r ~= nil then
      local okV, v = pcall(function() return r:value() end)   -- Format 2, Regel 7.3: auch den Wert prüfen
      if okV and v ~= nil then q, eh, dez = r, "%", 0 end
    end
  elseif art == "sensor" then
    -- Sensorliste in Stücken durchgehen (AppID, Teilwert, Physical ID falls angegeben). Nicht über getSource mit
    -- appId: am Sender lieferte das ein Objekt ohne Wert (value nil, Befund Elektro X18RS 20.11.2026).
    local P = S.phys
    if P == nil or P.key ~= key then
      S.phys = { key = key, l = S.sensoren or sensorListe(), i = 0 }
      S.sensoren = S.phys.l                             -- Liste nur einmal je Studio-Datei holen
      return false
    end
    local bis = math.min(#P.l, P.i + 20)
    for i = P.i + 1, bis do
      local s = P.l[i]
      local function r(f) local okf, v = pcall(s[f], s) if okf then return v end return nil end
      if r("appId") == a and (r("subId") or 0) == sub and (ph == nil or r("physId") == ph) then q = s break end
    end
    P.i = bis
    if q == nil and P.i < #P.l then return false end
    S.phys = nil
  end
  -- wie felder.lua: nur eine echte Quelle (Ethos liefert für Unbekanntes eine Quelle der Kategorie NONE)
  local tq = type(q)
  if not (tq == "userdata" or (tq == "table" and type(q.value) == "function")) then q = nil
  elseif CATEGORY_NONE then
    local okK, kat = pcall(q.category, q)
    if okK and kat == CATEGORY_NONE then q = nil end
  end
  if q ~= nil and art == "sensor" then
    local okD, d = pcall(q.decimals, q)
    if okD and math.type(d) == "integer" then dez = d end
    local okU, u = pcall(q.unit, q)
    if okU and u ~= nil and system.getUnitName then
      local okN, nm = pcall(system.getUnitName, u)
      if okN and type(nm) == "string" then eh = nm end
    end
  end
  if q == nil then print("Jet: Studio: " .. key .. " nicht gefunden, Platz zeigt ---") end
  S.quellen[key] = q and { q = q, eh = eh, dez = dez, kanal = art == "kanal" } or false
  S.offen[#S.offen] = nil
  if #S.offen == 0 then S.sensoren = nil end
  return #S.offen == 0
end

-- Wert eines Schlüssels: Zahl (angepasst nach «werte»), Einheit, Stellen, Name (Sprache sp)
function M.wert(w, key, art, s, sp)
  local S, v = w.studio, w.v
  local x, eh, dez, name
  if art == "lua" then
    local d = M.WERTE[s]
    local f = d[1]
    if f == "!laufzeit" then x = w.akt and w.akt[2] or 0
    elseif f == "!ml" then x = v.mlRest or v.ml
    elseif f == "!laeufe" then x = w.dauer and w.dauer.laeufe or 0
    elseif f == "!status" then x = w.absch and 4 or (w.tb and w.tb[1] and w.tb[1].gruppe) or nil
    else x = v[f] end
    eh, dez, name = d[2], d[3], d[sp == 2 and 8 or 7]
  elseif art == "sensor" or art == "kanal" then
    local Q = S.quellen[key]
    if Q then
      local ok, r = pcall(Q.q.value, Q.q)
      if ok and type(r) == "number" and r == r then x = Q.kanal and r / 10.24 or r end
      eh, dez = Q.eh, Q.dez
    end
    name = key
  else
    return nil, "", 0, ""
  end
  local a = S.werte[key]
  if a then
    if x then x = x * a.faktor + a.versatz end
    eh, dez, name = a.einheit or eh, a.stellen or dez, a.name or name
  end
  return x, eh or "", dez or 0, name or ""
end

-- Laufend (je wakeup nach dem Lesen): Quellen suchen, Min/Max/Mittel, Kurvenpunkte der sichtbaren Ansicht
function M.wecke(w, now)
  local S = w.studio
  if #S.offen > 0 then M.quellenSchritt(w) end
  local L = w.L
  local a = L and S.ansichten[L.W .. "x" .. L.H]
  if a == nil then return end
  for i, q in ipairs(a.plaetze) do
    if q.zusatz ~= "keine" or q.darst == "kurve" then
      local x = M.wert(w, q.w, q.art, q.s, 1)
      if x and q.zusatz ~= "keine" then
        local z = S.zx[q.w]
        if z == nil then z = { x, x, 0, 0 } S.zx[q.w] = z end
        if x < z[1] then z[1] = x end
        if x > z[2] then z[2] = x end
        z[3], z[4] = z[3] + x, z[4] + 1
      end
      if q.darst == "kurve" then
        local K = S.kurven[i]
        if K == nil or K.w ~= q.w then K = { w = q.w, n = 0, p = {}, t = -1e9 } S.kurven[i] = K end
        if now - K.t >= q.kurveS / 120 then
          K.t = now
          K.n = K.n % 120 + 1                           -- Ringpuffer, höchstens 120 Punkte
          K.p[K.n] = x or false
          K.voll = K.voll or K.n == 120
        end
      end
    end
  end
end

-- Min/Max/Mittel beginnen neu (neuer Flug)
function M.flugNeu(w)
  if w.studio then w.studio.zx = {} end
end

-- Grenzen der weiteren Werte prüfen (aus warnungen im Kern, mit dessen melde). Rückgabe: höchste Stufe
function M.grenzenExtra(w, now, melde, tele)
  local S = w.studio
  local hoechst = 0
  for _, x in ipairs(S.extra) do
    local wert, _, dez = M.wert(w, x.key, x.art, x.s, 1)
    local e = x.e
    local function jenseits(gr)
      if gr == nil or wert == nil then return false end
      if e.richtung == "unter" then return wert < gr end
      return wert > gr
    end
    local al = tele and jenseits(e.alarm) or false
    local m = melde(w, now, x.key .. "A", 2, al, nil, wert, 0, dez, e.beiMotorAus)
    local wn = melde(w, now, x.key .. "W", 1, tele and not al and jenseits(e.warnung) or false, nil, wert, 0, dez, e.beiMotorAus)
    local st = wert ~= nil and (m and 2 or ((wn or jenseits(e.warnung)) and 1 or 0)) or nil
    S.st[x.key] = st
    if st and st > hoechst then hoechst = st end
  end
  return hoechst
end

-- Änderungen aus dem Funken-Menü gegenüber dem Studio-Stand als Text für .funke.lua (nil = keine Änderung)
function M.funkeAusCfg(w, F)
  local S, c = w.studio, w.cfg
  local einst, grenzen, n = {}, {}, 0
  for k, b in pairs(S.einstBasis) do
    if c[k] ~= b then einst[k] = c[k] n = n + 1 end
  end
  for nm, info in pairs(M.UEBERWACHT) do
    local b = S.grenzBasis[nm]
    local cw, ca = c[nm .. "W"] or 0, c[nm .. "A"] or 0
    local key = "lua:" .. info[1]
    local ma = c[nm .. "MA"] ~= false
    if ma ~= (b[3] ~= false) then                    -- «auch bei Turbine aus» geändert: zählt je Feld wie ansage
      grenzen[key] = { beiMotorAus = ma }
      n = n + 1
    end
    if cw ~= b[1] or ca ~= b[2] then
      local a = S.werte[key]
      local function anz(x)
        if x == 0 then return false end              -- Stufe aus
        x = x / M.teiler(nm, c)
        if a then x = x * a.faktor + a.versatz end
        return x
      end
      local mg = grenzen[key] and grenzen[key].beiMotorAus
      if cw == 0 and ca == 0 then grenzen[key] = { aus = true, beiMotorAus = mg }
      else grenzen[key] = { aus = false, warnung = anz(cw), alarm = anz(ca), beiMotorAus = mg } end   -- hebt ein «aus» der Studio-Datei auf
      n = n + 1
    end
  end
  if n == 0 then return nil end
  return M.funkeText(einst, grenzen)
end

return M
