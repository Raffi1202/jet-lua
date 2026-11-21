🇬🇧 English · [🇩🇪 Deutsch](../de/FAQ.md)

# FAQ

**Which turbines?** JetCat (own telemetry adapter, turbines 1–4), Xicoy (TeleX), SportECU and the VSpeak ECU converter (Kingtech, Swiwin, PBS, evoJet, Hornet/Behotec, Jakadofsky, JetCat). See [Setup](Setup.md).

**Has Jet been used with a real turbine?** No. It ran in the simulator and on one X18RS with simulated JetCat telemetry. During your first runs rely on the GSU or ECU display, not on Jet's alarms.

**Why does an alarm come although SF is off?** By default all alarms also come with the turbine switch off. You can change it per value in the menu group «Alarm also with turbine off». Error codes and shutdown reasons always come. See [Alarms](Alarms.md).

**The RPM is 10 or 100 times too small.** Menu › Manufacturer › **RPM times**.

**Do I need Lua-Studio?** No. Without a Studio file Jet shows its built-in display. See [Lua-Studio](Lua-Studio.md).

**Which radios?** All Ethos 26.2 radios with colour display; tested on a real radio only on the X18RS. See [Installation](Installation.md).

---
[← Home](../Home.md) | [Previous](Lua-Studio.md) | [Next →](Troubleshooting.md)
