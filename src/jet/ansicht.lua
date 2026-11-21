-- Jet: zeichnet die Plätze einer Ansicht aus der Studio-Datei (Lua-Studio-Format v1, Abschnitte 6.3 und 7; Format 2:
-- Symbole, fette Einheit und Schmuck über die Referenz studio_symbole.lua in w.sym).
-- Wird nur geladen, wenn zur Fenstergrösse eine Studio-Ansicht passt. Rechnet nichts aus: Werte kommen aus
-- studio.lua (M.wert), Zustände aus den Grenzen (kern.lua bzw. studio.lua), Min/Max/Mittel und Kurven aus M.wecke.
-- Ersetzt im Vollbild nur Seite 1; Seiten 2 (Turbinen) und 3 (Flugliste) bleiben wie ohne Studio-Datei.
local A = {}
local floor, max, min = math.floor, math.max, math.min

local function rgb(t, sonst)
  if t then return lcd.RGB(t[1], t[2], t[3]) end
  return sonst
end

-- Entwurfsgrösse für Z.text aus einer gewünschten Pixelhöhe (Z.text rechnet gr × 1,25 × L.s)
local function gr(L, px) return max(6, px / (1.25 * L.s)) end

local function zahlText(Z, x, dez, eh, s)
  if x == nil then return nil end
  if s == "laufzeit" then return Z.zeit(x) end
  local t = Z.zahl(x, dez)
  if eh and eh ~= "" then t = t .. " " .. eh end
  return t
end

-- Farbe des Werts: Alarm/Warnung (Grenze des Werts) vor Farbstufen vor Grundfarbe
local function farbeVon(q, st, x, C)
  if st == 2 then return rgb(q.farbeAlarm, C.rot) end
  if st == 1 then return rgb(q.farbeWarn, C.orange) end
  if q.stufen and x then
    local f = nil
    for _, s in ipairs(q.stufen) do if x >= s.ab then f = s.farbe end end
    if f then return rgb(f) end
  end
  return rgb(q.farbe, C.hblau)
end

local function kachel(Z, L, q, st)
  local C, s = Z.C, L.s
  local rand = st == 2 and rgb(q.farbeAlarm, C.rot) or C.rand
  local r = floor(6 * s)
  Z.rund(q.x, q.y, q.b, q.h, r, rand)
  local d = st == 2 and max(2, floor(3 * s)) or max(1, floor(1.5 * s))
  Z.rund(q.x + d, q.y + d, q.b - 2 * d, q.h - 2 * d, r - d, rgb(q.hintergrund, C.kachel))
end

local function zusatzText(w, q, Z, dez, eh)
  if q.zusatz == "keine" then return nil end
  local z = w.studio.zx[q.w]
  if z == nil then return nil end
  local x, vor = z[2], "MAX "
  if q.zusatz == "min" then x, vor = z[1], "MIN " elseif q.zusatz == "mittel" then x, vor = (z[4] > 0 and z[3] / z[4] or nil), "Ø " end
  if x == nil then return nil end
  return vor .. zahlText(Z, x, dez, eh, q.s)
end

-- Statustext und Farbe der ECU (aus grau, Start blau, läuft grün, Fehler rot); Abschaltung: rot mit Grund
local function statusTF(w, C)
  local tb = w.tb[1]
  local t = tb.text or (tb.code ~= nil and string.format(w.T.code, tostring(tb.code))) or nil
  local f = ({ C.grau, C.blau, C.gruen, C.rot })[tb.gruppe or 0] or C.weiss
  if w.absch then
    f = C.rot
    if w.absch[2] then t = w.absch[2] elseif w.absch[3] then t = w.T.pAbsch end
    if w.absch[1] > 1 then t = "T" .. w.absch[1] .. " " .. tostring(t) end
  end
  return t, f
end

local function zeichnePlatz(w, L, Z, q, ST, i)
  local C = Z.C
  local x0, y0, b, h = q.x, q.y, q.b, q.h
  if q.art == "leer" then kachel(Z, L, q, nil) return end
  local x, eh, dez, name = ST.wert(w, q.w, q.art, q.s, w.sp)
  local u = q.art == "lua" and ST.WERTE[q.s].u
  local st = u and w.st[u] or w.studio.st[q.w]
  if q.s == "status" and w.absch then st = 2 end         -- Abschaltung: rot bis die Turbine wieder läuft
  local xa = x                                          -- angezeigte Zahl; Empfang am dBm-Empfänger wie Seite 1
  if q.s == "empfang" and w.v.dbm and x then xa, eh = x - 120, "dBm" end
  local fg = farbeVon(q, st, x, C)
  kachel(Z, L, q, st)
  local titel = q.titel or name
  local th = min(18, max(9, h * 0.2))                   -- Titelhöhe in Pixeln
  local pad = max(4, floor(6 * L.s))
  local d = q.darst
  -- Format 2 (studio_symbole.lua): Symbol und fette Einheit oben links, Titel rückt ein; Einheit am Wert nur, wenn
  -- die Referenz es so sagt. Bei Laufzeit (Zeit) und Status gibt es keine Einheit.
  local ein, amWert = 0, true
  local SY = w.sym
  if SY and q.roh then
    local zeitOderStatus = q.s == "laufzeit" or d == "status"
    q.roh._einheit = (not zeitOderStatus and eh ~= "") and eh or nil
    local sf = fg
    if d == "status" then
      if q.s == "status" then local _, f = statusTF(w, C) sf = f else sf = C.grau end
    end
    ein, amWert = SY.platz(q.roh, x0, y0, sf)
    if not amWert then eh = "" end
  end
  local tx = max(pad, ein)                              -- Titel links: Abstand vom Rand des Platzes
  local tb = max(8, b - tx - pad)                       -- Titel links: verfügbare Breite (nie negativ)
  local tcx = x0 + (tx + b - pad) / 2                   -- Titel mittig: Mitte der freien Breite
  local fehlt = (q.art == "sensor" or q.art == "kanal") and w.studio.quellen[q.w] == false
  local wert = fehlt and "---" or zahlText(Z, xa, dez, eh, q.s)
  local zt = zusatzText(w, q, Z, dez, eh)
  local lo = q.min or (q.art == "lua" and ST.WERTE[q.s][4]) or 0
  local hi = q.max or (q.art == "lua" and ST.WERTE[q.s][5]) or 100
  if hi <= lo then hi = lo + 1 end
  local anteil = x and max(0, min(1, (x - lo) / (hi - lo))) or nil

  if d == "status" then
    Z.text(L, x0 + tx, y0 + pad + th / 2, titel, gr(L, th), C.titel, LEFT, tb)
    -- Statustext der ECU in der Farbe seiner Gruppe (aus grau, Start blau, läuft grün, Fehler rot), wie Seite 1
    local t, f = nil, C.grau
    if q.s == "status" then t, f = statusTF(w, C) end
    Z.wert(L, x0 + b / 2, y0 + (h + th) / 2 + pad / 2, t, gr(L, min(h * 0.4, 34)), f, CENTERED, b - 2 * pad, true)

  elseif d == "ring" then
    Z.text(L, tcx, y0 + pad + th / 2, titel, gr(L, th), st == 2 and fg or C.titel, CENTERED, tb)
    local zh = zt and th or 0
    local r = min(b * 0.42, (h - th - zh - 3 * pad) * 0.5)
    local cx, cy = x0 + b / 2, y0 + pad + th + pad + r
    local ri = max(2, r - max(4, r * 0.22))
    Z.bogen(cx, cy, ri, r, 225, 495, C.spur)
    if anteil and anteil > 0 then Z.bogen(cx, cy, ri, r, 225, 225 + anteil * 270, fg) end
    local zahl = fehlt and "---" or (x ~= nil and (q.s == "laufzeit" and Z.zeit(x) or Z.zahl(xa, dez)) or nil)
    Z.wert(L, cx, cy - r * 0.08, zahl, gr(L, r * 0.62), st and st > 0 and fg or C.weiss, CENTERED, 2 * ri - 4, true)
    if eh ~= "" and q.s ~= "laufzeit" then Z.text(L, cx, cy + r * 0.38, eh, gr(L, max(8, r * 0.2)), C.titel, CENTERED, 2 * ri - 4, true) end
    if zt then Z.text(L, cx, y0 + h - pad - th / 2, zt, gr(L, th), C.gelb, CENTERED, b - 2 * pad, true) end

  elseif d == "balken_w" then
    Z.text(L, x0 + tx, y0 + pad + th / 2, titel, gr(L, th), C.titel, LEFT, max(8, b * 0.5 - (tx - pad)))
    local bh = max(6, floor(h * 0.22))
    local by = y0 + h - pad - bh - (zt and th or 0)
    local vh = by - (y0 + pad + th) - pad
    Z.wert(L, x0 + b - pad, y0 + pad + th / 2 + max(0, vh - th) / 2, wert, gr(L, max(th, min(vh + th, 44))), fg, RIGHT, b * 0.55, true)
    Z.rund(x0 + pad, by, b - 2 * pad, bh, 3, C.spur)
    if anteil and anteil > 0 then Z.rund(x0 + pad, by, max(2, (b - 2 * pad) * anteil), bh, 3, fg) end
    if zt then Z.text(L, x0 + b - pad, y0 + h - pad - th / 2, zt, gr(L, th), C.gelb, RIGHT, b - 2 * pad) end

  elseif d == "balken_s" then
    Z.text(L, tcx, y0 + pad + th / 2, titel, gr(L, th), C.titel, CENTERED, tb)
    local vh = min(30, max(12, h * 0.16))
    local zh = zt and th or 0
    local bt = y0 + 2 * pad + th
    local bhoch = y0 + h - pad - vh - zh - pad - bt
    local bb = min(b * 0.4, 40)
    local bx = x0 + (b - bb) / 2
    if bhoch > 4 then
      Z.rund(bx, bt, bb, bhoch, 3, C.spur)
      if anteil and anteil > 0 then local f = max(2, bhoch * anteil) Z.rund(bx, bt + bhoch - f, bb, f, 3, fg) end
    end
    Z.wert(L, x0 + b / 2, y0 + h - pad - zh - vh / 2, wert, gr(L, vh), fg, CENTERED, b - 2 * pad, true)
    if zt then Z.text(L, x0 + b / 2, y0 + h - pad - th / 2, zt, gr(L, th), C.gelb, CENTERED, b - 2 * pad) end

  elseif d == "kurve" then
    Z.text(L, x0 + tx, y0 + pad + th / 2, titel, gr(L, th), C.titel, LEFT, max(8, b * 0.5 - (tx - pad)))
    Z.wert(L, x0 + b - pad, y0 + pad + th / 2, wert, gr(L, th * 1.3), fg, RIGHT, b * 0.48, true)
    local px, py, pb, ph = x0 + pad, y0 + 2 * pad + th, b - 2 * pad, h - 3 * pad - th - (zt and th or 0)
    if ph > 4 then
      Z.rechteck(px, py + ph, pb, 1, C.linie)
      local K = w.studio.kurven[i]
      if K and K.n > 0 then
        local n = K.voll and 120 or K.n
        -- Befehle in paint: höchstens 60 Linien je Kurve (jeder zweite Punkt, der neueste immer), je Punkt nur
        -- zweimal floor (gemessen: 16 Plätze mit 2 vollen Kurven vorher ~12 500 Befehle für die Kurven)
        local sp = n > 60 and 2 or 1
        local dx, rng, p, basis = pb / 119, hi - lo, K.p, K.voll and K.n or 0
        lcd.color(fg)
        local lx, ly = nil, nil
        for j = (n - 1) % sp + 1, n, sp do
          local v = p[(basis + j - 1) % 120 + 1]                  -- älteste zuerst
          if v then
            local a = (v - lo) / rng
            if a < 0 then a = 0 elseif a > 1 then a = 1 end
            local sx, sy = floor(px + (120 - n + j - 1) * dx), floor(py + ph - a * ph)
            if lx then lcd.drawLine(lx, ly, sx, sy) end
            lx, ly = sx, sy
          else
            lx = nil
          end
        end
      end
    end
    if zt then Z.text(L, x0 + b - pad, y0 + h - pad - th / 2, zt, gr(L, th), C.gelb, RIGHT, b - 2 * pad) end

  else                                                   -- "zahl"
    Z.text(L, x0 + tx, y0 + pad + th / 2, titel, gr(L, th), st == 2 and fg or C.titel, LEFT, tb)
    local vy = y0 + pad + th + (h - 2 * pad - th - (zt and th or 0)) / 2
    Z.wert(L, x0 + b - pad, vy, wert, gr(L, min(h * 0.42, 52)), fg, RIGHT, b - 2 * pad, true)
    if zt then Z.text(L, x0 + b - pad, y0 + h - pad - th / 2, zt, gr(L, th), C.gelb, RIGHT, b - 2 * pad) end
  end

  -- antippbar wie im eingebauten Standard
  if q.w == "lua:laeufe" then Z.ziel(w, "liste_seite", x0, y0, b, h)
  elseif q.w == "lua:status" then Z.ziel(w, "status", x0, y0, b, h) end
end

function A.zeichne(w, L, Z, ans, ST)
  local SY = w.sym
  if SY then                                             -- Format 2: Schmuck nach dem Hintergrund, vor den Plätzen
    SY.bildAnfang()
    if ans.roh then SY.deko(ans.roh, 0, 0, Z.C.titel, ans.sk) end
  end
  for i, q in ipairs(ans.plaetze) do
    local ok, e = pcall(zeichnePlatz, w, L, Z, q, ST, i)
    if not ok and not w.platzFehler then
      w.platzFehler = true
      print(tostring(w.name) .. ": Fehler beim Zeichnen von " .. tostring(q.w) .. ": " .. tostring(e))
    end
  end
  -- reservierte Fläche im Vollbild 800 × 480: Zahl der Läufe (öffnet die Flugliste), wie im eingebauten Standard
  if L.W == 800 and L.H == 480 then
    local C, T = Z.C, w.T
    local g, fh = 8, 40
    local x, y, b = g, L.H - g - fh, 232
    Z.kachel(L, x, y, b, fh)
    local n = w.dauer.laeufe or 0
    local t = n == 1 and T.lauf1 or string.format(T.laeufe, string.format("%.0f", n))
    Z.text(L, x + b / 2, y + fh / 2, t, 16, C.weiss, CENTERED, b - 12, true)
    Z.ziel(w, "liste_seite", x, y, b, fh)
  end
  if SY and SY.nochZuZeichnen() and lcd.invalidate then lcd.invalidate() end   -- Masken/Texte für das nächste Bild
end

return A
