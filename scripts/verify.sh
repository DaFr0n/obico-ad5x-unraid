#!/bin/sh

PASS=0
WARN=0
FAIL=0

pass() {
    echo "[PASS] $*"
    PASS=$((PASS + 1))
}

warn() {
    echo "[WARN] $*"
    WARN=$((WARN + 1))
}

fail() {
    echo "[FAIL] $*"
    FAIL=$((FAIL + 1))
}

container_running() {
    docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null | grep -qx true
}

echo "Obico AD5X/ZMOD verification"
echo "============================"
echo

if ! command -v docker >/dev/null 2>&1; then
    echo "[FAIL] Docker command not found."
    exit 1
fi

for C in obico moonraker-obico obico-turn; do
    if container_running "$C"; then
        pass "$C is running"
    else
        fail "$C is not running"
    fi
done

echo

if docker exec moonraker-obico \
    grep -q 'ZMOD PATCH: self.ensure_api_key()' \
    /opt/moonraker-obico/moonraker_obico/moonraker_conn.py 2>/dev/null; then
    pass "ZMOD Moonraker API-key acquisition patch active"
else
    fail "ZMOD Moonraker API-key acquisition patch not detected"
fi

if docker exec moonraker-obico \
    grep -q 'ZMOD PATCH: Moonraker API-key auth disabled' \
    /opt/moonraker-obico/moonraker_obico/moonraker_conn.py 2>/dev/null; then
    pass "ZMOD Moonraker WebSocket API-key header patch active"
else
    fail "ZMOD Moonraker WebSocket API-key header patch not detected"
fi

if docker exec moonraker-obico \
    grep -q "turn=self.linked_printer.get('turn')" \
    /opt/moonraker-obico/moonraker_obico/webcam_stream.py 2>/dev/null; then
    pass "moonraker-obico TURN integration active"
else
    fail "moonraker-obico TURN integration not detected"
fi

if docker exec moonraker-obico \
    grep -q 'bandwidth_throttle = 0.0005' \
    /opt/moonraker-obico/moonraker_obico/webcam_stream.py 2>/dev/null; then
    pass "AD5X MJPEG throttle patch active (0.0005)"
else
    warn "Expected AD5X MJPEG throttle value not detected"
fi

echo

if docker inspect moonraker-obico --format '{{range .Mounts}}{{println .Destination}}{{end}}' 2>/dev/null |
    grep -qx '/opt/printer_data/config'; then
    pass "moonraker-obico config is persistently mounted"
else
    fail "moonraker-obico persistent config mount missing"
fi

if docker inspect moonraker-obico --format '{{range .Mounts}}{{println .Destination}}{{end}}' 2>/dev/null |
    grep -qx '/opt/printer_data/logs'; then
    pass "moonraker-obico logs are persistently mounted"
else
    warn "moonraker-obico persistent logs mount missing"
fi

if docker inspect obico --format '{{range .Mounts}}{{println .Destination}}{{end}}' 2>/dev/null |
    grep -qx '/config/turn-patch'; then
    pass "Obico TURN patch directory mounted"
else
    fail "Obico TURN patch directory not mounted"
fi

if docker exec obico sh -c '
    grep -q "TURN_SERVER = os.environ.get" /app/obico/backend/config/settings.py &&
    grep -q "def turn_config" /app/obico/backend/lib/turn.py &&
    grep -q "turn_config" /app/obico/backend/app/context_processors.py &&
    grep -q "turn_config" /app/obico/backend/api/octoprint_views.py
' 2>/dev/null; then
    pass "Obico backend TURN compatibility patch installed"
else
    fail "Obico backend TURN compatibility patch not detected"
fi

if docker exec obico test -s /app/obico/frontend/builds/frontend/js/root.js 2>/dev/null; then
    pass "Obico TURN-enabled frontend build installed"
else
    fail "Obico TURN-enabled frontend build not detected"
fi

echo

if docker exec obico sh -c \
    'test -n "${TURN_SERVER:-}" && test -n "${TURN_PORT:-}" && test -n "${TURN_SECRET:-}"' \
    2>/dev/null; then
    pass "Obico TURN environment configured"
else
    fail "Obico TURN environment incomplete"
fi

if docker exec obico sh -c 'test -n "${DJANGO_SECRET_KEY:-}"' 2>/dev/null; then
    pass "Unique Django secret key environment variable is set"
else
    warn "DJANGO_SECRET_KEY is not set; upstream default SECRET_KEY fallback may be in use"
fi

if docker exec obico-turn sh -c \
    'test -r /etc/coturn/turnserver.conf' 2>/dev/null; then
    pass "Coturn configuration mounted"
else
    fail "Coturn configuration unavailable"
fi

echo

# Compare secrets without displaying either secret.
TURN_FILE_SECRET=$(
    docker exec obico-turn sh -c \
    "sed -n 's/^[[:space:]]*static-auth-secret[[:space:]]*=[[:space:]]*//p' /etc/coturn/turnserver.conf | head -n1" \
    2>/dev/null | tr -d '\r\n'
)

OBICO_SECRET=$(
    docker exec obico sh -c 'printf "%s" "${TURN_SECRET:-}"' 2>/dev/null
)

if [ -n "$TURN_FILE_SECRET" ] && [ -n "$OBICO_SECRET" ]; then
    if [ "$TURN_FILE_SECRET" = "$OBICO_SECRET" ]; then
        pass "Obico and Coturn TURN secrets match"
    else
        fail "Obico and Coturn TURN secrets do not match"
    fi
else
    fail "Unable to obtain TURN secret from one or both containers"
fi

unset TURN_FILE_SECRET
unset OBICO_SECRET

echo

if command -v ss >/dev/null 2>&1; then
    if ss -lntu 2>/dev/null | grep -q ':3478[[:space:]]'; then
        pass "TURN port 3478 is listening"
    else
        fail "TURN port 3478 does not appear to be listening"
    fi
else
    warn "ss command unavailable; TURN listener not checked"
fi

echo
echo "============================"
echo "PASS: $PASS"
echo "WARN: $WARN"
echo "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi

exit 0
