-- Jet: alle Texte der Anzeige in zwei Sprachen. Jeder Text steht genau einmal hier: { deutsch, englisch }.
-- Der Kern holt sich nur die Texte der gewählten Sprache (1 = Deutsch, 2 = English) und gibt den Rest wieder frei.
-- Texte des Menüs stehen bei den Einstellungen in felder.lua, Statustexte der ECUs in status.lua.
-- Meldungen im Protokoll (print) bleiben deutsch.
local TEXT = {
  -- Turbinen-Pille
  pAus = { "AUS", "OFF" }, pStart = { "START", "START" }, pLaeuft = { "LÄUFT", "RUNNING" }, pAbsch = { "ABSCHALTUNG", "SHUTDOWN" },
  -- Titel der Tachos und Felder (lang, kurz für 480 x 320 und kompakt)
  t1 = { "DREHZAHL", "RPM" }, t2 = { "EGT", "EGT" }, t3 = { "KRAFTSTOFF", "FUEL" }, t3k = { "KRAFTST.", "FUEL" },
  t4 = { "ECU-AKKU", "ECU BATT" }, t5 = { "STATUS", "STATUS" }, t6 = { "FLUSS", "FLOW" }, t7 = { "PUMPE", "PUMP" },
  t8 = { "SCHUB", "THRUST" }, t9 = { "HÖHE", "ALTITUDE" }, t10 = { "SPEED", "SPEED" }, t11 = { "EMPFANG", "SIGNAL" },
  t12 = { "GAS", "THROTTLE" }, t13 = { "WELLE", "SHAFT" }, t14 = { "ECU-STROM", "ECU CURR." }, t15 = { "LAUFZEIT", "RUN TIME" },
  t16 = { "KRAFTSTOFF ML", "FUEL ML" }, t17 = { "RX-AKKU", "RX BATT" },
  umin = { "U/MIN", "RPM" }, volt = { "VOLT", "VOLT" },
  soll = { "SOLL", "SET" }, hoechst = { "HÖCHST", "MAX" }, tiefst = { "TIEFST", "MIN" },
  verbr = { "%s ml verbr.", "%s ml used" }, seit = { "seit %s", "since %s" }, code = { "Code %s", "Code %s" },
  turbineAus = { "Turbine aus %s", "Turbine off %s" }, absch = { "Abschaltung %s", "Shutdown %s" },
  laeufe = { "%s Läufe", "%s runs" }, lauf1 = { "1 Lauf", "1 run" },
  tankEinst = { "Tankgrösse einstellen", "Set tank size" }, ausMl = { "aus ml", "from ml" },
  hersteller = { "JetCat", "Xicoy", "SportECU", "VSpeak", "von Hand" },
  herstellerEn = { "JetCat", "Xicoy", "SportECU", "VSpeak", "manual" },
  -- Seite 2 (Turbinen)
  turbine = { "TURBINE %s", "TURBINE %s" },
  -- Statusliste (Feld STATUS antippen)
  statusListe = { "LETZTE STATUSWECHSEL", "LAST STATUS CHANGES" }, keineWechsel = { "Noch keine Wechsel", "No changes yet" },
  schliessen = { "SCHLIESSEN", "CLOSE" },
  -- Seite 3 (Flugliste)
  lauf = { "LAUF %s", "RUN %s" }, laufListe = { "LÄUFE", "RUNS" }, fertig = { "%s fertig", "%s done" },
  laeuft = { "läuft", "running" },
  nr = { "Nr", "No" }, dauer = { "Zeit", "Time" }, ende = { "Ende", "End" },
  dLaufzeit = { "Laufzeit", "Run time" }, dVerbraucht = { "Verbraucht", "Fuel used" }, dEgt = { "Höchst-EGT", "Max. EGT" },
  dRpm = { "Höchst-Drehzahl", "Max. RPM" }, dKraftstoff = { "Kraftstoff am Ende", "Fuel at end" }, dHoehe = { "Höchste Höhe", "Max. altitude" },
  dSpeed = { "Höchst-Speed", "Max. speed" }, dEcu = { "Tiefster ECU-Akku", "Lowest ECU batt" }, dEnde = { "Ende", "End" },
  dTurbinen = { "Turbinen", "Turbines" },
  eSf = { "SF aus", "SF off" }, eNormal = { "normal", "normal" }, eAbsch = { "Abschaltung", "Shutdown" },
  keineLaeufe = { "Noch keine Läufe", "No runs yet" }, antippen = { "Lauf in der Liste antippen", "Tap a run in the list" },
  zurueck = { "< ZURÜCK", "< BACK" }, laufLoeschen = { "LAUF %s LÖSCHEN", "DELETE RUN %s" },
  laufLoeschen0 = { "LAUF LÖSCHEN", "DELETE RUN" }, listeLoeschen = { "LISTE LÖSCHEN", "CLEAR LIST" },
  -- Hinweise (%s = Anzahl)
  autoSuche = { "%s Sensoren automatisch zugewiesen", "%s sensors assigned automatically" },
  neuSuche = { "%s Sensoren neu zugewiesen", "%s sensors newly assigned" },
  geloescht = { "Lauf %s gelöscht", "Run %s deleted" }, listeWeg = { "Flugliste gelöscht", "Run list cleared" },
  laufBeendet = { "Lauf beendet", "Run ended" },
  -- Rückfragen
  qLoeschen = { "Lauf %s löschen?", "Delete run %s?" }, qLoeschenZ = { "Die Nummern danach rücken nach.", "The following numbers move up." },
  qListe = { "Alle Läufe löschen?", "Delete all runs?" }, qListeZ = { "Der Zähler beginnt wieder bei 1.", "The counter starts again at 1." },
  jaLoeschen = { "JA, LÖSCHEN", "YES, DELETE" },
  qEnde = { "Lauf beenden?", "End run?" }, qEndeZ = { "Er kommt in die Flugliste.", "It goes into the run list." },
  jaEnde = { "JA, BEENDEN", "YES, END" },
  abbrechen = { "ABBRECHEN", "CANCEL" },
  herstellerWaehlen = { "Hersteller wählen", "Select manufacturer" },
  -- Menü (Kopf)
  mSuchen = { "Sensoren suchen (nur leere)", "Find sensors (empty only)" },
  mKnopf = { "Suchen", "Search" },
  mErkannt = { "Erkannt", "Detected" }, mNichts = { "noch nichts", "nothing yet" },
  mNeu = { "Turbinenwerte neu zuordnen", "Reassign turbine values" }, mNeuK = { "Neu", "Reassign" },
  qNeu = { "Turbinenwerte neu zuordnen?", "Reassign turbine values?" },
  qNeuZ = { "Sensoren nicht auf ID 0x1B werden ersetzt.", "Sensors not on ID 0x1B are replaced." },
  jaNeu = { "JA, NEU", "YES, REASSIGN" },
  mEnde = { "Lauf beenden", "End run" }, mEndeK = { "Beenden", "End" },
  mNr = { "Lauf Nr. zum Löschen", "Run no. to delete" }, mLoeschen = { "Lauf löschen", "Delete run" },
  mLoeschenK = { "Löschen", "Delete" }, mListe = { "Ganze Liste löschen", "Delete whole list" },
  mZuordnung = { "Zuordnung prüfen", "Check assignment" },
  mPasst = { "%s Sensoren passen, gewählt: %s - bitte prüfen", "%s sensors match, chosen: %s - please check" },
  mKeiner = { "kein Sensor", "no sensor" },
  -- Studio-Datei (Lua-Studio-Format v1)
  studioKaputt = { "Studio-Datei kaputt - Standard", "Studio file broken - default" },
  studioZuNeu = { "Studio-Datei zu neu - Lua aktualisieren", "Studio file too new - update the Lua" },
  studioFehler = { "Studio-Datei: %s Fehler", "Studio file: %s errors" },
  symFehlen = { "Studio: %s Symbole fehlen", "Studio: %s symbols missing" },
  funkeVerworfen = { "Änderungen an der Funke verworfen", "Changes on the radio discarded" },
  funkeNicht = { "Änderung nicht gespeichert", "Change not saved" },
  studioZurueck = { "Zurück auf Studio-Stand", "Back to Studio settings" },
  standardZurueck = { "Zurück auf Standard", "Back to defaults" },
  mStudio = { "Studio-Datei", "Studio file" },
  sFehlt = { "keine", "none" }, sGeladen = { "geladen", "loaded" }, sKaputt = { "kaputt", "broken" },
  sZuNeu = { "zu neu", "too new" },
  mStudioK = { "Zurück", "Reset" },
  qStudio = { "Zurück auf Studio-Stand?", "Back to Studio settings?" },
  qStudioZ = { "Deine Änderungen an der Funke werden gelöscht.", "Your changes on the radio are deleted." },
  qStandard = { "Zurück auf Standard?", "Back to defaults?" },
  qStandardZ = { "Einstellungen und Grenzwerte ab Werk; Sensoren und Läufe bleiben.", "Factory settings and limits; sensors and runs stay." },
  jaZurueck = { "JA, ZURÜCK", "YES, RESET" },
  -- «Alarm auch bei Turbine aus» (Lua-Studio-Format 2 §3.5)
  mMaHinweis = { "Ohne Haken: still, solange Turbine aus", "Unticked: silent while turbine off" },
  mMaAlle = { "alle", "all" },
  -- Rahmen der ECU und zugewiesener Sensor zeigen verschiedene Werte (Entscheid des Users 21.11.2026)
  widerspruch = { "%s: ECU-Daten und Sensor weichen ab", "%s: ECU data and sensor disagree" },
  wName = { egt = "EGT", rpm = "Drehzahl", ecu = "ECU-Akku", proz = "Kraftstoff" },
  wNameEn = { egt = "EGT", rpm = "RPM", ecu = "ECU battery", proz = "Fuel" },
}

return function(sp)
  local t = {}
  for k, p in pairs(TEXT) do
    if k == "hersteller" or k == "wName" then
      t[k] = sp == 2 and TEXT[k .. "En"] or p
    elseif k ~= "herstellerEn" and k ~= "wNameEn" then
      t[k] = p[sp] or p[1]
    end
  end
  return t
end
