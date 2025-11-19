#!/bin/bash

BOT_TOKEN="8093034722:AAET1DEX8-TkMnUG3KTtjKWj0FUhzHxryjU"
CHAT_ID="-1002293479274"

# Telegram message function
send_telegram() {
    MESSAGE=$1
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${MESSAGE}" \
        -d parse_mode="HTML" > /dev/null
}

# Find final ROM zip (static OR dynamic)
ZIP_PATH=$(find out/target/product/lisaa -name "*-lisaa*.zip" 2>/dev/null | head -n 1)

if [[ -f "$ZIP_PATH" ]]; then
    echo "Uploading to GoFile..."
    SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name')
    LINK=$(curl -s -F "file=@${ZIP_PATH}" "https://${SERVER}.gofile.io/uploadFile" | jq -r '.data.downloadPage')

    echo "ROM uploaded: $LINK"
    send_telegram " ^|^e <b>Build Complete</b> for Lisaa%0A<a href=\"$LINK\">Download ROM</a>"
else
    echo "ROM ZIP not found!"
    send_telegram "<b>Error</b>: ROM ZIP not found!"
fi
