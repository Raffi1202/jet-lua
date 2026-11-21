-- Jet: Statustexte der Turbinen-ECUs je Hersteller. Wird nur bei einem Statuswechsel geladen und gleich wieder
-- freigegeben. Aufruf: lade("status.lua")(tabelle, code, sp) -> text, gruppe, ansage
--   tabelle: 1 JetCat, 2 Xicoy, 3 Kingtech, 4 Swiwin, 5 PBS, 6 evoJet, 7 Hornet, 8 Jakadofsky
--   gruppe: 1 aus/bereit/abkühlen (grau), 2 Start/Test (blau), 3 läuft (grün), 4 Fehler/Abschaltgrund (rot)
--   ansage (nur Gruppe 4): 1 Flammabriss, 2 Kraftstoff leer, 3 Akku tief, 4 Übertemperatur, 5 Failsafe, sonst Störung
-- Unbekannter Code: nil (die Seite zeigt dann «Code n»).
-- Quellen (Konzept Fassung 2, 20.11.2026): JetCat aus dem VSpeak-Handbuch JetCat-Converter 1.7 S. 34 (für den
-- eigenen JetCat-Adapter abgeleitet); Xicoy aus dem Xicoy-Lua Tel5.lua; übrige aus den VSpeak-Handbüchern
-- (FrSky-Tabelle «Tmp2», Gruppen nach der Zuordnung zu den JetCat-Texten). Englisch = Originaltext der Quelle.
local T = {
  { -- 1 JetCat
    [0] = { "Aus", "OFF", 1 }, [1] = { "Auslaufen", "Slow Down", 1 }, [2] = { "Auto-Aus", "AutoOff", 1 },
    [3] = { "Warten auf Drehzahl", "Wait for RPM", 2 }, [4] = { "Vorheizen 1", "PreHeat1", 2 }, [5] = { "Vorheizen 2", "PreHeat2", 2 },
    [6] = { "Zündung", "Ignite", 2 }, [7] = { "Beschl. verzögert", "Accel. delay", 2 }, [8] = { "Hauptkraftst. Start", "MainFStrt", 2 },
    [9] = { "Kerosin voll", "Keros.FullOn", 2 }, [10] = { "Beschleunigen", "Accelerate", 2 }, [11] = { "Stabilisieren", "Stabilise", 2 },
    [12] = { "Leerlauf lernen", "Learn LO", 2 }, [13] = { "Läuft", "Run (reg.)", 3 }, [14] = { "Drehzahlregelung", "SpeedReg", 3 },
    [15] = { "Zweiwellen-Regelung", "Two-Shaft-Reg.", 3 },
    [-1] = { "Aus über Sender", "Shut down via RC", 1 }, [-2] = { "Auto-Aus", "Auto Off", 1 }, [-3] = { "Aus von Hand (GSU)", "Manual Off", 1 },
    [-4] = { "Beschl. Zeit über", "Accel. time out", 4 }, [-5] = { "Beschl. zu langsam", "Accel. too slow", 4 },
    [-6] = { "Überdrehzahl", "Over RPM", 4 }, [-7] = { "Drehzahl zu tief", "Low RPM Off", 4, 1 }, [-8] = { "Akku tief", "Low Battery", 4, 3 },
    [-9] = { "Übertemperatur", "Overtemperature", 4, 4 }, [-10] = { "Temperatur zu tief", "Low temp. Off", 4, 1 },
    [-11] = { "Temperatur zu hoch", "Hi Temp Off", 4, 4 }, [-12] = { "Glühkerze defekt", "Glow Plug defective", 4 },
    [-13] = { "Watchdog", "Watch Dog Timer", 4 }, [-14] = { "Failsafe-Abschaltung", "Fail Safe Off", 4, 5 },
    [-15] = { "Zündung Zeit über", "Ignition timeout", 4 }, [-16] = { "Stromausfall (Akku)", "Power fail", 4, 3 },
    [-17] = { "Temp.-Fühler defekt", "Temp Sensor fail", 4 }, [-18] = { "Kraftstofffehler", "Fuel fail", 4 },
    [-19] = { "Propellerfehler", "Prop fail", 4 }, [-20] = { "2. Turbine ausgef.", "2nd engine fail", 4 },
    [-21] = { "2. Turbine Abweichung", "2nd engine diff.", 4 }, [-22] = { "2. Turbine keine Verb.", "2nd engine no comm.", 4 },
    [-23] = { "Kein Öl", "No oil", 4 }, [-24] = { "Überstrom", "Over current", 4 }, [-25] = { "Keine Pumpe", "No fuel pump", 4 },
    [-26] = { "Falsche Pumpe", "Wrong fuel pump", 4 }, [-27] = { "Pumpe Verbindung", "Pump comm. error", 4 },
    [-28] = { "Kraftstoff leer", "Out of fuel", 4, 2 }, [-29] = { "Drehzahl tief (Pumpe?)", "Low RPM (pump?)", 4, 1 },
    [-30] = { "Drehzahl tief (Platine?)", "Low RPM (board?)", 4, 1 }, [-31] = { "Kupplung defekt", "Clutch fail", 4 },
    [-32] = { "ECU-Neustart", "ECU reboot", 4 },
  },
  { -- 2 Xicoy (Rohwert; 0 = kein Status)
    [0] = { "Kein Status", "No Status", 1 }, [1] = { "Trimmung tief", "Trim Low", 1 }, [2] = { "Leerlauf einstellen!", "SetIdle!", 1 },
    [3] = { "Bereit", "Ready", 1 }, [4] = { "Zündung", "Ignition", 2 }, [5] = { "Kraftstofframpe", "FuelRamp", 2 },
    [6] = { "Glühtest", "Glow Test", 2 }, [7] = { "Läuft", "Running", 3 }, [8] = { "Stopp", "Stop", 1 },
    [9] = { "Flammabriss", "FlameOut", 4, 1 }, [10] = { "Drehzahl tief", "SpeedLow", 4, 1 }, [11] = { "Abkühlen", "Cooling", 1 },
    [12] = { "Zünder defekt", "Ignitor Bad", 4 }, [13] = { "Starter defekt", "Starter Bad", 4 }, [14] = { "Gas schwach", "Weak Gas", 4 },
    [15] = { "Start ein", "Start On", 2 }, [16] = { "Aus (Pilot)", "User Off", 1 }, [17] = { "Failsafe", "Failsafe", 4, 5 },
    [18] = { "Drehzahl tief", "Low RPM", 4, 1 }, [19] = { "Reset", "Reset", 4 }, [20] = { "Empf.-Strom fehlt", "Rx PwFail", 4, 5 },
    [21] = { "Vorheizen", "Pre Heat", 2 }, [22] = { "Akku!", "Battery!", 4, 3 }, [23] = { "Zeit überschritten", "Time Out", 4 },
    [24] = { "Überlast", "Overload", 4 }, [25] = { "Zündfehler", "Ign.Fail", 4 }, [26] = { "Brenner ein", "BurnerOn", 2 },
    [27] = { "Startet", "Starting", 2 }, [28] = { "Umschalten", "SwitchOv", 2 }, [29] = { "Pumpe kalibrieren", "Cal.Pump", 2 },
    [30] = { "Pumpengrenze", "Pump Limit", 4 }, [31] = { "Keine Turbine", "NoEngine", 4 }, [32] = { "Leistungsschub", "PwrBoost", 3 },
    [33] = { "Läuft Leerlauf", "Run-Idle", 3 }, [34] = { "Läuft Vollgas", "Run-Max", 3 }, [35] = { "Neustart", "Restart", 2 },
  },
  { -- 3 Kingtech über VSpeak
    [22] = { "Neustart", "ReStart", 2 }, [20] = { "Läuft", "Running", 3 }, [14] = { "Stufe 3", "Stage3", 2 }, [13] = { "Stufe 2", "Stage2", 2 },
    [12] = { "Stufe 1", "Stage1", 2 }, [11] = { "Zündung", "Ignition", 2 }, [10] = { "Start ein", "Start On", 2 }, [9] = { "Brenner ein", "BurnerOn", 2 },
    [8] = { "Vorverdampfen", "PrimeVap", 2 }, [7] = { "Knüppel tief!", "StickLo!", 1 }, [6] = { "Glühtest", "GlowTest", 2 },
    [5] = { "Bereit (GD)", "GdReady", 1 }, [4] = { "Bereit", "Ready", 1 }, [3] = { "Abkühlen", "Cooling", 1 }, [2] = { "Stopp", "Stop", 1 },
    [1] = { "Aus (Pilot)", "User Off", 1 }, [0] = { "Trimmung tief", "Trim Low", 1 },
    [-1] = { "Glühkerze defekt", "Glow Bad", 4 }, [-2] = { "Zündfehler", "Ign.Fail", 4 }, [-3] = { "Zeit überschritten", "Time Out", 4 },
    [-4] = { "Gas schwach", "Weak Gas", 4 }, [-5] = { "Start fehlgeschlagen", "StartBad", 4 }, [-6] = { "Akku tief", "Low Batt", 4, 3 },
    [-7] = { "Überlast", "Overload", 4 }, [-8] = { "Empf.-Strom fehlt", "RxPwFail", 4, 5 }, [-9] = { "Failsafe", "Failsafe", 4, 5 },
    [-10] = { "Drehzahl tief", "SpeedLow", 4, 1 }, [-11] = { "Temperatur hoch", "TempHigh", 4, 4 }, [-12] = { "Flammabriss", "FlameOut", 4, 1 },
    [-13] = { "Kabel getrennt", "CAB-Lost", 4 }, [-19] = { "Unbekannt", "Unknown", 4 },
  },
  { -- 4 Swiwin über VSpeak
    [21] = { "Neustart", "Restart", 2 }, [20] = { "Läuft", "Running", 3 }, [13] = { "Kraftstofframpe", "Fuelramp", 2 },
    [12] = { "Vorheizen", "Preheat", 2 }, [11] = { "Zündung", "Ignition", 2 }, [10] = { "Bereit", "Ready", 1 },
    [9] = { "Test Starter", "TestStarter", 2 }, [8] = { "Test Pumpe", "TestPump", 2 }, [7] = { "Test Gasventil", "TestGasValve", 2 },
    [6] = { "Test Kraftst.-Ventil", "TestFuelValve", 2 }, [5] = { "Test Glühkerze", "TestGlowPlug", 2 }, [1] = { "Abkühlen", "Cooling", 1 },
    [0] = { "Stopp", "Stop", 1 },
    [-1] = { "Zeit überschritten", "Time Out", 4 }, [-2] = { "Akku tief", "Low Battery", 4, 3 }, [-3] = { "Glühkerze defekt", "GlowPlug Bad", 4 },
    [-4] = { "Pumpe gestört", "Pump Anomaly", 4 }, [-5] = { "Starter defekt", "Starter failure", 4 }, [-6] = { "Drehzahl tief", "RPM Low", 4, 1 },
    [-7] = { "Drehzahl unruhig", "RPM Instability", 4 }, [-8] = { "Temperatur hoch", "High Temp", 4, 4 }, [-9] = { "Temperatur tief", "Low Temp", 4, 1 },
    [-10] = { "Temp.-Fühler defekt", "TempSensorfail", 4 }, [-11] = { "Gasventil defekt", "Gas Valve Bad", 4 },
    [-12] = { "Kraftst.-Ventil defekt", "Fuel Valve Bad", 4 }, [-13] = { "Signal verloren", "Lost Signal", 4, 5 },
    [-14] = { "Startertemp. hoch", "StarterTemp High", 4 }, [-15] = { "Pumpentemp. hoch", "Pump Temp High", 4 },
    [-16] = { "Kupplung defekt", "Clutch failure", 4 }, [-17] = { "Überstrom", "Current overload", 4 },
    [-18] = { "Turbine nicht verb.", "Engine Offline", 4 }, [-30] = { "Keine Daten", "No data", 4 },
  },
  { -- 5 PBS über VSpeak
    [0] = { "Stopp", "STOP", 1 }, [10] = { "Bereit/Start", "Th:Idle", 2 }, [20] = { "Beschl. verzögert", "Th:-Rel", 2 },
    [25] = { "Vorheizen (Test)", "TEST", 2 }, [30] = { "Beschleunigen", "START", 2 }, [40] = { "Zündung", "FIRE", 2 },
    [70] = { "Läuft", "IDLE", 3 }, [-1] = { "Gesperrt", "LOCK", 1 }, [-10] = { "Abkühlen", "COOL", 1 }, [-30] = { "Fehler", "Error", 4 },
  },
  { -- 6 evoJet über VSpeak
    [0] = { "Stopp", "TH:stop", 1 }, [10] = { "Bereit/Start", "TH:run-", 2 }, [20] = { "Beschl. verzögert", "TH:rel-", 2 },
    [25] = { "Glühen", "TH:glow", 2 }, [30] = { "Andrehen", "TH:spin", 2 }, [40] = { "Zündung", "TH:fire", 2 }, [45] = { "Zünden", "TH:ignt", 2 },
    [50] = { "Aufheizen", "TH:heat", 2 }, [60] = { "Beschleunigen", "TH:acce", 2 }, [65] = { "Kalibrieren", "TH:cal.", 2 },
    [70] = { "Läuft", "TH:idle", 3 }, [-1] = { "Gesperrt", "TH:lock", 1 }, [-10] = { "Abkühlen", "TH:cool", 1 }, [-20] = { "Aus", "TH:-off", 1 },
    [-30] = { "Fehler", "Error", 4 },
  },
  { -- 7 ProJET Hornet über VSpeak (auch Behotec, Frank, BF, Jetitalia, Hammer laut Händler)
    [-30] = { "Gerät verzögert", "DEV.DELAY", 4 }, [-20] = { "Flammabriss", "FLAME OUT", 4, 1 }, [-10] = { "Notabschaltung", "EMERGENCY", 4 },
    [0] = { "Aus", "OFF", 1 }, [1] = { "Ein", "ON", 1 }, [10] = { "Abkühlen", "COOL-DOWN", 1 }, [20] = { "Auslaufen", "SLOW DOWN", 1 },
    [30] = { "Bereit", "STANDBY", 1 }, [31] = { "Propan-Zündung", "PROP IGNIT", 2 }, [32] = { "Propan heizt", "PROP-HEAT", 2 },
    [33] = { "Pumpe startet", "PUMPSTART", 2 }, [34] = { "Brenner ein", "BURNER ON", 2 }, [35] = { "Kraftstoff-Zündung", "FUELIGNIT", 2 },
    [36] = { "Kraftstoff heizt", "FUELHEAT", 2 }, [37] = { "Hochlauf verzögert", "RAMP DELAY", 2 }, [38] = { "Hochlauf", "RAMP-UP", 2 },
    [40] = { "Läuft stabil", "STEADY", 3 }, [41] = { "Leerlauf kalibr.", "CAL IDLE", 2 }, [42] = { "Kalibrieren", "CALIBRATE", 2 },
    [43] = { "Warten auf Gas", "WAIT ACC", 2 }, [44] = { "Zum Leerlauf", "GO IDLE", 2 }, [50] = { "Läuft (Auto)", "AUTO", 3 },
    [51] = { "Läuft (Auto HC)", "AUTO-HC", 3 },
  },
  { -- 8 Jakadofsky über VSpeak
    [0] = { "Stopp", "TH:stop", 1 }, [10] = { "Bereit/Start", "TH:run-", 2 }, [20] = { "Beschl. verzögert", "TH:rel-", 2 },
    [30] = { "Andrehen", "TH:spin", 2 }, [40] = { "Zündung", "TH:fire", 2 }, [50] = { "Aufheizen", "TH:heat", 2 },
    [60] = { "Beschleunigen", "TH:acce", 2 }, [70] = { "Läuft", "TH:idle", 3 }, [-1] = { "Gesperrt", "TH:lock", 1 },
    [-10] = { "Abkühlen", "TH:cool", 1 }, [-20] = { "Aus", "TH:-off", 1 }, [-30] = { "Fehler", "Error", 4 },
  },
}

return function(tabelle, code, sp)
  local t = T[tabelle]
  if t == nil or type(code) ~= "number" then return nil end
  local e = t[code]
  if e == nil then return nil end
  return e[sp == 2 and 2 or 1], e[3], e[4]
end
