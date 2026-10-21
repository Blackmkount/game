#!/usr/bin/env bash
# Captura: run.sh <nombre> <features>  -> shots/<nombre>/f000000NN.png y logs/<nombre>.log
set -u
D=/tmp/claude-0/-home-user-game/3bec4478-e817-5ed9-8d65-70f79ec89943/scratchpad/gfx-exp-b
G=/home/user/game/.tools/godot/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64
NAME=$1; FEATURES=${2:-}; FRAMES=${3:-20}
mkdir -p "$D/shots/$NAME" "$D/logs"
rm -f "$D/shots/$NAME"/*.png
timeout 120 xvfb-run -a -s "-screen 0 1400x1400x24" "$G" --path "$D" --rendering-driver opengl3 \
  --fixed-fps 30 --write-movie "$D/shots/$NAME/f.png" --quit-after "$FRAMES" -- --features="$FEATURES" > "$D/logs/$NAME.log" 2>&1
echo "exit=$? name=$NAME"
grep -iE "error|warn|FEATURES|VERTEX|not supported|unsupported" "$D/logs/$NAME.log" | head -20
