#!/bin/sh
set -e

PATCH=/config/turn-patch
BASE=/app/obico/backend
FRONTEND_BUILD="$PATCH/frontend-build"
FRONTEND_DEST=/app/obico/frontend/builds/frontend

echo "[obico-turn-patch] Applying server-side TURN support..."

# Backend portion of PR #1157
cp -f "$PATCH/settings.py"            "$BASE/config/settings.py"
cp -f "$PATCH/context_processors.py" "$BASE/app/context_processors.py"
cp -f "$PATCH/octoprint_views.py"    "$BASE/api/octoprint_views.py"
cp -f "$PATCH/turn.py"               "$BASE/lib/turn.py"

echo "[obico-turn-patch] Backend TURN patch applied"

# Frontend portion of PR #1157
if [ ! -f "$FRONTEND_BUILD/js/root.js" ]; then
    echo "[obico-turn-patch] ERROR: frontend TURN build missing"
    exit 1
fi

rm -rf "$FRONTEND_DEST"
mkdir -p "$FRONTEND_DEST"
cp -a "$FRONTEND_BUILD/." "$FRONTEND_DEST/"

echo "[obico-turn-patch] Frontend TURN build installed"

# ImageGenius /init runs Django collectstatic afterwards.
# It copies FRONTEND_DEST into backend/static_build.
exec /init
