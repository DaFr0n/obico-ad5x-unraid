#!/bin/sh
set -eu

BASE="/opt/moonraker-obico/moonraker_obico"
MOONRAKER_FILE="$BASE/moonraker_conn.py"

PATCH_DIR="/zmod-patch"
WEBCAM_PATCH="$PATCH_DIR/webcam_stream.py"
BUILDER_PATCH="$PATCH_DIR/janus_config_builder.py"

echo "ZMOD PATCH: Checking moonraker-obico compatibility..."

if [ ! -f "$MOONRAKER_FILE" ]; then
    echo "ZMOD PATCH ERROR: $MOONRAKER_FILE not found."
    exit 1
fi

# Disable automatic API-key acquisition for ZMOD Moonraker.
if grep -q '^[[:space:]]*self\.ensure_api_key()' "$MOONRAKER_FILE"; then
    sed -i 's/^\([[:space:]]*\)self\.ensure_api_key()/\1# ZMOD PATCH: self.ensure_api_key()/' "$MOONRAKER_FILE"
    echo "ZMOD PATCH: Disabled ensure_api_key()."
elif grep -q 'ZMOD PATCH: self\.ensure_api_key()' "$MOONRAKER_FILE"; then
    echo "ZMOD PATCH: ensure_api_key() already disabled."
else
    echo "ZMOD PATCH ERROR: Expected ensure_api_key() call not found."
    exit 1
fi

# Disable X-Api-Key websocket header.
if grep -Fq "header=['X-Api-Key: {}'.format(self.app_config.moonraker.api_key), ]" "$MOONRAKER_FILE"; then
    sed -i "s|header=\['X-Api-Key: {}'.format(self.app_config.moonraker.api_key), \]|header=[]  # ZMOD PATCH: Moonraker API-key auth disabled|" "$MOONRAKER_FILE"
    echo "ZMOD PATCH: Disabled X-Api-Key websocket header."
elif grep -q 'ZMOD PATCH: Moonraker API-key auth disabled' "$MOONRAKER_FILE"; then
    echo "ZMOD PATCH: websocket header already disabled."
else
    echo "ZMOD PATCH ERROR: Expected websocket API-key header not found."
    exit 1
fi

echo "ZMOD PATCH: Compatibility patch applied successfully."

# Install persistent TURN patches.
for FILE in webcam_stream.py janus_config_builder.py; do
    if [ ! -f "$PATCH_DIR/$FILE" ]; then
        echo "TURN PATCH ERROR: $PATCH_DIR/$FILE not found."
        exit 1
    fi

    cp -f "$PATCH_DIR/$FILE" "$BASE/$FILE"
    chmod 644 "$BASE/$FILE"
    echo "TURN PATCH: $FILE installed."
done

echo "TURN PATCH: Persistent TURN integration applied successfully."

exec /opt/moonraker-obico/scripts/docker-entrypoint.sh \
    -c /opt/printer_data/config/moonraker-obico.cfg
