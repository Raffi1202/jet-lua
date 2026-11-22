-- Jet: Regel «Einheit steht schon im Titel» (gleich wie Electric 0.7.4). Aufruf aus dem Repo-Ordner: lua test/titel-test.lua
lcd = {} local A = dofile("src/jet/ansicht.lua")
local f = A.imTitel
local faelle = { { "Akku %", "%", true }, { "Strom (A)", "A", true }, { "Speed km/h", "km/h", true }, { "Höhe max", "m", false },
  { "Akku Strom", "A", false }, { "Akku%", "%", false } }
local n = 0
for _, c in ipairs(faelle) do local ok = f(c[1], c[2]) == c[3] if not ok then n = n + 1 end print((ok and "ok " or "FEHLER ") .. c[1] .. " / " .. c[2]) end
print(n == 0 and "ERGEBNIS: kein Fehler" or "ERGEBNIS: " .. n .. " Fehler")
