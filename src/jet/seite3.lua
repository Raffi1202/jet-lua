-- Jet: Seite 3, Flugliste wie Heli RF und Elektro. Links die Werte des gewählten Laufs, rechts die Liste
-- (neueste oben, der laufende Lauf zuerst), unten ZURÜCK, LAUF n LÖSCHEN und LISTE LÖSCHEN (mit Rückfrage).
local S = {}
local floor, max, min = math.floor, math.max, math.min

-- Text zum Ende eines Laufs (Spalte 10: 1 SF aus, 2 Abschaltung; Grund aus Code 11 und Tabelle 12)
local function endeText(w, r, kurz)
  local T = w.T
  if r[10] == 1 then return T.eSf end
  if r[10] == 2 then
    if kurz then return T.eAbsch end                -- in der Liste kurz, der Grund steht in den Details
    local K = w.kern
    local t = K and K.statusText and K.statusText(w, r[12], r[11]) or nil
    if t then return t end
    return T.eAbsch
  end
  return kurz and "-" or T.eNormal
end

function S.zeichne(w, L, Z)
  local C, W, H, g, s, T = Z.C, L.W, L.H, L.gp, L.s, w.T
  local y0 = L.y0
  local kh = max(floor(40 * s), L.tipp)
  local h = H - y0 - kh - 2 * g
  local bl = (W - 3 * g) / 2
  Z.kachel(L, g, y0, bl, h)
  Z.kachel(L, 2 * g + bl, y0, bl, h)

  local e = {}
  if w.akt and w.akt[1] then e[1] = w.akt end
  for i = #w.liste, 1, -1 do e[#e + 1] = w.liste[i] end
  local sel = nil
  for _, r in ipairs(e) do if r[1] == w.wahl then sel = r end end
  if sel == nil then w.wahl = nil end

  -- links: Werte des gewählten Laufs
  if sel then
    Z.text(L, g + 14 * s, y0 + 20 * s, string.format(T.lauf, string.format("%.0f", sel[1])), 17, C.gelb, LEFT, bl - 28 * s, true)
    local function f(x, dez, e2) return x and (Z.zahl(x, dez) .. e2) or nil end
    local D = {
      { T.dLaufzeit, Z.zeit(sel[2]) }, { T.dVerbraucht, f(sel[3], 0, " ml") }, { T.dEgt, f(sel[4], 0, " °C") },
      { T.dRpm, f(sel[5], 0, "") }, { T.dKraftstoff, f(sel[6], 0, " %") }, { T.dHoehe, f(sel[7], 0, " m") },
      { T.dSpeed, f(sel[8], 0, " km/h") }, { T.dEcu, f(sel[9], 1, " V") },
      { T.dEnde, sel == w.akt and T.laeuft or endeText(w, sel) }, { T.dTurbinen, f(sel[13], 0, "") },
    }
    local zh = (h - 40 * s) / 5
    for i, d in ipairs(D) do
      local cx = g + 14 * s + ((i - 1) % 2) * (bl / 2)
      local cy = y0 + 40 * s + ((i - 1) // 2) * zh
      Z.text(L, cx, cy + zh * 0.28, d[1], 12, C.grau, LEFT, bl / 2 - 18 * s)
      local farbe = (i == 9 and sel[10] == 2) and C.rot or C.weiss
      Z.wert(L, cx, cy + zh * 0.66, d[2], 22, farbe, LEFT, bl / 2 - 18 * s, true)
    end
  else
    Z.text(L, g + bl / 2, y0 + h / 2, #e > 0 and T.antippen or T.keineLaeufe, 16, C.grau, CENTERED, bl - 20 * s)
  end

  -- rechts: Liste
  local xl = 2 * g + bl
  Z.text(L, xl + 14 * s, y0 + 20 * s, T.laufListe, 17, C.gelb, LEFT, bl * 0.5, true)
  Z.text(L, xl + bl - 12 * s, y0 + 20 * s, string.format(T.fertig, tostring(#w.liste)), 13, C.grau, RIGHT, bl * 0.4)
  local sp = { xl + 14 * s, xl + bl * 0.46, xl + bl * 0.68, xl + bl - 12 * s }
  local yk = y0 + max(42 * s, 33)
  local kopf = { T.nr, T.dauer, "ml", T.ende }
  for i = 1, 4 do Z.text(L, sp[i], yk, kopf[i], 12, C.grau, i == 1 and LEFT or RIGHT) end
  local yl = y0 + max(52 * s, 41)
  Z.rechteck(xl + 10 * s, yl, bl - 20 * s, 1, C.linie)
  local ys = yl + 4 * s
  local platz = y0 + h - 4 * s - ys
  local sicht = max(1, min(6, floor(platz / L.tipp)))   -- Zeilen sind antippbar: nie niedriger als L.tipp
  local rh = platz / sicht
  w.sicht = sicht
  if #e == 0 then
    Z.text(L, xl + bl / 2, y0 + h / 2, T.keineLaeufe, 18, C.grau, CENTERED, bl - 20 * s)
  end
  w.oben = max(0, min(w.oben or 0, max(0, #e - sicht)))
  for k = 1, sicht do
    local r = e[k + w.oben]
    if r == nil then break end
    local yy = ys + (k - 1) * rh
    local gewaehlt = r[1] == w.wahl
    if gewaehlt then Z.rund(xl + 6 * s, yy, bl - 12 * s, rh, 4 * s, C.wahl) end
    local farbe = (r == w.akt) and C.hblau or (r[10] == 2 and C.rot or C.weiss)
    local nr = string.format("%.0f", r[1])
    if r == w.akt then nr = nr .. " " .. T.laeuft end
    local t = { nr, Z.zeit(r[2]), r[3] and string.format("%.0f", r[3]), r == w.akt and "-" or endeText(w, r, true) }
    for i = 1, 4 do
      Z.wert(L, sp[i], yy + rh / 2, t[i], i == 4 and 15 or 20, farbe, i == 1 and LEFT or RIGHT,
        i == 1 and bl * 0.3 or (i == 4 and bl * 0.3 or nil), gewaehlt)
    end
    Z.ziel(w, "wahl", xl, yy, bl, rh, r[1])
  end

  -- Knöpfe
  local kb, ky = (W - 4 * g) / 3, H - g - kh
  Z.knopf(w, L, "seite1", g, ky, kb, kh, T.zurueck, C.akzent, false, 15, C.weiss)
  local da = sel ~= nil
  Z.knopf(w, L, da and "loeschen" or nil, 2 * g + kb, ky, kb, kh,
    da and string.format(T.laufLoeschen, string.format("%.0f", sel[1])) or T.laufLoeschen0,
    da and C.orange or C.rand, false, 15, da and C.orange or C.grau)
  local liste = #e > 0
  Z.knopf(w, L, liste and "liste" or nil, 3 * g + 2 * kb, ky, kb, kh, T.listeLoeschen,
    liste and C.akzent or C.rand, false, 15, liste and C.weiss or C.grau)
end

return S
