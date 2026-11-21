-- Jet: Zeichen-Baukasten im Aussehen von Heli RF und Elektro (Farben, Tachos, Kacheln, Kopfzeile, Rückfrage).
-- Zeichnet nur, rechnet nichts aus. Alle Masse gehen vom Entwurf 800 x 480 aus und werden mit L.s verkleinert.
local Z = {}
local floor, max, min = math.floor, math.max, math.min

Z.C = nil       -- Farben
local SCHRIFT   -- vorhandene Schriften mit gemessener Höhe, klein nach gross

-- Farben wie Heli RF: grün = gut, orange = Warnung, rot = Alarm, blau = Hinweis, grau = kein Wert.
local function farben()
  local R = lcd.RGB
  Z.C = {
    bg = R(8, 16, 34), kachel = R(21, 34, 62), rand = R(44, 62, 100), linie = R(36, 52, 88),
    weiss = R(255, 255, 255), titel = R(214, 222, 236), grau = R(150, 164, 190), dunkelgrau = R(75, 85, 99),
    spur = R(38, 82, 150), gelb = R(245, 197, 24), hblau = R(168, 212, 242), blau = R(64, 150, 240),
    orange = R(242, 140, 30), rot = R(239, 60, 60), gruen = R(64, 220, 110), akzent = R(190, 204, 226),
    dunkel = R(0, 0, 0), wahl = R(42, 62, 102),
  }
end

local function schriften()
  SCHRIFT = {}
  local kand = { FONT_XXS, FONT_XS, FONT_S, FONT_STD, FONT_L, FONT_XL, FONT_XXL }
  for i = 1, 7 do
    local f = kand[i]
    if f ~= nil then
      lcd.font(f)
      local _, h = lcd.getTextSize("0")
      local n = #SCHRIFT
      if n == 0 or h > SCHRIFT[n][2] then SCHRIFT[n + 1] = { f, h } end
    end
  end
end

-- Aufteilung für eine Fenstergrösse (wird im Kern je Grösse einmal gerechnet und gemerkt).
function Z.layout(W, H)
  if not Z.C then farben() end
  if not SCHRIFT then schriften() end
  -- Kompaktansicht: flaches Fenster (Ethos-Layout mit Kopf- und Fussleiste, X18RS 784 × 316 gemessen 20.11.2026)
  -- oder ein Fenster unter 400 × 250. Alles wird dann mit 0,72 der Fenstergrösse gezeichnet (wie im Konzept).
  local kompakt = H < W * 0.5 or W < 400 or H < 250
  local s = kompakt and min(W / 784, H / 316) * 0.72 or min(W / 800, H / 480)
  local klasse = W >= 700 and "L" or (W >= 560 and "M" or "S")
  local L = { W = W, H = H, s = s, klasse = klasse, klein = klasse == "S", kompakt = kompakt }
  L.tipp = 32                      -- Pixel: antippbare Flächen sind nie niedriger
  L.kh = floor((kompakt and 47 or 56) * s)   -- Kopfzeile (kompakt: schmale Leiste, 33 px bei 784 × 316)
  L.gp = max(3, floor(8 * s))      -- Abstand zwischen Kacheln
  L.y0 = L.kh + L.gp
  L.fi = {}
  return L
end

local function stufe(L, gr)
  local i = L.fi[gr]
  if i then return i end
  local ziel = gr * 1.25 * L.s + 0.5
  i = 1
  for k = 2, #SCHRIFT do
    if SCHRIFT[k][2] <= ziel then i = k end
  end
  L.fi[gr] = i
  return i
end

-- Text mit senkrechter Mitte ym. ausr: LEFT / RIGHT / CENTERED. maxB: passt der Text nicht, wird die Schrift
-- kleiner. fett: zweimal mit 1 Pixel Versatz. Rückgabe: Breite, Höhe.
function Z.text(L, x, ym, t, gr, farbe, ausr, maxB, fett)
  if t == nil then return 0, 0 end
  t = tostring(t)
  local i = stufe(L, gr)
  lcd.font(SCHRIFT[i][1])
  local b = lcd.getTextSize(t)
  if maxB then
    while b > maxB and i > 1 do
      i = i - 1
      lcd.font(SCHRIFT[i][1])
      b = lcd.getTextSize(t)
    end
  end
  lcd.color(farbe)
  local y = floor(ym - SCHRIFT[i][2] / 2)
  lcd.drawText(floor(x), y, t, ausr or LEFT)
  if fett then lcd.drawText(floor(x) + 1, y, t, ausr or LEFT) end
  return b, SCHRIFT[i][2]
end

function Z.breite(L, t, gr)
  lcd.font(SCHRIFT[stufe(L, gr)][1])
  return (lcd.getTextSize(t))
end

function Z.rechteck(x, y, b, h, farbe)
  if b < 1 or h < 1 then return end
  lcd.color(farbe)
  lcd.drawFilledRectangle(floor(x), floor(y), floor(b + 0.5), floor(h + 0.5))
end

-- Rechteck mit runden Ecken (Ethos kennt keines: zwei Rechtecke und vier Kreise).
function Z.rund(x, y, b, h, r, farbe)
  x, y, b, h, r = floor(x), floor(y), floor(b), floor(h), floor(r)
  if b < 1 or h < 1 then return end
  lcd.color(farbe)
  if r * 2 + 1 > h then r = floor((h - 1) / 2) end
  if r * 2 + 1 > b then r = floor((b - 1) / 2) end
  if r < 2 then
    lcd.drawFilledRectangle(x, y, b, h)
    return
  end
  lcd.drawFilledRectangle(x + r, y, b - 2 * r, h)
  lcd.drawFilledRectangle(x, y + r, b, h - 2 * r)
  lcd.drawFilledCircle(x + r, y + r, r)
  lcd.drawFilledCircle(x + b - r - 1, y + r, r)
  lcd.drawFilledCircle(x + r, y + h - r - 1, r)
  lcd.drawFilledCircle(x + b - r - 1, y + h - r - 1, r)
end

-- Kachel wie Heli RF; randFarbe gesetzt = dicker Rahmen (Alarm)
function Z.kachel(L, x, y, b, h, randFarbe)
  local s, C = L.s, Z.C
  local r = 6 * s
  Z.rund(x, y, b, h, r, randFarbe or C.rand)
  local d = randFarbe and max(2, floor(3 * s)) or max(1, floor(1.5 * s))
  Z.rund(x + d, y + d, b - 2 * d, h - 2 * d, r - d, C.kachel)
end

-- Kreisbogen; Winkel in Grad, 0 = oben, im Uhrzeigersinn. Geht auch über 360 hinaus.
function Z.bogen(cx, cy, r1, r2, a0, a1, farbe)
  if a1 <= a0 then return end
  lcd.color(farbe)
  cx, cy, r1, r2 = floor(cx), floor(cy), floor(r1), floor(r2)
  if a0 >= 360 then a0, a1 = a0 - 360, a1 - 360 end
  if a1 > 360 then
    lcd.drawAnnulusSector(cx, cy, r1, r2, a0, 360)
    lcd.drawAnnulusSector(cx, cy, r1, r2, 0, a1 - 360)
  else
    lcd.drawAnnulusSector(cx, cy, r1, r2, a0, a1)
  end
end

-- Zahl mit dez Stellen: deutsch mit Komma, englisch mit Punkt. nil bleibt nil.
function Z.zahl(x, dez)
  if x == nil then return nil end
  local t = string.format("%." .. (dez or 0) .. "f", x)
  if t == "-0" then t = "0" end
  if dez and dez > 0 then
    local a, b = t:match("^(-?%d+)%.(%d+)$")
    if a and not Z.punkt then t = a .. "," .. b end
  end
  return t
end

-- Sekunden als m:ss oder h:mm:ss.
function Z.zeit(sek)
  if sek == nil then return nil end
  local n = floor(sek)
  if n < 0 then n = 0 end
  if n >= 3600 then return string.format("%.0f:%02.0f:%02.0f", n // 3600, (n % 3600) // 60, n % 60) end
  return string.format("%.0f:%02.0f", n // 60, n % 60)
end

function Z.grund(L)
  lcd.color(Z.C.bg)
  lcd.drawFilledRectangle(0, 0, L.W, L.H)
end

-- Kurzer waagrechter Strich für «kein Wert». gr = Entwurfsgrösse.
function Z.strich(L, x, ym, gr, farbe, ausr)
  local b = floor(gr * 0.7 * L.s + 0.5)
  local d = max(2, floor(gr * 0.09 * L.s + 0.5))
  if ausr == CENTERED then x = x - b / 2 elseif ausr == RIGHT then x = x - b end
  Z.rechteck(x, ym - d / 2, b, d, farbe or Z.C.grau)
  return b
end

-- Text oder, wenn t nil ist, ein Strich. Jeder Messwert wird mit Z.wert gezeichnet.
function Z.wert(L, x, ym, t, gr, farbe, ausr, maxB, fett)
  if t == nil then return Z.strich(L, x, ym, gr, Z.C.grau, ausr) end
  return Z.text(L, x, ym, t, gr, farbe, ausr, maxB, fett)
end

local function stufenFarbe(st, sonst)
  if st == 2 then return Z.C.rot end
  if st == 1 then return Z.C.orange end
  return sonst
end
Z.stufenFarbe = stufenFarbe

-- Tacho-Kachel wie Heli RF: Bogen über 270°, unten 90° offen.
-- k = { titel, wert, einheit, anteil, farbe, unten, untenFarbe, st, akzent }
function Z.ring(L, x, y, b, h, k)
  local C, s = Z.C, L.s
  local alarm = k.st == 2
  Z.kachel(L, x, y, b, h, alarm and C.rot or nil)
  Z.rechteck(x + 8 * s, y, b - 16 * s, max(2, floor(2 * s)), alarm and C.rot or (k.akzent or C.akzent))
  Z.text(L, x + b / 2, y + 17 * s, k.titel, 14, alarm and C.rot or C.titel, CENTERED, b - 12 * s)
  local r = min(b * 0.42, h * 0.33)
  local cx, cy, ra, ri = x + b / 2, y + 17 * s + 14 * s + r + 4 * s, r, r - 12 * s
  Z.bogen(cx, cy, ri, ra, 225, 495, C.spur)
  if k.anteil and k.anteil > 0 then Z.bogen(cx, cy, ri, ra, 225, 225 + min(1, k.anteil) * 270, k.farbe or C.gruen) end
  local gr = (k.wert and #k.wert > 3) and 34 or 42
  local _, hw = Z.wert(L, cx, cy - 6 * s, k.wert, gr, stufenFarbe(k.st, C.weiss), CENTERED, 2 * ri - 10 * s, true)
  Z.text(L, cx, cy - 6 * s + max(hw or 0, 20 * s) / 2 + 8 * s, k.einheit, 9, C.titel, CENTERED, 2 * ri - 10 * s, true)
  if k.unten then
    Z.text(L, x + b / 2, y + h - 17 * s, k.unten, 14, k.untenFarbe or C.weiss, CENTERED, b - 12 * s, true)
  else
    Z.strich(L, x + b / 2, y + h - 17 * s, 14, C.grau, CENTERED)
  end
end

-- Kleine Kachel wie Heli RF: Titel oben links, Wert gross rechts, Zusatz klein rechts unten.
-- k = { titel, wert, zusatz, farbe, st, links (kleiner Text unten links), linksFarbe, gr (Schrift des Werts),
--       balken (Anteil 0 … 1: Balken unten), balkenFarbe }
function Z.feld(L, x, y, b, h, k)
  local C, s = Z.C, L.s
  local alarm = k.st == 2
  Z.kachel(L, x, y, b, h, alarm and C.rot or nil)
  Z.rechteck(x, y + 6 * s, max(2, floor(4 * s)), h - 12 * s, stufenFarbe(k.st, C.akzent))
  Z.text(L, x + 14 * s, y + 16 * s, k.titel, 14, alarm and C.rot or C.titel, LEFT, b - 22 * s)
  Z.wert(L, x + b - 10 * s, y + h * (k.balken and 0.42 or 0.50), k.wert, k.gr or 34, stufenFarbe(k.st, k.farbe or C.weiss), RIGHT, b - 24 * s, true)
  if k.balken then                                       -- grosses Feld: Balken über dem Zusatz
    local bh = max(6, floor(12 * s))
    local by = y + h - 34 * s - bh
    Z.rund(x + 14 * s, by, b - 28 * s, bh, 3 * s, C.spur)
    local f = max(0, min(1, k.balken))
    if f > 0 then Z.rund(x + 14 * s, by, max(2, (b - 28 * s) * f), bh, 3 * s, stufenFarbe(k.st, k.balkenFarbe or C.hblau)) end
  end
  if k.zusatz then Z.text(L, x + b - 10 * s, y + h - 15 * s, k.zusatz, 12, k.zusatzFarbe or C.titel, RIGHT, k.links and b * 0.5 or b - 24 * s) end
  if k.links then Z.text(L, x + 14 * s, y + h - 15 * s, k.links, 12, k.linksFarbe or C.gelb, LEFT, b * 0.45, true) end
end

-- Antippbare Fläche merken (beim Zeichnen); der Kern prüft damit die Berührungen.
function Z.ziel(w, id, x, y, b, h, arg)
  local n = (w.nZiele or 0) + 1
  w.nZiele = n
  local z = w.ziele[n] or {}
  z.id, z.x, z.y, z.b, z.h, z.arg = id, x, y, b, h, arg
  w.ziele[n] = z
end

-- Knopf mit Rand oder gefüllt; meldet seine Fläche als Ziel.
function Z.knopf(w, L, id, x, y, b, h, t, farbe, voll, gr, textFarbe, arg)
  local C, s = Z.C, L.s
  if voll then
    Z.rund(x, y, b, h, 6 * s, farbe)
  else
    Z.rund(x, y, b, h, 6 * s, farbe)
    local d = max(1, floor(1.5 * s))
    Z.rund(x + d, y + d, b - 2 * d, h - 2 * d, 6 * s - d, C.kachel)
  end
  Z.text(L, x + b / 2, y + h / 2, t, gr or 15, voll and C.dunkel or (textFarbe or farbe), CENTERED, b - 10 * s, true)
  if id then Z.ziel(w, id, x, y, b, h, arg) end
end

-- Pille (Schalter, Motor): gefüllt oder nur Rand
local function pille(L, x, ym, t, farbe, voll, maxB)
  local C, s = Z.C, L.s
  local ph = max(18, floor(26 * s))
  local b = Z.breite(L, t, 13) + 18 * s
  if maxB and b > maxB then return 0 end
  if voll then
    Z.rund(x - b, ym - ph / 2, b, ph, ph / 2, farbe)
  else
    Z.rund(x - b, ym - ph / 2, b, ph, ph / 2, farbe)
    Z.rund(x - b + 2, ym - ph / 2 + 2, b - 4, ph - 4, ph / 2 - 2, C.kachel)
  end
  Z.text(L, x - b / 2, ym, t, 13, voll and C.dunkel or farbe, CENTERED, b, true)
  return b
end

-- Kopfzeile wie Heli RF: Modellname, Laufzeit, Turbinen-Pille, eigene Schalter, Empfangsbalken, Senderakku.
-- Hintergrund orange bei Warnung, rot bei Alarm.
function Z.kopf(w, L)
  local C, s, W, kh = Z.C, L.s, L.W, L.kh
  local v, c, T = w.v, w.cfg, w.T
  local grund = w.stufe == 2 and C.rot or (w.stufe == 1 and C.orange or C.bg)
  Z.rechteck(0, 0, W, kh, grund)
  local a = w.akt
  local zx, x
  if L.kompakt then
    -- schmale Leiste: Modellname und Senderakku stehen in der Ethos-Kopfzeile, hier nur Flugzeit, Pillen, Empfang
    local zb = Z.breite(L, "00:00", 34) + 16 * s
    Z.text(L, 12 * s, kh / 2, Z.zeit(a and a[2] or 0), 34, C.weiss, LEFT, zb, true)
    zx = 12 * s + zb - 60 * s
    x = W - 12 * s
  else
    local name = tostring(w.modell or w.name)
    zx = W * 0.42
    Z.text(L, 12 * s, kh / 2, name, 30, C.weiss, LEFT, zx - 60 * s - 12 * s, true)
    Z.text(L, zx, kh / 2, Z.zeit(a and a[2] or 0), 34, C.weiss, CENTERED, 120 * s)
    x = W - 12 * s
  end
  if w.sAusruf and not w.sHinweis then x = x - 22 end   -- Platz für das «!» der Studio-Datei oben rechts
  if not L.kompakt then x = Z.senderakku(L, v, grund, x, kh) end
  Z.empfangUndPillen(w, L, x, kh, zx)
  Z.rechteck(0, kh, W, max(1, floor(2 * s)), C.linie)
end

function Z.senderakku(L, v, grund, x, kh)
  local C, s = Z.C, L.s
  local bb, bh = 22 * s, 32 * s
  local lo, hi = 6.4, 8.4
  if system.voltageRange then
    local okr, l, h = pcall(system.voltageRange)
    if okr and type(l) == "number" and type(h) == "number" and h > l then lo, hi = l, h end
  end
  local voll = v.sender and max(0, min(1, (v.sender - lo) / (hi - lo))) or 0
  local fa = (v.sender == nil) and C.grau or (voll > 0.25 and C.gruen or C.rot)
  if grund ~= C.bg and fa == C.rot then fa = C.weiss end
  Z.rund(x - bb, kh / 2 - bh / 2 + 3 * s, bb, bh - 3 * s, 3 * s, fa)
  Z.rund(x - bb + 2 * s, kh / 2 - bh / 2 + 5 * s, bb - 4 * s, bh - 7 * s, 2 * s, C.bg)
  Z.rechteck(x - bb / 2 - 5 * s, kh / 2 - bh / 2, 10 * s, 4 * s, fa)
  local fh = (bh - 11 * s) * voll
  if fh >= 1 then Z.rechteck(x - bb + 4 * s, kh / 2 + bh / 2 - 4 * s - fh, bb - 8 * s, fh, fa) end
  return x - bb - 12 * s
end

-- Empfangsbalken, dann von rechts nach links Motor und eigene Schalter (bis zur Grenze zx + 60 * s)
function Z.empfangUndPillen(w, L, x, kh, zx)
  local C, s, v, c, T = Z.C, L.s, w.v, w.cfg, w.T
  -- Empfangsbalken aus RSSI (0 … 100)
  local stufen = 0
  if v.rssi then
    local r = v.rssi
    stufen = (r >= 75 and 4) or (r >= 55 and 3) or (r >= 40 and 2) or (r > 0 and 1) or 0
  end
  for i = 4, 1, -1 do
    local h = (6 + 5 * i) * s
    Z.rechteck(x - 7 * s, kh / 2 + 13 * s - h, 6 * s, h, i <= stufen and C.gruen or C.linie)
    x = x - 9 * s
  end
  x = x - 8 * s
  -- Turbinen-Pille (AUS grau, START blau, LÄUFT grün, ABSCHALTUNG rot) und eigene Schalter, von rechts nach links
  local frei = x - (zx + 60 * s)
  local p = w.pille or 1
  local pt = ({ T.pAus, T.pStart, T.pLaeuft, T.pAbsch })[p]
  local pf = ({ C.grau, C.blau, C.gruen, C.rot })[p]
  local b = pille(L, x, kh / 2, pt, pf, p == 2 or p == 3, frei)
  x, frei = x - b - 6 * s, frei - b - 6 * s
  for i = 2, 1, -1 do
    if v["sw" .. i] then
      local b2 = pille(L, x, kh / 2, tostring(c["sw" .. i .. "Name"] or ""), C.gruen, true, frei)
      if b2 == 0 then break end
      x, frei = x - b2 - 6 * s, frei - b2 - 6 * s
    end
  end
end

-- Studio-Hinweis (Lua-Studio-Format v1): ein Band unten, 24 Pixel hoch, dunkel, über den Plätzen; danach «!» oben
-- rechts bis zum nächsten Modellwechsel
function Z.studioHinweis(w, L)
  if not w.sAusruf and not w.sDauer then return end
  local C, W, H = Z.C, L.W, L.H
  local t = w.sHinweis or w.sDauer       -- kurzer Hinweis, sonst die bleibende Zeile (Standard trotz Studio-Datei)
  if t then
    Z.rechteck(0, H - 24, W, 24, C.dunkel)
    Z.text(L, W / 2, H - 12, t, 14, C.orange, CENTERED, W - 8, true)
  else
    local r = 9
    local ym = max(r + 2, floor(L.kh / 2))
    lcd.color(C.orange)
    lcd.drawFilledCircle(W - r - 3, ym, r)
    Z.text(L, W - r - 3, ym, "!", 14, C.dunkel, CENTERED, nil, true)
  end
end

-- Kurzer blauer Hinweis unten über der Seite (3 s)
function Z.hinweis(w, L)
  if not w.hinweis then return end
  local C, s, W, H = Z.C, L.s, L.W, L.H
  local h = max(36 * s, 26)
  local b = min(W - 16, Z.breite(L, w.hinweis, 16) + 40 * s)
  Z.rund((W - b) / 2, H - h - 10 * s, b, h, 8 * s, C.blau)
  Z.text(L, W / 2, H - h / 2 - 10 * s, w.hinweis, 16, C.weiss, CENTERED, b - 16 * s, true)
end

-- Rückfragen: Titel, Zeile, Text Ja, Ziel Ja, Text Nein, Ziel Nein (Namen aus texte.lua)
local DIALOG = {
  loeschen = { "qLoeschen", "qLoeschenZ", "jaLoeschen", "ja_loeschen", "abbrechen", "abbrechen" },
  liste = { "qListe", "qListeZ", "jaLoeschen", "ja_liste", "abbrechen", "abbrechen" },
}

function Z.dialog(w, L)
  local d = DIALOG[w.dialog]
  if d == nil then
    w.dialog = nil
    return
  end
  local C, s, W, H, T = Z.C, L.s, L.W, L.H, w.T
  lcd.color(lcd.RGB(0, 0, 0, 0.6))
  lcd.drawFilledRectangle(0, 0, W, H)
  local b, h = min(W - 16, max(470 * s, 400)), min(H - 8, max(200 * s, 140))
  local x, y = (W - b) / 2, (H - h) / 2
  Z.rund(x, y, b, h, 12 * s, C.hblau)
  Z.rund(x + 2, y + 2, b - 4, h - 4, 11 * s, C.bg)
  local titel = T[d[1]]
  if w.dialog == "loeschen" then titel = string.format(titel, tostring(w.wahl or "")) end
  local kb, kh = (b - 66 * s) / 2, max(46 * s, L.tipp)
  local ky = y + h - kh - max(20 * s, 8)
  local yt = y + max(44 * s, 22)
  Z.text(L, W / 2, yt, titel, 26, C.weiss, CENTERED, b - 30 * s, true)
  Z.text(L, W / 2, (yt + ky) / 2 + 4 * s, T[d[2]], 15, C.titel, CENTERED, b - 30 * s)
  Z.ziel(w, "aussen", 0, 0, W, H)                 -- solange die Frage offen ist, wirkt sonst nichts
  Z.knopf(w, L, d[6], x + 22 * s, ky, kb, kh, T[d[5]], C.akzent, false, 15, C.weiss)
  Z.knopf(w, L, d[4], x + 44 * s + kb, ky, kb, kh, T[d[3]], C.gruen, true, 15, nil, w.dialog == "loeschen" and w.wahl or nil)
end

-- Fenster «Letzte Statuswechsel» (Feld STATUS antippen): Laufzeit und Text, neueste oben, Knopf SCHLIESSEN
function Z.statusListe(w, L)
  local C, s, W, H, T = Z.C, L.s, L.W, L.H, w.T
  local GF = { C.grau, C.blau, C.gruen, C.rot }
  lcd.color(lcd.RGB(0, 0, 0, 0.6))
  lcd.drawFilledRectangle(0, 0, W, H)
  local b, h = min(W - 16, max(520 * s, 400)), min(H - 8, max(330 * s, 200))
  local x, y = (W - b) / 2, (H - h) / 2
  Z.rund(x, y, b, h, 12 * s, C.hblau)
  Z.rund(x + 2, y + 2, b - 4, h - 4, 11 * s, C.bg)
  Z.text(L, x + 20 * s, y + max(26 * s, 16), T.statusListe, 18, C.gelb, LEFT, b - 40 * s, true)
  local kh = max(40 * s, L.tipp)
  local ky = y + h - kh - max(12 * s, 6)
  local y0 = y + max(50 * s, 30)
  local l = w.wechsel or {}
  local zh = (ky - y0 - 4 * s) / 5
  if #l == 0 then Z.text(L, W / 2, (y0 + ky) / 2, T.keineWechsel, 16, C.grau, CENTERED, b - 40 * s) end
  for i = #l, 1, -1 do
    local e = l[i]
    local yy = y0 + (#l - i) * zh + zh / 2
    Z.text(L, x + 20 * s, yy, Z.zeit(e[1]), 16, C.titel, LEFT, b * 0.2)
    Z.text(L, x + b * 0.26, yy, e[2], 18, GF[e[3]] or C.weiss, LEFT, b * 0.7, true)
  end
  Z.ziel(w, "aussen", 0, 0, W, H)
  local kb = min(b - 40 * s, max(220 * s, 140))
  Z.knopf(w, L, "abbrechen", (W - kb) / 2, ky, kb, kh, T.schliessen, C.akzent, false, 15, C.weiss)
end

return Z
