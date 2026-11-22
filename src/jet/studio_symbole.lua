-- Referenz: Schmuck (Lua-Studio-Format 2, Abschnitte 3.4 und 9). Alle Luas übernehmen das wörtlich.
-- 0.8.0 (Entscheid User 22.11.2026): Symbole ganz entfernt. symbole, symbol, symbolPx und Schmuck-Elemente der Art
-- «symbol» werden still überlesen (kein Zähler, keine Meldung); einheitZeigen = "fett" gilt wie true (Einheit am Wert).
-- Die Beschreibung unten gilt für deko, S.platz und S.zaehler (geladen und fehlend bleiben 0).
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
local MAX_DEKO = 24
local MAX_ANSICHTEN = 2
local MAX_PLAETZE = 16
local ARTEN = { symbol = true, text = true, linie = true, rahmen = true }

local B, rand = 800, 4
local dekoListen = setmetatable({}, { __mode = "k" })   -- [ansicht] = geprüfte Schmuck-Liste
-- Fette Schriften: Ethos 26.2 kennt FONT_STD_BOLD, aber kein FONT_S_BOLD; fett = Schrift + FONT_BOLD (im Simulator 26.2.0 geprüft)
local daten, phase, pos, ansichtNr, platzNr = nil, 0, 1, 1, 1
local anzahl, geladen, fehlend, verworfen = 0, 0, 0, 0
local wartet = false
local weiss = nil

local function meldung(t) print("Studio-Symbol: " .. t) end
local function ganz(v) return math.type(v) == "integer" end

-- Name nach 3.1: ^[a-z][a-z0-9_]*$, höchstens 24 Zeichen; px nur 24, 32, 48, 64

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
  dekoListen = setmetatable({}, { __mode = "k" })
  daten, phase, pos, ansichtNr, platzNr = nil, 0, 1, 1, 1
  anzahl, geladen, fehlend, verworfen = 0, 0, 0, 0
  wartet = false
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
  if type(d) == "table" and d.format == 2 then daten, phase, ansichtNr = d, 3, 1 end
end

local function ansicht(n)
  local a = type(daten.ansichten) == "table" and daten.ansichten[n] or nil
  if n > MAX_ANSICHTEN or type(a) ~= "table" then return nil end
  return a
end

local function pruefeElement(e, br, ho)
  if type(e) ~= "table" or not ARTEN[e.art] then return nil, "art unbekannt" end
  local x, y = e.x, e.y
  if not ganz(x) or not ganz(y) or x < 0 or y < 0 or x >= br or y >= ho then return nil, "x/y ausserhalb" end
  local g = { a = e.art, x = x, y = y, f = farbeVon(e.farbe) }
  if e.art == "symbol" then return nil end        -- 0.8.0: Symbole still überlesen (kein Zähler, keine Meldung)
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
    elseif grund then verworfen = verworfen + 1 meldung("deko[" .. i .. "] verworfen: " .. grund) end
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

function S.schritt()
  if phase == 0 then return true end
  local ok, fertig = pcall(function()
    if phase == 3 then                              -- 0.8.0: nur noch Schmuck prüfen (Linien, Rahmen, Texte)
      local a = ansicht(ansichtNr)
      if not a then phase = 0
      elseif pruefeDeko(a, JE_AUFRUF) then ansichtNr = ansichtNr + 1 end
    end
    return phase == 0
  end)
  if not ok then
    meldung("Fehler beim Prüfen: " .. tostring(fertig))
    phase = 0
    return true
  end
  return fertig
end

-- 0.8.0 (Entscheid User 22.11.2026: Symbole ganz entfernt): kein Symbol und keine fette Einheit im Platzkopf.
-- Rückgabe wie bisher: Einrückung 0, true = Einheit neben dem Wert (ausser einheitZeigen = false).
function S.platz(p)
  if type(p) ~= "table" then return 0, true end
  return 0, p.einheitZeigen ~= false
end

function S.bildAnfang() wartet = false end

-- Text eines Schmuck-Elements einmal auf die Breite b kürzen (Halbierung, höchstens 5 Messungen) und die Schrift aus h wählen
local JE_BILD_TEXT = 2       -- Texte je paint, die zum ersten Mal gemessen werden (Befehlsgrenze)
local function textVorbereiten(g)
  g.s = g.h >= 40 and FONT_XL or g.h >= 30 and FONT_L or g.h >= 22 and FONT_STD or g.h >= 16 and FONT_S or FONT_XS
  lcd.font(g.s)
  g.t0 = g.t0 or g.t
  local t = g.t0
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
    if art == "linie" then lcd.drawLine(x, y, x + g.b, y + g.h)
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

-- Umgerechnete Ansicht (andere Fenstergrösse): Lage und Grösse einmal umrechnen, 
-- Elemente in der Kopfzeile der Quelle oder ausserhalb der Fläche fallen weg.
local skaliert = setmetatable({}, { __mode = "k" })
local function skaliere(liste, sk)
  local r = {}
  for i = 1, #liste do
    local g = liste[i]
    if g.y >= sk.kq then
      local n = {}
      for k, v in pairs(g) do n[k] = v end
      n.x, n.y = math.floor(g.x * sk.fx + 0.5), math.floor(sk.kz + (g.y - sk.kq) * sk.fy + 0.5)
      if g.a ~= "symbol" and g.b then n.b = math.floor(g.b * sk.fx + 0.5) end
      if (g.a == "linie" or g.a == "rahmen") and g.h then n.h = math.floor(g.h * sk.fy + 0.5) end
      if g.a == "text" then n.s, n.t = nil, g.t0 or g.t end
      r[#r + 1] = n
    end
  end
  return r
end

function S.deko(a, ox, oy, standardFarbe, sk)
  if not daten or phase == 1 or type(a) ~= "table" then return end
  local liste = dekoListen[a]
  if liste and not liste.n and sk then
    local l2 = skaliert[liste]
    if l2 == nil then l2 = skaliere(liste, sk) skaliert[liste] = l2 end
    liste = l2
  end
  -- Ansicht noch nicht fertig geprüft (S.schritt läuft noch) oder fremde Tabelle: noch keinen Schmuck zeichnen.
  -- Nie in paint prüfen (Befehlsgrenze).
  if not liste or liste.n then return end
  if not weiss then weiss = lcd.RGB(255, 255, 255) end
  pcall(dekoRoh, liste, ox, oy, standardFarbe or weiss)
end

function S.zaehler() return geladen, fehlend, verworfen end

function S.nochZuZeichnen() return wartet end

return S
