#!/bin/bash
################################################################################
# Home Assistant Complete Export Script (Self-Fixing Version)
# Version: 1.0.0
# For Home Assistant OS with Advanced SSH & Web Terminal
# Repository: https://github.com/smarthomelily/Home-Assistant-Export-Script
# License: GNU GPL v3
################################################################################
# Instructions
################################################################################
# 1. Open "Advanced SSH & Web Terminal"
#     nano /homeassistant/export_ha.sh
#        Create file & close with "Ctrl+X" and save
# 2. Open "File editor" and paste content into "export_ha.sh" including token and save.
#                Replace "INSERT_YOUR_TOKEN_HERE" in line 47
# 3. Open "Advanced SSH & Web Terminal"
#    chmod +x /homeassistant/export_ha.sh && /homeassistant/export_ha.sh
################################################################################

# Script Version
VERSION="1.0.0"

################################################################################
# SELF-CORRECTION: Check for Windows line breaks (CRLF)
################################################################################
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [ -f "$SCRIPT_PATH" ]; then
    # Check if CRLF is present
    if file "$SCRIPT_PATH" 2>/dev/null | grep -q "CRLF"; then
        echo "WARNING: Windows line breaks (CRLF) detected!"
        echo "Converting to Linux format (LF)..."
        sed -i 's/\r$//' "$SCRIPT_PATH" 2>/dev/null
        echo "Correction completed!"
        echo "Restarting script..."
        echo ""
        exec "$SCRIPT_PATH" "$@"
        exit 0
    fi
fi

################################################################################
# ===== CONFIGURATION - ENTER TOKEN HERE ONLY =====
################################################################################

TOKEN="INSERT_YOUR_TOKEN_HERE"

# Base directories
HA_CONFIG_DIR="/homeassistant"
EXPORT_BASE_DIR="$HA_CONFIG_DIR/export"
STORAGE_DIR="$HA_CONFIG_DIR/.storage"

# API endpoint
HA_API="http://supervisor/core/api"

################################################################################
# Helper functions
################################################################################

# Colored output
print_success() { echo "[OK] $1"; }
print_error() { echo "[ERROR] $1"; }
print_info() { echo "[INFO] $1"; }
print_warning() { echo "[WARNING] $1"; }

# Check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "Command '$1' not found!"
        return 1
    fi
    return 0
}

################################################################################
# Check prerequisites
################################################################################

print_info "Checking prerequisites..."

# Check token
if [ "$TOKEN" = "INSERT_YOUR_TOKEN_HERE" ]; then
    print_error "TOKEN not configured yet!"
    echo ""
    echo "Please enter the TOKEN in line 32:"
    echo "TOKEN=\"your-long-token-here\""
    echo ""
    echo "Create token at:"
    echo "Settings -> People -> [Your Profile] -> Security -> Long-lived access tokens"
    exit 1
fi

# Check if curl is available
if ! check_command curl; then
    print_error "curl is not installed!"
    exit 1
fi

# Check if Python is available
if ! check_command python3; then
    print_error "Python3 is not installed!"
    exit 1
fi

# Check if PyYAML is installed
if ! python3 -c "import yaml" 2>/dev/null; then
    print_warning "PyYAML not installed!"
    echo ""
    echo "Install with:"
    echo "pip install pyyaml --break-system-packages"
    echo ""
    read -p "Install now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pip install pyyaml --break-system-packages
        if [ $? -ne 0 ]; then
            print_error "Installation failed!"
            exit 1
        fi
        print_success "PyYAML successfully installed!"
    else
        print_error "PyYAML is required!"
        exit 1
    fi
fi

################################################################################
# Prepare export directory
################################################################################

# Timestamp for unique names
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Get location name from HA configuration
LOCATION_NAME=$(curl -s -X GET "$HA_API/config" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" 2>/dev/null | \
    python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('location_name', 'HomeAssistant'))" 2>/dev/null)

# Fallback if API query fails
if [ -z "$LOCATION_NAME" ] || [ "$LOCATION_NAME" = "None" ]; then
    LOCATION_NAME="HomeAssistant"
fi

# Sanitize location name (only safe characters)
LOCATION_NAME=$(echo "$LOCATION_NAME" | sed 's/[^a-zA-Z0-9_-]/_/g')

# Export directory with timestamp
EXPORT_DIR="$EXPORT_BASE_DIR/${LOCATION_NAME}_$TIMESTAMP"
ZIP_NAME="${LOCATION_NAME}_${TIMESTAMP}.zip"

print_info "Creating export directory: $EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

################################################################################
# 1. Export registry files
################################################################################

print_info "Exporting registry files..."

REGISTRY_FILES=(
    "core.entity_registry"
    "core.device_registry"
    "core.area_registry"
)

for file in "${REGISTRY_FILES[@]}"; do
    if [ -f "$STORAGE_DIR/$file" ]; then
        cp "$STORAGE_DIR/$file" "$EXPORT_DIR/${file}.json"
        print_success "Copied: $file"
    else
        print_warning "Not found: $file"
    fi
done

################################################################################
# 2. Export API data
################################################################################

print_info "Exporting API data..."

# States (all current states)
curl -s -X GET "$HA_API/states" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    > "$EXPORT_DIR/states.json"
print_success "API states exported"

# Config (HA configuration)
curl -s -X GET "$HA_API/config" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    > "$EXPORT_DIR/config.json"
print_success "API config exported"

# Services (available services)
curl -s -X GET "$HA_API/services" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    > "$EXPORT_DIR/services.json"
print_success "API services exported"

################################################################################
# 3. Copy configuration files
################################################################################

print_info "Exporting configuration files..."

CONFIG_FILES=(
    "configuration.yaml"
    "automations.yaml"
    "scripts.yaml"
    "scenes.yaml"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$HA_CONFIG_DIR/$file" ]; then
        cp "$HA_CONFIG_DIR/$file" "$EXPORT_DIR/"
        print_success "Copied: $file"
    else
        print_warning "Not found: $file"
    fi
done

################################################################################
# 3.1. Copy externalized automations (recursive)
################################################################################

AUTOMATIONS_DIR="$HA_CONFIG_DIR/automations"
if [ -d "$AUTOMATIONS_DIR" ]; then
    print_info "Exporting externalized automations from $AUTOMATIONS_DIR..."
    
    # Create target directory
    mkdir -p "$EXPORT_DIR/automations"
    
    # Copy all YAML files recursively
    find "$AUTOMATIONS_DIR" -type f -name "*.yaml" -o -name "*.yml" | while read -r file; do
        # Relative path to automations directory
        rel_path="${file#$AUTOMATIONS_DIR/}"
        target_dir="$EXPORT_DIR/automations/$(dirname "$rel_path")"
        
        # Create target directory if needed
        mkdir -p "$target_dir"
        
        # Copy file
        cp "$file" "$target_dir/"
        print_success "Copied: automations/$rel_path"
    done
    
    # Count files
    yaml_count=$(find "$AUTOMATIONS_DIR" -type f \( -name "*.yaml" -o -name "*.yml" \) | wc -l)
    print_success "Total of $yaml_count automation files exported"
else
    print_info "No automations/ directory found - skipping"
fi

################################################################################
# 4. Create overviews (Python)
################################################################################

print_info "Creating overviews..."

# Python script inline for overview
python3 << 'PYTHON_SCRIPT'
import json
import yaml
from datetime import datetime
from collections import defaultdict

# Load registry data
with open('core.entity_registry.json', 'r', encoding='utf-8') as f:
    entities = json.load(f)['data']['entities']

with open('core.device_registry.json', 'r', encoding='utf-8') as f:
    devices = json.load(f)['data']['devices']

with open('core.area_registry.json', 'r', encoding='utf-8') as f:
    areas = json.load(f)['data']['areas']

# Create area mapping
area_map = {area['id']: area['name'] for area in areas}

# Create device mapping
device_map = {device['id']: device for device in devices}

# Group entities by area
entities_by_area = defaultdict(lambda: defaultdict(list))

for entity in entities:
    device_id = entity.get('device_id')
    
    # Determine area
    if device_id and device_id in device_map:
        device = device_map[device_id]
        area_id = device.get('area_id')
        area_name = area_map.get(area_id, 'No Room')
    else:
        area_name = 'No Device'
    
    # Determine domain (e.g. light, switch, sensor)
    entity_id = entity.get('entity_id', '')
    domain = entity_id.split('.')[0] if '.' in entity_id else 'unknown'
    
    entities_by_area[area_name][domain].append({
        'entity_id': entity_id,
        'name': entity.get('original_name', entity_id),
        'platform': entity.get('platform', 'unknown')
    })

# 1. devices_overview.yaml - Structured YAML file
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

# 2. README.md - Readable Markdown file
with open('README.md', 'w', encoding='utf-8') as f:
    f.write('# Home Assistant Device Export\n\n')
    f.write(f'**Export timestamp:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n\n')
    f.write(f'**Statistics:**\n')
    f.write(f'- Areas: {len(areas)}\n')
    f.write(f'- Devices: {len(devices)}\n')
    f.write(f'- Entities: {len(entities)}\n\n')
    f.write('---\n\n')
    
    # Grouped by areas
    for area_name in sorted(entities_by_area.keys()):
        f.write(f'## {area_name}\n\n')
        for domain in sorted(entities_by_area[area_name].keys()):
            domain_entities = entities_by_area[area_name][domain]
            f.write(f'### {domain.capitalize()} ({len(domain_entities)})\n\n')
            for entity in domain_entities:
                f.write(f'- **{entity["name"]}** (`{entity["entity_id"]}`)\n')
                f.write(f'  - Platform: {entity["platform"]}\n')
            f.write('\n')

# 3. devices_list.txt - Compact text list
with open('devices_list.txt', 'w', encoding='utf-8') as f:
    f.write('HOME ASSISTANT DEVICE EXPORT\n')
    f.write('='*60 + '\n')
    f.write(f'Export: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
    f.write(f'Areas: {len(areas)} | Devices: {len(devices)} | Entities: {len(entities)}\n')
    f.write('='*60 + '\n\n')
    
    for area_name in sorted(entities_by_area.keys()):
        f.write(f'\n[{area_name}]\n')
        f.write('-'*60 + '\n')
        for domain in sorted(entities_by_area[area_name].keys()):
            f.write(f'  {domain}:\n')
            for entity in entities_by_area[area_name][domain]:
                f.write(f'    - {entity["entity_id"]}\n')

# 4. export_info.yaml - Metadata
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

# Count entities by domain
domain_counts = defaultdict(int)
for entity in entities:
    entity_id = entity.get('entity_id', '')
    domain = entity_id.split('.')[0] if '.' in entity_id else 'unknown'
    domain_counts[domain] += 1

export_info['statistics']['entities_by_domain'] = dict(sorted(domain_counts.items()))

with open('export_info.yaml', 'w', encoding='utf-8') as f:
    yaml.dump(export_info, f, allow_unicode=True, default_flow_style=False)

print("Overviews successfully created!")
PYTHON_SCRIPT

# Change to export directory for Python execution
cd "$EXPORT_DIR" || exit 1
python3 << 'PYTHON_SCRIPT'
import json
import yaml
from datetime import datetime
from collections import defaultdict

# Load registry data
with open('core.entity_registry.json', 'r', encoding='utf-8') as f:
    entities = json.load(f)['data']['entities']

with open('core.device_registry.json', 'r', encoding='utf-8') as f:
    devices = json.load(f)['data']['devices']

with open('core.area_registry.json', 'r', encoding='utf-8') as f:
    areas = json.load(f)['data']['areas']

# Create area mapping
area_map = {area['id']: area['name'] for area in areas}

# Create device mapping
device_map = {device['id']: device for device in devices}

# Group entities by area
entities_by_area = defaultdict(lambda: defaultdict(list))

for entity in entities:
    device_id = entity.get('device_id')
    
    # Determine area
    if device_id and device_id in device_map:
        device = device_map[device_id]
        area_id = device.get('area_id')
        area_name = area_map.get(area_id, 'No Room')
    else:
        area_name = 'No Device'
    
    # Determine domain
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
    f.write(f'**Export timestamp:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n\n')
    f.write(f'**Statistics:**\n')
    f.write(f'- Areas: {len(areas)}\n')
    f.write(f'- Devices: {len(devices)}\n')
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
    f.write(f'Areas: {len(areas)} | Devices: {len(devices)} | Entities: {len(entities)}\n')
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

print_success "Overviews created!"
cd - > /dev/null

################################################################################
# 5. Create ZIP archive
################################################################################

print_info "Creating ZIP archive..."

cd "$EXPORT_BASE_DIR" || exit 1
zip -r -q "$ZIP_NAME" "$(basename "$EXPORT_DIR")"

if [ -f "$ZIP_NAME" ]; then
    ZIP_SIZE=$(du -h "$ZIP_NAME" | cut -f1)
    print_success "ZIP created: $ZIP_NAME ($ZIP_SIZE)"
else
    print_error "ZIP could not be created!"
    exit 1
fi

################################################################################
# 6. Cleanup
################################################################################

print_info "Cleaning up temporary files..."
rm -rf "$EXPORT_DIR"
print_success "Temporary files deleted"

################################################################################
# Completion
################################################################################

echo ""
echo "=========================================="
echo "Export successfully completed!"
echo "=========================================="
echo "File: $EXPORT_BASE_DIR/$ZIP_NAME"
echo "Size: $ZIP_SIZE"
echo ""
echo "You can find the file here:"
echo "- File Editor: /homeassistant/export/$ZIP_NAME"
echo "- Samba: \\\\homeassistant\\config\\export\\$ZIP_NAME"
echo ""

exit 0
