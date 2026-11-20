#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

OBICO_DIR="/mnt/cache/appdata/obico"
MOON_DIR="/mnt/cache/appdata/moonraker-obico"
TURN_DIR="/mnt/cache/appdata/obico-turn"

echo "Obico AD5X/ZMOD Community Installer"
echo "==================================="
echo
echo "This installs compatibility files and generates configuration."
echo "It does NOT create, delete, stop or modify Docker containers."
echo

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run this installer as root on Unraid."
    exit 1
fi

for CMD in openssl cp mkdir chmod grep; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: $CMD"
        exit 1
    fi
done

for FILE in \
    "$REPO_DIR/moonraker-obico/zmod-entrypoint.sh" \
    "$REPO_DIR/moonraker-obico/webcam_stream.py" \
    "$REPO_DIR/moonraker-obico/janus_config_builder.py" \
    "$REPO_DIR/obico/entrypoint.sh" \
    "$REPO_DIR/obico/settings.py" \
    "$REPO_DIR/obico/context_processors.py" \
    "$REPO_DIR/obico/octoprint_views.py" \
    "$REPO_DIR/obico/turn.py"; do

    if [ ! -f "$FILE" ]; then
        echo "ERROR: Required package file missing:"
        echo "       $FILE"
        exit 1
    fi
done

if [ ! -d "$REPO_DIR/obico/frontend-build" ]; then
    echo "ERROR: Obico frontend-build directory is missing."
    exit 1
fi

echo "Package files: OK"
echo

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
echo "Configuration:"
echo "  Unraid LAN IP : $UNRAID_IP"
echo "  Public IP     : $PUBLIC_IP"
echo "  Printer IP    : $PRINTER_IP"
echo "  Obico IP      : $OBICO_IP"
echo
echo "No TURN secret will be displayed."
echo

read -rp "Continue? [y/N]: " ANSWER
case "$ANSWER" in
    y|Y|yes|YES)
        ;;
    *)
        echo "Cancelled."
        exit 0
        ;;
esac

# Protect existing sensitive configuration.
for FILE in \
    "$TURN_DIR/turnserver.conf" \
    "$MOON_DIR/config/moonraker-obico.cfg"; do

    if [ -e "$FILE" ]; then
        echo
        echo "ERROR: Existing configuration detected:"
        echo "       $FILE"
        echo
        echo "Installer stopped to avoid overwriting a working installation."
        exit 1
    fi
done

echo
echo "Creating directories..."

mkdir -p \
    "$OBICO_DIR/turn-patch" \
    "$MOON_DIR/patch" \
    "$MOON_DIR/config" \
    "$MOON_DIR/logs" \
    "$TURN_DIR"

echo "Installing moonraker-obico compatibility files..."

cp -f \
    "$REPO_DIR/moonraker-obico/zmod-entrypoint.sh" \
    "$MOON_DIR/patch/zmod-entrypoint.sh"

cp -f \
    "$REPO_DIR/moonraker-obico/webcam_stream.py" \
    "$MOON_DIR/patch/webcam_stream.py"

cp -f \
    "$REPO_DIR/moonraker-obico/janus_config_builder.py" \
    "$MOON_DIR/patch/janus_config_builder.py"

chmod 755 "$MOON_DIR/patch/zmod-entrypoint.sh"
chmod 644 \
    "$MOON_DIR/patch/webcam_stream.py" \
    "$MOON_DIR/patch/janus_config_builder.py"

echo "Installing Obico TURN compatibility files..."

cp -f "$REPO_DIR/obico/entrypoint.sh" \
      "$OBICO_DIR/turn-patch/entrypoint.sh"

cp -f "$REPO_DIR/obico/settings.py" \
      "$OBICO_DIR/turn-patch/settings.py"

cp -f "$REPO_DIR/obico/context_processors.py" \
      "$OBICO_DIR/turn-patch/context_processors.py"

cp -f "$REPO_DIR/obico/octoprint_views.py" \
      "$OBICO_DIR/turn-patch/octoprint_views.py"

cp -f "$REPO_DIR/obico/turn.py" \
      "$OBICO_DIR/turn-patch/turn.py"

rm -rf "$OBICO_DIR/turn-patch/frontend-build"
mkdir -p "$OBICO_DIR/turn-patch/frontend-build"
cp -a "$REPO_DIR/obico/frontend-build/." \
      "$OBICO_DIR/turn-patch/frontend-build/"

chmod 755 "$OBICO_DIR/turn-patch/entrypoint.sh"

echo "Generating TURN secret..."

TURN_SECRET="$(openssl rand -hex 32)"

if [ "${#TURN_SECRET}" -ne 64 ]; then
    echo "ERROR: TURN secret generation failed."
    exit 1
fi

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

# Store the secret separately so the user can enter it into the
# Obico Unraid template without printing it to terminal.
SECRET_FILE="$TURN_DIR/turn-secret.txt"
printf '%s\n' "$TURN_SECRET" > "$SECRET_FILE"
chmod 600 "$SECRET_FILE"

unset TURN_SECRET

echo
echo "==================================="
echo "Installation files created."
echo
echo "Obico patch:"
echo "  $OBICO_DIR/turn-patch"
echo
echo "moonraker-obico:"
echo "  $MOON_DIR"
echo
echo "Coturn:"
echo "  $TURN_DIR/turnserver.conf"
echo
echo "TURN secret:"
echo "  $SECRET_FILE"
echo
echo "The TURN secret was NOT printed."
echo
echo "NEXT STEPS:"
echo
echo "1. Install/configure Redis and Obico."
echo
echo "2. Enter these values in the Obico template:"
echo "     HOST_IP=$UNRAID_IP"
echo "     TURN_SERVER=$UNRAID_IP"
echo "     TURN_PORT=3478"
echo "     TURN_TRANSPORTS=udp,tcp"
echo
echo "3. Copy the TURN secret from:"
echo "     $SECRET_FILE"
echo "   into the Obico TURN_SECRET field."
echo
echo "4. Install Obico-TURN."
echo
echo "5. Forward on your router:"
echo "     UDP 3478 -> $UNRAID_IP:3478"
echo "     TCP 3478 -> $UNRAID_IP:3478"
echo "     UDP 49160-49200 -> $UNRAID_IP:49160-49200"
echo
echo "6. Link the printer in Obico and replace:"
echo "     PASTE_LINKED_PRINTER_AUTH_TOKEN_HERE"
echo "   in:"
echo "     $MOON_DIR/config/moonraker-obico.cfg"
echo
echo "7. Install/start Moonraker-Obico-AD5X."
echo
echo "8. Run scripts/verify.sh."
echo
