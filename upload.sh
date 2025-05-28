#!/bin/bash

# ───────────────────────────────────────────────
# 🔧 Set Your Telegram Bot Token and Chat ID Here
# ───────────────────────────────────────────────
BOT_TOKEN="8093034722:AAFtN47P3_qgx1yz6grVQrrY7nLQMcRvt-g"
CHAT_ID="-1002293479274"

# 📬 Telegram message function
send_telegram() {
    MESSAGE=$1
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${MESSAGE}" \
        -d parse_mode="HTML" > /dev/null
}

# Find final ROM zip
    ZIP_PATH=$(find out/target/product/lisaa -name "*-lisaa*.zip" | head -n 1)

    if [[ -f "$ZIP_PATH" ]]; then
        echo "📤 Uploading to GoFile..."
        SERVER=$(curl -s https://api.gofile.io/servers | jq -r '.data.servers[0].name')
        LINK=$(curl -# -F "file=@${ZIP_PATH}" "https://${SERVER}.gofile.io/uploadFile" | jq -r '.data.downloadPage') 2>&1

        echo "📎 ROM uploaded: $LINK"
        send_telegram "✅ <b>Build Complete</b> for Lisaa 📎 <a href=\"$LINK\">Download ROM</a>"

fi
