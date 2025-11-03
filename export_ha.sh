#!/bin/bash
################################################################################
# Home Assistant Complete Export Script (Self-Fixing Version)
# Version: 1.0.0
# Für Home Assistant OS mit Advanced SSH & Web Terminal
# Repository: https://github.com/smarthomelily/Home-Assistant-Export-Script
# Lizenz: GNU GPL v3
################################################################################
# Anleitung
################################################################################
# 1. "Advanced SSH & Web Terminal" 
#     nano /homeassistant/export_ha.sh
#        Erstellen &  "strg+x" schließen und speichern 
# 2. "File editor" öffnen und Inhalt in die "export_ha.sh" einfügen inkl Token und speichern. 
#                "HIER_DEIN_TOKEN_EINFUEGEN" in Zeile 47 ersetzen
# 3. "Advanced SSH & Web Terminal" 
#    chmod +x /homeassistant/export_ha.sh && /homeassistant/export_ha.sh
################################################################################

# Script Version
VERSION="1.0.0"

################################################################################
# SELBST-KORREKTUR: Prüfe auf Windows-Zeilenumbrüche (CRLF)
################################################################################
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [ -f "$SCRIPT_PATH" ]; then
    # Prüfe ob CRLF vorhanden
    if file "$SCRIPT_PATH" 2>/dev/null | grep -q "CRLF"; then
        echo "WARNUNG: Windows-Zeilenumbrüche (CRLF) erkannt!"
        echo "Korrigiere zu Linux-Format (LF)..."
        sed -i 's/\r$//' "$SCRIPT_PATH" 2>/dev/null
        echo "Korrektur abgeschlossen!"
        echo "Starte Script neu..."
        echo ""
        exec "$SCRIPT_PATH" "$@"
        exit 0
    fi
fi

################################################################################
# ===== KONFIGURATION - NUR HIER TOKEN EINTRAGEN =====
################################################################################

TOKEN="HIER_DEIN_TOKEN_EINFUEGEN"

# Basis-Verzeichnisse
HA_CONFIG_DIR="/homeassistant"
EXPORT_BASE_DIR="$HA_CONFIG_DIR/export"
STORAGE_DIR="$HA_CONFIG_DIR/.storage"

# API-Endpunkt
HA_API="http://supervisor/core/api"

################################################################################
# Hilfs-Funktionen
################################################################################

# Farbige Ausgabe
print_success() { echo "[OK] $1"; }
print_error() { echo "[FEHLER] $1"; }
print_info() { echo "[INFO] $1"; }
print_warning() { echo "[WARNUNG] $1"; }

# Prüfe ob Kommando existiert
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "Kommando '$1' nicht gefunden!"
        return 1
    fi
    return 0
}

################################################################################
# Voraussetzungen prüfen
################################################################################

print_info "Prüfe Voraussetzungen..."

# Prüfe Token
if [ "$TOKEN" = "HIER_DEIN_TOKEN_EINFUEGEN" ]; then
    print_error "TOKEN noch nicht konfiguriert!"
    echo ""
    echo "Bitte in Zeile 32 den TOKEN eintragen:"
    echo "TOKEN=\"dein-langes-token-hier\""
    echo ""
    echo "Token erstellen unter:"
    echo "Einstellungen -> Personen -> [Dein Profil] -> Sicherheit -> Langlebige Zugriffstoken"
    exit 1
fi

# Prüfe ob curl vorhanden ist
if ! check_command curl; then
    print_error "curl ist nicht installiert!"
    exit 1
fi

# Prüfe ob Python verfügbar ist
if ! check_command python3; then
    print_error "Python3 ist nicht installiert!"
    exit 1
fi

# Prüfe ob PyYAML installiert ist
if ! python3 -c "import yaml" 2>/dev/null; then
    print_warning "PyYAML nicht installiert!"
    echo ""
    echo "Installation mit:"
    echo "pip install pyyaml --break-system-packages"
    echo ""
    read -p "Jetzt installieren? (j/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        pip install pyyaml --break-system-packages
        if [ $? -ne 0 ]; then
            print_error "Installation fehlgeschlagen!"
            exit 1
        fi
        print_success "PyYAML erfolgreich installiert!"
    else
        print_error "PyYAML wird benötigt!"
        exit 1
    fi
fi

################################################################################
# Export-Verzeichnis vorbereiten
################################################################################

# Zeitstempel für eindeutige Namen
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Hole Anlagennamen aus HA-Konfiguration
LOCATION_NAME=$(curl -s -X GET "$HA_API/config" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" 2>/dev/null | \
    python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('location_name', 'HomeAssistant'))" 2>/dev/null)

# Fallback falls API-Abfrage fehlschlägt
if [ -z "$LOCATION_NAME" ] || [ "$LOCATION_NAME" = "None" ]; then
    LOCATION_NAME="HomeAssistant"
fi

# Bereinige Anlagennamen (nur sichere Zeichen)
LOCATION_NAME=$(echo "$LOCATION_NAME" | sed 's/[^a-zA-Z0-9_-]/_/g')

# Export-Verzeichnis mit Zeitstempel
EXPORT_DIR="$EXPORT_BASE_DIR/${LOCATION_NAME}_$TIMESTAMP"
ZIP_NAME="${LOCATION_NAME}_${TIMESTAMP}.zip"

print_info "Erstelle Export-Verzeichnis: $EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

################################################################################
# 1. Registry-Dateien exportieren
################################################################################

print_info "Exportiere Registry-Dateien..."

REGISTRY_FILES=(
    "core.entity_registry"
    "core.device_registry"
    "core.area_registry"
)

for file in "${REGISTRY_FILES[@]}"; do
    if [ -f "$STORAGE_DIR/$file" ]; then
        cp "$STORAGE_DIR/$file" "$EXPORT_DIR/${file}.json"
        print_success "Kopiert: $file"
    else
        print_warning "Nicht gefunden: $file"
    fi
done

################################################################################
# 2. API-Daten exportieren
################################################################################

print_info "Exportiere API-Daten..."

# States (alle aktuellen Zustände)
curl -s -X GET "$HA_API/states" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    > "$EXPORT_DIR/states.json"
print_success "API States exportiert"

# Config (HA-Konfiguration)
curl -s -X GET "$HA_API/config" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    > "$EXPORT_DIR/config.json"
print_success "API Config exportiert"

# Services (verfügbare Dienste)
curl -s -X GET "$HA_API/services" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    > "$EXPORT_DIR/services.json"
print_success "API Services exportiert"

################################################################################
# 3. Konfigurationsdateien kopieren
################################################################################

print_info "Exportiere Konfigurationsdateien..."

CONFIG_FILES=(
    "configuration.yaml"
    "automations.yaml"
    "scripts.yaml"
    "scenes.yaml"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$HA_CONFIG_DIR/$file" ]; then
        cp "$HA_CONFIG_DIR/$file" "$EXPORT_DIR/"
        print_success "Kopiert: $file"
    else
        print_warning "Nicht gefunden: $file"
    fi
done

################################################################################
# 3.1. Ausgelagerte Automations kopieren (rekursiv)
################################################################################

AUTOMATIONS_DIR="$HA_CONFIG_DIR/automations"
if [ -d "$AUTOMATIONS_DIR" ]; then
    print_info "Exportiere ausgelagerte Automations aus $AUTOMATIONS_DIR..."
    
    # Erstelle Zielverzeichnis
    mkdir -p "$EXPORT_DIR/automations"
    
    # Kopiere alle YAML-Dateien rekursiv
    find "$AUTOMATIONS_DIR" -type f -name "*.yaml" -o -name "*.yml" | while read -r file; do
        # Relativer Pfad zum automations Verzeichnis
        rel_path="${file#$AUTOMATIONS_DIR/}"
        target_dir="$EXPORT_DIR/automations/$(dirname "$rel_path")"
        
        # Erstelle Zielverzeichnis falls nötig
        mkdir -p "$target_dir"
        
        # Kopiere Datei
        cp "$file" "$target_dir/"
        print_success "Kopiert: automations/$rel_path"
    done
    
    # Zähle Dateien
    yaml_count=$(find "$AUTOMATIONS_DIR" -type f \( -name "*.yaml" -o -name "*.yml" \) | wc -l)
    print_success "Insgesamt $yaml_count Automation-Dateien exportiert"
else
    print_info "Kein automations/ Verzeichnis gefunden - überspringe"
fi

################################################################################
# 4. Übersichten erstellen (Python)
################################################################################

print_info "Erstelle Übersichten..."

# Python-Script inline für Übersicht
python3 << 'PYTHON_SCRIPT'
import json
import yaml
from datetime import datetime
from collections import defaultdict

# Lade Registry-Daten
with open('core.entity_registry.json', 'r', encoding='utf-8') as f:
    entities = json.load(f)['data']['entities']

with open('core.device_registry.json', 'r', encoding='utf-8') as f:
    devices = json.load(f)['data']['devices']

with open('core.area_registry.json', 'r', encoding='utf-8') as f:
    areas = json.load(f)['data']['areas']

# Area-Mapping erstellen
area_map = {area['id']: area['name'] for area in areas}

# Device-Mapping erstellen
device_map = {device['id']: device for device in devices}

# Gruppiere Entities nach Area
entities_by_area = defaultdict(lambda: defaultdict(list))

for entity in entities:
    device_id = entity.get('device_id')
    
    # Bestimme Area
    if device_id and device_id in device_map:
        device = device_map[device_id]
        area_id = device.get('area_id')
        area_name = area_map.get(area_id, 'Kein Raum')
    else:
        area_name = 'Kein Gerät'
    
    # Bestimme Domain (z.B. light, switch, sensor)
    entity_id = entity.get('entity_id', '')
    domain = entity_id.split('.')[0] if '.' in entity_id else 'unknown'
    
    entities_by_area[area_name][domain].append({
        'entity_id': entity_id,
        'name': entity.get('original_name', entity_id),
        'platform': entity.get('platform', 'unknown')
    })

# 1. devices_overview.yaml - Strukturierte YAML-Datei
overview = {
    'export_info': {
        'timestamp': datetime.now().isoformat(),
        'total_areas': len(areas),
        'total_devices': len(devices),
        'total_entities': len(entities)
    },
    'areas': {}
}

for area_name in sorted(entities_by_area.keys()):
    overview['areas'][area_name] = {}
    for domain in sorted(entities_by_area[area_name].keys()):
        overview['areas'][area_name][domain] = entities_by_area[area_name][domain]

with open('devices_overview.yaml', 'w', encoding='utf-8') as f:
    yaml.dump(overview, f, allow_unicode=True, default_flow_style=False, sort_keys=False)

# 2. README.md - Lesbare Markdown-Datei
with open('README.md', 'w', encoding='utf-8') as f:
    f.write('# Home Assistant Device Export\n\n')
    f.write(f'**Export-Zeitpunkt:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n\n')
    f.write(f'**Statistik:**\n')
    f.write(f'- Räume: {len(areas)}\n')
    f.write(f'- Geräte: {len(devices)}\n')
    f.write(f'- Entities: {len(entities)}\n\n')
    f.write('---\n\n')
    
    # Gruppiert nach Räumen
    for area_name in sorted(entities_by_area.keys()):
        f.write(f'## {area_name}\n\n')
        for domain in sorted(entities_by_area[area_name].keys()):
            domain_entities = entities_by_area[area_name][domain]
            f.write(f'### {domain.capitalize()} ({len(domain_entities)})\n\n')
            for entity in domain_entities:
                f.write(f'- **{entity["name"]}** (`{entity["entity_id"]}`)\n')
                f.write(f'  - Platform: {entity["platform"]}\n')
            f.write('\n')

# 3. devices_list.txt - Kompakte Textliste
with open('devices_list.txt', 'w', encoding='utf-8') as f:
    f.write('HOME ASSISTANT DEVICE EXPORT\n')
    f.write('='*60 + '\n')
    f.write(f'Export: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
    f.write(f'Räume: {len(areas)} | Geräte: {len(devices)} | Entities: {len(entities)}\n')
    f.write('='*60 + '\n\n')
    
    for area_name in sorted(entities_by_area.keys()):
        f.write(f'\n[{area_name}]\n')
        f.write('-'*60 + '\n')
        for domain in sorted(entities_by_area[area_name].keys()):
            f.write(f'  {domain}:\n')
            for entity in entities_by_area[area_name][domain]:
                f.write(f'    - {entity["entity_id"]}\n')

# 4. export_info.yaml - Metadaten
export_info = {
    'export_timestamp': datetime.now().isoformat(),
    'script_version': '1.0.0',
    'statistics': {
        'areas': len(areas),
        'devices': len(devices),
        'entities': len(entities),
        'entities_by_domain': {}
    },
    'files_exported': [
        'core.entity_registry.json',
        'core.device_registry.json',
        'core.area_registry.json',
        'states.json',
        'config.json',
        'services.json',
        'devices_overview.yaml',
        'README.md',
        'devices_list.txt'
    ]
}

# Zähle Entities nach Domain
domain_counts = defaultdict(int)
for entity in entities:
    entity_id = entity.get('entity_id', '')
    domain = entity_id.split('.')[0] if '.' in entity_id else 'unknown'
    domain_counts[domain] += 1

export_info['statistics']['entities_by_domain'] = dict(sorted(domain_counts.items()))

with open('export_info.yaml', 'w', encoding='utf-8') as f:
    yaml.dump(export_info, f, allow_unicode=True, default_flow_style=False)

print("Übersichten erfolgreich erstellt!")
PYTHON_SCRIPT

# Wechsle ins Export-Verzeichnis für Python-Ausführung
cd "$EXPORT_DIR" || exit 1
python3 << 'PYTHON_SCRIPT'
import json
import yaml
from datetime import datetime
from collections import defaultdict

# Lade Registry-Daten
with open('core.entity_registry.json', 'r', encoding='utf-8') as f:
    entities = json.load(f)['data']['entities']

with open('core.device_registry.json', 'r', encoding='utf-8') as f:
    devices = json.load(f)['data']['devices']

with open('core.area_registry.json', 'r', encoding='utf-8') as f:
    areas = json.load(f)['data']['areas']

# Area-Mapping erstellen
area_map = {area['id']: area['name'] for area in areas}

# Device-Mapping erstellen
device_map = {device['id']: device for device in devices}

# Gruppiere Entities nach Area
entities_by_area = defaultdict(lambda: defaultdict(list))

for entity in entities:
    device_id = entity.get('device_id')
    
    # Bestimme Area
    if device_id and device_id in device_map:
        device = device_map[device_id]
        area_id = device.get('area_id')
        area_name = area_map.get(area_id, 'Kein Raum')
    else:
        area_name = 'Kein Gerät'
    
    # Bestimme Domain
    entity_id = entity.get('entity_id', '')
    domain = entity_id.split('.')[0] if '.' in entity_id else 'unknown'
    
    entities_by_area[area_name][domain].append({
        'entity_id': entity_id,
        'name': entity.get('original_name', entity_id),
        'platform': entity.get('platform', 'unknown')
    })

# 1. devices_overview.yaml
overview = {
    'export_info': {
        'timestamp': datetime.now().isoformat(),
        'total_areas': len(areas),
        'total_devices': len(devices),
        'total_entities': len(entities)
    },
    'areas': {}
}

for area_name in sorted(entities_by_area.keys()):
    overview['areas'][area_name] = {}
    for domain in sorted(entities_by_area[area_name].keys()):
        overview['areas'][area_name][domain] = entities_by_area[area_name][domain]

with open('devices_overview.yaml', 'w', encoding='utf-8') as f:
    yaml.dump(overview, f, allow_unicode=True, default_flow_style=False, sort_keys=False)

# 2. README.md
with open('README.md', 'w', encoding='utf-8') as f:
    f.write('# Home Assistant Device Export\n\n')
    f.write(f'**Export-Zeitpunkt:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n\n')
    f.write(f'**Statistik:**\n')
    f.write(f'- Räume: {len(areas)}\n')
    f.write(f'- Geräte: {len(devices)}\n')
    f.write(f'- Entities: {len(entities)}\n\n')
    f.write('---\n\n')
    
    for area_name in sorted(entities_by_area.keys()):
        f.write(f'## {area_name}\n\n')
        for domain in sorted(entities_by_area[area_name].keys()):
            domain_entities = entities_by_area[area_name][domain]
            f.write(f'### {domain.capitalize()} ({len(domain_entities)})\n\n')
            for entity in domain_entities:
                f.write(f'- **{entity["name"]}** (`{entity["entity_id"]}`)\n')
                f.write(f'  - Platform: {entity["platform"]}\n')
            f.write('\n')

# 3. devices_list.txt
with open('devices_list.txt', 'w', encoding='utf-8') as f:
    f.write('HOME ASSISTANT DEVICE EXPORT\n')
    f.write('='*60 + '\n')
    f.write(f'Export: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
    f.write(f'Räume: {len(areas)} | Geräte: {len(devices)} | Entities: {len(entities)}\n')
    f.write('='*60 + '\n\n')
    
    for area_name in sorted(entities_by_area.keys()):
        f.write(f'\n[{area_name}]\n')
        f.write('-'*60 + '\n')
        for domain in sorted(entities_by_area[area_name].keys()):
            f.write(f'  {domain}:\n')
            for entity in entities_by_area[area_name][domain]:
                f.write(f'    - {entity["entity_id"]}\n')

# 4. export_info.yaml
domain_counts = defaultdict(int)
for entity in entities:
    entity_id = entity.get('entity_id', '')
    domain = entity_id.split('.')[0] if '.' in entity_id else 'unknown'
    domain_counts[domain] += 1

export_info = {
    'export_timestamp': datetime.now().isoformat(),
    'script_version': '1.0.0',
    'statistics': {
        'areas': len(areas),
        'devices': len(devices),
        'entities': len(entities),
        'entities_by_domain': dict(sorted(domain_counts.items()))
    }
}

with open('export_info.yaml', 'w', encoding='utf-8') as f:
    yaml.dump(export_info, f, allow_unicode=True, default_flow_style=False)
PYTHON_SCRIPT

print_success "Übersichten erstellt!"
cd - > /dev/null

################################################################################
# 5. ZIP-Archiv erstellen
################################################################################

print_info "Erstelle ZIP-Archiv..."

cd "$EXPORT_BASE_DIR" || exit 1
zip -r -q "$ZIP_NAME" "$(basename "$EXPORT_DIR")"

if [ -f "$ZIP_NAME" ]; then
    ZIP_SIZE=$(du -h "$ZIP_NAME" | cut -f1)
    print_success "ZIP erstellt: $ZIP_NAME ($ZIP_SIZE)"
else
    print_error "ZIP konnte nicht erstellt werden!"
    exit 1
fi

################################################################################
# 6. Aufräumen
################################################################################

print_info "Räume temporäre Dateien auf..."
rm -rf "$EXPORT_DIR"
print_success "Temporäre Dateien gelöscht"

################################################################################
# Abschluss
################################################################################

echo ""
echo "=========================================="
echo "Export erfolgreich abgeschlossen!"
echo "=========================================="
echo "Datei: $EXPORT_BASE_DIR/$ZIP_NAME"
echo "Größe: $ZIP_SIZE"
echo ""
echo "Du findest die Datei hier:"
echo "- File Editor: /homeassistant/export/$ZIP_NAME"
echo "- Samba: \\\\homeassistant\\config\\export\\$ZIP_NAME"
echo ""

exit 0
