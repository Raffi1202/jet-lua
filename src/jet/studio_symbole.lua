-- Referenz: Symbole, fette Einheit und Schmuck (Lua-Studio-Format 2, Abschnitte 2–5 und 9). Alle Luas übernehmen das wörtlich.
-- Einbinden: local S = <diese Datei laden>()   (z. B. assert(loadfile("studio_symbole.lua"))())
-- Reine Funktionen ohne debug, alles Riskante in pcall, schreibt keine Dateien.
--
-- Aufrufe (Format 2, Abschnitt 9):
--   S.start(daten)                  nach fertiger Feldprüfung; daten = geprüfte Studio-Datei oder nil.
--                                   Gibt alte Verweise frei. Nur bei daten.format == 2 gelten symbole, symbol, symbolPx,
--                                   einheitZeigen und deko; sonst überliest die Referenz sie (Bild wie v1).
--   S.schritt()                     in jedem wakeup, bis true. Prüft in Stücken (höchstens 8 Einträge je Aufruf):
--                                   1. Liste symbole, 2. Verweise symbol der Plätze, 3. deko jeder Ansicht,
--                                   4. Kopfprüfung und Laden (höchstens 4 Dateien je Aufruf). Nie in paint aufrufen.
--   S.bildAnfang()                  am Anfang jedes paint.
--   S.platz(p, x, y, farbe)         in paint je Platz, nach dem Kästchen und vor Titel und Wert.
--                                   p     = geprüfter Platz mit symbol, symbolPx, einheitZeigen (Felder nach 3.2);
--                                   p._einheit = Einheit des Werts als Text (nach v1 §6.4 angepasst, höchstens 8 Byte).
--                                           DER AUFRUFER SETZT p._einheit; nil oder "" bei zeit = true und bei Status.
--                                   x, y  = linke obere Ecke des Platzes auf dem Bildschirm;
--                                   farbe = Farbe des Werts (lcd.RGB), Alarm/Warnung/Stufe/farbe bzw. Zustandsfarbe.
--                                   Rückgabe 1: Einrückung ab x in px; der Titel beginnt dann bei x + Rückgabe 1
--                                   (= x + rand + kante + rand). 0 = Titel an der gewohnten Stelle des Luas.
--                                   Rückgabe 2: true = Einheit wie v1 neben dem Wert zeigen, false = nicht (fett oben
--                                   oder einheitZeigen = false).
--   S.einheitFett(text, x, y, farbe, kante)
--                                   zeichnet text fett ab x; mit kante (Kantenlänge des Symbols in px) senkrecht
--                                   mittig in der Höhe kante ab y, sonst oben bei y. Gibt die Breite in px zurück.
--   S.deko(ansicht, ox, oy, standardFarbe)
--                                   in paint vor den Plätzen; ansicht = DIESELBE Tabelle aus daten.ansichten (keine Kopie),
--                                   ox/oy = Fensterlage. Schmuck erscheint erst, wenn S.schritt die Ansicht geprüft hat;
--                                   Texte werden höchstens 2 je paint zum ersten Mal gemessen (danach S.nochZuZeichnen).
--                                   standardFarbe (optional) = Farbe des Luas für Elemente ohne gültige farbe, sonst weiss.
--   S.freigeben()                   Modellwechsel und close: alle Verweise weg, collectgarbage("collect").
--   S.zaehler()                     gibt geladen, fehlend, verworfen zurück (Hinweis «Studio: n Symbole fehlen»).
--   S.nochZuZeichnen()              nach paint: true = Masken warten auf ihr erstes Zeichnen, dann lcd.invalidate().
--   S.B                             Displaybreite; nil = system.getVersion().lcdWidth. Nur zum Testen ausserhalb von
--                                   Ethos von aussen setzen (vor S.start).
-- Jede verworfene oder fehlende Angabe gibt eine Zeile print("Studio-Symbol: …").

local S = {}

local JE_AUFRUF = 8          -- Einträge je Prüf-Aufruf (Format 2, Regel 7.1)
local JE_LADEN = 4           -- Dateien je Lade-Aufruf (Abschnitt 4.4)
local JE_BILD = 4            -- Masken zum ersten Mal je paint (Abschnitt 4.7)
local MAX_SYMBOLE = 20
local MAX_DEKO = 24
local MAX_ANSICHTEN = 2
local MAX_PLAETZE = 16
local MAX_DATEI = 4096       -- Byte je Symboldatei (Abschnitt 4)
local ORDNER = "SCRIPTS:/studio/symbole/"
local PX = { [24] = true, [32] = true, [48] = true, [64] = true }
local KENNUNG = "\137PNG\r\n\26\n\0\0\0\13IHDR"         -- Byte 1–16: PNG-Kennung, Länge 13, IHDR
local ENDE = "\0\0\0\0IEND\174\66\96\130"                -- letzte 12 Byte jeder vollständigen PNG
local ARTEN = { symbol = true, text = true, linie = true, rahmen = true }

local B, rand = 800, 4
local masken = {}            -- [name .. "_" .. px] = { k = Kante, p = Pfad, m = Maske oder nil, z = schon gezeichnet }
local laden = {}             -- Schlüssel in der Reihenfolge der Liste, zum Laden
local dekoListen = setmetatable({}, { __mode = "k" })   -- [ansicht] = geprüfte Schmuck-Liste
local plaetze = setmetatable({}, { __mode = "k" })      -- [platz] = { e = Maske oder false, z = einheitZeigen }
-- Fette Schriften: Ethos 26.2 kennt FONT_STD_BOLD, aber kein FONT_S_BOLD; fett = Schrift + FONT_BOLD (im Simulator 26.2.0 geprüft)
local fettKlein = FONT_S_BOLD or (FONT_S and FONT_BOLD and FONT_S + FONT_BOLD) or FONT_S
local fettGross = FONT_STD_BOLD or (FONT_STD and FONT_BOLD and FONT_STD + FONT_BOLD) or FONT_STD
local daten, phase, pos, ansichtNr, platzNr = nil, 0, 1, 1, 1
local anzahl, geladen, fehlend, verworfen = 0, 0, 0, 0
local ersteImBild, wartet = 0, false
local weiss = nil

local function meldung(t) print("Studio-Symbol: " .. t) end
local function ganz(v) return math.type(v) == "integer" end
local function kanteVon(px) return math.floor(px * B / 800 + 0.5) end

-- Name nach 3.1: ^[a-z][a-z0-9_]*$, höchstens 24 Zeichen; px nur 24, 32, 48, 64
local function nameGut(n) return type(n) == "string" and #n <= 24 and n:find("^[a-z][a-z0-9_]*$") ~= nil end
local function schluessel(name, px)
  if not nameGut(name) or not ganz(px) or not PX[px] then return nil end
  return name .. "_" .. px
end

-- Text auf höchstens n Byte kürzen, nur vor einem Byte, das ein Zeichen beginnt (wie titel, v1 §6.3).
-- Höchstens 3 Byte zurück (ein UTF-8-Zeichen hat höchstens 4 Byte); bei ungültigem UTF-8 danach hart abschneiden.
local function kuerze(t, n)
  if #t <= n then return t end
  local m = n
  while m > 0 and m > n - 3 do
    local b = t:byte(m + 1)
    if b < 0x80 or b > 0xBF then return t:sub(1, m) end
    m = m - 1
  end
  local b = t:byte(m + 1)
  if m > 0 and (b < 0x80 or b > 0xBF) then return t:sub(1, m) end
  return t:sub(1, n)
end

-- Farbe {r,g,b} mit ganzen Zahlen 0 … 255 nach lcd-Farbe, sonst nil
local function farbeVon(f)
  if type(f) ~= "table" then return nil end
  local r, g, b = f[1], f[2], f[3]
  if not (ganz(r) and ganz(g) and ganz(b)) or r < 0 or r > 255 or g < 0 or g > 255 or b < 0 or b > 255 then return nil end
  local ok, c = pcall(lcd.RGB, r, g, b)
  return ok and c or nil
end

function S.freigeben()
  masken, laden = {}, {}
  dekoListen = setmetatable({}, { __mode = "k" })
  plaetze = setmetatable({}, { __mode = "k" })
  daten, phase, pos, ansichtNr, platzNr = nil, 0, 1, 1, 1
  anzahl, geladen, fehlend, verworfen = 0, 0, 0, 0
  ersteImBild, wartet = 0, false
  collectgarbage("collect")
end

function S.start(d)
  S.freigeben()
  B = 800
  if type(S.B) == "number" then B = S.B
  else
    local ok, v = pcall(system.getVersion)
    if ok and type(v) == "table" and ganz(v.lcdWidth) and v.lcdWidth > 0 then B = v.lcdWidth end
  end
  rand = math.floor(4 * B / 800 + 0.5)
  if type(d) == "table" and d.format == 2 then daten, phase = d, 1 end
end

-- Phase 1: Liste symbole prüfen (Einträge pos … pos+7)
local function pruefeListe()
  local liste = daten.symbole
  if liste == nil then return true end
  if type(liste) ~= "table" then verworfen = verworfen + 1 meldung("symbole ist keine Liste") return true end
  local bis = math.min(#liste, pos + JE_AUFRUF - 1)
  for i = pos, bis do
    local e = liste[i]
    local k = type(e) == "table" and schluessel(e.name, e.px) or nil
    if not k then
      verworfen = verworfen + 1
      meldung("symbole[" .. i .. "] verworfen: Name oder px ungültig")
    elseif not masken[k] then
      if anzahl >= MAX_SYMBOLE then
        verworfen = verworfen + 1
        meldung("symbole[" .. i .. "] verworfen: mehr als " .. MAX_SYMBOLE .. " Symbole")
      else
        anzahl = anzahl + 1
        masken[k] = { k = kanteVon(e.px), p = ORDNER .. k .. ".png" }
        laden[#laden + 1] = k
      end
    end
  end
  pos = bis + 1
  return pos > #liste
end

-- Ansichten aus daten (höchstens 2), sonst nil
local function ansicht(n)
  local a = type(daten.ansichten) == "table" and daten.ansichten[n] or nil
  if n > MAX_ANSICHTEN or type(a) ~= "table" then return nil end
  return a
end

-- Phase 2: Verweise symbol der Plätze prüfen (fehlt der Eintrag in symbole: kein Symbol plus Hinweis)
local function pruefePlaetze()
  local n = 0
  while n < JE_AUFRUF do
    local a = ansicht(ansichtNr)
    if not a then return true end
    local pl = type(a.plaetze) == "table" and a.plaetze or {}
    local p = platzNr <= MAX_PLAETZE and pl[platzNr] or nil
    if not p then ansichtNr, platzNr = ansichtNr + 1, 1
    else
      if type(p) == "table" and p.symbol ~= nil then
        local px = (ganz(p.symbolPx) and PX[p.symbolPx]) and p.symbolPx or 24
        local k = schluessel(p.symbol, px)
        if not k or not masken[k] then
          verworfen = verworfen + 1
          meldung("Ansicht " .. ansichtNr .. " Platz " .. platzNr .. ": symbol nicht in symbole, kein Symbol")
        end
      end
      platzNr, n = platzNr + 1, n + 1
    end
  end
  return false
end

-- Ein Schmuck-Element nach 3.4 prüfen; gibt das geprüfte Element oder nil, Grund zurück
local function pruefeElement(e, br, ho)
  if type(e) ~= "table" or not ARTEN[e.art] then return nil, "art unbekannt" end
  local x, y = e.x, e.y
  if not ganz(x) or not ganz(y) or x < 0 or y < 0 or x >= br or y >= ho then return nil, "x/y ausserhalb" end
  local g = { a = e.art, x = x, y = y, f = farbeVon(e.farbe) }
  if e.art == "symbol" then
    local k = schluessel(e.name, e.px)
    if not k then return nil, "name/px ungültig" end
    if not masken[k] then return nil, "symbol nicht in symbole" end
    local kt = masken[k].k
    if kt > br - x or kt > ho - y then return nil, "Symbol passt nicht in die Ansicht" end
    g.k = k
    return g
  end
  local b, h = e.b, e.h
  if not ganz(b) or not ganz(h) then return nil, "b/h fehlt" end
  if e.art == "linie" then
    if b == 0 and h == 0 then return nil, "Linie ohne Länge" end
    -- Vergleiche ohne x + b (kein Ganzzahl-Überlauf bei riesigen Werten)
    if b < -x or b >= br - x or h < -y or h >= ho - y then return nil, "Endpunkt ausserhalb" end
  else
    if b < 1 or h < 1 or b > br - x or h > ho - y then return nil, "b/h ausserhalb" end
  end
  g.b, g.h = b, h
  if e.art == "text" then
    if type(e.text) ~= "string" then return nil, "text fehlt" end
    g.t = kuerze(e.text, 24)
  end
  return g
end

-- Phase 3: deko einer Ansicht prüfen, höchstens 8 Elemente je Aufruf; Ergebnis in dekoListen[ansicht]
local function pruefeDeko(a, bis)
  local liste = dekoListen[a]
  if liste and not liste.n then return true end
  if not liste then
    liste = { n = 1 }
    dekoListen[a] = liste
  end
  local deko, br, ho = a.deko, a.breite, a.hoehe
  if type(deko) ~= "table" or not ganz(br) or not ganz(ho) then
    if deko ~= nil then verworfen = verworfen + 1 meldung("deko ungültig") end
    liste.n = nil
    return true
  end
  local ende = math.min(#deko, MAX_DEKO)
  local letzt = math.min(ende, liste.n + bis - 1)
  for i = liste.n, letzt do
    local g, grund = pruefeElement(deko[i], br, ho)
    if g then liste[#liste + 1] = g
    else verworfen = verworfen + 1 meldung("deko[" .. i .. "] verworfen: " .. grund) end
  end
  liste.n = letzt + 1
  if liste.n > ende then
    if #deko > MAX_DEKO then
      verworfen = verworfen + #deko - MAX_DEKO
      meldung((#deko - MAX_DEKO) .. " deko-Elemente über " .. MAX_DEKO .. " verworfen")
    end
    liste.n = nil
    return true
  end
  return false
end

-- Phase 4: Kopfprüfung (erste 24 Byte), Rest bis 4 KB mit IEND am Ende, dann pcall(lcd.loadMask)
local function pruefeDatei(e)
  local ok, f = pcall(io.open, e.p, "rb")
  if not ok or not f then return "fehlt" end
  local ok1, kopf = pcall(f.read, f, 24)
  local ok2, rest = pcall(f.read, f, MAX_DATEI - 23)
  pcall(f.close, f)
  if not ok1 or type(kopf) ~= "string" or #kopf < 24 or kopf:sub(1, 16) ~= KENNUNG then return "keine PNG" end
  local b1, b2, b3, b4, h1, h2, h3, h4 = kopf:byte(17, 24)
  local breite = ((b1 * 256 + b2) * 256 + b3) * 256 + b4
  local hoehe = ((h1 * 256 + h2) * 256 + h3) * 256 + h4
  if breite ~= e.k or hoehe ~= e.k then return "Kante " .. breite .. "x" .. hoehe .. " statt " .. e.k end
  if not ok2 or type(rest) ~= "string" then return "abgeschnitten" end
  if 24 + #rest > MAX_DATEI then return "grösser als 4 KB" end
  if rest:byte(1) ~= 8 or rest:byte(2) ~= 0 then return "nicht Graustufen 8 Bit" end
  if #rest < 12 or rest:sub(-12) ~= ENDE then return "abgeschnitten" end
  return nil
end

local function ladeDateien()
  local n = 0
  while n < JE_LADEN and pos <= #laden do
    local e = masken[laden[pos]]
    local grund = pruefeDatei(e)
    if not grund then
      local ok, m = pcall(lcd.loadMask, e.p)
      if ok and m ~= nil then e.m = m geladen = geladen + 1 else grund = "loadMask fehlgeschlagen" end
    end
    if grund then fehlend = fehlend + 1 meldung(e.p .. ": " .. grund .. ", kein Symbol") end
    pos, n = pos + 1, n + 1
  end
  return pos > #laden
end

function S.schritt()
  if phase == 0 then return true end
  local ok, fertig = pcall(function()
    if phase == 1 then
      if pruefeListe() then phase, ansichtNr, platzNr = 2, 1, 1 end
    elseif phase == 2 then
      if pruefePlaetze() then phase, ansichtNr = 3, 1 end
    elseif phase == 3 then
      local a = ansicht(ansichtNr)
      if not a then phase, pos = 4, 1
      elseif pruefeDeko(a, JE_AUFRUF) then ansichtNr = ansichtNr + 1 end
    elseif phase == 4 then
      if ladeDateien() then phase = 0 laden = {} end
    end
    return phase == 0
  end)
  if not ok then
    meldung("Fehler beim Prüfen: " .. tostring(fertig))
    phase, laden = 0, {}
    return true
  end
  return fertig
end

function S.bildAnfang()
  ersteImBild, wartet = 0, false
end

-- Maske zeichnen (ohne pcall, der Aufrufer schützt), höchstens JE_BILD zum ersten Mal je paint; true = gezeichnet
local function zeichne(e, x, y)
  if not e.z then
    if ersteImBild >= JE_BILD then wartet = true return false end
    ersteImBild = ersteImBild + 1
    e.z = true
  end
  lcd.drawMask(x, y, e.m)
  return true
end

local function fettRoh(text, x, y, farbe, kante)
  lcd.font((kante and kante >= 32) and fettGross or fettKlein)
  lcd.color(farbe)
  local w, h = lcd.getTextSize(text)
  lcd.drawText(x, kante and (y + (kante - h) // 2) or y, text)
  return w
end

function S.einheitFett(text, x, y, farbe, kante)
  if type(text) ~= "string" or text == "" then return 0 end
  local ok, w = pcall(fettRoh, text, x, y, farbe, kante)
  return ok and w or 0
end

-- Platz einmal auswerten und merken: [p] = { e = Maske oder false, z = einheitZeigen }
local function platzInfo(p)
  local zeigen = p.einheitZeigen
  if zeigen ~= false and zeigen ~= "fett" then zeigen = true end
  local px = (ganz(p.symbolPx) and PX[p.symbolPx]) and p.symbolPx or 24
  local k = p.symbol ~= nil and schluessel(p.symbol, px) or nil
  local info = { e = k and masken[k] or false, z = zeigen }
  if phase ~= 1 then plaetze[p] = info end   -- erst merken, wenn die Liste symbole geprüft ist
  return info
end

local function platzRoh(p, x, y, farbe)
  local info = plaetze[p] or platzInfo(p)
  local e, ein, kante = info.e, 0, nil
  if e and e.m then
    lcd.color(farbe)
    if zeichne(e, x + rand, y + rand) then kante = e.k ein = rand + kante + rand end
  end
  if info.z == "fett" then
    local t = p._einheit
    if type(t) == "string" and t ~= "" then
      if ein == 0 then ein = rand end
      ein = ein + fettRoh(t, x + ein, y + rand, farbe, kante) + rand
    end
  end
  return ein, info.z == true
end

function S.platz(p, x, y, farbe)
  if not daten or type(p) ~= "table" then return 0, true end
  local ok, ein, amWert = pcall(platzRoh, p, x, y, farbe)
  -- Fehler: Einheit nur dann neben den Wert, wenn der Platz das so will (direkt aus p, unabhängig von der Prüfphase)
  if not ok then return 0, p.einheitZeigen ~= false and p.einheitZeigen ~= "fett" end
  return ein, amWert
end

-- Text eines Schmuck-Elements einmal auf die Breite b kürzen (Halbierung, höchstens 5 Messungen) und die Schrift aus h wählen
local JE_BILD_TEXT = 2       -- Texte je paint, die zum ersten Mal gemessen werden (Befehlsgrenze)
local function textVorbereiten(g)
  g.s = g.h >= 40 and FONT_XL or g.h >= 30 and FONT_L or g.h >= 22 and FONT_STD or g.h >= 16 and FONT_S or FONT_XS
  lcd.font(g.s)
  local t = g.t
  if lcd.getTextSize(t) > g.b then
    local lo, hi = 0, #t - 1     -- längste passende Länge in [lo, hi]
    while lo < hi do
      local mitte = (lo + hi + 1) // 2
      if lcd.getTextSize(kuerze(t, mitte)) <= g.b then lo = mitte else hi = mitte - 1 end
    end
    t = kuerze(t, lo)
  end
  g.t = t
end

local function dekoRoh(liste, ox, oy, std)
  local neueTexte = 0
  for i = 1, #liste do
    local g = liste[i]
    local x, y, art = ox + g.x, oy + g.y, g.a
    lcd.color(g.f or std)
    if art == "symbol" then
      local e = masken[g.k]
      if e and e.m then zeichne(e, x, y) end     -- nicht geladen: nichts zeichnen, zählt nicht als erstes Zeichnen
    elseif art == "linie" then lcd.drawLine(x, y, x + g.b, y + g.h)
    elseif art == "rahmen" then lcd.drawRectangle(x, y, g.b, g.h)
    else
      if not g.s then
        if neueTexte < JE_BILD_TEXT then neueTexte = neueTexte + 1 textVorbereiten(g) else wartet = true end
      end
      if g.s then
        lcd.font(g.s)
        lcd.drawText(x, y, g.t)
      end
    end
  end
end

function S.deko(a, ox, oy, standardFarbe)
  if not daten or phase == 1 or type(a) ~= "table" then return end
  local liste = dekoListen[a]
  -- Ansicht noch nicht fertig geprüft (S.schritt läuft noch) oder fremde Tabelle: noch keinen Schmuck zeichnen.
  -- Nie in paint prüfen (Befehlsgrenze).
  if not liste or liste.n then return end
  if not weiss then weiss = lcd.RGB(255, 255, 255) end
  pcall(dekoRoh, liste, ox, oy, standardFarbe or weiss)
end

function S.zaehler() return geladen, fehlend, verworfen end

function S.nochZuZeichnen() return wartet end

return S
