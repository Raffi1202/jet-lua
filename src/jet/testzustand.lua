-- Jet: Testhaken «Zustand als JSON» (bauplan.md, Abschnitt Testhaken). Nur im Simulator in Gebrauch:
-- Der Kern lädt diese Datei erst, wenn der Ablauf TEST.zustand setzt und Ethos meldet, dass es ein Simulator ist.
-- Auf dem Sender wird sie nie geladen und kostet keinen Speicher.
-- Schreibt den Zustand des Widgets in die Datei test-zustand.json im Skriptordner. Der Treiber liest sie mit
-- readFile und vergleicht sie mit dem erwarteten Zustand, ohne Bild.
local floor = math.floor

local function zk(s)
  return '"' .. s:gsub('[%c"\\]', function(c)
    if c == '"' then return '\\"' elseif c == "\\" then return "\\\\" end
    return string.format("\\u%04x", c:byte())
  end) .. '"'
end

-- Quelle (userdata) als Name, sonst nil
local function quelle(q)
  local ok, n = pcall(function() return q:name() end)
  if ok and type(n) == "string" then return n end
  return nil
end

local function json(x, tiefe)
  local t = type(x)
  if t == "number" then
    if x ~= x or x == math.huge or x == -math.huge then return "null" end
    if x == floor(x) and x > -1e15 and x < 1e15 then return string.format("%d", x) end
    return string.format("%.6g", x)
  elseif t == "boolean" then return tostring(x)
  elseif t == "string" then return zk(x)
  elseif t == "userdata" then local n = quelle(x) return n and zk(n) or "null"
  elseif t ~= "table" or tiefe > 4 then return "null" end
  if #x > 0 then                                   -- Liste
    local a = {}
    for i = 1, #x do a[i] = json(x[i], tiefe + 1) end
    return "[" .. table.concat(a, ",") .. "]"
  end
  local k = {}
  for n, v in pairs(x) do
    if type(n) == "string" and type(v) ~= "function" then k[#k + 1] = n end
  end
  table.sort(k)
  local a = {}
  for i = 1, #k do a[i] = zk(k[i]) .. ":" .. json(x[k[i]], tiefe + 1) end
  return "{" .. table.concat(a, ",") .. "}"
end

-- Feste Felder in jedem Lua gleich. Eigene Felder eines Lua kommen nach w.testExtra (Tabelle), sie stehen dann
-- unter «extra».
return function(w, now, datei)
  local aktiv = {}
  for i = 1, w.nAktiv or 0 do aktiv[i] = w.aktiv[i].name end
  local L = w.L
  local z = {
    name = w.name, version = w.version, zeit = now, seite = w.seite, seiten = w.seiten,
    zustand = w.zustand, stufe = w.stufe, meldung = (w.nAktiv or 0) > 0 and w.meldText or "", aktiv = aktiv,
    werte = w.v, dauer = w.dauer, grenzen = w.g, cfg = w.cfg, dialog = w.dialog or "", hinweis = w.hinweis or "",
    sprache = w.sp, fenster = L and { L.W, L.H } or nil, fehler = w.fehler or "", gelesen = w.gelesen,
    speicherKB = floor(collectgarbage("count")), extra = w.testExtra,
  }
  local f = io.open(datei, "w")
  if not f then return false end
  f:write(json(z, 0))
  f:close()
  return true
end
