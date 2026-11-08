#!/bin/sh
set -eu

STEAM_DIR=/root/Steam
HLDS_DIR=/hlds
STEAM_MARKER="$HLDS_DIR/.steamcmd-installed-legacy"
REHLDS_MARKER="$HLDS_DIR/.rehlds-installed"

cd "$STEAM_DIR"

# Install/update CS 1.6 from the legacy Steam branch.
if [ ! -f "$STEAM_MARKER" ]; then
  ./steamcmd.sh \
    +force_install_dir "$HLDS_DIR" \
    +login anonymous \
    +app_set_config 90 mod cstrike \
    +app_update 90 -beta steam_legacy validate \
    +quit

  ./steamcmd.sh +login anonymous +app_update 70 validate +quit || true
  ./steamcmd.sh +login anonymous +app_update 10 validate +quit || true

  # Re-apply App 90 after the auxiliary SteamCMD updates.
  ./steamcmd.sh \
    +force_install_dir "$HLDS_DIR" \
    +login anonymous \
    +app_set_config 90 mod cstrike \
    +app_update 90 -beta steam_legacy validate \
    +quit

  touch "$STEAM_MARKER"
fi

# Install/update ReHLDS from the configured pinned Linux ZIP release.
if [ -z "${REHLDS_URL:-}" ]; then
  echo "ERROR: Set REHLDS_URL to a pinned ReHLDS Linux ZIP release asset URL."
  exit 1
fi

if [ ! -f "$REHLDS_MARKER" ] || [ "$(cat "$REHLDS_MARKER")" != "$REHLDS_URL" ]; then
  command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required"; exit 1; }
  command -v unzip >/dev/null 2>&1 || { echo "ERROR: unzip is required"; exit 1; }

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  echo "Downloading ReHLDS from $REHLDS_URL"
  curl -fL "$REHLDS_URL" -o "$tmpdir/rehlds.zip"
  unzip -q "$tmpdir/rehlds.zip" -d "$tmpdir/unpacked"

  rehlds_engine="$(find "$tmpdir/unpacked" -type f -name engine_i486.so -print -quit)"
  hlds_engine="$(find "$HLDS_DIR" -type f -name engine_i486.so -print -quit)"

  if [ -z "$rehlds_engine" ]; then
    echo "ERROR: ReHLDS archive did not contain engine_i486.so"
    exit 1
  fi
  if [ -z "$hlds_engine" ]; then
    echo "ERROR: Could not find HLDS engine_i486.so under $HLDS_DIR"
    exit 1
  fi

  install -m 755 "$rehlds_engine" "$hlds_engine"
  printf '%s' "$REHLDS_URL" > "$REHLDS_MARKER"
  echo "Installed ReHLDS engine at $hlds_engine"
fi

cd "$HLDS_DIR"
exec ./hlds_run -game cstrike -strictportbind -ip 0.0.0.0 \
  -port "${PORT:-27015}" \
  +sv_lan "${SV_LAN:-0}" \
  +map "${MAP:-de_dust2}" \
  -maxplayers "${MAXPLAYERS:-16}"
