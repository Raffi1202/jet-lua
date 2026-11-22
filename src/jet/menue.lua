-- Jet: Einstellungen im Ethos-Menü (Modell › Bildschirme › Widget antippen, oder Widget lange drücken ›
-- Widget konfigurieren). Baut sich aus felder.lua: Gruppen als aufklappbare Felder, oben die Knöpfe für alles,
-- was sonst nur per Berührung geht (X14, X10 und X12 haben keine Berührung). Jede Löschung fragt nach.
return function(w, F, fertig, suche, aktion, K)
  local c = w.cfg
  local name = tostring(w.name)
  local sp, T = w.sp or 1, w.T or {}       -- Sprache beim Öffnen; ein Wechsel gilt im Menü ab dem nächsten Öffnen
  local function tx(t) return F.text(t, sp) end

  local function frage(titel, zeile, ja, id, arg)
    if not form.openDialog then return end
    pcall(form.openDialog, {
      title = titel, message = zeile,
      buttons = {     -- Ethos zeigt den letzten Knopf links und wählt ihn vor (gemessen 26.1.2): ABBRECHEN zuletzt
        { label = ja, action = function() pcall(aktion, id, arg) return true end },
        { label = T.abbrechen, action = function() return true end },
      },
    })
  end

  local kopf = form.addLine(T.mSuchen or "Sensoren suchen")
  if form.addButton then
    form.addButton(kopf, nil, { text = T.mKnopf or "Suchen", press = function()
      local ok, n = pcall(suche)
      if ok then
        print(name .. ": Suche " .. tostring(n))
      else
        print(name .. ": Fehler bei der Suche: " .. tostring(n))
        w.fehler = "Suche: " .. tostring(n)
      end
    end })
  end
  form.addStaticText(form.addLine(name), nil, "Version " .. tostring(w.version or ""))
  -- Studio-Datei: Zustand und «Zurück auf Studio-Stand» (mit Datei) bzw. «Zurück auf Standard» (ohne)
  local zs = w.studioZustand
  local zt = (zs == "geladen" and T.sGeladen) or (zs == "kaputt" and T.sKaputt) or (zs == "zuNeu" and T.sZuNeu) or T.sFehlt
  if zs == "geladen" and (w.studioFehler or 0) > 0 then zt = zt .. ", " .. string.format(T.studioFehler, tostring(w.studioFehler)) end
  local ls = form.addLine((T.mStudio or "Studio") .. ": " .. tostring(zt))
  if form.addButton then
    form.addButton(ls, nil, { text = T.mStudioK, press = function()
      if w.studio then frage(T.qStudio, T.qStudioZ, T.jaZurueck, "ja_studio")
      else frage(T.qStandard, T.qStandardZ, T.jaZurueck, "ja_standard") end
    end })
  end
  -- Studio-Layout: automatisch (Datei nach Modellnamen) oder eine Datei aus SCRIPTS:, SD: und RADIO: (Liste nur hier)
  local okL, ST = pcall(K.studioModul)
  local dateien = okL and ST and ST.liste() or {}
  -- «automatisch» zeigt in Klammern, was gerade gilt; Standard.jet.lua heisst «Standard (alle Modelle)»
  local gilt = w.studioWahlArt == "standard" and "Standard" or (T.mModellname or "Modellname")
  local wahlen, akt = { { string.format(T.mLayoutAuto or "automatisch (%s)", gilt), 0 } }, 0
  for i, d in ipairs(dateien) do
    local std = d[1]:match("[^/]*$") == "Standard.jet.lua"
    wahlen[#wahlen + 1] = { std and ((T.mLayoutStd or "Standard") .. " " .. (d[2]:match("%(%a+%)$") or "")) or d[2], i }
    if d[1] == w.studioWahl then akt = i end
  end
  if akt == 0 and type(w.studioWahl) == "string" and w.studioWahl ~= "" then   -- gewählt, aber nicht mehr da
    dateien[#dateien + 1] = { w.studioWahl, w.studioWahl:match("[^/]*$") .. " (?)" }
    akt = #dateien
    wahlen[#wahlen + 1] = { dateien[akt][2], akt }
  end
  form.addChoiceField(form.addLine(T.mLayout or "Studio-Layout"), nil, wahlen, function() return akt end, function(v)
    akt = v
    w.studioWahl = v > 0 and dateien[v] and dateien[v][1] or ""
    pcall(K.studioNeu, w)
  end)
  -- Erkannter bzw. gewählter Hersteller
  local h = K.hersteller(w)
  local ht = h and T.hersteller and T.hersteller[h] or T.mNichts
  if h == 4 and (c.vsEcu or 0) == 0 then ht = ht .. " - " .. tostring(T.herstellerWaehlen) end
  form.addStaticText(form.addLine(T.mErkannt), nil, tostring(ht))

  if form.addButton then
    form.addButton(form.addLine(T.mNeu), nil, { text = T.mNeuK, press = function()
      frage(T.qNeu, T.qNeuZ, T.jaNeu, "ja_neu")
    end })
    form.addButton(form.addLine(T.mEnde), nil, { text = T.mEndeK, press = function()
      frage(T.qEnde, T.qEndeZ, T.jaEnde, "ja_ende")
    end })
    -- gewählte Nummer bleibt gespeichert (Datei), damit sie nach dem Neustart gleich ist
    local function nr() local x = w.dauer.mnr return (type(x) == "number" and x >= 1 and x <= 99999) and math.floor(x) or 1 end
    form.addNumberField(form.addLine(T.mNr), nil, 1, 99999, nr, function(v)
      w.dauer.mnr = v
      fertig()
    end)
    form.addButton(form.addLine(T.mLoeschen), nil, { text = T.mLoeschenK, press = function()
      local n = nr()
      frage(string.format(T.qLoeschen, tostring(n)), T.qLoeschenZ, T.jaLoeschen, "ja_loeschen", n)
    end })
    form.addButton(form.addLine(T.mListe), nil, { text = T.mLoeschenK, press = function()
      frage(T.qListe, T.qListeZ, T.jaLoeschen, "ja_liste")
    end })
  end

  -- Zuordnung prüfen: je Sensorfeld Name, Physical ID und AppID, damit gleichnamige Sensoren unterscheidbar sind;
  -- nach einer Suche mit mehreren passenden Sensoren der Hinweis «n Sensoren passen».
  local pz = form.addExpansionPanel(T.mZuordnung or "Zuordnung")
  pcall(pz.open, pz, false)
  local function hx(x, stellen)
    if type(x) ~= "number" or x ~= x or x < 0 or x > 65535 then return "?" end
    return string.format("%0" .. stellen .. "X", math.floor(x))
  end
  local function info(q)
    if not F.istQuelle(q) then return T.mKeiner or "-" end
    local function r(f) local okf, v = pcall(q[f], q) if okf then return v end return nil end
    local nm, ph, id = r("name"), r("physId"), r("appId")
    local t = tostring(nm or "?")
    if type(id) == "number" then t = t .. "  P" .. hx(ph, 2) .. " / " .. hx(id, 4) end
    return t
  end
  for _, f in ipairs(F.gruppen[1][2]) do
    form.addStaticText(form.addLine(tx(f[3]), pz), nil, info(c[f[1]]))
    local hw = w.suchHinweis and w.suchHinweis[f[1]]
    if hw and T.mPasst then
      local gew = tostring(hw[2]) .. " P" .. hx(hw[3], 2) .. "/" .. tostring(hw[4])
      form.addStaticText(form.addLine("", pz), nil, string.format(T.mPasst, tostring(hw[1]), gew))
    end
  end

  for _, g in ipairs(F.gruppen) do
    local panel = form.addExpansionPanel(tx(g[1]))
    pcall(panel.open, panel, false)
    local gname = type(g[1]) == "table" and g[1][1] or g[1]
    if gname:sub(1, 5) == "Alarm" then             -- «auch bei Turbine aus»: Schalter «alle» und Hinweis oben
      form.addStaticText(form.addLine(T.mMaHinweis or "", panel), nil, "")
      form.addBooleanField(form.addLine(T.mMaAlle or "alle", panel), nil, function()
        for _, f in ipairs(g[2]) do if c[f[1]] == false then return false end end
        return true
      end, function(v)
        for _, f in ipairs(g[2]) do c[f[1]] = v and true or false end
        fertig()
      end)
    end
    for _, f in ipairs(g[2]) do
      local feld, art = f[1], f[2]
      local line = form.addLine(tx(f[3]), panel)
      local function get() return c[feld] end
      local function set(v)
        if art == "q" and not F.istQuelle(v) then v = nil end
        if art == "t" then v = F.eigen(v) or f[4] end
        if feld == "ecuArt" then                 -- Zellen-Schwellen auf dem Werkwert folgen der Akkuart
          local alt, neu = F.ECU_WERK[c.ecuArt] or F.ECU_WERK[1], F.ECU_WERK[v] or F.ECU_WERK[1]
          if c.ecuW == alt[1] and c.ecuA == alt[2] then c.ecuW, c.ecuA = neu[1], neu[2] end
        end
        c[feld] = v
        fertig()
      end
      if art == "q" then
        form.addSourceField(line, nil, get, set)
      elseif art == "b" then
        form.addBooleanField(line, nil, get, set)
      elseif art == "t" then
        if form.addTextField then form.addTextField(line, nil, get, set) end
      elseif art == "w" then
        local wahl = {}
        for i, a in ipairs(f[5]) do wahl[i] = { tx(a[1]), a[2] } end
        form.addChoiceField(line, nil, wahl, get, set)
      elseif art == "z" then
        local fe = form.addNumberField(line, nil, f[5], f[6], get, set)
        if fe then
          if f[7] and f[7] > 0 then pcall(fe.decimals, fe, f[7]) end
          if f[8] then pcall(fe.suffix, fe, f[8]) end
          if f[9] then pcall(fe.step, fe, f[9]) end
          pcall(fe.default, fe, f[4])
        end
      end
    end
  end
end
