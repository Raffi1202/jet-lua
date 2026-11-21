-- Jet: Seite 2 «Turbinen», nur bei 2–4 Turbinen (JetCat-Slaves). Je Turbine eine Spalte mit Drehzahl, EGT,
-- Kraftstoff, ECU-Akku und Status. Werte über der Warnschwelle orange, über der Alarmschwelle rot.
local S = {}
local max = math.max

function S.zeichne(w, L, Z)
  local C, W, H, g, s, T, gr = Z.C, L.W, L.H, L.gp, L.s, w.T, w.g
  local n = math.min(4, max(2, w.nTurb or 2))
  local y0 = L.y0
  local b = (W - (n + 1) * g) / n
  local h = H - y0 - g
  local GF = { C.grau, C.blau, C.gruen, C.rot }
  local function stufe(x, wn, al, unter)
    if x == nil then return C.weiss end
    if al and ((unter and x < al) or ((not unter) and x > al)) then return C.rot end
    if wn and ((unter and x < wn) or ((not unter) and x > wn)) then return C.orange end
    return C.weiss
  end
  for i = 1, n do
    local t = w.tb[i]
    local x = g + (i - 1) * (b + g)
    local ecuF = stufe(t.ecu, gr.ecuW, gr.ecuA, true)
    local egtF = stufe(t.egt, gr.egtW, gr.egtA, false)
    local krF = stufe(t.proz, gr.kraftW, gr.kraftA, true)
    local schlimm = (egtF == C.rot or krF == C.rot or ecuF == C.rot or t.gruppe == 4)
    Z.kachel(L, x, y0, b, h, schlimm and C.rot or nil)
    Z.rechteck(x + 8 * s, y0, b - 16 * s, max(2, math.floor(2 * s)), (egtF ~= C.weiss or krF ~= C.weiss) and C.orange or C.akzent)
    Z.text(L, x + b / 2, y0 + 22 * s, string.format(T.turbine, tostring(i)), 17, C.gelb, CENTERED, b - 12 * s, true)
    local status = t.text or (t.code ~= nil and string.format(T.code, tostring(t.code))) or nil
    local zeilen = {
      { T.t1, t.rpm and string.format("%.0f", t.rpm), C.weiss },
      { T.t2 .. " °C", t.egt and string.format("%.0f", t.egt), egtF },
      { T.t3 .. " %", t.proz and string.format("%.0f", t.proz), krF },
      { T.t4 .. " V", t.ecu and Z.zahl(t.ecu, 1), ecuF },
      { T.t5, status, GF[t.gruppe or 0] or C.weiss },
    }
    local zh = (h - 40 * s) / 5
    for j, r in ipairs(zeilen) do
      local yy = y0 + 40 * s + (j - 1) * zh
      Z.text(L, x + 12 * s, yy + zh * 0.25, r[1], 12, C.grau, LEFT, b - 24 * s)
      Z.wert(L, x + b - 12 * s, yy + zh * 0.62, r[2], n > 2 and 22 or 28, r[3], RIGHT, b - 24 * s, true)
    end
  end
end

return S
