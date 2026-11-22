-- Jet: Pflichttests Lua-Studio-Format 2 (Format 2, Abschnitt 9, Tests 1–17) auf dem Mac, mit dem echten kern.lua.
-- Aufruf aus dem Repo-Ordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/format2-test.lua ["<Ordner Testdateien>"]
--   Ordner = the folder with the Lua-Studio format 2 test files (p*.lua und symbole/), wird nur gelesen.
--   Ohne Angabe: Ordner aus der Umgebungsvariable JET_FORMAT2_TESTDATEIEN (Testdateien zum Lua-Studio-Format 2).
-- Läuft in einer Kopie von src/jet in einem temporären Ordner. Die Testdateien nennen Elektro-Werte (lua:akku_proz …);
-- der Test ersetzt sie durch Jet-Werte, sonst bleiben die Dateien gleich. Prüft je Testdatei: geladen / fehlend /
-- verworfen (S.zaehler), loadMask nur für gültige Dateien, keine Datei ausserhalb von symbole/, Modellwechsel ohne
-- Speicherwachstum, «---» bei fehlendem Sensor, Listen höchstens 48. Befehle je wakeup unter 5000 (Fehler).
-- Befehle je ganzem paint (auch im ersten paint, während S.schritt noch läuft) werden gemessen und als MESSUNG
-- ausgegeben: die eingebaute Seite von Jet liegt schon ohne Studio-Datei darüber (wie Elektro 0.4.0, rund 8800 hier,
-- läuft am X18RS seit 0.1.x ohne Abbruch). Fehler nur, wenn Format 2 das paint um mehr als die Referenz verteuert
-- (Vergleich mit derselben Datei als Format 1, Grenze 3600 Befehle; 0.5.6 vorübergehend 5000 wegen der Symbole, seit
-- 0.6.0 ohne Symbole wieder 3600. Begründung für 0.5.6: Sendertest
-- X18RS 0.5.3–0.5.5 mit ~14 500 je paint ohne «Max instructions»; die Spitze entsteht nur beim Laden der Symbole
-- (Platzköpfe werden bis zum Ende des Ladens je paint neu gewählt), der Dauerbetrieb danach liegt tiefer, siehe MESSUNG).
local quelle = arg[0]:gsub("test/format2%-test%.lua$", "") .. "src/jet"
local testOrdner = arg[1] or os.getenv("JET_FORMAT2_TESTDATEIEN")
if not testOrdner or testOrdner == "" then
  print("Testordner fehlt: lua test/format2-test.lua <Ordner> oder Umgebungsvariable JET_FORMAT2_TESTDATEIEN setzen")
  os.exit(2)
end
local tmp = os.tmpname()
os.remove(tmp)
assert(os.execute("mkdir -p '" .. tmp .. "/jet/daten' '" .. tmp .. "/SCRIPTS/studio' && cp '" .. quelle .. "'/*.lua '" .. tmp .. "/jet/'"))
assert(os.execute("cp -R '" .. testOrdner .. "/symbole' '" .. tmp .. "/SCRIPTS/studio/symbole'"))

local GRENZE = 5000
local fehler = 0
local zeilen = {}
local print_ = print
print = function(...)
  local t = {}
  for i = 1, select("#", ...) do t[#t + 1] = tostring((select(i, ...))) end
  t = table.concat(t, " ")
  zeilen[#zeilen + 1] = t
end
local messungen = {}
local function messung(text) messungen[#messungen + 1] = text end
local function pruefe(ok, text)
  print_((ok and "ok     " or "FEHLER ") .. text)
  if not ok then fehler = fehler + 1 end
end

-- Pfade wie am Sender: SCRIPTS:/ -> tmp/SCRIPTS/, relative -> Skriptordner
local function pfad(p)
  if p:sub(1, 9) == "SCRIPTS:/" then return tmp .. "/SCRIPTS/" .. p:sub(10) end
  if p:sub(1, 1) == "/" then return p end
  return tmp .. "/jet/" .. p
end
local geoeffnet = {}
local io_open = io.open
io.open = function(p, m)
  if type(p) == "string" and p:find("symbole", 1, true) then geoeffnet[#geoeffnet + 1] = p end
  return io_open(pfad(p), m)
end
local laden = loadfile
loadfile = function(p, ...) return laden(pfad(p), ...) end
local os_rename, os_remove = os.rename, os.remove
os.rename = function(a, b)
  local f = io_open(pfad(b), "r")
  if f then f:close() return nil, "exists" end
  return os_rename(pfad(a), pfad(b))
end
os.remove = function(p) return os_remove(pfad(p)) end
os.mkdir = function() return true end

-- Ethos-Nachbildung (unbekannte Funktionen von system/lcd: C-Funktion ohne Rückgabe)
local T = 0
os.clock = function() return T end
local BREITE, W, H = 800, 800, 480
local CF = coroutine.running              -- C-Funktion, nimmt beliebige Argumente an, zählt in Lua nicht
local function stumm(t) return setmetatable(t, { __index = function() return CF end }) end
system = stumm({ getVersion = function() return { simulation = false, board = "X18RS", version = "26.2.0", lcdWidth = BREITE } end,
  getSource = function() return nil end, getSources = function() return {} end, getLocale = function() return "de" end,
  getAudioVoice = function() return "de" end })
model = stumm({ name = function() return "TEST" end, path = function() return "models/test.bin" end })
storage = { read = function() return nil end, write = function() end }
local masken = {}
-- Zeichenbefehle als C-Funktionen: am Sender sind lcd.* C-Funktionen, ihre Befehle zählen nicht in Lua.
-- getTextSize gibt immer 70 × 14 (eine Lua-Zeile).
lcd = stumm({ getWindowSize = function() return W, H end, isVisible = function() return true end,
  RGB = math.max, getTextSize = function() return 70, 14 end, color = CF, font = CF, drawText = CF, drawLine = CF,
  drawRectangle = CF, drawFilledRectangle = CF, drawFilledCircle = CF, drawAnnulusSector = CF, drawMask = CF, invalidate = CF,
  loadMask = function(p) masken[#masken + 1] = p return { p = p } end })
for i, n in ipairs({ "FONT_XS", "FONT_S", "FONT_STD", "FONT_L", "FONT_XL", "FONT_XXL", "FONT_BOLD", "FONT_STD_BOLD",
  "LEFT", "CENTERED", "RIGHT", "UNIT_PERCENT", "UNIT_VOLT", "UNIT_MILLIAMPERE_HOUR", "UNIT_AMPERE", "UNIT_RPM",
  "UNIT_CELSIUS", "UNIT_METER", "UNIT_METER_PER_SECOND", "UNIT_KPH", "UNIT_DB", "WHITE", "TEXT_LEFT", "TEXT_CENTERED", "TEXT_RIGHT" }) do _ENV[n] = i end
CATEGORY_TELEMETRY_SENSOR, CATEGORY_CHANNEL, CATEGORY_NONE = 101, 102, 0

local function esc(t) return '"' .. t:gsub(".", function(c) return "\\" .. c:byte() end) .. '"' end
-- Elektro-Werte der Testdateien -> Jet-Werte
local ERSATZ = { { "lua:akku_proz", "lua:kraftstoff_proz" }, { "lua:spannung", "lua:ecu_akku" }, { "lua:flugzeit", "lua:laufzeit" } }
local ZIEL = tmp .. "/SCRIPTS/studio/TEST.jet.lua"
local function bereite(datei)
  local a = assert(io_open(datei:find("/", 1, true) and datei or (testOrdner .. "/" .. datei), "rb")) local t = a:read("a") a:close()
  for _, e in ipairs(ERSATZ) do
    local von, nach = esc(e[1]), esc(e[2])
    local i = 1
    while true do
      local s, x = t:find(von, i, true)
      if not s then break end
      t = t:sub(1, s - 1) .. nach .. t:sub(x + 1)
      i = s + #nach
    end
  end
  local b = assert(io_open(ZIEL, "wb")) b:write(t) b:close()
end

local function messe(f, ...)
  local n = 0
  debug.sethook(function() n = n + 1 end, "", 1)
  local ok, e = pcall(f, ...)
  debug.sethook()
  if not ok then print_("  Fehler: " .. tostring(e)) end
  return n, ok
end

-- Datei laden wie nach einem Modellwechsel; paint nach jedem wakeup (auch solange S.schritt läuft).
-- Rückgabe: w, höchste Befehle je wakeup, je paint, Zähler der Referenz, Absturz, K, Befehle im ersten paint mit Symbolen
local function lauf(datei, fenster, n)
  if datei then bereite(datei) else os_remove(ZIEL) end
  masken, geoeffnet, zeilen = {}, {}, {}
  W, H = fenster[1], fenster[2]
  local K = assert(loadfile("kern.lua"))()
  local w = K.neu()
  K.lies(w)
  local maxW, maxP, absturz, ersterP, maxS, maxD = 0, 0, false, nil, 0, 0
  for _ = 1, n or 600 do
    T = T + 0.2
    local nw, okW = messe(K.wecke, w)
    local warOffen = w.symOffen
    local np, okP = messe(K.zeichne, w)
    if warOffen and ersterP == nil then ersterP = np end
    if not (okW and okP) then absturz = true end
    if nw > maxW then maxW = nw end
    if np > maxP then maxP = np end
    if w.studio and w.studio.ansichten[W .. "x" .. H] and np > maxS then maxS = np end   -- paint der Studio-Ansicht
    if _ > (n or 600) - 20 and not w.symOffen and np > maxD then maxD = np end            -- Dauerbetrieb nach dem Laden
  end
  local g, f, v = 0, 0, 0
  if w.sym then g, f, v = w.sym.zaehler() end
  return w, maxW, maxP, { g, f, v }, absturz, K, ersterP, maxS, maxD
end

local function gleich(z, e) return z[1] == e[1] and z[2] == e[2] and z[3] == e[3] end
local function txt(z) return z[1] .. " / " .. z[2] .. " / " .. z[3] end

-- Tests 1–10, 12, 15 (bei 800), 16, 17 je Testdatei, in beiden Ansichten von Jet mit Studio-Belegung
local faelle = {
  { "p00_bild.lua", { 0, 0, 0 } },
  { "p01_kaputte_png.lua", { 0, 0, 0 } },
  { "p06_100_symbole.lua", { 0, 0, 0 } },
  { "p07_namen.lua", { 0, 0, 0 } },
  { "p08_px.lua", { 0, 0, 0 } },
  { "p09_deko.lua", { 0, 0, 15 } },
  { "p10_symbol_ohne_eintrag.lua", { 0, 0, 0 } },
  { "p12_voll.lua", { 0, 0, 0 } },
  { "p16_wertanpassungen.lua", { 0, 0, 0 } },
  { "p17_schmaltexte.lua", { 0, 0, 0 } },
}
local hoechstW, hoechstP = 0, 0
for _, fa in ipairs(faelle) do
  for _, fe in ipairs({ { 800, 480 }, { 784, 316 }, { 640, 360 } }) do   -- 640x360: umgerechnete Ansicht (0.5.0)
    local w, maxW, maxP, z, absturz, _, ersterP, maxS, maxD = lauf(fa[1], fe)
    pruefe(not absturz and w.studioZustand == "geladen" and gleich(z, fa[2]),
      string.format("%s %dx%d: %s (erwartet %s)", fa[1], fe[1], fe[2], txt(z), txt(fa[2])))
    pruefe(maxW < GRENZE, string.format("%s %dx%d: wakeup höchstens %d Befehle (< %d)", fa[1], fe[1], fe[2], maxW, GRENZE))
    messung(string.format("%s %dx%d: wakeup %d, paint %d (Studio-Ansicht %d, Dauerbetrieb nach dem Laden %d), erstes paint mit laufendem S.schritt %s",
      fa[1], fe[1], fe[2], maxW, maxP, maxS, maxD, tostring(ersterP)))
    if maxW > hoechstW then hoechstW = maxW end
    if maxP > hoechstP then hoechstP = maxP end
    -- 0.6.0 (Entscheid User 22.11.): keine Symbole mehr: nie loadMask, nie eine Datei unter studio/symbole/ öffnen
    local keine = #masken == 0
    for _, p in ipairs(geoeffnet) do if p:find("/symbole/", 1, true) then keine = false print_("  geöffnet: " .. p) end end
    pruefe(keine, string.format("0.6.0: %s %dx%d: keine Symboldatei geöffnet, kein loadMask", fa[1], fe[1], fe[2]))
    if fa[1] == "p16_wertanpassungen.lua" and fe[1] == 800 then
      -- Regel 7.2: werte, grenzen, einstellungen höchstens 48; 100 Wert-Anpassungen -> 52 verworfen mit Hinweis
      local n = 0
      for _ in pairs(w.studio.werte) do n = n + 1 end
      local hinweis = false
      for _, zl in ipairs(zeilen) do if zl:find("werte: 52 Einträge über 48 verworfen", 1, true) then hinweis = true end end
      pruefe(n <= 48 and hinweis, "16: 100 Wert-Anpassungen: " .. n .. " übernommen (<= 48), Rest verworfen mit Hinweis")
    end
  end
end

-- Tests 12/17: Mehrkosten von Format 2 im paint gegenüber derselben Datei als Format 1 (ohne Symbole, ohne Schmuck)
local function alsFormat1(datei)
  bereite(datei)
  local a = assert(io_open(ZIEL, "rb")) local t = a:read("a") a:close()
  t = t:gsub("format = 2", "format = 1", 1)
  local b = assert(io_open(testOrdner:gsub(".*", tmp) .. "/f1.lua", "wb")) b:write(t) b:close()
end
for _, d in ipairs({ "p12_voll.lua", "p06_100_symbole.lua", "p17_schmaltexte.lua" }) do
  for _, fe in ipairs(d == "p12_voll.lua" and { { 800, 480 }, { 784, 316 } } or { { 800, 480 } }) do
    local _, _, _, _, _, _, _, p2 = lauf(d, fe)
    alsFormat1(d)
    local f1 = assert(io_open(tmp .. "/f1.lua", "rb")) local t1 = f1:read("a") f1:close()
    local altBereite = bereite
    bereite = function() local b = assert(io_open(ZIEL, "wb")) b:write(t1) b:close() end
    local w1, _, _, _, _, _, _, p1 = lauf(d, fe)
    bereite = altBereite
    pruefe(w1.sym == nil and p2 - p1 <= 3600, string.format("12/17: %s %dx%d: paint Format 2 %d, als Format 1 %d, Mehrkosten %d (<= 3600)",
      d, fe[1], fe[2], p2, p1, p2 - p1))
  end
end

-- Test 11: Format-1-Datei mit Format-2-Feldern: Felder überlesen, keine Symbole, kein Schmuck
local w11, mw, mp = lauf("p11_format1.lua", { 800, 480 })
pruefe(w11.studioZustand == "geladen" and w11.sym == nil and #masken == 0,
  "11: p11 (Format 1): geladen, keine Symbole/kein Schmuck, Bild wie v1 (wakeup " .. mw .. ", paint " .. mp .. ")")

-- Test 15 mit Displaybreite 640: alle 48-px-Dateien abgewiesen ausser fremdkante_48 (38 × 38)
BREITE = 640
local _, _, _, z15 = lauf("p01_kaputte_png.lua", { 630, 258 })
pruefe(gleich(z15, { 0, 0, 0 }), "15: p01 bei 640 px: " .. txt(z15) .. " (erwartet 0 / 0 / 0, keine Symbole seit 0.6.0)")
BREITE = 800

-- Test 13: Modellwechsel 10 × hin und her (p12 64 px, p06 24 px): Lua-Speicher wächst nicht dauerhaft
collectgarbage("collect")
local speicher = {}
for i = 1, 10 do
  lauf(i % 2 == 1 and "p12_voll.lua" or "p06_100_symbole.lua", { 800, 480 }, 120)
  collectgarbage("collect") collectgarbage("collect")
  speicher[i] = collectgarbage("count")
end
pruefe(speicher[10] < speicher[2] + 40, string.format("13: Modellwechsel, Lua-Speicher nach 2./10. Wechsel %.0f / %.0f KB", speicher[2], speicher[10]))

-- Test 14 (zwei Widgets zeigen dasselbe Symbol): zwei Instanzen mit derselben Datei, beide laden ihre Masken
do
  bereite("p00_bild.lua")
  masken = {}
  W, H = 800, 480
  local K = assert(loadfile("kern.lua"))()
  local a, b = K.neu(), K.neu()
  K.lies(a) K.lies(b)
  local ok = true
  for _ = 1, 260 do
    T = T + 0.2
    ok = pcall(K.wecke, a) and pcall(K.wecke, b) and pcall(K.zeichne, a) and pcall(K.zeichne, b) and ok
  end
  local ga = a.sym and a.sym.zaehler() or 0
  local gb = b.sym and b.sym.zaehler() or 0
  pruefe(ok and ga == 0 and gb == 0, "14: zwei Widgets mit p00: je " .. tostring(ga) .. " / " .. tostring(gb) .. " Symbole (0 seit 0.6.0), kein Absturz")
end

-- fehlender Sensor in einem Studio-Platz zeichnet «---» (Format 1 und 2, alle Darstellungen ausser Status)
for _, fm in ipairs({ 1, 2 }) do
  for _, da in ipairs({ "zahl", "balken_w", "balken_s", "kurve", "ring" }) do
    local f = io_open(ZIEL, "w")
    f:write("return { format = " .. fm .. ", ansichten = { { breite = 800, hoehe = 480, plaetze = { { x = 10, y = 70, b = 380, h = 200, w = "
      .. esc("sensor:0B50:0") .. ", darstellung = " .. esc(da) .. " } } } } }")
    f:close()
    W, H = 800, 480
    local K = assert(loadfile("kern.lua"))()
    local w = K.neu() K.lies(w)
    for _ = 1, 200 do T = T + 0.2 K.wecke(w) end
    local texte, alt = {}, lcd.drawText
    lcd.drawText = function(_, _, t) texte[#texte + 1] = tostring(t) end
    K.zeichne(w)
    lcd.drawText = alt
    local gefunden = false
    for _, t in ipairs(texte) do if t == "---" then gefunden = true end end
    pruefe(w.studioZustand == "geladen" and gefunden, "fehlender Sensor, Format " .. fm .. ", " .. da .. ": zeigt «---»")
  end
end

-- Testdatei für den Sendertest (test/studio/format2.jet.lua): lädt ohne Fehler, Symbole da, Befehle unter der Grenze
do
  local a = io_open(quelle:gsub("src/jet$", "") .. "test/studio/format2.jet.lua", "rb")
  if a then
    local t = a:read("a") a:close()
    for _, fe in ipairs({ { 800, 480 }, { 784, 316 }, { 640, 360 } }) do   -- 640x360: umgerechnete Ansicht (0.5.0)
      local b = assert(io_open(ZIEL, "wb")) b:write(t) b:close()
      masken, zeilen = {}, {}
      W, H = fe[1], fe[2]
      local K = assert(loadfile("kern.lua"))()
      local w = K.neu() K.lies(w)
      local maxW, maxP, ok = 0, 0, true
      for _ = 1, 260 do
        T = T + 0.2
        local nw, o1 = messe(K.wecke, w)
        local np, o2 = messe(K.zeichne, w)
        ok = ok and o1 and o2
        if nw > maxW then maxW = nw end
        if np > maxP then maxP = np end
      end
      local g, fe2, v = 0, 0, 0
      if w.sym then g, fe2, v = w.sym.zaehler() end
      pruefe(ok and w.studioZustand == "geladen" and w.studioFehler == 0 and g == 0 and fe2 == 0 and v == 0 and maxW < GRENZE,
        string.format("format2.jet.lua %dx%d: geladen, %d Fehler, Symbole %d / %d / %d, wakeup %d, paint %d", fe[1], fe[2],
          w.studioFehler or -1, g, fe2, v, maxW, maxP))
    end
  else
    pruefe(false, "test/studio/format2.jet.lua fehlt")
  end
end

-- Lua-Speicher: Zuwachs durch ein geladenes Widget (mit allen Modulen) ohne / mit Studio-Datei
do
  local function zuwachs(datei)
    collectgarbage("collect") collectgarbage("collect")
    local vor = collectgarbage("count")
    local w = lauf(datei, { 800, 480 }, 200)
    collectgarbage("collect") collectgarbage("collect")
    local kb = collectgarbage("count") - vor
    w = nil
    return kb
  end
  local k0 = zuwachs(nil)
  local kf = zuwachs(quelle:gsub("src/jet$", "") .. "test/studio/format2.jet.lua")
  local k12 = zuwachs("p12_voll.lua")
  messung(string.format("Lua-Speicher je Widget (Prüfstand, nach GC): ohne Studio-Datei %.0f KB, format2.jet.lua %.0f KB, p12_voll %.0f KB",
    k0, kf, k12))
end

-- ohne Studio-Datei: nichts geladen, kein Symbol-Baustein
local w0, m0w, m0p = lauf(nil, { 800, 480 })
messung("ohne Studio-Datei 800x480: wakeup höchstens " .. m0w .. ", paint höchstens " .. m0p .. " Befehle (Grundlast)")
pruefe(w0.studioZustand == "fehlt" and w0.sym == nil, "ohne Studio-Datei: kein studio_symbole geladen")

for _, m in ipairs(messungen) do print_("MESSUNG " .. m) end
print_(string.format("MESSUNG höchstens über alle Testdateien: wakeup %d, paint %d Befehle", hoechstW, hoechstP))
os.execute("rm -rf '" .. tmp .. "'")
print_(fehler == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehler .. " Fehler"))
os.exit(fehler == 0 and 0 or 1)
