#!/bin/bash

BOT_TOKEN="8093034722:AAET1DEX8-TkMnUG3KTtjKWj0FUhzHxryjU"
CHAT_ID="-1002293479274"

# ---------- helpers ----------
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

sep() {
    echo "--------------------------------------------------"
}

send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="$1" \
        -d parse_mode="HTML" > /dev/null
}

sep
log "ROM upload script started"
sep

PRODUCT_BASE="out/target/product"

log "Detecting device directory..."

# Detect device directory automatically (first real product dir)
DEVICE=$(ls -1 "$PRODUCT_BASE" \
    | grep -vE '^(generic|symbols|obj)$' \
    | head -n 1)

PRODUCT_DIR="$PRODUCT_BASE/$DEVICE"

# Safety check
if [[ -z "$DEVICE" || ! -d "$PRODUCT_DIR" ]]; then
    log "ERROR: Device directory not detected"
    send_telegram "<b>❌ Build Failed</b>%0ADevice directory not detected!"
    exit 1
fi

log "Device detected: $DEVICE"

sep
log "Searching for ROM zip..."

# Detect ROM zip
ROM_ZIP=$(find "$PRODUCT_DIR" -name "*.zip" | grep -Ev "ota|symbol" | head -n 1)

if [[ ! -f "$ROM_ZIP" ]]; then
    log "ERROR: ROM ZIP not found"
    send_telegram "<b>❌ Build Failed</b>%0AROM ZIP not found!"
    exit 1
fi

ZIP_NAME=$(basename "$ROM_ZIP")
log "ROM zip found: $ZIP_NAME"

sep
log "Extracting ROM metadata..."

# Detect ROM name (first part before device codename)
ROM_NAME=$(echo "$ZIP_NAME" | sed -E "s/-${DEVICE}.*//")

# Detect build type
if echo "$ZIP_NAME" | grep -qi "UNOFFICIAL"; then
    BUILD_TYPE="Unofficial"
elif echo "$ZIP_NAME" | grep -qi "OFFICIAL"; then
    BUILD_TYPE="Official"
else
    BUILD_TYPE="Unknown"
fi

log "ROM Name : $ROM_NAME"
log "Build    : $BUILD_TYPE"

sep
log "Checking image files..."

BOOT_IMG="$PRODUCT_DIR/boot.img"
VENDOR_BOOT_IMG="$PRODUCT_DIR/vendor_boot.img"
DTBO_IMG="$PRODUCT_DIR/dtbo.img"

[[ -f "$BOOT_IMG" ]] && log "boot.img         : OK" || log "boot.img         : MISSING"
[[ -f "$VENDOR_BOOT_IMG" ]] && log "vendor_boot.img  : OK" || log "vendor_boot.img  : MISSING"
[[ -f "$DTBO_IMG" ]] && log "dtbo.img         : OK" || log "dtbo.img         : MISSING"

sep
log "Starting upload stage..."

# Upload helper (ONLY jq stderr suppressed)
SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name')

upload() {
    [[ -f "$1" ]] || { echo "N/A"; return; }
    curl -s -F "file=@$1" "https://${SERVER}.gofile.io/uploadFile" \
        | jq -r '.data.downloadPage' 2>/dev/null
}

ROM_LINK=$(upload "$ROM_ZIP")
BOOT_LINK=$(upload "$BOOT_IMG")
VENDOR_BOOT_LINK=$(upload "$VENDOR_BOOT_IMG")
DTBO_LINK=$(upload "$DTBO_IMG")

log "Upload stage completed"

sep
log "Calculating file information..."

SIZE=$(du -h "$ROM_ZIP" | awk '{print $1}')
MD5SUM=$(md5sum "$ROM_ZIP" | awk '{print $1}')

log "ROM size : $SIZE"
log "MD5SUM   : $MD5SUM"

sep
log "Sending Telegram notification..."

send_telegram "🟢 | <b>ROM compiled!!</b>

• <b>ROM</b>: ${ROM_NAME}
• <b>DEVICE</b>: ${DEVICE}
• <b>TYPE</b>: ${BUILD_TYPE}
• <b>SIZE</b>: ${SIZE}
• <b>MD5SUM</b>: <code>${MD5SUM}</code>
• <b>ROM</b>: <a href=\"${ROM_LINK}\">Download</a>
• <b>BOOT</b>: <a href=\"${BOOT_LINK}\">Download</a>
• <b>VENDOR_BOOT</b>: <a href=\"${VENDOR_BOOT_LINK}\">Download</a>
• <b>DTBO</b>: <a href=\"${DTBO_LINK}\">Download</a>
"

sep
log "Telegram notification sent"
log "Script finished"
sep
