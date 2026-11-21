-- Jet: Studio-Datei laden und prüfen (Lua-Studio-Format v1, Abschnitt 12) auf dem Mac.
-- Aufruf aus dem Repo-Ordner:  /opt/homebrew/opt/lua@5.4/bin/lua test/studio-test.lua
--  a) keine Datei: Zustand «fehlt», kein Hinweis
--  b) alle Angriffs- und Grenzfalldateien (test/studio-dateien): nie ein Absturz, Zustand passt
--  c) gültige Datei mit absichtlichen Fehlern (test/studio/gueltig.jet.lua) und .funke.lua: Werte geprüft
--  d) .funke.lua schreiben: .neu, prüfen, alte entfernen, umbenennen; übrig gebliebene .funke.neu
--  k) «auch bei Motor aus» (beiMotorAus) lesen, anwenden, in .funke.lua schreiben und zurücklesen
-- Je Aufruf von studio.schritt höchstens 5000 Lua-Befehle (debug.sethook).
local repo = arg[0]:gsub("test/studio%-test%.lua$", "")
local tmp = os.tmpname()
os.remove(tmp)
assert(os.execute("mkdir -p '" .. tmp .. "/SCRIPTS/studio' '" .. tmp .. "/jet'"))
assert(os.execute("cp '" .. repo .. "src/jet/'*.lua '" .. tmp .. "/jet/'"))

local print_ = print
local fehlerZahl = 0
local function pruefe(ok, text)
  print_((ok and "ok     " or "FEHLER ") .. text)
  if not ok then fehlerZahl = fehlerZahl + 1 end
end

-- Ethos-Umgebung: SCRIPTS:/ -> tmp/SCRIPTS/, relative Pfade -> Skriptordner
local function pfad(p)
  if p:sub(1, 9) == "SCRIPTS:/" then return tmp .. "/SCRIPTS/" .. p:sub(10) end
  if p:sub(1, 1) == "/" then return p end
  return tmp .. "/jet/" .. p
end
local io_open, os_rename, os_remove = io.open, os.rename, os.remove
io.open = function(p, m) return io_open(pfad(p), m) end
local laden = loadfile
loadfile = function(p, ...) return laden(pfad(p), ...) end
os.rename = function(a, b)
  local f = io_open(pfad(b), "r")                     -- wie am Sender: überschreibt nicht
  if f then f:close() return nil, "exists" end
  return os_rename(pfad(a), pfad(b))
end
os.remove = function(p) return os_remove(pfad(p)) end
os.mkdir = function() return true end
model = { name = function() return "TEST" end, path = function() return "/models/test.bin" end }
system = { getSources = function() return {} end, getVersion = function() return { board = "X18RS", version = "26.2.0" } end }
CATEGORY_TELEMETRY_SENSOR = 4
local zeilen = 0
print = function(...) zeilen = zeilen + 1 end

local F = assert(loadfile("felder.lua"))()
local ST = assert(loadfile("studio.lua"))()

local function kopiere(von, nach)
  local a = assert(io_open(von, "rb")) local t = a:read("a") a:close()
  local b = assert(io_open(nach, "wb")) b:write(t) b:close()
end
local ziel = tmp .. "/SCRIPTS/studio/TEST.jet.lua"

-- ein ganzer Ladevorgang; Rückgabe Ergebnis, grösste Befehlszahl je Aufruf, Fehlertext (grStufe: Stufe dazu)
local grStufe
local function ganz()
  local w = {}
  local hoechst, r = 0, nil
  for _ = 1, 2000 do
    local n = 0
    debug.sethook(function() n = n + 1 end, "", 1)
    local st0 = w.studioJob and w.studioJob.stufe
    local ok, e = pcall(ST.schritt, w, F)
    debug.sethook()
    if n > hoechst then hoechst, grStufe = n, st0 end
    if not ok then return nil, hoechst, tostring(e) end
    if e then r = e break end
  end
  return r, hoechst
end

-- a) keine Datei
os_remove(ziel)
local r, n = ganz()
pruefe(r and r.zustand == "fehlt", "a) keine Datei: fehlt (" .. n .. " Befehle)")

-- b) Angriffe und Grenzfälle
local liste = io.popen("ls '" .. repo .. "test/studio-dateien/'"):read("a")
local maxN, anzahl = 0, 0
for name in liste:gmatch("[^\n]+") do
  kopiere(repo .. "test/studio-dateien/" .. name, ziel)
  local e, nb, err = ganz()
  anzahl = anzahl + 1
  if nb > maxN then maxN = nb end
  pruefe(e ~= nil and err == nil, "b) " .. name .. ": " .. (err or (e.zustand .. (e.fehler and (", " .. e.fehler .. " Fehler") or ""))) .. ", " .. nb .. " Befehle")
end
pruefe(maxN < 5000, "b) " .. anzahl .. " Dateien, höchstens " .. maxN .. " Befehle je Aufruf (< 5000)")

-- erwartete Zustände der Format-Testdateien (Abschnitt 12.1)
do
  local soll = { format99 = "zuNeu", typisch = "geladen", g16_lang24 = "geladen", g16_513 = "geladen", g16_liste = "geladen",
    g16_tab = "geladen", g16_text = "geladen", g12_lang24 = "geladen" }
  for _, n in ipairs({ "a", "b", "c", "binaer", "escapeQuote", "global", "inf", "pruefer3_a1", "pruefer3_a2", "pruefer3_a3",
    "pruefer3_a4", "pruefer3_a5", "pruefer3_a6", "pruefer3_a7", "riesigeListe", "schleife", "tiefe" }) do soll[n] = "kaputt" end
  local falsch = {}
  for name, z in pairs(soll) do
    kopiere(repo .. "test/studio-dateien/" .. name .. ".txt", ziel)
    local e = ganz()
    if not e or e.zustand ~= z then falsch[#falsch + 1] = name .. "=" .. tostring(e and e.zustand) end
  end
  pruefe(#falsch == 0, "b) Zustände wie erwartet (zuNeu, geladen, kaputt) " .. table.concat(falsch, " "))
end

-- b2) Speicher beim Laden (Mac, Lua 5.4, Aufräumen aus, nach jedem Befehl abgetastet): Spitze und danach
for _, name in ipairs({ "typisch", "g16_lang24", "g16_513", "g12_lang24" }) do
  kopiere(repo .. "test/studio-dateien/" .. name .. ".txt", ziel)
  collectgarbage() collectgarbage()
  local m0, spitze = collectgarbage("count"), 0
  collectgarbage("stop")
  local w = {}
  local r
  for _ = 1, 2000 do
    debug.sethook(function() local m = collectgarbage("count") if m > spitze then spitze = m end end, "", 1)
    r = ST.schritt(w, F)
    debug.sethook()
    if r then break end
  end
  collectgarbage("restart") collectgarbage() collectgarbage()
  local m1 = collectgarbage("count")
  print_(string.format("info   b2) %s: Spitze +%.0f KB, danach +%.1f KB (Ergebnis behalten), Zustand %s", name, spitze - m0, m1 - m0, tostring(r and r.zustand)))
  r = nil
end

-- c) gültige Datei mit absichtlichen Fehlern, dazu .funke.lua
kopiere(repo .. "test/studio/gueltig.jet.lua", ziel)
kopiere(repo .. "test/studio/gueltig.jet.funke.lua", tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua")
zeilen = 0
local J, nc = ganz()
pruefe(J and J.zustand == "geladen", "c) gültige Datei geladen, " .. nc .. " Befehle je Aufruf höchstens")
pruefe(J.fehler == zeilen and J.fehler >= 8, "c) Fehler gezählt und je Fehler eine Log-Zeile: " .. tostring(J.fehler) .. " / " .. zeilen)
pruefe(J.einst.tank == 3300, "c) Tank: .funke.lua (3300) über Studio (2200)")
pruefe(J.einst.ecuZellen == 3 and J.einst.kraftArt == 2 and J.einst.sw1Name == "FAHRWERK", "c) Einstellungen mit Namen klein_mit_ übernommen")
pruefe(J.einst.leerlauf == nil, "c) ungültige Einstellung (leerlauf = 999999) verworfen")
local g = J.grenzen
pruefe(g["lua:kraftstoff_proz"].warnung == 35 and g["lua:kraftstoff_proz"].alarm == 25, "c) Grenze Kraftstoff: Warnung aus .funke.lua (35), Alarm aus Studio (25)")
pruefe(J.grenzenStudio["lua:kraftstoff_proz"].warnung == 40, "c) Studio-Stand der Grenze gemerkt (40)")
pruefe(g["lua:hoehe"].aus == true, "c) Höhe: aus = true")
pruefe(g["lua:egt"].werk == true and not g["lua:egt"].aus, "c) EGT mit abweichender Richtung: Werkgrenze bleibt, plus Fehler")
pruefe(g["lua:empfang"].warnung == nil and g["lua:empfang"].alarm == 40, "c) Empfang vertauscht: nur Alarm")
pruefe(g["kanal:3"].richtung == "ueber" and g["kanal:3"].warnung == 50, "c) Kanal 3 mit Richtung")
pruefe(g["sensor:0A10:0"].aus == true, "c) Sensor ohne Richtung: aus")
pruefe(J.werte["lua:drehzahl"].faktor == 0.5 and J.werte["lua:quatsch"] == nil, "c) Werte: Faktor übernommen, unbekannter Schlüssel verworfen")
local a = J.ansichten["784x316"]
pruefe(a ~= nil and J.ansichten["800x480"] ~= nil and J.ansichten["480x272"] == nil, "c) zwei Ansichten, dritte verworfen")
local darst, nK = {}, 0
for _, p in ipairs(a.plaetze) do darst[#darst + 1] = p.darst if p.darst == "kurve" then nK = nK + 1 end end
pruefe(#a.plaetze == 11, "c) 11 von 16 Plätzen gültig (" .. #a.plaetze .. "): " .. table.concat(darst, ","))
local nV = 0
for _, p in ipairs(J.ansichten["800x480"].plaetze) do if p.darst == "kurve" then nV = nV + 1 end end
pruefe(nK == 1 and nV == 2 and J.ansichten["800x480"].plaetze[4].darst == "zahl", "c) zu kleine Kurven verworfen, höchstens 2 Kurven je Ansicht, dritte wird zahl")
local tz
for _, p in ipairs(a.plaetze) do if p.w == "lua:egt" then tz = p.titel end end
pruefe(tz and #tz <= 24 and tz:byte(#tz) < 0x80, "c) Titel auf 24 Byte gekürzt, kein halbes Zeichen: " .. tostring(tz))
pruefe(a.plaetze[1].stufen and #a.plaetze[1].stufen == 2, "c) Farbstufen übernommen")
-- ECU-Akku: Grenze in Volt für den ganzen Akku, im cfg je Zelle (3 Zellen aus der Studio-Datei)
local wc = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
ST.anwenden(wc, J, F)
pruefe(wc.cfg.ecuZellen == 3 and wc.cfg.ecuW == 350 and wc.cfg.ecuA == 330, "c) ECU-Akku 10,5/9,9 V bei 3 Zellen -> 350/330 je Zelle (" .. wc.cfg.ecuW .. "/" .. wc.cfg.ecuA .. ")")
pruefe(wc.cfg.egtW == 720 and wc.cfg.egtA == 750 and wc.cfg.hoeheW == 0 and wc.cfg.hoeheA == 0 and wc.cfg.rssiW == 0 and wc.cfg.rssiA == 40,
  "c) im cfg: EGT Werk 720/750, Höhe aus, Empfang nur Alarm 40")
pruefe(wc.cfg.tank == 3300 and wc.cfg.leerlauf == 10000, "c) im cfg: Tank 3300, Leerlauf Werkwert")

-- d) .funke.lua schreiben (wie am Sender: os.rename überschreibt nicht, darum erst entfernen)
local text = ST.funkeText({ tank = 4000, laufAns = false, sw1Name = "Möwe" }, { ["lua:kraftstoff_proz"] = { warnung = 33, alarm = 21 }, ["lua:hoehe"] = { aus = true } })
pruefe(ST.studioLaden ~= nil and ST.funkeSchreiben("TEST", text), "d) .funke.lua geschrieben")
local fu, grund = ST.studioLaden(tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua", 1)
pruefe(fu and fu.einstellungen.tank == 4000 and fu.einstellungen.lauf_ans == false and fu.einstellungen.sw1_name == "Möwe", "d) zurückgelesen: " .. tostring(grund))
pruefe(fu and fu.grenzen["lua:kraftstoff_proz"].warnung == 33 and fu.grenzen["lua:hoehe"].aus == true, "d) Grenzen zurückgelesen")
pruefe(io_open(tmp .. "/SCRIPTS/studio/TEST.jet.funke.neu", "r") == nil, "d) keine .funke.neu übrig")
os_rename(tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua", tmp .. "/SCRIPTS/studio/TEST.jet.funke.neu")
kopiere(repo .. "test/studio/gueltig.jet.lua", ziel)
J = ganz()
pruefe(J and J.einst.tank == 4000 and io_open(tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua", "r") ~= nil, "d) .funke.neu nach Stromausfall übernommen")
local k = io_open(tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua", "w") k:write("return { format = 1, a = os }") k:close()
J = ganz()
pruefe(J and J.zustand == "geladen" and J.funkeVerworfen and J.einst.tank == 2200, "d) kaputte .funke.lua verworfen, Studio-Datei gilt (2200)")

-- e) volle Belegung (Abschnitt 12.2): 2 Ansichten zu 16 Plätzen, je 2 Kurven, 8 eigene Sensoren, 12 Grenzen
os_remove(tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua")
kopiere(repo .. "test/studio/voll.jet.lua", ziel)
local Jv, nv = ganz()
pruefe(Jv and Jv.zustand == "geladen" and Jv.fehler == 0, "e) volle Belegung geladen, 0 Fehler (" .. tostring(Jv and Jv.fehler) .. ")")
pruefe(nv < 5000, "e) höchstens " .. nv .. " Befehle je Aufruf (< 5000)")
local n16 = #Jv.ansichten["784x316"].plaetze + #Jv.ansichten["800x480"].plaetze
pruefe(n16 == 32, "e) 32 Plätze gültig (" .. n16 .. ")")
-- anwenden in Schritten wie im Kern; Rückgabe grösste Befehlszahl je Schritt, Zahl der Schritte
local function anwendenGemessen(wx, Jx)
  local hoechst, schritte = 0, 0
  repeat
    local n = 0
    debug.sethook(function() n = n + 1 end, "", 1)
    local fertig = ST.anwendenSchritt(wx, Jx, F)
    debug.sethook()
    schritte = schritte + 1
    if n > hoechst then hoechst = n end
  until fertig or schritte > 1000
  return hoechst, schritte
end
local w = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
local nA = anwendenGemessen(w, Jv)
pruefe(nA < 5000 and w.cfg.tank == 5000 and w.cfg.leerlauf == 35000 and w.cfg.egtW == 700, "e) angewendet in " .. nA .. " Befehlen, tank " .. tostring(w.cfg.tank) .. ", egtW " .. tostring(w.cfg.egtW))
pruefe(w.cfg.ecuW == 360 and w.cfg.ecuA == 340 and w.cfg.rxW == 700 and w.cfg.speedW == 0 and w.cfg.speedA == 400, "e) Grenzen in cfg (ECU 360/340, RX 700, Speed nur Alarm 400)")
pruefe(#w.studio.extra == 5 and #w.studio.offen == 9, "e) 5 weitere Grenzen, 9 Quellen zu suchen (" .. #w.studio.extra .. ", " .. #w.studio.offen .. ")")
-- laufender Betrieb mit voller Belegung: Werte, Grenzen, Kurven je Aufruf unter 5000 Befehlen
CATEGORY_CHANNEL = 3
system = { getSource = function() return { value = function() return 512 end, decimals = function() return 1 end, unit = function() return 0 end } end,
  getSources = function() return {} end }
w.L = { W = 784, H = 316 }
w.v = { rpm = 98000, egt = 650, proz = 50, ecu = 7.6, rssi = 70, hoehe = 80, speed = 200, fluss = 300 }
w.tb, w.akt = { { gruppe = 3 } }, { 1, 100 }
local nW = 0
for i = 1, 40 do
  local n = 0
  debug.sethook(function() n = n + 1 end, "", 1)
  ST.wecke(w, i * 0.2)
  ST.grenzenExtra(w, i * 0.2, function() return false end, true)
  debug.sethook()
  if n > nW then nW = n end
end
pruefe(nW < 5000 and #w.studio.offen == 0, "e) Betrieb: höchstens " .. nW .. " Befehle je Aufruf, alle Quellen gesucht")

-- f) Modellwechsel zehnmal (Abschnitt 12.3): Speicher wächst nicht
local function wechsel()
  local J2 = ganz()
  local w2 = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
  ST.anwenden(w2, J2, F)
  return w2
end
wechsel() collectgarbage() collectgarbage()
local m0 = collectgarbage("count")
for _ = 1, 10 do wechsel() end
collectgarbage() collectgarbage()
local m1 = collectgarbage("count")
pruefe(m1 - m0 < 4, string.format("f) zehn Modellwechsel: Speicher %.1f KB -> %.1f KB", m0, m1))

-- g) Format 6.5: «false» = Stufe aus; ohne Eintrag in der Studio-Datei beginnt .funke.lua mit den Werkgrenzen
kopiere(repo .. "test/studio/demo.jet.lua", ziel)        -- hat keinen Eintrag für lua:hoehe
local function lua(k) return '["' .. k:gsub(".", function(c) return "\\" .. c:byte() end) .. '"]' end
local fk = io_open(tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua", "w")
fk:write('return { format = 1, grenzen = { ' .. lua("lua:hoehe") .. ' = { warnung = false } } }')
fk:close()
local Jg = ganz()
local gs = Jg and Jg.grenzen["lua:hoehe"]
pruefe(gs and gs.warnung == nil and gs.alarm == 120 and gs.richtung == "ueber", "g) {warnung = false} ohne Studio-Eintrag: Werk-Alarm 120 ohne Warnung")
local wg = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
ST.anwenden(wg, Jg, F)
pruefe(wg.cfg.hoeheW == 0 and wg.cfg.hoeheA == 120, "g) im cfg: Höhe Warnung aus (0), Alarm 120")
wg.cfg.egtW = 0                                              -- an der Funke nur die Warnung ausschalten
local txt = ST.funkeAusCfg(wg, F)
local fz = txt and load(txt, "=t", "t", {})()
local tz2 = fz and fz.grenzen["lua:egt"]
pruefe(tz2 and tz2.warnung == false and tz2.alarm == 740, "g) .funke.lua schreibt warnung = false, Alarm bleibt 740")
os_remove(tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua")

-- h) Alarm-Sicherheit (Ergänzungen «Sicherheit Alarme») und Grenzfälle
local function datei(text) local x = io_open(ziel, "w") x:write(text) x:close() end
local function lade(text)
  datei(text)
  local Jx = ganz()
  local wx = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
  ST.anwenden(wx, Jx, F)
  return Jx, wx
end
local function ist(c, n, wW, wA) return c[n .. "W"] == wW and c[n .. "A"] == wA end
-- fehlende Grenzen schalten nie einen Alarm ab: ohne «grenzen», mit leerer Tabelle, mit nur einer fremden Grenze
for _, t in ipairs({ "return { format = 1 }", "return { format = 1, grenzen = { } }",
  "return { format = 1, grenzen = { " .. lua("kanal:2") .. " = { richtung = " .. lua("ueber"):sub(2, -2) .. ", alarm = 50 } } }" }) do
  local _, wx = lade(t)
  local c = wx.cfg
  pruefe(ist(c, "egt", 720, 750) and ist(c, "kraft", 30, 20) and ist(c, "ecu", 370, 350) and ist(c, "rssi", 45, 40)
    and ist(c, "hoehe", 110, 120) and ist(c, "rx", 0, 0) and ist(c, "speed", 0, 0), "h) fehlende Grenzen = Werkgrenzen: " .. t:sub(1, 40))
end
-- Werkgrenzen in studio.lua = standard.grenzen in studio/beschreibung.json
do
  local f = assert(io_open(repo .. "studio/beschreibung.json", "r"))
  local js = f:read("a") f:close()
  local std = js:match('"standard"%s*:%s*(%b{})')
  local gz = std and std:match('"grenzen"%s*:%s*(%b{})')
  local fehlt = {}
  for s, d in pairs(ST.WERTE) do
    if d.u then
      local e = gz and gz:match('"lua:' .. s .. '"%s*:%s*(%b{})')
      local wg2 = ST.werkGrenze("lua:" .. s, F)
      local ok = e ~= nil and e:match('"richtung"%s*:%s*"(%a+)"') == wg2.richtung
      if ok and e:match('"aus"%s*:%s*true') then ok = wg2.warnung == false and wg2.alarm == false
      elseif ok then
        ok = tonumber(e:match('"warnung"%s*:%s*([%d%.%-]+)')) == wg2.warnung and tonumber(e:match('"alarm"%s*:%s*([%d%.%-]+)')) == wg2.alarm
      end
      if not ok then fehlt[#fehlt + 1] = s end
    end
  end
  local namen = {}
  for s in (js:match('"werte"%s*:%s*(%b[])') or ""):gmatch('\n      "s"%s*:%s*"([%w_]+)"') do namen[s] = true end
  for s in pairs(ST.WERTE) do if not namen[s] then fehlt[#fehlt + 1] = "Wert " .. s end end
  for s in pairs(namen) do if not ST.WERTE[s] then fehlt[#fehlt + 1] = "Wert " .. s .. " (nur JSON)" end end
  pruefe(#fehlt == 0, "h) Werkgrenzen und Werte wie studio/beschreibung.json " .. table.concat(fehlt, " "))
end
-- ausdrücklich aus nur mit aus = true; aus = false hebt es an der Funke wieder auf
local J1, w1 = lade("return { format = 1, grenzen = { " .. lua("lua:kraftstoff_proz") .. " = { aus = true } } }")
pruefe(ist(w1.cfg, "kraft", 0, 0), "h) Studio-Datei schaltet Kraftstoff-Alarm aus (0/0)")
w1.cfg.kraftW, w1.cfg.kraftA = 30, 20
pruefe(ST.funkeSchreiben("TEST", ST.funkeAusCfg(w1, F)), "h) .funke.lua mit Kraftstoff 30/20 geschrieben")
local _, w2 = lade("return { format = 1, grenzen = { " .. lua("lua:kraftstoff_proz") .. " = { aus = true } } }")
pruefe(ist(w2.cfg, "kraft", 30, 20), "h) nach dem Neuladen bleibt der Alarm an (" .. w2.cfg.kraftW .. "/" .. w2.cfg.kraftA .. ")")
os_remove(tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua")
local J3, w3 = lade("return { format = 1, grenzen = { " .. lua("lua:kraftstoff_proz") .. " = { richtung = " .. lua("ueber"):sub(2, -2) .. ", warnung = 30, alarm = 20 } } }")
pruefe(ist(w3.cfg, "kraft", 30, 20) and J3.fehler == 1, "h) abweichende Richtung: Werkgrenze 30/20, 1 Fehler (" .. J3.fehler .. ")")
local J4, w4 = lade("return { format = 1, werte = { " .. lua("lua:kraftstoff_proz") .. " = { faktor = -1, versatz = 100 } }, grenzen = { " .. lua("lua:kraftstoff_proz") .. " = { warnung = 30, alarm = 20 } } }")
pruefe(J4.werte["lua:kraftstoff_proz"] == nil and ist(w4.cfg, "kraft", 30, 20) and J4.fehler == 1, "h) negativer Faktor bei Kraftstoff %: Eintrag verworfen, Grenze 30/20")
local _, w5 = lade("return { format = 1, grenzen = { " .. lua("lua:ecu_akku") .. " = { warnung = 7, alarm = 0.004 } } }")
pruefe(ist(w5.cfg, "ecu", 350, 1), "h) ECU-Akku-Alarm 0,004 V bleibt an (ecuW " .. w5.cfg.ecuW .. ", ecuA " .. w5.cfg.ecuA .. ")")
local J7, w7 = lade("return { format = 1, grenzen = { " .. lua("lua:kraftstoff_proz") .. " = { warnung = " .. lua("x"):sub(2, -2) .. ", alarm = 15 } } }")
pruefe(ist(w7.cfg, "kraft", 30, 15) and J7.fehler == 1, "h) ungültige Warnung: Werkwarnung 30, Alarm 15 (" .. w7.cfg.kraftW .. "/" .. w7.cfg.kraftA .. ")")
local _, w8 = lade("return { format = 1, einstellungen = { ecu_art = 2 } }")
pruefe(ist(w8.cfg, "ecu", 310, 300), "h) ECU-Akkuart LiFe ohne Grenze: Werkgrenze LiFe 310/300 je Zelle")
kopiere(repo .. "test/studio/gueltig.jet.funke.lua", tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua")
kopiere(repo .. "test/studio/gueltig.jet.funke.lua", tmp .. "/SCRIPTS/studio/TEST.jet.funke.neu")
ganz()
pruefe(io_open(tmp .. "/SCRIPTS/studio/TEST.jet.funke.neu", "r") == nil, "h) übrige .funke.neu neben .funke.lua gelöscht")
os_remove(tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua")
local J6 = lade("return { format = 1, ansichten = { { breite = 784, hoehe = 316, plaetze = { { x = 0, y = 0, b = 108, h = 108, w = " .. lua("lua:egt"):sub(2, -2) .. ", darstellung = " .. lua("ring"):sub(2, -2) .. " } } } } }")
pruefe(J6.fehler == 0 and #J6.ansichten["784x316"].plaetze == 1, "h) Ring 108 × 108 auf 784 × 316 gültig")

-- i) grösste gültige Datei je Abschnitt (Lua-Studio-Format v1, 12.2/12.6): so viele Einträge wie die Grenzen
-- von studioLaden (16384 Byte, 1200 Elemente, 240 Tabellen) zulassen, mit den teuersten Einträgen (viele Fehler).
-- Je Aufruf von schritt und anwendenSchritt < 4000 Befehle (Rest bis 5000 bleibt dem Kern im selben Aufruf).
local function esc(t) return '"' .. t:gsub(".", function(c) return "\\" .. c:byte() end) .. '"' end
local function gross(kopf, eintrag, fuss)
  local teile, n = { kopf }, 0
  while true do
    teile[#teile + 1] = eintrag(n + 1)
    local probe = table.concat(teile) .. fuss
    datei(probe)
    if ST.studioLaden(ziel, 1) == nil then teile[#teile] = nil break end
    n = n + 1
  end
  local text = table.concat(teile) .. fuss
  datei(text)
  return n, #text
end
local einstNamen = {}                                 -- bekannte Einstellungen (Studio-Schreibweise) mit Art
for _, gr in ipairs(F.gruppen) do
  for _, f in ipairs(gr[2]) do
    if F.studioEinstellung(f[1]) then
      einstNamen[#einstNamen + 1] = { (f[1]:gsub("(%u)", function(c) return "_" .. c:lower() end)), f[2] }
    end
  end
end
local function buchst(i) local t = "" repeat t = t .. string.char(97 + i % 26) i = i // 26 until i == 0 return t end
local faelle = {
  { "Einstellungen (bekannt ungültig, unbekannt mit vielen _)", "return { format = 1, einstellungen = {", function(i)
    local e = einstNamen[i]
    if e then return " " .. e[1] .. " = " .. (e[2] == "b" and "7" or "true") .. "," end
    return " " .. (buchst(i) .. "_a_b_c_d_e_f_g_h_i_j_k"):sub(1, 24) .. " = 1,"
  end, " } }" },
  { "Werte (je 5 ungültige Felder)", "return { format = 1, werte = {", function(i)
    return " [" .. esc(string.format("sensor:%04X:0", i)) .. "] = { faktor = true, versatz = true, einheit = 1, stellen = 9, name = 1 },"
  end, " } }" },
  { "Werte (gültig, lange Texte)", "return { format = 1, werte = {", function(i)
    return " [" .. esc(string.format("sensor:%04X:0", i)) .. "] = { faktor = 2, versatz = 1, einheit = " .. esc("ABCDEFGHIJ")
      .. ", stellen = 1, name = " .. esc(string.rep("N", 30)) .. " },"
  end, " } }" },
  { "Grenzen (je 5 ungültige Felder, ohne Richtung)", "return { format = 1, grenzen = {", function(i)
    return " [" .. esc(string.format("sensor:%04X:0", i)) .. "] = { warnung = true, alarm = true, ansage = 1, vibration = 1, aus = 1 },"
  end, " } }" },
  { "Grenzen (gültig, vertauscht)", "return { format = 1, grenzen = {", function(i)
    return " [" .. esc(string.format("sensor:%04X:%d", i, i % 3)) .. "] = { richtung = " .. esc("ueber")
      .. ", warnung = 9, alarm = 1, ansage = false, vibration = true },"
  end, " } }" },
  { "Ansichten (2 x 16 Plätze, Titel, Zusatz, Farbe)", "return { format = 1, ansichten = {", function(i)
    if i > 3 then return " {}," end
    local t = { " { breite = " .. (i == 2 and 800 or 784) .. ", hoehe = " .. (i == 2 and 480 or 316) .. ", plaetze = {" }
    for k = 1, 17 do
      t[#t + 1] = " { x = 0, y = 0, b = 200, h = 100, w = " .. esc(k <= 3 and "lua:egt" or string.format("sensor:%04X:0", k))
        .. ", darstellung = " .. esc(k <= 3 and "kurve" or "zahl") .. ", titel = " .. esc(string.rep("T", 30))
        .. ", zusatz = " .. esc("max") .. ", kurveS = 60, farbe = { 1, 2, 3 } },"
    end
    t[#t + 1] = " } },"
    return table.concat(t)
  end, " } }" },
  { "Ansichten (1 x 16 Plätze, alle Felder)", "return { format = 1, ansichten = {", function(i)
    if i > 2 then return " {}," end                   -- nur 2 Ansichten zählen; der Rest wird verworfen
    local t = { " { breite = 784, hoehe = 316, plaetze = {" }
    for k = 1, 16 do
      t[#t + 1] = " { x = 0, y = 0, b = 200, h = 100, w = " .. esc(k <= 2 and "lua:egt" or string.format("sensor:%04X:0", k))
        .. ", darstellung = " .. esc(k <= 2 and "kurve" or "zahl") .. ", titel = " .. esc(string.rep("T", 30))
        .. ", min = 0, max = 100, zusatz = " .. esc("max") .. ", kurveS = 60, farbe = { 1, 2, 3 },"
        .. " stufen = { { ab = 1, farbe = { 1, 2, 3 } }, { ab = 2, farbe = { 4, 5, 6 } } } },"
    end
    t[#t + 1] = " } },"
    return table.concat(t)
  end, " } }" },
}
for _, fall in ipairs(faelle) do
  local n, byte = gross(fall[2], fall[3], fall[4])
  local Ji, ni = ganz()
  local wi = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
  local na, sa = 0, 0
  if Ji and Ji.zustand == "geladen" then na, sa = anwendenGemessen(wi, Ji) end
  pruefe(Ji and Ji.zustand == "geladen" and ni < 4000 and na < 4000, string.format("i) %s: %d Einträge, %d Byte, %s, %s Fehler; schritt höchstens %d (Stufe %s), anwenden höchstens %d Befehle (%d Schritte)",
    fall[1], n, byte, tostring(Ji and Ji.zustand), tostring(Ji and Ji.fehler), ni, tostring(grStufe), na, sa))
end
-- Grenzen in Studio-Datei und .funke.lua (Zusammenführen mit Werkgrenzen, Fehler im Menübereich)
do
  local function g(i, funke)
    local k = i <= 7 and ("lua:" .. ({ "egt", "kraftstoff_proz", "ecu_akku", "rx_akku", "empfang", "hoehe", "speed" })[i])
      or string.format("kanal:%d", i - 7)
    local r = ({ "ueber", "unter", "unter", "unter", "unter", "ueber", "ueber" })[i] or "ueber"
    if funke then return " [" .. esc(k) .. "] = { warnung = 5, aus = false }," end
    return " [" .. esc(k) .. "] = { richtung = " .. esc(r) .. ", warnung = 100000, alarm = 200000, ansage = true, vibration = true },"
  end
  local nf = gross("return { format = 1, grenzen = {", function(i) return g(i, true) end, " } }")
  kopiere(ziel, tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua")
  local n = gross("return { format = 1, grenzen = {", g, " } }")
  local Ji, ni = ganz()
  local wi = { cfg = F.standard(), v = {}, st = {}, dauer = {} }
  local na = anwendenGemessen(wi, Ji)
  pruefe(Ji.zustand == "geladen" and not Ji.funkeVerworfen and ni < 4000 and na < 4000, string.format("i) Grenzen Studio (%d) und .funke.lua (%d): schritt höchstens %d, anwenden höchstens %d Befehle", n, nf, ni, na))
  os_remove(tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua")
end
-- Grenze über dem Menübereich: Fehler, Werkgrenze (nicht still begrenzt)
do
  local Jb, wb = lade("return { format = 1, grenzen = { " .. lua("lua:egt") .. " = { warnung = 5000, alarm = 99999 } } }")
  pruefe(ist(wb.cfg, "egt", 720, 750) and Jb.fehler == 2 and wb.studio.fehler == 2, "i) Grenze über dem Menübereich: Werkgrenze 720/750, 2 Fehler (" .. wb.cfg.egtW .. "/" .. wb.cfg.egtA .. ", " .. Jb.fehler .. ")")
end

-- j) Quelle der Kategorie NONE (Ethos liefert für Unbekanntes eine leere Quelle): gilt als nicht gefunden.
-- Sensoren kommen aus der Liste getSources(Zahl); die Tabellenform liefert am Sender eine leere Liste (X18RS 20.11.2026).
do
  CATEGORY_NONE, CATEGORY_CHANNEL = 0, 3
  local function quelle(kat, id) return { value = function() return 1 end, category = function() return kat end,
    decimals = function() return 0 end, unit = function() return 0 end, appId = function() return id end,
    subId = function() return 0 end, physId = function() return 0x1B end } end
  local function liste(kat) return function(x) if type(x) == "table" then return {} end return { quelle(kat, 0x0A10) } end end
  local function alle(wq) for _ = 1, 20 do if ST.quellenSchritt(wq) then return end end end
  local alt = system
  system = { getSource = function() return quelle(0) end, getSources = liste(0) }
  local wq = { studio = { offen = { "sensor:0A10:0", "kanal:3" }, quellen = {} } }
  alle(wq)
  pruefe(wq.studio.quellen["sensor:0A10:0"] == false and wq.studio.quellen["kanal:3"] == false, "j) Sensor und Kanal mit Kategorie NONE: nicht gefunden")
  system = { getSource = function(t) return quelle(t.category) end, getSources = liste(CATEGORY_TELEMETRY_SENSOR) }
  wq = { studio = { offen = { "sensor:0A10:0", "kanal:3" }, quellen = {} } }
  alle(wq)
  pruefe(wq.studio.quellen["sensor:0A10:0"] and wq.studio.quellen["kanal:3"] and true or false, "j) echte Quellen über die Liste (Zahlform) übernommen")
  system.getSources = function() return {} end
  wq = { studio = { offen = { "sensor:0A10:0" }, quellen = {} } }
  alle(wq)
  pruefe(wq.studio.quellen["sensor:0A10:0"] == false, "j) Sensor nicht über getSource mit appId gesucht")
  -- 150 Sensoren in der Liste: Suche in Stücken, je Aufruf unter 1000 Befehlen
  local viele = {}
  for i = 1, 150 do viele[i] = quelle(CATEGORY_TELEMETRY_SENSOR, 0x0400 + i) end
  system = { getSource = function(t) return quelle(t.category) end,
    getSources = function(x) if type(x) == "table" then return {} end return viele end }
  wq = { studio = { offen = { "sensor:0496:0", "sensor:0A10:0" }, quellen = {} } }
  local maxB = 0
  for _ = 1, 40 do
    local n = 0
    debug.sethook(function() n = n + 1 end, "", 1)
    local fertig = ST.quellenSchritt(wq)
    debug.sethook()
    if n > maxB then maxB = n end
    if fertig then break end
  end
  pruefe(wq.studio.quellen["sensor:0496:0"] and wq.studio.quellen["sensor:0A10:0"] == false and maxB < 1000,
    "j) 150 Sensoren: gefunden/nicht gefunden richtig, höchstens " .. maxB .. " Befehle je Aufruf")
  system, CATEGORY_NONE = alt, nil
end

-- k) «auch bei Motor aus» (Lua-Studio-Format 2 §3.5): Schlüssel beiMotorAus je Grenze, fehlt = true, falscher Typ =
-- true plus Fehler, gilt auch für weitere Grenzen; .funke.lua zählt je Feld wie ansage (true hebt false auf)
do
  local f = "return { format = 2, grenzen = { " .. lua("lua:egt") .. " = { warnung = 720, alarm = 750, beiMotorAus = false }, "
    .. lua("lua:empfang") .. " = { warnung = 45, alarm = 40, beiMotorAus = " .. lua("x"):sub(2, -2) .. " }, "
    .. lua("kanal:1") .. " = { richtung = " .. lua("ueber"):sub(2, -2) .. ", alarm = 50, beiMotorAus = false } } }"
  local Jk, wk = lade(f)
  local c = wk.cfg
  pruefe(c.egtMA == false and c.rssiMA == true and c.kraftMA == true and ist(c, "egt", 720, 750) and Jk.fehler == 1,
    "k) beiMotorAus: EGT aus, falscher Typ = true mit 1 Fehler (" .. Jk.fehler .. "), fehlt = true, Grenzen unverändert")
  local x = wk.studio.extra[1]
  pruefe(x and x.key == "kanal:1" and x.e.beiMotorAus == false, "k) weitere Grenze kanal:1 trägt beiMotorAus = false")
  pruefe(ST.funkeAusCfg(wk, F) == nil, "k) ohne Änderung an der Funke keine .funke.lua")
  c.egtMA, c.kraftMA = true, false                          -- an der Funke: EGT wieder an, Kraftstoff aus
  local txt = ST.funkeAusCfg(wk, F)
  local fz = txt and load(txt, "=t", "t", {})()
  local ge, gk = fz and fz.grenzen["lua:egt"], fz and fz.grenzen["lua:kraftstoff_proz"]
  pruefe(ge and ge.beiMotorAus == true and ge.warnung == nil and gk and gk.beiMotorAus == false,
    "k) .funke.lua: EGT beiMotorAus = true (hebt false auf), Kraftstoff false, Grenzen nicht mitgeschrieben")
  pruefe(ST.funkeSchreiben("TEST", txt), "k) .funke.lua geschrieben")
  local _, wk2 = lade(f)
  pruefe(wk2.cfg.egtMA == true and wk2.cfg.kraftMA == false and ist(wk2.cfg, "egt", 720, 750) and ist(wk2.cfg, "kraft", 30, 20),
    "k) nach dem Neuladen: EGT an, Kraftstoff aus, Grenzen wie vorher")
  wk2.cfg.egtW = 700                                        -- Grenze und Haken zusammen geändert
  local fz2 = load(ST.funkeAusCfg(wk2, F), "=t", "t", {})()
  local g2 = fz2.grenzen["lua:egt"]
  pruefe(g2.warnung == 700 and g2.alarm == 750 and g2.beiMotorAus == true, "k) Grenze und Haken zusammen in einem Eintrag")
  os_remove(tmp .. "/SCRIPTS/studio/TEST.jet.funke.lua")
  local _, wk3 = lade("return { format = 1, grenzen = { " .. lua("lua:egt") .. " = { aus = true, beiMotorAus = false } } }")
  pruefe(wk3.cfg.egtMA == false and ist(wk3.cfg, "egt", 0, 0), "k) Format 1 kennt den Schlüssel auch, auch bei aus = true")
  -- Alarm-Sicherheit (Befund aus Heli, 21.11.): Eintrag ohne aktive Stufe gibt die Werkgrenze, still nur mit aus = true
  local _, wk4 = lade("return { format = 2, grenzen = { " .. lua("lua:egt") .. " = { beiMotorAus = false }, "
    .. lua("lua:kraftstoff_proz") .. " = { ansage = false } } }")
  pruefe(ist(wk4.cfg, "egt", 720, 750) and wk4.cfg.egtMA == false and ist(wk4.cfg, "kraft", 30, 20),
    "k) nur beiMotorAus bzw. nur ansage: Werkgrenzen EGT 720/750, Kraftstoff 30/20 (" .. wk4.cfg.egtW .. "/" .. wk4.cfg.egtA .. ")")
  local J5, wk5 = lade("return { format = 2, grenzen = { " .. lua("lua:egt") .. " = { warnung = false, alarm = false } } }")
  pruefe(ist(wk5.cfg, "egt", 720, 750) and J5.fehler == 1, "k) warnung = false und alarm = false ohne aus: Werkgrenze, 1 Hinweis (" .. J5.fehler .. ")")
  local _, wk6 = lade("return { format = 2, grenzen = { " .. lua("lua:egt") .. " = { warnung = false, alarm = 760 } } }")
  pruefe(ist(wk6.cfg, "egt", 0, 760), "k) nur Warnung aus: Alarm 760 bleibt")
  local _, wk7 = lade("return { format = 2, grenzen = { " .. lua("lua:status") .. " = { richtung = " .. lua("ueber"):sub(2, -2) .. ", alarm = 3, beiMotorAus = false } } }")
  local xs = wk7.studio.extra[1]
  pruefe(xs and xs.key == "lua:status" and xs.e.beiMotorAus == true, "k) Status (immerAlarm): beiMotorAus = false wird nicht beachtet")
end

-- Kennung byteweise
model.name = function() return "M\195\182we 1" end
pruefe(ST.kennung() == "M__we_1", "Kennung «Möwe 1» -> M__we_1")
model.name = function() return "" end
pruefe(ST.kennung() == "modell", "Kennung leer -> modell")

os.execute("rm -rf '" .. tmp .. "'")
print = print_
print(fehlerZahl == 0 and "ERGEBNIS: kein Fehler" or ("ERGEBNIS: " .. fehlerZahl .. " Fehler"))
os.exit(fehlerZahl == 0 and 0 or 1)
