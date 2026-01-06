#!/bin/bash

BOT_TOKEN="8093034722:AAET1DEX8-TkMnUG3KTtjKWj0FUhzHxryjU"
CHAT_ID="-1002293479274"

BUILD_START_TIME=$(date +%s)

send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="$1" \
        -d parse_mode="HTML" > /dev/null
}

PRODUCT_BASE="out/target/product"

# Detect device directory automatically
DEVICE=$(ls "$PRODUCT_BASE" | head -n 1)
PRODUCT_DIR="$PRODUCT_BASE/$DEVICE"

# Detect ROM zip
ROM_ZIP=$(find "$PRODUCT_DIR" -name "*.zip" | grep -Ev "ota|symbol" | head -n 1)

if [[ ! -f "$ROM_ZIP" ]]; then
    send_telegram "<b>❌ Build Failed</b>%0AROM ZIP not found!"
    exit 1
fi

ZIP_NAME=$(basename "$ROM_ZIP")

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

# Detect images
BOOT_IMG="$PRODUCT_DIR/boot.img"
VENDOR_BOOT_IMG="$PRODUCT_DIR/vendor_boot.img"
DTBO_IMG="$PRODUCT_DIR/dtbo.img"

# Upload helper
SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name')

upload() {
    [[ -f "$1" ]] || echo "N/A"
    curl -s -F "file=@$1" "https://${SERVER}.gofile.io/uploadFile" \
        | jq -r '.data.downloadPage'
}

ROM_LINK=$(upload "$ROM_ZIP")
BOOT_LINK=$(upload "$BOOT_IMG")
VENDOR_BOOT_LINK=$(upload "$VENDOR_BOOT_IMG")
DTBO_LINK=$(upload "$DTBO_IMG")

# File info
SIZE=$(du -h "$ROM_ZIP" | awk '{print $1}')
MD5SUM=$(md5sum "$ROM_ZIP" | awk '{print $1}')

# Build time
BUILD_END_TIME=$(date +%s)
ELAPSED=$((BUILD_END_TIME - BUILD_START_TIME))
HOURS=$((ELAPSED / 3600))
MINUTES=$(((ELAPSED % 3600) / 60))

# Telegram message
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

Compilation took ${HOURS} hour(s) and ${MINUTES} minute(s)"

echo "Telegram notification sent."
