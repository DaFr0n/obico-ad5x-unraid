#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

OBICO_DIR="/mnt/cache/appdata/obico"
MOON_DIR="/mnt/cache/appdata/moonraker-obico"
TURN_DIR="/mnt/cache/appdata/obico-turn"

echo "Obico AD5X/ZMOD Recovery"
echo "========================"
echo
echo "This restores the configuration/patch files supplied with this package."
echo "It does NOT create, delete, stop, or modify Docker containers."
echo

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run this script as root on Unraid."
    exit 1
fi

for CMD in openssl cp mkdir chmod grep sed; do
    command -v "$CMD" >/dev/null 2>&1 || {
        echo "ERROR: Required command not found: $CMD"
        exit 1
    }
done

echo "Checking package..."

REQUIRED_FILES=(
    "$REPO_DIR/moonraker-obico/zmod-entrypoint.sh"
    "$REPO_DIR/moonraker-obico/webcam_stream.py"
    "$REPO_DIR/moonraker-obico/janus_config_builder.py"
    "$REPO_DIR/obico/entrypoint.sh"
    "$REPO_DIR/obico/settings.py"
    "$REPO_DIR/obico/context_processors.py"
    "$REPO_DIR/obico/octoprint_views.py"
    "$REPO_DIR/obico/turn.py"
    "$REPO_DIR/templates/Moonraker-Obico-AD5X.xml"
    "$REPO_DIR/templates/Obico-AD5X.xml"
    "$REPO_DIR/templates/Obico-TURN.xml"
)

for FILE in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
        echo "ERROR: Required package file missing:"
        echo "       $FILE"
        exit 1
    fi
done

[ -d "$REPO_DIR/obico/frontend-build" ] || {
    echo "ERROR: Obico frontend-build directory is missing."
    exit 1
}

echo "Package files: OK"
echo

# Existing configuration is deliberately never overwritten automatically.
EXISTING=()

for FILE in \
    "$TURN_DIR/turnserver.conf" \
    "$TURN_DIR/turn-secret.txt" \
    "$MOON_DIR/config/moonraker-obico.cfg"; do
    [ -e "$FILE" ] && EXISTING+=("$FILE")
done

if [ "${#EXISTING[@]}" -gt 0 ]; then
    echo "Existing configuration detected:"
    printf '  %s\n' "${EXISTING[@]}"
    echo
    echo "Recovery stopped to protect the existing installation."
    echo "Back up/remove the existing configuration first if a full rebuild is intended."
    exit 1
fi

read -rp "Unraid LAN IPv4 address: " UNRAID_IP
read -rp "Public IPv4 address: " PUBLIC_IP
read -rp "AD5X/ZMOD IPv4 address: " PRINTER_IP
read -rp "Obico server IP [${UNRAID_IP}]: " OBICO_IP
OBICO_IP="${OBICO_IP:-$UNRAID_IP}"

valid_ipv4() {
    local ip="$1"
    local IFS=.
    local -a octets

    read -ra octets <<< "$ip"
    [ "${#octets[@]}" -eq 4 ] || return 1

    for octet in "${octets[@]}"; do
        [[ "$octet" =~ ^[0-9]+$ ]] || return 1
        (( octet >= 0 && octet <= 255 )) || return 1
    done
}

for ENTRY in \
    "Unraid:$UNRAID_IP" \
    "Public:$PUBLIC_IP" \
    "Printer:$PRINTER_IP" \
    "Obico:$OBICO_IP"; do

    LABEL="${ENTRY%%:*}"
    VALUE="${ENTRY#*:}"

    if ! valid_ipv4 "$VALUE"; then
        echo "ERROR: Invalid $LABEL IPv4 address: $VALUE"
        exit 1
    fi
done

echo
echo "Recovery configuration:"
echo "  Unraid LAN IP : $UNRAID_IP"
echo "  Public IP     : $PUBLIC_IP"
echo "  Printer IP    : $PRINTER_IP"
echo "  Obico IP      : $OBICO_IP"
echo

read -rp "Continue with recovery? [y/N]: " ANSWER
case "$ANSWER" in
    y|Y|yes|YES) ;;
    *) echo "Cancelled."; exit 0 ;;
esac

echo
echo "Creating directories..."

mkdir -p \
    "$OBICO_DIR/turn-patch" \
    "$MOON_DIR/patch" \
    "$MOON_DIR/config" \
    "$MOON_DIR/logs" \
    "$TURN_DIR"

echo "Restoring Moonraker-Obico compatibility files..."

cp -f "$REPO_DIR/moonraker-obico/zmod-entrypoint.sh" \
      "$MOON_DIR/patch/zmod-entrypoint.sh"
cp -f "$REPO_DIR/moonraker-obico/webcam_stream.py" \
      "$MOON_DIR/patch/webcam_stream.py"
cp -f "$REPO_DIR/moonraker-obico/janus_config_builder.py" \
      "$MOON_DIR/patch/janus_config_builder.py"

chmod 755 "$MOON_DIR/patch/zmod-entrypoint.sh"
chmod 644 \
    "$MOON_DIR/patch/webcam_stream.py" \
    "$MOON_DIR/patch/janus_config_builder.py"

echo "Restoring Obico TURN compatibility files..."

for FILE in \
    entrypoint.sh \
    settings.py \
    context_processors.py \
    octoprint_views.py \
    turn.py; do
    cp -f "$REPO_DIR/obico/$FILE" "$OBICO_DIR/turn-patch/$FILE"
done

rm -rf "$OBICO_DIR/turn-patch/frontend-build"
mkdir -p "$OBICO_DIR/turn-patch/frontend-build"
cp -a "$REPO_DIR/obico/frontend-build/." \
      "$OBICO_DIR/turn-patch/frontend-build/"

chmod 755 "$OBICO_DIR/turn-patch/entrypoint.sh"
chmod 644 \
    "$OBICO_DIR/turn-patch/settings.py" \
    "$OBICO_DIR/turn-patch/context_processors.py" \
    "$OBICO_DIR/turn-patch/octoprint_views.py" \
    "$OBICO_DIR/turn-patch/turn.py"

echo "Generating new TURN secret..."

TURN_SECRET="$(openssl rand -hex 32)"

[ "${#TURN_SECRET}" -eq 64 ] || {
    echo "ERROR: TURN secret generation failed."
    exit 1
}

cat > "$TURN_DIR/turnserver.conf" <<EOF_TURN
listening-port=3478
listening-ip=$UNRAID_IP
relay-ip=$UNRAID_IP
external-ip=$PUBLIC_IP/$UNRAID_IP

realm=obico.local
server-name=obico-turn

fingerprint
use-auth-secret
static-auth-secret=$TURN_SECRET

min-port=49160
max-port=49200

no-cli
no-tls
no-dtls
stale-nonce=600
EOF_TURN

chmod 600 "$TURN_DIR/turnserver.conf"

printf '%s\n' "$TURN_SECRET" > "$TURN_DIR/turn-secret.txt"
chmod 600 "$TURN_DIR/turn-secret.txt"

unset TURN_SECRET

cat > "$MOON_DIR/config/moonraker-obico.cfg" <<EOF_MOON
[server]
url = http://$OBICO_IP:3334
auth_token = PASTE_LINKED_PRINTER_AUTH_TOKEN_HERE

[moonraker]
host = $PRINTER_IP
port = 7125

[webcam]
disable_video_streaming = False
snapshot_url = http://$PRINTER_IP/webcam/?action=snapshot
stream_url = http://$PRINTER_IP/webcam/?action=stream

[logging]
path = /opt/printer_data/logs/moonraker-obico.log
level = INFO

[tunnel]
EOF_MOON

chmod 600 "$MOON_DIR/config/moonraker-obico.cfg"

echo
echo "======================================"
echo "Recovery files restored successfully."
echo "======================================"
echo
echo "TURN secret:"
echo "  $TURN_DIR/turn-secret.txt"
echo
echo "The TURN secret was not printed."
echo
echo "NEXT STEPS:"
echo
echo "1. Install/configure Redis and Obico."
echo "2. Install the supplied Obico-AD5X template."
echo "3. Set:"
echo "     HOST_IP=$UNRAID_IP"
echo "     TURN_SERVER=$UNRAID_IP"
echo "     TURN_PORT=3478"
echo "     TURN_TRANSPORTS=udp,tcp"
echo "4. Copy the TURN secret from:"
echo "     $TURN_DIR/turn-secret.txt"
echo "   into the Obico TURN_SECRET field."
echo "5. Install/start Obico-TURN."
echo "6. Forward TCP/UDP 3478 and UDP 49160-49200 on your router."
echo "7. Link the AD5X printer in Obico."
echo "8. Replace PASTE_LINKED_PRINTER_AUTH_TOKEN_HERE in:"
echo "     $MOON_DIR/config/moonraker-obico.cfg"
echo "9. Install/start Moonraker-Obico-AD5X."
echo "10. Run:"
echo "     $REPO_DIR/scripts/verify.sh"
echo
