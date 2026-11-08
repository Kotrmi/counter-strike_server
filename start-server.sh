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

cd /hlds
exec ./hlds_run -game cstrike -strictportbind -ip 0.0.0.0 \
  -port "$PORT" +sv_lan "$SV_LAN" +map "$MAP" -maxplayers "$MAXPLAYERS"

