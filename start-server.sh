#!/bin/sh
set -e

cd /root/Steam

# Download the server at container startup, not during the image build.
if [ ! -f /hlds/.steamcmd-installed ]; then
  ./steamcmd.sh +force_install_dir /hlds +login anonymous +app_update 90 validate +quit
  ./steamcmd.sh +login anonymous +app_update 70 validate +quit || true
  ./steamcmd.sh +login anonymous +app_update 10 validate +quit || true
  ./steamcmd.sh +force_install_dir /hlds +login anonymous +app_update 90 validate +quit
  touch /hlds/.steamcmd-installed
fi

# Install ReHLDS if the configured release has not already been installed.
if [ -z "${REHLDS_URL:-}" ]; then
  echo "ERROR: Set REHLDS_URL to a pinned ReHLDS Linux ZIP release asset URL."
  exit 1
fi

if [ ! -f /hlds/.rehlds-installed ] || [ "$(cat /hlds/.rehlds-installed)" != "$REHLDS_URL" ]; then
  command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required"; exit 1; }
  command -v unzip >/dev/null 2>&1 || { echo "ERROR: unzip is required"; exit 1; }

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  curl -fL "$REHLDS_URL" -o "$tmpdir/rehlds.zip"
  unzip -q "$tmpdir/rehlds.zip" -d "$tmpdir/unpacked"

  rehlds_engine="$(find "$tmpdir/unpacked" -type f -name engine_i486.so -print -quit)"
  hlds_engine="$(find /hlds -type f -name engine_i486.so -print -quit)"

  if [ -z "$rehlds_engine" ]; then
    echo "ERROR: The ReHLDS archive did not contain engine_i486.so"
    exit 1
  fi
  if [ -z "$hlds_engine" ]; then
    echo "ERROR: Could not find the existing HLDS engine_i486.so under /hlds"
    exit 1
  fi

  install -m 755 "$rehlds_engine" "$hlds_engine"
  printf '%s' "$REHLDS_URL" > /hlds/.rehlds-installed
  echo "Installed ReHLDS engine at $hlds_engine"
fi

cd /hlds
exec ./hlds_run -game cstrike -strictportbind -ip 0.0.0.0 \
  -port "$PORT" +sv_lan "$SV_LAN" +map "$MAP" -maxplayers "$MAXPLAYERS"

