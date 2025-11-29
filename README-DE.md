# Home-Assistant-Export-Script 1.1.0

---

## ⚡ Quick Start (3 Schritte)

```bash
# 1. Script hochladen nach /homeassistant/export_ha.sh
# 2. Token eintragen (nano /homeassistant/export_ha.sh) in Zeile 50
# 3. Ausführbar machen und ausführen (erstes Mal mit CRLF-Fix)
sed -i 's/\r$//' /homeassistant/export_ha.sh && chmod +x /homeassistant/export_ha.sh && /homeassistant/export_ha.sh
```

**Hinweis:** Der `sed`-Befehl korrigiert Windows-Zeilenumbrüche (CRLF → LF). Nur beim ersten Mal nötig. Danach reicht:
```bash
/homeassistant/export_ha.sh
```

---

## ✨ Hauptfeatures

✅ **Lovelace Dashboards**: Exportiert alle Dashboards (JSON + YAML) ⭐ NEU in 1.1.0  
✅ **Ausgelagerte Automations**: Sichert `/homeassistant/automations/` rekursiv  
✅ **Vollständiges Backup**: Registry, Config, States, Services  
✅ **Übersichten**: README.md, YAML, TXT mit allen Infos  
✅ **ZIP-Archiv**: Automatisch mit Zeitstempel  
✅ **Mehrfach-Backups**: Alte Backups werden behalten  

---

## 🚀 Was das Script macht

### 1. 📥 Daten exportieren
- Registry-Dateien (entities, devices, areas)
- API-Daten (states, config, services)
- Konfiguration (automations.yaml, configuration.yaml, etc.)
- Ausgelagerte Automations aus `/homeassistant/automations/`

### 2. 🖼️ Dashboards exportieren (NEU in 1.1.0)
- Haupt-Dashboard aus `.storage/lovelace`
- Alle zusätzlichen Dashboards aus `.storage/lovelace.*`
- Automatische Konvertierung zu YAML (besser lesbar)
- Lovelace Resources (Custom Cards, Themes, etc.)
- YAML-basierte Dashboards (`ui-lovelace.yaml`)
- Dashboard-Verzeichnisse (`/lovelace/`, `/dashboards/`)

### 3. 📝 Übersichten erstellen
- README.md (lesbare Dokumentation)
- devices_overview.yaml (strukturierte Daten)
- devices_list.txt (kompakte Liste)
- export_info.yaml (Metadaten)

### 4. 📦 ZIP-Backup erstellen
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
📂 /homeassistant/export/
├── HomeAssistant_2025-11-29_14-30-45.zip  ← Heute
├── HomeAssistant_2025-11-28_03-00-12.zip  ← Gestern
└── HomeAssistant_2025-11-27_03-00-08.zip  ← Vorgestern
```

**ZIP-Inhalt:**

```
📦 HomeAssistant_2025-11-29_14-30-45.zip
├── core.entity_registry.json
├── core.device_registry.json
├── core.area_registry.json
├── states.json
├── config.json
├── services.json
├── configuration.yaml
├── automations.yaml
├── scripts.yaml
├── scenes.yaml
├── automations/                    ← Ausgelagerte Automations
│   ├── wohnzimmer/
│   │   ├── licht.yaml
│   │   └── heizung.yaml
│   └── kueche/
│       └── dunstabzug.yaml
├── lovelace.json                   ← Haupt-Dashboard (JSON) ⭐ NEU
├── dashboard_lovelace.yaml         ← Haupt-Dashboard (YAML) ⭐ NEU
├── lovelace.dashboard_xyz.json     ← Weitere Dashboards ⭐ NEU
├── dashboard_dashboard_xyz.yaml    ← Weitere Dashboards ⭐ NEU
├── lovelace_resources.json         ← Custom Cards & Themes ⭐ NEU
├── README.md                       ⭐ START HIER
├── devices_overview.yaml           ⭐ Strukturiert
├── devices_list.txt                ⭐ Kompakt
└── export_info.yaml
```

---

## 💡 Installation

### Kurz:

```bash
# 1. Upload nach /homeassistant/export_ha.sh
# 2. Token eintragen (nano /homeassistant/export_ha.sh) in Zeile 50
# 3. Ausführbar machen und Ausführen
sed -i 's/\r$//' /homeassistant/export_ha.sh && chmod +x /homeassistant/export_ha.sh && /homeassistant/export_ha.sh
```

### Ausführlich:

1. **Script hochladen** nach `/homeassistant/export_ha.sh`
2. **Token eintragen** in Zeile 50 (Long-Lived Access Token)
3. **Ausführen** mit dem Befehl oben

---

## ⚙️ Konfiguration

Vor dem ersten Start muss der Home Assistant Access Token eingetragen werden:

1. Gehe zu: Einstellungen → Personen → [Dein Profil] → Sicherheit
2. Erstelle einen "Langlebigen Zugriffstoken"
3. Trage den Token in Zeile 50 des Scripts ein
4. Speichern

---

## 📂 Dashboard-Dateien (NEU in 1.1.0)

| Datei | Beschreibung |
|-------|--------------|
| `lovelace.json` | Haupt-Dashboard (Original JSON) |
| `dashboard_lovelace.yaml` | Haupt-Dashboard (konvertiertes YAML) |
| `lovelace.*.json` | Zusätzliche Dashboards (Original JSON) |
| `dashboard_*.yaml` | Zusätzliche Dashboards (konvertiertes YAML) |
| `lovelace_resources.json` | Custom Cards & Themes |

---

## 📜 Changelog

### Version 1.1.0 (2025-11-29)
- ✨ **NEU:** Lovelace Dashboard Export
  - Haupt-Dashboard + alle zusätzlichen Dashboards
  - JSON (Original) + YAML (lesbar) Format
  - Custom Cards & Resources
  - Unterstützung für YAML-basierte Konfiguration

### Version 1.0.0 (2025-11-03)
- 🎉 Erstes Release

---

## 📝 Hinweise

- Alle vorherigen Backups bleiben erhalten
- ZIP-Dateien sind mit Zeitstempel benannt
- Einzeldateien werden nach ZIP-Erstellung gelöscht
- Unterstützt verschachtelte Automation-Ordner
- Dashboards werden in JSON und YAML exportiert

---

## 📄 Lizenz

GNU GPL v3
