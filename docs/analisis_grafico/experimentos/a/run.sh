#!/usr/bin/env bash
# Corre un modo y guarda la captura en shots/<modo>/ y el registro en logs/<modo>.log
set -u
D=/tmp/claude-0/-home-user-game/3bec4478-e817-5ed9-8d65-70f79ec89943/scratchpad/gfx-exp-a
G=/home/user/game/.tools/godot/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64
MODE=$1
TAG=${2:-$1}
shift; [ $# -gt 0 ] && shift
mkdir -p "$D/shots/$TAG" "$D/logs"
rm -f "$D/shots/$TAG"/*.png
timeout 120 xvfb-run -a -s "-screen 0 1400x1400x24" "$G" --path "$D" --rendering-driver opengl3 \
  --fixed-fps 30 --write-movie "$D/shots/$TAG/f.png" --quit-after 20 -- --mode="$MODE" "$@" > "$D/logs/$TAG.log" 2>&1
echo "exit=$? mode=$MODE"
