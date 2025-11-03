# Home-Assistant-Export-Script 1.0.0

---

## ⚡ Quick Start (3 Schritte)

```bash
# 1. Script hochladen nach /homeassistant/export_ha.sh
# 2. Ausführbar machen und ausführen 
chmod +x /homeassistant/export_ha.sh && /homeassistant/export_ha.sh
```

**Vor dem ersten Start:** Token in der Datei eintragen!


## ✨ Hauptfeatures

✅ **Ausgelagerte Automations**: Sichert `/homeassistant/automations/` rekursiv  
✅ **Vollständiges Backup**: Registry, Config, States, Services  
✅ **Übersichten**: README.md, YAML, TXT mit allen Infos  
✅ **ZIP-Archiv**: Automatisch mit Zeitstempel  
✅ **Mehrfach-Backups**: Alte Backups werden behalten  

---

## 🚀 Was das Script macht

1. 📥 **Daten exportieren**
   - Registry-Dateien (entities, devices, areas)
   - API-Daten (states, config, services)
   - Konfiguration (automations.yaml, configuration.yaml, etc.)
   - Ausgelagerte Automations aus `/homeassistant/automations/`

2. 📝 **Übersichten erstellen**
   - README.md (lesbare Dokumentation)
   - devices_overview.yaml (strukturierte Daten)
   - devices_list.txt (kompakte Liste)
   - export_info.yaml (Metadaten)

3. 📦 **ZIP-Backup erstellen**
   - Format: `Anlagenname_YYYY-MM-DD_HH-MM-SS.zip`
   - Enthält ALLE exportierten Dateien
   - Einzeldateien werden gelöscht (nur ZIP bleibt)

---

## 📋 System-Kompatibilität

✅ **Getestet mit:**
- Home Assistant OS 16.2
- Core 2025.10.4
- Supervisor 2025.10.0
- Frontend 20251001.4

---

## 🎯 Typischer Output

```
📂 /homeassistant/Info/
├── HomeAssistant_2025-11-03_14-30-45.zip  ← Heute
├── HomeAssistant_2025-11-02_03-00-12.zip  ← Gestern
└── HomeAssistant_2025-11-01_03-00-08.zip  ← Vorgestern
```

**ZIP-Inhalt:**
```
📦 HomeAssistant_2025-11-03_14-30-45.zip
├── entity_registry.json
├── device_registry.json
├── area_registry.json
├── states.json
├── config.json
├── services.json
├── configuration.yaml
├── automations.yaml
├── scripts.yaml
├── scenes.yaml
├── automations/              ← Ausgelagerte Automations
│   ├── wohnzimmer/
│   │   ├── licht.yaml
│   │   └── heizung.yaml
│   └── kueche/
│       └── dunstabzug.yaml
├── README.md                 ⭐ START HIER
├── devices_overview.yaml     ⭐ Strukturiert
├── devices_list.txt          ⭐ Kompakt
├── export_info.yaml
└── export_ha.sh             ← Das Script selbst
```

---

## 💡 Installation

**Siehe [INSTALLATION.md](INSTALLATION.md) für Details!**

Kurz:
```bash
# 1. Upload nach /homeassistant/export_ha.sh
# 2. Token eintragen (nano /homeassistant/export_ha.sh)
# 3. Ausführbar machen und Ausführen
chmod +x /homeassistant/export_ha.sh && sed -i 's/\r$//' /homeassistant/export_ha.sh && /homeassistant/export_ha.sh
```
