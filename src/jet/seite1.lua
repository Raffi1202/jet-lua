-- Jet: Seite 1. Vollbild: oben vier Tachos, unten links das grosse Feld STATUS und die Zahl der Läufe, rechts sechs
-- Felder. Kompaktansicht (Layout mit Kopf- und Fussleiste): oben vier Tachos, unten acht Felder (STATUS, Feld 1–6,
-- Läufe). Was in welchem Tacho und Feld steht, wählt der User im Menü (Nummern wie in felder.lua, INHALT).
-- Eine Seite zeichnet nur: Werte kommen aus w.v, Texte aus w.T.
local S = {}
local floor, max, min = math.floor, math.max, math.min

local function ganz(x) return x and string.format("%.0f", x) or nil end

-- Bei mehreren Turbinen: «T2» hinter dem kritischsten Wert
local function tn(w, k)
  local n = w.v.krit and w.v.krit[k]
  return n and (" T" .. n) or ""
end

-- Inhalt Nummer n: { titel, wert, einheit, anteil, farbe, unten, untenFarbe, st, akzent, wertFarbe }
local function inhalt(w, Z, n, klein)
  local v, c, T, C, st = w.v, w.cfg, w.T, Z.C, w.st
  local function mx(x, e) return x and (T.hoechst .. " " .. x .. e) or nil end
  if n == 1 then
    local maxR = (c.maxRpm or 0) > 0 and c.maxRpm or max(v.sollHoch or 0, v.rpmHoch or 0, 1)
    local unten = v.soll and (T.soll .. " " .. ganz(v.soll)) or mx(ganz(v.rpmHoch), "")
    return { titel = T.t1, wert = ganz(v.rpm), einheit = T.umin, anteil = v.rpm and v.rpm / maxR,
      farbe = C.hblau, unten = unten, untenFarbe = C.gelb, akzent = C.hblau, kurz = "" }
  elseif n == 2 then
    return { titel = T.t2 .. tn(w, "egt"), wert = ganz(v.egt), einheit = "°C", anteil = v.egt and (v.egt - 350) / 450,
      farbe = Z.stufenFarbe(st.egt, C.gruen), unten = mx(ganz(v.egtHoch), "°C"), untenFarbe = C.gelb, st = st.egt,
      akzent = Z.stufenFarbe(st.egt, C.gruen), kurz = "°C" }
  elseif n == 3 then
    local unten, uf = v.mlRest and (ganz(v.mlRest) .. " ml") or nil, C.weiss
    if v.tankFehlt then unten, uf = T.tankEinst, C.orange
    elseif v.ml and v.mlRest == nil then unten = ganz(v.ml) .. " ml" end
    return { titel = (klein and T.t3k or T.t3) .. tn(w, "proz"), wert = ganz(v.proz), einheit = "%",
      anteil = v.proz and v.proz / 100, farbe = Z.stufenFarbe(st.kraft, C.gruen), unten = unten, untenFarbe = uf,
      st = st.kraft, akzent = Z.stufenFarbe(st.kraft, C.gruen), kurz = " %" }
  elseif n == 4 then
    local lv = w.ECU_LEER_VOLL[c.ecuArt or 1] or w.ECU_LEER_VOLL[1]
    local z = max(1, c.ecuZellen or 2)
    return { titel = T.t4 .. tn(w, "ecu"), wert = v.ecu and Z.zahl(v.ecu, 1), einheit = T.volt,
      anteil = v.ecu and (v.ecu / z - lv[1]) / (lv[2] - lv[1]), farbe = Z.stufenFarbe(st.ecu, C.gruen),
      unten = v.ecuTief and (T.tiefst .. " " .. Z.zahl(v.ecuTief, 1) .. "V"), untenFarbe = C.gelb, st = st.ecu,
      akzent = C.gruen, kurz = "V" }
  elseif n == 5 then
    local t = w.tb[1]
    local text = t.text or (t.code ~= nil and string.format(T.code, tostring(t.code))) or nil
    local f = ({ C.grau, C.blau, C.gruen, C.rot })[t.gruppe or 0] or C.weiss
    local st5 = nil
    if w.absch then
      st5 = 2
      if w.absch[2] then text = w.absch[2] elseif w.absch[3] then text = w.T.pAbsch end
      if w.absch[1] > 1 then text = "T" .. w.absch[1] .. " " .. tostring(text) end
    end
    local unten = nil
    if w.akt and t.gruppe == 3 then unten = string.format(T.seit, Z.zeit(w.akt[2] or 0)) end
    return { titel = T.t5, wert = text, einheit = "", farbe = f, st = st5, unten = unten, untenFarbe = C.titel,
      wertFarbe = f, status = true, akzent = f }
  elseif n == 6 then
    local a = w.akt
    return { titel = klein and T.t6 or (T.t6 .. " ml/min"), wert = ganz(v.fluss), einheit = "ml/min",
      anteil = v.fluss and v.fluss / 1000, farbe = C.hblau, akzent = C.hblau,
      unten = a and a[3] and string.format(T.verbr, ganz(a[3])) or nil }
  elseif n == 7 then
    local pw = v.pumpePW
    local wert = v.pumpe and (pw and (ganz(v.pumpe * 100) .. " PW") or (Z.zahl(v.pumpe, 2) .. " V"))
    local hoch = v.pumpeHoch and (pw and (ganz(v.pumpeHoch * 100) .. " PW") or (Z.zahl(v.pumpeHoch, 2) .. "V"))
    return { titel = T.t7, wert = wert, einheit = pw and "PW" or "V", anteil = v.pumpe and v.pumpe / 3, farbe = C.hblau,
      unten = hoch and (T.hoechst .. " " .. hoch), akzent = C.hblau }
  elseif n == 8 then
    return { titel = T.t8, wert = v.schub and (ganz(v.schub) .. " N"), einheit = "N", anteil = v.schub and v.schub / max(1, v.schubHoch or 1),
      farbe = C.hblau, unten = mx(ganz(v.schubHoch), "N"), akzent = C.hblau }
  elseif n == 9 then
    local e = (w.dz.hoehe or 0) > 0 and 1 or 0
    return { titel = T.t9, wert = v.hoehe and (Z.zahl(v.hoehe, e) .. " m"), einheit = "m",
      anteil = v.hoehe and v.hoehe / max(1, (w.g.hoeheA or 150) * 1.2), farbe = Z.stufenFarbe(st.hoehe, C.hblau),
      unten = mx(ganz(v.hoeheHoch), "m"), st = st.hoehe, akzent = C.hblau }
  elseif n == 10 then
    return { titel = T.t10, wert = v.speed and (ganz(v.speed) .. (klein and "" or " km/h")), einheit = "km/h",
      anteil = v.speed and v.speed / max(1, w.g.speedA or 400), farbe = Z.stufenFarbe(st.speed, C.hblau),
      unten = mx(ganz(v.speedHoch), ""), st = st.speed, akzent = C.hblau }
  elseif n == 11 then
    local d0 = v.dbm and 120 or 0
    local eh = v.dbm and "dBm" or "dB"
    local z = nil
    if v.rx then z = "RX " .. Z.zahl(v.rx, 1) .. "V" end
    if v.rssiTief and not klein then z = (z and (z .. "  ") or "") .. T.tiefst .. " " .. ganz(v.rssiTief - d0) end
    local stx = st.rssi
    if st.rx and (stx == nil or st.rx > stx) then stx = st.rx end
    return { titel = T.t11, wert = v.rssi and (ganz(v.rssi - d0) .. " " .. eh), einheit = eh,
      anteil = v.rssi and v.rssi / 100, farbe = Z.stufenFarbe(stx, C.gruen), unten = z, st = stx,
      wertFarbe = C.gruen, akzent = C.gruen }
  elseif n == 12 then
    return { titel = T.t12, wert = v.gas and (ganz(v.gas) .. " %"), einheit = "%", anteil = v.gas and v.gas / 100,
      farbe = C.hblau, akzent = C.hblau }
  elseif n == 13 then
    return { titel = T.t13, wert = ganz(v.welle), einheit = T.umin, anteil = v.welle and v.welle / max(1, v.welleHoch or 1),
      farbe = C.hblau, unten = mx(ganz(v.welleHoch), ""), akzent = C.hblau }
  elseif n == 14 then
    return { titel = T.t14, wert = v.strom and (Z.zahl(v.strom, 1) .. " A"), einheit = "A", anteil = v.strom and v.strom / 10,
      farbe = C.blau, akzent = C.blau }
  elseif n == 15 then
    local a = w.akt
    return { titel = T.t15, wert = Z.zeit(a and a[2] or 0), einheit = "", anteil = a and a[2] and a[2] / 900,
      farbe = C.blau, akzent = C.blau }
  elseif n == 16 then
    return { titel = T.t16, wert = v.mlRest and (ganz(v.mlRest) .. " ml") or (v.ml and (ganz(v.ml) .. " ml")), einheit = "ml",
      anteil = v.proz and v.proz / 100, farbe = Z.stufenFarbe(st.kraft, C.gruen), st = st.kraft, akzent = C.gruen }
  elseif n == 17 then
    return { titel = T.t17, wert = v.rx and (Z.zahl(v.rx, 1) .. "V"), einheit = "V", anteil = v.rx and v.rx / 8.4,
      farbe = Z.stufenFarbe(st.rx, C.gruen), unten = v.rxTief and (T.tiefst .. " " .. Z.zahl(v.rxTief, 1) .. "V"),
      st = st.rx, akzent = C.akzent }
  end
  return nil
end

local function tacho(w, L, Z, x, y, b, h, n)
  local k = inhalt(w, Z, n, L.klein or L.kompakt)
  if k == nil then
    Z.kachel(L, x, y, b, h)
    return
  end
  if k.wert and not k.status then k.wert = k.wert:gsub("%s*[%a/%%]+$", "") end   -- im Tacho steht die Einheit unter der Zahl
  if k.status then                                    -- Status als Tacho: Text in der Mitte, kein Bogen
    k.anteil = nil
    k.einheit = ""
  end
  Z.ring(L, x, y, b, h, k)
end

local function feld(w, L, Z, x, y, b, h, n, gross)
  local C = Z.C
  local k = inhalt(w, Z, n, L.klein or L.kompakt)
  if k == nil then
    Z.kachel(L, x, y, b, h)
    return
  end
  if k.wert and k.kurz then k.wert = k.wert .. k.kurz end
  Z.feld(L, x, y, b, h, { titel = k.titel, wert = k.wert, zusatz = k.unten, zusatzFarbe = k.untenFarbe,
    farbe = k.wertFarbe or C.weiss, st = k.st, gr = gross and 40 or nil })
  if n == 5 then Z.ziel(w, "status", x, y, b, h) end   -- STATUS antippen: letzte Statuswechsel
end

-- Zahl der Läufe (antippen öffnet die Flugliste)
local function laeufe(w, L, Z, x, y, b, h, alsFeld)
  local C, T = Z.C, w.T
  local n = w.dauer.laeufe or 0
  if alsFeld then
    Z.feld(L, x, y, b, h, { titel = T.laufListe, wert = ganz(n), farbe = C.weiss })
  else
    Z.kachel(L, x, y, b, h)
    local t = n == 1 and T.lauf1 or string.format(T.laeufe, ganz(n))
    Z.text(L, x + b / 2, y + h / 2, t, 16, C.weiss, CENTERED, b - 12 * L.s, true)
  end
  Z.ziel(w, "liste_seite", x, y, b, h)
end

-- Kompaktansicht: vier Tachos, darunter zwei Reihen mit je vier Feldern (Konzept «Luas kompakt», 20.11.2026)
local function kompakt(w, L, Z)
  local W, H, g, c = L.W, L.H, L.gp, w.cfg
  local y1 = L.y0
  local frei = H - y1 - 2 * g
  local h1 = floor(frei * 0.54)
  local b1 = (W - 5 * g) / 4
  for i = 1, 4 do tacho(w, L, Z, g + (i - 1) * (b1 + g), y1, b1, h1, c["t" .. i] or 0) end
  local y2 = y1 + h1 + g
  local hf = (H - y2 - 2 * g) / 2
  local bf = (W - 5 * g) / 4
  local liste = { 5, c.f1 or 0, c.f2 or 0, c.f3 or 0, c.f4 or 0, c.f5 or 0, c.f6 or 0 }
  for i = 1, 8 do
    local x, y = g + ((i - 1) % 4) * (bf + g), y2 + ((i - 1) // 4) * (hf + g)
    if i == 8 then laeufe(w, L, Z, x, y, bf, hf, true) else feld(w, L, Z, x, y, bf, hf, liste[i]) end
  end
end

function S.zeichne(w, L, Z)
  if L.kompakt then return kompakt(w, L, Z) end
  local W, H, g, s, c = L.W, L.H, L.gp, L.s, w.cfg
  local y1 = L.y0
  local h1 = floor(198 * s)
  local b1 = (W - 5 * g) / 4
  for i = 1, 4 do tacho(w, L, Z, g + (i - 1) * (b1 + g), y1, b1, h1, c["t" .. i] or 0) end
  local y2 = y1 + h1 + g
  local h2 = H - y2 - g
  local bb = floor(232 * s)
  local fh = max(floor(40 * s), L.tipp)
  feld(w, L, Z, g, y2, bb, h2 - fh - g, 5, true)          -- STATUS gross an der Stelle des früheren Bildes
  laeufe(w, L, Z, g, H - g - fh, bb, fh, false)
  local x0 = 2 * g + bb
  local bf, hf = (W - x0 - 3 * g) / 3, (h2 - g) / 2
  for i = 1, 6 do
    local col, row = (i - 1) % 3, (i - 1) // 3
    feld(w, L, Z, x0 + col * (bf + g), y2 + row * (hf + g), bf, hf, c["f" .. i] or 0)
  end
end

return S
