# Home Assistant Export Script

Complete backup script for Home Assistant - exports devices, automations, and config with readable overviews

## Quick Start

```bash
# 1. Upload script to /homeassistant/export_ha.sh
# 2. Make executable and run
chmod +x /homeassistant/export_ha.sh && /homeassistant/export_ha.sh
```

**Before first run: Enter your token in the file!**

## Features

✅ **Externalized Automations**: Backs up `/homeassistant/automations/` recursively  
✅ **Complete Backup**: Registry, Config, States, Services  
✅ **Overviews**: README.md, YAML, TXT with all information  
✅ **ZIP Archive**: Automatically created with timestamp  
✅ **Multiple Backups**: Old backups are retained  

## What the Script Does

### 📥 Export Data
- Registry files (entities, devices, areas)
- API data (states, config, services)
- Configuration (automations.yaml, configuration.yaml, etc.)
- Externalized automations from `/homeassistant/automations/`

### 📝 Create Overviews
- `README.md` (readable documentation)
- `devices_overview.yaml` (structured data)
- `devices_list.txt` (compact list)
- `export_info.yaml` (metadata)

### 📦 Create ZIP Backup
- Format: `SystemName_YYYY-MM-DD_HH-MM-SS.zip`
- Contains ALL exported files
- Individual files are deleted (only ZIP remains)

## Tested With

✅ Home Assistant OS 16.2  
✅ Core 2025.10.4  
✅ Supervisor 2025.10.0  
✅ Frontend 20251001.4  

## Folder Structure

```
📂 /homeassistant/Info/
├── HomeAssistant_2025-11-03_14-30-45.zip ← Today
├── HomeAssistant_2025-11-02_03-00-12.zip ← Yesterday
└── HomeAssistant_2025-11-01_03-00-08.zip ← Day before yesterday
```

### ZIP Contents

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
├── automations/ ← Externalized automations
│   ├── living_room/
│   │   ├── lights.yaml
│   │   └── heating.yaml
│   └── kitchen/
│       └── exhaust_hood.yaml
├── README.md ⭐ START HERE
├── devices_overview.yaml ⭐ Structured
├── devices_list.txt ⭐ Compact
├── export_info.yaml
└── export_ha.sh ← The script itself
```

## Installation

### Short version:

```bash
# 1. Upload to /homeassistant/export_ha.sh
# 2. Enter token (nano /homeassistant/export_ha.sh)
# 3. Make executable and run
chmod +x /homeassistant/export_ha.sh && sed -i 's/\r$//' /homeassistant/export_ha.sh && /homeassistant/export_ha.sh
```

### Detailed Instructions:

1. **Upload the script** to your Home Assistant installation at `/homeassistant/export_ha.sh`
2. **Edit the script** and enter your long-lived access token
3. **Make it executable** and run it using the command above

## Configuration

Before running the script for the first time, you need to configure your Home Assistant access token:

1. Go to your Home Assistant profile settings
2. Create a long-lived access token
3. Edit the script and paste the token in the designated location
4. Save the file

## Usage

Run the script manually:

```bash
/homeassistant/export_ha.sh
```

Or set up an automation to run it automatically at regular intervals.

## Output Files

The script creates several overview files for easy reference:

- **README.md**: Human-readable documentation of your setup
- **devices_overview.yaml**: Structured overview of all devices
- **devices_list.txt**: Simple list format for quick reference
- **export_info.yaml**: Metadata about the export

## Notes

- The script preserves all previous backups
- ZIP files are named with timestamps for easy identification
- Individual files are automatically cleaned up after ZIP creation
- Supports nested automation folders
